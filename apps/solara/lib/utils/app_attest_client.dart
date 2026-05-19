// Solara App Attest クライアント (Flutter ↔ Worker /auth/* /protected/*)
//
// 役割:
//   - 起動時に keyId を SharedPreferences から復元、なければ Worker で attest
//   - /protected/* 呼び出し時の HTTP header に X-AppAttest-KeyId/Assertion を付与
//   - DCError.invalidInput/invalidKey 時の key 再生成リトライ
//   - iOS Simulator / Android / Web / kDebugMode では bypass (= ヘッダ無し、
//     Worker 側 APP_ATTEST_ENFORCEMENT=log_only で通過させる前提)
//
// Worker 側仕様: apps/solara/worker/src/index.js
//   POST /auth/challenge   → {challengeId, challenge: base64(32B), ttlSec}
//   POST /auth/attest      body: {keyId, challengeId, attestation: base64}
//   /protected/* headers: X-AppAttest-KeyId, X-AppAttest-Assertion: base64
//
// 設計: apps/solara/docs/app_attest_design.md (v2.0+)

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:app_attest_integrity/app_attest_integrity.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'solara_api.dart';

const String _kPrefsKeyId = 'solara_appattest_key_id_v1';

/// AppAttestClient シングルトン。
///
/// Solara 内で 1 端末あたり 1 keyId を保持する。`initialize()` は main.dart で
/// 起動直後に await で呼ぶ。`addHeaders(headers, body)` を /protected/* 呼び出し
/// 直前に呼ぶ。
class AppAttestClient {
  AppAttestClient._();
  static final AppAttestClient instance = AppAttestClient._();

  final AppAttestIntegrity _attest = AppAttestIntegrity();
  String? _keyId;
  bool _isInitialized = false;
  bool _isBypassed = false;

  /// 現在の keyId (debug / 監視用)。`null` なら未初期化 or bypass。
  String? get keyId => _keyId;

  /// このプラットフォーム / 実行環境では App Attest を bypass する判定。
  /// - Web は対応不可
  /// - Android は別途 Play Integrity 実装 (本クラスは iOS のみ)
  /// - iOS Simulator は実機鍵がないので bypass
  /// - kDebugMode は開発時の bypass (本番では発火しない)
  bool get _shouldBypass {
    if (kIsWeb) return true;
    if (!Platform.isIOS) return true; // Android は Phase 2 で別実装
    if (kDebugMode) return true; // 実機 release で初めて有効化
    return false;
  }

  /// 起動時 1 回だけ呼ぶ。keyId を復元 or 新規 attest する。
  /// 失敗してもアプリ起動は止めない (= /protected/* 呼び出し時に再試行)。
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (_shouldBypass) {
      _isBypassed = true;
      debugPrint('[AppAttest] bypassed (web/non-iOS/simulator/debug)');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kPrefsKeyId);
      if (saved != null && saved.isNotEmpty) {
        _keyId = saved;
        debugPrint('[AppAttest] restored keyId from prefs (prefix=${saved.substring(0, 8)}...)');
        return;
      }
      // 新規 attest
      await _attestNewKey();
    } catch (e) {
      debugPrint('[AppAttest] initialize failed: $e');
      // bypass mode に倒す (= /protected/* は middleware:log_only 経由で通過)
      _isBypassed = true;
    }
  }

  /// 新規 keyId 生成 + Worker /auth/attest 登録 + SharedPreferences 保存。
  /// 既存 keyId が残っていれば上書きする (= DCError.invalidKey 復旧パス)。
  Future<void> _attestNewKey() async {
    // 1. Worker から challenge 取得 (challenge は base64 string でそのまま使う)
    final chRes = await http.post(Uri.parse(solaraChallengeUrl));
    if (chRes.statusCode != 200) {
      throw Exception('challenge fetch failed: ${chRes.statusCode}');
    }
    final chBody = json.decode(chRes.body) as Map<String, dynamic>;
    final challengeId = chBody['challengeId'] as String;
    final challengeB64 = chBody['challenge'] as String; // server 発行 32B の base64

    // 2. iOS 側で keyPair 生成 + attestation 生成
    // app_attest_integrity 1.0.0 API: iOSgenerateAttestation(String challenge)
    //   → GenerateAttestationResponse? { keyId: String, attestation: String (base64) }
    final result = await _attest.iOSgenerateAttestation(challengeB64);
    if (result == null) {
      throw Exception('iOSgenerateAttestation returned null');
    }
    final newKeyId = result.keyId;
    final attestationB64 = result.attestation;

    // 3. Worker /auth/attest で検証 + 永続化
    final atRes = await http.post(
      Uri.parse(solaraAttestUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'keyId': newKeyId,
        'challengeId': challengeId,
        'attestation': attestationB64, // 既に base64
      }),
    );
    if (atRes.statusCode != 200) {
      throw Exception('attest verify failed: ${atRes.statusCode} ${atRes.body}');
    }

    // 4. 成功 → SharedPreferences に永続化
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKeyId, newKeyId);
    _keyId = newKeyId;
    debugPrint('[AppAttest] new keyId stored (prefix=${newKeyId.substring(0, 8)}...)');
  }

  /// /protected/* 呼び出し直前に header を注入。
  ///
  /// 設計 v1.8 §16.2 payload 規約に従い、`payloadBytes` は HTTP body そのもの
  /// (= jsonEncode した string を utf8.encode した結果) を渡す必要がある。
  /// Worker 側 middleware は `request.arrayBuffer()` で raw bytes を取得して
  /// SHA-256 を計算するので、ここで使う bytes と完全一致が必須。
  ///
  /// bypass 時 (Simulator / debug / 未初期化) は何もしない → Worker 側
  /// log_only モードで通過する想定。enforced モードでは 401 になる。
  Future<void> addHeaders(Map<String, String> headers, List<int> payloadBytes) async {
    if (_isBypassed || _keyId == null) return; // 何もしない
    try {
      // 設計 v1.8 §16.2: Flutter は payloadBytes (= jsonEncode → utf8.encode)
      // を base64 にして clientData として渡す。Worker 側は request.arrayBuffer()
      // で取った raw bytes を SHA-256 するので、payloadBytes と完全一致する bytes
      // を package 内部で SHA-256 → assertion 生成。
      // package 戻り値は assertion (base64 string)。
      final clientDataB64 = base64.encode(payloadBytes);
      final assertionB64 = await _attest.verify(
        clientData: clientDataB64,
        iOSkeyID: _keyId,
      );
      if (assertionB64.isEmpty) throw Exception('verify returned empty string');
      headers['X-AppAttest-KeyId'] = _keyId!;
      headers['X-AppAttest-Assertion'] = assertionB64; // 既に base64
    } catch (e) {
      debugPrint('[AppAttest] addHeaders failed: $e');
      // 失敗時は headers に何も追加しない → Worker 側 enforced なら 401、log_only なら通過
      // (DCError.invalidKey 時の再 attest は呼び出し側のリトライ責任、
      //  Solara では 401 で initialize 再実行 + リトライする設計を別途配線)
    }
  }

  /// `/protected/*` への POST を attestation header 付きで送る wrapper。
  /// 既存 http.post 呼び出しを置換する形で使う:
  ///   旧: await http.post(Uri.parse(solaraFortuneUrl), headers: {...}, body: body);
  ///   新: await AppAttestClient.instance.postProtected(solaraFortuneUrl, payload: bodyMap);
  ///
  /// payload は `Map<String, dynamic>` を渡す (内部で jsonEncode する)。
  /// 設計 v1.8 §16.2 規約: 必ず jsonEncode → utf8.encode で bytes を確定し、
  /// その bytes をそのまま HTTP body にする (中間で変換しない)。
  Future<http.Response> postProtected(
    String url, {
    required Map<String, dynamic> payload,
    Map<String, String>? extraHeaders,
  }) async {
    final bodyString = json.encode(payload);
    final bodyBytes = utf8.encode(bodyString);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?extraHeaders,
    };
    await addHeaders(headers, bodyBytes);
    return http.post(Uri.parse(url), headers: headers, body: bodyBytes);
  }

  /// 401 で middleware に弾かれた時のリトライ用: key 再生成 + 再 attest。
  /// 呼び出し側で `if (res.statusCode == 401 && res.body contains 'attestation_not_registered')`
  /// 等を判定して invoke する想定。
  Future<bool> reattestOnFailure() async {
    if (_shouldBypass) return false;
    try {
      // 既存 keyId を破棄して新規 attest
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPrefsKeyId);
      _keyId = null;
      _isBypassed = false;
      await _attestNewKey();
      return _keyId != null;
    } catch (e) {
      debugPrint('[AppAttest] reattest failed: $e');
      return false;
    }
  }

  /// payload bytes の SHA-256 (debug 用、Worker 側計算値との一致確認に使う)。
  static String debugPayloadSha256(List<int> payloadBytes) {
    return crypto.sha256.convert(payloadBytes).toString();
  }
}

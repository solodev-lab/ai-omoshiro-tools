// Solara App Attest / Play Integrity クライアント (Flutter ↔ Worker /auth/* /protected/*)
//
// 役割:
//   iOS (App Attest):
//     - 起動時に keyId を SharedPreferences から復元、なければ Worker で attest
//     - /protected/* 呼び出し時の HTTP header に X-AppAttest-KeyId/Assertion を付与
//     - DCError.invalidInput/invalidKey 時の key 再生成リトライ
//   Android (Play Integrity Standard、S5 追加):
//     - 起動時に prepareTokenProvider(cloudProjectNumber) で warmup (≈1 時間有効)
//     - /protected/* 呼び出しごとに /auth/integrity/challenge で nonce 取得 →
//       clientData = {nonce, uid, ts} を JSON 化 → verify(clientData) で token 取得 →
//       X-PlayIntegrity-Token / -ClientData / -NonceId をヘッダー注入
//   - iOS Simulator / Web / kDebugMode / Cloud Project Number 未設定では bypass
//
// Worker 側仕様: apps/solara/worker/src/index.js
//   POST /auth/challenge            → {challengeId, challenge: base64(32B), ttlSec}
//   POST /auth/attest               body: {keyId, challengeId, attestation: base64}
//   POST /auth/integrity/challenge  → {nonceId, nonce: base64(32B), ttlSec}  (S4 追加)
//   /protected/* headers (iOS):     X-AppAttest-KeyId, X-AppAttest-Assertion
//   /protected/* headers (Android): X-PlayIntegrity-Token, X-PlayIntegrity-ClientData, X-PlayIntegrity-NonceId
//
// 設計: apps/solara/docs/app_attest_design.md (iOS v2.0+)
//      apps/solara/docs/play_integrity_design.md (Android v0.7+)

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:app_attest_integrity/app_attest_integrity.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'purchases_service.dart';
import 'solara_api.dart';

const String _kPrefsKeyId = 'solara_appattest_key_id_v1';

/// Cloud Project Number — Play Console > Solara > アプリの完全性 > Play Integrity API
/// にリンクした Cloud project の 12 桁数字。release ビルド時に
/// `--dart-define=SOLARA_GCP_PROJECT_NUMBER=...` で注入する (public 情報、secret 不要)。
///
/// 未注入 (= 0) なら Android 経路は bypass (ヘッダー注入せず、Worker 側
/// PLAY_INTEGRITY_ENFORCEMENT=log_only で通過させる前提)。
const int _kCloudProjectNumber =
    int.fromEnvironment('SOLARA_GCP_PROJECT_NUMBER', defaultValue: 0);

/// /protected/* body 内で Worker に App User ID を伝える予約フィールド名
/// (Worker `index.js` の `APP_USER_ID_FIELD` と完全一致)。
const String _kAppUserIdField = '__appUserId';

/// AppAttestClient シングルトン。
///
/// Solara 内で 1 端末あたり 1 keyId (iOS) または warmup 済 TokenProvider (Android) を保持する。
/// `initialize()` は main.dart で起動直後に await で呼ぶ。
/// `addHeaders(headers, body)` または `postProtected(url, payload: ...)` を /protected/* 呼び出し
/// 直前に呼ぶ。
class AppAttestClient {
  AppAttestClient._({AppAttestIntegrity? attest, http.Client? httpClient})
      : _attest = attest ?? const AppAttestIntegrity(),
        _httpClient = httpClient ?? http.Client();

  /// 本番用 singleton。
  static final AppAttestClient instance = AppAttestClient._();

  /// テスト専用コンストラクタ。mock plugin + mock http client を注入できる。
  /// 本番 instance には影響しない。
  @visibleForTesting
  factory AppAttestClient.forTesting({
    AppAttestIntegrity? attest,
    http.Client? httpClient,
  }) =>
      AppAttestClient._(attest: attest, httpClient: httpClient);

  final AppAttestIntegrity _attest;
  final http.Client _httpClient;
  String? _keyId;
  Future<void>? _initFuture;
  bool _isBypassed = false;
  bool _androidPrepared = false;

  /// 現在の keyId (iOS、debug / 監視用)。`null` なら未初期化 or bypass。
  String? get keyId => _keyId;

  /// 現在のプラットフォームが Android Play Integrity 経路を使えるか。
  /// テスト時は `kIsWeb` / `Platform.isAndroid` を直接判定できないため、helper にしておく。
  bool get _isAndroidPath => !kIsWeb && Platform.isAndroid;

  /// 現在のプラットフォームが iOS App Attest 経路を使えるか。
  bool get _isIosPath => !kIsWeb && Platform.isIOS;

  /// iOS / Android 経路を完全に bypass するかの判定。
  /// - Web は両方対応不可
  /// - kDebugMode は両方 bypass (実機 release で初めて有効化)
  /// - iOS Simulator は実機鍵がないので bypass (= Worker log_only で通過)
  /// - Android で Cloud Project Number 未注入 (= 0) なら bypass
  bool get _shouldBypass {
    if (kIsWeb) return true;
    if (kDebugMode) return true;
    if (_isIosPath) return false; // iOS は実機 release のみ有効
    if (_isAndroidPath) {
      // Android は Cloud Project Number が dart-define で注入されている場合のみ有効
      return _kCloudProjectNumber <= 0;
    }
    return true; // 想定外プラットフォーム (Windows/macOS/Linux 等)
  }

  /// 起動時 1 回だけ呼ぶ (main.dart で unawaited)。
  /// - iOS: keyId を復元 or 新規 attest
  /// - Android: prepareTokenProvider(cloudProjectNumber) で warmup
  /// 失敗してもアプリ起動は止めない (= /protected/* 呼び出し時に再試行可)。
  ///
  /// 初回呼び出しの Future を memoize して共有する。addHeaders/postProtected も
  /// 内部でこれを await するため、main.dart で await し忘れても起動直後の
  /// /protected/* 呼び出しが keyId (iOS) / warmup (Android) 完了を待ってから
  /// ヘッダーを注入できる (= 付与漏れによる missing_attestation_headers を防ぐ)。
  Future<void> initialize() => _initFuture ??= _doInitialize();

  Future<void> _doInitialize() async {
    if (_shouldBypass) {
      _isBypassed = true;
      debugPrint(
          '[AppAttest] bypassed (web/debug/simulator/gcp_unset/unsupported)');
      return;
    }

    if (_isIosPath) {
      await _initializeIos();
    } else if (_isAndroidPath) {
      await _initializeAndroid();
    }
  }

  // ── iOS App Attest 初期化 ──────────────────────────────

  Future<void> _initializeIos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kPrefsKeyId);
      if (saved != null && saved.isNotEmpty) {
        _keyId = saved;
        debugPrint(
            '[AppAttest:iOS] restored keyId from prefs (prefix=${saved.substring(0, 8)}...)');
        return;
      }
      await _attestNewKey();
    } catch (e) {
      debugPrint('[AppAttest:iOS] initialize failed: $e');
      _isBypassed = true;
    }
  }

  /// 新規 keyId 生成 + Worker /auth/attest 登録 + SharedPreferences 保存。
  Future<void> _attestNewKey() async {
    final chRes = await _httpClient.post(Uri.parse(solaraChallengeUrl));
    if (chRes.statusCode != 200) {
      throw Exception('challenge fetch failed: ${chRes.statusCode}');
    }
    final chBody = json.decode(chRes.body) as Map<String, dynamic>;
    final challengeId = chBody['challengeId'] as String;
    final challengeB64 = chBody['challenge'] as String;

    final result = await _attest.iOSgenerateAttestation(challengeB64);
    if (result == null) {
      throw Exception('iOSgenerateAttestation returned null');
    }
    final newKeyId = result.keyId;
    final attestationB64 = result.attestation;

    final atRes = await _httpClient.post(
      Uri.parse(solaraAttestUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'keyId': newKeyId,
        'challengeId': challengeId,
        'attestation': attestationB64,
      }),
    );
    if (atRes.statusCode != 200) {
      throw Exception('attest verify failed: ${atRes.statusCode} ${atRes.body}');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKeyId, newKeyId);
    _keyId = newKeyId;
    if (kDebugMode) {
      debugPrint(
          '[AppAttest:iOS] new keyId stored (prefix=${newKeyId.substring(0, 8)}...)');
    }
  }

  // ── Android Play Integrity 初期化 (S5 追加) ────────────────

  Future<void> _initializeAndroid() async {
    try {
      // app_attest_integrity v1.0.0 API: androidPrepareIntegrityServer(int cloudProjectNumber)
      // Standard request の warmup。≈1 時間 valid な StandardIntegrityTokenProvider を保持。
      await _attest.androidPrepareIntegrityServer(_kCloudProjectNumber);
      _androidPrepared = true;
      debugPrint(
          '[AppAttest:Android] prepareTokenProvider OK (cloudProject=$_kCloudProjectNumber)');
    } catch (e) {
      debugPrint('[AppAttest:Android] prepareTokenProvider failed: $e');
      // 失敗してもアプリは起動継続。リクエスト時に verify() 内で再 prepare がかかる
      // (plugin の自動 retry on INTEGRITY_TOKEN_PROVIDER_INVALID) ため致命的ではない。
      _androidPrepared = false;
    }
  }

  // ── ヘッダー注入 (経路自動分岐) ─────────────────────────

  /// /protected/* 呼び出し直前に header を注入。
  ///
  /// iOS 経路:
  ///   `payloadBytes` (= jsonEncode → utf8.encode した HTTP body そのもの) を
  ///   base64 化して clientData として渡し、X-AppAttest-KeyId/Assertion を注入。
  ///
  /// Android 経路 (S5 追加):
  ///   1. /auth/integrity/challenge で nonce 取得
  ///   2. clientData = jsonEncode({nonce, uid, ts}) を構築
  ///   3. verify(clientData) で Play Integrity token 取得
  ///   4. X-PlayIntegrity-Token / -ClientData / -NonceId を注入
  ///
  /// bypass 時 (Simulator / debug / 未初期化 / Cloud Project Number 未設定) は
  /// 何もしない → Worker 側 log_only モードで通過する想定 (enforced では 401)。
  Future<void> addHeaders(
      Map<String, String> headers, List<int> payloadBytes) async {
    // initialize() は main.dart で unawaited に呼ばれるため、ここで完了を待つ。
    // これがないと起動直後の /protected/* 呼び出しが keyId (iOS) / warmup (Android)
    // 未完了のまま走り、ヘッダー欠落 → Worker で missing_attestation_headers に
    // なる (2026-05-21 TestFlight log_only で判明)。memoize 済みなので 2 回目以降は
    // 即 return。
    await initialize();
    if (_isBypassed) return;
    if (_isIosPath) {
      await _addIosHeaders(headers, payloadBytes);
    } else if (_isAndroidPath) {
      await _addAndroidHeaders(headers, payloadBytes);
    }
  }

  Future<void> _addIosHeaders(
      Map<String, String> headers, List<int> payloadBytes) async {
    if (_keyId == null) return;
    try {
      final clientDataB64 = base64.encode(payloadBytes);
      final assertionB64 = await _attest.verify(
        clientData: clientDataB64,
        iOSkeyID: _keyId,
      );
      if (assertionB64.isEmpty) throw Exception('verify returned empty string');
      headers['X-AppAttest-KeyId'] = _keyId!;
      headers['X-AppAttest-Assertion'] = assertionB64;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppAttest:iOS] addHeaders failed: $e');
      }
      // 失敗時は何も注入しない (= Worker enforced なら 401)
    }
  }

  /// Android 経路: nonce 取得 → clientData 構築 → verify() で token 取得。
  /// 設計 v0.7 §7.2 + §4 Step 1-3。
  Future<void> _addAndroidHeaders(
      Map<String, String> headers, List<int> payloadBytes) async {
    try {
      // 1. Worker から nonce 取得
      final chRes = await _httpClient.post(Uri.parse(solaraIntegrityChallengeUrl));
      if (chRes.statusCode != 200) {
        throw Exception('integrity challenge fetch failed: ${chRes.statusCode}');
      }
      final chBody = json.decode(chRes.body) as Map<String, dynamic>;
      final nonceId = chBody['nonceId'] as String;
      final nonce = chBody['nonce'] as String;

      // 2. clientData 構築: nonce + uid + ts を JSON 化
      //    uid は body.__appUserId と同値 (Worker Step 12 で binding 検証)
      final uid = PurchasesService.instance.appUserId ?? '';
      final clientDataMap = <String, dynamic>{
        'nonce': nonce,
        'uid': uid,
        'ts': DateTime.now().millisecondsSinceEpoch,
      };
      final clientDataStr = json.encode(clientDataMap);

      // 3. plugin の verify() で token 取得
      //    plugin 内部で requestHash = base64(sha256(clientData)) を計算
      //    → StandardIntegrityTokenProvider.request(requestHash) で token 取得
      final token = await _attest.verify(clientData: clientDataStr);
      if (token.isEmpty) throw Exception('verify returned empty string');

      // 4. 3 ヘッダー注入
      headers['X-PlayIntegrity-Token'] = token;
      headers['X-PlayIntegrity-ClientData'] = clientDataStr;
      headers['X-PlayIntegrity-NonceId'] = nonceId;

      // payloadBytes は Worker 側 body parse で __appUserId 抽出に使う
      // (Step 12 で clientData.uid と一致確認)。本関数からは参照のみ、変更しない。
      // ignore: unused_local_variable
      final _ = payloadBytes;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppAttest:Android] addHeaders failed: $e');
      }
      // 失敗時は何も注入しない (= Worker enforced なら 401、log_only なら通過)
    }
  }

  /// payload に App User ID を merge した新しい Map を返す (元 Map は破壊しない)。
  static Map<String, dynamic> _withAppUserId(Map<String, dynamic> payload) {
    final merged = <String, dynamic>{...payload};
    final uid = PurchasesService.instance.appUserId;
    if (uid != null && uid.isNotEmpty) {
      merged[_kAppUserIdField] = uid;
    }
    return merged;
  }

  /// 呼び出し側で body Map を構築している場合に使う公開 helper。
  static Map<String, dynamic> withAppUserIdMerged(Map<String, dynamic> payload) {
    return _withAppUserId(payload);
  }

  /// `/protected/*` への POST を attestation header 付きで送る wrapper。
  Future<http.Response> postProtected(
    String url, {
    required Map<String, dynamic> payload,
    Map<String, String>? extraHeaders,
  }) async {
    final merged = _withAppUserId(payload);
    final bodyString = json.encode(merged);
    final bodyBytes = utf8.encode(bodyString);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?extraHeaders,
    };
    await addHeaders(headers, bodyBytes);
    return _httpClient.post(Uri.parse(url), headers: headers, body: bodyBytes);
  }

  /// 401 で middleware に弾かれた時のリトライ用。
  /// - iOS: keyId 再生成 + 再 attest
  /// - Android: prepareTokenProvider 再呼出 (plugin 側で auto-retry もあるが念のため)
  Future<bool> reattestOnFailure() async {
    if (_shouldBypass) return false;
    try {
      if (_isIosPath) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_kPrefsKeyId);
        _keyId = null;
        _isBypassed = false;
        await _attestNewKey();
        return _keyId != null;
      }
      if (_isAndroidPath) {
        _isBypassed = false;
        await _initializeAndroid();
        return _androidPrepared;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppAttest] reattest failed: $e');
      }
      return false;
    }
  }

  /// payload bytes の SHA-256 (debug 用、Worker 側計算値との一致確認に使う)。
  static String debugPayloadSha256(List<int> payloadBytes) {
    return crypto.sha256.convert(payloadBytes).toString();
  }

  /// Cloud Project Number (debug / テスト用、本番では _kCloudProjectNumber と同値)
  @visibleForTesting
  static int get cloudProjectNumberForTest => _kCloudProjectNumber;

  // ── テスト専用 hook ──────────────────────────────────────
  // `flutter test` は host (Windows/macOS) で動くため Platform.isAndroid が
  // false になる。実機 Android 経路の logic をテストするため、forTesting
  // インスタンスでのみ Android logic を直接呼べる public wrapper を提供する。

  /// Android 経路の `_addAndroidHeaders` を直接呼ぶ (テスト専用)。
  @visibleForTesting
  Future<void> addAndroidHeadersForTest(
          Map<String, String> headers, List<int> payloadBytes) =>
      _addAndroidHeaders(headers, payloadBytes);

  /// Android 経路の `_initializeAndroid` を直接呼ぶ (テスト専用)。
  /// Cloud Project Number 0 でも呼べる (= bypass 判定を経由しない)。
  @visibleForTesting
  Future<void> initializeAndroidForTest() => _initializeAndroid();

  /// テスト終了後に内部状態をリセットする (forTesting インスタンス専用)。
  @visibleForTesting
  void resetForTest() {
    _keyId = null;
    _initFuture = null;
    _isBypassed = false;
    _androidPrepared = false;
  }

  /// _androidPrepared の現値 (テスト assertion 用)。
  @visibleForTesting
  bool get androidPreparedForTest => _androidPrepared;
}

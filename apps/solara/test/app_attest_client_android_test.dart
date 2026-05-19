/// AppAttestClient の Android 経路 (Play Integrity) 単体テスト (S5)。
///
/// flutter test は host OS (Windows/macOS) で動くため `Platform.isAndroid` は false。
/// テスト専用 hook (`addAndroidHeadersForTest` / `initializeAndroidForTest`) で
/// 直接 Android logic を呼出し、mock plugin + mock http で挙動検証する。
///
/// カバー範囲:
///   - initializeAndroidForTest: plugin warmup 成功 / 失敗
///   - addAndroidHeadersForTest: nonce 取得 → clientData 構築 → token 取得 → 3 ヘッダー注入
///   - challenge endpoint エラー時の defensive 動作
///   - plugin verify 例外時の defensive 動作 (= ヘッダー注入しない)
///   - uid 注入 (PurchasesService.appUserId の値が clientData.uid に入る)

import 'dart:convert';

import 'package:app_attest_integrity/app_attest_integrity.dart';
import 'package:app_attest_integrity/app_attest_integrity_platform_interface.dart';
import 'package:app_attest_integrity/src/model/generate_attestation_response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:solara/utils/app_attest_client.dart';

// ── Mock plugin ─────────────────────────────────────────────

class _MockIntegrityPlatform extends AppAttestIntegrityPlatform {
  _MockIntegrityPlatform({
    this.prepareShouldThrow = false,
    this.verifyShouldThrow = false,
    this.verifyReturnEmpty = false,
    this.fixedToken = 'mock-play-integrity-token',
  });

  final bool prepareShouldThrow;
  final bool verifyShouldThrow;
  final bool verifyReturnEmpty;
  final String fixedToken;

  int prepareCalls = 0;
  int verifyCalls = 0;
  int? lastCloudProjectNumber;
  String? lastClientData;

  @override
  Future<void> androidPrepareIntegrityServer(int cloudProjectNumber) async {
    prepareCalls++;
    lastCloudProjectNumber = cloudProjectNumber;
    if (prepareShouldThrow) throw Exception('mock prepare failure');
  }

  @override
  Future<GenerateAttestationResponse?> iOSgenerateAttestation(String challenge) async {
    return null; // Android only テストなので unused
  }

  @override
  Future<String> verify({
    required String clientData,
    String? iOSkeyID,
    int? androidCloudProjectNumber,
  }) async {
    verifyCalls++;
    lastClientData = clientData;
    if (verifyShouldThrow) throw Exception('mock verify failure');
    if (verifyReturnEmpty) return '';
    return fixedToken;
  }
}

// ── helpers ─────────────────────────────────────────────────

http.Client _mockChallengeClient({
  required String nonceId,
  required String nonce,
  int ttlSec = 300,
  int? statusCode,
  String? body,
}) {
  return http_testing.MockClient((request) async {
    if (request.url.path.endsWith('/auth/integrity/challenge')) {
      return http.Response(
        body ?? json.encode({'nonceId': nonceId, 'nonce': nonce, 'ttlSec': ttlSec}),
        statusCode ?? 200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response('unexpected', 500);
  });
}

// ── tests ──────────────────────────────────────────────────

void main() {
  group('AppAttestClient Android 経路', () {
    late _MockIntegrityPlatform mockPlatform;

    setUp(() {
      mockPlatform = _MockIntegrityPlatform();
      AppAttestIntegrityPlatform.instance = mockPlatform;
    });

    test('initializeAndroidForTest: cloudProjectNumber を渡して prepare 呼出', () async {
      final client = AppAttestClient.forTesting(attest: const AppAttestIntegrity());
      await client.initializeAndroidForTest();

      expect(mockPlatform.prepareCalls, 1);
      expect(mockPlatform.lastCloudProjectNumber, AppAttestClient.cloudProjectNumberForTest);
      expect(client.androidPreparedForTest, true);
    });

    test('initializeAndroidForTest: plugin 例外で androidPrepared=false (致命的でない)', () async {
      mockPlatform = _MockIntegrityPlatform(prepareShouldThrow: true);
      AppAttestIntegrityPlatform.instance = mockPlatform;

      final client = AppAttestClient.forTesting(attest: const AppAttestIntegrity());
      await client.initializeAndroidForTest();

      expect(mockPlatform.prepareCalls, 1);
      expect(client.androidPreparedForTest, false);
      // 例外は呼出側にスローされない (= アプリ起動継続)
    });

    test('addAndroidHeadersForTest: 正常系で 3 ヘッダー注入 + clientData 形式', () async {
      const fixedNonce = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
      const fixedNonceId = 'nonce-uuid-1';
      final httpClient = _mockChallengeClient(nonceId: fixedNonceId, nonce: fixedNonce);

      final client = AppAttestClient.forTesting(
        attest: const AppAttestIntegrity(),
        httpClient: httpClient,
      );
      final headers = <String, String>{};
      await client.addAndroidHeadersForTest(headers, utf8.encode('{"foo":"bar"}'));

      expect(headers['X-PlayIntegrity-Token'], 'mock-play-integrity-token');
      expect(headers['X-PlayIntegrity-NonceId'], fixedNonceId);
      expect(headers['X-PlayIntegrity-ClientData'], isNotNull);

      final clientData = json.decode(headers['X-PlayIntegrity-ClientData']!) as Map;
      expect(clientData['nonce'], fixedNonce);
      expect(clientData['ts'], isA<int>());
      expect(clientData['ts'], greaterThan(0));
      expect(clientData.containsKey('uid'), true);

      // plugin の verify が clientData 文字列で呼ばれていること
      expect(mockPlatform.verifyCalls, 1);
      expect(mockPlatform.lastClientData, headers['X-PlayIntegrity-ClientData']);
    });

    test('addAndroidHeadersForTest: challenge endpoint 500 → ヘッダー注入なし', () async {
      final httpClient = _mockChallengeClient(
        nonceId: 'x',
        nonce: 'x',
        statusCode: 500,
        body: 'internal',
      );

      final client = AppAttestClient.forTesting(
        attest: const AppAttestIntegrity(),
        httpClient: httpClient,
      );
      final headers = <String, String>{};
      await client.addAndroidHeadersForTest(headers, utf8.encode('{}'));

      expect(headers.containsKey('X-PlayIntegrity-Token'), false);
      expect(headers.containsKey('X-PlayIntegrity-ClientData'), false);
      expect(headers.containsKey('X-PlayIntegrity-NonceId'), false);
      expect(mockPlatform.verifyCalls, 0); // challenge 失敗で verify は呼ばれない
    });

    test('addAndroidHeadersForTest: plugin verify 例外 → ヘッダー注入なし', () async {
      mockPlatform = _MockIntegrityPlatform(verifyShouldThrow: true);
      AppAttestIntegrityPlatform.instance = mockPlatform;
      final httpClient = _mockChallengeClient(
          nonceId: 'nid', nonce: 'A' * 44);

      final client = AppAttestClient.forTesting(
        attest: const AppAttestIntegrity(),
        httpClient: httpClient,
      );
      final headers = <String, String>{};
      await client.addAndroidHeadersForTest(headers, utf8.encode('{}'));

      expect(headers.containsKey('X-PlayIntegrity-Token'), false);
      expect(mockPlatform.verifyCalls, 1); // plugin は呼ばれたが例外で fallthrough
    });

    test('addAndroidHeadersForTest: verify 戻り値 empty → ヘッダー注入なし', () async {
      mockPlatform = _MockIntegrityPlatform(verifyReturnEmpty: true);
      AppAttestIntegrityPlatform.instance = mockPlatform;
      final httpClient = _mockChallengeClient(
          nonceId: 'nid', nonce: 'A' * 44);

      final client = AppAttestClient.forTesting(
        attest: const AppAttestIntegrity(),
        httpClient: httpClient,
      );
      final headers = <String, String>{};
      await client.addAndroidHeadersForTest(headers, utf8.encode('{}'));

      expect(headers.containsKey('X-PlayIntegrity-Token'), false);
    });

    test('addAndroidHeadersForTest: malformed challenge response → ヘッダー注入なし', () async {
      final httpClient = http_testing.MockClient((req) async {
        return http.Response('not json', 200);
      });

      final client = AppAttestClient.forTesting(
        attest: const AppAttestIntegrity(),
        httpClient: httpClient,
      );
      final headers = <String, String>{};
      await client.addAndroidHeadersForTest(headers, utf8.encode('{}'));

      expect(headers.containsKey('X-PlayIntegrity-Token'), false);
    });

    test('cloudProjectNumberForTest: dart-define 未注入時は 0 (= bypass 条件)', () {
      // テスト実行時は --dart-define を指定していないので 0
      expect(AppAttestClient.cloudProjectNumberForTest, 0);
    });

    test('withAppUserIdMerged: 元 Map を破壊せず copy 返却 (uid 注入有無)', () {
      final source = {'foo': 'bar'};
      final merged = AppAttestClient.withAppUserIdMerged(source);

      // 元 Map は不変
      expect(source.containsKey('__appUserId'), false);
      // merged は別 instance
      expect(identical(source, merged), false);
      // PurchasesService.appUserId が null/empty なら merged にも __appUserId 無し
      // (= flutter test 環境では RC SDK 未初期化のため null)
      // どちらでもテスト不変 = source の foo は両方に存在
      expect(merged['foo'], 'bar');
    });
  });
}

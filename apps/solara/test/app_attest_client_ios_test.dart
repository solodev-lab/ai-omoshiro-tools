// AppAttestClient の iOS 経路 (App Attest assertion v3.1 = リクエスト毎チャレンジ) テスト。
//
// flutter test は host OS (Windows/macOS) で動くため Platform.isIOS は false。
// テスト専用 hook addIosHeadersForTest で keyId を注入して _addIosHeaders を直接呼び、
// mock plugin + mock http で挙動検証する。
//
// カバー範囲:
//   - 正常系: /auth/challenge 取得 → clientData JSON 構築 → 4 ヘッダー注入
//   - challenge endpoint エラー時の defensive 動作 (ヘッダー注入しない)
//   - plugin verify 例外 / 戻り値 empty 時の defensive 動作

import 'dart:convert';

import 'package:app_attest_integrity/app_attest_integrity.dart';
import 'package:app_attest_integrity/app_attest_integrity_platform_interface.dart';
import 'package:app_attest_integrity/src/model/generate_attestation_response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:solara/utils/app_attest_client.dart';

class _MockIosPlatform extends AppAttestIntegrityPlatform {
  _MockIosPlatform({
    this.verifyShouldThrow = false,
    this.verifyReturnEmpty = false,
  });

  final bool verifyShouldThrow;
  final bool verifyReturnEmpty;
  static const String fixedAssertion = 'mock-assertion';

  int verifyCalls = 0;
  String? lastClientData;
  String? lastKeyId;

  @override
  Future<void> androidPrepareIntegrityServer(int cloudProjectNumber) async {}

  @override
  Future<GenerateAttestationResponse?> iOSgenerateAttestation(String challenge) async => null;

  @override
  Future<String> verify({
    required String clientData,
    String? iOSkeyID,
    int? androidCloudProjectNumber,
  }) async {
    verifyCalls++;
    lastClientData = clientData;
    lastKeyId = iOSkeyID;
    if (verifyShouldThrow) throw Exception('mock verify failure');
    if (verifyReturnEmpty) return '';
    return fixedAssertion;
  }
}

http.Client _mockChallengeClient({
  required String challengeId,
  required String challenge,
  int? statusCode,
  String? body,
}) {
  return http_testing.MockClient((request) async {
    if (request.url.path.endsWith('/auth/challenge')) {
      return http.Response(
        body ?? json.encode({'challengeId': challengeId, 'challenge': challenge, 'ttlSec': 300}),
        statusCode ?? 200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response('unexpected', 500);
  });
}

void main() {
  group('AppAttestClient iOS 経路 (assertion v3.1)', () {
    late _MockIosPlatform mock;

    setUp(() {
      mock = _MockIosPlatform();
      AppAttestIntegrityPlatform.instance = mock;
    });

    test('正常系: challenge 取得 → clientData 構築 → 4 ヘッダー注入', () async {
      const challengeId = 'ch-uuid-1';
      const challenge = 'HT1fk5pGgpTLNXfAXvtQwA7/vqIxJF0jeUU2fMspqhk=';
      final client = AppAttestClient.forTesting(
        attest: const AppAttestIntegrity(),
        httpClient: _mockChallengeClient(challengeId: challengeId, challenge: challenge),
      );
      final headers = <String, String>{};
      await client.addIosHeadersForTest(headers, utf8.encode('{"foo":"bar"}'), keyId: 'key-abc');

      expect(headers['X-AppAttest-KeyId'], 'key-abc');
      expect(headers['X-AppAttest-Assertion'], 'mock-assertion');
      expect(headers['X-AppAttest-ChallengeId'], challengeId);

      final cd = json.decode(headers['X-AppAttest-ClientData']!) as Map;
      expect(cd['challenge'], challenge);
      expect(cd.containsKey('uid'), true);
      expect(cd['ts'], isA<int>());
      expect(cd['ts'], greaterThan(0));

      // plugin.verify が clientData 文字列 + keyId で呼ばれている
      expect(mock.verifyCalls, 1);
      expect(mock.lastClientData, headers['X-AppAttest-ClientData']);
      expect(mock.lastKeyId, 'key-abc');
    });

    test('challenge endpoint 500 → ヘッダー注入なし', () async {
      final client = AppAttestClient.forTesting(
        attest: const AppAttestIntegrity(),
        httpClient: _mockChallengeClient(
            challengeId: 'x', challenge: 'x', statusCode: 500, body: 'err'),
      );
      final headers = <String, String>{};
      await client.addIosHeadersForTest(headers, utf8.encode('{}'), keyId: 'key-abc');

      expect(headers.containsKey('X-AppAttest-KeyId'), false);
      expect(headers.containsKey('X-AppAttest-ClientData'), false);
      expect(mock.verifyCalls, 0); // challenge 失敗で verify は呼ばれない
    });

    test('plugin verify 例外 → ヘッダー注入なし', () async {
      mock = _MockIosPlatform(verifyShouldThrow: true);
      AppAttestIntegrityPlatform.instance = mock;
      final client = AppAttestClient.forTesting(
        attest: const AppAttestIntegrity(),
        httpClient: _mockChallengeClient(challengeId: 'c', challenge: 'AAAA'),
      );
      final headers = <String, String>{};
      await client.addIosHeadersForTest(headers, utf8.encode('{}'), keyId: 'key-abc');

      expect(headers.containsKey('X-AppAttest-Assertion'), false);
      expect(mock.verifyCalls, 1); // plugin は呼ばれたが例外で fallthrough
    });

    test('verify 戻り値 empty → ヘッダー注入なし', () async {
      mock = _MockIosPlatform(verifyReturnEmpty: true);
      AppAttestIntegrityPlatform.instance = mock;
      final client = AppAttestClient.forTesting(
        attest: const AppAttestIntegrity(),
        httpClient: _mockChallengeClient(challengeId: 'c', challenge: 'AAAA'),
      );
      final headers = <String, String>{};
      await client.addIosHeadersForTest(headers, utf8.encode('{}'), keyId: 'key-abc');

      expect(headers.containsKey('X-AppAttest-Assertion'), false);
    });
  });
}

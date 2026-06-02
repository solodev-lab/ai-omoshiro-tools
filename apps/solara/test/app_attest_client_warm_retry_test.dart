// AppAttestClient の grant 系 degrade→warm リトライ (2026-06-02) 単体テスト。
//
// 背景: CF log 解析で welcome-grant / migrate-purchased が cold/stale warmup 時に
// attestation ヘッダ無しで送信され (= addHeaders の 8s degrade)、Worker が
// missing_attestation_headers を warn していた。対策として「degrade を検知したら
// 本送信の前に warmup を待ってヘッダを付け直す」warmRetryAttach を導入。
//
// flutter test は host (Windows/macOS) で動き実機 attestation を模せない
// (kDebugMode=true → _shouldBypass=true)。よって:
//   - warmRetryAttach: 純ロジックを fake で全分岐検証 (本テストの主目的)
//   - hasAttestationHeader: ヘッダ判定の静的検証
//   - addHeadersWithWarmRetry: bypass 環境で無限リトライしない / ヘッダを付けないことを検証

import 'package:flutter_test/flutter_test.dart';
import 'package:solara/utils/app_attest_client.dart';

void main() {
  group('warmRetryAttach (純ロジック)', () {
    test('1 回目で attach 成功 → warmUp は呼ばれず true', () async {
      var attachCalls = 0;
      var warmCalls = 0;
      final ok = await warmRetryAttach(
        attach: () async {
          attachCalls++;
          return true;
        },
        warmUp: () async {
          warmCalls++;
          return true;
        },
      );
      expect(ok, isTrue);
      expect(attachCalls, 1);
      expect(warmCalls, 0, reason: 'warm path では warmUp/再 attach 不要');
    });

    test('degrade かつ warmUp=false (bypass/間に合わず) → 1 回で諦め false', () async {
      var attachCalls = 0;
      final ok = await warmRetryAttach(
        attach: () async {
          attachCalls++;
          return false;
        },
        warmUp: () async => false,
      );
      expect(ok, isFalse);
      expect(attachCalls, 1, reason: 'warmUp 不可なら再 attach しない');
    });

    test('degrade → warmUp=true → 2 回目 attach 成功 → true (cold→warm)', () async {
      var attachCalls = 0;
      final ok = await warmRetryAttach(
        attach: () async {
          attachCalls++;
          return attachCalls >= 2; // 1 回目 degrade, 2 回目 warm で成功
        },
        warmUp: () async => true,
      );
      expect(ok, isTrue);
      expect(attachCalls, 2);
    });

    test('degrade → warmUp=true → 2 回目も degrade → false (粘らない・最大 2 回)', () async {
      var attachCalls = 0;
      final ok = await warmRetryAttach(
        attach: () async {
          attachCalls++;
          return false;
        },
        warmUp: () async => true,
      );
      expect(ok, isFalse);
      expect(attachCalls, 2, reason: 'attach は最大 2 回 (無限リトライしない)');
    });
  });

  group('hasAttestationHeader', () {
    test('iOS ヘッダがあれば true', () {
      expect(
        AppAttestClient.hasAttestationHeader({'X-AppAttest-KeyId': 'k'}),
        isTrue,
      );
    });

    test('Android ヘッダがあれば true', () {
      expect(
        AppAttestClient.hasAttestationHeader({'X-PlayIntegrity-Token': 't'}),
        isTrue,
      );
    });

    test('Content-Type のみ (degrade) → false', () {
      expect(
        AppAttestClient.hasAttestationHeader(
            {'Content-Type': 'application/json'}),
        isFalse,
      );
    });
  });

  group('addHeadersWithWarmRetry (bypass 環境 = host)', () {
    test('bypass ではヘッダを付けず false を返す (無限リトライしない)', () async {
      // host では _shouldBypass=true (kDebugMode)。ensureWarm が false を返すため
      // 再 attach は走らず、headers に attestation ヘッダは付かない。
      final client = AppAttestClient.forTesting();
      final headers = <String, String>{'Content-Type': 'application/json'};
      final ok = await client.addHeadersWithWarmRetry(
        headers,
        const [1, 2, 3],
        warmupWait: const Duration(milliseconds: 50),
      );
      expect(ok, isFalse);
      expect(AppAttestClient.hasAttestationHeader(headers), isFalse);
      // Content-Type は呼出側が付けたものなので残る
      expect(headers['Content-Type'], 'application/json');
    });

    test('ensureWarm: bypass では即 false', () async {
      final client = AppAttestClient.forTesting();
      final warm = await client.ensureWarm(const Duration(milliseconds: 50));
      expect(warm, isFalse);
    });
  });
}

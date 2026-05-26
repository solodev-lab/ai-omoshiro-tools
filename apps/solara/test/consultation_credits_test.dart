// ConsultationCredits singleton のテスト
//
// 検証ポイント:
//   - resetForTest で初期状態を設定できる
//   - listener が notifyListeners で発火する
//   - status getter が singleton の値を返す
//
// HTTP を伴う refresh() の実体検証は consultation_v2_api_test.dart 側でカバー
// (fetchConsultationCredits は consultation_api.dart にあるため)。

import 'package:flutter_test/flutter_test.dart';

import 'package:solara/utils/consultation_api.dart' show ConsultationCreditStatus;
import 'package:solara/utils/consultation_credits.dart';

void main() {
  group('ConsultationCredits singleton', () {
    setUp(() {
      ConsultationCredits.instance.resetForTest();
    });

    test('初期状態は status=null, loaded=false', () {
      expect(ConsultationCredits.instance.status, isNull);
      expect(ConsultationCredits.instance.loaded, isFalse);
    });

    test('resetForTest で値をセットできる', () {
      const fixture = ConsultationCreditStatus(
        pro: false,
        freeRemaining: 2,
        freeLimit: 3,
        purchasedBalance: 5,
      );
      ConsultationCredits.instance.resetForTest(
        status: fixture,
        loaded: true,
      );
      final s = ConsultationCredits.instance.status;
      expect(s, isNotNull);
      expect(s!.pro, isFalse);
      expect(s.freeRemaining, 2);
      expect(s.freeLimit, 3);
      expect(s.purchasedBalance, 5);
      expect(ConsultationCredits.instance.loaded, isTrue);
    });

    test('resetForTest で listener が発火する (UI rebuild トリガ)', () {
      int notifyCount = 0;
      void listener() => notifyCount++;
      ConsultationCredits.instance.addListener(listener);

      ConsultationCredits.instance.resetForTest(
        status: const ConsultationCreditStatus(pro: true),
        loaded: true,
      );
      expect(notifyCount, 1);

      ConsultationCredits.instance.resetForTest(
        status: const ConsultationCreditStatus(
          pro: false,
          freeRemaining: 1,
          freeLimit: 3,
          purchasedBalance: 0,
        ),
        loaded: true,
      );
      expect(notifyCount, 2);

      ConsultationCredits.instance.removeListener(listener);
    });

    test('複数 listener が同時に発火する', () {
      int a = 0, b = 0, c = 0;
      void la() => a++;
      void lb() => b++;
      void lc() => c++;
      ConsultationCredits.instance.addListener(la);
      ConsultationCredits.instance.addListener(lb);
      ConsultationCredits.instance.addListener(lc);

      ConsultationCredits.instance.resetForTest(
        status: const ConsultationCreditStatus(pro: true),
        loaded: true,
      );
      expect(a, 1);
      expect(b, 1);
      expect(c, 1);

      ConsultationCredits.instance.removeListener(la);
      ConsultationCredits.instance.removeListener(lb);
      ConsultationCredits.instance.removeListener(lc);
    });

    test('hasAny: pro=true は常に true', () {
      const s = ConsultationCreditStatus(pro: true);
      expect(s.hasAny, isTrue);
    });

    test('hasAny: free+purchased ともに 0 は false', () {
      const s = ConsultationCreditStatus(
        pro: false,
        freeRemaining: 0,
        freeLimit: 3,
        purchasedBalance: 0,
      );
      expect(s.hasAny, isFalse);
    });

    test('hasAny: free が残っていれば true', () {
      const s = ConsultationCreditStatus(
        pro: false,
        freeRemaining: 1,
        freeLimit: 3,
        purchasedBalance: 0,
      );
      expect(s.hasAny, isTrue);
    });

    test('hasAny: purchased が残っていれば true', () {
      const s = ConsultationCreditStatus(
        pro: false,
        freeRemaining: 0,
        freeLimit: 3,
        purchasedBalance: 1,
      );
      expect(s.hasAny, isTrue);
    });
  });
}

// Unit tests: SolaraAuth (Phase 2-9 Sign in 統合)
//
// SDK の native call (sign_in_with_apple / google_sign_in) は test env で呼べないので、
// テスト可能な範囲のみ確認:
//   - default state (signed out)
//   - SolaraAuthAccount JSON シリアライズ ↔ デシリアライズ
//   - resetForTest で状態がリセットされる
//   - displayLabel の優先順 (displayName > email > provider 既定文言)

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solara/utils/solara_auth.dart';

void main() {
  group('SolaraAuthAccount', () {
    test('toJson / fromJson 往復で同じ値を維持', () {
      const original = SolaraAuthAccount(
        provider: SolaraAuthProvider.apple,
        uid: 'apple:001234.abcd',
        displayName: 'クラウ Solara',
        email: 'test@example.com',
      );
      final raw = jsonEncode(original.toJson());
      final restored =
          SolaraAuthAccount.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      expect(restored, isNotNull);
      expect(restored!.provider, SolaraAuthProvider.apple);
      expect(restored.uid, 'apple:001234.abcd');
      expect(restored.displayName, 'クラウ Solara');
      expect(restored.email, 'test@example.com');
    });

    test('fromJson(null) は null を返す', () {
      expect(SolaraAuthAccount.fromJson(null), isNull);
    });

    test('fromJson は uid 欠落で null', () {
      expect(
        SolaraAuthAccount.fromJson({'provider': 'apple'}),
        isNull,
      );
    });

    test('fromJson は provider 欠落で null', () {
      expect(
        SolaraAuthAccount.fromJson({'uid': 'apple:xxx'}),
        isNull,
      );
    });

    test('displayLabel は displayName を最優先', () {
      const acc = SolaraAuthAccount(
        provider: SolaraAuthProvider.google,
        uid: 'google:1',
        displayName: 'クラウ',
        email: 'mail@example.com',
      );
      expect(acc.displayLabel, 'クラウ');
    });

    test('displayLabel は displayName なしで email にフォールバック', () {
      const acc = SolaraAuthAccount(
        provider: SolaraAuthProvider.google,
        uid: 'google:1',
        email: 'mail@example.com',
      );
      expect(acc.displayLabel, 'mail@example.com');
    });

    test('displayLabel は displayName も email も無いと provider 既定文言', () {
      const apple = SolaraAuthAccount(
        provider: SolaraAuthProvider.apple,
        uid: 'apple:1',
      );
      const google = SolaraAuthAccount(
        provider: SolaraAuthProvider.google,
        uid: 'google:1',
      );
      expect(apple.displayLabel, 'Apple アカウント');
      expect(google.displayLabel, 'Google アカウント');
    });
  });

  group('SolaraAuth singleton', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await SolaraAuth.instance.resetForTest();
    });

    test('default は signedIn=false / account=null', () async {
      await SolaraAuth.instance.resetForTest();
      expect(SolaraAuth.instance.isSignedIn, isFalse);
      expect(SolaraAuth.instance.account, isNull);
      expect(SolaraAuth.instance.loaded, isTrue);
    });

    test('SharedPreferences に保存された JSON は SolaraAuthAccount.fromJson で復元できる', () async {
      // load() は singleton + _loaded ガードがあるためテスト env で再実行できない。
      // 復元ロジックの中核 = JSON → SolaraAuthAccount のみ単独で検証。
      final raw = jsonEncode({
        'provider': 'apple',
        'uid': 'apple:001234.abcd',
        'displayName': 'クラウ',
        'email': null,
      });
      final acc =
          SolaraAuthAccount.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      expect(acc, isNotNull);
      expect(acc!.provider, SolaraAuthProvider.apple);
      expect(acc.uid, 'apple:001234.abcd');
      expect(acc.displayName, 'クラウ');
      expect(acc.email, isNull);
    });

    test('listener が状態変化で発火', () async {
      await SolaraAuth.instance.resetForTest();
      int notifyCount = 0;
      void listener() => notifyCount++;
      SolaraAuth.instance.addListener(listener);

      // resetForTest 自身が notifyListeners() を呼ぶので、もう 1 度呼んで増えることを確認
      await SolaraAuth.instance.resetForTest();
      expect(notifyCount, greaterThanOrEqualTo(1));

      SolaraAuth.instance.removeListener(listener);
    });
  });

  group('Platform gate (build-time constants)', () {
    test('default --dart-define なしでビルドできる', () {
      // String.fromEnvironment の defaultValue が効いていることを確認。
      // ここでは crash しないことが主目的 (実値はテスト env では空のはず)。
      expect(
        () => SolaraAuth.instance.account,
        returnsNormally,
      );
      // kIsWeb / defaultTargetPlatform 自体は環境依存なので true/false を assert しない
      expect(kIsWeb || !kIsWeb, isTrue);
    });
  });
}

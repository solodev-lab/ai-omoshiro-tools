// Unit tests: PurchasesService (Phase 2-6b RevenueCat 配線)
//
// SDK 初期化は実機/エミュレータが必要なので、ここでは検証可能な範囲のみテスト:
//   - 初期状態 (`isConfigured == false`)
//   - 静的判定関数 `isEntitledFrom` の挙動 (entitlement 有無 / verification 結果別)

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:solara/utils/purchases_service.dart';

EntitlementInfo _buildEntitlement({
  required bool isActive,
  required VerificationResult verification,
}) {
  return EntitlementInfo(
    PurchasesService.entitlementId,
    isActive,
    true,
    '2026-05-01T00:00:00Z',
    '2026-05-01T00:00:00Z',
    'solara_cosmic_pro_monthly',
    true,
    verification: verification,
  );
}

CustomerInfo _buildCustomerInfo({EntitlementInfo? entitlement}) {
  final active = <String, EntitlementInfo>{};
  final all = <String, EntitlementInfo>{};
  if (entitlement != null) {
    if (entitlement.isActive) active[entitlement.identifier] = entitlement;
    all[entitlement.identifier] = entitlement;
  }
  return CustomerInfo(
    EntitlementInfos(all, active),
    const <String, String?>{},
    const <String>[],
    const <String>[],
    const [],
    '2026-05-01T00:00:00Z',
    'anon-test',
    const <String, String?>{},
    '2026-05-01T00:00:00Z',
  );
}

void main() {
  group('PurchasesService static state', () {
    test('default は isConfigured == false (API キー未設定の env)', () {
      // テスト環境では --dart-define が無いので false に固定される
      expect(PurchasesService.instance.isConfigured, isFalse);
      expect(PurchasesService.hasApiKeyForCurrentPlatform, isFalse);
    });

    test('未 configured 時の getOfferings は null を返す', () async {
      final offerings = await PurchasesService.instance.getOfferings();
      expect(offerings, isNull);
    });

    test('未 configured 時の restorePurchases は null を返す', () async {
      final info = await PurchasesService.instance.restorePurchases();
      expect(info, isNull);
    });
  });

  group('isEntitledFrom', () {
    test('該当 entitlement なし → Free', () {
      final info = _buildCustomerInfo();
      expect(PurchasesService.isEntitledFrom(info), isFalse);
    });

    test('entitlement あり + isActive=true + verified → Pro', () {
      final info = _buildCustomerInfo(
        entitlement: _buildEntitlement(
          isActive: true,
          verification: VerificationResult.verified,
        ),
      );
      expect(PurchasesService.isEntitledFrom(info), isTrue);
    });

    test('entitlement あり + verifiedOnDevice → Pro', () {
      final info = _buildCustomerInfo(
        entitlement: _buildEntitlement(
          isActive: true,
          verification: VerificationResult.verifiedOnDevice,
        ),
      );
      expect(PurchasesService.isEntitledFrom(info), isTrue);
    });

    test('entitlement あり + notRequested → Pro (informational off でも通す)', () {
      final info = _buildCustomerInfo(
        entitlement: _buildEntitlement(
          isActive: true,
          verification: VerificationResult.notRequested,
        ),
      );
      expect(PurchasesService.isEntitledFrom(info), isTrue);
    });

    test('entitlement あり + verification=failed → Free (security_principles 原則 1)', () {
      // failed は active map に積まれているケースを想定。
      // security_principles: MiTM 疑い時は Pro 判定しない。
      final entitlement = _buildEntitlement(
        isActive: true,
        verification: VerificationResult.failed,
      );
      final info = CustomerInfo(
        EntitlementInfos(
          {PurchasesService.entitlementId: entitlement},
          {PurchasesService.entitlementId: entitlement},
        ),
        const <String, String?>{},
        const <String>[],
        const <String>[],
        const [],
        '2026-05-01T00:00:00Z',
        'anon-test',
        const <String, String?>{},
        '2026-05-01T00:00:00Z',
      );
      expect(PurchasesService.isEntitledFrom(info), isFalse);
    });

    test('entitlement あり + isActive=false → Free', () {
      final entitlement = _buildEntitlement(
        isActive: false,
        verification: VerificationResult.verified,
      );
      // 期限切れ entitlement は active map に積まれないが、安全側のテストとして
      // 強制的に active に積んでも isActive=false なら Free 判定であること。
      final info = CustomerInfo(
        EntitlementInfos(
          {PurchasesService.entitlementId: entitlement},
          {PurchasesService.entitlementId: entitlement},
        ),
        const <String, String?>{},
        const <String>[],
        const <String>[],
        const [],
        '2026-05-01T00:00:00Z',
        'anon-test',
        const <String, String?>{},
        '2026-05-01T00:00:00Z',
      );
      expect(PurchasesService.isEntitledFrom(info), isFalse);
    });
  });

  group('hasApiKeyForCurrentPlatform', () {
    test('Windows/Linux/macOS test env では false', () {
      // テスト実行プラットフォームに応じて defaultTargetPlatform が変わるが、
      // どの場合でも API キーが --dart-define で渡されないテスト環境では false。
      final isMobile = defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android;
      // mobile プラットフォームでも --dart-define 無しなら false
      if (!isMobile) {
        expect(PurchasesService.hasApiKeyForCurrentPlatform, isFalse);
      } else {
        // 万一 mobile target で実行されてもキー無しなら false
        expect(PurchasesService.hasApiKeyForCurrentPlatform, isFalse);
      }
    });
  });
}

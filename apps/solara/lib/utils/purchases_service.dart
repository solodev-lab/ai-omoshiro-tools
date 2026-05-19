// Solara RevenueCat ラッパー — Phase 2-6b
//
// 設計:
//   - launch_checklist Phase 2「サブスク基盤」
//   - project_solara_security_principles 原則 1「クライアント単独 isPro 禁止」
//   - pro_candidates §7.2 Phase 2-6b
//
// 役割:
//   - purchases_flutter 10.x を init し、entitlement 更新で ProStatus.setPro を呼ぶ
//   - Offerings / 購入 / 復元 の API を 1 箇所に集約
//   - API キー未設定 / 未対応 OS では no-op (DEV トグルにフォールバック)
//
// 🔴 RevenueCat 「.enforced」モードは現行 SDK には無い (.disabled / .informational のみ)。
//    本クラスでは informational で SDK 検証を有効化し、`verification == failed` の時は
//    Pro 判定しない方式で security_principles 原則 1 を担保する。
//    将来 Worker 側 /auth/whoami が出来たら、API 呼出時にサーバ再検証で二重チェックする。
//
// 🔴 Sign in with Apple/Google の uid 連携 (Purchases.logIn) は Phase 2「Sign in 統合」で実装。
//    本フェーズでは anonymous appUserID で運用 (公開前に必ず Sign in を入れる)。
//
// 🔴 API キーは --dart-define で渡す (リポジトリにコミットしない):
//    --dart-define=SOLARA_RC_IOS_KEY=appl_xxxx
//    --dart-define=SOLARA_RC_ANDROID_KEY=goog_xxxx
//    未設定なら configure をスキップし `isConfigured = false`。

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import 'pro_status.dart';

class PurchasesService {
  PurchasesService._();

  static final PurchasesService instance = PurchasesService._();

  /// RevenueCat 上の Pro エンタイトルメント識別子。
  /// ダッシュボードで `cosmic_pro` を作成し、サブスクプロダクトを紐づける前提。
  static const String entitlementId = 'cosmic_pro';

  /// --dart-define で渡される iOS 用 API キー (appl_ プレフィックス)。
  static const String _iosApiKey =
      String.fromEnvironment('SOLARA_RC_IOS_KEY', defaultValue: '');

  /// --dart-define で渡される Android 用 API キー (goog_ プレフィックス)。
  static const String _androidApiKey =
      String.fromEnvironment('SOLARA_RC_ANDROID_KEY', defaultValue: '');

  bool _configured = false;
  bool _initStarted = false;
  CustomerInfoUpdateListener? _listener;

  /// 現在の RevenueCat appUserID。configure 後に cache、logIn/logOut で更新。
  /// 未 configure or 取得失敗時は null。
  ///
  /// 形式:
  ///   - sign in 済み: "apple:xxx" / "google:xxx" (SolaraAuth が `Purchases.logIn` 経由でセット)
  ///   - anonymous   : "$RCAnonymousID:xxxx" (RevenueCat SDK が自動発行)
  ///
  /// この値が Worker 側 /protected/* 呼出時に body `__appUserId` として送られ、
  /// middleware が DO `user_entitlements` から Pro 状態を引き当てる。
  String? _currentAppUserId;
  String? get appUserId => _currentAppUserId;

  /// `Purchases.configure` 済かどうか。UI 側で「ストア準備中」表示の分岐に使う。
  bool get isConfigured => _configured;

  /// 対象 OS で API キーが揃っているか (init() 呼ぶ前でも判定可能)。
  static bool get hasApiKeyForCurrentPlatform {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosApiKey.isNotEmpty;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidApiKey.isNotEmpty;
    }
    return false;
  }

  /// 起動時に 1 度だけ呼ぶ。
  ///
  /// - API キー未設定 / iOS/Android 以外 (Windows/macOS/Web/Linux) ではスキップ
  /// - Trusted Entitlements は informational モードで設定 (SDK 内検証)
  /// - addCustomerInfoUpdateListener で entitlement 変化を ProStatus に同期
  Future<void> init() async {
    if (_initStarted) return;
    _initStarted = true;

    if (!hasApiKeyForCurrentPlatform) {
      if (kDebugMode) {
        debugPrint(
            '[PurchasesService] API キー未設定。configure をスキップ (DEV トグルにフォールバック)');
      }
      return;
    }

    try {
      final apiKey = defaultTargetPlatform == TargetPlatform.iOS
          ? _iosApiKey
          : _androidApiKey;

      final config = PurchasesConfiguration(apiKey)
        ..entitlementVerificationMode = EntitlementVerificationMode.informational
        // Sign in 統合 (Phase 2 後半) までは anonymous appUserID で運用。
        // logIn(uid) を呼んだ瞬間に anonymous → 永続 ID に切替わる。
        ..appUserID = null;

      await Purchases.configure(config);
      _configured = true;

      // anonymous appUserID を cache (SDK が "$RCAnonymousID:xxx" を発行している)
      try {
        _currentAppUserId = await Purchases.appUserID;
      } catch (_) {
        _currentAppUserId = null;
      }

      _listener = _onCustomerInfo;
      Purchases.addCustomerInfoUpdateListener(_listener!);

      // 起動時の現在状態を ProStatus に反映 (キャッシュされていれば即返る)。
      try {
        final info = await Purchases.getCustomerInfo();
        _onCustomerInfo(info);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[PurchasesService] getCustomerInfo 失敗: $e');
        }
      }
    } catch (e, st) {
      // SDK 初期化失敗時は Free 扱いで継続。DEV トグルがあれば手動切替可。
      if (kDebugMode) {
        debugPrint('[PurchasesService] configure 失敗: $e\n$st');
      }
      _configured = false;
    }
  }

  /// CustomerInfo の更新で呼ばれる。entitlement の有効性を ProStatus に同期。
  void _onCustomerInfo(CustomerInfo info) {
    final entitled = isEntitledFrom(info);
    // ProStatus.setPro は SharedPreferences 永続化 + listener 通知 (UI 即時更新)。
    // unawaited で起動するが、setState 呼出は listener 経由で安全。
    // ignore: discarded_futures
    ProStatus.instance.setPro(entitled);
  }

  /// `CustomerInfo` から Solara Pro エンタイトルメントが有効かを判定。
  ///
  /// - 該当エンタイトルメントが無い → false (Free)
  /// - `isActive == false` (期限切れ / 解約済) → false
  /// - `verification == failed` (MiTM 疑い) → false ← security_principles 原則 1
  /// - 上記以外 (verified / verifiedOnDevice / notRequested) → true
  @visibleForTesting
  static bool isEntitledFrom(CustomerInfo info) {
    final entitlement = info.entitlements.active[entitlementId];
    if (entitlement == null) return false;
    if (!entitlement.isActive) return false;
    if (entitlement.verification == VerificationResult.failed) return false;
    return true;
  }

  /// 配信中の Offerings を取得。未配信 / オフライン時は null。
  /// ペイウォールが「準備中」表示に切替えるためのフック。
  Future<Offerings?> getOfferings() async {
    if (!_configured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PurchasesService] getOfferings 失敗: $e');
      }
      return null;
    }
  }

  /// パッケージを購入。成功時は listener 経由で ProStatus が更新される。
  /// 戻り値: 成功なら CustomerInfo、ユーザーキャンセル / 失敗なら null。
  Future<CustomerInfo?> purchasePackage(Package package) async {
    if (!_configured) return null;
    try {
      final result =
          await Purchases.purchase(PurchaseParams.package(package));
      return result.customerInfo;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        // ユーザーが意図的にキャンセル → エラー表示せず null
        return null;
      }
      if (kDebugMode) {
        debugPrint('[PurchasesService] purchase 失敗: $code / $e');
      }
      rethrow;
    }
  }

  /// 復元。RevenueCat が同一 appUserID 配下の過去購入を再リンクする。
  /// 戻り値: 成功時 CustomerInfo、失敗 / 未設定時 null。
  Future<CustomerInfo?> restorePurchases() async {
    if (!_configured) return null;
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PurchasesService] restorePurchases 失敗: $e');
      }
      rethrow;
    }
  }

  /// Sign in 完了後に uid を渡す (`SolaraAuth._commitAccount` から呼ばれる)。
  /// RevenueCat 側で anonymous → 永続 uid に切替わり、Worker 側 entitlement の
  /// キーも切替わる。
  Future<void> logIn(String uid) async {
    if (!_configured) return;
    await Purchases.logIn(uid);
    _currentAppUserId = uid;
  }

  /// サインアウト時に呼ぶ。SDK が新しい anonymous uid を発行するので再 cache。
  Future<void> logOut() async {
    if (!_configured) return;
    await Purchases.logOut();
    try {
      _currentAppUserId = await Purchases.appUserID;
    } catch (_) {
      _currentAppUserId = null;
    }
  }

  /// テスト用: 純粋関数 `isEntitledFrom` は静的なので直接呼べる。
  /// この dispose は本番では呼ばないが、widget test のクリーンアップ用。
  @visibleForTesting
  void disposeForTest() {
    if (_listener != null) {
      Purchases.removeCustomerInfoUpdateListener(_listener!);
      _listener = null;
    }
    _configured = false;
    _initStarted = false;
  }
}

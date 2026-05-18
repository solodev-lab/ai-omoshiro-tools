// Solara 法務リンク定数 — Phase 2-6b
//
// 設計: docs/legal.md + launch_checklist Phase 0 (法的書類)
//
// 役割:
//   - プライバシーポリシー / 利用規約 (EULA) / 特定商取引法に基づく表記 / 解約案内 の URL を一元化
//   - 公開ブロッカー B5 (3.1.2): ペイウォールから EULA / プライバシーをクリック可能リンクで提示するため
//
// 現状 (2026-05-18):
//   - 3 文書は solodev-lab.com 配下に静的公開 (legal/solara/ 配下)
//   - 公開前に同じ URL に本物を up すれば、コード変更ゼロで反映される
//   - 「解約方法」は iOS=設定アプリ deep link / Android=Play Store 該当ページ
//     (どちらも `url_launcher.launchUrl(mode: externalApplication)` で開く)
//
// 🔴 特商法表記は Platform 分岐:
//   - iOS = 個人事業主 林宏治 名義 (scta-ios.html)
//   - Android = 法人 arrayu 株式会社 名義 (scta-android.html)
//   - App Store と Google Play Developer Program の登録名義が異なるため両ストア審査の整合を取る
//
// 🔴 launch_checklist 連動:
//   - Phase 0 完了時に同 URL に文書を公開してから審査提出する
//   - Phase 0 未完で本番ビルドを出すと審査リジェクト (B5)、絶対に飛ばさない
//
// 🔴 i18n:
//   - 当面 ja-JP のみ。ストアアップ前最終工程で EN 版 URL を追加 (feedback_i18n_last)

import 'dart:io' show Platform;

abstract class LegalUrls {
  static const String _base = 'https://solodev-lab.com/legal/solara';

  /// プライバシーポリシー (ja-JP)。両ストア共通。
  static const String privacyPolicy = '$_base/privacy.html';

  /// 利用規約 / EULA (ja-JP)。両ストア共通。
  static const String termsOfService = '$_base/terms.html';

  /// 特定商取引法に基づく表記 (ja-JP、課金あり時必須)。
  /// Platform で出し分け:
  ///   iOS     → 個人事業主 林宏治 名義 (Apple Developer = Individual)
  ///   Android → 法人 arrayu 株式会社 名義 (Google Play = Organization)
  static String get specifiedCommercialTransactions =>
      Platform.isIOS ? '$_base/scta-ios.html' : '$_base/scta-android.html';

  /// 「解約方法」案内ページ (アプリ内 fallback 用)。
  static const String howToCancel = '$_base/cancel.html';

  /// iOS Subscriptions 設定への deep link。
  /// Apple 推奨 (Apple Developer Documentation: "Subscription management URLs")。
  static const String iosSubscriptionsDeepLink =
      'https://apps.apple.com/account/subscriptions';

  /// Google Play Subscriptions 設定 (パッケージ名指定可、ここは一般トップ)。
  static const String androidSubscriptionsDeepLink =
      'https://play.google.com/store/account/subscriptions';
}

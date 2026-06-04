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
// 🔴 i18n (2026-06-04 言語別サブフォルダ化):
//   - 各文書は /{lang}/ サブフォルダ配下に置く (例: /legal/solara/en/privacy.html,
//     /legal/solara/ja/privacy.html)。表示言語 (AppLocale.resolvedCode) で出し分け。
//   - _hostedLangs に列挙した言語のみ実在。未ホスト言語は 'en' にフォールバック。
//   - 🔴 公開前に en/ + ja/ 配下へ実ファイルを設置すること (B5 ブロッカー)。新言語は
//     ページ公開 + _hostedLangs に languageCode 追加。英語=ストア提出のプライマリ。

import 'dart:io' show Platform;

import 'app_locale.dart';

abstract class LegalUrls {
  static const String _base = 'https://solodev-lab.com/legal/solara';

  /// 法務ページをホスト済みの言語サブフォルダ。新言語の法務ページを公開したら
  /// ここに languageCode を追加する。未ホスト言語は英語 ('en') にフォールバック。
  static const Set<String> _hostedLangs = {'en', 'ja'};

  /// 現在の表示言語に対応する法務ページのサブフォルダ ('en'/'ja'/...)。
  /// AppLocale の解決言語 (端末追従 or override) を使い、未ホストは 'en'。
  static String _lang() {
    final code = AppLocale.instance.resolvedCode;
    return _hostedLangs.contains(code) ? code : 'en';
  }

  /// プライバシーポリシー。両ストア共通。言語別 (/{lang}/privacy.html)。
  static String get privacyPolicy => '$_base/${_lang()}/privacy.html';

  /// 利用規約 / EULA。両ストア共通。言語別。
  static String get termsOfService => '$_base/${_lang()}/terms.html';

  /// 特定商取引法に基づく表記 (課金あり時必須)。言語別 + Platform で出し分け:
  ///   iOS     → 個人事業主 林宏治 名義 (Apple Developer = Individual)
  ///   Android → 法人 arrayu 株式会社 名義 (Google Play = Organization)
  static String get specifiedCommercialTransactions =>
      '$_base/${_lang()}/${Platform.isIOS ? 'scta-ios' : 'scta-android'}.html';

  /// 「解約方法」案内ページ (アプリ内 fallback 用)。言語別。
  static String get howToCancel => '$_base/${_lang()}/cancel.html';

  /// アカウント削除のお手続き案内ページ。言語別。
  /// Google Play Console > Data Safety form の "Account deletion URL" には
  /// 英語版 ($_base/en/delete-account.html) を提出する (2024 から義務化)。Apple は
  /// 別途 App Privacy 質問票で「アプリ内で削除可能」と申告 (sanctuary_account_section.dart)。
  /// 設計根拠: docs/store_compliance.md §3.5
  static String get accountDeletion => '$_base/${_lang()}/delete-account.html';

  /// iOS Subscriptions 設定への deep link。
  /// Apple 推奨 (Apple Developer Documentation: "Subscription management URLs")。
  static const String iosSubscriptionsDeepLink =
      'https://apps.apple.com/account/subscriptions';

  /// Google Play Subscriptions 設定 (パッケージ名指定可、ここは一般トップ)。
  static const String androidSubscriptionsDeepLink =
      'https://play.google.com/store/account/subscriptions';
}

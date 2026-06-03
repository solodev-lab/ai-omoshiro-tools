import 'app_locale.dart';

// ════════════════════════════════════════════════════════════
// Solara 軽量 i18n
//
// 正典語彙は docs/i18n_glossary.md。本ファイルの _strings はそれと一致させる。
// .arb / intl は未導入 (別フェーズ)。当面はこの key→(ja,en) テーブルで賄う。
//
// 🔴 EN 表示の条件: AppLocale の override が 'en' のときだけ (= アプリ内の
//    言語切替で明示的に English にしたとき)。端末が英語でも override 未設定なら
//    日本語のまま。理由: EN カバレッジが未完なので、system 連動にすると
//    「半分英語・半分日本語」の UI を system-en ユーザーに見せてしまうため。
//    EN が出揃ったら isEnLocale() を system 連動へ切り替えればよい。
//    (この仕様により flutter test も override 未設定=日本語で安定する。)
// ════════════════════════════════════════════════════════════

/// 現在 English 表示にすべきか。AppLocale override == 'en' のときのみ true。
bool isEnLocale() => AppLocale.instance.notifier.value?.languageCode == 'en';

/// 内部カテゴリ id → 語彙キー (concept)。
/// Map/Horo/Observe/Forecast で id 表記が揺れる (all/overall, work/career) のを吸収。
const Map<String, String> _categoryConcept = {
  'all': 'overall', 'overall': 'overall',
  'healing': 'healing',
  'money': 'abundance',
  'love': 'love',
  'work': 'work', 'career': 'work',
  'communication': 'talk',
  'newStart': 'change',
};

/// 正典語彙テーブル: key → (ja, en)。docs/i18n_glossary.md と一致させること。
const Map<String, (String ja, String en)> _strings = {
  // ── カテゴリ (§1) ──
  'category.overall': ('総合', 'Overall'),
  'category.healing': ('癒し', 'Healing'),
  'category.abundance': ('豊かさ', 'Abundance'), // 🔴 Money/Wealth 禁止
  'category.love': ('恋愛', 'Love'),
  'category.work': ('仕事', 'Work'),
  'category.talk': ('話す', 'Talk'),
  'category.change': ('変化', 'Change'),

  // ── 正典ディスクレーマ (§6.3) ──
  'disclaimer.ai': (
    '✦ AI 生成・娯楽目的。医療・法律・金融等の専門的な助言ではありません。',
    '✦ AI-generated, for entertainment & self-reflection. '
        'Not professional medical, legal, or financial advice.',
  ),
  'disclaimer.fetchFailed': (
    '解説の取得に失敗しました。通信状況を確認して、もう一度お試しください。',
    "We couldn't load the reading. Please check your connection and try again.",
  ),
  'common.tryAgain': ('再試行', 'Try again'),
};

/// key → 現在ロケールの文字列。未登録キーは key をそのまま返す (開発時に気づける)。
String tr(String key) {
  final pair = _strings[key];
  if (pair == null) return key;
  return isEnLocale() ? pair.$2 : pair.$1;
}

/// 内部カテゴリ id (all/overall/healing/money/love/work/career/communication/newStart)
/// → ローカライズ表示名。未知の id はそのまま返す。
String categoryLabel(String id) {
  final concept = _categoryConcept[id];
  return concept != null ? tr('category.$concept') : id;
}

import '../i18n/strings.g.dart' as i18n;

// ════════════════════════════════════════════════════════════
// Solara i18n ファサード (slang バックエンド)
//
// 正典語彙は docs/i18n_glossary.md。実際の対訳は lib/i18n/<locale>.i18n.json。
// 型安全アクセスは `t.category.overall` (import '../i18n/strings.g.dart')。
// 本ファイルは「動的キー tr(key)」と「カテゴリ id 吸収」の薄いファサードのみ提供する。
//
// 🔴 EN 表示の完成度ゲート (正典「半英語UIを出さない」): 現在ロケールは
//    app_locale.dart が AppLocale(override) → slang LocaleSettings へ橋渡しする。
//    Phase 0 では override=='en' のときだけ LocaleSettings が en になる
//    (端末が英語でも override 未設定なら ja)。EN カバレッジが
//    `dart run slang analyze` で 0 未訳になったら、app_locale.dart の
//    ゲートを system 連動 (useDeviceLocale) へ広げる。
// ════════════════════════════════════════════════════════════

/// 現在 English 表示にすべきか。slang の現在ロケールが en のとき true。
bool isEnLocale() => i18n.LocaleSettings.currentLocale == i18n.AppLocale.en;

/// API へ送る言語コード ('ja' / 'en' / 将来 'es' 等)。Worker の lang パラメータの
/// 単一の真実源。AI エンドポイント (fortune/tarot/consultation/relocation) はこれを使う。
String currentLang() => i18n.LocaleSettings.currentLocale.languageCode;

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

/// key → 現在ロケールの文字列。未登録キーは key をそのまま返す (開発時に気づける)。
/// slang の flat map に委譲 (fallback_strategy=base_locale なので en 未訳は ja に落ちる)。
String tr(String key) {
  final v = i18n.t[key];
  return v is String ? v : key;
}

/// 内部カテゴリ id (all/overall/healing/money/love/work/career/communication/newStart)
/// → ローカライズ表示名。未知の id はそのまま返す。
String categoryLabel(String id) {
  final concept = _categoryConcept[id];
  return concept != null ? tr('category.$concept') : id;
}

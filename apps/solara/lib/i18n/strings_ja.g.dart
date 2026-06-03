///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsJa = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ja,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ja>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$sanctuary$ja sanctuary = Translations$sanctuary$ja.internal(_root);
	late final Translations$mapDaily$ja mapDaily = Translations$mapDaily$ja.internal(_root);
	late final Translations$mapFortune$ja mapFortune = Translations$mapFortune$ja.internal(_root);
	late final Translations$galaxy$ja galaxy = Translations$galaxy$ja.internal(_root);
	late final Translations$forecast$ja forecast = Translations$forecast$ja.internal(_root);
	late final Translations$consultHistory$ja consultHistory = Translations$consultHistory$ja.internal(_root);
	late final Translations$consultCredit$ja consultCredit = Translations$consultCredit$ja.internal(_root);
	late final Translations$consultPlacePicker$ja consultPlacePicker = Translations$consultPlacePicker$ja.internal(_root);
	late final Translations$consultResult$ja consultResult = Translations$consultResult$ja.internal(_root);
	late final Translations$consultStart$ja consultStart = Translations$consultStart$ja.internal(_root);
	late final Translations$consultInput$ja consultInput = Translations$consultInput$ja.internal(_root);
	late final Translations$mapAcg$ja mapAcg = Translations$mapAcg$ja.internal(_root);
	late final Translations$mapVp$ja mapVp = Translations$mapVp$ja.internal(_root);
	late final Translations$mapMenu$ja mapMenu = Translations$mapMenu$ja.internal(_root);
	late final Translations$locations$ja locations = Translations$locations$ja.internal(_root);
	late final Translations$paywall$ja paywall = Translations$paywall$ja.internal(_root);
	late final Translations$category$ja category = Translations$category$ja.internal(_root);
	late final Translations$disclaimer$ja disclaimer = Translations$disclaimer$ja.internal(_root);
	late final Translations$common$ja common = Translations$common$ja.internal(_root);
	late final Translations$aiConsent$ja aiConsent = Translations$aiConsent$ja.internal(_root);
}

// Path: sanctuary
class Translations$sanctuary$ja {
	Translations$sanctuary$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '✦ Pro 残 $remaining / $limit ・ 購入 $pur （月曜補充）'
	String creditPro({required Object remaining, required Object limit, required Object pur}) => '✦ Pro 残 ${remaining} / ${limit} ・ 購入 ${pur} （月曜補充）';

	/// ja: '✦ Pro 残 確認中 ・ 購入 $pur'
	String creditProSyncing({required Object pur}) => '✦ Pro 残 確認中 ・ 購入 ${pur}';

	/// ja: '✦ クレジット残 ─ 無料 $free ・ 購入 $pur'
	String creditFree({required Object free, required Object pur}) => '✦ クレジット残 ─ 無料 ${free} ・ 購入 ${pur}';

	/// ja: '設定済み ›'
	String get set => '設定済み ›';

	/// ja: '未設定 ›'
	String get unset => '未設定 ›';

	/// ja: '出生情報'
	String get birthInfo => '出生情報';

	/// ja: '自宅（現住所）'
	String get home => '自宅（現住所）';

	/// ja: '✦ あなたの称号を受け取る'
	String get receiveTitle => '✦ あなたの称号を受け取る';

	/// ja: '✦ 称号カードを共有する'
	String get shareTitleCard => '✦ 称号カードを共有する';

	/// ja: '再診断する'
	String get rediagnose => '再診断する';

	/// ja: '再診断はCosmic Pro限定'
	String get rediagnoseProOnly => '再診断はCosmic Pro限定';

	/// ja: 'まず出生情報を設定してください'
	String get needProfile => 'まず出生情報を設定してください';

	/// ja: 'クラスの取り直し'
	String get rediagnoseProFeature => 'クラスの取り直し';

	/// ja: '「今の自分」は変わっていきます。 Cosmic Pro なら何度でも診断を受け直せ、 変遷ギャラリーで過去のクラスを並べて見返せます。'
	String get rediagnoseProDesc => '「今の自分」は変わっていきます。\nCosmic Pro なら何度でも診断を受け直せ、\n変遷ギャラリーで過去のクラスを並べて見返せます。';

	late final Translations$sanctuary$guide$ja guide = Translations$sanctuary$guide$ja.internal(_root);

	/// ja: '相談履歴'
	String get consultHistory => '相談履歴';

	/// ja: '称号 変遷'
	String get titleHistory => '称号 変遷';

	/// ja: 'タロット全カテゴリ · 星読みの深い読み · 地図の引越し&120本ライン'
	String get proPerks1 => 'タロット全カテゴリ · 星読みの深い読み · 地図の引越し&120本ライン';

	/// ja: 'おでかけの時刻指定 · 称号は無制限に再診断 · Forecast 5年 ほか'
	String get proPerks2 => 'おでかけの時刻指定 · 称号は無制限に再診断 · Forecast 5年 ほか';

	/// ja: 'プランと価格はペイウォールでご確認ください · いつでも解約可能'
	String get proPaywallNote => 'プランと価格はペイウォールでご確認ください · いつでも解約可能';

	/// ja: 'Cosmic Pro 加入中'
	String get proActive => 'Cosmic Pro 加入中';

	/// ja: 'すべての機能が解放されています。'
	String get proActiveDesc => 'すべての機能が解放されています。';

	/// ja: 'プラン・規約'
	String get plansTerms => 'プラン・規約';

	/// ja: '復元する購入が見つかりませんでした。'
	String get restoreNotFound => '復元する購入が見つかりませんでした。';

	/// ja: '購入を復元しました。'
	String get restoreDone => '購入を復元しました。';

	/// ja: '復元中にエラーが発生しました: $e'
	String restoreError({required Object e}) => '復元中にエラーが発生しました: ${e}';

	/// ja: 'ホロスコープのオーブ'
	String get orbSetting => 'ホロスコープのオーブ';

	/// ja: '標準 ›'
	String get orbStandard => '標準 ›';

	/// ja: 'カスタム ›'
	String get orbCustom => 'カスタム ›';

	/// ja: '1日の開始時刻'
	String get dayStart => '1日の開始時刻';

	/// ja: '端末の設定で通知を許可してください'
	String get notifyNeedPermission => '端末の設定で通知を許可してください';
}

// Path: mapDaily
class Translations$mapDaily$ja {
	Translations$mapDaily$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '出生地'
	String get birthplace => '出生地';

	/// ja: '世界規模で見る'
	String get worldScale => '世界規模で見る';

	/// ja: 'Stella に相談'
	String get consultStella => 'Stella に相談';

	/// ja: '天体から場所を読む'
	String get consultStellaSub => '天体から場所を読む';

	/// ja: '本日'
	String get tabToday => '本日';

	/// ja: '明日'
	String get tabTomorrow => '明日';

	/// ja: '全カテゴリ'
	String get allCategories => '全カテゴリ';

	/// ja: '今日の TOP — $label'
	String todayTop({required Object label}) => '今日の TOP — ${label}';

	late final Translations$mapDaily$tagline$ja tagline = Translations$mapDaily$tagline$ja.internal(_root);

	/// ja: '外向きの相'
	String get subLabelOuter => '外向きの相';

	/// ja: '内向きの相'
	String get subLabelInner => '内向きの相';

	/// ja: '外向き＋内向きの相が混在'
	String get subLabelMixed => '外向き＋内向きの相が混在';

	/// ja: 'おすすめ行動の例（参考）'
	String get recommendedActions => 'おすすめ行動の例（参考）';

	/// ja: '※ 他の行動も、この例を参考に自由に考えてみてください'
	String get otherActionsNote => '※ 他の行動も、この例を参考に自由に考えてみてください';

	/// ja: '惑星の動きを読み取っています'
	String get loading => '惑星の動きを読み取っています';

	/// ja: 'データの取得に失敗しました'
	String get failed => 'データの取得に失敗しました';

	/// ja: 'もう一度'
	String get retry => 'もう一度';

	/// ja: '今日は静かな日。 特別な動きは見えません。'
	String get quietDay => '今日は静かな日。\n特別な動きは見えません。';

	/// ja: 'このフィルタ条件に 該当するイベントはありません。 フィルタを変更してください。'
	String get noFilterMatch => 'このフィルタ条件に\n該当するイベントはありません。\nフィルタを変更してください。';

	/// ja: 'この時刻をMapで見る'
	String get viewOnMap => 'この時刻をMapで見る';

	/// ja: '$planet が$angle通過'
	String transitPass({required Object planet, required Object angle}) => '${planet} が${angle}通過';

	/// ja: '$planetの$angle通過'
	String transitTitle({required Object planet, required Object angle}) => '${planet}の${angle}通過';

	late final Translations$mapDaily$angle$ja angle = Translations$mapDaily$angle$ja.internal(_root);
	late final Translations$mapDaily$angleHint$ja angleHint = Translations$mapDaily$angleHint$ja.internal(_root);

	/// ja: '★ 天頂寄り'
	String get zenithBias => '★ 天頂寄り';

	/// ja: '★ 天底寄り'
	String get nadirBias => '★ 天底寄り';

	/// ja: '今あなたの緯度帯 (緯度 $lat°、オーブ ±$orb°)'
	String latitudeBand({required Object lat, required Object orb}) => '今あなたの緯度帯 (緯度 ${lat}°、オーブ ±${orb}°)';

	/// ja: '天頂帯'
	String get zenithBand => '天頂帯';

	/// ja: '天底帯'
	String get nadirBand => '天底帯';

	late final Translations$mapDaily$usage$ja usage = Translations$mapDaily$usage$ja.internal(_root);
}

// Path: mapFortune
class Translations$mapFortune$ja {
	Translations$mapFortune$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$mapFortune$srcShort$ja srcShort = Translations$mapFortune$srcShort$ja.internal(_root);
	late final Translations$mapFortune$srcFull$ja srcFull = Translations$mapFortune$srcFull$ja.internal(_root);

	/// ja: '$src / $cat'
	String header({required Object src, required Object cat}) => '${src} / ${cat}';

	/// ja: 'Tソフト'
	String get legendTSoft => 'Tソフト';

	/// ja: 'Tハード'
	String get legendTHard => 'Tハード';

	/// ja: 'Pソフト'
	String get legendPSoft => 'Pソフト';

	/// ja: 'Pハード'
	String get legendPHard => 'Pハード';

	late final Translations$mapFortune$catMeta$ja catMeta = Translations$mapFortune$catMeta$ja.internal(_root);
	late final Translations$mapFortune$usage$ja usage = Translations$mapFortune$usage$ja.internal(_root);
	late final Translations$mapFortune$catPlanets$ja catPlanets = Translations$mapFortune$catPlanets$ja.internal(_root);
}

// Path: galaxy
class Translations$galaxy$ja {
	Translations$galaxy$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '今日の月: $name'
	String todayMoon({required Object name}) => '今日の月: ${name}';

	late final Translations$galaxy$phaseDesc$ja phaseDesc = Translations$galaxy$phaseDesc$ja.internal(_root);
	late final Translations$galaxy$events$ja events = Translations$galaxy$events$ja.internal(_root);
	late final Translations$galaxy$guide$ja guide = Translations$galaxy$guide$ja.internal(_root);
}

// Path: forecast
class Translations$forecast$ja {
	Translations$forecast$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Forecast の取得に失敗しました。ネットワーク接続を確認してください。'
	String get error => 'Forecast の取得に失敗しました。ネットワーク接続を確認してください。';

	/// ja: '5 年の流れ'
	String get pro5yrLabel => '5 年の流れ';

	/// ja: '今年だけでなく翌年・来々年も含めた 5 年分のヒートマップで、人生の大きな流れを見渡せます。'
	String get pro5yrDesc => '今年だけでなく翌年・来々年も含めた 5 年分のヒートマップで、人生の大きな流れを見渡せます。';

	/// ja: '($n日)'
	String daysCount({required Object n}) => '(${n}日)';

	/// ja: '天体の運行を計算中…'
	String get calculating => '天体の運行を計算中…';

	/// ja: 'データがありません'
	String get noData => 'データがありません';

	/// ja: '表示期間'
	String get displayPeriod => '表示期間';

	/// ja: '年間ベスト'
	String get yearBest => '年間ベスト';

	List<String> get yearLabels => [
		'今年',
		'来年',
		'再来年',
		'3年後',
		'4年後',
	];

	/// ja: '+$n年'
	String plusYears({required Object n}) => '+${n}年';

	/// ja: '$fy年$fm月 〜 $ly年$lm月'
	String monthRange({required Object fy, required Object fm, required Object ly, required Object lm}) => '${fy}年${fm}月 〜 ${ly}年${lm}月';

	/// ja: '1年ヒートマップ'
	String get heatmap1yr => '1年ヒートマップ';

	/// ja: '相対'
	String get segRelative => '相対';

	/// ja: '絶対'
	String get segAbsolute => '絶対';

	/// ja: 'カテゴリ'
	String get segCategory => 'カテゴリ';

	/// ja: '🟢↑高'
	String get highGreen => '🟢↑高';

	/// ja: '🔴↑高'
	String get highRed => '🔴↑高';

	/// ja: '$n位'
	String rankNth({required Object n}) => '${n}位';

	/// ja: '総合'
	String get metricOverall => '総合';

	/// ja: '高まる方位'
	String get metricTopDir => '高まる方位';

	/// ja: '方位スコア'
	String get metricDirScore => '方位スコア';

	/// ja: 'カテゴリ別'
	String get categoryBy => 'カテゴリ別';

	/// ja: '最終取得: $ts / 差分更新方式（月次）'
	String lastFetch({required Object ts}) => '最終取得: ${ts}  /  差分更新方式（月次）';

	late final Translations$forecast$legend$ja legend = Translations$forecast$legend$ja.internal(_root);
	late final Translations$forecast$usage$ja usage = Translations$forecast$usage$ja.internal(_root);
	late final Translations$forecast$heatmapInfo$ja heatmapInfo = Translations$forecast$heatmapInfo$ja.internal(_root);
	late final Translations$forecast$cycles$ja cycles = Translations$forecast$cycles$ja.internal(_root);
	late final Translations$forecast$top5$ja top5 = Translations$forecast$top5$ja.internal(_root);
}

// Path: consultHistory
class Translations$consultHistory$ja {
	Translations$consultHistory$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '相談履歴'
	String get title => '相談履歴';

	/// ja: 'すべて削除'
	String get deleteAll => 'すべて削除';

	/// ja: 'すべて削除しますか？'
	String get deleteAllTitle => 'すべて削除しますか？';

	/// ja: '保存された全ての相談記録が消えます。元に戻せません。'
	String get deleteAllBody => '保存された全ての相談記録が消えます。元に戻せません。';

	/// ja: '削除'
	String get delete => '削除';

	/// ja: 'この記録を削除しますか？'
	String get deleteOneTitle => 'この記録を削除しますか？';

	/// ja: 'すべて'
	String get filterAll => 'すべて';

	/// ja: '★ お気に入り'
	String get filterFav => '★ お気に入り';

	/// ja: 'まだ相談履歴はありません'
	String get emptyAll => 'まだ相談履歴はありません';

	/// ja: 'お気に入りはまだありません'
	String get emptyFav => 'お気に入りはまだありません';

	/// ja: 'Map で地点をタップ、または Daily Transit から相談を始めると、 ここに保存されます。'
	String get emptyAllHint => 'Map で地点をタップ、または Daily Transit から相談を始めると、\nここに保存されます。';

	/// ja: '記録の ☆ をタップすると、ここに集まります。'
	String get emptyFavHint => '記録の ☆ をタップすると、ここに集まります。';

	/// ja: 'だれと: $name'
	String withWhomPrefix({required Object name}) => 'だれと: ${name}';

	/// ja: '未定'
	String get undecidedShort => '未定';

	/// ja: 'おでかけ・イベント'
	String get modeDaily => 'おでかけ・イベント';

	/// ja: 'お気に入り登録'
	String get fav => 'お気に入り登録';

	/// ja: 'お気に入り解除'
	String get unfav => 'お気に入り解除';
}

// Path: consultCredit
class Translations$consultCredit$ja {
	Translations$consultCredit$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'サインインが必要です'
	String get signinTitle => 'サインインが必要です';

	/// ja: 'クレジットのご購入には $provider サインインが必要です。 サインインすると、機種変更や再インストール後も残高が引き継がれます。無料の機能はサインインなしでお使いいただけます。'
	String signinBody({required Object provider}) => 'クレジットのご購入には ${provider} サインインが必要です。\n\nサインインすると、機種変更や再インストール後も残高が引き継がれます。無料の機能はサインインなしでお使いいただけます。';

	/// ja: '$provider でサインイン'
	String signinCta({required Object provider}) => '${provider} でサインイン';

	/// ja: 'サインインに失敗しました'
	String get signinFailed => 'サインインに失敗しました';

	/// ja: '購入に失敗しました。時間をおいてお試しください。'
	String get buyFailed => '購入に失敗しました。時間をおいてお試しください。';

	/// ja: 'Stella 相談クレジット'
	String get heading => 'Stella 相談クレジット';

	/// ja: '今週の無料相談 あと$n回'
	String balanceFree({required Object n}) => '今週の無料相談 あと${n}回';

	/// ja: ' ・ 購入残高 $n回'
	String balancePaid({required Object n}) => ' ・ 購入残高 ${n}回';

	/// ja: '✦ Cosmic Pro なら回数無制限 →'
	String get proUnlimited => '✦ Cosmic Pro なら回数無制限 →';

	/// ja: 'クレジットの販売準備中です。 しばらくしてからお試しください。'
	String get preparing => 'クレジットの販売準備中です。\nしばらくしてからお試しください。';

	/// ja: 'クレジット'
	String get fallbackProduct => 'クレジット';
}

// Path: consultPlacePicker
class Translations$consultPlacePicker$ja {
	Translations$consultPlacePicker$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'タップ または 検索 で地点を選んでください'
	String get prompt => 'タップ または 検索 で地点を選んでください';

	/// ja: '読み込み中…'
	String get loading => '読み込み中…';

	/// ja: '選択地点'
	String get selectedPoint => '選択地点';

	/// ja: '選択地点 ($lat°, $lng°)'
	String coordName({required Object lat, required Object lng}) => '選択地点 (${lat}°, ${lng}°)';

	/// ja: 'この地点で相談'
	String get consultHere => 'この地点で相談';
}

// Path: consultResult
class Translations$consultResult$ja {
	Translations$consultResult$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '相談の結果'
	String get title => '相談の結果';

	/// ja: '戻る'
	String get back => '戻る';

	/// ja: 'シェア'
	String get shareTooltip => 'シェア';

	/// ja: '接続に届きませんでした。もう一度試せます。'
	String get connError => '接続に届きませんでした。もう一度試せます。';

	/// ja: '方角'
	String get kindDirection => '方角';

	/// ja: '場所'
	String get kindPlace => '場所';

	/// ja: '(narrative なし)'
	String get noReading => '(narrative なし)';

	/// ja: '地図で見る'
	String get viewOnMap => '地図で見る';

	/// ja: '$dir 約${dist}km'
	String distanceFromHome({required Object dir, required Object dist}) => '${dir} 約${dist}km';

	/// ja: 'Stella が読み解いています…'
	String get loading => 'Stella が読み解いています…';

	/// ja: 'もう一度試す'
	String get retry => 'もう一度試す';

	/// ja: 'Stella の声が今は届きませんでした'
	String get voiceUnavailable => 'Stella の声が今は届きませんでした';

	/// ja: 'この読み解きについて'
	String get aboutReading => 'この読み解きについて';

	/// ja: 'この土地の占星術ファクター'
	String get factorsTitle => 'この土地の占星術ファクター';

	/// ja: ' $factor：約 ${km}km'
	String kmFactor({required Object factor, required Object km}) => '  ${factor}：約 ${km}km';

	/// ja: '距離はエネルギーの有無を決めません。惑星ははるか遠方、地上の数百kmは「圏内かどうか」の差にすぎません。'
	String get distanceNote => '距離はエネルギーの有無を決めません。惑星ははるか遠方、地上の数百kmは「圏内かどうか」の差にすぎません。';

	/// ja: '（近くの候補は$n件ほど）'
	String nearbyCount({required Object n}) => '（近くの候補は${n}件ほど）';

	/// ja: 'この近くは候補が少なめです$countText。半径を広げる・方角を変えると見つかりやすくなります。'
	String sparseHint({required Object countText}) => 'この近くは候補が少なめです${countText}。半径を広げる・方角を変えると見つかりやすくなります。';

	late final Translations$consultResult$exhaust$ja exhaust = Translations$consultResult$exhaust$ja.internal(_root);
	late final Translations$consultResult$suggest$ja suggest = Translations$consultResult$suggest$ja.internal(_root);

	/// ja: '別の候補地を探しています…'
	String get refreshLoading => '別の候補地を探しています…';

	/// ja: '別の候補地を見る'
	String get refresh => '別の候補地を見る';

	late final Translations$consultResult$delta$ja delta = Translations$consultResult$delta$ja.internal(_root);

	/// ja: 'この候補の根拠（エビデンス）は、最上部「相談の結果」に表示しています。Stella は、その一つの読み方をお伝えしています。違和感があれば、ご自身の解釈も重ねてみてください。ここでの表示は、数ある解釈の一つです。'
	String get interpNote => 'この候補の根拠（エビデンス）は、最上部「相談の結果」に表示しています。Stella は、その一つの読み方をお伝えしています。違和感があれば、ご自身の解釈も重ねてみてください。ここでの表示は、数ある解釈の一つです。';

	/// ja: 'この30分後の変化は、上に示した線の動きをエビデンスとして、Stellaが解釈の１つとして表示しています。内容に違和感がある場合はご自身で解釈を広げてみてください。あくまでここでの表示は解釈の１つに過ぎません。'
	String get deltaInterpNote => 'この30分後の変化は、上に示した線の動きをエビデンスとして、Stellaが解釈の１つとして表示しています。内容に違和感がある場合はご自身で解釈を広げてみてください。あくまでここでの表示は解釈の１つに過ぎません。';

	late final Translations$consultResult$pro$ja pro = Translations$consultResult$pro$ja.internal(_root);
	late final Translations$consultResult$block$ja block = Translations$consultResult$block$ja.internal(_root);
	late final Translations$consultResult$shareSheet$ja shareSheet = Translations$consultResult$shareSheet$ja.internal(_root);

	/// ja: '相談結果に戻る'
	String get returnChip => '相談結果に戻る';
}

// Path: consultStart
class Translations$consultStart$ja {
	Translations$consultStart$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Pro 週次クレジットを使う'
	String get useProWeekly => 'Pro 週次クレジットを使う';

	/// ja: '有料クレジットを使う'
	String get usePaid => '有料クレジットを使う';

	/// ja: 'クレジットを使う'
	String get useCredit => 'クレジットを使う';

	/// ja: '無料クレジットを使う'
	String get useFree => '無料クレジットを使う';

	/// ja: 'Pro 週次クレジット'
	String get proWeeklyLabel => 'Pro 週次クレジット';

	/// ja: '無料クレジット'
	String get freeLabel => '無料クレジット';

	/// ja: '残り $n / $limit 回'
	String remaining({required Object n, required Object limit}) => '残り ${n} / ${limit} 回';

	/// ja: '残り回数を確認中'
	String get checkingRemaining => '残り回数を確認中';

	/// ja: '毎週月曜日に補充（Pro 加入中）'
	String get refillProMonday => '毎週月曜日に補充（Pro 加入中）';

	/// ja: '毎週月曜日に補充'
	String get refillMonday => '毎週月曜日に補充';

	/// ja: '有料クレジット'
	String get paidLabel => '有料クレジット';

	/// ja: '残り $n 回'
	String paidRemaining({required Object n}) => '残り ${n} 回';

	/// ja: '失効なし（購入分は端末を変えても残る）'
	String get neverExpires => '失効なし（購入分は端末を変えても残る）';

	/// ja: '次回以降表示しない'
	String get dontShowAgain => '次回以降表示しない';

	/// ja: 'クレジットを購入'
	String get buyCredits => 'クレジットを購入';

	/// ja: '相談を始める'
	String get start => '相談を始める';
}

// Path: consultInput
class Translations$consultInput$ja {
	Translations$consultInput$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '相談する'
	String get screenTitle => '相談する';

	late final Translations$consultInput$section$ja section = Translations$consultInput$section$ja.internal(_root);
	late final Translations$consultInput$proTimePick$ja proTimePick = Translations$consultInput$proTimePick$ja.internal(_root);

	/// ja: '例: 妻と / ひとりで / 気になる人と'
	String get whomHint => '例: 妻と / ひとりで / 気になる人と';

	/// ja: '今いちばん大切にしたい気持ちを一言で'
	String get wishHint => '今いちばん大切にしたい気持ちを一言で';

	late final Translations$consultInput$whomExamples$ja whomExamples = Translations$consultInput$whomExamples$ja.internal(_root);
	late final Translations$consultInput$wishExamples$ja wishExamples = Translations$consultInput$wishExamples$ja.internal(_root);
	late final Translations$consultInput$picker$ja picker = Translations$consultInput$picker$ja.internal(_root);
	late final Translations$consultInput$theme$ja theme = Translations$consultInput$theme$ja.internal(_root);
	late final Translations$consultInput$mode$ja mode = Translations$consultInput$mode$ja.internal(_root);
	late final Translations$consultInput$scope$ja scope = Translations$consultInput$scope$ja.internal(_root);
	late final Translations$consultInput$when$ja when = Translations$consultInput$when$ja.internal(_root);
	late final Translations$consultInput$timeBand$ja timeBand = Translations$consultInput$timeBand$ja.internal(_root);
	late final Translations$consultInput$hourPicker$ja hourPicker = Translations$consultInput$hourPicker$ja.internal(_root);

	/// ja: '$time を指定中（30分後の変化が見られます）'
	String timeRowSelected({required Object time}) => '${time} を指定中（30分後の変化が見られます）';

	/// ja: '$min〜${max}km'
	String radiusBand({required Object min, required Object max}) => '${min}〜${max}km';

	/// ja: '${km}km'
	String radiusSingle({required Object km}) => '${km}km';

	/// ja: '相談を始める'
	String get submit => '相談を始める';

	/// ja: '現住所が未設定です。「方角・現住所から半径・自国内」は現住所を設定すると使えます。「具体地点」は今すぐ使えます。'
	String get noHomeNote => '現住所が未設定です。「方角・現住所から半径・自国内」は現住所を設定すると使えます。「具体地点」は今すぐ使えます。';

	/// ja: '$name を見ます'
	String presetCard({required Object name}) => '${name} を見ます';

	/// ja: 'いつ・どこで・何をするか を選ぶと、その時その場所で“どんなエネルギーが働くか”を、膨大な占星術データから Stella が分かりやすく読み解きます。'
	String get introNote => 'いつ・どこで・何をするか を選ぶと、その時その場所で“どんなエネルギーが働くか”を、膨大な占星術データから Stella が分かりやすく読み解きます。';

	late final Translations$consultInput$about$ja about = Translations$consultInput$about$ja.internal(_root);
}

// Path: mapAcg
class Translations$mapAcg$ja {
	Translations$mapAcg$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '引越し'
	String get pillRelocate => '引越し';

	/// ja: 'アスペクト'
	String get pillAspect => 'アスペクト';

	late final Translations$mapAcg$sub$ja sub = Translations$mapAcg$sub$ja.internal(_root);
	late final Translations$mapAcg$frameLabel$ja frameLabel = Translations$mapAcg$frameLabel$ja.internal(_root);

	/// ja: 'この地点で相談する'
	String get consultHere => 'この地点で相談する';

	late final Translations$mapAcg$guide$ja guide = Translations$mapAcg$guide$ja.internal(_root);
}

// Path: mapVp
class Translations$mapVp$ja {
	Translations$mapVp$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '保存済みスロット'
	String get savedSlots => '保存済みスロット';

	/// ja: '登録地'
	String get registeredPlaces => '登録地';

	/// ja: '（スロットなし）'
	String get noSlots => '（スロットなし）';

	/// ja: '現在地に移動'
	String get moveToCurrent => '現在地に移動';

	/// ja: 'この地点を保存'
	String get saveThisPoint => 'この地点を保存';

	/// ja: 'この地点を登録'
	String get registerThisPoint => 'この地点を登録';

	/// ja: '上に移動'
	String get subMoveUp => '上に移動';

	/// ja: '下に移動'
	String get subMoveDown => '下に移動';

	/// ja: 'アイコン変更'
	String get subChangeIcon => 'アイコン変更';

	/// ja: '名称変更'
	String get subRename => '名称変更';

	/// ja: '削除'
	String get subDelete => '削除';

	/// ja: 'アイコンを選択'
	String get iconPickerTitle => 'アイコンを選択';

	late final Translations$mapVp$help$ja help = Translations$mapVp$help$ja.internal(_root);
}

// Path: mapMenu
class Translations$mapMenu$ja {
	Translations$mapMenu$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '惑星'
	String get tabPlanet => '惑星';

	late final Translations$mapMenu$map$ja map = Translations$mapMenu$map$ja.internal(_root);
	late final Translations$mapMenu$planet$ja planet = Translations$mapMenu$planet$ja.internal(_root);
	late final Translations$mapMenu$acg$ja acg = Translations$mapMenu$acg$ja.internal(_root);
	late final Translations$mapMenu$pg$ja pg = Translations$mapMenu$pg$ja.internal(_root);
	late final Translations$mapMenu$popup$ja popup = Translations$mapMenu$popup$ja.internal(_root);
}

// Path: locations
class Translations$locations$ja {
	Translations$locations$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	List<String> get locDefaults => [
		'場所1',
		'場所2',
		'場所3',
		'場所4',
	];
	List<String> get vpDefaults => [
		'職場',
		'お気に入り',
		'スポット',
		'場所',
	];

	/// ja: '現住所'
	String get currentAddress => '現住所';

	/// ja: '地図中心'
	String get mapCenter => '地図中心';

	/// ja: '地点の名称を入力'
	String get renameTitle => '地点の名称を入力';

	/// ja: 'キャンセル'
	String get cancel => 'キャンセル';

	/// ja: '$dir方位'
	String bearing({required Object dir}) => '${dir}方位';

	/// ja: '登録された拠点はまだありません'
	String get emptyTitle => '登録された拠点はまだありません';

	/// ja: '📍 現在地を登録'
	String get addCurrent => '📍 現在地を登録';

	/// ja: '✏ 名称変更'
	String get menuRename => '✏ 名称変更';

	/// ja: '🗑 削除'
	String get menuDelete => '🗑 削除';

	late final Translations$locations$guide$ja guide = Translations$locations$guide$ja.internal(_root);
}

// Path: paywall
class Translations$paywall$ja {
	Translations$paywall$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$paywall$period$ja period = Translations$paywall$period$ja.internal(_root);
	late final Translations$paywall$introPeriod$ja introPeriod = Translations$paywall$introPeriod$ja.internal(_root);
	late final Translations$paywall$store$ja store = Translations$paywall$store$ja.internal(_root);

	/// ja: 'サブスクリプションは自動更新されます。期間終了の 24 時間以上前に自動更新を解約しない限り、同じ価格で次の期間に更新されます。料金は期間終了の 24 時間以内に Apple ID / Google アカウントへ請求されます。自動更新の管理や解約は、ご利用ストアのアカウント設定からいつでも行えます。'
	String get autoRenewNotice => 'サブスクリプションは自動更新されます。期間終了の 24 時間以上前に自動更新を解約しない限り、同じ価格で次の期間に更新されます。料金は期間終了の 24 時間以内に Apple ID / Google アカウントへ請求されます。自動更新の管理や解約は、ご利用ストアのアカウント設定からいつでも行えます。';

	late final Translations$paywall$legal$ja legal = Translations$paywall$legal$ja.internal(_root);

	/// ja: '購入を復元'
	String get restore => '購入を復元';

	late final Translations$paywall$hero$ja hero = Translations$paywall$hero$ja.internal(_root);
	late final Translations$paywall$billing$ja billing = Translations$paywall$billing$ja.internal(_root);
	late final Translations$paywall$plans$ja plans = Translations$paywall$plans$ja.internal(_root);
	late final Translations$paywall$cta$ja cta = Translations$paywall$cta$ja.internal(_root);
	late final Translations$paywall$comparison$ja comparison = Translations$paywall$comparison$ja.internal(_root);
	late final Translations$paywall$faq$ja faq = Translations$paywall$faq$ja.internal(_root);
}

// Path: category
class Translations$category$ja {
	Translations$category$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '総合'
	String get overall => '総合';

	/// ja: '癒し'
	String get healing => '癒し';

	/// ja: '豊かさ'
	String get abundance => '豊かさ';

	/// ja: '恋愛'
	String get love => '恋愛';

	/// ja: '仕事'
	String get work => '仕事';

	/// ja: '話す'
	String get talk => '話す';

	/// ja: '変化'
	String get change => '変化';
}

// Path: disclaimer
class Translations$disclaimer$ja {
	Translations$disclaimer$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '✦ AI 生成・娯楽目的。医療・法律・金融等の専門的な助言ではありません。'
	String get ai => '✦ AI 生成・娯楽目的。医療・法律・金融等の専門的な助言ではありません。';

	/// ja: '解説の取得に失敗しました。通信状況を確認して、もう一度お試しください。'
	String get fetchFailed => '解説の取得に失敗しました。通信状況を確認して、もう一度お試しください。';
}

// Path: common
class Translations$common$ja {
	Translations$common$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '再試行'
	String get tryAgain => '再試行';
}

// Path: aiConsent
class Translations$aiConsent$ja {
	Translations$aiConsent$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'ご利用前のおしらせ'
	String get subtitle => 'ご利用前のおしらせ';

	/// ja: '同意して始める'
	String get agree => '同意して始める';

	/// ja: '同意しない'
	String get decline => '同意しない';

	/// ja: '戻る'
	String get back => '戻る';

	/// ja: 'リンクを開けませんでした: $url'
	String linkOpenFailed({required Object url}) => 'リンクを開けませんでした: ${url}';

	late final Translations$aiConsent$declineDialog$ja declineDialog = Translations$aiConsent$declineDialog$ja.internal(_root);
	late final Translations$aiConsent$links$ja links = Translations$aiConsent$links$ja.internal(_root);
	late final Translations$aiConsent$intro$ja intro = Translations$aiConsent$intro$ja.internal(_root);
	late final Translations$aiConsent$entertainment$ja entertainment = Translations$aiConsent$entertainment$ja.internal(_root);
	late final Translations$aiConsent$thirdParty$ja thirdParty = Translations$aiConsent$thirdParty$ja.internal(_root);
	late final Translations$aiConsent$geminiContent$ja geminiContent = Translations$aiConsent$geminiContent$ja.internal(_root);
	late final Translations$aiConsent$decisions$ja decisions = Translations$aiConsent$decisions$ja.internal(_root);
	late final Translations$aiConsent$consentHandling$ja consentHandling = Translations$aiConsent$consentHandling$ja.internal(_root);
}

// Path: sanctuary.guide
class Translations$sanctuary$guide$ja {
	Translations$sanctuary$guide$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '✦ 称号の受け直しについて'
	String get title => '✦ 称号の受け直しについて';

	/// ja: 'Cosmic Pro では、称号を何度でも受け取り直すことができます。'
	String get lead => 'Cosmic Pro では、称号を何度でも受け取り直すことができます。';

	/// ja: 'ただし、あなたの太陽星座・月星座から導かれる「二つ名」そのものは変わりません。変わるのは、設問への答えで形づくられる「称号（クラス）」の部分だけです。'
	String get body1 => 'ただし、あなたの太陽星座・月星座から導かれる「二つ名」そのものは変わりません。変わるのは、設問への答えで形づくられる「称号（クラス）」の部分だけです。';

	/// ja: '称号は一つひとつの設問と深く結びついています。ご自身の内面の変化や、環境の変化を感じたときに受け直すと、のちに「称号 変遷」で振り返ったとき、あなたの成長や移ろいを辿ることができます。'
	String get body2 => '称号は一つひとつの設問と深く結びついています。ご自身の内面の変化や、環境の変化を感じたときに受け直すと、のちに「称号 変遷」で振り返ったとき、あなたの成長や移ろいを辿ることができます。';

	/// ja: 'もちろん毎日受け直していただいても構いません。そんな使い方もある、というご案内をそっとお伝えしておきます。'
	String get body3 => 'もちろん毎日受け直していただいても構いません。そんな使い方もある、というご案内をそっとお伝えしておきます。';

	/// ja: '戻る'
	String get back => '戻る';
}

// Path: mapDaily.tagline
class Translations$mapDaily$tagline$ja {
	Translations$mapDaily$tagline$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '今日の動きを確認しましょう'
	String get neutral => '今日の動きを確認しましょう';

	/// ja: '関係性のエネルギーが多面的に動く一日'
	String get love => '関係性のエネルギーが多面的に動く一日';

	/// ja: '物質的な豊かさのエネルギーが流れる一日'
	String get money => '物質的な豊かさのエネルギーが流れる一日';

	/// ja: '社会的役割のエネルギーが動く一日'
	String get work => '社会的役割のエネルギーが動く一日';

	/// ja: '内省と統合のエネルギーが流れる一日'
	String get healing => '内省と統合のエネルギーが流れる一日';

	/// ja: '対話と知性のエネルギーが動く一日'
	String get communication => '対話と知性のエネルギーが動く一日';
}

// Path: mapDaily.angle
class Translations$mapDaily$angle$ja {
	Translations$mapDaily$angle$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '東の地平 (ASC)'
	String get asc => '東の地平 (ASC)';

	/// ja: '天頂 (MC)'
	String get mc => '天頂 (MC)';

	/// ja: '西の地平 (DSC)'
	String get dsc => '西の地平 (DSC)';

	/// ja: '天底 (IC)'
	String get ic => '天底 (IC)';
}

// Path: mapDaily.angleHint
class Translations$mapDaily$angleHint$ja {
	Translations$mapDaily$angleHint$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '昇り始める時刻 — $compass の地平に現れる'
	String asc({required Object compass}) => '昇り始める時刻 — ${compass} の地平に現れる';

	/// ja: '最も高くに上る時刻 — $compass の空で頂点'
	String mc({required Object compass}) => '最も高くに上る時刻 — ${compass} の空で頂点';

	/// ja: '沈む時刻 — $compass の地平に降る'
	String dsc({required Object compass}) => '沈む時刻 — ${compass} の地平に降る';

	/// ja: '地下を通る時刻 — 内的な動きとして効く'
	String get ic => '地下を通る時刻 — 内的な動きとして効く';
}

// Path: mapDaily.usage
class Translations$mapDaily$usage$ja {
	Translations$mapDaily$usage$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '今日の動きの読み方'
	String get title => '今日の動きの読み方';

	/// ja: 'この画面では、あなたの意図する目的に合わせて 「いつ行動するか」の時間の指針が分かります。'
	String get summary => 'この画面では、あなたの意図する目的に合わせて\n「いつ行動するか」の時間の指針が分かります。';

	/// ja: '【基準地点 (VIEWPOINT)】'
	String get vpTitle => '【基準地点 (VIEWPOINT)】';

	/// ja: '右側のプルダウンが「基準地点」です。 出生地 (現住所として登録した地点) や、 VIEWPOINT として登録した地点を選択できます。 この画面では、選択した基準地点の空で、 惑星が「天空方位」のどこにいつ来るかを表示します。'
	String get vpBody => '右側のプルダウンが「基準地点」です。\n出生地 (現住所として登録した地点) や、\nVIEWPOINT として登録した地点を選択できます。\nこの画面では、選択した基準地点の空で、\n惑星が「天空方位」のどこにいつ来るかを表示します。';

	/// ja: '【⚠ Map 画面の方位とは別物です】'
	String get diffTitle => '【⚠ Map 画面の方位とは別物です】';

	/// ja: '・Map 画面 = 「地表方位」(16 方位) 基準地点から見て地表のどの方向に行くか (東の土地へ行く / 北の土地へ向かう、という地理) ・この画面 = 「天空方位」(4 アングル) 基準地点の真上の空で惑星がどこにあるか (東の地平線 / 真上の天頂 / 西の地平線 / 真下) 同じ「東」でも、Map では「東の土地」、 この画面では「東の地平線 (惑星が昇る位置)」を指します。'
	String get diffBody => '・Map 画面 = 「地表方位」(16 方位)\n　基準地点から見て地表のどの方向に行くか\n　(東の土地へ行く / 北の土地へ向かう、という地理)\n\n・この画面 = 「天空方位」(4 アングル)\n　基準地点の真上の空で惑星がどこにあるか\n　(東の地平線 / 真上の天頂 / 西の地平線 / 真下)\n\n同じ「東」でも、Map では「東の土地」、\nこの画面では「東の地平線 (惑星が昇る位置)」を指します。';

	/// ja: '【時間と天空方位を読む】'
	String get timeTitle => '【時間と天空方位を読む】';

	/// ja: '今日、各惑星が選択した基準地点の空で 4 つの天空方位 (アングル) を通る時刻を表示します: ・ASC (東の地平線) — 惑星が昇る瞬間 ・MC (真上 = 天頂) — 惑星が最高点を通る瞬間 ・DSC (西の地平線) — 惑星が沈む瞬間 ・IC (真下 = 地下) — 惑星が地球の裏側にある瞬間 「いつ恋愛のテーマが動く」「いつ仕事の節目になる」など、 行動する時間の指針が読み取れます。'
	String get timeBody => '今日、各惑星が選択した基準地点の空で\n4 つの天空方位 (アングル) を通る時刻を表示します:\n\n・ASC (東の地平線) — 惑星が昇る瞬間\n・MC  (真上 = 天頂) — 惑星が最高点を通る瞬間\n・DSC (西の地平線) — 惑星が沈む瞬間\n・IC  (真下 = 地下) — 惑星が地球の裏側にある瞬間\n\n「いつ恋愛のテーマが動く」「いつ仕事の節目になる」など、\n行動する時間の指針が読み取れます。';

	/// ja: '【Map スコアバーと組み合わせる】'
	String get comboTitle => '【Map スコアバーと組み合わせる】';

	/// ja: '地表方位ごとのエネルギーの強さは、 Map のスコアバーから確認できます (16 方位)。 「合計 / 総合」ラベル下の i ボタンに詳細解説があります。 スコアバー (地表方位の強さ) と この画面 (天空方位 × 時刻) を組み合わせると、 あなたの望む未来に対する最適な 「方角 × 時間」を Solara が算出します。'
	String get comboBody => '地表方位ごとのエネルギーの強さは、\nMap のスコアバーから確認できます (16 方位)。\n「合計 / 総合」ラベル下の i ボタンに詳細解説があります。\n\nスコアバー (地表方位の強さ) と\nこの画面 (天空方位 × 時刻) を組み合わせると、\nあなたの望む未来に対する最適な\n「方角 × 時間」を Solara が算出します。';
}

// Path: mapFortune.srcShort
class Translations$mapFortune$srcShort$ja {
	Translations$mapFortune$srcShort$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '合計'
	String get combined => '合計';

	/// ja: 'TR'
	String get transit => 'TR';

	/// ja: 'PR'
	String get progressed => 'PR';
}

// Path: mapFortune.srcFull
class Translations$mapFortune$srcFull$ja {
	Translations$mapFortune$srcFull$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '合計'
	String get combined => '合計';

	/// ja: 'トランジット'
	String get transit => 'トランジット';

	/// ja: 'プログレス'
	String get progressed => 'プログレス';
}

// Path: mapFortune.catMeta
class Translations$mapFortune$catMeta$ja {
	Translations$mapFortune$catMeta$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '休息・回復・直感が流れるテーマ'
	String get healing => '休息・回復・直感が流れるテーマ';

	/// ja: '繁栄・喜び・自己肯定のテーマ'
	String get money => '繁栄・喜び・自己肯定のテーマ';

	/// ja: '愛・情熱・親密さのテーマ'
	String get love => '愛・情熱・親密さのテーマ';

	/// ja: '責任・行動・拡大のテーマ'
	String get work => '責任・行動・拡大のテーマ';

	/// ja: '伝達・対話・知性のテーマ'
	String get communication => '伝達・対話・知性のテーマ';
}

// Path: mapFortune.usage
class Translations$mapFortune$usage$ja {
	Translations$mapFortune$usage$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Map の使い方'
	String get title => 'Map の使い方';

	/// ja: '【方角を読む】'
	String get dirTitle => '【方角を読む】';

	/// ja: '基準地点 (VIEWPOINT) を中心に、地表の 16 方位 (北・北北東・北東・東北東・東…) ごとのエネルギーを スコア化して表示しています。 「どの土地・方向に意識を向けるべきか」が判断できます。 どの方向に進むべきかだけの表示ではありません。 もちろん方角に向かい進む事も一つの方角に対する 行動です。他には、意識を向ける事や、声をかける、 大切なアイテムの置き場所を方角に合わせて家を出発する、 話しかける時の方角を意識する、お店で座る席や どちらに向くか意識する、深呼吸をする方角、 など、あなたが自由に決められます。 決めた行動により、惑星たちのエネルギーが あなたに届くでしょう。 惑星たちは常に大きな視点であなたを見守っています。 スコアバーをタップするとカテゴリが切替わります (総合 → 癒し → 豊かさ → 恋愛 → 仕事 → 話す)。 見たいカテゴリを選ぶと、そのエネルギーが どの方位に強く出ているかが分かります。'
	String get dirBody => '基準地点 (VIEWPOINT) を中心に、地表の 16 方位\n(北・北北東・北東・東北東・東…) ごとのエネルギーを\nスコア化して表示しています。\n「どの土地・方向に意識を向けるべきか」が判断できます。\n\nどの方向に進むべきかだけの表示ではありません。\nもちろん方角に向かい進む事も一つの方角に対する\n行動です。他には、意識を向ける事や、声をかける、\n大切なアイテムの置き場所を方角に合わせて家を出発する、\n話しかける時の方角を意識する、お店で座る席や\nどちらに向くか意識する、深呼吸をする方角、\nなど、あなたが自由に決められます。\n決めた行動により、惑星たちのエネルギーが\nあなたに届くでしょう。\n惑星たちは常に大きな視点であなたを見守っています。\n\nスコアバーをタップするとカテゴリが切替わります\n(総合 → 癒し → 豊かさ → 恋愛 → 仕事 → 話す)。\n見たいカテゴリを選ぶと、そのエネルギーが\nどの方位に強く出ているかが分かります。';

	/// ja: '【基準地点を登録する】'
	String get regTitle => '【基準地点を登録する】';

	/// ja: '基準地点は地図画面の左側にある '
	String get regPre => '基準地点は地図画面の左側にある ';

	/// ja: ' (VIEWPOINT) ボタン から登録できます。 登録したい場所を地図中央に表示してパネルを開き、 「この地点を保存」をタップすると、その地点が VIEWPOINT として保存されます。 保存した基準地点は、検索結果一覧の上部や 下部メニューの「Daily」チップ内のプルダウンから、 いつでも切り替えて使えます。'
	String get regPost => ' (VIEWPOINT) ボタン\nから登録できます。\n登録したい場所を地図中央に表示してパネルを開き、\n「この地点を保存」をタップすると、その地点が\nVIEWPOINT として保存されます。\n\n保存した基準地点は、検索結果一覧の上部や\n下部メニューの「Daily」チップ内のプルダウンから、\nいつでも切り替えて使えます。';

	/// ja: '【場所を探す】'
	String get findTitle => '【場所を探す】';

	/// ja: '検索ボタンから買い物・待ち合わせ・お店などを 検索すると、その地点が今どの惑星から エネルギーを受けているかを確認できます。'
	String get findBody => '検索ボタンから買い物・待ち合わせ・お店などを\n検索すると、その地点が今どの惑星から\nエネルギーを受けているかを確認できます。';

	/// ja: '【時間を読む】'
	String get timeTitle => '【時間を読む】';

	/// ja: '下部メニューの「Daily」チップから 「行動する時間の指針」が分かります。 ※「Daily」チップの画面は「天空方位」(惑星が空の どこにいつ来るか) を扱い、この Map の「地表方位」 (どの土地に向かうか) とは別物です。 スコアバー (地表方位の強さ) と「Daily」チップ (天空方位 × 時刻) を組み合わせると、 あなたの望む未来に対する最適な 「方角 × 時間」を Solara が算出します。'
	String get timeBody => '下部メニューの「Daily」チップから\n「行動する時間の指針」が分かります。\n※「Daily」チップの画面は「天空方位」(惑星が空の\n　 どこにいつ来るか) を扱い、この Map の「地表方位」\n　 (どの土地に向かうか) とは別物です。\n\nスコアバー (地表方位の強さ) と「Daily」チップ\n(天空方位 × 時刻) を組み合わせると、\nあなたの望む未来に対する最適な\n「方角 × 時間」を Solara が算出します。';
}

// Path: mapFortune.catPlanets
class Translations$mapFortune$catPlanets$ja {
	Translations$mapFortune$catPlanets$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'カテゴリと関連惑星'
	String get title => 'カテゴリと関連惑星';

	/// ja: '各カテゴリは、関連する惑星ペアのアスペクトを抽出し、 ペア重みをかけて方位ごとにスコア化しています。 (ペア重みの仕組みは下に詳しく説明)'
	String get intro => '各カテゴリは、関連する惑星ペアのアスペクトを抽出し、\nペア重みをかけて方位ごとにスコア化しています。\n(ペア重みの仕組みは下に詳しく説明)';

	/// ja: '【ペア重みの仕組み】'
	String get weightTitle => '【ペア重みの仕組み】';

	/// ja: 'カテゴリ別スコアは、関連する惑星ペアのアスペクトを抽出し、 ペアの「中心度」に応じた重みをかけて合算しています。 ・主役ペア (重み 2.0) そのカテゴリの中心テーマを担う惑星ペア。 例: 恋愛 = 金星×火星 / 仕事 = 土星×太陽 → アスペクト出現時は 2 倍の影響力で計上されます。 ・サブペア (重み 0.5) 片方の惑星だけがカテゴリに関わるアスペクト。 例: 恋愛で「金星×木星」(金星のみ love 担当) → 0.5 倍の控えめな影響力で計上されます。 ・ペア外 (重み 0) 両方ともカテゴリに関係ない惑星のアスペクト。 → そのカテゴリのスコアには反映されません。 この「重み付け」により、カテゴリの「中心テーマ」を 反映した精度の高いスコアが得られます。 ペア重みなしの単純合算では、カテゴリの個性が ぼやけてしまうため、加重計算で精緻化しています。'
	String get weightBody => 'カテゴリ別スコアは、関連する惑星ペアのアスペクトを抽出し、\nペアの「中心度」に応じた重みをかけて合算しています。\n\n・主役ペア (重み 2.0)\n　そのカテゴリの中心テーマを担う惑星ペア。\n　例: 恋愛 = 金星×火星 / 仕事 = 土星×太陽\n　→ アスペクト出現時は 2 倍の影響力で計上されます。\n\n・サブペア (重み 0.5)\n　片方の惑星だけがカテゴリに関わるアスペクト。\n　例: 恋愛で「金星×木星」(金星のみ love 担当)\n　→ 0.5 倍の控えめな影響力で計上されます。\n\n・ペア外 (重み 0)\n　両方ともカテゴリに関係ない惑星のアスペクト。\n　→ そのカテゴリのスコアには反映されません。\n\nこの「重み付け」により、カテゴリの「中心テーマ」を\n反映した精度の高いスコアが得られます。\nペア重みなしの単純合算では、カテゴリの個性が\nぼやけてしまうため、加重計算で精緻化しています。';

	/// ja: '【総合との関係】'
	String get overallTitle => '【総合との関係】';

	/// ja: '上部スコアバーで「総合」を選んでいる時の数字は、 全惑星・全アスペクトをそのまま合算した値です。 カテゴリ重みは入りません (= ペア重みなし)。 一方、カテゴリ別 (癒し / 豊かさ / 恋愛 / 仕事 / 話す) は 上記のペア重みがかかります。 さらに 1 つのアスペクトが複数カテゴリに重複計上される こともあります (例: 金星×木星 → 恋愛にも豊かさにも入る)。 このため「カテゴリ別 5 つの単純合算 ≠ 総合」となります。 両者は別の角度からエネルギーを見るための数値で、 どちらが正しいということはありません。 ・カテゴリ別 = カテゴリの「集中度」を見る ・総合 = 全体の「総量」を見る'
	String get overallBody => '上部スコアバーで「総合」を選んでいる時の数字は、\n全惑星・全アスペクトをそのまま合算した値です。\nカテゴリ重みは入りません (= ペア重みなし)。\n\n一方、カテゴリ別 (癒し / 豊かさ / 恋愛 / 仕事 / 話す) は\n上記のペア重みがかかります。\nさらに 1 つのアスペクトが複数カテゴリに重複計上される\nこともあります (例: 金星×木星 → 恋愛にも豊かさにも入る)。\n\nこのため「カテゴリ別 5 つの単純合算 ≠ 総合」となります。\n両者は別の角度からエネルギーを見るための数値で、\nどちらが正しいということはありません。\n・カテゴリ別 = カテゴリの「集中度」を見る\n・総合 = 全体の「総量」を見る';
}

// Path: galaxy.phaseDesc
class Translations$galaxy$phaseDesc$ja {
	Translations$galaxy$phaseDesc$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '始まりの時。 空が最も暗く、星々が最もよく見える夜。 新しい意図を立て、種を蒔く時間帯です。'
	String get newMoon => '始まりの時。\n空が最も暗く、星々が最もよく見える夜。\n新しい意図を立て、種を蒔く時間帯です。';

	/// ja: '芽吹きの時。 細い光が西の空に現れます。 新月で蒔いた意図に向けて、少しずつ動き出す時間帯。'
	String get crescent => '芽吹きの時。\n細い光が西の空に現れます。\n新月で蒔いた意図に向けて、少しずつ動き出す時間帯。';

	/// ja: '行動の時。 半月が天頂に達し、決断と行動が求められます。 芽生えた意図を形にしていく転換点。'
	String get firstQuarter => '行動の時。\n半月が天頂に達し、決断と行動が求められます。\n芽生えた意図を形にしていく転換点。';

	/// ja: '高まりの時。 月が満ちていく勢いがピークに近づきます。 準備が整い、表現が膨らむ時間帯。'
	String get gibbous13 => '高まりの時。\n月が満ちていく勢いがピークに近づきます。\n準備が整い、表現が膨らむ時間帯。';

	/// ja: '達成・解放の時。 月が最も明るく輝く夜。 気づきと完了がやってきます。 手にしたものを見つめ直し、感謝する時間帯。'
	String get fullMoon => '達成・解放の時。\n月が最も明るく輝く夜。\n気づきと完了がやってきます。\n手にしたものを見つめ直し、感謝する時間帯。';

	/// ja: '共有の時。 月が欠け始めます。 満月で得た学びを他者と分かち合う時間帯。'
	String get waningGibbous18 => '共有の時。\n月が欠け始めます。\n満月で得た学びを他者と分かち合う時間帯。';

	/// ja: '手放しの時。 半月が逆向きに浮かびます。 不要なものを整理し、ゆるめる時間帯。'
	String get lastQuarter => '手放しの時。\n半月が逆向きに浮かびます。\n不要なものを整理し、ゆるめる時間帯。';

	/// ja: '休息の時。 空に薄い月が残ります。 次のサイクルへ向けて静かに整える時間帯。'
	String get waning26 => '休息の時。\n空に薄い月が残ります。\n次のサイクルへ向けて静かに整える時間帯。';

	/// ja: '月のサイクルが流れています。'
	String get flowing => '月のサイクルが流れています。';
}

// Path: galaxy.events
class Translations$galaxy$events$ja {
	Translations$galaxy$events$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '月のイベントについて'
	String get title => '月のイベントについて';

	/// ja: 'このサイクルでは、月の満ち欠けに合わせて 3 つの節目があなたを訪れます。'
	String get intro => 'このサイクルでは、月の満ち欠けに合わせて\n3 つの節目があなたを訪れます。';

	/// ja: '🌑 新月イベント'
	String get newTitle => '🌑 新月イベント';

	/// ja: '新月の日に「意図（インテンション）」を立てる出発点。 このサイクルで大切にしたいことを言葉にします。 すべてはここから始まります。'
	String get newBody => '新月の日に「意図（インテンション）」を立てる出発点。\nこのサイクルで大切にしたいことを言葉にします。\nすべてはここから始まります。';

	/// ja: '🌕 満月イベント'
	String get fullTitle => '🌕 満月イベント';

	/// ja: '満月の日に、立てた意図への中間チェック（振り返り）。 ※ 新月で意図を立てていないと出てきません。'
	String get fullBody => '満月の日に、立てた意図への中間チェック（振り返り）。\n※ 新月で意図を立てていないと出てきません。';

	/// ja: '✦ 刻星化イベント'
	String get catTitle => '✦ 刻星化イベント';

	/// ja: '次の新月の前日以降に訪れる、サイクルの締めくくり。 手放しと、あなただけの星座の形成です。 ※ こちらも新月で意図を立てているのが前提です。'
	String get catBody => '次の新月の前日以降に訪れる、サイクルの締めくくり。\n手放しと、あなただけの星座の形成です。\n※ こちらも新月で意図を立てているのが前提です。';

	/// ja: '🔔 通知をオンにするのがおすすめ'
	String get notifyTitle => '🔔 通知をオンにするのがおすすめ';

	/// ja: '各イベントは「その日」だけ訪れます。 Sanctuary で通知をオンにしておくと、 当日の朝にお知らせします。 満月・刻星化は新月の意図設定が前提なので、 まず新月を逃さないことが大切です。'
	String get notifyBody => '各イベントは「その日」だけ訪れます。\nSanctuary で通知をオンにしておくと、\n当日の朝にお知らせします。\n\n満月・刻星化は新月の意図設定が前提なので、\nまず新月を逃さないことが大切です。';
}

// Path: galaxy.guide
class Translations$galaxy$guide$ja {
	Translations$galaxy$guide$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Galaxy 画面とは'
	String get title => 'Galaxy 画面とは';

	/// ja: '月のサイクル (約 29.5 日) に合わせて、 あなたの日々のタロットリーディングが 「星」として記録されていく画面です。 1 サイクル = 1 つの constellation (星座) が完成。 内面のリズムが、星座という形で残っていきます。'
	String get intro => '月のサイクル (約 29.5 日) に合わせて、\nあなたの日々のタロットリーディングが\n「星」として記録されていく画面です。\n\n1 サイクル = 1 つの constellation (星座) が完成。\n内面のリズムが、星座という形で残っていきます。';

	/// ja: '🌌 CYCLE タブ (現在のサイクル)'
	String get cycleTitle => '🌌 CYCLE タブ (現在のサイクル)';

	/// ja: '今の月サイクルの「現在地」を表示。 日々の reading を描いた "dot" が螺旋上に並び、 完成に向けて進んでいきます。 ・右上の数字: サイクル何日目か (例: 23 of 30) ・左上の月齢バッジ: 今日の月の相 (← 今ココ) ・ドラッグで 3D 回転 ・dot タップで該当日のリーディングを表示 ・新月・満月の日は特別オーバーレイで 意図を立てる/振り返るアクションを促します'
	String get cycleBody => '今の月サイクルの「現在地」を表示。\n日々の reading を描いた "dot" が螺旋上に並び、\n完成に向けて進んでいきます。\n\n・右上の数字: サイクル何日目か (例: 23 of 30)\n・左上の月齢バッジ: 今日の月の相 (← 今ココ)\n・ドラッグで 3D 回転\n・dot タップで該当日のリーディングを表示\n・新月・満月の日は特別オーバーレイで\n　意図を立てる/振り返るアクションを促します';

	/// ja: '🌟 Star Atlas タブ (過去の星座図鑑)'
	String get atlasTitle => '🌟 Star Atlas タブ (過去の星座図鑑)';

	/// ja: '完成した過去のサイクル (= 星座) のコレクション。 1 つ 1 つが、あなた自身の内面が紡いだ星座です。 ・各カードは 1 サイクル分の reading が織りなす星座 ・カードタップで再アニメ + 詳細表示 (星座名・期間・レア度) ・レア度: 5 段階の星評価 (★) レア度が高いほど「珍しい組み合わせ」が出た証'
	String get atlasBody => '完成した過去のサイクル (= 星座) のコレクション。\n1 つ 1 つが、あなた自身の内面が紡いだ星座です。\n\n・各カードは 1 サイクル分の reading が織りなす星座\n・カードタップで再アニメ + 詳細表示\n　(星座名・期間・レア度)\n・レア度: 5 段階の星評価 (★)\n　レア度が高いほど「珍しい組み合わせ」が出た証';

	/// ja: '月のサイクルの意味'
	String get meaningTitle => '月のサイクルの意味';

	/// ja: '🌑 新月 → 始まり。種を蒔く時。 🌕 満月 → 達成・解放。気づきの時。 1 サイクルかけて、あなたの内面が 1 つの星座に なっていきます。Tarot タブで日々のカードを 引いて、ゆっくり育てていってください。'
	String get meaningBody => '🌑 新月 → 始まり。種を蒔く時。\n🌕 満月 → 達成・解放。気づきの時。\n\n1 サイクルかけて、あなたの内面が 1 つの星座に\nなっていきます。Tarot タブで日々のカードを\n引いて、ゆっくり育てていってください。';
}

// Path: forecast.legend
class Translations$forecast$legend$ja {
	Translations$forecast$legend$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '赤=年内最低'
	String get relLowRed => '赤=年内最低';

	/// ja: '緑=年内最低'
	String get relLowGreen => '緑=年内最低';

	/// ja: '緑=年内最高'
	String get relHighGreen => '緑=年内最高';

	/// ja: '赤=年内最高'
	String get relHighRed => '赤=年内最高';

	/// ja: '$low / $high （min:$min → max:$max）'
	String relRange({required Object low, required Object high, required Object min, required Object max}) => '${low}  /  ${high}  （min:${min} → max:${max}）';

	/// ja: '赤=45以下'
	String get absLowRed => '赤=45以下';

	/// ja: '緑=45以下'
	String get absLowGreen => '緑=45以下';

	/// ja: '緑=85以上'
	String get absHighGreen => '緑=85以上';

	/// ja: '赤=85以上'
	String get absHighRed => '赤=85以上';

	/// ja: '$low / 黄=65 / $high （固定スケール）'
	String absScale({required Object low, required Object high}) => '${low}  /  黄=65  /  ${high}  （固定スケール）';

	/// ja: '色=$rank位カテゴリ / 濃さ=スコア高低'
	String catRank({required Object rank}) => '色=${rank}位カテゴリ / 濃さ=スコア高低';
}

// Path: forecast.usage
class Translations$forecast$usage$ja {
	Translations$forecast$usage$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'FORECAST の使い方'
	String get title => 'FORECAST の使い方';

	/// ja: 'あなたの今後 1 年 (365 日) の星のリズムを表示します。 日々の総合スコア・カテゴリ別スコアを一目で把握でき、 動きやすい日 / 慎重に進める日を事前に確認できます。'
	String get intro => 'あなたの今後 1 年 (365 日) の星のリズムを表示します。\n日々の総合スコア・カテゴリ別スコアを一目で把握でき、\n動きやすい日 / 慎重に進める日を事前に確認できます。';

	/// ja: '【1 年ヒートマップ】'
	String get s1Title => '【1 年ヒートマップ】';

	/// ja: '12 ヶ月 × 31 日のグリッドで、各日のスコアを色で表現。 モード切替 (相対 / 絶対 / カテゴリ)、色方向 (緑↑高 / 赤↑高)、ランク (1 位 / 2 位) で見せ方を変えられます。 詳細はヒートマップ右の i ボタンを参照してください。'
	String get s1Body => '12 ヶ月 × 31 日のグリッドで、各日のスコアを色で表現。\nモード切替 (相対 / 絶対 / カテゴリ)、色方向 (緑↑高 /\n赤↑高)、ランク (1 位 / 2 位) で見せ方を変えられます。\n詳細はヒートマップ右の i ボタンを参照してください。';

	/// ja: '【選択日詳細】'
	String get s2Title => '【選択日詳細】';

	/// ja: 'ヒートマップで日をタップすると、その日の方位スコアと カテゴリ別ランキングが下に表示されます。'
	String get s2Body => 'ヒートマップで日をタップすると、その日の方位スコアと\nカテゴリ別ランキングが下に表示されます。';

	/// ja: '【あなたの星のサイクル】'
	String get s3Title => '【あなたの星のサイクル】';

	/// ja: 'カテゴリ別の「期間」(モテ期 / 豊かさ期 / 癒し期 等) を 表示。今日以降に到来する継続期間のみ表示します。 長期計画の指針に。'
	String get s3Body => 'カテゴリ別の「期間」(モテ期 / 豊かさ期 / 癒し期 等) を\n表示。今日以降に到来する継続期間のみ表示します。\n長期計画の指針に。';

	/// ja: '【ハイライト Top5】'
	String get s4Title => '【ハイライト Top5】';

	/// ja: 'カテゴリ別の上位 5 日を表示。「いつ動くか」の 短期ピンポイント計画に。'
	String get s4Body => 'カテゴリ別の上位 5 日を表示。「いつ動くか」の\n短期ピンポイント計画に。';

	/// ja: '【Map 画面の数字との関係】'
	String get s5Title => '【Map 画面の数字との関係】';

	/// ja: 'FORECAST の数字と、Map で同じ日を開いた時の数字は 一致しません。これは別計算だからです。 ・FORECAST = あなたの出生情報のみで算出。 地球のどこにいても、何時に見ても変わらない、 あなた自身に流れているエネルギーを 1 年分追跡。 ・Map = 今いる地点 + 今この瞬間で算出。 ASC (地平線) と MC (天頂) を含むため、 地点が変われば数字が変わり、同じ日でも 12:00 と 19:00 で違う数字になります (ASC は 15°/時間で動くため)。 どちらが正しい・間違いではなく、別の角度から 同じあなたを読み取る 2 つのレンズです。 ・FORECAST で「動きやすい時期」を掴み ・Map で「その地点・その時刻」を詳しく読む という使い分けで両方使えます。'
	String get s5Body => 'FORECAST の数字と、Map で同じ日を開いた時の数字は\n一致しません。これは別計算だからです。\n\n・FORECAST = あなたの出生情報のみで算出。\n　地球のどこにいても、何時に見ても変わらない、\n　あなた自身に流れているエネルギーを 1 年分追跡。\n\n・Map = 今いる地点 + 今この瞬間で算出。\n　ASC (地平線) と MC (天頂) を含むため、\n　地点が変われば数字が変わり、同じ日でも\n　12:00 と 19:00 で違う数字になります\n　(ASC は 15°/時間で動くため)。\n\nどちらが正しい・間違いではなく、別の角度から\n同じあなたを読み取る 2 つのレンズです。\n・FORECAST で「動きやすい時期」を掴み\n・Map で「その地点・その時刻」を詳しく読む\nという使い分けで両方使えます。';
}

// Path: forecast.heatmapInfo
class Translations$forecast$heatmapInfo$ja {
	Translations$forecast$heatmapInfo$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '1 年ヒートマップの読み方'
	String get title => '1 年ヒートマップの読み方';

	/// ja: '【3 つの色モード】'
	String get s1Title => '【3 つの色モード】';

	/// ja: '■ 相対モード (デフォルト) 1 年内の最低 → 最高で正規化。 あなたの 365 日のうち相対的に高い日が明るく 見えます。日々の濃淡を最大化して把握できます。 ■ 絶対モード スコアの絶対値で色化。低い値は暗く、 高い値は明るい。他の年・他のユーザーと 比較する時に使います。 ■ カテゴリモード 日ごとに最も強いカテゴリを色で表現: 🟢 癒し 🟡 豊かさ 🩷 恋愛 🔵 仕事 🟣 話す 同じ色が連続している期間が、そのカテゴリの 「波」が来ている時期です。 ・🩷 が連続 → モテ期 (関係性のエネルギーが流れる) ・🟡 が連続 → 豊かさ期 ・🟢 が連続 → 癒し期 ・🔵 が連続 → 仕事期 ・🟣 が連続 → 発信期 これらの「○○期」は下の「あなたの星のサイクル」 セクションでも、開始日・終了日付きで一覧表示されます (7 日以上の継続のみ抽出)。'
	String get s1Body => '■ 相対モード (デフォルト)\n1 年内の最低 → 最高で正規化。\nあなたの 365 日のうち相対的に高い日が明るく\n見えます。日々の濃淡を最大化して把握できます。\n\n■ 絶対モード\nスコアの絶対値で色化。低い値は暗く、\n高い値は明るい。他の年・他のユーザーと\n比較する時に使います。\n\n■ カテゴリモード\n日ごとに最も強いカテゴリを色で表現:\n　🟢 癒し　🟡 豊かさ　🩷 恋愛\n　🔵 仕事　🟣 話す\n\n同じ色が連続している期間が、そのカテゴリの\n「波」が来ている時期です。\n・🩷 が連続 → モテ期 (関係性のエネルギーが流れる)\n・🟡 が連続 → 豊かさ期\n・🟢 が連続 → 癒し期\n・🔵 が連続 → 仕事期\n・🟣 が連続 → 発信期\n\nこれらの「○○期」は下の「あなたの星のサイクル」\nセクションでも、開始日・終了日付きで一覧表示されます\n(7 日以上の継続のみ抽出)。';

	/// ja: '【色方向 (🟢↑高 / 🔴↑高)】'
	String get s2Title => '【色方向 (🟢↑高 / 🔴↑高)】';

	/// ja: '「相対」「絶対」モードで有効です。 ・🟢↑高: 高スコア=緑、低スコア=赤 ・🔴↑高: 高スコア=赤、低スコア=緑 (反転) 吉凶判定を避けるため、見たい色の方向を あなた自身で選べます。'
	String get s2Body => '「相対」「絶対」モードで有効です。\n・🟢↑高: 高スコア=緑、低スコア=赤\n・🔴↑高: 高スコア=赤、低スコア=緑 (反転)\n\n吉凶判定を避けるため、見たい色の方向を\nあなた自身で選べます。';

	/// ja: '【ランク (1 位 / 2 位)】'
	String get s3Title => '【ランク (1 位 / 2 位)】';

	/// ja: '「カテゴリ」モードで有効です。 ・1 位: その日の最強カテゴリ色で塗る ・2 位: 2 番目に強いカテゴリ色で塗る 両方確認すると、1 日の中の「主役」と「サブ」が 見えてきます。'
	String get s3Body => '「カテゴリ」モードで有効です。\n・1 位: その日の最強カテゴリ色で塗る\n・2 位: 2 番目に強いカテゴリ色で塗る\n\n両方確認すると、1 日の中の「主役」と「サブ」が\n見えてきます。';

	/// ja: '※ 同じ日でも Map で開いた数字とは別の指標です (場所・時刻に依存しない計算)。 詳細は画面上部 ❓ ボタンの「Map 画面の数字との関係」へ。'
	String get footer => '※ 同じ日でも Map で開いた数字とは別の指標です\n(場所・時刻に依存しない計算)。\n詳細は画面上部 ❓ ボタンの「Map 画面の数字との関係」へ。';
}

// Path: forecast.cycles
class Translations$forecast$cycles$ja {
	Translations$forecast$cycles$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'あなたの星のサイクル'
	String get title => 'あなたの星のサイクル';

	/// ja: '今日以降に到来する期間を表示（7日以上の継続）'
	String get hint => '今日以降に到来する期間を表示（7日以上の継続）';

	/// ja: '今日以降に到来する期間はありません'
	String get empty => '今日以降に到来する期間はありません';

	/// ja: '星のサイクルとは'
	String get infoTitle => '星のサイクルとは';

	/// ja: '【表示の意味】'
	String get s1Title => '【表示の意味】';

	/// ja: '今後 1 年で、各カテゴリ (恋愛 / 豊かさ / 癒し / 仕事 / 話す) のエネルギーが強く流れる「期間」を 表示します。 例:「💗 モテ期 6/15 〜 7/2 (18 日間)」 → 6/15 から 7/2 まで関係性のエネルギーが 継続して強い時期'
	String get s1Body => '今後 1 年で、各カテゴリ (恋愛 / 豊かさ / 癒し /\n仕事 / 話す) のエネルギーが強く流れる「期間」を\n表示します。\n\n例:「💗 モテ期 6/15 〜 7/2 (18 日間)」\n　 → 6/15 から 7/2 まで関係性のエネルギーが\n　   継続して強い時期';

	/// ja: '【表示条件】'
	String get s2Title => '【表示条件】';

	/// ja: '・今日以降に到来する期間のみ表示 (過ぎた期間は非表示) ・7 日以上連続して強い場合のみ「期間」と認定 (短い波は表示しない) ・カテゴリごとに最も近い 1 件ずつ表示'
	String get s2Body => '・今日以降に到来する期間のみ表示\n　(過ぎた期間は非表示)\n・7 日以上連続して強い場合のみ「期間」と認定\n　(短い波は表示しない)\n・カテゴリごとに最も近い 1 件ずつ表示';

	/// ja: '【活用方法】'
	String get s3Title => '【活用方法】';

	/// ja: '「いつ動くか」の長期計画に。 その期間の中で具体的な 1 日を Map 画面で確認すると、 その地点・時刻での方角と時間が見えます。'
	String get s3Body => '「いつ動くか」の長期計画に。\nその期間の中で具体的な 1 日を Map 画面で確認すると、\nその地点・時刻での方角と時間が見えます。';

	/// ja: '※ 同じ期間のスコアでも Map で開いた数字とは別の指標です (場所・時刻に依存しない計算)。 詳細は画面上部 ❓ ボタンの「Map 画面の数字との関係」へ。'
	String get footer => '※ 同じ期間のスコアでも Map で開いた数字とは別の指標です\n(場所・時刻に依存しない計算)。\n詳細は画面上部 ❓ ボタンの「Map 画面の数字との関係」へ。';
}

// Path: forecast.top5
class Translations$forecast$top5$ja {
	Translations$forecast$top5$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'ハイライトTop5'
	String get title => 'ハイライトTop5';

	/// ja: '$year年'
	String year({required Object year}) => '${year}年';

	/// ja: 'ハイライト Top5 の読み方'
	String get infoTitle => 'ハイライト Top5 の読み方';

	/// ja: '【表示の意味】'
	String get s1Title => '【表示の意味】';

	/// ja: '表示中の年 (1/1〜12/31) で、選択中の カテゴリのスコアが最も高い 5 日を表示します。'
	String get s1Body => '表示中の年 (1/1〜12/31) で、選択中の\nカテゴリのスコアが最も高い 5 日を表示します。';

	/// ja: '【カテゴリ切替】'
	String get s2Title => '【カテゴリ切替】';

	/// ja: '総合 / 恋愛 / 豊かさ / 癒し / 仕事 / 話す から選択。 選んだカテゴリの上位 5 日が表示されます。'
	String get s2Body => '総合 / 恋愛 / 豊かさ / 癒し / 仕事 / 話す から選択。\n選んだカテゴリの上位 5 日が表示されます。';

	/// ja: '【順位マーカー】'
	String get s3Title => '【順位マーカー】';

	/// ja: '👑 1 位 / 🥈 2 位 / 🥉 3 位 / ⭐ 4 位 / ✨ 5 位'
	String get s3Body => '👑 1 位 / 🥈 2 位 / 🥉 3 位 / ⭐ 4 位 / ✨ 5 位';

	/// ja: '【行の見方】'
	String get s4Title => '【行の見方】';

	/// ja: '日付 — 選択中カテゴリのその日のスコア タップで選択日詳細にジャンプ。 (その日の高まる方位は選択日詳細で確認できます)'
	String get s4Body => '日付 — 選択中カテゴリのその日のスコア\nタップで選択日詳細にジャンプ。\n(その日の高まる方位は選択日詳細で確認できます)';

	/// ja: '【活用方法】'
	String get s5Title => '【活用方法】';

	/// ja: '「動きどころ」の短期ピンポイント計画に。 特に 1 位の日は、そのカテゴリのテーマで動くと エネルギーが特に強く流れる日です。'
	String get s5Body => '「動きどころ」の短期ピンポイント計画に。\n特に 1 位の日は、そのカテゴリのテーマで動くと\nエネルギーが特に強く流れる日です。';

	/// ja: '※ 同じ日でも Map で開いた数字とは別の指標です (場所・時刻に依存しない計算)。 詳細は画面上部 ❓ ボタンの「Map 画面の数字との関係」へ。'
	String get footer => '※ 同じ日でも Map で開いた数字とは別の指標です\n(場所・時刻に依存しない計算)。\n詳細は画面上部 ❓ ボタンの「Map 画面の数字との関係」へ。';
}

// Path: consultResult.exhaust
class Translations$consultResult$exhaust$ja {
	Translations$consultResult$exhaust$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'この条件では、いま強く惹かれる土地が見当たりませんでした。'
	String get allQuiet => 'この条件では、いま強く惹かれる土地が見当たりませんでした。';

	/// ja: 'これ以上の新しい候補地は見つかりませんでした。'
	String get noFresh => 'これ以上の新しい候補地は見つかりませんでした。';

	/// ja: 'この範囲には候補が見つかりませんでした。'
	String get emptyPool => 'この範囲には候補が見つかりませんでした。';

	/// ja: 'これ以上は無理に候補を作りませんでした。'
	String get fallback => 'これ以上は無理に候補を作りませんでした。';

	/// ja: '条件を変えると見つかるかもしれません:'
	String get tipsLead => '条件を変えると見つかるかもしれません:';

	/// ja: '※ この案内ではクレジットを消費していません。'
	String get noCredit => '※ この案内ではクレジットを消費していません。';
}

// Path: consultResult.suggest
class Translations$consultResult$suggest$ja {
	Translations$consultResult$suggest$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '半径を広げてみる'
	String get widenRadius => '半径を広げてみる';

	/// ja: '方角で探す'
	String get bearing => '方角で探す';

	/// ja: '具体的な場所を指定する'
	String get point => '具体的な場所を指定する';

	/// ja: '世界全体に広げる'
	String get world => '世界全体に広げる';
}

// Path: consultResult.delta
class Translations$consultResult$delta$ja {
	Translations$consultResult$delta$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '${m}分経過後を見る'
	String open({required Object m}) => '${m}分経過後を見る';

	/// ja: '${m}分後の変化を閉じる'
	String close({required Object m}) => '${m}分後の変化を閉じる';

	/// ja: '「30分経過後を見る」とは'
	String get infoTitle => '「30分経過後を見る」とは';

	/// ja: 'アストロカートグラフィの星の線は、地球の自転で刻一刻と動いています。 惑星が真上や地平線に来る「角ライン」は、${m}分でおよそ 7.5°——中緯度で約 800km も西へ進みます。 だから同じ場所でも、選んだ時刻と${m}分後では「その場の主役」が静かに入れ替わることがあります。火星の線が離れていく、金星の線が近づいてくる——その移ろいを先に知っておくと、「核心は前半に」「後半にかけて温まる」のように、その場での時間の使い方が見えてきます。 吉凶ではなく、エネルギーの“質の移り変わり”として読んでいます。Cosmic Pro・おでかけで時刻を指定したときに見られます。'
	String infoBody({required Object m}) => 'アストロカートグラフィの星の線は、地球の自転で刻一刻と動いています。\n惑星が真上や地平線に来る「角ライン」は、${m}分でおよそ 7.5°——中緯度で約 800km も西へ進みます。\n\nだから同じ場所でも、選んだ時刻と${m}分後では「その場の主役」が静かに入れ替わることがあります。火星の線が離れていく、金星の線が近づいてくる——その移ろいを先に知っておくと、「核心は前半に」「後半にかけて温まる」のように、その場での時間の使い方が見えてきます。\n\n吉凶ではなく、エネルギーの“質の移り変わり”として読んでいます。Cosmic Pro・おでかけで時刻を指定したときに見られます。';

	/// ja: '近づく'
	String get approaching => '近づく';

	/// ja: '差してくる'
	String get entering => '差してくる';

	/// ja: '離れる'
	String get receding => '離れる';

	/// ja: '外れる'
	String get leaving => '外れる';

	/// ja: '安定'
	String get steady => '安定';

	/// ja: '$planet $angle・$label'
	String chip({required Object planet, required Object angle, required Object label}) => '${planet} ${angle}・${label}';
}

// Path: consultResult.pro
class Translations$consultResult$pro$ja {
	Translations$consultResult$pro$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Stella 相談'
	String get consultLabel => 'Stella 相談';

	/// ja: 'Cosmic Pro なら回数無制限で読み解けます。'
	String get consultDesc => 'Cosmic Pro なら回数無制限で読み解けます。';

	/// ja: '移住・旅行の相談'
	String get migrationLabel => '移住・旅行の相談';

	/// ja: 'おでかけ・イベント以外の相談も、Cosmic Pro なら無制限に。'
	String get migrationDesc => 'おでかけ・イベント以外の相談も、Cosmic Pro なら無制限に。';

	/// ja: '候補の出し直し'
	String get refreshLabel => '候補の出し直し';

	/// ja: '別の候補を何度でも見比べられます。'
	String get refreshDesc => '別の候補を何度でも見比べられます。';

	/// ja: 'Stella 相談'
	String get weeklyLabel => 'Stella 相談';

	/// ja: '今週の無料の相談を使い切りました。Cosmic Pro なら回数無制限・thinking でより深く読み解きます。'
	String get weeklyDesc => '今週の無料の相談を使い切りました。Cosmic Pro なら回数無制限・thinking でより深く読み解きます。';
}

// Path: consultResult.block
class Translations$consultResult$block$ja {
	Translations$consultResult$block$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'このモードは Cosmic Pro で'
	String get proOnlyModeTitle => 'このモードは Cosmic Pro で';

	/// ja: 'おでかけ・イベント以外の相談 (移住・旅行) は Cosmic Pro で読み解けます。'
	String get proOnlyModeBody => 'おでかけ・イベント以外の相談 (移住・旅行) は Cosmic Pro で読み解けます。';

	/// ja: '候補の出し直しは Cosmic Pro で'
	String get proOnlyRefreshTitle => '候補の出し直しは Cosmic Pro で';

	/// ja: '別の候補を何度でも見比べられます。'
	String get proOnlyRefreshBody => '別の候補を何度でも見比べられます。';

	/// ja: '今週の Pro 相談上限に達しました'
	String get proWeeklyTitle => '今週の Pro 相談上限に達しました';

	/// ja: 'Cosmic Pro は週 100 回まで Stella に相談できます。月曜日に補充されます。すぐ続けるなら、追加クレジットの購入が選べます。'
	String get proWeeklyBody => 'Cosmic Pro は週 100 回まで Stella に相談できます。月曜日に補充されます。すぐ続けるなら、追加クレジットの購入が選べます。';

	/// ja: 'Pro 状態を同期しています'
	String get proSyncTitle => 'Pro 状態を同期しています';

	/// ja: 'Cosmic Pro の課金状態をストアと再確認しています。クレジットは消費されていません。数十秒待ってからもう一度お試しください。'
	String get proSyncBody => 'Cosmic Pro の課金状態をストアと再確認しています。クレジットは消費されていません。数十秒待ってからもう一度お試しください。';

	/// ja: '相談クレジットを使い切りました'
	String get exhaustedTitle => '相談クレジットを使い切りました';

	/// ja: '無料の Stella 相談は週ごとに補充されます。すぐ続けるなら、追加クレジットの購入か、回数無制限の Cosmic Pro が選べます。'
	String get exhaustedBody => '無料の Stella 相談は週ごとに補充されます。すぐ続けるなら、追加クレジットの購入か、回数無制限の Cosmic Pro が選べます。';

	/// ja: '追加クレジットを購入'
	String get buyCredits => '追加クレジットを購入';

	/// ja: '✦ Cosmic Pro で無制限にする'
	String get goUnlimited => '✦ Cosmic Pro で無制限にする';

	/// ja: '✦ Cosmic Pro を見る'
	String get seePro => '✦ Cosmic Pro を見る';
}

// Path: consultResult.shareSheet
class Translations$consultResult$shareSheet$ja {
	Translations$consultResult$shareSheet$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'テキストをコピー'
	String get copyText => 'テキストをコピー';

	/// ja: '相談結果を clipboard に整形してコピー'
	String get copyTextSub => '相談結果を clipboard に整形してコピー';

	/// ja: '画像で共有'
	String get shareImage => '画像で共有';

	/// ja: '結果画面を PNG にして OS 標準シェアで共有'
	String get shareImageSub => '結果画面を PNG にして OS 標準シェアで共有';

	/// ja: 'テキストをコピーしました'
	String get copied => 'テキストをコピーしました';

	/// ja: 'シェアに失敗しました: $e'
	String failed({required Object e}) => 'シェアに失敗しました: ${e}';
}

// Path: consultInput.section
class Translations$consultInput$section$ja {
	Translations$consultInput$section$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'どんな場面で？'
	String get occasion => 'どんな場面で？';

	/// ja: 'いつ？'
	String get when => 'いつ？';

	/// ja: '時間帯（任意）'
	String get timeBand => '時間帯（任意）';

	/// ja: 'どこで？'
	String get where => 'どこで？';

	/// ja: '現住所からの距離'
	String get radiusDaily => '現住所からの距離';

	/// ja: '現住所からの距離帯'
	String get radiusBand => '現住所からの距離帯';

	/// ja: '地域ブロック'
	String get region => '地域ブロック';

	/// ja: '地点を選ぶ'
	String get point => '地点を選ぶ';

	/// ja: '何のテーマで観たい？'
	String get theme => '何のテーマで観たい？';

	/// ja: 'だれと？（任意）'
	String get whom => 'だれと？（任意）';

	/// ja: 'どうなりたい？／願い（任意）'
	String get wish => 'どうなりたい？／願い（任意）';
}

// Path: consultInput.proTimePick
class Translations$consultInput$proTimePick$ja {
	Translations$consultInput$proTimePick$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'おでかけの時刻指定 + 30分後の変化'
	String get label => 'おでかけの時刻指定 + 30分後の変化';

	/// ja: '行く時刻を1時間刻みで指定でき、その場の流れが「30分後どう変わるか」まで読めます。CCGの線は地球の自転で動くので、同じ場所でも前半と後半で主役が入れ替わります。'
	String get desc => '行く時刻を1時間刻みで指定でき、その場の流れが「30分後どう変わるか」まで読めます。CCGの線は地球の自転で動くので、同じ場所でも前半と後半で主役が入れ替わります。';
}

// Path: consultInput.whomExamples
class Translations$consultInput$whomExamples$ja {
	Translations$consultInput$whomExamples$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	List<String> get love => [
		'ひとりで',
		'パートナーと',
		'気になる人と',
	];
	List<String> get money => [
		'ひとりで',
		'家族と',
		'パートナーと',
	];
	List<String> get work => [
		'ひとりで',
		'同僚と',
		'仲間と',
	];
	List<String> get communication => [
		'友人と',
		'仲間と',
		'ひとりで',
	];
	List<String> get healing => [
		'ひとりで',
		'パートナーと',
		'家族と',
	];
	List<String> get newStart => [
		'ひとりで',
		'パートナーと',
		'家族と',
	];
	List<String> get fallback => [
		'ひとりで',
		'パートナーと',
		'友人と',
		'家族と',
	];
}

// Path: consultInput.wishExamples
class Translations$consultInput$wishExamples$ja {
	Translations$consultInput$wishExamples$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	List<String> get love => [
		'関係を深めたい',
		'いい出会いがほしい',
		'心を通わせたい',
	];
	List<String> get money => [
		'豊かさを引き寄せたい',
		'仕事の基盤を築きたい',
		'安定した暮らしがしたい',
	];
	List<String> get work => [
		'仕事で前進したい',
		'新しい挑戦をしたい',
		'集中できる場所がほしい',
	];
	List<String> get communication => [
		'視野を広げたい',
		'学びを深めたい',
		'いい刺激がほしい',
	];
	List<String> get healing => [
		'心を休めたい',
		'気分転換したい',
		'穏やかに過ごしたい',
	];
	List<String> get newStart => [
		'流れを変えたい',
		'新たな一歩を踏み出したい',
		'心機一転したい',
	];
	List<String> get fallback => [
		'今より一歩進みたい',
		'流れを変えたい',
	];
}

// Path: consultInput.picker
class Translations$consultInput$picker$ja {
	Translations$consultInput$picker$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '住所 / 店名で検索'
	String get searchHint => '住所 / 店名で検索';

	/// ja: 'クリア'
	String get clearSearch => 'クリア';

	/// ja: '🔭 視点 (ViewPoint) から'
	String get fromViewpoint => '🔭 視点 (ViewPoint) から';

	/// ja: '📍 保存地点 (Locations) から'
	String get fromLocations => '📍 保存地点 (Locations) から';

	/// ja: '地図で選ぶ'
	String get pickOnMap => '地図で選ぶ';

	/// ja: '選択を解除'
	String get clearSelection => '選択を解除';
}

// Path: consultInput.theme
class Translations$consultInput$theme$ja {
	Translations$consultInput$theme$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '恋愛・関係'
	String get love => '恋愛・関係';

	/// ja: '豊かさ・お金'
	String get money => '豊かさ・お金';

	/// ja: '仕事・キャリア'
	String get work => '仕事・キャリア';

	/// ja: '対話・学び'
	String get communication => '対話・学び';

	/// ja: '癒し・休息'
	String get healing => '癒し・休息';

	/// ja: '変化・新たな出発'
	String get newStart => '変化・新たな出発';
}

// Path: consultInput.mode
class Translations$consultInput$mode$ja {
	Translations$consultInput$mode$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'おでかけ イベント'
	String get daily => 'おでかけ\nイベント';

	/// ja: '旅行'
	String get travel => '旅行';

	/// ja: '移住'
	String get migration => '移住';
}

// Path: consultInput.scope
class Translations$consultInput$scope$ja {
	Translations$consultInput$scope$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '具体地点'
	String get point => '具体地点';

	/// ja: '方角'
	String get bearing => '方角';

	/// ja: '現住所から半径'
	String get radius => '現住所から半径';

	/// ja: '地域'
	String get region => '地域';

	/// ja: '自国内'
	String get country => '自国内';

	/// ja: '世界全体'
	String get world => '世界全体';
}

// Path: consultInput.when
class Translations$consultInput$when$ja {
	Translations$consultInput$when$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '今日'
	String get today => '今日';

	/// ja: '日付指定'
	String get date => '日付指定';

	/// ja: '特定の日'
	String get specificDay => '特定の日';

	/// ja: '期間'
	String get range => '期間';

	/// ja: '時期未定'
	String get undecided => '時期未定';

	/// ja: '半年以内'
	String get within6mo => '半年以内';

	/// ja: '1年以内'
	String get within1yr => '1年以内';

	/// ja: '3年後くらい'
	String get in3yr => '3年後くらい';

	/// ja: '5年以上先'
	String get in5yrPlus => '5年以上先';
}

// Path: consultInput.timeBand
class Translations$consultInput$timeBand$ja {
	Translations$consultInput$timeBand$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '朝'
	String get morning => '朝';

	/// ja: '昼'
	String get midday => '昼';

	/// ja: '夕方'
	String get evening => '夕方';

	/// ja: '夜'
	String get night => '夜';

	/// ja: '夜更け'
	String get lateNight => '夜更け';
}

// Path: consultInput.hourPicker
class Translations$consultInput$hourPicker$ja {
	Translations$consultInput$hourPicker$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '時刻を指定（1時間刻み）'
	String get title => '時刻を指定（1時間刻み）';

	/// ja: '行く時刻のその場の流れと、30分後の変化を読みます'
	String get sub => '行く時刻のその場の流れと、30分後の変化を読みます';

	/// ja: '$time に決定'
	String confirm({required Object time}) => '${time} に決定';
}

// Path: consultInput.about
class Translations$consultInput$about$ja {
	Translations$consultInput$about$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Stella 相談とは'
	String get title => 'Stella 相談とは';

	/// ja: '「いつ・どこで・何をするか」を選ぶだけ。その予定に、地球規模の星の地図を重ね、その時・その場所であなたに働くエネルギーを読み解く——Solara の中核機能です。 本来は占星術師が長い時間をかけて読み解く膨大な天体計算を Stella が瞬時に行い、専門用語ではなく、あなたに寄り添う言葉でお渡しします。'
	String get intro => '「いつ・どこで・何をするか」を選ぶだけ。その予定に、地球規模の星の地図を重ね、その時・その場所であなたに働くエネルギーを読み解く——Solara の中核機能です。\n本来は占星術師が長い時間をかけて読み解く膨大な天体計算を Stella が瞬時に行い、専門用語ではなく、あなたに寄り添う言葉でお渡しします。';

	/// ja: '・「どこで・何をすると、どんな作用が得られるか」を、あなたの願いに照らして描きます。 ・吉凶やランキングはしません。「良い/悪い」ではなく“どんな質の流れか（後押しになる質か、向き合う質か）”として伝えます。 ・おでかけ・旅行・移住——スケールに合わせて。Cosmic Pro なら時刻を1時間刻みで指定でき、「30分後にその場の流れがどう動くか」まで読めます。'
	String get bullets => '・「どこで・何をすると、どんな作用が得られるか」を、あなたの願いに照らして描きます。\n・吉凶やランキングはしません。「良い/悪い」ではなく“どんな質の流れか（後押しになる質か、向き合う質か）”として伝えます。\n・おでかけ・旅行・移住——スケールに合わせて。Cosmic Pro なら時刻を1時間刻みで指定でき、「30分後にその場の流れがどう動くか」まで読めます。';

	/// ja: 'Stella 相談が読み解くデータ'
	String get dataTitle => 'Stella 相談が読み解くデータ';

	/// ja: 'Solara の星のライン計算は 10天体 × 4アングル(ASC・MC・DSC・IC) × 3アスペクト(合・スクエア・トライン／セクスタイル)＝1フレーム120本。これを複数フレーム重ね、緯度帯・12ハウス・進行図まで計算します。'
	String get dataIntro => 'Solara の星のライン計算は 10天体 × 4アングル(ASC・MC・DSC・IC) × 3アスペクト(合・スクエア・トライン／セクスタイル)＝1フレーム120本。これを複数フレーム重ね、緯度帯・12ハウス・進行図まで計算します。';

	/// ja: '― おでかけ・イベント（Free）でも、ここまで ―'
	String get freeHead => '― おでかけ・イベント（Free）でも、ここまで ―';

	/// ja: '・出生図（ネイタル）の 10 天体／今日の経過天体（トランジット）の 10 天体 ・アストロカートグラフィ（Astro*Carto*Graphy／出生のライン） ・サイクロカートグラフィ（Cyclo*Carto*Graphy／今この瞬間の動くライン） ・合・スクエア・トライン・セクスタイルの全アスペクトライン（テーマ天体 × 4アングル × 3アスペクト） ・天頂帯・天底帯（緯度のエネルギー帯） ・その土地のリロケーション（ASC／MC／12ハウスの組み替え＋テーマ天体の在室） ・内的季節（進行の月・太陽、ソーラーアークの節目）／現地の時間帯（天体が角を通過する時刻） …これを世界中の候補地点に重ね、あなたの願いに響く場所・方角を Stella が描きます。'
	String get freeList => '・出生図（ネイタル）の 10 天体／今日の経過天体（トランジット）の 10 天体\n・アストロカートグラフィ（Astro*Carto*Graphy／出生のライン）\n・サイクロカートグラフィ（Cyclo*Carto*Graphy／今この瞬間の動くライン）\n・合・スクエア・トライン・セクスタイルの全アスペクトライン（テーマ天体 × 4アングル × 3アスペクト）\n・天頂帯・天底帯（緯度のエネルギー帯）\n・その土地のリロケーション（ASC／MC／12ハウスの組み替え＋テーマ天体の在室）\n・内的季節（進行の月・太陽、ソーラーアークの節目）／現地の時間帯（天体が角を通過する時刻）\n…これを世界中の候補地点に重ね、あなたの願いに響く場所・方角を Stella が描きます。';

	/// ja: '― Cosmic Pro なら、さらに ―'
	String get proHead => '― Cosmic Pro なら、さらに ―';

	/// ja: '・移住スケール＝生涯不変のネイタル ACG ＋ 進行（プログレス）の人生の章 ・旅行スケール＝旅行日ごとの動くライン（期間を複数日サンプリング） ・時刻を1時間刻みで指定 → 30分後に線がどう動くかまで'
	String get proList => '・移住スケール＝生涯不変のネイタル ACG ＋ 進行（プログレス）の人生の章\n・旅行スケール＝旅行日ごとの動くライン（期間を複数日サンプリング）\n・時刻を1時間刻みで指定 → 30分後に線がどう動くかまで';

	/// ja: '― Solara 開発者より ―'
	String get devHead => '― Solara 開発者より ―';

	/// ja: 'このきめ細かさは、占星術を実践してきた私自身が、設計から開発まで直接手がけているからこそ実現できました。「ここをこう汲んでほしい」と誰かに頼むのではなく、占星術師がそのまま形にする——だから、細部のひとつひとつに星の意味を宿せています。あなたの毎日のそばに、この星の地図が寄り添えますように。'
	String get devBody => 'このきめ細かさは、占星術を実践してきた私自身が、設計から開発まで直接手がけているからこそ実現できました。「ここをこう汲んでほしい」と誰かに頼むのではなく、占星術師がそのまま形にする——だから、細部のひとつひとつに星の意味を宿せています。あなたの毎日のそばに、この星の地図が寄り添えますように。';
}

// Path: mapAcg.sub
class Translations$mapAcg$sub$ja {
	Translations$mapAcg$sub$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '天頂'
	String get zenith => '天頂';

	/// ja: '天底'
	String get nadir => '天底';

	/// ja: '天頂帯'
	String get zenithBand => '天頂帯';

	/// ja: '天底帯'
	String get nadirBand => '天底帯';
}

// Path: mapAcg.frameLabel
class Translations$mapAcg$frameLabel$ja {
	Translations$mapAcg$frameLabel$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'TRANSIT — 今この瞬間の天体位置'
	String get transit => 'TRANSIT — 今この瞬間の天体位置';

	/// ja: 'PROGRESSED — 2次進行 (1日=1年)'
	String get progressed => 'PROGRESSED — 2次進行 (1日=1年)';

	/// ja: 'SOLAR ARC — 太陽進行弧で全惑星シフト'
	String get solarArc => 'SOLAR ARC — 太陽進行弧で全惑星シフト';
}

// Path: mapAcg.guide
class Translations$mapAcg$guide$ja {
	Translations$mapAcg$guide$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'ASTRO*CARTO*GRAPHY / CYCLO*CARTO*GRAPHY の使い方'
	String get title => 'ASTRO*CARTO*GRAPHY / CYCLO*CARTO*GRAPHY の使い方';

	/// ja: '— Jim Lewis が遺した、地球上の天体地図 —'
	String get jimLewis => '— Jim Lewis が遺した、地球上の天体地図 —';

	/// ja: '【ACG（アストロカートグラフィ）とは】'
	String get acgHead => '【ACG（アストロカートグラフィ）とは】';

	/// ja: '1970 年代に占星術師 Jim Lewis が体系化した手法。 出生時の天体配置を世界地図上の「線」として投影し、 どの土地でどの惑星が立ち上がるかを描き出します (生涯不変の地図)。'
	String get acgBody => '1970 年代に占星術師 Jim Lewis が体系化した手法。\n出生時の天体配置を世界地図上の「線」として投影し、\nどの土地でどの惑星が立ち上がるかを描き出します\n(生涯不変の地図)。';

	/// ja: '【CCG（サイクロカートグラフィ）とは】'
	String get ccgHead => '【CCG（サイクロカートグラフィ）とは】';

	/// ja: 'Jim Lewis が 1982 年に ACG の続編として体系化した 発展形。出生時ではなく「今この瞬間」や指定時刻の 天体位置を投影します。線は地球の自転とともに動き、 星の風景が刻一刻と書き換わります。 Solara の Transit / Prog / S.Arc フレームが この CCG にあたります。'
	String get ccgBody => 'Jim Lewis が 1982 年に ACG の続編として体系化した\n発展形。出生時ではなく「今この瞬間」や指定時刻の\n天体位置を投影します。線は地球の自転とともに動き、\n星の風景が刻一刻と書き換わります。\nSolara の Transit / Prog / S.Arc フレームが\nこの CCG にあたります。';

	/// ja: '【4 つのフレーム (上部ピル・すべて無料)】'
	String get framesHead => '【4 つのフレーム (上部ピル・すべて無料)】';

	/// ja: '・Natal … 出生時の配置 (ACG・生涯不変) ・Transit / Prog / S.Arc … 時刻で動く配置 (CCG) 各ピル横の i ボタンに、それぞれの詳しい説明があります。'
	String get framesBody => '・Natal … 出生時の配置 (ACG・生涯不変)\n・Transit / Prog / S.Arc … 時刻で動く配置 (CCG)\n\n各ピル横の i ボタンに、それぞれの詳しい説明があります。';

	/// ja: '【地図上の線・マーカー】'
	String get linesHead => '【地図上の線・マーカー】';

	/// ja: '惑星 × アングルのライン、天頂・天底マーカーを 表示します。ライン・マーカーをタップすると、 その地点の意味や惑星固有のメッセージが見られます。 各ピル (アングル / 天頂 / 天底) 横の i ボタンに 詳しい説明があります。'
	String get linesBody => '惑星 × アングルのライン、天頂・天底マーカーを\n表示します。ライン・マーカーをタップすると、\nその地点の意味や惑星固有のメッセージが見られます。\n各ピル (アングル / 天頂 / 天底) 横の i ボタンに\n詳しい説明があります。';

	/// ja: '【Pro 機能】'
	String get proHead => '【Pro 機能】';

	/// ja: '・アスペクト線 (120 本): 本線にスクエア / トライン / セクスタイルを追加 ・引越し: タップ地点を引越し先に見立て、動く星の ライン・ASC/MC・ハウスを比較 ・天頂帯 / 天底帯: 同じ緯度全周に効く Lewis 流の帯表示 いずれも Cosmic Pro で解放されます。'
	String get proBody => '・アスペクト線 (120 本): 本線にスクエア / トライン /\n　セクスタイルを追加\n・引越し: タップ地点を引越し先に見立て、動く星の\n　ライン・ASC/MC・ハウスを比較\n・天頂帯 / 天底帯: 同じ緯度全周に効く Lewis 流の帯表示\n\nいずれも Cosmic Pro で解放されます。';

	/// ja: '【活用方法】'
	String get usageHead => '【活用方法】';

	/// ja: '旅行・引越し・出張先の選定に。 同じ行動でも、土地によってエネルギーの流れ方が 変わります。さらに 16 方位スコア (方位エネルギー扇) を 重ねれば、「どこに」と「いつ」が地図と時計の上に 同時に立ち上がります。'
	String get usageBody => '旅行・引越し・出張先の選定に。\n同じ行動でも、土地によってエネルギーの流れ方が\n変わります。さらに 16 方位スコア (方位エネルギー扇) を\n重ねれば、「どこに」と「いつ」が地図と時計の上に\n同時に立ち上がります。';
}

// Path: mapVp.help
class Translations$mapVp$help$ja {
	Translations$mapVp$help$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'VIEWPOINT と LOCATIONS'
	String get title => 'VIEWPOINT と LOCATIONS';

	/// ja: '【📍 VIEWPOINT】'
	String get vpHead => '【📍 VIEWPOINT】';

	/// ja: '方位スコアを計算する基準地点 (観測点) です。 ここから見た 16 方位それぞれに惑星の エネルギーがどう降りているかを Map に描画します。 検索結果リスト上部のプルダウンや、 Daily チップ画面の VIEWPOINT 切替で使われます。'
	String get vpBody => '方位スコアを計算する基準地点 (観測点) です。\nここから見た 16 方位それぞれに惑星の\nエネルギーがどう降りているかを Map に描画します。\n\n検索結果リスト上部のプルダウンや、\nDaily チップ画面の VIEWPOINT 切替で使われます。';

	/// ja: '【🌐 LOCATIONS】'
	String get locHead => '【🌐 LOCATIONS】';

	/// ja: '地図上にマーカーとして表示しておく地点です (よく行く場所のリスト)。 登録すると Map にずっとマーカーが残り、 位置関係を一目で確認できます。 Map 画面下部の「LOCATIONS」タイルボタンを タップすると、VIEWPOINT から見た LOCATIONS（登録地点）のエネルギースコアを 一覧で確認できます。 よく行く場所を登録しておくと、 今日この公園は癒しスコアが高い、 今日このカフェは恋愛スコアが高い、 というように、登録地ごとの今日のエネルギー 強弱が一目で分かる便利機能です。'
	String get locBody => '地図上にマーカーとして表示しておく地点です\n(よく行く場所のリスト)。\n登録すると Map にずっとマーカーが残り、\n位置関係を一目で確認できます。\n\nMap 画面下部の「LOCATIONS」タイルボタンを\nタップすると、VIEWPOINT から見た\nLOCATIONS（登録地点）のエネルギースコアを\n一覧で確認できます。\nよく行く場所を登録しておくと、\n今日この公園は癒しスコアが高い、\n今日このカフェは恋愛スコアが高い、\nというように、登録地ごとの今日のエネルギー\n強弱が一目で分かる便利機能です。';

	/// ja: '使い方'
	String get usageTitle => '使い方';

	/// ja: '【登録する】'
	String get registerHead => '【登録する】';

	/// ja: 'VIEWPOINT / LOCATIONS とも、それぞれ 5 件まで 登録できます (自宅 🏠 を含む)。 自宅はプロフィールから自動で先頭スロットに 入るので、追加で登録できるのは最大 4 件です。 登録したい場所を地図中央に表示し、 VIEWPOINT タブなら「この地点を保存」、 LOCATIONS タブなら「この地点を登録」を タップすると、現在のタブに保存されます。'
	String get registerBody => 'VIEWPOINT / LOCATIONS とも、それぞれ 5 件まで\n登録できます (自宅 🏠 を含む)。\n自宅はプロフィールから自動で先頭スロットに\n入るので、追加で登録できるのは最大 4 件です。\n\n登録したい場所を地図中央に表示し、\nVIEWPOINT タブなら「この地点を保存」、\nLOCATIONS タブなら「この地点を登録」を\nタップすると、現在のタブに保存されます。';

	/// ja: '【アイコン・名前を変える】'
	String get iconNameHead => '【アイコン・名前を変える】';

	/// ja: '各スロット右端の ⋯ ボタンからサブメニューを 開き、名前の変更とアイコン変更ができます。 アイコンは 32 種類から選べます。'
	String get iconNameBody => '各スロット右端の ⋯ ボタンからサブメニューを\n開き、名前の変更とアイコン変更ができます。\nアイコンは 32 種類から選べます。';

	/// ja: '【順序を変える】'
	String get reorderHead => '【順序を変える】';

	/// ja: '同じく ⋯ メニュー内の ↑ ↓ で並び替えできます。 上にあるスロットほど一覧で先に出ます。 (自宅 🏠 は先頭固定で移動・削除できません。)'
	String get reorderBody => '同じく ⋯ メニュー内の ↑ ↓ で並び替えできます。\n上にあるスロットほど一覧で先に出ます。\n(自宅 🏠 は先頭固定で移動・削除できません。)';
}

// Path: mapMenu.map
class Translations$mapMenu$map$ja {
	Translations$mapMenu$map$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '方位エネルギー'
	String get dirEnergy => '方位エネルギー';

	/// ja: 'コンパス'
	String get compass => 'コンパス';

	/// ja: '座標取得'
	String get coords => '座標取得';
}

// Path: mapMenu.planet
class Translations$mapMenu$planet$ja {
	Translations$mapMenu$planet$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'タイプ'
	String get type => 'タイプ';

	/// ja: 'グループ'
	String get group => 'グループ';

	/// ja: 'テーマ'
	String get focus => 'テーマ';
}

// Path: mapMenu.acg
class Translations$mapMenu$acg$ja {
	Translations$mapMenu$acg$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Natal線'
	String get natalLine => 'Natal線';

	/// ja: 'Transit線'
	String get transitLine => 'Transit線';

	/// ja: 'Prog線'
	String get progLine => 'Prog線';

	/// ja: 'S.Arc線'
	String get sArcLine => 'S.Arc線';

	/// ja: 'アスペクト線'
	String get aspectLines => 'アスペクト線';

	/// ja: '引越し'
	String get relocate => '引越し';
}

// Path: mapMenu.pg
class Translations$mapMenu$pg$ja {
	Translations$mapMenu$pg$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '個人'
	String get personal => '個人';

	/// ja: '社会'
	String get social => '社会';

	/// ja: '世代'
	String get generational => '世代';
}

// Path: mapMenu.popup
class Translations$mapMenu$popup$ja {
	Translations$mapMenu$popup$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Map レイヤー'
	String get mapTitle => 'Map レイヤー';

	/// ja: '通常マップとダークマップを切替。視認性の好みで選択。'
	String get mapDarkBody => '通常マップとダークマップを切替。視認性の好みで選択。';

	/// ja: '自分の星のエネルギーを 16 方位の扇形で地図上に表示。色が濃い方位ほどエネルギーが強い。タップでカテゴリ別に絞り込める。'
	String get dirEnergyBody => '自分の星のエネルギーを 16 方位の扇形で地図上に表示。色が濃い方位ほどエネルギーが強い。タップでカテゴリ別に絞り込める。';

	/// ja: '中心地点から見た方位線 (N / E / S / W)。距離感の把握に。'
	String get compassBody => '中心地点から見た方位線 (N / E / S / W)。距離感の把握に。';

	/// ja: '画面中央の + の下に緯度経度ラベルを表示。地図を動かすと中心の座標がリアルタイムで更新される。ラベルをタップするとクリップボードにコピーされる。場所登録の事前確認や任意地点の座標確認に。十字 (+) 自体はトグル OFF でも常時表示。'
	String get coordsBody => '画面中央の + の下に緯度経度ラベルを表示。地図を動かすと中心の座標がリアルタイムで更新される。ラベルをタップするとクリップボードにコピーされる。場所登録の事前確認や任意地点の座標確認に。十字 (+) 自体はトグル OFF でも常時表示。';

	/// ja: '惑星レイヤー'
	String get planetTitle => '惑星レイヤー';

	/// ja: 'どのチャートの惑星を表示するか。Natal (出生時固定) / Prog (1日=1年で進行) / Transit (今この瞬間)。'
	String get typeBody => 'どのチャートの惑星を表示するか。Natal (出生時固定) / Prog (1日=1年で進行) / Transit (今この瞬間)。';

	/// ja: '10 惑星のグループフィルタ。 ・個人: $personal ・社会: $social ・世代: $generational'
	String groupBody({required Object personal, required Object social, required Object generational}) => '10 惑星のグループフィルタ。\n・個人: ${personal}\n・社会: ${social}\n・世代: ${generational}';

	/// ja: 'カテゴリ別フィルタ。テーマに関わる惑星のみ強調表示する。 ・総合: 全惑星 ・癒し: $healing ・豊かさ: $money ・恋愛: $love ・仕事: $work ・話す: $communication'
	String focusBody({required Object healing, required Object money, required Object love, required Object work, required Object communication}) => 'カテゴリ別フィルタ。テーマに関わる惑星のみ強調表示する。\n・総合: 全惑星\n・癒し: ${healing}\n・豊かさ: ${money}\n・恋愛: ${love}\n・仕事: ${work}\n・話す: ${communication}';

	/// ja: 'ACG レイヤー (Astro*Carto*Graphy)'
	String get acgTitle => 'ACG レイヤー (Astro*Carto*Graphy)';

	/// ja: '4 フレームのライン (Natal / Transit / Prog / S.Arc)'
	String get framesHead => '4 フレームのライン (Natal / Transit / Prog / S.Arc)';

	/// ja: '各惑星 × 4 アングル (ASC/MC/DSC/IC) の「本線」を世界規模で描画。4 フレームはすべて無料で切替できる (Natal=出生時固定 / Transit=今動く / Prog=2次進行 / S.Arc=ソーラーアーク)。各ピル横の i ボタンに詳しい説明があります。'
	String get framesBody => '各惑星 × 4 アングル (ASC/MC/DSC/IC) の「本線」を世界規模で描画。4 フレームはすべて無料で切替できる (Natal=出生時固定 / Transit=今動く / Prog=2次進行 / S.Arc=ソーラーアーク)。各ピル横の i ボタンに詳しい説明があります。';

	/// ja: 'アスペクト線 〔Pro〕'
	String get aspectHead => 'アスペクト線 〔Pro〕';

	/// ja: '本線 (コンジャンクション 40 本) に、スクエア / トライン / セクスタイルを加えた全 120 本を表示する拡張。ON 中の全フレームに同時適用されます。Cosmic Pro 限定。'
	String get aspectBody => '本線 (コンジャンクション 40 本) に、スクエア / トライン / セクスタイルを加えた全 120 本を表示する拡張。ON 中の全フレームに同時適用されます。Cosmic Pro 限定。';

	/// ja: '引越し 〔Pro〕'
	String get relocateHead => '引越し 〔Pro〕';

	/// ja: '地図タップ地点を引越し先に見立てて表示。①現住所と比べて近づく / 遠ざかる星のライン、②ASC / MC の星座変化、③10 惑星の 12 ハウス遷移、をまとめて確認できます。Cosmic Pro 限定。'
	String get relocateBody => '地図タップ地点を引越し先に見立てて表示。①現住所と比べて近づく / 遠ざかる星のライン、②ASC / MC の星座変化、③10 惑星の 12 ハウス遷移、をまとめて確認できます。Cosmic Pro 限定。';

	/// ja: '表示のヒント'
	String get hintHead => '表示のヒント';

	/// ja: 'ACG 線は世界規模で表示するため、ズームレベルによっては画面外に出て見えないことがあります。ズームアウト (縮小表示) すると線の全体像が確認しやすくなります。'
	String get hintBody => 'ACG 線は世界規模で表示するため、ズームレベルによっては画面外に出て見えないことがあります。ズームアウト (縮小表示) すると線の全体像が確認しやすくなります。';
}

// Path: locations.guide
class Translations$locations$guide$ja {
	Translations$locations$guide$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'LOCATIONS の使い方'
	String get title => 'LOCATIONS の使い方';

	/// ja: 'あなたが登録したVIEWPOINT（視点の中心点）から みた、LOCATION（登録地点）のエネルギーを 一覧で確認できます。 気になるところをLOCATIONとして登録しておけば、 一目で今日のエネルギーを知る事ができます。 よく行く場所を登録しておくと、 今日この公園は癒しスコアが高い、 今日このカフェは恋愛スコアが高い、 というように、登録地ごとの今日のエネルギー 強弱が一目で分かる便利機能です。'
	String get intro => 'あなたが登録したVIEWPOINT（視点の中心点）から\nみた、LOCATION（登録地点）のエネルギーを\n一覧で確認できます。\n気になるところをLOCATIONとして登録しておけば、\n一目で今日のエネルギーを知る事ができます。\n\nよく行く場所を登録しておくと、\n今日この公園は癒しスコアが高い、\n今日このカフェは恋愛スコアが高い、\nというように、登録地ごとの今日のエネルギー\n強弱が一目で分かる便利機能です。';

	/// ja: '【日付・時刻】'
	String get dateTimeHead => '【日付・時刻】';

	/// ja: '上部の「日付」と「時刻」を変更すると、その時点の スコアで再計算されます。「今日に戻す」ボタンで 現在に戻せます。'
	String get dateTimeBody => '上部の「日付」と「時刻」を変更すると、その時点の\nスコアで再計算されます。「今日に戻す」ボタンで\n現在に戻せます。';

	/// ja: '【VIEWPOINT 切替】'
	String get viewpointHead => '【VIEWPOINT 切替】';

	/// ja: '「VIEWPOINT」プルダウンで、距離・方位スコアの 基準地点を切替えられます。 ・地図中心 (現在地) ・現住所 ・登録した VIEWPOINT を選択可能。'
	String get viewpointBody => '「VIEWPOINT」プルダウンで、距離・方位スコアの\n基準地点を切替えられます。\n・地図中心 (現在地) ・現住所 ・登録した VIEWPOINT\nを選択可能。';

	/// ja: '【カテゴリ切替】'
	String get categoryHead => '【カテゴリ切替】';

	/// ja: '癒し / 豊かさ / 恋愛 / 仕事 / 話す をタップで切替えると、 そのカテゴリのスコアで地点が再ランクされます。 もう一度同じカテゴリをタップで未選択 (= 総合スコア表示) に 戻ります。'
	String get categoryBody => '癒し / 豊かさ / 恋愛 / 仕事 / 話す をタップで切替えると、\nそのカテゴリのスコアで地点が再ランクされます。\nもう一度同じカテゴリをタップで未選択 (= 総合スコア表示) に\n戻ります。';

	/// ja: '【地点の登録】'
	String get registerHead => '【地点の登録】';

	/// ja: 'Map 画面の左側 📍 ボタンから、地図中央の地点を VIEWPOINT と LOCATION のどちらにも保存できます。 保存した地点は名前変更や削除も可能です。'
	String get registerBody => 'Map 画面の左側 📍 ボタンから、地図中央の地点を\nVIEWPOINT と LOCATION のどちらにも保存できます。\n保存した地点は名前変更や削除も可能です。';
}

// Path: paywall.period
class Translations$paywall$period$ja {
	Translations$paywall$period$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '年'
	String get year => '年';

	/// ja: '6 か月'
	String get sixMonth => '6 か月';

	/// ja: '3 か月'
	String get threeMonth => '3 か月';

	/// ja: '2 か月'
	String get twoMonth => '2 か月';

	/// ja: '月'
	String get month => '月';

	/// ja: '週'
	String get week => '週';

	/// ja: '買い切り'
	String get lifetime => '買い切り';

	/// ja: '期間'
	String get generic => '期間';
}

// Path: paywall.introPeriod
class Translations$paywall$introPeriod$ja {
	Translations$paywall$introPeriod$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '$n 日間'
	String days({required Object n}) => '${n} 日間';

	/// ja: '$n 週間'
	String weeks({required Object n}) => '${n} 週間';

	/// ja: '$n か月'
	String months({required Object n}) => '${n} か月';

	/// ja: '$n 年'
	String years({required Object n}) => '${n} 年';

	/// ja: '$n'
	String unknown({required Object n}) => '${n}';
}

// Path: paywall.store
class Translations$paywall$store$ja {
	Translations$paywall$store$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'ストアの準備中です'
	String get preparingTitle => 'ストアの準備中です';

	/// ja: '購入手続きは公開後にご利用いただけます。 少し時間を空けてもう一度お試しください。'
	String get preparingBody => '購入手続きは公開後にご利用いただけます。\n少し時間を空けてもう一度お試しください。';

	/// ja: 'もう一度確認する'
	String get recheck => 'もう一度確認する';
}

// Path: paywall.legal
class Translations$paywall$legal$ja {
	Translations$paywall$legal$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '解約方法'
	String get cancelMethod => '解約方法';

	/// ja: '利用規約'
	String get terms => '利用規約';

	/// ja: 'プライバシーポリシー'
	String get privacy => 'プライバシーポリシー';

	/// ja: '特定商取引法に基づく表記'
	String get sctaNotice => '特定商取引法に基づく表記';
}

// Path: paywall.hero
class Translations$paywall$hero$ja {
	Translations$paywall$hero$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Stella と深く対話し、星と地に重なる景色を読み解くための完全機能。'
	String get subtitle => 'Stella と深く対話し、星と地に重なる景色を読み解くための完全機能。';
}

// Path: paywall.billing
class Translations$paywall$billing$ja {
	Translations$paywall$billing$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '月額'
	String get monthly => '月額';

	/// ja: '年額'
	String get annual => '年額';
}

// Path: paywall.plans
class Translations$paywall$plans$ja {
	Translations$paywall$plans$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '現在のプラン'
	String get currentPlan => '現在のプラン';

	/// ja: '¥0 / ずっと'
	String get freePrice => '¥0  /  ずっと';

	/// ja: '価格を取得中…'
	String get priceLoading => '価格を取得中…';

	/// ja: '(税込)'
	String get taxIncl => '(税込)';

	/// ja: '月あたり ¥$yen 相当'
	String monthlyEquivalent({required Object yen}) => '月あたり ¥${yen} 相当';

	/// ja: '🎁 $periodの無料トライアル → 終了後に自動課金'
	String trialLine({required Object period}) => '🎁 ${period}の無料トライアル → 終了後に自動課金';

	/// ja: 'ご加入中'
	String get badgeSubscribed => 'ご加入中';

	/// ja: '人気'
	String get badgePopular => '人気';

	late final Translations$paywall$plans$free$ja free = Translations$paywall$plans$free$ja.internal(_root);
	late final Translations$paywall$plans$pro$ja pro = Translations$paywall$plans$pro$ja.internal(_root);
}

// Path: paywall.cta
class Translations$paywall$cta$ja {
	Translations$paywall$cta$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '定期購入を管理'
	String get manageSubscription => '定期購入を管理';

	/// ja: '年額プランを始める'
	String get startAnnual => '年額プランを始める';

	/// ja: '月額プランを始める'
	String get startMonthly => '月額プランを始める';
}

// Path: paywall.comparison
class Translations$paywall$comparison$ja {
	Translations$paywall$comparison$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Free と Pro の違い'
	String get title => 'Free と Pro の違い';

	/// ja: '機能'
	String get colFeature => '機能';

	/// ja: '相談・読み解き'
	String get secConsult => '相談・読み解き';

	/// ja: '地図 (ACG / CCG)'
	String get secMap => '地図 (ACG / CCG)';

	/// ja: '記録（あなたの記録は Free でも永久に残ります）'
	String get secRecords => '記録（あなたの記録は Free でも永久に残ります）';

	/// ja: '予報'
	String get secForecast => '予報';

	late final Translations$paywall$comparison$stellaConsult$ja stellaConsult = Translations$paywall$comparison$stellaConsult$ja.internal(_root);
	late final Translations$paywall$comparison$tarot$ja tarot = Translations$paywall$comparison$tarot$ja.internal(_root);
	late final Translations$paywall$comparison$starReading$ja starReading = Translations$paywall$comparison$starReading$ja.internal(_root);
	late final Translations$paywall$comparison$relocationLine$ja relocationLine = Translations$paywall$comparison$relocationLine$ja.internal(_root);
	late final Translations$paywall$comparison$outingTime$ja outingTime = Translations$paywall$comparison$outingTime$ja.internal(_root);
	late final Translations$paywall$comparison$acgFrames$ja acgFrames = Translations$paywall$comparison$acgFrames$ja.internal(_root);
	late final Translations$paywall$comparison$zenithNadirPoints$ja zenithNadirPoints = Translations$paywall$comparison$zenithNadirPoints$ja.internal(_root);
	late final Translations$paywall$comparison$zenithNadirBands$ja zenithNadirBands = Translations$paywall$comparison$zenithNadirBands$ja.internal(_root);
	late final Translations$paywall$comparison$aspectLines$ja aspectLines = Translations$paywall$comparison$aspectLines$ja.internal(_root);
	late final Translations$paywall$comparison$relocationSim$ja relocationSim = Translations$paywall$comparison$relocationSim$ja.internal(_root);
	late final Translations$paywall$comparison$locationSlots$ja locationSlots = Translations$paywall$comparison$locationSlots$ja.internal(_root);
	late final Translations$paywall$comparison$recordsSave$ja recordsSave = Translations$paywall$comparison$recordsSave$ja.internal(_root);
	late final Translations$paywall$comparison$archiveSearch$ja archiveSearch = Translations$paywall$comparison$archiveSearch$ja.internal(_root);
	late final Translations$paywall$comparison$replayExport$ja replayExport = Translations$paywall$comparison$replayExport$ja.internal(_root);
	late final Translations$paywall$comparison$titleRediagnosis$ja titleRediagnosis = Translations$paywall$comparison$titleRediagnosis$ja.internal(_root);
	late final Translations$paywall$comparison$forecastPeriod$ja forecastPeriod = Translations$paywall$comparison$forecastPeriod$ja.internal(_root);
}

// Path: paywall.faq
class Translations$paywall$faq$ja {
	Translations$paywall$faq$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'よくあるご質問'
	String get title => 'よくあるご質問';

	late final Translations$paywall$faq$diff$ja diff = Translations$paywall$faq$diff$ja.internal(_root);
	late final Translations$paywall$faq$weeklyCap$ja weeklyCap = Translations$paywall$faq$weeklyCap$ja.internal(_root);
	late final Translations$paywall$faq$proTarot$ja proTarot = Translations$paywall$faq$proTarot$ja.internal(_root);
	late final Translations$paywall$faq$outing30min$ja outing30min = Translations$paywall$faq$outing30min$ja.internal(_root);
	late final Translations$paywall$faq$upgradeDowngrade$ja upgradeDowngrade = Translations$paywall$faq$upgradeDowngrade$ja.internal(_root);
	late final Translations$paywall$faq$afterCancel$ja afterCancel = Translations$paywall$faq$afterCancel$ja.internal(_root);
	late final Translations$paywall$faq$resubscribe$ja resubscribe = Translations$paywall$faq$resubscribe$ja.internal(_root);
}

// Path: aiConsent.declineDialog
class Translations$aiConsent$declineDialog$ja {
	Translations$aiConsent$declineDialog$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '本アプリのご利用には同意が必要です'
	String get title => '本アプリのご利用には同意が必要です';

	/// ja: 'Solara をご利用いただくためには、「ご利用前のおしらせ」にご記載の内容にご同意いただく必要がございます。同意なしではご利用いただけません。 もう一度ご確認いただくか、Solara をアンインストールしてください。本アプリでは、ユーザーの個人情報を含む一切のデータを受け取っておりませんので、安心してアンインストールしていただけます。'
	String get body => 'Solara をご利用いただくためには、「ご利用前のおしらせ」にご記載の内容にご同意いただく必要がございます。同意なしではご利用いただけません。\n\nもう一度ご確認いただくか、Solara をアンインストールしてください。本アプリでは、ユーザーの個人情報を含む一切のデータを受け取っておりませんので、安心してアンインストールしていただけます。';
}

// Path: aiConsent.links
class Translations$aiConsent$links$ja {
	Translations$aiConsent$links$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'プライバシーポリシー'
	String get privacy => 'プライバシーポリシー';

	/// ja: '利用規約'
	String get terms => '利用規約';
}

// Path: aiConsent.intro
class Translations$aiConsent$intro$ja {
	Translations$aiConsent$intro$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '◆ はじめに'
	String get heading => '◆ はじめに';

	/// ja: 'このアプリは広大な宇宙のデータを1つにまとめたアプリです。その瞬間1点において占星術を使い解釈する時、膨大なデータが実は存在します。このアプリはその膨大なデータを判断材料としてあなたに提供する、とても便利なアプリです。 アプリが解釈して生成する文章やデータはエビデンスとして列挙してあり、そのエビデンスから導き出される1つの解釈としてあなたに提示しています。 エビデンスを元に様々な解釈もできるので、本アプリからの提示は、解釈の一つの例に過ぎません。本アプリで、提示する文章において違和感を感じた場合は、エビデンスをもとにご自身の解釈を加えてみてください。是非、本アプリのデータを活用してあなた自身で占星術を試して頂けると幸いです。 本アプリは現役の占星術師である私が作りました。あなたの人生が、あなたらしく輝いて生きられるように願っています。 私はあなたの幸せを祈っています。あなたと本アプリを通して出会えた事に感謝します。ありがとう。 ー Solara 開発者より'
	String get body => 'このアプリは広大な宇宙のデータを1つにまとめたアプリです。その瞬間1点において占星術を使い解釈する時、膨大なデータが実は存在します。このアプリはその膨大なデータを判断材料としてあなたに提供する、とても便利なアプリです。\n\nアプリが解釈して生成する文章やデータはエビデンスとして列挙してあり、そのエビデンスから導き出される1つの解釈としてあなたに提示しています。\n\nエビデンスを元に様々な解釈もできるので、本アプリからの提示は、解釈の一つの例に過ぎません。本アプリで、提示する文章において違和感を感じた場合は、エビデンスをもとにご自身の解釈を加えてみてください。是非、本アプリのデータを活用してあなた自身で占星術を試して頂けると幸いです。\n\n本アプリは現役の占星術師である私が作りました。あなたの人生が、あなたらしく輝いて生きられるように願っています。\n私はあなたの幸せを祈っています。あなたと本アプリを通して出会えた事に感謝します。ありがとう。\n\nー Solara 開発者より';
}

// Path: aiConsent.entertainment
class Translations$aiConsent$entertainment$ja {
	Translations$aiConsent$entertainment$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '◆ 本アプリは娯楽・自己探求を目的としています'
	String get heading => '◆ 本アプリは娯楽・自己探求を目的としています';

	/// ja: 'Solara の以下のすべての機能は、娯楽および自己探求のための手段です。 ・出生図・トランジット・プログレスなどの占星術 ・タロットカードの引きと解釈 ・Stella との相談 ・星読み ・地図上のアストロカートグラフィと方位スコア表示 医療・法律・金融・心理に関する専門的な助言ではありません。将来の出来事を予測・保証するものでもありません。'
	String get body => 'Solara の以下のすべての機能は、娯楽および自己探求のための手段です。\n\n・出生図・トランジット・プログレスなどの占星術\n・タロットカードの引きと解釈\n・Stella との相談\n・星読み\n・地図上のアストロカートグラフィと方位スコア表示\n\n医療・法律・金融・心理に関する専門的な助言ではありません。将来の出来事を予測・保証するものでもありません。';
}

// Path: aiConsent.thirdParty
class Translations$aiConsent$thirdParty$ja {
	Translations$aiConsent$thirdParty$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '◆ 第三者へのデータ送信について'
	String get heading => '◆ 第三者へのデータ送信について';

	/// ja: '本アプリは、サービス提供のために以下の第三者サービスへデータを送信します: ・Apple / Google ─ 不正利用防止 (デバイス認証) のため。認証情報を送信します。 ・Google Gemini AI ─ 占星術を元にした解釈文章生成及びタロット解釈文章生成のため。あなたの出生情報 (生年月日・出生時刻・出生地) と相談で入力したテキストを送信します。 ・RevenueCat ─ 課金管理のため。匿名 ID と購入情報を送信します。'
	String get body => '本アプリは、サービス提供のために以下の第三者サービスへデータを送信します:\n\n・Apple / Google ─ 不正利用防止 (デバイス認証) のため。認証情報を送信します。\n・Google Gemini AI ─ 占星術を元にした解釈文章生成及びタロット解釈文章生成のため。あなたの出生情報 (生年月日・出生時刻・出生地) と相談で入力したテキストを送信します。\n・RevenueCat ─ 課金管理のため。匿名 ID と購入情報を送信します。';
}

// Path: aiConsent.geminiContent
class Translations$aiConsent$geminiContent$ja {
	Translations$aiConsent$geminiContent$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '◆ Gemini AI が生成するコンテンツについて'
	String get heading => '◆ Gemini AI が生成するコンテンツについて';

	/// ja: '本アプリは、以下の機能で Google の Gemini AI を利用して文章を生成しています: ・タロット ─ 引いたカードの解釈文章 ・Stella 相談 ─ あなたの問いへの占星術相談の解釈文章 ・星読み ─ 5 カテゴリ別 (恋愛 / 豊かさ / 仕事 / 対話 / 全体) の解釈文章 ・リロケーション (地図) ─ 地図上で選択した地点の占星術解釈文章'
	String get body => '本アプリは、以下の機能で Google の Gemini AI を利用して文章を生成しています:\n\n・タロット ─ 引いたカードの解釈文章\n・Stella 相談 ─ あなたの問いへの占星術相談の解釈文章\n・星読み ─ 5 カテゴリ別 (恋愛 / 豊かさ / 仕事 / 対話 / 全体) の解釈文章\n・リロケーション (地図) ─ 地図上で選択した地点の占星術解釈文章';
}

// Path: aiConsent.decisions
class Translations$aiConsent$decisions$ja {
	Translations$aiConsent$decisions$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '◆ 重要な意思決定について'
	String get heading => '◆ 重要な意思決定について';

	/// ja: 'Solara の読み解きは、あなた自身を理解するための参考情報です。不正確だったり、あなたに合わない内容になる場合もあります。 違和感を感じた結果は鵜呑みにせず、移住・転職・結婚など人生の重要な判断は、ご自身の意思と、ご家族・専門家への相談に基づいて行ってください。 データの詳しい取扱いは下記をご確認ください。'
	String get body => 'Solara の読み解きは、あなた自身を理解するための参考情報です。不正確だったり、あなたに合わない内容になる場合もあります。\n\n違和感を感じた結果は鵜呑みにせず、移住・転職・結婚など人生の重要な判断は、ご自身の意思と、ご家族・専門家への相談に基づいて行ってください。\n\nデータの詳しい取扱いは下記をご確認ください。';
}

// Path: aiConsent.consentHandling
class Translations$aiConsent$consentHandling$ja {
	Translations$aiConsent$consentHandling$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '◆ 同意の取扱いについて'
	String get heading => '◆ 同意の取扱いについて';

	/// ja: '「同意して始める」を押すと、この「ご利用前のおしらせ」に記載されている事項に同意した事実を端末内に記録します。次回以降は表示されません。（規約変更の際は再度のご案内をさせて頂く場合がございます） 同意しない場合は、画面下の「同意しない」をタップしていただき、Solara をアンインストールしてください。この時点では、本アプリではユーザーの個人情報含む一切のデータを受け取っておりません。'
	String get body => '「同意して始める」を押すと、この「ご利用前のおしらせ」に記載されている事項に同意した事実を端末内に記録します。次回以降は表示されません。（規約変更の際は再度のご案内をさせて頂く場合がございます）\n\n同意しない場合は、画面下の「同意しない」をタップしていただき、Solara をアンインストールしてください。この時点では、本アプリではユーザーの個人情報含む一切のデータを受け取っておりません。';
}

// Path: paywall.plans.free
class Translations$paywall$plans$free$ja {
	Translations$paywall$plans$free$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Stella 相談 週 3 回 (月曜リセット) + 購入クレジット'
	String get stella => 'Stella 相談  週 3 回 (月曜リセット) + 購入クレジット';

	/// ja: 'タロット 1 日 1 回（カテゴリ指定はクレジット消費）'
	String get tarot => 'タロット  1 日 1 回（カテゴリ指定はクレジット消費）';

	/// ja: '星読み 「総合」カテゴリのみ'
	String get starReading => '星読み  「総合」カテゴリのみ';

	/// ja: 'アスペクトライン 40 本'
	String get aspectLines => 'アスペクトライン  40 本';

	/// ja: 'ACG / CCG 4 フレームすべて (natal / transit / prog / solar arc)'
	String get acgFrames => 'ACG / CCG  4 フレームすべて (natal / transit / prog / solar arc)';

	/// ja: '星座アーカイブ・タロット履歴の検索・フィルタ'
	String get archiveSearch => '星座アーカイブ・タロット履歴の検索・フィルタ';

	/// ja: '形成演出の再生・テキスト書き出し'
	String get replayExport => '形成演出の再生・テキスト書き出し';

	/// ja: '読み解き結果の永久保存とシェア'
	String get save => '読み解き結果の永久保存とシェア';
}

// Path: paywall.plans.pro
class Translations$paywall$plans$pro$ja {
	Translations$paywall$plans$pro$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Stella 相談 週 100 回 (月曜リセット)'
	String get stella => 'Stella 相談  週 100 回 (月曜リセット)';

	/// ja: 'おでかけ相談 時刻を1時間刻みで指定 + 「30分後の変化」が読める (CCG の線が自転で動き、前半/後半で主役が入れ替わる)'
	String get outing => 'おでかけ相談  時刻を1時間刻みで指定 + 「30分後の変化」が読める (CCG の線が自転で動き、前半/後半で主役が入れ替わる)';

	/// ja: 'タロット 7 カテゴリ (総合・恋愛・豊かさ・仕事・対話・癒し・変化) をクレジット消費なしで指定 + 質問入力欄'
	String get tarot => 'タロット  7 カテゴリ (総合・恋愛・豊かさ・仕事・対話・癒し・変化) をクレジット消費なしで指定 + 質問入力欄';

	/// ja: '星読み 全 5 カテゴリ (総合・恋愛・豊かさ・仕事・話す) + 深い読み'
	String get starReading => '星読み  全 5 カテゴリ (総合・恋愛・豊かさ・仕事・話す) + 深い読み';

	/// ja: 'Forecast 5 年予測 モテ期や豊かさ期などが 5 年先までわかる。ヒートマップを 5 年先まで見られる'
	String get forecast => 'Forecast 5 年予測  モテ期や豊かさ期などが 5 年先までわかる。ヒートマップを 5 年先まで見られる';

	/// ja: 'アスペクトライン 全 120 本 (合・スクエア・トライン・セクスタイル)'
	String get aspectLines => 'アスペクトライン  全 120 本 (合・スクエア・トライン・セクスタイル)';

	/// ja: '天頂帯・天底帯 惑星が真上/真下を通る緯度を帯で表示 (Lewis 流)'
	String get zenithBands => '天頂帯・天底帯  惑星が真上/真下を通る緯度を帯で表示 (Lewis 流)';

	/// ja: '引越しシミュレーション 地点タップで ASC / MC / 12 ハウスを再計算'
	String get relocationSim => '引越しシミュレーション  地点タップで ASC / MC / 12 ハウスを再計算';

	/// ja: '保存拠点数 10か所'
	String get slots => '保存拠点数  10か所';

	/// ja: '称号 (クラス) の再診断 無制限'
	String get rediagnosis => '称号 (クラス) の再診断  無制限';
}

// Path: paywall.comparison.stellaConsult
class Translations$paywall$comparison$stellaConsult$ja {
	Translations$paywall$comparison$stellaConsult$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Stella 相談'
	String get label => 'Stella 相談';

	/// ja: '週 3 回 + 購入クレジット'
	String get free => '週 3 回\n+ 購入クレジット';

	/// ja: '週 100 回'
	String get pro => '週 100 回';
}

// Path: paywall.comparison.tarot
class Translations$paywall$comparison$tarot$ja {
	Translations$paywall$comparison$tarot$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'タロット'
	String get label => 'タロット';

	/// ja: '総合 無料 他カテゴリ 1 クレジット (1 日 1 回)'
	String get free => '総合 無料\n他カテゴリ 1 クレジット\n(1 日 1 回)';

	/// ja: '全 7 カテゴリ クレジット消費なし + 質問入力欄 (1 日 1 回)'
	String get pro => '全 7 カテゴリ\nクレジット消費なし\n+ 質問入力欄\n(1 日 1 回)';
}

// Path: paywall.comparison.starReading
class Translations$paywall$comparison$starReading$ja {
	Translations$paywall$comparison$starReading$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '星読み (Horo)'
	String get label => '星読み (Horo)';

	/// ja: '「総合」のみ'
	String get free => '「総合」のみ';

	/// ja: '全 5 カテゴリ (総合・恋愛・豊かさ ・仕事・話す) + 深い読み'
	String get pro => '全 5 カテゴリ\n(総合・恋愛・豊かさ\n・仕事・話す)\n+ 深い読み';
}

// Path: paywall.comparison.relocationLine
class Translations$paywall$comparison$relocationLine$ja {
	Translations$paywall$comparison$relocationLine$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '拠点 (ライン近接) 解説'
	String get label => '拠点 (ライン近接) 解説';
}

// Path: paywall.comparison.outingTime
class Translations$paywall$comparison$outingTime$ja {
	Translations$paywall$comparison$outingTime$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'おでかけの時刻指定 + 30分後の変化'
	String get label => 'おでかけの時刻指定\n+ 30分後の変化';

	/// ja: '✓ (1時間刻み)'
	String get pro => '✓\n(1時間刻み)';
}

// Path: paywall.comparison.acgFrames
class Translations$paywall$comparison$acgFrames$ja {
	Translations$paywall$comparison$acgFrames$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'ACG / CCG 4 フレーム'
	String get label => 'ACG / CCG 4 フレーム';

	/// ja: '✓ すべて (natal/transit /prog/solar arc)'
	String get value => '✓ すべて\n(natal/transit\n/prog/solar arc)';
}

// Path: paywall.comparison.zenithNadirPoints
class Translations$paywall$comparison$zenithNadirPoints$ja {
	Translations$paywall$comparison$zenithNadirPoints$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '天頂・天底点 / カテゴリ絞り込み'
	String get label => '天頂・天底点 / カテゴリ絞り込み';
}

// Path: paywall.comparison.zenithNadirBands
class Translations$paywall$comparison$zenithNadirBands$ja {
	Translations$paywall$comparison$zenithNadirBands$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '天頂帯・天底帯 (緯度帯)'
	String get label => '天頂帯・天底帯 (緯度帯)';
}

// Path: paywall.comparison.aspectLines
class Translations$paywall$comparison$aspectLines$ja {
	Translations$paywall$comparison$aspectLines$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'アスペクトライン'
	String get label => 'アスペクトライン';

	/// ja: '40 本 (合)'
	String get free => '40 本\n(合)';

	/// ja: '120 本 (合・□・△・⚹)'
	String get pro => '120 本\n(合・□・△・⚹)';
}

// Path: paywall.comparison.relocationSim
class Translations$paywall$comparison$relocationSim$ja {
	Translations$paywall$comparison$relocationSim$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '引越しシミュレーション'
	String get label => '引越しシミュレーション';
}

// Path: paywall.comparison.locationSlots
class Translations$paywall$comparison$locationSlots$ja {
	Translations$paywall$comparison$locationSlots$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '拠点 (VP/LOCATION) 枠'
	String get label => '拠点 (VP/LOCATION) 枠';

	/// ja: '5か所'
	String get free => '5か所';

	/// ja: '10か所'
	String get pro => '10か所';
}

// Path: paywall.comparison.recordsSave
class Translations$paywall$comparison$recordsSave$ja {
	Translations$paywall$comparison$recordsSave$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '読み解き・サイクルの永久保存'
	String get label => '読み解き・サイクルの永久保存';
}

// Path: paywall.comparison.archiveSearch
class Translations$paywall$comparison$archiveSearch$ja {
	Translations$paywall$comparison$archiveSearch$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '星座アーカイブ・履歴の検索/フィルタ'
	String get label => '星座アーカイブ・履歴の検索/フィルタ';
}

// Path: paywall.comparison.replayExport
class Translations$paywall$comparison$replayExport$ja {
	Translations$paywall$comparison$replayExport$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '形成演出の再生・テキスト書き出し'
	String get label => '形成演出の再生・テキスト書き出し';
}

// Path: paywall.comparison.titleRediagnosis
class Translations$paywall$comparison$titleRediagnosis$ja {
	Translations$paywall$comparison$titleRediagnosis$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '称号 (クラス) の再診断'
	String get label => '称号 (クラス) の再診断';

	/// ja: '1 回まで'
	String get free => '1 回まで';

	/// ja: '無制限'
	String get pro => '無制限';
}

// Path: paywall.comparison.forecastPeriod
class Translations$paywall$comparison$forecastPeriod$ja {
	Translations$paywall$comparison$forecastPeriod$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Forecast 期間'
	String get label => 'Forecast 期間';

	/// ja: '1 年'
	String get free => '1 年';

	/// ja: '5 年'
	String get pro => '5 年';
}

// Path: paywall.faq.diff
class Translations$paywall$faq$diff$ja {
	Translations$paywall$faq$diff$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Free と Pro の違いは何ですか?'
	String get q => 'Free と Pro の違いは何ですか?';

	/// ja: 'Stella 相談は Free 週 3 回 → Pro 週 100 回、星読みは Free「総合」のみ → Pro 全 5 カテゴリ、アスペクトラインは Free 40 本 → Pro 120 本に増えます。タロットは両プラン 1 日 1 回ですが、Pro はカテゴリ指定時のクレジット消費なし + 質問入力欄が付与されます。 ACG / CCG の 4 フレーム、星座アーカイブやタロット履歴の検索・フィルタ、読み解き結果の保存・シェアは Free でもお使いいただけます。詳細は上記表でご確認ください。'
	String get a => 'Stella 相談は Free 週 3 回 → Pro 週 100 回、星読みは Free「総合」のみ → Pro 全 5 カテゴリ、アスペクトラインは Free 40 本 → Pro 120 本に増えます。タロットは両プラン 1 日 1 回ですが、Pro はカテゴリ指定時のクレジット消費なし + 質問入力欄が付与されます。\n\nACG / CCG の 4 フレーム、星座アーカイブやタロット履歴の検索・フィルタ、読み解き結果の保存・シェアは Free でもお使いいただけます。詳細は上記表でご確認ください。';
}

// Path: paywall.faq.weeklyCap
class Translations$paywall$faq$weeklyCap$ja {
	Translations$paywall$faq$weeklyCap$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Stella 相談の週次キャップを超えるとどうなりますか?'
	String get q => 'Stella 相談の週次キャップを超えるとどうなりますか?';

	/// ja: '追加クレジットの購入で継続してご利用いただけます。月曜のリセット時に Pro 週 100 回が補充されます。'
	String get a => '追加クレジットの購入で継続してご利用いただけます。月曜のリセット時に Pro 週 100 回が補充されます。';
}

// Path: paywall.faq.proTarot
class Translations$paywall$faq$proTarot$ja {
	Translations$paywall$faq$proTarot$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Pro のタロットは何が変わりますか?'
	String get q => 'Pro のタロットは何が変わりますか?';

	/// ja: 'タロットは Free・Pro とも 1 日 1 回です。Pro では、クレジットを消費せずに聞きたいカテゴリ（総合・恋愛・豊かさ・仕事・対話・癒し・変化）を指定してリーディングできます。さらに、知りたいことを直接質問として入力でき、その質問内容に応じたリーディング結果が表示されます。 Free では総合のみ無料（1 日 1 回）で、ほかのカテゴリは 1 回につき1 クレジットを消費します。'
	String get a => 'タロットは Free・Pro とも 1 日 1 回です。Pro では、クレジットを消費せずに聞きたいカテゴリ（総合・恋愛・豊かさ・仕事・対話・癒し・変化）を指定してリーディングできます。さらに、知りたいことを直接質問として入力でき、その質問内容に応じたリーディング結果が表示されます。\n\nFree では総合のみ無料（1 日 1 回）で、ほかのカテゴリは 1 回につき1 クレジットを消費します。';
}

// Path: paywall.faq.outing30min
class Translations$paywall$faq$outing30min$ja {
	Translations$paywall$faq$outing30min$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'おでかけ相談の「30分後の変化」とは?'
	String get q => 'おでかけ相談の「30分後の変化」とは?';

	/// ja: 'Cosmic Pro なら、おでかけ・イベントの相談で行く時刻を 1 時間刻みで指定できます。アストロカートグラフィ（CCG）の星の線は地球の自転で動くため、同じ場所でも 30 分で「その場の主役」が静かに入れ替わります。 結果画面の「30分経過後を見る」を開くと、火星の線が離れていく／金星の線が近づいてくる といった移ろいを先に読めます。「核心は前半に」「後半にかけて温まる」のように、その場での時間の使い方が見えてきます（吉凶ではなく、エネルギーの質の移り変わりです）。'
	String get a => 'Cosmic Pro なら、おでかけ・イベントの相談で行く時刻を 1 時間刻みで指定できます。アストロカートグラフィ（CCG）の星の線は地球の自転で動くため、同じ場所でも 30 分で「その場の主役」が静かに入れ替わります。\n\n結果画面の「30分経過後を見る」を開くと、火星の線が離れていく／金星の線が近づいてくる といった移ろいを先に読めます。「核心は前半に」「後半にかけて温まる」のように、その場での時間の使い方が見えてきます（吉凶ではなく、エネルギーの質の移り変わりです）。';
}

// Path: paywall.faq.upgradeDowngrade
class Translations$paywall$faq$upgradeDowngrade$ja {
	Translations$paywall$faq$upgradeDowngrade$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'プランをアップグレード / ダウングレードできますか?'
	String get q => 'プランをアップグレード / ダウングレードできますか?';

	/// ja: 'Apple App Store または Google Play のサブスクリプション管理画面から、いつでも変更できます。自動更新を解約すると、次の課金日から Free プランへ自動的に切り替わります。'
	String get a => 'Apple App Store または Google Play のサブスクリプション管理画面から、いつでも変更できます。自動更新を解約すると、次の課金日から Free プランへ自動的に切り替わります。';
}

// Path: paywall.faq.afterCancel
class Translations$paywall$faq$afterCancel$ja {
	Translations$paywall$faq$afterCancel$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '解約後の機能はどうなりますか?'
	String get q => '解約後の機能はどうなりますか?';

	/// ja: '現在の課金期間が終了するまでは Cosmic Pro 機能を継続してお使いいただけます。期間終了後は Free プランに自動移行します。読み解き結果の履歴は端末内に保存されたまま残ります。'
	String get a => '現在の課金期間が終了するまでは Cosmic Pro 機能を継続してお使いいただけます。期間終了後は Free プランに自動移行します。読み解き結果の履歴は端末内に保存されたまま残ります。';
}

// Path: paywall.faq.resubscribe
class Translations$paywall$faq$resubscribe$ja {
	Translations$paywall$faq$resubscribe$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Pro を再契約すると週次クレジットは増えますか?'
	String get q => 'Pro を再契約すると週次クレジットは増えますか?';

	/// ja: 'いいえ。週次クレジットは 1 アカウントごとに管理され、毎週月曜日にリセットされます。Pro を解約してすぐ再契約しても、その時点の残数は変わりません。不正利用ではありませんが、再契約によって「週 100 回」の制度を繰り返し補充するような抜け穴的な使い方はできない仕組みです。 例: 水曜日に週次クレジットが残り 0 の状態で Pro を解約し、すぐ再契約しても、残りは 0 のままです。翌週の月曜日に 100 回へ復活します。'
	String get a => 'いいえ。週次クレジットは 1 アカウントごとに管理され、毎週月曜日にリセットされます。Pro を解約してすぐ再契約しても、その時点の残数は変わりません。不正利用ではありませんが、再契約によって「週 100 回」の制度を繰り返し補充するような抜け穴的な使い方はできない仕組みです。\n\n例: 水曜日に週次クレジットが残り 0 の状態で Pro を解約し、すぐ再契約しても、残りは 0 のままです。翌週の月曜日に 100 回へ復活します。';
}

/// The flat map containing all translations for locale <ja>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'sanctuary.creditPro' => ({required Object remaining, required Object limit, required Object pur}) => '✦ Pro 残 ${remaining} / ${limit} ・ 購入 ${pur} （月曜補充）',
			'sanctuary.creditProSyncing' => ({required Object pur}) => '✦ Pro 残 確認中 ・ 購入 ${pur}',
			'sanctuary.creditFree' => ({required Object free, required Object pur}) => '✦ クレジット残 ─ 無料 ${free} ・ 購入 ${pur}',
			'sanctuary.set' => '設定済み ›',
			'sanctuary.unset' => '未設定 ›',
			'sanctuary.birthInfo' => '出生情報',
			'sanctuary.home' => '自宅（現住所）',
			'sanctuary.receiveTitle' => '✦ あなたの称号を受け取る',
			'sanctuary.shareTitleCard' => '✦ 称号カードを共有する',
			'sanctuary.rediagnose' => '再診断する',
			'sanctuary.rediagnoseProOnly' => '再診断はCosmic Pro限定',
			'sanctuary.needProfile' => 'まず出生情報を設定してください',
			'sanctuary.rediagnoseProFeature' => 'クラスの取り直し',
			'sanctuary.rediagnoseProDesc' => '「今の自分」は変わっていきます。\nCosmic Pro なら何度でも診断を受け直せ、\n変遷ギャラリーで過去のクラスを並べて見返せます。',
			'sanctuary.guide.title' => '✦ 称号の受け直しについて',
			'sanctuary.guide.lead' => 'Cosmic Pro では、称号を何度でも受け取り直すことができます。',
			'sanctuary.guide.body1' => 'ただし、あなたの太陽星座・月星座から導かれる「二つ名」そのものは変わりません。変わるのは、設問への答えで形づくられる「称号（クラス）」の部分だけです。',
			'sanctuary.guide.body2' => '称号は一つひとつの設問と深く結びついています。ご自身の内面の変化や、環境の変化を感じたときに受け直すと、のちに「称号 変遷」で振り返ったとき、あなたの成長や移ろいを辿ることができます。',
			'sanctuary.guide.body3' => 'もちろん毎日受け直していただいても構いません。そんな使い方もある、というご案内をそっとお伝えしておきます。',
			'sanctuary.guide.back' => '戻る',
			'sanctuary.consultHistory' => '相談履歴',
			'sanctuary.titleHistory' => '称号 変遷',
			'sanctuary.proPerks1' => 'タロット全カテゴリ · 星読みの深い読み · 地図の引越し&120本ライン',
			'sanctuary.proPerks2' => 'おでかけの時刻指定 · 称号は無制限に再診断 · Forecast 5年 ほか',
			'sanctuary.proPaywallNote' => 'プランと価格はペイウォールでご確認ください · いつでも解約可能',
			'sanctuary.proActive' => 'Cosmic Pro 加入中',
			'sanctuary.proActiveDesc' => 'すべての機能が解放されています。',
			'sanctuary.plansTerms' => 'プラン・規約',
			'sanctuary.restoreNotFound' => '復元する購入が見つかりませんでした。',
			'sanctuary.restoreDone' => '購入を復元しました。',
			'sanctuary.restoreError' => ({required Object e}) => '復元中にエラーが発生しました: ${e}',
			'sanctuary.orbSetting' => 'ホロスコープのオーブ',
			'sanctuary.orbStandard' => '標準 ›',
			'sanctuary.orbCustom' => 'カスタム ›',
			'sanctuary.dayStart' => '1日の開始時刻',
			'sanctuary.notifyNeedPermission' => '端末の設定で通知を許可してください',
			'mapDaily.birthplace' => '出生地',
			'mapDaily.worldScale' => '世界規模で見る',
			'mapDaily.consultStella' => 'Stella に相談',
			'mapDaily.consultStellaSub' => '天体から場所を読む',
			'mapDaily.tabToday' => '本日',
			'mapDaily.tabTomorrow' => '明日',
			'mapDaily.allCategories' => '全カテゴリ',
			'mapDaily.todayTop' => ({required Object label}) => '今日の TOP — ${label}',
			'mapDaily.tagline.neutral' => '今日の動きを確認しましょう',
			'mapDaily.tagline.love' => '関係性のエネルギーが多面的に動く一日',
			'mapDaily.tagline.money' => '物質的な豊かさのエネルギーが流れる一日',
			'mapDaily.tagline.work' => '社会的役割のエネルギーが動く一日',
			'mapDaily.tagline.healing' => '内省と統合のエネルギーが流れる一日',
			'mapDaily.tagline.communication' => '対話と知性のエネルギーが動く一日',
			'mapDaily.subLabelOuter' => '外向きの相',
			'mapDaily.subLabelInner' => '内向きの相',
			'mapDaily.subLabelMixed' => '外向き＋内向きの相が混在',
			'mapDaily.recommendedActions' => 'おすすめ行動の例（参考）',
			'mapDaily.otherActionsNote' => '※ 他の行動も、この例を参考に自由に考えてみてください',
			'mapDaily.loading' => '惑星の動きを読み取っています',
			'mapDaily.failed' => 'データの取得に失敗しました',
			'mapDaily.retry' => 'もう一度',
			'mapDaily.quietDay' => '今日は静かな日。\n特別な動きは見えません。',
			'mapDaily.noFilterMatch' => 'このフィルタ条件に\n該当するイベントはありません。\nフィルタを変更してください。',
			'mapDaily.viewOnMap' => 'この時刻をMapで見る',
			'mapDaily.transitPass' => ({required Object planet, required Object angle}) => '${planet} が${angle}通過',
			'mapDaily.transitTitle' => ({required Object planet, required Object angle}) => '${planet}の${angle}通過',
			'mapDaily.angle.asc' => '東の地平 (ASC)',
			'mapDaily.angle.mc' => '天頂 (MC)',
			'mapDaily.angle.dsc' => '西の地平 (DSC)',
			'mapDaily.angle.ic' => '天底 (IC)',
			'mapDaily.angleHint.asc' => ({required Object compass}) => '昇り始める時刻 — ${compass} の地平に現れる',
			'mapDaily.angleHint.mc' => ({required Object compass}) => '最も高くに上る時刻 — ${compass} の空で頂点',
			'mapDaily.angleHint.dsc' => ({required Object compass}) => '沈む時刻 — ${compass} の地平に降る',
			'mapDaily.angleHint.ic' => '地下を通る時刻 — 内的な動きとして効く',
			'mapDaily.zenithBias' => '★ 天頂寄り',
			'mapDaily.nadirBias' => '★ 天底寄り',
			'mapDaily.latitudeBand' => ({required Object lat, required Object orb}) => '今あなたの緯度帯 (緯度 ${lat}°、オーブ ±${orb}°)',
			'mapDaily.zenithBand' => '天頂帯',
			'mapDaily.nadirBand' => '天底帯',
			'mapDaily.usage.title' => '今日の動きの読み方',
			'mapDaily.usage.summary' => 'この画面では、あなたの意図する目的に合わせて\n「いつ行動するか」の時間の指針が分かります。',
			'mapDaily.usage.vpTitle' => '【基準地点 (VIEWPOINT)】',
			'mapDaily.usage.vpBody' => '右側のプルダウンが「基準地点」です。\n出生地 (現住所として登録した地点) や、\nVIEWPOINT として登録した地点を選択できます。\nこの画面では、選択した基準地点の空で、\n惑星が「天空方位」のどこにいつ来るかを表示します。',
			'mapDaily.usage.diffTitle' => '【⚠ Map 画面の方位とは別物です】',
			'mapDaily.usage.diffBody' => '・Map 画面 = 「地表方位」(16 方位)\n　基準地点から見て地表のどの方向に行くか\n　(東の土地へ行く / 北の土地へ向かう、という地理)\n\n・この画面 = 「天空方位」(4 アングル)\n　基準地点の真上の空で惑星がどこにあるか\n　(東の地平線 / 真上の天頂 / 西の地平線 / 真下)\n\n同じ「東」でも、Map では「東の土地」、\nこの画面では「東の地平線 (惑星が昇る位置)」を指します。',
			'mapDaily.usage.timeTitle' => '【時間と天空方位を読む】',
			'mapDaily.usage.timeBody' => '今日、各惑星が選択した基準地点の空で\n4 つの天空方位 (アングル) を通る時刻を表示します:\n\n・ASC (東の地平線) — 惑星が昇る瞬間\n・MC  (真上 = 天頂) — 惑星が最高点を通る瞬間\n・DSC (西の地平線) — 惑星が沈む瞬間\n・IC  (真下 = 地下) — 惑星が地球の裏側にある瞬間\n\n「いつ恋愛のテーマが動く」「いつ仕事の節目になる」など、\n行動する時間の指針が読み取れます。',
			'mapDaily.usage.comboTitle' => '【Map スコアバーと組み合わせる】',
			'mapDaily.usage.comboBody' => '地表方位ごとのエネルギーの強さは、\nMap のスコアバーから確認できます (16 方位)。\n「合計 / 総合」ラベル下の i ボタンに詳細解説があります。\n\nスコアバー (地表方位の強さ) と\nこの画面 (天空方位 × 時刻) を組み合わせると、\nあなたの望む未来に対する最適な\n「方角 × 時間」を Solara が算出します。',
			'mapFortune.srcShort.combined' => '合計',
			'mapFortune.srcShort.transit' => 'TR',
			'mapFortune.srcShort.progressed' => 'PR',
			'mapFortune.srcFull.combined' => '合計',
			'mapFortune.srcFull.transit' => 'トランジット',
			'mapFortune.srcFull.progressed' => 'プログレス',
			'mapFortune.header' => ({required Object src, required Object cat}) => '${src} / ${cat}',
			'mapFortune.legendTSoft' => 'Tソフト',
			'mapFortune.legendTHard' => 'Tハード',
			'mapFortune.legendPSoft' => 'Pソフト',
			'mapFortune.legendPHard' => 'Pハード',
			'mapFortune.catMeta.healing' => '休息・回復・直感が流れるテーマ',
			'mapFortune.catMeta.money' => '繁栄・喜び・自己肯定のテーマ',
			'mapFortune.catMeta.love' => '愛・情熱・親密さのテーマ',
			'mapFortune.catMeta.work' => '責任・行動・拡大のテーマ',
			'mapFortune.catMeta.communication' => '伝達・対話・知性のテーマ',
			'mapFortune.usage.title' => 'Map の使い方',
			'mapFortune.usage.dirTitle' => '【方角を読む】',
			'mapFortune.usage.dirBody' => '基準地点 (VIEWPOINT) を中心に、地表の 16 方位\n(北・北北東・北東・東北東・東…) ごとのエネルギーを\nスコア化して表示しています。\n「どの土地・方向に意識を向けるべきか」が判断できます。\n\nどの方向に進むべきかだけの表示ではありません。\nもちろん方角に向かい進む事も一つの方角に対する\n行動です。他には、意識を向ける事や、声をかける、\n大切なアイテムの置き場所を方角に合わせて家を出発する、\n話しかける時の方角を意識する、お店で座る席や\nどちらに向くか意識する、深呼吸をする方角、\nなど、あなたが自由に決められます。\n決めた行動により、惑星たちのエネルギーが\nあなたに届くでしょう。\n惑星たちは常に大きな視点であなたを見守っています。\n\nスコアバーをタップするとカテゴリが切替わります\n(総合 → 癒し → 豊かさ → 恋愛 → 仕事 → 話す)。\n見たいカテゴリを選ぶと、そのエネルギーが\nどの方位に強く出ているかが分かります。',
			'mapFortune.usage.regTitle' => '【基準地点を登録する】',
			'mapFortune.usage.regPre' => '基準地点は地図画面の左側にある ',
			'mapFortune.usage.regPost' => ' (VIEWPOINT) ボタン\nから登録できます。\n登録したい場所を地図中央に表示してパネルを開き、\n「この地点を保存」をタップすると、その地点が\nVIEWPOINT として保存されます。\n\n保存した基準地点は、検索結果一覧の上部や\n下部メニューの「Daily」チップ内のプルダウンから、\nいつでも切り替えて使えます。',
			'mapFortune.usage.findTitle' => '【場所を探す】',
			'mapFortune.usage.findBody' => '検索ボタンから買い物・待ち合わせ・お店などを\n検索すると、その地点が今どの惑星から\nエネルギーを受けているかを確認できます。',
			'mapFortune.usage.timeTitle' => '【時間を読む】',
			'mapFortune.usage.timeBody' => '下部メニューの「Daily」チップから\n「行動する時間の指針」が分かります。\n※「Daily」チップの画面は「天空方位」(惑星が空の\n　 どこにいつ来るか) を扱い、この Map の「地表方位」\n　 (どの土地に向かうか) とは別物です。\n\nスコアバー (地表方位の強さ) と「Daily」チップ\n(天空方位 × 時刻) を組み合わせると、\nあなたの望む未来に対する最適な\n「方角 × 時間」を Solara が算出します。',
			'mapFortune.catPlanets.title' => 'カテゴリと関連惑星',
			'mapFortune.catPlanets.intro' => '各カテゴリは、関連する惑星ペアのアスペクトを抽出し、\nペア重みをかけて方位ごとにスコア化しています。\n(ペア重みの仕組みは下に詳しく説明)',
			'mapFortune.catPlanets.weightTitle' => '【ペア重みの仕組み】',
			'mapFortune.catPlanets.weightBody' => 'カテゴリ別スコアは、関連する惑星ペアのアスペクトを抽出し、\nペアの「中心度」に応じた重みをかけて合算しています。\n\n・主役ペア (重み 2.0)\n　そのカテゴリの中心テーマを担う惑星ペア。\n　例: 恋愛 = 金星×火星 / 仕事 = 土星×太陽\n　→ アスペクト出現時は 2 倍の影響力で計上されます。\n\n・サブペア (重み 0.5)\n　片方の惑星だけがカテゴリに関わるアスペクト。\n　例: 恋愛で「金星×木星」(金星のみ love 担当)\n　→ 0.5 倍の控えめな影響力で計上されます。\n\n・ペア外 (重み 0)\n　両方ともカテゴリに関係ない惑星のアスペクト。\n　→ そのカテゴリのスコアには反映されません。\n\nこの「重み付け」により、カテゴリの「中心テーマ」を\n反映した精度の高いスコアが得られます。\nペア重みなしの単純合算では、カテゴリの個性が\nぼやけてしまうため、加重計算で精緻化しています。',
			'mapFortune.catPlanets.overallTitle' => '【総合との関係】',
			'mapFortune.catPlanets.overallBody' => '上部スコアバーで「総合」を選んでいる時の数字は、\n全惑星・全アスペクトをそのまま合算した値です。\nカテゴリ重みは入りません (= ペア重みなし)。\n\n一方、カテゴリ別 (癒し / 豊かさ / 恋愛 / 仕事 / 話す) は\n上記のペア重みがかかります。\nさらに 1 つのアスペクトが複数カテゴリに重複計上される\nこともあります (例: 金星×木星 → 恋愛にも豊かさにも入る)。\n\nこのため「カテゴリ別 5 つの単純合算 ≠ 総合」となります。\n両者は別の角度からエネルギーを見るための数値で、\nどちらが正しいということはありません。\n・カテゴリ別 = カテゴリの「集中度」を見る\n・総合 = 全体の「総量」を見る',
			'galaxy.todayMoon' => ({required Object name}) => '今日の月: ${name}',
			'galaxy.phaseDesc.newMoon' => '始まりの時。\n空が最も暗く、星々が最もよく見える夜。\n新しい意図を立て、種を蒔く時間帯です。',
			'galaxy.phaseDesc.crescent' => '芽吹きの時。\n細い光が西の空に現れます。\n新月で蒔いた意図に向けて、少しずつ動き出す時間帯。',
			'galaxy.phaseDesc.firstQuarter' => '行動の時。\n半月が天頂に達し、決断と行動が求められます。\n芽生えた意図を形にしていく転換点。',
			'galaxy.phaseDesc.gibbous13' => '高まりの時。\n月が満ちていく勢いがピークに近づきます。\n準備が整い、表現が膨らむ時間帯。',
			'galaxy.phaseDesc.fullMoon' => '達成・解放の時。\n月が最も明るく輝く夜。\n気づきと完了がやってきます。\n手にしたものを見つめ直し、感謝する時間帯。',
			'galaxy.phaseDesc.waningGibbous18' => '共有の時。\n月が欠け始めます。\n満月で得た学びを他者と分かち合う時間帯。',
			'galaxy.phaseDesc.lastQuarter' => '手放しの時。\n半月が逆向きに浮かびます。\n不要なものを整理し、ゆるめる時間帯。',
			'galaxy.phaseDesc.waning26' => '休息の時。\n空に薄い月が残ります。\n次のサイクルへ向けて静かに整える時間帯。',
			'galaxy.phaseDesc.flowing' => '月のサイクルが流れています。',
			'galaxy.events.title' => '月のイベントについて',
			'galaxy.events.intro' => 'このサイクルでは、月の満ち欠けに合わせて\n3 つの節目があなたを訪れます。',
			'galaxy.events.newTitle' => '🌑 新月イベント',
			'galaxy.events.newBody' => '新月の日に「意図（インテンション）」を立てる出発点。\nこのサイクルで大切にしたいことを言葉にします。\nすべてはここから始まります。',
			'galaxy.events.fullTitle' => '🌕 満月イベント',
			'galaxy.events.fullBody' => '満月の日に、立てた意図への中間チェック（振り返り）。\n※ 新月で意図を立てていないと出てきません。',
			'galaxy.events.catTitle' => '✦ 刻星化イベント',
			'galaxy.events.catBody' => '次の新月の前日以降に訪れる、サイクルの締めくくり。\n手放しと、あなただけの星座の形成です。\n※ こちらも新月で意図を立てているのが前提です。',
			'galaxy.events.notifyTitle' => '🔔 通知をオンにするのがおすすめ',
			'galaxy.events.notifyBody' => '各イベントは「その日」だけ訪れます。\nSanctuary で通知をオンにしておくと、\n当日の朝にお知らせします。\n\n満月・刻星化は新月の意図設定が前提なので、\nまず新月を逃さないことが大切です。',
			'galaxy.guide.title' => 'Galaxy 画面とは',
			'galaxy.guide.intro' => '月のサイクル (約 29.5 日) に合わせて、\nあなたの日々のタロットリーディングが\n「星」として記録されていく画面です。\n\n1 サイクル = 1 つの constellation (星座) が完成。\n内面のリズムが、星座という形で残っていきます。',
			'galaxy.guide.cycleTitle' => '🌌 CYCLE タブ (現在のサイクル)',
			'galaxy.guide.cycleBody' => '今の月サイクルの「現在地」を表示。\n日々の reading を描いた "dot" が螺旋上に並び、\n完成に向けて進んでいきます。\n\n・右上の数字: サイクル何日目か (例: 23 of 30)\n・左上の月齢バッジ: 今日の月の相 (← 今ココ)\n・ドラッグで 3D 回転\n・dot タップで該当日のリーディングを表示\n・新月・満月の日は特別オーバーレイで\n　意図を立てる/振り返るアクションを促します',
			'galaxy.guide.atlasTitle' => '🌟 Star Atlas タブ (過去の星座図鑑)',
			'galaxy.guide.atlasBody' => '完成した過去のサイクル (= 星座) のコレクション。\n1 つ 1 つが、あなた自身の内面が紡いだ星座です。\n\n・各カードは 1 サイクル分の reading が織りなす星座\n・カードタップで再アニメ + 詳細表示\n　(星座名・期間・レア度)\n・レア度: 5 段階の星評価 (★)\n　レア度が高いほど「珍しい組み合わせ」が出た証',
			'galaxy.guide.meaningTitle' => '月のサイクルの意味',
			'galaxy.guide.meaningBody' => '🌑 新月 → 始まり。種を蒔く時。\n🌕 満月 → 達成・解放。気づきの時。\n\n1 サイクルかけて、あなたの内面が 1 つの星座に\nなっていきます。Tarot タブで日々のカードを\n引いて、ゆっくり育てていってください。',
			'forecast.error' => 'Forecast の取得に失敗しました。ネットワーク接続を確認してください。',
			'forecast.pro5yrLabel' => '5 年の流れ',
			'forecast.pro5yrDesc' => '今年だけでなく翌年・来々年も含めた 5 年分のヒートマップで、人生の大きな流れを見渡せます。',
			'forecast.daysCount' => ({required Object n}) => '(${n}日)',
			'forecast.calculating' => '天体の運行を計算中…',
			'forecast.noData' => 'データがありません',
			'forecast.displayPeriod' => '表示期間',
			'forecast.yearBest' => '年間ベスト',
			'forecast.yearLabels.0' => '今年',
			'forecast.yearLabels.1' => '来年',
			'forecast.yearLabels.2' => '再来年',
			'forecast.yearLabels.3' => '3年後',
			'forecast.yearLabels.4' => '4年後',
			'forecast.plusYears' => ({required Object n}) => '+${n}年',
			'forecast.monthRange' => ({required Object fy, required Object fm, required Object ly, required Object lm}) => '${fy}年${fm}月 〜 ${ly}年${lm}月',
			'forecast.heatmap1yr' => '1年ヒートマップ',
			'forecast.segRelative' => '相対',
			'forecast.segAbsolute' => '絶対',
			'forecast.segCategory' => 'カテゴリ',
			'forecast.highGreen' => '🟢↑高',
			'forecast.highRed' => '🔴↑高',
			'forecast.rankNth' => ({required Object n}) => '${n}位',
			'forecast.metricOverall' => '総合',
			'forecast.metricTopDir' => '高まる方位',
			'forecast.metricDirScore' => '方位スコア',
			'forecast.categoryBy' => 'カテゴリ別',
			'forecast.lastFetch' => ({required Object ts}) => '最終取得: ${ts}  /  差分更新方式（月次）',
			'forecast.legend.relLowRed' => '赤=年内最低',
			'forecast.legend.relLowGreen' => '緑=年内最低',
			'forecast.legend.relHighGreen' => '緑=年内最高',
			'forecast.legend.relHighRed' => '赤=年内最高',
			'forecast.legend.relRange' => ({required Object low, required Object high, required Object min, required Object max}) => '${low}  /  ${high}  （min:${min} → max:${max}）',
			'forecast.legend.absLowRed' => '赤=45以下',
			'forecast.legend.absLowGreen' => '緑=45以下',
			'forecast.legend.absHighGreen' => '緑=85以上',
			'forecast.legend.absHighRed' => '赤=85以上',
			'forecast.legend.absScale' => ({required Object low, required Object high}) => '${low}  /  黄=65  /  ${high}  （固定スケール）',
			'forecast.legend.catRank' => ({required Object rank}) => '色=${rank}位カテゴリ / 濃さ=スコア高低',
			'forecast.usage.title' => 'FORECAST の使い方',
			'forecast.usage.intro' => 'あなたの今後 1 年 (365 日) の星のリズムを表示します。\n日々の総合スコア・カテゴリ別スコアを一目で把握でき、\n動きやすい日 / 慎重に進める日を事前に確認できます。',
			'forecast.usage.s1Title' => '【1 年ヒートマップ】',
			'forecast.usage.s1Body' => '12 ヶ月 × 31 日のグリッドで、各日のスコアを色で表現。\nモード切替 (相対 / 絶対 / カテゴリ)、色方向 (緑↑高 /\n赤↑高)、ランク (1 位 / 2 位) で見せ方を変えられます。\n詳細はヒートマップ右の i ボタンを参照してください。',
			'forecast.usage.s2Title' => '【選択日詳細】',
			'forecast.usage.s2Body' => 'ヒートマップで日をタップすると、その日の方位スコアと\nカテゴリ別ランキングが下に表示されます。',
			'forecast.usage.s3Title' => '【あなたの星のサイクル】',
			'forecast.usage.s3Body' => 'カテゴリ別の「期間」(モテ期 / 豊かさ期 / 癒し期 等) を\n表示。今日以降に到来する継続期間のみ表示します。\n長期計画の指針に。',
			'forecast.usage.s4Title' => '【ハイライト Top5】',
			'forecast.usage.s4Body' => 'カテゴリ別の上位 5 日を表示。「いつ動くか」の\n短期ピンポイント計画に。',
			'forecast.usage.s5Title' => '【Map 画面の数字との関係】',
			'forecast.usage.s5Body' => 'FORECAST の数字と、Map で同じ日を開いた時の数字は\n一致しません。これは別計算だからです。\n\n・FORECAST = あなたの出生情報のみで算出。\n　地球のどこにいても、何時に見ても変わらない、\n　あなた自身に流れているエネルギーを 1 年分追跡。\n\n・Map = 今いる地点 + 今この瞬間で算出。\n　ASC (地平線) と MC (天頂) を含むため、\n　地点が変われば数字が変わり、同じ日でも\n　12:00 と 19:00 で違う数字になります\n　(ASC は 15°/時間で動くため)。\n\nどちらが正しい・間違いではなく、別の角度から\n同じあなたを読み取る 2 つのレンズです。\n・FORECAST で「動きやすい時期」を掴み\n・Map で「その地点・その時刻」を詳しく読む\nという使い分けで両方使えます。',
			'forecast.heatmapInfo.title' => '1 年ヒートマップの読み方',
			'forecast.heatmapInfo.s1Title' => '【3 つの色モード】',
			'forecast.heatmapInfo.s1Body' => '■ 相対モード (デフォルト)\n1 年内の最低 → 最高で正規化。\nあなたの 365 日のうち相対的に高い日が明るく\n見えます。日々の濃淡を最大化して把握できます。\n\n■ 絶対モード\nスコアの絶対値で色化。低い値は暗く、\n高い値は明るい。他の年・他のユーザーと\n比較する時に使います。\n\n■ カテゴリモード\n日ごとに最も強いカテゴリを色で表現:\n　🟢 癒し　🟡 豊かさ　🩷 恋愛\n　🔵 仕事　🟣 話す\n\n同じ色が連続している期間が、そのカテゴリの\n「波」が来ている時期です。\n・🩷 が連続 → モテ期 (関係性のエネルギーが流れる)\n・🟡 が連続 → 豊かさ期\n・🟢 が連続 → 癒し期\n・🔵 が連続 → 仕事期\n・🟣 が連続 → 発信期\n\nこれらの「○○期」は下の「あなたの星のサイクル」\nセクションでも、開始日・終了日付きで一覧表示されます\n(7 日以上の継続のみ抽出)。',
			'forecast.heatmapInfo.s2Title' => '【色方向 (🟢↑高 / 🔴↑高)】',
			'forecast.heatmapInfo.s2Body' => '「相対」「絶対」モードで有効です。\n・🟢↑高: 高スコア=緑、低スコア=赤\n・🔴↑高: 高スコア=赤、低スコア=緑 (反転)\n\n吉凶判定を避けるため、見たい色の方向を\nあなた自身で選べます。',
			'forecast.heatmapInfo.s3Title' => '【ランク (1 位 / 2 位)】',
			'forecast.heatmapInfo.s3Body' => '「カテゴリ」モードで有効です。\n・1 位: その日の最強カテゴリ色で塗る\n・2 位: 2 番目に強いカテゴリ色で塗る\n\n両方確認すると、1 日の中の「主役」と「サブ」が\n見えてきます。',
			'forecast.heatmapInfo.footer' => '※ 同じ日でも Map で開いた数字とは別の指標です\n(場所・時刻に依存しない計算)。\n詳細は画面上部 ❓ ボタンの「Map 画面の数字との関係」へ。',
			'forecast.cycles.title' => 'あなたの星のサイクル',
			'forecast.cycles.hint' => '今日以降に到来する期間を表示（7日以上の継続）',
			'forecast.cycles.empty' => '今日以降に到来する期間はありません',
			'forecast.cycles.infoTitle' => '星のサイクルとは',
			'forecast.cycles.s1Title' => '【表示の意味】',
			'forecast.cycles.s1Body' => '今後 1 年で、各カテゴリ (恋愛 / 豊かさ / 癒し /\n仕事 / 話す) のエネルギーが強く流れる「期間」を\n表示します。\n\n例:「💗 モテ期 6/15 〜 7/2 (18 日間)」\n　 → 6/15 から 7/2 まで関係性のエネルギーが\n　   継続して強い時期',
			'forecast.cycles.s2Title' => '【表示条件】',
			'forecast.cycles.s2Body' => '・今日以降に到来する期間のみ表示\n　(過ぎた期間は非表示)\n・7 日以上連続して強い場合のみ「期間」と認定\n　(短い波は表示しない)\n・カテゴリごとに最も近い 1 件ずつ表示',
			'forecast.cycles.s3Title' => '【活用方法】',
			'forecast.cycles.s3Body' => '「いつ動くか」の長期計画に。\nその期間の中で具体的な 1 日を Map 画面で確認すると、\nその地点・時刻での方角と時間が見えます。',
			'forecast.cycles.footer' => '※ 同じ期間のスコアでも Map で開いた数字とは別の指標です\n(場所・時刻に依存しない計算)。\n詳細は画面上部 ❓ ボタンの「Map 画面の数字との関係」へ。',
			'forecast.top5.title' => 'ハイライトTop5',
			'forecast.top5.year' => ({required Object year}) => '${year}年',
			'forecast.top5.infoTitle' => 'ハイライト Top5 の読み方',
			'forecast.top5.s1Title' => '【表示の意味】',
			'forecast.top5.s1Body' => '表示中の年 (1/1〜12/31) で、選択中の\nカテゴリのスコアが最も高い 5 日を表示します。',
			'forecast.top5.s2Title' => '【カテゴリ切替】',
			'forecast.top5.s2Body' => '総合 / 恋愛 / 豊かさ / 癒し / 仕事 / 話す から選択。\n選んだカテゴリの上位 5 日が表示されます。',
			'forecast.top5.s3Title' => '【順位マーカー】',
			'forecast.top5.s3Body' => '👑 1 位 / 🥈 2 位 / 🥉 3 位 / ⭐ 4 位 / ✨ 5 位',
			'forecast.top5.s4Title' => '【行の見方】',
			'forecast.top5.s4Body' => '日付 — 選択中カテゴリのその日のスコア\nタップで選択日詳細にジャンプ。\n(その日の高まる方位は選択日詳細で確認できます)',
			'forecast.top5.s5Title' => '【活用方法】',
			'forecast.top5.s5Body' => '「動きどころ」の短期ピンポイント計画に。\n特に 1 位の日は、そのカテゴリのテーマで動くと\nエネルギーが特に強く流れる日です。',
			'forecast.top5.footer' => '※ 同じ日でも Map で開いた数字とは別の指標です\n(場所・時刻に依存しない計算)。\n詳細は画面上部 ❓ ボタンの「Map 画面の数字との関係」へ。',
			'consultHistory.title' => '相談履歴',
			'consultHistory.deleteAll' => 'すべて削除',
			'consultHistory.deleteAllTitle' => 'すべて削除しますか？',
			'consultHistory.deleteAllBody' => '保存された全ての相談記録が消えます。元に戻せません。',
			'consultHistory.delete' => '削除',
			'consultHistory.deleteOneTitle' => 'この記録を削除しますか？',
			'consultHistory.filterAll' => 'すべて',
			'consultHistory.filterFav' => '★ お気に入り',
			'consultHistory.emptyAll' => 'まだ相談履歴はありません',
			'consultHistory.emptyFav' => 'お気に入りはまだありません',
			'consultHistory.emptyAllHint' => 'Map で地点をタップ、または Daily Transit から相談を始めると、\nここに保存されます。',
			'consultHistory.emptyFavHint' => '記録の ☆ をタップすると、ここに集まります。',
			'consultHistory.withWhomPrefix' => ({required Object name}) => 'だれと: ${name}',
			'consultHistory.undecidedShort' => '未定',
			'consultHistory.modeDaily' => 'おでかけ・イベント',
			'consultHistory.fav' => 'お気に入り登録',
			'consultHistory.unfav' => 'お気に入り解除',
			'consultCredit.signinTitle' => 'サインインが必要です',
			'consultCredit.signinBody' => ({required Object provider}) => 'クレジットのご購入には ${provider} サインインが必要です。\n\nサインインすると、機種変更や再インストール後も残高が引き継がれます。無料の機能はサインインなしでお使いいただけます。',
			'consultCredit.signinCta' => ({required Object provider}) => '${provider} でサインイン',
			'consultCredit.signinFailed' => 'サインインに失敗しました',
			'consultCredit.buyFailed' => '購入に失敗しました。時間をおいてお試しください。',
			'consultCredit.heading' => 'Stella 相談クレジット',
			'consultCredit.balanceFree' => ({required Object n}) => '今週の無料相談 あと${n}回',
			'consultCredit.balancePaid' => ({required Object n}) => ' ・ 購入残高 ${n}回',
			'consultCredit.proUnlimited' => '✦ Cosmic Pro なら回数無制限 →',
			'consultCredit.preparing' => 'クレジットの販売準備中です。\nしばらくしてからお試しください。',
			'consultCredit.fallbackProduct' => 'クレジット',
			'consultPlacePicker.prompt' => 'タップ または 検索 で地点を選んでください',
			'consultPlacePicker.loading' => '読み込み中…',
			'consultPlacePicker.selectedPoint' => '選択地点',
			'consultPlacePicker.coordName' => ({required Object lat, required Object lng}) => '選択地点 (${lat}°, ${lng}°)',
			'consultPlacePicker.consultHere' => 'この地点で相談',
			'consultResult.title' => '相談の結果',
			'consultResult.back' => '戻る',
			'consultResult.shareTooltip' => 'シェア',
			'consultResult.connError' => '接続に届きませんでした。もう一度試せます。',
			'consultResult.kindDirection' => '方角',
			'consultResult.kindPlace' => '場所',
			'consultResult.noReading' => '(narrative なし)',
			'consultResult.viewOnMap' => '地図で見る',
			'consultResult.distanceFromHome' => ({required Object dir, required Object dist}) => '${dir} 約${dist}km',
			'consultResult.loading' => 'Stella が読み解いています…',
			'consultResult.retry' => 'もう一度試す',
			'consultResult.voiceUnavailable' => 'Stella の声が今は届きませんでした',
			'consultResult.aboutReading' => 'この読み解きについて',
			'consultResult.factorsTitle' => 'この土地の占星術ファクター',
			'consultResult.kmFactor' => ({required Object factor, required Object km}) => '  ${factor}：約 ${km}km',
			'consultResult.distanceNote' => '距離はエネルギーの有無を決めません。惑星ははるか遠方、地上の数百kmは「圏内かどうか」の差にすぎません。',
			'consultResult.nearbyCount' => ({required Object n}) => '（近くの候補は${n}件ほど）',
			'consultResult.sparseHint' => ({required Object countText}) => 'この近くは候補が少なめです${countText}。半径を広げる・方角を変えると見つかりやすくなります。',
			'consultResult.exhaust.allQuiet' => 'この条件では、いま強く惹かれる土地が見当たりませんでした。',
			'consultResult.exhaust.noFresh' => 'これ以上の新しい候補地は見つかりませんでした。',
			'consultResult.exhaust.emptyPool' => 'この範囲には候補が見つかりませんでした。',
			'consultResult.exhaust.fallback' => 'これ以上は無理に候補を作りませんでした。',
			'consultResult.exhaust.tipsLead' => '条件を変えると見つかるかもしれません:',
			'consultResult.exhaust.noCredit' => '※ この案内ではクレジットを消費していません。',
			'consultResult.suggest.widenRadius' => '半径を広げてみる',
			'consultResult.suggest.bearing' => '方角で探す',
			'consultResult.suggest.point' => '具体的な場所を指定する',
			'consultResult.suggest.world' => '世界全体に広げる',
			'consultResult.refreshLoading' => '別の候補地を探しています…',
			'consultResult.refresh' => '別の候補地を見る',
			'consultResult.delta.open' => ({required Object m}) => '${m}分経過後を見る',
			'consultResult.delta.close' => ({required Object m}) => '${m}分後の変化を閉じる',
			'consultResult.delta.infoTitle' => '「30分経過後を見る」とは',
			'consultResult.delta.infoBody' => ({required Object m}) => 'アストロカートグラフィの星の線は、地球の自転で刻一刻と動いています。\n惑星が真上や地平線に来る「角ライン」は、${m}分でおよそ 7.5°——中緯度で約 800km も西へ進みます。\n\nだから同じ場所でも、選んだ時刻と${m}分後では「その場の主役」が静かに入れ替わることがあります。火星の線が離れていく、金星の線が近づいてくる——その移ろいを先に知っておくと、「核心は前半に」「後半にかけて温まる」のように、その場での時間の使い方が見えてきます。\n\n吉凶ではなく、エネルギーの“質の移り変わり”として読んでいます。Cosmic Pro・おでかけで時刻を指定したときに見られます。',
			'consultResult.delta.approaching' => '近づく',
			'consultResult.delta.entering' => '差してくる',
			'consultResult.delta.receding' => '離れる',
			'consultResult.delta.leaving' => '外れる',
			'consultResult.delta.steady' => '安定',
			'consultResult.delta.chip' => ({required Object planet, required Object angle, required Object label}) => '${planet} ${angle}・${label}',
			'consultResult.interpNote' => 'この候補の根拠（エビデンス）は、最上部「相談の結果」に表示しています。Stella は、その一つの読み方をお伝えしています。違和感があれば、ご自身の解釈も重ねてみてください。ここでの表示は、数ある解釈の一つです。',
			'consultResult.deltaInterpNote' => 'この30分後の変化は、上に示した線の動きをエビデンスとして、Stellaが解釈の１つとして表示しています。内容に違和感がある場合はご自身で解釈を広げてみてください。あくまでここでの表示は解釈の１つに過ぎません。',
			'consultResult.pro.consultLabel' => 'Stella 相談',
			'consultResult.pro.consultDesc' => 'Cosmic Pro なら回数無制限で読み解けます。',
			'consultResult.pro.migrationLabel' => '移住・旅行の相談',
			'consultResult.pro.migrationDesc' => 'おでかけ・イベント以外の相談も、Cosmic Pro なら無制限に。',
			'consultResult.pro.refreshLabel' => '候補の出し直し',
			'consultResult.pro.refreshDesc' => '別の候補を何度でも見比べられます。',
			'consultResult.pro.weeklyLabel' => 'Stella 相談',
			'consultResult.pro.weeklyDesc' => '今週の無料の相談を使い切りました。Cosmic Pro なら回数無制限・thinking でより深く読み解きます。',
			'consultResult.block.proOnlyModeTitle' => 'このモードは Cosmic Pro で',
			'consultResult.block.proOnlyModeBody' => 'おでかけ・イベント以外の相談 (移住・旅行) は Cosmic Pro で読み解けます。',
			'consultResult.block.proOnlyRefreshTitle' => '候補の出し直しは Cosmic Pro で',
			'consultResult.block.proOnlyRefreshBody' => '別の候補を何度でも見比べられます。',
			'consultResult.block.proWeeklyTitle' => '今週の Pro 相談上限に達しました',
			'consultResult.block.proWeeklyBody' => 'Cosmic Pro は週 100 回まで Stella に相談できます。月曜日に補充されます。すぐ続けるなら、追加クレジットの購入が選べます。',
			'consultResult.block.proSyncTitle' => 'Pro 状態を同期しています',
			'consultResult.block.proSyncBody' => 'Cosmic Pro の課金状態をストアと再確認しています。クレジットは消費されていません。数十秒待ってからもう一度お試しください。',
			'consultResult.block.exhaustedTitle' => '相談クレジットを使い切りました',
			'consultResult.block.exhaustedBody' => '無料の Stella 相談は週ごとに補充されます。すぐ続けるなら、追加クレジットの購入か、回数無制限の Cosmic Pro が選べます。',
			'consultResult.block.buyCredits' => '追加クレジットを購入',
			'consultResult.block.goUnlimited' => '✦ Cosmic Pro で無制限にする',
			'consultResult.block.seePro' => '✦ Cosmic Pro を見る',
			'consultResult.shareSheet.copyText' => 'テキストをコピー',
			'consultResult.shareSheet.copyTextSub' => '相談結果を clipboard に整形してコピー',
			'consultResult.shareSheet.shareImage' => '画像で共有',
			'consultResult.shareSheet.shareImageSub' => '結果画面を PNG にして OS 標準シェアで共有',
			'consultResult.shareSheet.copied' => 'テキストをコピーしました',
			'consultResult.shareSheet.failed' => ({required Object e}) => 'シェアに失敗しました: ${e}',
			'consultResult.returnChip' => '相談結果に戻る',
			'consultStart.useProWeekly' => 'Pro 週次クレジットを使う',
			'consultStart.usePaid' => '有料クレジットを使う',
			'consultStart.useCredit' => 'クレジットを使う',
			'consultStart.useFree' => '無料クレジットを使う',
			'consultStart.proWeeklyLabel' => 'Pro 週次クレジット',
			'consultStart.freeLabel' => '無料クレジット',
			'consultStart.remaining' => ({required Object n, required Object limit}) => '残り ${n} / ${limit} 回',
			'consultStart.checkingRemaining' => '残り回数を確認中',
			'consultStart.refillProMonday' => '毎週月曜日に補充（Pro 加入中）',
			'consultStart.refillMonday' => '毎週月曜日に補充',
			'consultStart.paidLabel' => '有料クレジット',
			'consultStart.paidRemaining' => ({required Object n}) => '残り ${n} 回',
			'consultStart.neverExpires' => '失効なし（購入分は端末を変えても残る）',
			'consultStart.dontShowAgain' => '次回以降表示しない',
			'consultStart.buyCredits' => 'クレジットを購入',
			'consultStart.start' => '相談を始める',
			'consultInput.screenTitle' => '相談する',
			'consultInput.section.occasion' => 'どんな場面で？',
			'consultInput.section.when' => 'いつ？',
			'consultInput.section.timeBand' => '時間帯（任意）',
			'consultInput.section.where' => 'どこで？',
			'consultInput.section.radiusDaily' => '現住所からの距離',
			'consultInput.section.radiusBand' => '現住所からの距離帯',
			'consultInput.section.region' => '地域ブロック',
			'consultInput.section.point' => '地点を選ぶ',
			'consultInput.section.theme' => '何のテーマで観たい？',
			'consultInput.section.whom' => 'だれと？（任意）',
			'consultInput.section.wish' => 'どうなりたい？／願い（任意）',
			'consultInput.proTimePick.label' => 'おでかけの時刻指定 + 30分後の変化',
			'consultInput.proTimePick.desc' => '行く時刻を1時間刻みで指定でき、その場の流れが「30分後どう変わるか」まで読めます。CCGの線は地球の自転で動くので、同じ場所でも前半と後半で主役が入れ替わります。',
			'consultInput.whomHint' => '例: 妻と / ひとりで / 気になる人と',
			'consultInput.wishHint' => '今いちばん大切にしたい気持ちを一言で',
			'consultInput.whomExamples.love.0' => 'ひとりで',
			'consultInput.whomExamples.love.1' => 'パートナーと',
			'consultInput.whomExamples.love.2' => '気になる人と',
			'consultInput.whomExamples.money.0' => 'ひとりで',
			'consultInput.whomExamples.money.1' => '家族と',
			'consultInput.whomExamples.money.2' => 'パートナーと',
			'consultInput.whomExamples.work.0' => 'ひとりで',
			'consultInput.whomExamples.work.1' => '同僚と',
			'consultInput.whomExamples.work.2' => '仲間と',
			'consultInput.whomExamples.communication.0' => '友人と',
			'consultInput.whomExamples.communication.1' => '仲間と',
			'consultInput.whomExamples.communication.2' => 'ひとりで',
			'consultInput.whomExamples.healing.0' => 'ひとりで',
			'consultInput.whomExamples.healing.1' => 'パートナーと',
			'consultInput.whomExamples.healing.2' => '家族と',
			'consultInput.whomExamples.newStart.0' => 'ひとりで',
			'consultInput.whomExamples.newStart.1' => 'パートナーと',
			'consultInput.whomExamples.newStart.2' => '家族と',
			'consultInput.whomExamples.fallback.0' => 'ひとりで',
			'consultInput.whomExamples.fallback.1' => 'パートナーと',
			'consultInput.whomExamples.fallback.2' => '友人と',
			'consultInput.whomExamples.fallback.3' => '家族と',
			'consultInput.wishExamples.love.0' => '関係を深めたい',
			'consultInput.wishExamples.love.1' => 'いい出会いがほしい',
			'consultInput.wishExamples.love.2' => '心を通わせたい',
			'consultInput.wishExamples.money.0' => '豊かさを引き寄せたい',
			'consultInput.wishExamples.money.1' => '仕事の基盤を築きたい',
			'consultInput.wishExamples.money.2' => '安定した暮らしがしたい',
			'consultInput.wishExamples.work.0' => '仕事で前進したい',
			'consultInput.wishExamples.work.1' => '新しい挑戦をしたい',
			'consultInput.wishExamples.work.2' => '集中できる場所がほしい',
			'consultInput.wishExamples.communication.0' => '視野を広げたい',
			'consultInput.wishExamples.communication.1' => '学びを深めたい',
			'consultInput.wishExamples.communication.2' => 'いい刺激がほしい',
			'consultInput.wishExamples.healing.0' => '心を休めたい',
			'consultInput.wishExamples.healing.1' => '気分転換したい',
			'consultInput.wishExamples.healing.2' => '穏やかに過ごしたい',
			'consultInput.wishExamples.newStart.0' => '流れを変えたい',
			'consultInput.wishExamples.newStart.1' => '新たな一歩を踏み出したい',
			'consultInput.wishExamples.newStart.2' => '心機一転したい',
			'consultInput.wishExamples.fallback.0' => '今より一歩進みたい',
			'consultInput.wishExamples.fallback.1' => '流れを変えたい',
			'consultInput.picker.searchHint' => '住所 / 店名で検索',
			'consultInput.picker.clearSearch' => 'クリア',
			'consultInput.picker.fromViewpoint' => '🔭 視点 (ViewPoint) から',
			'consultInput.picker.fromLocations' => '📍 保存地点 (Locations) から',
			'consultInput.picker.pickOnMap' => '地図で選ぶ',
			'consultInput.picker.clearSelection' => '選択を解除',
			'consultInput.theme.love' => '恋愛・関係',
			'consultInput.theme.money' => '豊かさ・お金',
			'consultInput.theme.work' => '仕事・キャリア',
			'consultInput.theme.communication' => '対話・学び',
			'consultInput.theme.healing' => '癒し・休息',
			'consultInput.theme.newStart' => '変化・新たな出発',
			'consultInput.mode.daily' => 'おでかけ\nイベント',
			'consultInput.mode.travel' => '旅行',
			'consultInput.mode.migration' => '移住',
			'consultInput.scope.point' => '具体地点',
			'consultInput.scope.bearing' => '方角',
			'consultInput.scope.radius' => '現住所から半径',
			'consultInput.scope.region' => '地域',
			'consultInput.scope.country' => '自国内',
			'consultInput.scope.world' => '世界全体',
			'consultInput.when.today' => '今日',
			'consultInput.when.date' => '日付指定',
			'consultInput.when.specificDay' => '特定の日',
			'consultInput.when.range' => '期間',
			'consultInput.when.undecided' => '時期未定',
			'consultInput.when.within6mo' => '半年以内',
			'consultInput.when.within1yr' => '1年以内',
			'consultInput.when.in3yr' => '3年後くらい',
			'consultInput.when.in5yrPlus' => '5年以上先',
			'consultInput.timeBand.morning' => '朝',
			'consultInput.timeBand.midday' => '昼',
			'consultInput.timeBand.evening' => '夕方',
			'consultInput.timeBand.night' => '夜',
			'consultInput.timeBand.lateNight' => '夜更け',
			'consultInput.hourPicker.title' => '時刻を指定（1時間刻み）',
			'consultInput.hourPicker.sub' => '行く時刻のその場の流れと、30分後の変化を読みます',
			'consultInput.hourPicker.confirm' => ({required Object time}) => '${time} に決定',
			'consultInput.timeRowSelected' => ({required Object time}) => '${time} を指定中（30分後の変化が見られます）',
			'consultInput.radiusBand' => ({required Object min, required Object max}) => '${min}〜${max}km',
			'consultInput.radiusSingle' => ({required Object km}) => '${km}km',
			'consultInput.submit' => '相談を始める',
			'consultInput.noHomeNote' => '現住所が未設定です。「方角・現住所から半径・自国内」は現住所を設定すると使えます。「具体地点」は今すぐ使えます。',
			'consultInput.presetCard' => ({required Object name}) => '${name} を見ます',
			'consultInput.introNote' => 'いつ・どこで・何をするか を選ぶと、その時その場所で“どんなエネルギーが働くか”を、膨大な占星術データから Stella が分かりやすく読み解きます。',
			'consultInput.about.title' => 'Stella 相談とは',
			'consultInput.about.intro' => '「いつ・どこで・何をするか」を選ぶだけ。その予定に、地球規模の星の地図を重ね、その時・その場所であなたに働くエネルギーを読み解く——Solara の中核機能です。\n本来は占星術師が長い時間をかけて読み解く膨大な天体計算を Stella が瞬時に行い、専門用語ではなく、あなたに寄り添う言葉でお渡しします。',
			'consultInput.about.bullets' => '・「どこで・何をすると、どんな作用が得られるか」を、あなたの願いに照らして描きます。\n・吉凶やランキングはしません。「良い/悪い」ではなく“どんな質の流れか（後押しになる質か、向き合う質か）”として伝えます。\n・おでかけ・旅行・移住——スケールに合わせて。Cosmic Pro なら時刻を1時間刻みで指定でき、「30分後にその場の流れがどう動くか」まで読めます。',
			'consultInput.about.dataTitle' => 'Stella 相談が読み解くデータ',
			'consultInput.about.dataIntro' => 'Solara の星のライン計算は 10天体 × 4アングル(ASC・MC・DSC・IC) × 3アスペクト(合・スクエア・トライン／セクスタイル)＝1フレーム120本。これを複数フレーム重ね、緯度帯・12ハウス・進行図まで計算します。',
			'consultInput.about.freeHead' => '― おでかけ・イベント（Free）でも、ここまで ―',
			'consultInput.about.freeList' => '・出生図（ネイタル）の 10 天体／今日の経過天体（トランジット）の 10 天体\n・アストロカートグラフィ（Astro*Carto*Graphy／出生のライン）\n・サイクロカートグラフィ（Cyclo*Carto*Graphy／今この瞬間の動くライン）\n・合・スクエア・トライン・セクスタイルの全アスペクトライン（テーマ天体 × 4アングル × 3アスペクト）\n・天頂帯・天底帯（緯度のエネルギー帯）\n・その土地のリロケーション（ASC／MC／12ハウスの組み替え＋テーマ天体の在室）\n・内的季節（進行の月・太陽、ソーラーアークの節目）／現地の時間帯（天体が角を通過する時刻）\n…これを世界中の候補地点に重ね、あなたの願いに響く場所・方角を Stella が描きます。',
			'consultInput.about.proHead' => '― Cosmic Pro なら、さらに ―',
			'consultInput.about.proList' => '・移住スケール＝生涯不変のネイタル ACG ＋ 進行（プログレス）の人生の章\n・旅行スケール＝旅行日ごとの動くライン（期間を複数日サンプリング）\n・時刻を1時間刻みで指定 → 30分後に線がどう動くかまで',
			'consultInput.about.devHead' => '― Solara 開発者より ―',
			'consultInput.about.devBody' => 'このきめ細かさは、占星術を実践してきた私自身が、設計から開発まで直接手がけているからこそ実現できました。「ここをこう汲んでほしい」と誰かに頼むのではなく、占星術師がそのまま形にする——だから、細部のひとつひとつに星の意味を宿せています。あなたの毎日のそばに、この星の地図が寄り添えますように。',
			'mapAcg.pillRelocate' => '引越し',
			'mapAcg.pillAspect' => 'アスペクト',
			'mapAcg.sub.zenith' => '天頂',
			'mapAcg.sub.nadir' => '天底',
			'mapAcg.sub.zenithBand' => '天頂帯',
			'mapAcg.sub.nadirBand' => '天底帯',
			'mapAcg.frameLabel.transit' => 'TRANSIT — 今この瞬間の天体位置',
			'mapAcg.frameLabel.progressed' => 'PROGRESSED — 2次進行 (1日=1年)',
			'mapAcg.frameLabel.solarArc' => 'SOLAR ARC — 太陽進行弧で全惑星シフト',
			'mapAcg.consultHere' => 'この地点で相談する',
			'mapAcg.guide.title' => 'ASTRO*CARTO*GRAPHY / CYCLO*CARTO*GRAPHY の使い方',
			'mapAcg.guide.jimLewis' => '— Jim Lewis が遺した、地球上の天体地図 —',
			'mapAcg.guide.acgHead' => '【ACG（アストロカートグラフィ）とは】',
			'mapAcg.guide.acgBody' => '1970 年代に占星術師 Jim Lewis が体系化した手法。\n出生時の天体配置を世界地図上の「線」として投影し、\nどの土地でどの惑星が立ち上がるかを描き出します\n(生涯不変の地図)。',
			'mapAcg.guide.ccgHead' => '【CCG（サイクロカートグラフィ）とは】',
			'mapAcg.guide.ccgBody' => 'Jim Lewis が 1982 年に ACG の続編として体系化した\n発展形。出生時ではなく「今この瞬間」や指定時刻の\n天体位置を投影します。線は地球の自転とともに動き、\n星の風景が刻一刻と書き換わります。\nSolara の Transit / Prog / S.Arc フレームが\nこの CCG にあたります。',
			'mapAcg.guide.framesHead' => '【4 つのフレーム (上部ピル・すべて無料)】',
			'mapAcg.guide.framesBody' => '・Natal … 出生時の配置 (ACG・生涯不変)\n・Transit / Prog / S.Arc … 時刻で動く配置 (CCG)\n\n各ピル横の i ボタンに、それぞれの詳しい説明があります。',
			'mapAcg.guide.linesHead' => '【地図上の線・マーカー】',
			'mapAcg.guide.linesBody' => '惑星 × アングルのライン、天頂・天底マーカーを\n表示します。ライン・マーカーをタップすると、\nその地点の意味や惑星固有のメッセージが見られます。\n各ピル (アングル / 天頂 / 天底) 横の i ボタンに\n詳しい説明があります。',
			'mapAcg.guide.proHead' => '【Pro 機能】',
			'mapAcg.guide.proBody' => '・アスペクト線 (120 本): 本線にスクエア / トライン /\n　セクスタイルを追加\n・引越し: タップ地点を引越し先に見立て、動く星の\n　ライン・ASC/MC・ハウスを比較\n・天頂帯 / 天底帯: 同じ緯度全周に効く Lewis 流の帯表示\n\nいずれも Cosmic Pro で解放されます。',
			'mapAcg.guide.usageHead' => '【活用方法】',
			'mapAcg.guide.usageBody' => '旅行・引越し・出張先の選定に。\n同じ行動でも、土地によってエネルギーの流れ方が\n変わります。さらに 16 方位スコア (方位エネルギー扇) を\n重ねれば、「どこに」と「いつ」が地図と時計の上に\n同時に立ち上がります。',
			'mapVp.savedSlots' => '保存済みスロット',
			'mapVp.registeredPlaces' => '登録地',
			'mapVp.noSlots' => '（スロットなし）',
			'mapVp.moveToCurrent' => '現在地に移動',
			'mapVp.saveThisPoint' => 'この地点を保存',
			'mapVp.registerThisPoint' => 'この地点を登録',
			'mapVp.subMoveUp' => '上に移動',
			'mapVp.subMoveDown' => '下に移動',
			'mapVp.subChangeIcon' => 'アイコン変更',
			'mapVp.subRename' => '名称変更',
			'mapVp.subDelete' => '削除',
			'mapVp.iconPickerTitle' => 'アイコンを選択',
			'mapVp.help.title' => 'VIEWPOINT と LOCATIONS',
			'mapVp.help.vpHead' => '【📍 VIEWPOINT】',
			'mapVp.help.vpBody' => '方位スコアを計算する基準地点 (観測点) です。\nここから見た 16 方位それぞれに惑星の\nエネルギーがどう降りているかを Map に描画します。\n\n検索結果リスト上部のプルダウンや、\nDaily チップ画面の VIEWPOINT 切替で使われます。',
			'mapVp.help.locHead' => '【🌐 LOCATIONS】',
			'mapVp.help.locBody' => '地図上にマーカーとして表示しておく地点です\n(よく行く場所のリスト)。\n登録すると Map にずっとマーカーが残り、\n位置関係を一目で確認できます。\n\nMap 画面下部の「LOCATIONS」タイルボタンを\nタップすると、VIEWPOINT から見た\nLOCATIONS（登録地点）のエネルギースコアを\n一覧で確認できます。\nよく行く場所を登録しておくと、\n今日この公園は癒しスコアが高い、\n今日このカフェは恋愛スコアが高い、\nというように、登録地ごとの今日のエネルギー\n強弱が一目で分かる便利機能です。',
			'mapVp.help.usageTitle' => '使い方',
			'mapVp.help.registerHead' => '【登録する】',
			'mapVp.help.registerBody' => 'VIEWPOINT / LOCATIONS とも、それぞれ 5 件まで\n登録できます (自宅 🏠 を含む)。\n自宅はプロフィールから自動で先頭スロットに\n入るので、追加で登録できるのは最大 4 件です。\n\n登録したい場所を地図中央に表示し、\nVIEWPOINT タブなら「この地点を保存」、\nLOCATIONS タブなら「この地点を登録」を\nタップすると、現在のタブに保存されます。',
			'mapVp.help.iconNameHead' => '【アイコン・名前を変える】',
			'mapVp.help.iconNameBody' => '各スロット右端の ⋯ ボタンからサブメニューを\n開き、名前の変更とアイコン変更ができます。\nアイコンは 32 種類から選べます。',
			'mapVp.help.reorderHead' => '【順序を変える】',
			'mapVp.help.reorderBody' => '同じく ⋯ メニュー内の ↑ ↓ で並び替えできます。\n上にあるスロットほど一覧で先に出ます。\n(自宅 🏠 は先頭固定で移動・削除できません。)',
			'mapMenu.tabPlanet' => '惑星',
			'mapMenu.map.dirEnergy' => '方位エネルギー',
			_ => null,
		} ?? switch (path) {
			'mapMenu.map.compass' => 'コンパス',
			'mapMenu.map.coords' => '座標取得',
			'mapMenu.planet.type' => 'タイプ',
			'mapMenu.planet.group' => 'グループ',
			'mapMenu.planet.focus' => 'テーマ',
			'mapMenu.acg.natalLine' => 'Natal線',
			'mapMenu.acg.transitLine' => 'Transit線',
			'mapMenu.acg.progLine' => 'Prog線',
			'mapMenu.acg.sArcLine' => 'S.Arc線',
			'mapMenu.acg.aspectLines' => 'アスペクト線',
			'mapMenu.acg.relocate' => '引越し',
			'mapMenu.pg.personal' => '個人',
			'mapMenu.pg.social' => '社会',
			'mapMenu.pg.generational' => '世代',
			'mapMenu.popup.mapTitle' => 'Map レイヤー',
			'mapMenu.popup.mapDarkBody' => '通常マップとダークマップを切替。視認性の好みで選択。',
			'mapMenu.popup.dirEnergyBody' => '自分の星のエネルギーを 16 方位の扇形で地図上に表示。色が濃い方位ほどエネルギーが強い。タップでカテゴリ別に絞り込める。',
			'mapMenu.popup.compassBody' => '中心地点から見た方位線 (N / E / S / W)。距離感の把握に。',
			'mapMenu.popup.coordsBody' => '画面中央の + の下に緯度経度ラベルを表示。地図を動かすと中心の座標がリアルタイムで更新される。ラベルをタップするとクリップボードにコピーされる。場所登録の事前確認や任意地点の座標確認に。十字 (+) 自体はトグル OFF でも常時表示。',
			'mapMenu.popup.planetTitle' => '惑星レイヤー',
			'mapMenu.popup.typeBody' => 'どのチャートの惑星を表示するか。Natal (出生時固定) / Prog (1日=1年で進行) / Transit (今この瞬間)。',
			'mapMenu.popup.groupBody' => ({required Object personal, required Object social, required Object generational}) => '10 惑星のグループフィルタ。\n・個人: ${personal}\n・社会: ${social}\n・世代: ${generational}',
			'mapMenu.popup.focusBody' => ({required Object healing, required Object money, required Object love, required Object work, required Object communication}) => 'カテゴリ別フィルタ。テーマに関わる惑星のみ強調表示する。\n・総合: 全惑星\n・癒し: ${healing}\n・豊かさ: ${money}\n・恋愛: ${love}\n・仕事: ${work}\n・話す: ${communication}',
			'mapMenu.popup.acgTitle' => 'ACG レイヤー (Astro*Carto*Graphy)',
			'mapMenu.popup.framesHead' => '4 フレームのライン (Natal / Transit / Prog / S.Arc)',
			'mapMenu.popup.framesBody' => '各惑星 × 4 アングル (ASC/MC/DSC/IC) の「本線」を世界規模で描画。4 フレームはすべて無料で切替できる (Natal=出生時固定 / Transit=今動く / Prog=2次進行 / S.Arc=ソーラーアーク)。各ピル横の i ボタンに詳しい説明があります。',
			'mapMenu.popup.aspectHead' => 'アスペクト線 〔Pro〕',
			'mapMenu.popup.aspectBody' => '本線 (コンジャンクション 40 本) に、スクエア / トライン / セクスタイルを加えた全 120 本を表示する拡張。ON 中の全フレームに同時適用されます。Cosmic Pro 限定。',
			'mapMenu.popup.relocateHead' => '引越し 〔Pro〕',
			'mapMenu.popup.relocateBody' => '地図タップ地点を引越し先に見立てて表示。①現住所と比べて近づく / 遠ざかる星のライン、②ASC / MC の星座変化、③10 惑星の 12 ハウス遷移、をまとめて確認できます。Cosmic Pro 限定。',
			'mapMenu.popup.hintHead' => '表示のヒント',
			'mapMenu.popup.hintBody' => 'ACG 線は世界規模で表示するため、ズームレベルによっては画面外に出て見えないことがあります。ズームアウト (縮小表示) すると線の全体像が確認しやすくなります。',
			'locations.locDefaults.0' => '場所1',
			'locations.locDefaults.1' => '場所2',
			'locations.locDefaults.2' => '場所3',
			'locations.locDefaults.3' => '場所4',
			'locations.vpDefaults.0' => '職場',
			'locations.vpDefaults.1' => 'お気に入り',
			'locations.vpDefaults.2' => 'スポット',
			'locations.vpDefaults.3' => '場所',
			'locations.currentAddress' => '現住所',
			'locations.mapCenter' => '地図中心',
			'locations.renameTitle' => '地点の名称を入力',
			'locations.cancel' => 'キャンセル',
			'locations.bearing' => ({required Object dir}) => '${dir}方位',
			'locations.emptyTitle' => '登録された拠点はまだありません',
			'locations.addCurrent' => '📍 現在地を登録',
			'locations.menuRename' => '✏ 名称変更',
			'locations.menuDelete' => '🗑 削除',
			'locations.guide.title' => 'LOCATIONS の使い方',
			'locations.guide.intro' => 'あなたが登録したVIEWPOINT（視点の中心点）から\nみた、LOCATION（登録地点）のエネルギーを\n一覧で確認できます。\n気になるところをLOCATIONとして登録しておけば、\n一目で今日のエネルギーを知る事ができます。\n\nよく行く場所を登録しておくと、\n今日この公園は癒しスコアが高い、\n今日このカフェは恋愛スコアが高い、\nというように、登録地ごとの今日のエネルギー\n強弱が一目で分かる便利機能です。',
			'locations.guide.dateTimeHead' => '【日付・時刻】',
			'locations.guide.dateTimeBody' => '上部の「日付」と「時刻」を変更すると、その時点の\nスコアで再計算されます。「今日に戻す」ボタンで\n現在に戻せます。',
			'locations.guide.viewpointHead' => '【VIEWPOINT 切替】',
			'locations.guide.viewpointBody' => '「VIEWPOINT」プルダウンで、距離・方位スコアの\n基準地点を切替えられます。\n・地図中心 (現在地) ・現住所 ・登録した VIEWPOINT\nを選択可能。',
			'locations.guide.categoryHead' => '【カテゴリ切替】',
			'locations.guide.categoryBody' => '癒し / 豊かさ / 恋愛 / 仕事 / 話す をタップで切替えると、\nそのカテゴリのスコアで地点が再ランクされます。\nもう一度同じカテゴリをタップで未選択 (= 総合スコア表示) に\n戻ります。',
			'locations.guide.registerHead' => '【地点の登録】',
			'locations.guide.registerBody' => 'Map 画面の左側 📍 ボタンから、地図中央の地点を\nVIEWPOINT と LOCATION のどちらにも保存できます。\n保存した地点は名前変更や削除も可能です。',
			'paywall.period.year' => '年',
			'paywall.period.sixMonth' => '6 か月',
			'paywall.period.threeMonth' => '3 か月',
			'paywall.period.twoMonth' => '2 か月',
			'paywall.period.month' => '月',
			'paywall.period.week' => '週',
			'paywall.period.lifetime' => '買い切り',
			'paywall.period.generic' => '期間',
			'paywall.introPeriod.days' => ({required Object n}) => '${n} 日間',
			'paywall.introPeriod.weeks' => ({required Object n}) => '${n} 週間',
			'paywall.introPeriod.months' => ({required Object n}) => '${n} か月',
			'paywall.introPeriod.years' => ({required Object n}) => '${n} 年',
			'paywall.introPeriod.unknown' => ({required Object n}) => '${n}',
			'paywall.store.preparingTitle' => 'ストアの準備中です',
			'paywall.store.preparingBody' => '購入手続きは公開後にご利用いただけます。\n少し時間を空けてもう一度お試しください。',
			'paywall.store.recheck' => 'もう一度確認する',
			'paywall.autoRenewNotice' => 'サブスクリプションは自動更新されます。期間終了の 24 時間以上前に自動更新を解約しない限り、同じ価格で次の期間に更新されます。料金は期間終了の 24 時間以内に Apple ID / Google アカウントへ請求されます。自動更新の管理や解約は、ご利用ストアのアカウント設定からいつでも行えます。',
			'paywall.legal.cancelMethod' => '解約方法',
			'paywall.legal.terms' => '利用規約',
			'paywall.legal.privacy' => 'プライバシーポリシー',
			'paywall.legal.sctaNotice' => '特定商取引法に基づく表記',
			'paywall.restore' => '購入を復元',
			'paywall.hero.subtitle' => 'Stella と深く対話し、星と地に重なる景色を読み解くための完全機能。',
			'paywall.billing.monthly' => '月額',
			'paywall.billing.annual' => '年額',
			'paywall.plans.currentPlan' => '現在のプラン',
			'paywall.plans.freePrice' => '¥0  /  ずっと',
			'paywall.plans.priceLoading' => '価格を取得中…',
			'paywall.plans.taxIncl' => '(税込)',
			'paywall.plans.monthlyEquivalent' => ({required Object yen}) => '月あたり ¥${yen} 相当',
			'paywall.plans.trialLine' => ({required Object period}) => '🎁 ${period}の無料トライアル → 終了後に自動課金',
			'paywall.plans.badgeSubscribed' => 'ご加入中',
			'paywall.plans.badgePopular' => '人気',
			'paywall.plans.free.stella' => 'Stella 相談  週 3 回 (月曜リセット) + 購入クレジット',
			'paywall.plans.free.tarot' => 'タロット  1 日 1 回（カテゴリ指定はクレジット消費）',
			'paywall.plans.free.starReading' => '星読み  「総合」カテゴリのみ',
			'paywall.plans.free.aspectLines' => 'アスペクトライン  40 本',
			'paywall.plans.free.acgFrames' => 'ACG / CCG  4 フレームすべて (natal / transit / prog / solar arc)',
			'paywall.plans.free.archiveSearch' => '星座アーカイブ・タロット履歴の検索・フィルタ',
			'paywall.plans.free.replayExport' => '形成演出の再生・テキスト書き出し',
			'paywall.plans.free.save' => '読み解き結果の永久保存とシェア',
			'paywall.plans.pro.stella' => 'Stella 相談  週 100 回 (月曜リセット)',
			'paywall.plans.pro.outing' => 'おでかけ相談  時刻を1時間刻みで指定 + 「30分後の変化」が読める (CCG の線が自転で動き、前半/後半で主役が入れ替わる)',
			'paywall.plans.pro.tarot' => 'タロット  7 カテゴリ (総合・恋愛・豊かさ・仕事・対話・癒し・変化) をクレジット消費なしで指定 + 質問入力欄',
			'paywall.plans.pro.starReading' => '星読み  全 5 カテゴリ (総合・恋愛・豊かさ・仕事・話す) + 深い読み',
			'paywall.plans.pro.forecast' => 'Forecast 5 年予測  モテ期や豊かさ期などが 5 年先までわかる。ヒートマップを 5 年先まで見られる',
			'paywall.plans.pro.aspectLines' => 'アスペクトライン  全 120 本 (合・スクエア・トライン・セクスタイル)',
			'paywall.plans.pro.zenithBands' => '天頂帯・天底帯  惑星が真上/真下を通る緯度を帯で表示 (Lewis 流)',
			'paywall.plans.pro.relocationSim' => '引越しシミュレーション  地点タップで ASC / MC / 12 ハウスを再計算',
			'paywall.plans.pro.slots' => '保存拠点数  10か所',
			'paywall.plans.pro.rediagnosis' => '称号 (クラス) の再診断  無制限',
			'paywall.cta.manageSubscription' => '定期購入を管理',
			'paywall.cta.startAnnual' => '年額プランを始める',
			'paywall.cta.startMonthly' => '月額プランを始める',
			'paywall.comparison.title' => 'Free と Pro の違い',
			'paywall.comparison.colFeature' => '機能',
			'paywall.comparison.secConsult' => '相談・読み解き',
			'paywall.comparison.secMap' => '地図 (ACG / CCG)',
			'paywall.comparison.secRecords' => '記録（あなたの記録は Free でも永久に残ります）',
			'paywall.comparison.secForecast' => '予報',
			'paywall.comparison.stellaConsult.label' => 'Stella 相談',
			'paywall.comparison.stellaConsult.free' => '週 3 回\n+ 購入クレジット',
			'paywall.comparison.stellaConsult.pro' => '週 100 回',
			'paywall.comparison.tarot.label' => 'タロット',
			'paywall.comparison.tarot.free' => '総合 無料\n他カテゴリ 1 クレジット\n(1 日 1 回)',
			'paywall.comparison.tarot.pro' => '全 7 カテゴリ\nクレジット消費なし\n+ 質問入力欄\n(1 日 1 回)',
			'paywall.comparison.starReading.label' => '星読み (Horo)',
			'paywall.comparison.starReading.free' => '「総合」のみ',
			'paywall.comparison.starReading.pro' => '全 5 カテゴリ\n(総合・恋愛・豊かさ\n・仕事・話す)\n+ 深い読み',
			'paywall.comparison.relocationLine.label' => '拠点 (ライン近接) 解説',
			'paywall.comparison.outingTime.label' => 'おでかけの時刻指定\n+ 30分後の変化',
			'paywall.comparison.outingTime.pro' => '✓\n(1時間刻み)',
			'paywall.comparison.acgFrames.label' => 'ACG / CCG 4 フレーム',
			'paywall.comparison.acgFrames.value' => '✓ すべて\n(natal/transit\n/prog/solar arc)',
			'paywall.comparison.zenithNadirPoints.label' => '天頂・天底点 / カテゴリ絞り込み',
			'paywall.comparison.zenithNadirBands.label' => '天頂帯・天底帯 (緯度帯)',
			'paywall.comparison.aspectLines.label' => 'アスペクトライン',
			'paywall.comparison.aspectLines.free' => '40 本\n(合)',
			'paywall.comparison.aspectLines.pro' => '120 本\n(合・□・△・⚹)',
			'paywall.comparison.relocationSim.label' => '引越しシミュレーション',
			'paywall.comparison.locationSlots.label' => '拠点 (VP/LOCATION) 枠',
			'paywall.comparison.locationSlots.free' => '5か所',
			'paywall.comparison.locationSlots.pro' => '10か所',
			'paywall.comparison.recordsSave.label' => '読み解き・サイクルの永久保存',
			'paywall.comparison.archiveSearch.label' => '星座アーカイブ・履歴の検索/フィルタ',
			'paywall.comparison.replayExport.label' => '形成演出の再生・テキスト書き出し',
			'paywall.comparison.titleRediagnosis.label' => '称号 (クラス) の再診断',
			'paywall.comparison.titleRediagnosis.free' => '1 回まで',
			'paywall.comparison.titleRediagnosis.pro' => '無制限',
			'paywall.comparison.forecastPeriod.label' => 'Forecast 期間',
			'paywall.comparison.forecastPeriod.free' => '1 年',
			'paywall.comparison.forecastPeriod.pro' => '5 年',
			'paywall.faq.title' => 'よくあるご質問',
			'paywall.faq.diff.q' => 'Free と Pro の違いは何ですか?',
			'paywall.faq.diff.a' => 'Stella 相談は Free 週 3 回 → Pro 週 100 回、星読みは Free「総合」のみ → Pro 全 5 カテゴリ、アスペクトラインは Free 40 本 → Pro 120 本に増えます。タロットは両プラン 1 日 1 回ですが、Pro はカテゴリ指定時のクレジット消費なし + 質問入力欄が付与されます。\n\nACG / CCG の 4 フレーム、星座アーカイブやタロット履歴の検索・フィルタ、読み解き結果の保存・シェアは Free でもお使いいただけます。詳細は上記表でご確認ください。',
			'paywall.faq.weeklyCap.q' => 'Stella 相談の週次キャップを超えるとどうなりますか?',
			'paywall.faq.weeklyCap.a' => '追加クレジットの購入で継続してご利用いただけます。月曜のリセット時に Pro 週 100 回が補充されます。',
			'paywall.faq.proTarot.q' => 'Pro のタロットは何が変わりますか?',
			'paywall.faq.proTarot.a' => 'タロットは Free・Pro とも 1 日 1 回です。Pro では、クレジットを消費せずに聞きたいカテゴリ（総合・恋愛・豊かさ・仕事・対話・癒し・変化）を指定してリーディングできます。さらに、知りたいことを直接質問として入力でき、その質問内容に応じたリーディング結果が表示されます。\n\nFree では総合のみ無料（1 日 1 回）で、ほかのカテゴリは 1 回につき1 クレジットを消費します。',
			'paywall.faq.outing30min.q' => 'おでかけ相談の「30分後の変化」とは?',
			'paywall.faq.outing30min.a' => 'Cosmic Pro なら、おでかけ・イベントの相談で行く時刻を 1 時間刻みで指定できます。アストロカートグラフィ（CCG）の星の線は地球の自転で動くため、同じ場所でも 30 分で「その場の主役」が静かに入れ替わります。\n\n結果画面の「30分経過後を見る」を開くと、火星の線が離れていく／金星の線が近づいてくる といった移ろいを先に読めます。「核心は前半に」「後半にかけて温まる」のように、その場での時間の使い方が見えてきます（吉凶ではなく、エネルギーの質の移り変わりです）。',
			'paywall.faq.upgradeDowngrade.q' => 'プランをアップグレード / ダウングレードできますか?',
			'paywall.faq.upgradeDowngrade.a' => 'Apple App Store または Google Play のサブスクリプション管理画面から、いつでも変更できます。自動更新を解約すると、次の課金日から Free プランへ自動的に切り替わります。',
			'paywall.faq.afterCancel.q' => '解約後の機能はどうなりますか?',
			'paywall.faq.afterCancel.a' => '現在の課金期間が終了するまでは Cosmic Pro 機能を継続してお使いいただけます。期間終了後は Free プランに自動移行します。読み解き結果の履歴は端末内に保存されたまま残ります。',
			'paywall.faq.resubscribe.q' => 'Pro を再契約すると週次クレジットは増えますか?',
			'paywall.faq.resubscribe.a' => 'いいえ。週次クレジットは 1 アカウントごとに管理され、毎週月曜日にリセットされます。Pro を解約してすぐ再契約しても、その時点の残数は変わりません。不正利用ではありませんが、再契約によって「週 100 回」の制度を繰り返し補充するような抜け穴的な使い方はできない仕組みです。\n\n例: 水曜日に週次クレジットが残り 0 の状態で Pro を解約し、すぐ再契約しても、残りは 0 のままです。翌週の月曜日に 100 回へ復活します。',
			'category.overall' => '総合',
			'category.healing' => '癒し',
			'category.abundance' => '豊かさ',
			'category.love' => '恋愛',
			'category.work' => '仕事',
			'category.talk' => '話す',
			'category.change' => '変化',
			'disclaimer.ai' => '✦ AI 生成・娯楽目的。医療・法律・金融等の専門的な助言ではありません。',
			'disclaimer.fetchFailed' => '解説の取得に失敗しました。通信状況を確認して、もう一度お試しください。',
			'common.tryAgain' => '再試行',
			'aiConsent.subtitle' => 'ご利用前のおしらせ',
			'aiConsent.agree' => '同意して始める',
			'aiConsent.decline' => '同意しない',
			'aiConsent.back' => '戻る',
			'aiConsent.linkOpenFailed' => ({required Object url}) => 'リンクを開けませんでした: ${url}',
			'aiConsent.declineDialog.title' => '本アプリのご利用には同意が必要です',
			'aiConsent.declineDialog.body' => 'Solara をご利用いただくためには、「ご利用前のおしらせ」にご記載の内容にご同意いただく必要がございます。同意なしではご利用いただけません。\n\nもう一度ご確認いただくか、Solara をアンインストールしてください。本アプリでは、ユーザーの個人情報を含む一切のデータを受け取っておりませんので、安心してアンインストールしていただけます。',
			'aiConsent.links.privacy' => 'プライバシーポリシー',
			'aiConsent.links.terms' => '利用規約',
			'aiConsent.intro.heading' => '◆ はじめに',
			'aiConsent.intro.body' => 'このアプリは広大な宇宙のデータを1つにまとめたアプリです。その瞬間1点において占星術を使い解釈する時、膨大なデータが実は存在します。このアプリはその膨大なデータを判断材料としてあなたに提供する、とても便利なアプリです。\n\nアプリが解釈して生成する文章やデータはエビデンスとして列挙してあり、そのエビデンスから導き出される1つの解釈としてあなたに提示しています。\n\nエビデンスを元に様々な解釈もできるので、本アプリからの提示は、解釈の一つの例に過ぎません。本アプリで、提示する文章において違和感を感じた場合は、エビデンスをもとにご自身の解釈を加えてみてください。是非、本アプリのデータを活用してあなた自身で占星術を試して頂けると幸いです。\n\n本アプリは現役の占星術師である私が作りました。あなたの人生が、あなたらしく輝いて生きられるように願っています。\n私はあなたの幸せを祈っています。あなたと本アプリを通して出会えた事に感謝します。ありがとう。\n\nー Solara 開発者より',
			'aiConsent.entertainment.heading' => '◆ 本アプリは娯楽・自己探求を目的としています',
			'aiConsent.entertainment.body' => 'Solara の以下のすべての機能は、娯楽および自己探求のための手段です。\n\n・出生図・トランジット・プログレスなどの占星術\n・タロットカードの引きと解釈\n・Stella との相談\n・星読み\n・地図上のアストロカートグラフィと方位スコア表示\n\n医療・法律・金融・心理に関する専門的な助言ではありません。将来の出来事を予測・保証するものでもありません。',
			'aiConsent.thirdParty.heading' => '◆ 第三者へのデータ送信について',
			'aiConsent.thirdParty.body' => '本アプリは、サービス提供のために以下の第三者サービスへデータを送信します:\n\n・Apple / Google ─ 不正利用防止 (デバイス認証) のため。認証情報を送信します。\n・Google Gemini AI ─ 占星術を元にした解釈文章生成及びタロット解釈文章生成のため。あなたの出生情報 (生年月日・出生時刻・出生地) と相談で入力したテキストを送信します。\n・RevenueCat ─ 課金管理のため。匿名 ID と購入情報を送信します。',
			'aiConsent.geminiContent.heading' => '◆ Gemini AI が生成するコンテンツについて',
			'aiConsent.geminiContent.body' => '本アプリは、以下の機能で Google の Gemini AI を利用して文章を生成しています:\n\n・タロット ─ 引いたカードの解釈文章\n・Stella 相談 ─ あなたの問いへの占星術相談の解釈文章\n・星読み ─ 5 カテゴリ別 (恋愛 / 豊かさ / 仕事 / 対話 / 全体) の解釈文章\n・リロケーション (地図) ─ 地図上で選択した地点の占星術解釈文章',
			'aiConsent.decisions.heading' => '◆ 重要な意思決定について',
			'aiConsent.decisions.body' => 'Solara の読み解きは、あなた自身を理解するための参考情報です。不正確だったり、あなたに合わない内容になる場合もあります。\n\n違和感を感じた結果は鵜呑みにせず、移住・転職・結婚など人生の重要な判断は、ご自身の意思と、ご家族・専門家への相談に基づいて行ってください。\n\nデータの詳しい取扱いは下記をご確認ください。',
			'aiConsent.consentHandling.heading' => '◆ 同意の取扱いについて',
			'aiConsent.consentHandling.body' => '「同意して始める」を押すと、この「ご利用前のおしらせ」に記載されている事項に同意した事実を端末内に記録します。次回以降は表示されません。（規約変更の際は再度のご案内をさせて頂く場合がございます）\n\n同意しない場合は、画面下の「同意しない」をタップしていただき、Solara をアンインストールしてください。この時点では、本アプリではユーザーの個人情報含む一切のデータを受け取っておりません。',
			_ => null,
		};
	}
}

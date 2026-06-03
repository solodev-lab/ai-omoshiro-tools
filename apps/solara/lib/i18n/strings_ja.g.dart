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
	late final Translations$consultResult$ja consultResult = Translations$consultResult$ja.internal(_root);
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

// Path: consultInput
class Translations$consultInput$ja {
	Translations$consultInput$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
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

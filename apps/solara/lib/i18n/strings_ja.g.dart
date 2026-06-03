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
	late final Translations$paywall$ja paywall = Translations$paywall$ja.internal(_root);
	late final Translations$category$ja category = Translations$category$ja.internal(_root);
	late final Translations$disclaimer$ja disclaimer = Translations$disclaimer$ja.internal(_root);
	late final Translations$common$ja common = Translations$common$ja.internal(_root);
	late final Translations$aiConsent$ja aiConsent = Translations$aiConsent$ja.internal(_root);
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

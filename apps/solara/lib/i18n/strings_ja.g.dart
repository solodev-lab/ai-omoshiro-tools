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
	late final Translations$category$ja category = Translations$category$ja.internal(_root);
	late final Translations$disclaimer$ja disclaimer = Translations$disclaimer$ja.internal(_root);
	late final Translations$common$ja common = Translations$common$ja.internal(_root);
	late final Translations$aiConsent$ja aiConsent = Translations$aiConsent$ja.internal(_root);
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

/// The flat map containing all translations for locale <ja>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
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

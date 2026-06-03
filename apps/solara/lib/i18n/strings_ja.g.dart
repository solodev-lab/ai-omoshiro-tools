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
			_ => null,
		};
	}
}

///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsEn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$category$en category = _Translations$category$en._(_root);
	@override late final _Translations$disclaimer$en disclaimer = _Translations$disclaimer$en._(_root);
	@override late final _Translations$common$en common = _Translations$common$en._(_root);
}

// Path: category
class _Translations$category$en extends Translations$category$ja {
	_Translations$category$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get overall => 'Overall';
	@override String get healing => 'Healing';
	@override String get abundance => 'Abundance';
	@override String get love => 'Love';
	@override String get work => 'Work';
	@override String get talk => 'Talk';
	@override String get change => 'Change';
}

// Path: disclaimer
class _Translations$disclaimer$en extends Translations$disclaimer$ja {
	_Translations$disclaimer$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get ai => '✦ AI-generated, for entertainment & self-reflection. Not professional medical, legal, or financial advice.';
	@override String get fetchFailed => 'We couldn\'t load the reading. Please check your connection and try again.';
}

// Path: common
class _Translations$common$en extends Translations$common$ja {
	_Translations$common$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get tryAgain => 'Try again';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'category.overall' => 'Overall',
			'category.healing' => 'Healing',
			'category.abundance' => 'Abundance',
			'category.love' => 'Love',
			'category.work' => 'Work',
			'category.talk' => 'Talk',
			'category.change' => 'Change',
			'disclaimer.ai' => '✦ AI-generated, for entertainment & self-reflection. Not professional medical, legal, or financial advice.',
			'disclaimer.fetchFailed' => 'We couldn\'t load the reading. Please check your connection and try again.',
			'common.tryAgain' => 'Try again',
			_ => null,
		};
	}
}

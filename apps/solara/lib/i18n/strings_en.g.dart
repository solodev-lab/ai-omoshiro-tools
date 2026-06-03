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
	@override late final _Translations$aiConsent$en aiConsent = _Translations$aiConsent$en._(_root);
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

// Path: aiConsent
class _Translations$aiConsent$en extends Translations$aiConsent$ja {
	_Translations$aiConsent$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Before You Begin';
	@override String get agree => 'Agree and Begin';
	@override String get decline => 'Decline';
	@override String get back => 'Back';
	@override String linkOpenFailed({required Object url}) => 'Couldn\'t open the link: ${url}';
	@override late final _Translations$aiConsent$declineDialog$en declineDialog = _Translations$aiConsent$declineDialog$en._(_root);
	@override late final _Translations$aiConsent$links$en links = _Translations$aiConsent$links$en._(_root);
	@override late final _Translations$aiConsent$intro$en intro = _Translations$aiConsent$intro$en._(_root);
	@override late final _Translations$aiConsent$entertainment$en entertainment = _Translations$aiConsent$entertainment$en._(_root);
	@override late final _Translations$aiConsent$thirdParty$en thirdParty = _Translations$aiConsent$thirdParty$en._(_root);
	@override late final _Translations$aiConsent$geminiContent$en geminiContent = _Translations$aiConsent$geminiContent$en._(_root);
	@override late final _Translations$aiConsent$decisions$en decisions = _Translations$aiConsent$decisions$en._(_root);
	@override late final _Translations$aiConsent$consentHandling$en consentHandling = _Translations$aiConsent$consentHandling$en._(_root);
}

// Path: aiConsent.declineDialog
class _Translations$aiConsent$declineDialog$en extends Translations$aiConsent$declineDialog$ja {
	_Translations$aiConsent$declineDialog$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Consent is required to use Solara';
	@override String get body => 'To use Solara, you\'ll need to agree to what\'s described in "Before You Begin." Without your consent, the app can\'t be used.\n\nPlease take another look, or feel free to uninstall Solara. At this point we have not received any of your data, including any personal information, so you can uninstall with complete peace of mind.';
}

// Path: aiConsent.links
class _Translations$aiConsent$links$en extends Translations$aiConsent$links$ja {
	_Translations$aiConsent$links$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get privacy => 'Privacy Policy';
	@override String get terms => 'Terms of Service';
}

// Path: aiConsent.intro
class _Translations$aiConsent$intro$en extends Translations$aiConsent$intro$ja {
	_Translations$aiConsent$intro$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get heading => '◆ Welcome';
	@override String get body => 'Solara gathers the vast data of the cosmos into one place. Behind a single moment, read through astrology, lies an enormous wealth of data. Solara hands that wealth to you as material to reflect on — a genuinely useful companion.\n\nThe text and data Solara generates are laid out as evidence, and what you read is offered as one interpretation drawn from that evidence.\n\nBecause evidence can be read in many ways, what Solara offers is only one example among many. If something in the words feels off to you, return to the evidence and add your own reading. I would be glad if you used Solara\'s data to explore astrology in your own way.\n\nI built this app as a practicing astrologer. My wish is that your life shines in a way that is wholly your own.\nI am praying for your happiness. I\'m grateful that we met through this app. Thank you.\n\n— From the maker of Solara';
}

// Path: aiConsent.entertainment
class _Translations$aiConsent$entertainment$en extends Translations$aiConsent$entertainment$ja {
	_Translations$aiConsent$entertainment$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get heading => '◆ Solara is for entertainment and self-discovery';
	@override String get body => 'All of the following features in Solara are means for entertainment and self-discovery:\n\n• Astrology such as birth charts, transits, and progressions\n• Drawing and interpreting tarot cards\n• Consultations with Stella\n• Star readings\n• Astrocartography on the map and directional energy scores\n\nThey are not professional medical, legal, financial, or psychological advice, and they do not predict or guarantee future events.';
}

// Path: aiConsent.thirdParty
class _Translations$aiConsent$thirdParty$en extends Translations$aiConsent$thirdParty$ja {
	_Translations$aiConsent$thirdParty$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get heading => '◆ Data sent to third parties';
	@override String get body => 'To provide its service, Solara sends data to the following third parties:\n\n• Apple / Google — for abuse prevention (device attestation). Attestation data is sent.\n• Google Gemini AI — to generate astrology-based interpretations and tarot interpretations. Your birth details (date, time, and place of birth) and the text you enter in consultations are sent.\n• RevenueCat — for purchase management. An anonymous ID and purchase information are sent.';
}

// Path: aiConsent.geminiContent
class _Translations$aiConsent$geminiContent$en extends Translations$aiConsent$geminiContent$ja {
	_Translations$aiConsent$geminiContent$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get heading => '◆ Content generated by Gemini AI';
	@override String get body => 'Solara uses Google\'s Gemini AI to generate text in the following features:\n\n• Tarot — interpretations of the cards you draw\n• Stella Consultation — astrological interpretations in response to your questions\n• Star Reading — interpretations across five categories (Love / Abundance / Work / Talk / Overall)\n• Relocation (map) — astrological interpretations for the point you select on the map';
}

// Path: aiConsent.decisions
class _Translations$aiConsent$decisions$en extends Translations$aiConsent$decisions$ja {
	_Translations$aiConsent$decisions$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get heading => '◆ About important decisions';
	@override String get body => 'Solara\'s interpretations are reference material for understanding yourself. At times they may be inaccurate, or may not fit you.\n\nIf a result feels off, please don\'t take it at face value. For life\'s important decisions — moving, changing jobs, marriage — please rely on your own judgment and on talking with family and professionals.\n\nFor details on how your data is handled, please see below.';
}

// Path: aiConsent.consentHandling
class _Translations$aiConsent$consentHandling$en extends Translations$aiConsent$consentHandling$ja {
	_Translations$aiConsent$consentHandling$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get heading => '◆ How your consent is handled';
	@override String get body => 'When you tap "Agree and Begin," the fact that you agreed to what\'s described in "Before You Begin" is recorded on your device. It won\'t be shown again. (If the terms change, we may show this notice once more.)\n\nIf you do not agree, please tap "Decline" at the bottom of the screen and uninstall Solara. At this point, we have not received any of your data, including any personal information.';
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
			'aiConsent.subtitle' => 'Before You Begin',
			'aiConsent.agree' => 'Agree and Begin',
			'aiConsent.decline' => 'Decline',
			'aiConsent.back' => 'Back',
			'aiConsent.linkOpenFailed' => ({required Object url}) => 'Couldn\'t open the link: ${url}',
			'aiConsent.declineDialog.title' => 'Consent is required to use Solara',
			'aiConsent.declineDialog.body' => 'To use Solara, you\'ll need to agree to what\'s described in "Before You Begin." Without your consent, the app can\'t be used.\n\nPlease take another look, or feel free to uninstall Solara. At this point we have not received any of your data, including any personal information, so you can uninstall with complete peace of mind.',
			'aiConsent.links.privacy' => 'Privacy Policy',
			'aiConsent.links.terms' => 'Terms of Service',
			'aiConsent.intro.heading' => '◆ Welcome',
			'aiConsent.intro.body' => 'Solara gathers the vast data of the cosmos into one place. Behind a single moment, read through astrology, lies an enormous wealth of data. Solara hands that wealth to you as material to reflect on — a genuinely useful companion.\n\nThe text and data Solara generates are laid out as evidence, and what you read is offered as one interpretation drawn from that evidence.\n\nBecause evidence can be read in many ways, what Solara offers is only one example among many. If something in the words feels off to you, return to the evidence and add your own reading. I would be glad if you used Solara\'s data to explore astrology in your own way.\n\nI built this app as a practicing astrologer. My wish is that your life shines in a way that is wholly your own.\nI am praying for your happiness. I\'m grateful that we met through this app. Thank you.\n\n— From the maker of Solara',
			'aiConsent.entertainment.heading' => '◆ Solara is for entertainment and self-discovery',
			'aiConsent.entertainment.body' => 'All of the following features in Solara are means for entertainment and self-discovery:\n\n• Astrology such as birth charts, transits, and progressions\n• Drawing and interpreting tarot cards\n• Consultations with Stella\n• Star readings\n• Astrocartography on the map and directional energy scores\n\nThey are not professional medical, legal, financial, or psychological advice, and they do not predict or guarantee future events.',
			'aiConsent.thirdParty.heading' => '◆ Data sent to third parties',
			'aiConsent.thirdParty.body' => 'To provide its service, Solara sends data to the following third parties:\n\n• Apple / Google — for abuse prevention (device attestation). Attestation data is sent.\n• Google Gemini AI — to generate astrology-based interpretations and tarot interpretations. Your birth details (date, time, and place of birth) and the text you enter in consultations are sent.\n• RevenueCat — for purchase management. An anonymous ID and purchase information are sent.',
			'aiConsent.geminiContent.heading' => '◆ Content generated by Gemini AI',
			'aiConsent.geminiContent.body' => 'Solara uses Google\'s Gemini AI to generate text in the following features:\n\n• Tarot — interpretations of the cards you draw\n• Stella Consultation — astrological interpretations in response to your questions\n• Star Reading — interpretations across five categories (Love / Abundance / Work / Talk / Overall)\n• Relocation (map) — astrological interpretations for the point you select on the map',
			'aiConsent.decisions.heading' => '◆ About important decisions',
			'aiConsent.decisions.body' => 'Solara\'s interpretations are reference material for understanding yourself. At times they may be inaccurate, or may not fit you.\n\nIf a result feels off, please don\'t take it at face value. For life\'s important decisions — moving, changing jobs, marriage — please rely on your own judgment and on talking with family and professionals.\n\nFor details on how your data is handled, please see below.',
			'aiConsent.consentHandling.heading' => '◆ How your consent is handled',
			'aiConsent.consentHandling.body' => 'When you tap "Agree and Begin," the fact that you agreed to what\'s described in "Before You Begin" is recorded on your device. It won\'t be shown again. (If the terms change, we may show this notice once more.)\n\nIf you do not agree, please tap "Decline" at the bottom of the screen and uninstall Solara. At this point, we have not received any of your data, including any personal information.',
			_ => null,
		};
	}
}

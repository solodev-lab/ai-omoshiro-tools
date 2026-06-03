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
	@override late final _Translations$mapMenu$en mapMenu = _Translations$mapMenu$en._(_root);
	@override late final _Translations$locations$en locations = _Translations$locations$en._(_root);
	@override late final _Translations$paywall$en paywall = _Translations$paywall$en._(_root);
	@override late final _Translations$category$en category = _Translations$category$en._(_root);
	@override late final _Translations$disclaimer$en disclaimer = _Translations$disclaimer$en._(_root);
	@override late final _Translations$common$en common = _Translations$common$en._(_root);
	@override late final _Translations$aiConsent$en aiConsent = _Translations$aiConsent$en._(_root);
}

// Path: mapMenu
class _Translations$mapMenu$en extends Translations$mapMenu$ja {
	_Translations$mapMenu$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get tabPlanet => 'Planets';
	@override late final _Translations$mapMenu$map$en map = _Translations$mapMenu$map$en._(_root);
	@override late final _Translations$mapMenu$planet$en planet = _Translations$mapMenu$planet$en._(_root);
	@override late final _Translations$mapMenu$acg$en acg = _Translations$mapMenu$acg$en._(_root);
	@override late final _Translations$mapMenu$pg$en pg = _Translations$mapMenu$pg$en._(_root);
	@override late final _Translations$mapMenu$popup$en popup = _Translations$mapMenu$popup$en._(_root);
}

// Path: locations
class _Translations$locations$en extends Translations$locations$ja {
	_Translations$locations$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override List<String> get locDefaults => [
		'Place 1',
		'Place 2',
		'Place 3',
		'Place 4',
	];
	@override List<String> get vpDefaults => [
		'Workplace',
		'Favorite',
		'Spot',
		'Place',
	];
	@override String get currentAddress => 'Current address';
	@override String get mapCenter => 'Map center';
	@override String get renameTitle => 'Enter a name for this place';
	@override String get cancel => 'Cancel';
	@override String bearing({required Object dir}) => '${dir}';
	@override String get emptyTitle => 'No places saved yet';
	@override String get addCurrent => '📍 Save current location';
	@override String get menuRename => '✏ Rename';
	@override String get menuDelete => '🗑 Delete';
	@override late final _Translations$locations$guide$en guide = _Translations$locations$guide$en._(_root);
}

// Path: paywall
class _Translations$paywall$en extends Translations$paywall$ja {
	_Translations$paywall$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$paywall$period$en period = _Translations$paywall$period$en._(_root);
	@override late final _Translations$paywall$introPeriod$en introPeriod = _Translations$paywall$introPeriod$en._(_root);
	@override late final _Translations$paywall$store$en store = _Translations$paywall$store$en._(_root);
	@override String get autoRenewNotice => 'Your subscription renews automatically. Unless you cancel auto-renewal at least 24 hours before the end of the current period, it renews at the same price for the next period. You will be charged to your Apple ID / Google account within 24 hours before the period ends. You can manage or cancel auto-renewal anytime in your store account settings.';
	@override late final _Translations$paywall$legal$en legal = _Translations$paywall$legal$en._(_root);
	@override String get restore => 'Restore purchases';
	@override late final _Translations$paywall$hero$en hero = _Translations$paywall$hero$en._(_root);
	@override late final _Translations$paywall$billing$en billing = _Translations$paywall$billing$en._(_root);
	@override late final _Translations$paywall$plans$en plans = _Translations$paywall$plans$en._(_root);
	@override late final _Translations$paywall$cta$en cta = _Translations$paywall$cta$en._(_root);
	@override late final _Translations$paywall$comparison$en comparison = _Translations$paywall$comparison$en._(_root);
	@override late final _Translations$paywall$faq$en faq = _Translations$paywall$faq$en._(_root);
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

// Path: mapMenu.map
class _Translations$mapMenu$map$en extends Translations$mapMenu$map$ja {
	_Translations$mapMenu$map$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get dirEnergy => 'Directional Energy';
	@override String get compass => 'Compass';
	@override String get coords => 'Coordinates';
}

// Path: mapMenu.planet
class _Translations$mapMenu$planet$en extends Translations$mapMenu$planet$ja {
	_Translations$mapMenu$planet$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get type => 'Type';
	@override String get group => 'Group';
	@override String get focus => 'Focus';
}

// Path: mapMenu.acg
class _Translations$mapMenu$acg$en extends Translations$mapMenu$acg$ja {
	_Translations$mapMenu$acg$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get natalLine => 'Natal lines';
	@override String get transitLine => 'Transit lines';
	@override String get progLine => 'Prog lines';
	@override String get sArcLine => 'S.Arc lines';
	@override String get aspectLines => 'Aspect lines';
	@override String get relocate => 'Relocate';
}

// Path: mapMenu.pg
class _Translations$mapMenu$pg$en extends Translations$mapMenu$pg$ja {
	_Translations$mapMenu$pg$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get personal => 'Personal';
	@override String get social => 'Social';
	@override String get generational => 'Generational';
}

// Path: mapMenu.popup
class _Translations$mapMenu$popup$en extends Translations$mapMenu$popup$ja {
	_Translations$mapMenu$popup$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get mapTitle => 'Map layers';
	@override String get mapDarkBody => 'Switch between the normal and dark map. Choose by visibility preference.';
	@override String get dirEnergyBody => 'Shows your stars\' energy as 16-direction fans on the map. The darker a direction\'s color, the stronger its energy. Tap to filter by category.';
	@override String get compassBody => 'Direction lines (N / E / S / W) seen from the center point. Helps gauge bearing.';
	@override String get coordsBody => 'Shows a latitude/longitude label below the + at the center of the screen. As you move the map, the center coordinates update in real time. Tap the label to copy it to the clipboard. Useful for checking before saving a place, or for confirming the coordinates of any point. The crosshair (+) itself is always shown, even when this toggle is off.';
	@override String get planetTitle => 'Planet layers';
	@override String get typeBody => 'Which chart\'s planets to show. Natal (fixed at birth) / Prog (one day = one year) / Transit (this very moment).';
	@override String groupBody({required Object personal, required Object social, required Object generational}) => 'Group filter for the 10 planets.\n• Personal: ${personal}\n• Social: ${social}\n• Generational: ${generational}';
	@override String focusBody({required Object healing, required Object money, required Object love, required Object work, required Object communication}) => 'Category filter — highlights only the planets related to a theme.\n• Overall: all planets\n• Healing: ${healing}\n• Abundance: ${money}\n• Love: ${love}\n• Work: ${work}\n• Talk: ${communication}';
	@override String get acgTitle => 'ACG layers (Astro*Carto*Graphy)';
	@override String get framesHead => 'The 4 frames of lines (Natal / Transit / Prog / S.Arc)';
	@override String get framesBody => 'Draws the "main lines" of each planet × 4 angles (ASC/MC/DSC/IC) on a world scale. All 4 frames can be switched for free (Natal = fixed at birth / Transit = moving now / Prog = secondary progression / S.Arc = solar arc). The i button beside each pill has a detailed explanation.';
	@override String get aspectHead => 'Aspect lines [Pro]';
	@override String get aspectBody => 'An extension that adds square / trine / sextile to the main lines (40 conjunction lines), for 120 lines in total. It applies to all frames that are on at the same time. Cosmic Pro only.';
	@override String get relocateHead => 'Relocate [Pro]';
	@override String get relocateBody => 'Treats the point you tap on the map as a relocation destination. You can check, all together: (1) which planets\' lines move closer or farther compared with your current address, (2) the sign changes of ASC / MC, and (3) the 12-house transitions of the 10 planets. Cosmic Pro only.';
	@override String get hintHead => 'Display tip';
	@override String get hintBody => 'Because ACG lines are drawn on a world scale, at some zoom levels they may move off-screen and be hard to see. Zooming out makes the overall picture of the lines easier to see.';
}

// Path: locations.guide
class _Translations$locations$guide$en extends Translations$locations$guide$ja {
	_Translations$locations$guide$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'How to use LOCATIONS';
	@override String get intro => 'See, at a glance, the energy of your LOCATIONS (saved places)\nas viewed from the VIEWPOINT (your chosen center point) you registered.\nSave the places you care about as LOCATIONS,\nand you can read today\'s energy for each at a glance.\n\nRegister the places you visit often, and you\'ll see\nthings like "this park has a high Healing score today" or\n"this café has a high Love score today" —\na handy way to see how strong today\'s energy is\nat each saved place.';
	@override String get dateTimeHead => '[Date & time]';
	@override String get dateTimeBody => 'Change the "date" and "time" at the top to recalculate\nthe scores for that moment. The "Back to today" button\nreturns you to the present.';
	@override String get viewpointHead => '[Switch VIEWPOINT]';
	@override String get viewpointBody => 'The "VIEWPOINT" dropdown switches the reference point for\ndistance and direction scores.\nYou can choose the map center (current location), your current address,\nor a VIEWPOINT you\'ve saved.';
	@override String get categoryHead => '[Switch category]';
	@override String get categoryBody => 'Tap Healing / Abundance / Love / Work / Talk to switch,\nand the places are re-ranked by that category\'s score.\nTap the same category again to deselect (= show the overall score).';
	@override String get registerHead => '[Saving a place]';
	@override String get registerBody => 'From the 📍 button on the left of the Map screen, you can save\nthe point at the center of the map as either a VIEWPOINT or a LOCATION.\nSaved places can also be renamed or deleted.';
}

// Path: paywall.period
class _Translations$paywall$period$en extends Translations$paywall$period$ja {
	_Translations$paywall$period$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get year => 'year';
	@override String get sixMonth => '6 months';
	@override String get threeMonth => '3 months';
	@override String get twoMonth => '2 months';
	@override String get month => 'month';
	@override String get week => 'week';
	@override String get lifetime => 'one-time';
	@override String get generic => 'period';
}

// Path: paywall.introPeriod
class _Translations$paywall$introPeriod$en extends Translations$paywall$introPeriod$ja {
	_Translations$paywall$introPeriod$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String days({required Object n}) => '${n} days';
	@override String weeks({required Object n}) => '${n} weeks';
	@override String months({required Object n}) => '${n} months';
	@override String years({required Object n}) => '${n} years';
	@override String unknown({required Object n}) => '${n}';
}

// Path: paywall.store
class _Translations$paywall$store$en extends Translations$paywall$store$ja {
	_Translations$paywall$store$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get preparingTitle => 'The store is being set up';
	@override String get preparingBody => 'Purchases will be available after launch.\nPlease wait a moment and try again.';
	@override String get recheck => 'Check again';
}

// Path: paywall.legal
class _Translations$paywall$legal$en extends Translations$paywall$legal$ja {
	_Translations$paywall$legal$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get cancelMethod => 'How to cancel';
	@override String get terms => 'Terms of Service';
	@override String get privacy => 'Privacy Policy';
	@override String get sctaNotice => 'Commercial Transactions Act notice';
}

// Path: paywall.hero
class _Translations$paywall$hero$en extends Translations$paywall$hero$ja {
	_Translations$paywall$hero$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'The complete experience — for deeper conversations with Stella, and for reading the landscape where sky meets land.';
}

// Path: paywall.billing
class _Translations$paywall$billing$en extends Translations$paywall$billing$ja {
	_Translations$paywall$billing$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get monthly => 'Monthly';
	@override String get annual => 'Annual';
}

// Path: paywall.plans
class _Translations$paywall$plans$en extends Translations$paywall$plans$ja {
	_Translations$paywall$plans$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get currentPlan => 'Current plan';
	@override String get freePrice => 'Free  /  forever';
	@override String get priceLoading => 'Loading price…';
	@override String get taxIncl => '(tax incl.)';
	@override String monthlyEquivalent({required Object yen}) => '≈ ¥${yen} / month';
	@override String trialLine({required Object period}) => '🎁 ${period} free trial → auto-billing after it ends';
	@override String get badgeSubscribed => 'Subscribed';
	@override String get badgePopular => 'Popular';
	@override late final _Translations$paywall$plans$free$en free = _Translations$paywall$plans$free$en._(_root);
	@override late final _Translations$paywall$plans$pro$en pro = _Translations$paywall$plans$pro$en._(_root);
}

// Path: paywall.cta
class _Translations$paywall$cta$en extends Translations$paywall$cta$ja {
	_Translations$paywall$cta$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get manageSubscription => 'Manage subscription';
	@override String get startAnnual => 'Start annual plan';
	@override String get startMonthly => 'Start monthly plan';
}

// Path: paywall.comparison
class _Translations$paywall$comparison$en extends Translations$paywall$comparison$ja {
	_Translations$paywall$comparison$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Free vs Pro';
	@override String get colFeature => 'Feature';
	@override String get secConsult => 'Consultation & Interpretation';
	@override String get secMap => 'Map (ACG / CCG)';
	@override String get secRecords => 'Records (your records are kept forever, even on Free)';
	@override String get secForecast => 'Forecast';
	@override late final _Translations$paywall$comparison$stellaConsult$en stellaConsult = _Translations$paywall$comparison$stellaConsult$en._(_root);
	@override late final _Translations$paywall$comparison$tarot$en tarot = _Translations$paywall$comparison$tarot$en._(_root);
	@override late final _Translations$paywall$comparison$starReading$en starReading = _Translations$paywall$comparison$starReading$en._(_root);
	@override late final _Translations$paywall$comparison$relocationLine$en relocationLine = _Translations$paywall$comparison$relocationLine$en._(_root);
	@override late final _Translations$paywall$comparison$outingTime$en outingTime = _Translations$paywall$comparison$outingTime$en._(_root);
	@override late final _Translations$paywall$comparison$acgFrames$en acgFrames = _Translations$paywall$comparison$acgFrames$en._(_root);
	@override late final _Translations$paywall$comparison$zenithNadirPoints$en zenithNadirPoints = _Translations$paywall$comparison$zenithNadirPoints$en._(_root);
	@override late final _Translations$paywall$comparison$zenithNadirBands$en zenithNadirBands = _Translations$paywall$comparison$zenithNadirBands$en._(_root);
	@override late final _Translations$paywall$comparison$aspectLines$en aspectLines = _Translations$paywall$comparison$aspectLines$en._(_root);
	@override late final _Translations$paywall$comparison$relocationSim$en relocationSim = _Translations$paywall$comparison$relocationSim$en._(_root);
	@override late final _Translations$paywall$comparison$locationSlots$en locationSlots = _Translations$paywall$comparison$locationSlots$en._(_root);
	@override late final _Translations$paywall$comparison$recordsSave$en recordsSave = _Translations$paywall$comparison$recordsSave$en._(_root);
	@override late final _Translations$paywall$comparison$archiveSearch$en archiveSearch = _Translations$paywall$comparison$archiveSearch$en._(_root);
	@override late final _Translations$paywall$comparison$replayExport$en replayExport = _Translations$paywall$comparison$replayExport$en._(_root);
	@override late final _Translations$paywall$comparison$titleRediagnosis$en titleRediagnosis = _Translations$paywall$comparison$titleRediagnosis$en._(_root);
	@override late final _Translations$paywall$comparison$forecastPeriod$en forecastPeriod = _Translations$paywall$comparison$forecastPeriod$en._(_root);
}

// Path: paywall.faq
class _Translations$paywall$faq$en extends Translations$paywall$faq$ja {
	_Translations$paywall$faq$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Frequently Asked Questions';
	@override late final _Translations$paywall$faq$diff$en diff = _Translations$paywall$faq$diff$en._(_root);
	@override late final _Translations$paywall$faq$weeklyCap$en weeklyCap = _Translations$paywall$faq$weeklyCap$en._(_root);
	@override late final _Translations$paywall$faq$proTarot$en proTarot = _Translations$paywall$faq$proTarot$en._(_root);
	@override late final _Translations$paywall$faq$outing30min$en outing30min = _Translations$paywall$faq$outing30min$en._(_root);
	@override late final _Translations$paywall$faq$upgradeDowngrade$en upgradeDowngrade = _Translations$paywall$faq$upgradeDowngrade$en._(_root);
	@override late final _Translations$paywall$faq$afterCancel$en afterCancel = _Translations$paywall$faq$afterCancel$en._(_root);
	@override late final _Translations$paywall$faq$resubscribe$en resubscribe = _Translations$paywall$faq$resubscribe$en._(_root);
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

// Path: paywall.plans.free
class _Translations$paywall$plans$free$en extends Translations$paywall$plans$free$ja {
	_Translations$paywall$plans$free$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get stella => 'Stella Consultation  3 / week (Monday reset) + purchased credits';
	@override String get tarot => 'Tarot  once a day (choosing a category uses a credit)';
	@override String get starReading => 'Star Reading  "Overall" category only';
	@override String get aspectLines => 'Aspect lines  40';
	@override String get acgFrames => 'ACG / CCG  all 4 frames (natal / transit / prog / solar arc)';
	@override String get archiveSearch => 'Search & filter for Star Atlas and tarot history';
	@override String get replayExport => 'Replay the formation animation · export as text';
	@override String get save => 'Permanent saving and sharing of your interpretations';
}

// Path: paywall.plans.pro
class _Translations$paywall$plans$pro$en extends Translations$paywall$plans$pro$ja {
	_Translations$paywall$plans$pro$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get stella => 'Stella Consultation  100 / week (Monday reset)';
	@override String get outing => 'Outing consultations  set the time in one-hour steps + read "changes 30 minutes later" (CCG lines move with Earth\'s rotation; the lead star shifts between the first and second half)';
	@override String get tarot => 'Tarot  choose any of 7 categories (Overall · Love · Abundance · Work · Talk · Healing · Change) with no credits used + question field';
	@override String get starReading => 'Star Reading  all 5 categories (Overall · Love · Abundance · Work · Talk) + deeper reading';
	@override String get forecast => 'Forecast — 5-year outlook  see periods of romance and abundance up to 5 years ahead, and view the heatmap 5 years out';
	@override String get aspectLines => 'Aspect lines  all 120 (conjunction · square · trine · sextile)';
	@override String get zenithBands => 'Zenith / Nadir bands  shows the latitudes where a planet passes directly overhead or underfoot, as bands (Lewis style)';
	@override String get relocationSim => 'Relocation simulation  tap a location to recompute ASC / MC / the 12 houses';
	@override String get slots => 'Saved home bases  10 places';
	@override String get rediagnosis => 'Re-diagnosing your Title (Class)  unlimited';
}

// Path: paywall.comparison.stellaConsult
class _Translations$paywall$comparison$stellaConsult$en extends Translations$paywall$comparison$stellaConsult$ja {
	_Translations$paywall$comparison$stellaConsult$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Stella Consultation';
	@override String get free => '3 / week\n+ purchased credits';
	@override String get pro => '100 / week';
}

// Path: paywall.comparison.tarot
class _Translations$paywall$comparison$tarot$en extends Translations$paywall$comparison$tarot$ja {
	_Translations$paywall$comparison$tarot$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Tarot';
	@override String get free => 'Overall free\nOther categories: 1 credit\n(once a day)';
	@override String get pro => 'All 7 categories\nno credits used\n+ question field\n(once a day)';
}

// Path: paywall.comparison.starReading
class _Translations$paywall$comparison$starReading$en extends Translations$paywall$comparison$starReading$ja {
	_Translations$paywall$comparison$starReading$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Star Reading (Horo)';
	@override String get free => '"Overall" only';
	@override String get pro => 'All 5 categories\n(Overall · Love · Abundance\n· Work · Talk)\n+ deeper reading';
}

// Path: paywall.comparison.relocationLine
class _Translations$paywall$comparison$relocationLine$en extends Translations$paywall$comparison$relocationLine$ja {
	_Translations$paywall$comparison$relocationLine$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Home base reading (line proximity)';
}

// Path: paywall.comparison.outingTime
class _Translations$paywall$comparison$outingTime$en extends Translations$paywall$comparison$outingTime$ja {
	_Translations$paywall$comparison$outingTime$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Set the time of your outing\n+ changes 30 min later';
	@override String get pro => '✓\n(hourly)';
}

// Path: paywall.comparison.acgFrames
class _Translations$paywall$comparison$acgFrames$en extends Translations$paywall$comparison$acgFrames$ja {
	_Translations$paywall$comparison$acgFrames$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'ACG / CCG — 4 frames';
	@override String get value => '✓ all\n(natal/transit\n/prog/solar arc)';
}

// Path: paywall.comparison.zenithNadirPoints
class _Translations$paywall$comparison$zenithNadirPoints$en extends Translations$paywall$comparison$zenithNadirPoints$ja {
	_Translations$paywall$comparison$zenithNadirPoints$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Zenith / Nadir points · category filter';
}

// Path: paywall.comparison.zenithNadirBands
class _Translations$paywall$comparison$zenithNadirBands$en extends Translations$paywall$comparison$zenithNadirBands$ja {
	_Translations$paywall$comparison$zenithNadirBands$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Zenith / Nadir bands (latitude bands)';
}

// Path: paywall.comparison.aspectLines
class _Translations$paywall$comparison$aspectLines$en extends Translations$paywall$comparison$aspectLines$ja {
	_Translations$paywall$comparison$aspectLines$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Aspect lines';
	@override String get free => '40 lines\n(conjunction)';
	@override String get pro => '120 lines\n(conj. □ △ ⚹)';
}

// Path: paywall.comparison.relocationSim
class _Translations$paywall$comparison$relocationSim$en extends Translations$paywall$comparison$relocationSim$ja {
	_Translations$paywall$comparison$relocationSim$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Relocation simulation';
}

// Path: paywall.comparison.locationSlots
class _Translations$paywall$comparison$locationSlots$en extends Translations$paywall$comparison$locationSlots$ja {
	_Translations$paywall$comparison$locationSlots$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Home base slots (VP / LOCATION)';
	@override String get free => '5 places';
	@override String get pro => '10 places';
}

// Path: paywall.comparison.recordsSave
class _Translations$paywall$comparison$recordsSave$en extends Translations$paywall$comparison$recordsSave$ja {
	_Translations$paywall$comparison$recordsSave$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Permanent saving of interpretations & cycles';
}

// Path: paywall.comparison.archiveSearch
class _Translations$paywall$comparison$archiveSearch$en extends Translations$paywall$comparison$archiveSearch$ja {
	_Translations$paywall$comparison$archiveSearch$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Search / filter Star Atlas & history';
}

// Path: paywall.comparison.replayExport
class _Translations$paywall$comparison$replayExport$en extends Translations$paywall$comparison$replayExport$ja {
	_Translations$paywall$comparison$replayExport$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Replay formation animation · export as text';
}

// Path: paywall.comparison.titleRediagnosis
class _Translations$paywall$comparison$titleRediagnosis$en extends Translations$paywall$comparison$titleRediagnosis$ja {
	_Translations$paywall$comparison$titleRediagnosis$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Re-diagnose your Title (Class)';
	@override String get free => 'Up to once';
	@override String get pro => 'Unlimited';
}

// Path: paywall.comparison.forecastPeriod
class _Translations$paywall$comparison$forecastPeriod$en extends Translations$paywall$comparison$forecastPeriod$ja {
	_Translations$paywall$comparison$forecastPeriod$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Forecast range';
	@override String get free => '1 year';
	@override String get pro => '5 years';
}

// Path: paywall.faq.diff
class _Translations$paywall$faq$diff$en extends Translations$paywall$faq$diff$ja {
	_Translations$paywall$faq$diff$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get q => 'What\'s the difference between Free and Pro?';
	@override String get a => 'Stella Consultation goes from 3 / week on Free to 100 / week on Pro; Star Reading goes from "Overall" only on Free to all 5 categories on Pro; aspect lines increase from 40 on Free to 120 on Pro. Tarot is once a day on both plans, but Pro adds no credit cost when you choose a category, plus a question field.\n\nThe 4 ACG / CCG frames, search and filter for the Star Atlas and tarot history, and saving and sharing your interpretations are all available on Free too. Please see the table above for details.';
}

// Path: paywall.faq.weeklyCap
class _Translations$paywall$faq$weeklyCap$en extends Translations$paywall$faq$weeklyCap$ja {
	_Translations$paywall$faq$weeklyCap$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get q => 'What happens if I exceed the weekly cap for Stella Consultation?';
	@override String get a => 'You can keep going by purchasing additional credits. On Pro, your 100 / week are replenished at the Monday reset.';
}

// Path: paywall.faq.proTarot
class _Translations$paywall$faq$proTarot$en extends Translations$paywall$faq$proTarot$ja {
	_Translations$paywall$faq$proTarot$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get q => 'What changes with Tarot on Pro?';
	@override String get a => 'Tarot is once a day on both Free and Pro. On Pro, you can choose the category you want to ask about (Overall · Love · Abundance · Work · Talk · Healing · Change) and draw a reading without spending any credits. You can also type what you\'d like to know as a direct question, and the reading responds to it.\n\nOn Free, only Overall is free (once a day); other categories cost 1 credit each time.';
}

// Path: paywall.faq.outing30min
class _Translations$paywall$faq$outing30min$en extends Translations$paywall$faq$outing30min$ja {
	_Translations$paywall$faq$outing30min$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get q => 'What does "changes 30 minutes later" mean in outing consultations?';
	@override String get a => 'With Cosmic Pro, you can set the time of an outing or event consultation in one-hour steps. The star lines of astrocartography (CCG) move with Earth\'s rotation, so even in the same place the "lead star of the moment" quietly changes within 30 minutes.\n\nOpening "View 30 minutes later" on the result screen lets you read the shift in advance — Mars\'s line drawing away, or Venus\'s line drawing near. You begin to see how to use your time in that place, such as "the heart of it comes early" or "it warms up toward the latter half" (this is not good or bad fortune, but a shift in the quality of energy).';
}

// Path: paywall.faq.upgradeDowngrade
class _Translations$paywall$faq$upgradeDowngrade$en extends Translations$paywall$faq$upgradeDowngrade$ja {
	_Translations$paywall$faq$upgradeDowngrade$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get q => 'Can I upgrade or downgrade my plan?';
	@override String get a => 'You can change it anytime from the subscription management screen in the Apple App Store or Google Play. If you cancel auto-renewal, you\'ll switch to the Free plan automatically from your next billing date.';
}

// Path: paywall.faq.afterCancel
class _Translations$paywall$faq$afterCancel$en extends Translations$paywall$faq$afterCancel$ja {
	_Translations$paywall$faq$afterCancel$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get q => 'What happens to features after I cancel?';
	@override String get a => 'You can keep using Cosmic Pro features until your current billing period ends. After it ends, you\'ll move to the Free plan automatically. Your history of interpretations stays saved on your device.';
}

// Path: paywall.faq.resubscribe
class _Translations$paywall$faq$resubscribe$en extends Translations$paywall$faq$resubscribe$ja {
	_Translations$paywall$faq$resubscribe$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get q => 'If I resubscribe to Pro, do my weekly credits increase?';
	@override String get a => 'No. Weekly credits are managed per account and reset every Monday. Even if you cancel Pro and resubscribe right away, your remaining count at that moment doesn\'t change. This isn\'t about misuse — it simply means resubscribing can\'t be used as a loophole to repeatedly top up the "100 / week" allowance.\n\nExample: if you cancel Pro on a Wednesday with 0 weekly credits left and resubscribe immediately, the remaining count stays at 0. It returns to 100 the following Monday.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'mapMenu.tabPlanet' => 'Planets',
			'mapMenu.map.dirEnergy' => 'Directional Energy',
			'mapMenu.map.compass' => 'Compass',
			'mapMenu.map.coords' => 'Coordinates',
			'mapMenu.planet.type' => 'Type',
			'mapMenu.planet.group' => 'Group',
			'mapMenu.planet.focus' => 'Focus',
			'mapMenu.acg.natalLine' => 'Natal lines',
			'mapMenu.acg.transitLine' => 'Transit lines',
			'mapMenu.acg.progLine' => 'Prog lines',
			'mapMenu.acg.sArcLine' => 'S.Arc lines',
			'mapMenu.acg.aspectLines' => 'Aspect lines',
			'mapMenu.acg.relocate' => 'Relocate',
			'mapMenu.pg.personal' => 'Personal',
			'mapMenu.pg.social' => 'Social',
			'mapMenu.pg.generational' => 'Generational',
			'mapMenu.popup.mapTitle' => 'Map layers',
			'mapMenu.popup.mapDarkBody' => 'Switch between the normal and dark map. Choose by visibility preference.',
			'mapMenu.popup.dirEnergyBody' => 'Shows your stars\' energy as 16-direction fans on the map. The darker a direction\'s color, the stronger its energy. Tap to filter by category.',
			'mapMenu.popup.compassBody' => 'Direction lines (N / E / S / W) seen from the center point. Helps gauge bearing.',
			'mapMenu.popup.coordsBody' => 'Shows a latitude/longitude label below the + at the center of the screen. As you move the map, the center coordinates update in real time. Tap the label to copy it to the clipboard. Useful for checking before saving a place, or for confirming the coordinates of any point. The crosshair (+) itself is always shown, even when this toggle is off.',
			'mapMenu.popup.planetTitle' => 'Planet layers',
			'mapMenu.popup.typeBody' => 'Which chart\'s planets to show. Natal (fixed at birth) / Prog (one day = one year) / Transit (this very moment).',
			'mapMenu.popup.groupBody' => ({required Object personal, required Object social, required Object generational}) => 'Group filter for the 10 planets.\n• Personal: ${personal}\n• Social: ${social}\n• Generational: ${generational}',
			'mapMenu.popup.focusBody' => ({required Object healing, required Object money, required Object love, required Object work, required Object communication}) => 'Category filter — highlights only the planets related to a theme.\n• Overall: all planets\n• Healing: ${healing}\n• Abundance: ${money}\n• Love: ${love}\n• Work: ${work}\n• Talk: ${communication}',
			'mapMenu.popup.acgTitle' => 'ACG layers (Astro*Carto*Graphy)',
			'mapMenu.popup.framesHead' => 'The 4 frames of lines (Natal / Transit / Prog / S.Arc)',
			'mapMenu.popup.framesBody' => 'Draws the "main lines" of each planet × 4 angles (ASC/MC/DSC/IC) on a world scale. All 4 frames can be switched for free (Natal = fixed at birth / Transit = moving now / Prog = secondary progression / S.Arc = solar arc). The i button beside each pill has a detailed explanation.',
			'mapMenu.popup.aspectHead' => 'Aspect lines [Pro]',
			'mapMenu.popup.aspectBody' => 'An extension that adds square / trine / sextile to the main lines (40 conjunction lines), for 120 lines in total. It applies to all frames that are on at the same time. Cosmic Pro only.',
			'mapMenu.popup.relocateHead' => 'Relocate [Pro]',
			'mapMenu.popup.relocateBody' => 'Treats the point you tap on the map as a relocation destination. You can check, all together: (1) which planets\' lines move closer or farther compared with your current address, (2) the sign changes of ASC / MC, and (3) the 12-house transitions of the 10 planets. Cosmic Pro only.',
			'mapMenu.popup.hintHead' => 'Display tip',
			'mapMenu.popup.hintBody' => 'Because ACG lines are drawn on a world scale, at some zoom levels they may move off-screen and be hard to see. Zooming out makes the overall picture of the lines easier to see.',
			'locations.locDefaults.0' => 'Place 1',
			'locations.locDefaults.1' => 'Place 2',
			'locations.locDefaults.2' => 'Place 3',
			'locations.locDefaults.3' => 'Place 4',
			'locations.vpDefaults.0' => 'Workplace',
			'locations.vpDefaults.1' => 'Favorite',
			'locations.vpDefaults.2' => 'Spot',
			'locations.vpDefaults.3' => 'Place',
			'locations.currentAddress' => 'Current address',
			'locations.mapCenter' => 'Map center',
			'locations.renameTitle' => 'Enter a name for this place',
			'locations.cancel' => 'Cancel',
			'locations.bearing' => ({required Object dir}) => '${dir}',
			'locations.emptyTitle' => 'No places saved yet',
			'locations.addCurrent' => '📍 Save current location',
			'locations.menuRename' => '✏ Rename',
			'locations.menuDelete' => '🗑 Delete',
			'locations.guide.title' => 'How to use LOCATIONS',
			'locations.guide.intro' => 'See, at a glance, the energy of your LOCATIONS (saved places)\nas viewed from the VIEWPOINT (your chosen center point) you registered.\nSave the places you care about as LOCATIONS,\nand you can read today\'s energy for each at a glance.\n\nRegister the places you visit often, and you\'ll see\nthings like "this park has a high Healing score today" or\n"this café has a high Love score today" —\na handy way to see how strong today\'s energy is\nat each saved place.',
			'locations.guide.dateTimeHead' => '[Date & time]',
			'locations.guide.dateTimeBody' => 'Change the "date" and "time" at the top to recalculate\nthe scores for that moment. The "Back to today" button\nreturns you to the present.',
			'locations.guide.viewpointHead' => '[Switch VIEWPOINT]',
			'locations.guide.viewpointBody' => 'The "VIEWPOINT" dropdown switches the reference point for\ndistance and direction scores.\nYou can choose the map center (current location), your current address,\nor a VIEWPOINT you\'ve saved.',
			'locations.guide.categoryHead' => '[Switch category]',
			'locations.guide.categoryBody' => 'Tap Healing / Abundance / Love / Work / Talk to switch,\nand the places are re-ranked by that category\'s score.\nTap the same category again to deselect (= show the overall score).',
			'locations.guide.registerHead' => '[Saving a place]',
			'locations.guide.registerBody' => 'From the 📍 button on the left of the Map screen, you can save\nthe point at the center of the map as either a VIEWPOINT or a LOCATION.\nSaved places can also be renamed or deleted.',
			'paywall.period.year' => 'year',
			'paywall.period.sixMonth' => '6 months',
			'paywall.period.threeMonth' => '3 months',
			'paywall.period.twoMonth' => '2 months',
			'paywall.period.month' => 'month',
			'paywall.period.week' => 'week',
			'paywall.period.lifetime' => 'one-time',
			'paywall.period.generic' => 'period',
			'paywall.introPeriod.days' => ({required Object n}) => '${n} days',
			'paywall.introPeriod.weeks' => ({required Object n}) => '${n} weeks',
			'paywall.introPeriod.months' => ({required Object n}) => '${n} months',
			'paywall.introPeriod.years' => ({required Object n}) => '${n} years',
			'paywall.introPeriod.unknown' => ({required Object n}) => '${n}',
			'paywall.store.preparingTitle' => 'The store is being set up',
			'paywall.store.preparingBody' => 'Purchases will be available after launch.\nPlease wait a moment and try again.',
			'paywall.store.recheck' => 'Check again',
			'paywall.autoRenewNotice' => 'Your subscription renews automatically. Unless you cancel auto-renewal at least 24 hours before the end of the current period, it renews at the same price for the next period. You will be charged to your Apple ID / Google account within 24 hours before the period ends. You can manage or cancel auto-renewal anytime in your store account settings.',
			'paywall.legal.cancelMethod' => 'How to cancel',
			'paywall.legal.terms' => 'Terms of Service',
			'paywall.legal.privacy' => 'Privacy Policy',
			'paywall.legal.sctaNotice' => 'Commercial Transactions Act notice',
			'paywall.restore' => 'Restore purchases',
			'paywall.hero.subtitle' => 'The complete experience — for deeper conversations with Stella, and for reading the landscape where sky meets land.',
			'paywall.billing.monthly' => 'Monthly',
			'paywall.billing.annual' => 'Annual',
			'paywall.plans.currentPlan' => 'Current plan',
			'paywall.plans.freePrice' => 'Free  /  forever',
			'paywall.plans.priceLoading' => 'Loading price…',
			'paywall.plans.taxIncl' => '(tax incl.)',
			'paywall.plans.monthlyEquivalent' => ({required Object yen}) => '≈ ¥${yen} / month',
			'paywall.plans.trialLine' => ({required Object period}) => '🎁 ${period} free trial → auto-billing after it ends',
			'paywall.plans.badgeSubscribed' => 'Subscribed',
			'paywall.plans.badgePopular' => 'Popular',
			'paywall.plans.free.stella' => 'Stella Consultation  3 / week (Monday reset) + purchased credits',
			'paywall.plans.free.tarot' => 'Tarot  once a day (choosing a category uses a credit)',
			'paywall.plans.free.starReading' => 'Star Reading  "Overall" category only',
			'paywall.plans.free.aspectLines' => 'Aspect lines  40',
			'paywall.plans.free.acgFrames' => 'ACG / CCG  all 4 frames (natal / transit / prog / solar arc)',
			'paywall.plans.free.archiveSearch' => 'Search & filter for Star Atlas and tarot history',
			'paywall.plans.free.replayExport' => 'Replay the formation animation · export as text',
			'paywall.plans.free.save' => 'Permanent saving and sharing of your interpretations',
			'paywall.plans.pro.stella' => 'Stella Consultation  100 / week (Monday reset)',
			'paywall.plans.pro.outing' => 'Outing consultations  set the time in one-hour steps + read "changes 30 minutes later" (CCG lines move with Earth\'s rotation; the lead star shifts between the first and second half)',
			'paywall.plans.pro.tarot' => 'Tarot  choose any of 7 categories (Overall · Love · Abundance · Work · Talk · Healing · Change) with no credits used + question field',
			'paywall.plans.pro.starReading' => 'Star Reading  all 5 categories (Overall · Love · Abundance · Work · Talk) + deeper reading',
			'paywall.plans.pro.forecast' => 'Forecast — 5-year outlook  see periods of romance and abundance up to 5 years ahead, and view the heatmap 5 years out',
			'paywall.plans.pro.aspectLines' => 'Aspect lines  all 120 (conjunction · square · trine · sextile)',
			'paywall.plans.pro.zenithBands' => 'Zenith / Nadir bands  shows the latitudes where a planet passes directly overhead or underfoot, as bands (Lewis style)',
			'paywall.plans.pro.relocationSim' => 'Relocation simulation  tap a location to recompute ASC / MC / the 12 houses',
			'paywall.plans.pro.slots' => 'Saved home bases  10 places',
			'paywall.plans.pro.rediagnosis' => 'Re-diagnosing your Title (Class)  unlimited',
			'paywall.cta.manageSubscription' => 'Manage subscription',
			'paywall.cta.startAnnual' => 'Start annual plan',
			'paywall.cta.startMonthly' => 'Start monthly plan',
			'paywall.comparison.title' => 'Free vs Pro',
			'paywall.comparison.colFeature' => 'Feature',
			'paywall.comparison.secConsult' => 'Consultation & Interpretation',
			'paywall.comparison.secMap' => 'Map (ACG / CCG)',
			'paywall.comparison.secRecords' => 'Records (your records are kept forever, even on Free)',
			'paywall.comparison.secForecast' => 'Forecast',
			'paywall.comparison.stellaConsult.label' => 'Stella Consultation',
			'paywall.comparison.stellaConsult.free' => '3 / week\n+ purchased credits',
			'paywall.comparison.stellaConsult.pro' => '100 / week',
			'paywall.comparison.tarot.label' => 'Tarot',
			'paywall.comparison.tarot.free' => 'Overall free\nOther categories: 1 credit\n(once a day)',
			'paywall.comparison.tarot.pro' => 'All 7 categories\nno credits used\n+ question field\n(once a day)',
			'paywall.comparison.starReading.label' => 'Star Reading (Horo)',
			'paywall.comparison.starReading.free' => '"Overall" only',
			'paywall.comparison.starReading.pro' => 'All 5 categories\n(Overall · Love · Abundance\n· Work · Talk)\n+ deeper reading',
			'paywall.comparison.relocationLine.label' => 'Home base reading (line proximity)',
			'paywall.comparison.outingTime.label' => 'Set the time of your outing\n+ changes 30 min later',
			'paywall.comparison.outingTime.pro' => '✓\n(hourly)',
			'paywall.comparison.acgFrames.label' => 'ACG / CCG — 4 frames',
			'paywall.comparison.acgFrames.value' => '✓ all\n(natal/transit\n/prog/solar arc)',
			'paywall.comparison.zenithNadirPoints.label' => 'Zenith / Nadir points · category filter',
			'paywall.comparison.zenithNadirBands.label' => 'Zenith / Nadir bands (latitude bands)',
			'paywall.comparison.aspectLines.label' => 'Aspect lines',
			'paywall.comparison.aspectLines.free' => '40 lines\n(conjunction)',
			'paywall.comparison.aspectLines.pro' => '120 lines\n(conj. □ △ ⚹)',
			'paywall.comparison.relocationSim.label' => 'Relocation simulation',
			'paywall.comparison.locationSlots.label' => 'Home base slots (VP / LOCATION)',
			'paywall.comparison.locationSlots.free' => '5 places',
			'paywall.comparison.locationSlots.pro' => '10 places',
			'paywall.comparison.recordsSave.label' => 'Permanent saving of interpretations & cycles',
			'paywall.comparison.archiveSearch.label' => 'Search / filter Star Atlas & history',
			'paywall.comparison.replayExport.label' => 'Replay formation animation · export as text',
			'paywall.comparison.titleRediagnosis.label' => 'Re-diagnose your Title (Class)',
			'paywall.comparison.titleRediagnosis.free' => 'Up to once',
			'paywall.comparison.titleRediagnosis.pro' => 'Unlimited',
			'paywall.comparison.forecastPeriod.label' => 'Forecast range',
			'paywall.comparison.forecastPeriod.free' => '1 year',
			'paywall.comparison.forecastPeriod.pro' => '5 years',
			'paywall.faq.title' => 'Frequently Asked Questions',
			'paywall.faq.diff.q' => 'What\'s the difference between Free and Pro?',
			'paywall.faq.diff.a' => 'Stella Consultation goes from 3 / week on Free to 100 / week on Pro; Star Reading goes from "Overall" only on Free to all 5 categories on Pro; aspect lines increase from 40 on Free to 120 on Pro. Tarot is once a day on both plans, but Pro adds no credit cost when you choose a category, plus a question field.\n\nThe 4 ACG / CCG frames, search and filter for the Star Atlas and tarot history, and saving and sharing your interpretations are all available on Free too. Please see the table above for details.',
			'paywall.faq.weeklyCap.q' => 'What happens if I exceed the weekly cap for Stella Consultation?',
			'paywall.faq.weeklyCap.a' => 'You can keep going by purchasing additional credits. On Pro, your 100 / week are replenished at the Monday reset.',
			'paywall.faq.proTarot.q' => 'What changes with Tarot on Pro?',
			'paywall.faq.proTarot.a' => 'Tarot is once a day on both Free and Pro. On Pro, you can choose the category you want to ask about (Overall · Love · Abundance · Work · Talk · Healing · Change) and draw a reading without spending any credits. You can also type what you\'d like to know as a direct question, and the reading responds to it.\n\nOn Free, only Overall is free (once a day); other categories cost 1 credit each time.',
			'paywall.faq.outing30min.q' => 'What does "changes 30 minutes later" mean in outing consultations?',
			'paywall.faq.outing30min.a' => 'With Cosmic Pro, you can set the time of an outing or event consultation in one-hour steps. The star lines of astrocartography (CCG) move with Earth\'s rotation, so even in the same place the "lead star of the moment" quietly changes within 30 minutes.\n\nOpening "View 30 minutes later" on the result screen lets you read the shift in advance — Mars\'s line drawing away, or Venus\'s line drawing near. You begin to see how to use your time in that place, such as "the heart of it comes early" or "it warms up toward the latter half" (this is not good or bad fortune, but a shift in the quality of energy).',
			'paywall.faq.upgradeDowngrade.q' => 'Can I upgrade or downgrade my plan?',
			'paywall.faq.upgradeDowngrade.a' => 'You can change it anytime from the subscription management screen in the Apple App Store or Google Play. If you cancel auto-renewal, you\'ll switch to the Free plan automatically from your next billing date.',
			'paywall.faq.afterCancel.q' => 'What happens to features after I cancel?',
			'paywall.faq.afterCancel.a' => 'You can keep using Cosmic Pro features until your current billing period ends. After it ends, you\'ll move to the Free plan automatically. Your history of interpretations stays saved on your device.',
			'paywall.faq.resubscribe.q' => 'If I resubscribe to Pro, do my weekly credits increase?',
			'paywall.faq.resubscribe.a' => 'No. Weekly credits are managed per account and reset every Monday. Even if you cancel Pro and resubscribe right away, your remaining count at that moment doesn\'t change. This isn\'t about misuse — it simply means resubscribing can\'t be used as a loophole to repeatedly top up the "100 / week" allowance.\n\nExample: if you cancel Pro on a Wednesday with 0 weekly credits left and resubscribe immediately, the remaining count stays at 0. It returns to 100 the following Monday.',
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

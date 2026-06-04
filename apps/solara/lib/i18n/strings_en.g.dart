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
	@override late final _Translations$consultShare$en consultShare = _Translations$consultShare$en._(_root);
	@override late final _Translations$locationPicker$en locationPicker = _Translations$locationPicker$en._(_root);
	@override late final _Translations$dateStepper$en dateStepper = _Translations$dateStepper$en._(_root);
	@override late final _Translations$solaraAuth$en solaraAuth = _Translations$solaraAuth$en._(_root);
	@override late final _Translations$philosophy$en philosophy = _Translations$philosophy$en._(_root);
	@override late final _Translations$moonOverlay$en moonOverlay = _Translations$moonOverlay$en._(_root);
	@override late final _Translations$galaxyArchive$en galaxyArchive = _Translations$galaxyArchive$en._(_root);
	@override late final _Translations$galaxyActions$en galaxyActions = _Translations$galaxyActions$en._(_root);
	@override late final _Translations$starAtlas$en starAtlas = _Translations$starAtlas$en._(_root);
	@override late final _Translations$shareConstellation$en shareConstellation = _Translations$shareConstellation$en._(_root);
	@override late final _Translations$celestialBar$en celestialBar = _Translations$celestialBar$en._(_root);
	@override late final _Translations$mapWelcome$en mapWelcome = _Translations$mapWelcome$en._(_root);
	@override late final _Translations$mapOverlay$en mapOverlay = _Translations$mapOverlay$en._(_root);
	@override late final _Translations$consultEntry$en consultEntry = _Translations$consultEntry$en._(_root);
	@override late final _Translations$planetIntroPopup$en planetIntroPopup = _Translations$planetIntroPopup$en._(_root);
	@override late final _Translations$mapAspect$en mapAspect = _Translations$mapAspect$en._(_root);
	@override late final _Translations$proDialog$en proDialog = _Translations$proDialog$en._(_root);
	@override late final _Translations$observe$en observe = _Translations$observe$en._(_root);
	@override late final _Translations$horoDisplay$en horoDisplay = _Translations$horoDisplay$en._(_root);
	@override late final _Translations$horoPanel$en horoPanel = _Translations$horoPanel$en._(_root);
	@override late final _Translations$horoScreen$en horoScreen = _Translations$horoScreen$en._(_root);
	@override late final _Translations$relocPanel$en relocPanel = _Translations$relocPanel$en._(_root);
	@override late final _Translations$mapReloc$en mapReloc = _Translations$mapReloc$en._(_root);
	@override late final _Translations$mapSearch$en mapSearch = _Translations$mapSearch$en._(_root);
	@override late final _Translations$mapDir$en mapDir = _Translations$mapDir$en._(_root);
	@override late final _Translations$aiReport$en aiReport = _Translations$aiReport$en._(_root);
	@override late final _Translations$mapScreen$en mapScreen = _Translations$mapScreen$en._(_root);
	@override late final _Translations$homeEdit$en homeEdit = _Translations$homeEdit$en._(_root);
	@override late final _Translations$resetPicker$en resetPicker = _Translations$resetPicker$en._(_root);
	@override late final _Translations$orbOverlay$en orbOverlay = _Translations$orbOverlay$en._(_root);
	@override late final _Translations$legalMenu$en legalMenu = _Translations$legalMenu$en._(_root);
	@override late final _Translations$account$en account = _Translations$account$en._(_root);
	@override late final _Translations$shareCard$en shareCard = _Translations$shareCard$en._(_root);
	@override late final _Translations$titleHow$en titleHow = _Translations$titleHow$en._(_root);
	@override late final _Translations$titleHist$en titleHist = _Translations$titleHist$en._(_root);
	@override late final _Translations$profileEdit$en profileEdit = _Translations$profileEdit$en._(_root);
	@override late final _Translations$titleDiag$en titleDiag = _Translations$titleDiag$en._(_root);
	@override late final _Translations$sanctuary$en sanctuary = _Translations$sanctuary$en._(_root);
	@override late final _Translations$mapDaily$en mapDaily = _Translations$mapDaily$en._(_root);
	@override late final _Translations$mapFortune$en mapFortune = _Translations$mapFortune$en._(_root);
	@override late final _Translations$galaxy$en galaxy = _Translations$galaxy$en._(_root);
	@override late final _Translations$forecast$en forecast = _Translations$forecast$en._(_root);
	@override late final _Translations$consultHistory$en consultHistory = _Translations$consultHistory$en._(_root);
	@override late final _Translations$consultCredit$en consultCredit = _Translations$consultCredit$en._(_root);
	@override late final _Translations$consultPlacePicker$en consultPlacePicker = _Translations$consultPlacePicker$en._(_root);
	@override late final _Translations$consultResult$en consultResult = _Translations$consultResult$en._(_root);
	@override late final _Translations$consultStart$en consultStart = _Translations$consultStart$en._(_root);
	@override late final _Translations$consultInput$en consultInput = _Translations$consultInput$en._(_root);
	@override late final _Translations$mapAcg$en mapAcg = _Translations$mapAcg$en._(_root);
	@override late final _Translations$mapVp$en mapVp = _Translations$mapVp$en._(_root);
	@override late final _Translations$mapMenu$en mapMenu = _Translations$mapMenu$en._(_root);
	@override late final _Translations$locations$en locations = _Translations$locations$en._(_root);
	@override late final _Translations$paywall$en paywall = _Translations$paywall$en._(_root);
	@override late final _Translations$category$en category = _Translations$category$en._(_root);
	@override late final _Translations$disclaimer$en disclaimer = _Translations$disclaimer$en._(_root);
	@override late final _Translations$common$en common = _Translations$common$en._(_root);
	@override late final _Translations$appSettings$en appSettings = _Translations$appSettings$en._(_root);
	@override late final _Translations$aiConsent$en aiConsent = _Translations$aiConsent$en._(_root);
}

// Path: consultShare
class _Translations$consultShare$en extends Translations$consultShare$ja {
	_Translations$consultShare$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get header => '— A consultation with Stella · Solara —';
	@override String metaLine({required Object theme, required Object mode, required Object scope}) => 'Theme: ${theme} / Setting: ${mode} / Scope: ${scope}';
	@override String withWhom({required Object v}) => 'With whom: ${v}';
	@override String wish({required Object v}) => 'Wish: ${v}';
	@override String captionIntro({required Object theme}) => 'I asked Stella about "${theme}" on Solara.';
	@override String candidates({required Object names}) => 'Candidates: ${names}';
	@override late final _Translations$consultShare$mode$en mode = _Translations$consultShare$mode$en._(_root);
	@override late final _Translations$consultShare$scope$en scope = _Translations$consultShare$scope$en._(_root);
}

// Path: locationPicker
class _Translations$locationPicker$en extends Translations$locationPicker$ja {
	_Translations$locationPicker$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Move the map to adjust the pin';
}

// Path: dateStepper
class _Translations$dateStepper$en extends Translations$dateStepper$ja {
	_Translations$dateStepper$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get date => 'Date';
	@override String get time => 'Time';
	@override String get backToToday => 'Back to today';
	@override String get year => 'Year';
	@override String get month => 'Month';
	@override String get day => 'Day';
	@override String get hourDialogTitle => 'Time (0–23)';
	@override String get hourSuffix => 'h';
}

// Path: solaraAuth
class _Translations$solaraAuth$en extends Translations$solaraAuth$ja {
	_Translations$solaraAuth$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get appleAccount => 'Apple account';
	@override String get googleAccount => 'Google account';
	@override String get appleOnlyPlatform => 'Sign in with Apple is only available on iOS / macOS';
	@override String get appleUnavailable => 'Sign in with Apple isn\'t available on this device';
	@override String get appleNoUserId => 'Couldn\'t retrieve your Apple user ID';
	@override String get googleSignInFailed => 'Google sign-in failed';
}

// Path: philosophy
class _Translations$philosophy$en extends Translations$philosophy$ja {
	_Translations$philosophy$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Design Philosophy';
}

// Path: moonOverlay
class _Translations$moonOverlay$en extends Translations$moonOverlay$ja {
	_Translations$moonOverlay$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get pressAgainSkip => 'Press again to start with "No particular theme"';
}

// Path: galaxyArchive
class _Translations$galaxyArchive$en extends Translations$galaxyArchive$ja {
	_Translations$galaxyArchive$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get proLabel => 'Search & filter the archive';
	@override String get proDesc => 'Filter your completed cycles by name, rarity, and order.\nThe more your records build up, the easier they are to look back on.';
	@override String get searchHint => 'Search by name (e.g. Wing / Dragon)';
	@override String get searchHintLocked => 'Search — Cosmic Pro';
	@override String get sortNewest => 'Newest first';
	@override String get sortOldest => 'Oldest first';
	@override String get sortRarity => 'By rarity';
	@override String get sortTooltip => 'Sort order';
	@override String get selectedLabel => 'Selected:';
	@override String get clear => 'Clear';
}

// Path: galaxyActions
class _Translations$galaxyActions$en extends Translations$galaxyActions$ja {
	_Translations$galaxyActions$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get copied => 'Copied as text';
	@override String get replayLabel => 'Replay';
	@override String get replaySub => 'Watch the lines being drawn';
	@override String get formationLabel => 'Play the formation';
	@override String get formationSub => 'Play the 8-second catasterism scene';
	@override String get copyLabel => 'Copy as text';
	@override String get copySub => 'To the clipboard as Markdown';
}

// Path: starAtlas
class _Translations$starAtlas$en extends Translations$starAtlas$ja {
	_Translations$starAtlas$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String resultCount({required Object shown, required Object total}) => '${shown} / ${total}';
	@override String get noMatch => 'No cycles match your filters';
}

// Path: shareConstellation
class _Translations$shareConstellation$en extends Translations$shareConstellation$ja {
	_Translations$shareConstellation$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String shareText({required Object name}) => 'My constellation "${name}" has formed.\n#Solara';
	@override String shareFailed({required Object e}) => 'Share failed: ${e}';
	@override String get appBarTitle => 'Share constellation';
	@override String get shareButton => '✦ Share constellation card';
}

// Path: celestialBar
class _Translations$celestialBar$en extends Translations$celestialBar$ja {
	_Translations$celestialBar$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get ingress => 'Ingress';
	@override String get retrograde => 'Retrograde';
	@override String get retrogradeEnd => 'Direct';
	@override String get eclipse => 'Eclipse';
	@override String get conjunction => 'Conjunction';
	@override String get nodeShift => 'Node shift';
}

// Path: mapWelcome
class _Translations$mapWelcome$en extends Translations$mapWelcome$ja {
	_Translations$mapWelcome$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get addHomeTitle => '✦ Register your current location and receive 3 free credits';
	@override String get addHomeSub => 'We\'ll read the stars from where you are now — and you can use it for Stella consultations too.';
	@override String get addHomeCta => 'Set current location';
	@override String get signinTitle => '✦ Sign in with Google / Apple and receive 3 more free credits';
	@override String get signinSub => 'Signing in carries your records over, so a new device or a reinstall is nothing to worry about.';
	@override String get signinCta => 'Sign in';
	@override String get stellaTitle => '✦ Welcome. We\'ve given you 3 free credits';
	@override String get stellaSub => 'These consultation tickets don\'t reset weekly. Why not ask Stella about your stars and your place?';
	@override String get stellaCta => 'Ask Stella';
}

// Path: mapOverlay
class _Translations$mapOverlay$en extends Translations$mapOverlay$ja {
	_Translations$mapOverlay$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get searchHint => 'Search for a place...';
	@override String get vpLabel => 'VP:';
	@override String get currentLocation => '📍 Current location';
	@override String get home => 'Home';
	@override String get today => 'Today';
	@override String get birthplace => 'Birthplace';
}

// Path: consultEntry
class _Translations$consultEntry$en extends Translations$consultEntry$ja {
	_Translations$consultEntry$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get loading => 'Loading…';
	@override String get getCoords => 'Copy coords';
	@override String get coordsCopied => 'Coordinates copied';
	@override String get nearestLines => 'Nearest lines';
	@override String get consultHere => 'Consult about this place';
}

// Path: planetIntroPopup
class _Translations$planetIntroPopup$en extends Translations$planetIntroPopup$ja {
	_Translations$planetIntroPopup$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get frameNatal => 'NATAL';
	@override String get frameTransit => 'TRANSIT';
	@override String get frameProgressed => 'PROGRESSED';
	@override String basics({required Object name}) => '${name} basics';
	@override String get preparing => 'An interpretation for this planet is still being prepared.';
}

// Path: mapAspect
class _Translations$mapAspect$en extends Translations$mapAspect$ja {
	_Translations$mapAspect$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get orb => 'Orb ';
	@override String get nature => 'Nature';
	@override String get theme => 'Theme';
	@override String get reading => 'Reading';
}

// Path: proDialog
class _Translations$proDialog$en extends Translations$proDialog$ja {
	_Translations$proDialog$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String isFeature({required Object label}) => '${label} is a Pro feature';
	@override String get upgrade => 'Upgrade to Pro';
	@override String get close => 'Close';
	@override String get secTitle => '✦ Device security check';
	@override String unavailableHere({required Object label}) => '${label} isn\'t available on this device right now';
	@override String get compromisedBody => 'We\'ve detected signs of tampering or analysis tools (rooting, Frida, jailbreak, emulator, etc.) on this device.\n\nPro features are locked because we can\'t provide them safely here.\nFree features remain available as usual.';
}

// Path: observe
class _Translations$observe$en extends Translations$observe$ja {
	_Translations$observe$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get loading1 => 'The stars are weaving their words for you';
	@override String get loading2 => 'Listening closely to the planets\' whispers';
	@override String get loading3 => 'Unraveling the mystery of the cards';
	@override String get loading4 => 'Crystallizing what today means for you';
	@override String get tapToDraw => '👆 Tap to draw a card';
	@override String get alreadyDrawn => '✓ Today\'s card already drawn';
	@override String get offlineMode => '⚠ Offline mode (simplified)';
	@override String get failTitle => 'Couldn\'t load the reading.';
	@override String get failBody => 'Please check your connection and try again.';
	@override String get stellaNote => 'Stella shows this as one interpretation drawn from the cards. If something feels off, feel free to expand on it with your own reading. What\'s shown here is only one of many interpretations.';
	@override String get posUpright => 'Upright';
	@override String get posReversed => 'Reversed';
	@override String get posShortUpright => 'Up';
	@override String get posShortReversed => 'Rev';
	@override String get cancel => 'Cancel';
	@override String get delete => 'Delete';
	@override String get creditTitleFree => 'Use a free credit';
	@override String get creditTitlePaid => 'Use a paid credit';
	@override String get creditTitleNone => 'No credits';
	@override String catLine({required Object label}) => 'Category: ${label}';
	@override String get freeCredits => 'Free credits';
	@override String freeRemaining({required Object remaining, required Object limit}) => '${remaining} / ${limit} left';
	@override String get freeChecking => 'Checking remaining';
	@override String get weeklyRefill => 'Refills every Monday';
	@override String get paidCredits => 'Paid credits';
	@override String paidRemaining({required Object n}) => '${n} left';
	@override String get noExpiry => 'No expiry (purchased credits carry across devices)';
	@override String get buyCredits => 'Buy credits';
	@override String get draw => 'Draw';
	@override String get todayTheme => 'Today\'s theme';
	@override String themeOptional({required Object n}) => 'Optional · ${n}/200';
	@override String get alreadyDrawnHint => 'Already drawn today (come back tomorrow)';
	@override String get themeExample => 'e.g. I\'m unsure whether to start a new project';
	@override String get qProFeature => 'Tarot with a question';
	@override String get qProDesc => 'Add a "theme for today" in 200 characters or less, and Stella reads the cards in tune with it. Cosmic Pro also unlocks a deeper reading.';
	@override String get addTheme => 'Draw with today\'s theme';
	@override String get qProHint => 'Cosmic Pro opens the theme field, and Stella reads in tune with it.';
	@override String get readCategory => 'Category to read';
	@override String get onceADay => 'Tarot is once a day';
	@override String get catCreditNonOverall => 'Choosing a category other than Overall uses a credit.';
	@override String catCreditWithCount({required Object free, required Object purExtra}) => 'Choosing a category uses 1 credit (${free} free left${purExtra})';
	@override String purExtra({required Object n}) => ' · ${n} purchased';
	@override String get catCreditSimple => 'Choosing a category uses 1 credit';
	@override String get overallFree => 'Overall uses no credits';
	@override String get fullText => 'Show full text for easy reading';
	@override String get confirm => 'Confirm';
	@override String get deleteAllConfirm => 'Delete all history?';
	@override String get tabCurrentCycle => 'This cycle';
	@override String get tabPastCycle => 'Past cycles';
	@override String get limitNote => '* History keeps up to 50 entries. The oldest are removed automatically.';
	@override String countLine({required Object visible, required Object total}) => '${visible} / ${total}';
	@override String get emptyHistory => 'No history yet\n\nDraw a card on the TAROT DRAW tab\nto record it here';
	@override String get noMatch => 'No cards match your filters';
	@override String get home => 'Home';
	@override String get hasQuestion => 'Has a question';
	@override String get memoHintSync => 'Note a coincidence or insight...';
	@override String get noPastCycles => 'No past cycles yet\n\nWhen the moon fills and a new cycle begins,\nyour tarot history until then remains here.';
	@override String dateCount({required Object date, required Object count}) => '${date} · ${count}';
	@override String get noTarotInCycle => 'No tarot history in this cycle';
	@override String get memoHintPast => 'Note what you noticed back then...';
	@override String get filterProFeature => 'Search & filter history';
	@override String get filterProDesc => 'Narrow your past card history by keyword, arcana, or element.\nThe moment you\'re after, found in an instant.';
	@override String get searchHint => 'Search card name, reading, question, synchronicity';
	@override String get searchProLocked => 'Search — Cosmic Pro';
	@override String get majorArcana => 'Major Arcana';
	@override String get minorArcana => 'Minor Arcana';
}

// Path: horoDisplay
class _Translations$horoDisplay$en extends Translations$horoDisplay$ja {
	_Translations$horoDisplay$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get filterHint => 'Left check = toggle ON/OFF / Right label = open description';
	@override String get secPlacement => 'Placement features';
	@override String get secNatal => 'When natal (N)';
	@override String get secTransit => 'When transit-active (T)';
	@override String get secProgress => 'When progressed (P)';
	@override String get active => 'Active';
	@override String get soon => 'Soon';
	@override String daysLater({required Object days}) => 'in ${days} days';
	@override String get legendSoft => 'Soft';
	@override String get legendHard => 'Hard';
	@override String get neutral => 'Neutral';
	@override String get legendNatal => 'Natal';
	@override String get legendTransit => 'Transit';
	@override String get legendProgress => 'Progress';
	@override String get backdropSub => 'Set it up in SANCTUARY to also see your own personal horoscope';
	@override String orb({required Object deg}) => 'Orb ${deg}°';
	@override String get aspNature => 'Nature';
	@override String get aspTheme => 'Theme';
	@override String get aspReading => 'Reading';
	@override String get noAspects => 'No aspects';
	@override String moreAspects({required Object n}) => '... ${n} more';
	@override String horoOfDate({required Object date}) => 'Horoscope for ${date}';
	@override String get stellaNote => 'Stella shows this as one interpretation, drawn from the aspects and houses of your horoscope. If something feels off, the evidence behind Stella\'s reading is right there in your horoscope — please feel free to expand on it with your own interpretation. What\'s shown here is only one of many readings.';
	@override String get birthDataNote => 'Star readings reflect only your original birth details.\nEdits to BIRTH DATA are not reflected in star readings.';
	@override String proOpenReading({required Object name}) => 'Cosmic Pro also opens ${name}\'s reading';
	@override String get filterSecAspect => 'Aspect nature';
	@override String get filterSoft => 'Soft (harmony)';
	@override String get filterHard => 'Hard (tension)';
	@override String get filterSecCategory => 'Category';
	@override String get filterSecPlanetGroup => 'Planet group';
	@override String get filterPersonal => 'Personal planets';
	@override String get filterSocial => 'Social planets';
	@override String get filterGenerational => 'Generational planets';
}

// Path: horoPanel
class _Translations$horoPanel$en extends Translations$horoPanel$ja {
	_Translations$horoPanel$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get tabBirth => 'Birth';
	@override String get tabProgress => 'Progress';
	@override String get tabTransit => 'Transit';
	@override String get tabPlanets => 'Planets';
	@override String get tabRelocate => 'Base';
	@override String get tabFilter => 'Filter';
	@override String get tabAspects => 'Aspects';
	@override String get progressUpdate => 'Update progression';
	@override String get transitUpdate => 'Update transit';
	@override String get dateLabel => 'DATE';
	@override String get timeLabel => 'TIME';
	@override String get placeLabel => 'PLACE';
	@override String get hourSuffix => 'h';
	@override String get minuteSuffix => 'm';
	@override String get birthDataNote => '* BIRTH DATA resets when you leave the Horo screen';
	@override String get nameLabel => 'NAME';
	@override String get nameHint => 'Friend A\'s name (optional)';
	@override String get birthDateLabel => 'DATE';
	@override String get birthTimeLabel => 'TIME';
	@override String get unknown => 'Unknown';
	@override String get birthCityHint => 'City/town level is fine for the birthplace — no street address needed';
	@override String get birthplaceLabel => 'BIRTHPLACE';
	@override String get calcCta => '✨ Calculate with this data';
	@override String get clipboardInvalid => 'No valid "latitude, longitude" on the clipboard';
	@override String get pasteCoords => 'Paste coordinates';
	@override String get copyHint => 'Tap a point on the Map → "Copy coords" to copy';
	@override String get autoFetch => '— (auto-fetched after you enter coordinates)';
	@override String get latLabel => 'LAT';
	@override String get latHint => 'e.g. 35.6762';
	@override String get lngLabel => 'LNG';
	@override String get lngHint => 'e.g. 139.6503';
	@override String get tzLabel => 'TZ';
}

// Path: horoScreen
class _Translations$horoScreen$en extends Translations$horoScreen$ja {
	_Translations$horoScreen$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get thisTheme => 'this theme';
	@override String proReadLabel({required Object name}) => 'Stella\'s reading of ${name}';
	@override String proReadDesc({required Object name}) => 'Stella reads today\'s star positions through the theme of "${name}". All 5 categories and deeper readings are unlocked with Cosmic Pro.';
	@override String get fortuneApiError => 'Couldn\'t connect to the Fortune API';
	@override String get modeNatal => 'NATAL';
	@override String get modeNT => 'N+T';
	@override String get modeNP => 'N+P';
	@override String get modeAstro => '✦ Star reading';
	@override String get houseEssence => 'Essence';
	@override String get houseEssenceTip => 'Houses based on your birthplace';
	@override String get houseReality => 'Reality';
	@override String get houseRealityTipHome => 'Houses based on your current residence (relocation)';
	@override String get houseRealityTipNoHome => 'Please set your current residence in the Sanctuary';
}

// Path: relocPanel
class _Translations$relocPanel$en extends Translations$relocPanel$ja {
	_Translations$relocPanel$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String headerSub({required Object from, required Object to}) => 'From ${from} to ${to}: how the planets near and leave the angles';
	@override String get loading => 'Stella is reading the stars of this place…';
	@override String get failTitle => 'Couldn\'t load the reading.';
	@override String get failBody => 'Please check your connection and try again.';
	@override String get secAngleSign => 'The angles\' signs change';
	@override String get secPlanetAngle => 'How close the 10 planets are to the angles';
	@override String angleHead({required Object angle, required Object domain}) => '${angle} (${domain})';
	@override String axisLabel({required Object angle}) => '${angle} axis';
	@override String get tagHouseShift => '◆ House shift';
	@override String get tagCloser => '▲ Approaching';
	@override String get tagFarther => '▽ Receding';
	@override String get tagSame => '・ Almost no change';
	@override String get needChart => 'Set your birth time and current residence to read which angle the planets draw near here.';
	@override String get samePlace => 'Your birthplace and current residence are almost the same spot. The farther you move, the more clearly the distance between planets and angles changes.';
	@override String get footnote => '* The closer a planet is to an angle (ASC/MC/DSC/IC), the more that planet\'s theme comes forward in that land. Not a good/bad verdict, but a leaning toward "stronger / gentler".';
}

// Path: mapReloc
class _Translations$mapReloc$en extends Translations$mapReloc$ja {
	_Translations$mapReloc$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get consultHere => 'Consult about this place';
	@override String deltaTitle({required Object base}) => 'Star lines that shift here, compared with your ${base}';
	@override String linesTitle({required Object n}) => 'Points on lines (nearby ${n})';
	@override String moreLines({required Object n}) => '${n} more';
	@override String titleIntegrated({required Object coord}) => 'Integrated — ${coord}';
	@override String titleRelocate({required Object coord}) => 'Relocation layer — ${coord}';
	@override String titleTapped({required Object coord}) => 'Tapped point — ${coord}';
	@override String get getCoords => 'Copy coords';
	@override String baseToTap({required Object base}) => '${base} → tapped point';
	@override String get noChange => 'No change';
	@override String get personalPlanet => 'Personal planet';
	@override String get coordsCopied => 'Coordinates copied';
	@override String signSuffix({required Object sign}) => '${sign}';
}

// Path: mapSearch
class _Translations$mapSearch$en extends Translations$mapSearch$ja {
	_Translations$mapSearch$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String results({required Object n}) => 'Results (${n})';
	@override String get rankDistance => 'Nearby';
	@override String get rankRelevance => 'Popular';
	@override String get rankHelpTitle => 'How to narrow results';
	@override String get rankDistanceHead => '[Nearby]';
	@override String get rankDistanceBody => 'Fetches in order of nearness to the map\'s center (e.g. your current residence).\nEven lesser-known places rank high if they\'re nearby.';
	@override String get rankRelevanceHead => '[Popular]';
	@override String get rankRelevanceBody => 'Prioritizes places well-known on Google.\nWell-known candidates rank high even if somewhat far.';
	@override String get rankNote => '* This isn\'t a re-sort — the candidates fetched themselves change.';
	@override String bearing({required Object dir}) => '${dir}';
	@override String get categoryBreakdown => 'Category breakdown';
	@override String get saveViewpoint => '📍 Save as VIEWPOINT';
	@override String get savedViewpoint => '✓ Saved as VIEWPOINT';
	@override String get saveLocation => '🏠 Save as LOCATION';
	@override String get savedLocation => '✓ Saved as LOCATION';
	@override String get moveHere => '✈ Move here';
	@override String get openGoogleMaps => '🗺 View on Google Maps';
	@override String get consultStella => '✦ Consult Stella';
	@override String get googleMapsFailed => 'Couldn\'t open Google Maps';
}

// Path: mapDir
class _Translations$mapDir$en extends Translations$mapDir$ja {
	_Translations$mapDir$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get mainContrib => 'Main contributing aspects';
	@override String get twoEnergies => 'About the two energies';
	@override String get guidanceBoth => 'Both energies are present in this direction at once.\nA place of deep experience where both flow and friction take effect.\nWhich to ride, or to observe both — the choice is yours.';
	@override String get guidanceSoft => 'Soft energy is dominant in this direction.\nA place where it\'s easy to ride the flow.\nWhether to move receptively or to consciously choose your direction is up to you.';
	@override String get guidanceHard => 'Hard energy is dominant in this direction.\nA place of friction and transformation.\nWhether to look again, to confront, or to keep your distance is your choice.';
	@override String get guidanceQuiet => 'Both energies in this direction are quiet right now.\nA time when special effects are hard to feel.\nA place to stay natural, without forcing meaning onto it.';
}

// Path: aiReport
class _Translations$aiReport$en extends Translations$aiReport$ja {
	_Translations$aiReport$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get reportLink => 'Report inappropriate content';
	@override String get sheetTitle => 'Report AI output';
	@override String get sheetIntro => 'Tell us what was wrong. We\'ll review it and use it to improve the AI\'s quality.';
	@override String get detailHint => 'Details (optional, up to 500 characters)';
	@override String get submit => 'Submit';
	@override String get cancel => 'Cancel';
	@override String get thanks => 'Thank you for your report. We\'ll review it.';
	@override String get sendFailed => 'Sending failed. Please try again where you have a good signal.';
	@override late final _Translations$aiReport$reasons$en reasons = _Translations$aiReport$reasons$en._(_root);
}

// Path: mapScreen
class _Translations$mapScreen$en extends Translations$mapScreen$ja {
	_Translations$mapScreen$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get vpOffscreen => 'VIEWPOINT is off-screen. Zoom out, or check the 16-direction status from the score bar at the top-left.';
	@override String get geoServiceOff => 'Location services are OFF on your device. Please turn them on in Settings.';
	@override String get geoDeniedForever => 'Location access is permanently denied. Please allow it from the Settings app.';
	@override String get geoDenied => 'Location access was denied.';
	@override String get geoGetting => 'Getting your current location…';
	@override String geoFailed({required Object e}) => 'Couldn\'t get your current location: ${e}';
	@override String coordsCopied({required Object coords}) => 'Coordinates copied: ${coords}';
	@override String get searching => 'Searching…';
	@override String get calculating => 'Calculating…';
	@override String get tappedPoint => 'Tapped point';
	@override String get proBandLabel => 'Zenith / Nadir bands';
	@override String get proAspectLabel => 'Aspect lines (120)';
	@override String get proRelocateLabel => 'Relocation simulation';
	@override String get proAcgLabel => 'Advanced ACG';
	@override String get proBandDesc => 'A Lewis-style display showing, as bands, the latitudes where a planet passes directly overhead (zenith) or underfoot (nadir). You can read career and home themes by "latitude".';
	@override String get proAspectDesc => 'In addition to the 40 conjunction lines, shows all 120 aspect lines including squares, trines, and sextiles.';
	@override String get proRelocateDesc => 'Treats the tapped point on the map as a relocation destination, recalculating ASC / MC / the 12 houses and comparing them side by side with your current residence.';
	@override String get proAcgDesc => 'A feature unlocked with Cosmic Pro.';
	@override String get creditBannerTitle => '✦ Register your birth details and current residence to get 3 free credits';
	@override String get creditBannerSub => 'Set them up in SANCTUARY to also see the direction scores for each place';
	@override String get setupCta => 'Set up →';
	@override String get vpHelpTitle => 'Choosing your VIEWPOINT (the 16-direction reference point)';
	@override String get vpHelpIntro => 'Tapping a chip switches the reference point (VP) for the 16-direction score\nto that place. The map view doesn\'t move.\nIf you search without entering a place name, candidates are returned from\naround the map\'s center (the VP is a separate axis).';
	@override String get vpHelpGpsHead => '[📍 Current location]';
	@override String get vpHelpGpsBody => 'For when you want to see "which way to head, right now".\nUses GPS to get your current location and makes that spot the viewpoint.\nFor "the directions here and now" while moving or traveling.';
	@override String get vpHelpHomeHead => '[🏠 Home / saved VP]';
	@override String get vpHelpHomeBody => 'Using your own base (home, school, workplace, etc.) as the viewpoint.\nYou can read it as "what energy this searched place receives\nas seen from my home, school, or workplace".';
	@override String get vpHelpChoiceHead => 'Which to choose is up to you';
	@override String get vpHelpChoiceBody => 'In astrology, "where to place the viewpoint" changes with the theme you want\nto see. For everyday guidance, home; for a decision in the moment of action,\nyour current location; for a place to put down roots while traveling, that land.\nUsing them by purpose, the "meaning of direction" comes into fuller relief.';
	@override String get vpHelpOffscreenHead => 'When the VP goes off-screen';
	@override String get vpHelpOffscreenBody => 'When the searched place and the VP are far apart, the 16-direction fan\ngoes off-screen and can\'t be seen. Zoom out, or tap the score bar (band)\nat the top-left, and you can check today\'s direction status even off-screen.';
	@override List<String> get vpSlotDefaults => [
		'Workplace',
		'Favorite',
		'Spot',
		'Place',
	];
	@override List<String> get locSlotDefaults => [
		'Place 1',
		'Place 2',
		'Place 3',
		'Place 4',
	];
}

// Path: homeEdit
class _Translations$homeEdit$en extends Translations$homeEdit$ja {
	_Translations$homeEdit$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get addressLabel => 'Address / place name';
	@override String get placeHint => 'e.g. Dallas, Texas';
	@override String get notFound => 'No results found';
	@override String get connError => 'Connection error';
}

// Path: resetPicker
class _Translations$resetPicker$en extends Translations$resetPicker$ja {
	_Translations$resetPicker$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => '✦ Start of day';
	@override String get subtitle => 'Tarot\'s "once a day" and the moon rituals (new moon, full moon, catasterism) roll over to a new day when this time passes.\n(Star readings switch at midnight.)';
	@override String get unitHour => 'h';
	@override String get unitMinute => 'm';
	@override String get cancel => 'Cancel';
	@override String get confirm => 'Done';
}

// Path: orbOverlay
class _Translations$orbOverlay$en extends Translations$orbOverlay$ja {
	_Translations$orbOverlay$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get reset => 'Reset';
	@override String get scopeNote => 'This setting applies to aspect and pattern detection on the Horoscope screen. It does not affect the Map\'s direction scores or Daily Transit.';
}

// Path: legalMenu
class _Translations$legalMenu$en extends Translations$legalMenu$ja {
	_Translations$legalMenu$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get heading => '✦ Legal';
	@override String get eula => 'Terms of Service (EULA)';
	@override String openFailed({required Object url}) => 'Couldn\'t open the link: ${url}';
}

// Path: account
class _Translations$account$en extends Translations$account$ja {
	_Translations$account$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get signInBenefit => 'Sign in to carry Pro across devices';
	@override String get signInBenefitSub => 'Keep Cosmic Pro even when you change or add devices. Your records stay on this device even without signing in.';
	@override String get signInApple => ' Sign in with Apple';
	@override String get signInGoogle => 'Sign in with Google';
	@override String signedInWith({required Object provider}) => 'Signed in with ${provider}';
	@override String get signOut => 'Sign out';
	@override String get deleting => 'Deleting…';
	@override String get deleteAccount => 'Delete account from Solara';
	@override String signInFailed({required Object e}) => 'Sign-in failed: ${e}';
	@override String get signedOut => 'Signed out';
	@override String get deleteTitle => 'Delete your account?';
	@override String get deleteBody => 'This deletes your sign-in info and the subscription records on our server.\n\n· For Apple sign-in, you\'ll be asked to sign in with Apple again to confirm deletion (to fully revoke the link).\n· If you have a paid plan, please cancel it separately from the App Store / Google Play (deletion does not auto-cancel).\n· Your on-device records (consultation history, titles, Galaxy) stay on this device.\n· This action can\'t be undone.';
	@override String get cancel => 'Cancel';
	@override String get deleteConfirm => 'Delete';
	@override String get deleted => 'Your account has been deleted.';
	@override String deleteFailed({required Object e}) => 'Deletion failed: ${e}';
}

// Path: shareCard
class _Translations$shareCard$en extends Translations$shareCard$ja {
	_Translations$shareCard$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get appBar => 'Share your title';
	@override String get noClassData => 'No class data';
	@override String shareText({required Object title, required Object cls}) => 'My title is "${title}" — ${cls}\n#Solara';
	@override String shareFailed({required Object e}) => 'Share failed: ${e}';
}

// Path: titleHow
class _Translations$titleHow$en extends Translations$titleHow$ja {
	_Translations$titleHow$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => '✦ How titles work';
	@override String get s1Title => 'Birth date → Epithet';
	@override String get s1Body => 'From the combination of your Sun sign × Moon sign, one of 144 "epithets" is set.\nThis one is uniquely yours — the diagnosis never changes it.';
	@override String get s2Title => '28 questions → 5-axis score';
	@override String get s2Body => 'As you answer the PART 1 (everyday) and PART 2 (destiny) questions by choosing cards on intuition, points are added to five axes (Power, Mind, Spirit, Shadow, Heart).\nYour highest-scoring axis becomes your "temperament".';
	@override String get s3Title => 'PART 3 → Court (role)';
	@override String get s3Body => 'Across the 4 court-card questions, whichever of page, knight, queen, king you pick two or more times becomes your court. If they\'re scattered, it becomes "mixed".';
	@override String get s4Title => 'Axis × Court → 25 classes';
	@override String get s4Body => '5 axes × 5 courts = 25 kinds of class (Knight, Sage, Astrologer, Ninja…), from which the one class that fits you is chosen.';
	@override String get s5Title => 'Light side / Shadow side';
	@override String get s5Body => 'Tap the result screen to flip between the front (Light) and back (Shadow).\nLight is your strengths; Shadow is a humor-tinged "oh, that\'s so me".';
	@override String get s6Title => 'Tiebreak — astrological seed';
	@override String get s6Body => 'When axes or courts tie, one is chosen from your Sun sign × Moon sign (144 combinations).\nThe real lead is the cards you chose — pick different cards and you get a different result.\nThe astrological seed only plays "the final tiebreaker for when the judge is stuck".';
	@override String get footer => '* You can take the diagnosis again anytime. Temperament moves with the mood of the day — enjoy it as a mirror reflecting "the you of now".';
}

// Path: titleHist
class _Translations$titleHist$en extends Translations$titleHist$ja {
	_Translations$titleHist$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get clearTitle => 'Delete all history?';
	@override String get clearBody => 'Your saved title (class) history will be erased. This can\'t be undone.\nYour current title stays in the Sanctuary.';
	@override String get cancel => 'Cancel';
	@override String get delete => 'Delete';
	@override String get guideTitle => 'What "Title history" is';
	@override String get guideIntro => 'Here, the changes in the "title (class)" you diagnosed in the Sanctuary are recorded, newest first.';
	@override String get guideClassEpithetHead => '[Title (class) and epithet]';
	@override String get guideClassEpithet => '· Epithet … the name drawn from your Sun sign × Moon sign that stays with you for life.\n· Title (class) … "the you of now", shaped by your answers. It changes through re-diagnosis as your inner life and circumstances shift.';
	@override String get guideRediagnoseHead => '[About re-diagnosis]';
	@override String get guideRediagnose => 'You can retake it from "Retake the diagnosis" in the Sanctuary.\n· Free … up to once\n· Cosmic Pro … as many times as you like (even daily)\nRetake it at moments of change, and your history stacks up here so you can trace the path of your growth.';
	@override String get guideStanceHead => '[Solara\'s stance]';
	@override String get guideStance => 'We never weaken a past title as "you used to be…". Every title stands equally, as the you of that moment.';
	@override String get emptyTitle => 'No title history yet';
	@override String get emptyBody => 'Each time you retake the diagnosis in the Sanctuary,\nyour past classes will remain here.';
	@override String get noteHint => 'Leave a note for yourself about the situation or feelings when your title changed';
}

// Path: profileEdit
class _Translations$profileEdit$en extends Translations$profileEdit$ja {
	_Translations$profileEdit$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => '✦ Birth details';
	@override String get nickname => 'Nickname';
	@override String get nicknameHint => 'Enter a nickname';
	@override String get birthDate => 'Date of birth';
	@override String get birthDateRequired => 'Please enter your date of birth';
	@override String get birthTime => 'Birth time';
	@override String get hourHint => 'Hour';
	@override String get minuteHint => 'Min';
	@override String hourItem({required Object h}) => '${h}';
	@override String minuteItem({required Object m}) => '${m}';
	@override String get timeUnknown => 'I don\'t know my birth time';
	@override String get timeUnknownNote => 'The reading uses planetary positions and aspects. House, ASC and MC readings are omitted.';
	@override String get birthPlace => 'Birthplace';
	@override String get cityLevelHint => 'City/town level is fine — no street address needed';
	@override String get placeHint => 'e.g. Dallas, Texas';
	@override String get placeRequired => 'Please enter your birthplace';
	@override String get search => 'Search';
	@override String get latitude => 'Latitude';
	@override String get longitude => 'Longitude';
	@override String get tzResolving => 'Resolving timezone…';
	@override String tzAuto({required Object tz}) => 'Timezone: ${tz} (DST auto)';
	@override String tzFixed({required Object tz}) => 'Timezone: UTC+${tz} (fixed)';
	@override String get language => 'Language';
	@override String get langDevice => 'Device';
	@override String get langDeviceSub => 'System default';
	@override String get langEnglishSub => 'English';
	@override String get save => 'Save';
}

// Path: titleDiag
class _Translations$titleDiag$en extends Translations$titleDiag$ja {
	_Translations$titleDiag$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get ceremonyDash => '— The Title Ceremony —';
	@override String get ceremony => 'The Title Ceremony';
	@override String get introBody => 'The cards reflect who you are.\nAnswer the 28 questions with your intuition.';
	@override String get begin => 'Begin';
	@override String get later => 'Later';
	@override String get forging1 => 'Reading your stars…';
	@override String get forging2 => 'Weaving your destiny…';
	@override String get forging3 => 'Engraving your title…';
	@override String get goWithThis => 'Go with this';
	@override String get compareWithPrevious => '✦ Compare with your previous class';
	@override String get prevReturnTitle => '✦ Return to your previous class?';
	@override String get adoptPrevious => '✦ Keep the previous class';
	@override String get keepNew => 'Keep the new class';
}

// Path: sanctuary
class _Translations$sanctuary$en extends Translations$sanctuary$ja {
	_Translations$sanctuary$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String creditPro({required Object remaining, required Object limit, required Object pur}) => '✦ Pro ${remaining} / ${limit} ・ Purchased ${pur} (refills Monday)';
	@override String creditProSyncing({required Object pur}) => '✦ Pro balance syncing ・ Purchased ${pur}';
	@override String creditFree({required Object free, required Object pur}) => '✦ Credits ─ Free ${free} ・ Purchased ${pur}';
	@override String get set => 'Set ›';
	@override String get unset => 'Not set ›';
	@override String get birthInfo => 'Birth details';
	@override String get home => 'Home (current residence)';
	@override String get receiveTitle => '✦ Receive your title';
	@override String get shareTitleCard => '✦ Share your title card';
	@override String get rediagnose => 'Retake the diagnosis';
	@override String get rediagnoseProOnly => 'Retaking is Cosmic Pro only';
	@override String get needProfile => 'Please set your birth details first';
	@override String get rediagnoseProFeature => 'Retaking your class';
	@override String get rediagnoseProDesc => 'The "you of now" keeps changing.\nWith Cosmic Pro you can retake the diagnosis any time,\nand line up your past classes side by side in the history gallery.';
	@override late final _Translations$sanctuary$guide$en guide = _Translations$sanctuary$guide$en._(_root);
	@override String get consultHistory => 'Consultation history';
	@override String get titleHistory => 'Title history';
	@override String get proPerks1 => 'All tarot categories · Deeper star readings · Map relocation & 120 lines';
	@override String get proPerks2 => 'Time-specific outings · Unlimited title retakes · 5-year Forecast, and more';
	@override String get proPaywallNote => 'See plans and pricing on the paywall · Cancel anytime';
	@override String get proActive => 'Cosmic Pro active';
	@override String get proActiveDesc => 'All features are unlocked.';
	@override String get plansTerms => 'Plans & terms';
	@override String get restoreNotFound => 'No purchases to restore were found.';
	@override String get restoreDone => 'Your purchases have been restored.';
	@override String restoreError({required Object e}) => 'An error occurred while restoring: ${e}';
	@override String get orbSetting => 'Horoscope orbs';
	@override String get orbStandard => 'Standard ›';
	@override String get orbCustom => 'Custom ›';
	@override String get dayStart => 'Start of day';
	@override String get notifyNeedPermission => 'Please allow notifications in your device settings';
}

// Path: mapDaily
class _Translations$mapDaily$en extends Translations$mapDaily$ja {
	_Translations$mapDaily$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get birthplace => 'Birthplace';
	@override String get worldScale => 'See on a world scale';
	@override String get consultStella => 'Consult Stella';
	@override String get consultStellaSub => 'Read places from the planets';
	@override String get tabToday => 'Today';
	@override String get tabTomorrow => 'Tomorrow';
	@override String get allCategories => 'All categories';
	@override String todayTop({required Object label}) => 'Today\'s TOP — ${label}';
	@override late final _Translations$mapDaily$tagline$en tagline = _Translations$mapDaily$tagline$en._(_root);
	@override String get subLabelOuter => 'Outward phase';
	@override String get subLabelInner => 'Inward phase';
	@override String get subLabelMixed => 'Outward + inward phases mixed';
	@override String get recommendedActions => 'Example actions (for reference)';
	@override String get otherActionsNote => '* Feel free to think up other actions too, using these as a guide';
	@override String get loading => 'Reading the planets\' motion';
	@override String get failed => 'Couldn\'t fetch the data';
	@override String get retry => 'Try again';
	@override String get quietDay => 'A quiet day.\nNo special movement is visible.';
	@override String get noFilterMatch => 'No events match this filter.\nPlease change the filter.';
	@override String get viewOnMap => 'See this time on the Map';
	@override String transitPass({required Object planet, required Object angle}) => '${planet} passing ${angle}';
	@override String transitTitle({required Object planet, required Object angle}) => '${planet} passing ${angle}';
	@override late final _Translations$mapDaily$angle$en angle = _Translations$mapDaily$angle$en._(_root);
	@override late final _Translations$mapDaily$angleHint$en angleHint = _Translations$mapDaily$angleHint$en._(_root);
	@override String get zenithBias => '★ Near zenith';
	@override String get nadirBias => '★ Near nadir';
	@override String latitudeBand({required Object lat, required Object orb}) => 'Your latitude band now (lat ${lat}°, orb ±${orb}°)';
	@override String get zenithBand => 'Zenith band';
	@override String get nadirBand => 'Nadir band';
	@override late final _Translations$mapDaily$usage$en usage = _Translations$mapDaily$usage$en._(_root);
}

// Path: mapFortune
class _Translations$mapFortune$en extends Translations$mapFortune$ja {
	_Translations$mapFortune$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$mapFortune$srcShort$en srcShort = _Translations$mapFortune$srcShort$en._(_root);
	@override late final _Translations$mapFortune$srcFull$en srcFull = _Translations$mapFortune$srcFull$en._(_root);
	@override String header({required Object src, required Object cat}) => '${src} / ${cat}';
	@override String get legendTSoft => 'T-soft';
	@override String get legendTHard => 'T-hard';
	@override String get legendPSoft => 'P-soft';
	@override String get legendPHard => 'P-hard';
	@override late final _Translations$mapFortune$catMeta$en catMeta = _Translations$mapFortune$catMeta$en._(_root);
	@override late final _Translations$mapFortune$usage$en usage = _Translations$mapFortune$usage$en._(_root);
	@override late final _Translations$mapFortune$catPlanets$en catPlanets = _Translations$mapFortune$catPlanets$en._(_root);
}

// Path: galaxy
class _Translations$galaxy$en extends Translations$galaxy$ja {
	_Translations$galaxy$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String todayMoon({required Object name}) => 'Today\'s moon: ${name}';
	@override late final _Translations$galaxy$phaseDesc$en phaseDesc = _Translations$galaxy$phaseDesc$en._(_root);
	@override late final _Translations$galaxy$events$en events = _Translations$galaxy$events$en._(_root);
	@override late final _Translations$galaxy$guide$en guide = _Translations$galaxy$guide$en._(_root);
}

// Path: forecast
class _Translations$forecast$en extends Translations$forecast$ja {
	_Translations$forecast$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get error => 'Couldn\'t fetch the forecast. Please check your network connection.';
	@override String get pro5yrLabel => 'The 5-year flow';
	@override String get pro5yrDesc => 'A 5-year heatmap — this year plus the years ahead — to take in the larger flow of your life.';
	@override String daysCount({required Object n}) => '(${n} days)';
	@override String get calculating => 'Calculating the planets\' motion…';
	@override String get noData => 'No data';
	@override String get displayPeriod => 'Period';
	@override String get yearBest => 'Best of the year';
	@override List<String> get yearLabels => [
		'This year',
		'Next year',
		'In 2 years',
		'In 3 years',
		'In 4 years',
	];
	@override String plusYears({required Object n}) => '+${n} yrs';
	@override String monthRange({required Object fy, required Object fm, required Object ly, required Object lm}) => '${fy}/${fm} – ${ly}/${lm}';
	@override String get heatmap1yr => '1-year heatmap';
	@override String get segRelative => 'Relative';
	@override String get segAbsolute => 'Absolute';
	@override String get segCategory => 'Category';
	@override String get highGreen => '🟢↑high';
	@override String get highRed => '🔴↑high';
	@override String rankNth({required Object n}) => '#${n}';
	@override String get metricOverall => 'Overall';
	@override String get metricTopDir => 'Rising direction';
	@override String get metricDirScore => 'Direction score';
	@override String get categoryBy => 'By category';
	@override String lastFetch({required Object ts}) => 'Last fetched: ${ts}  /  monthly incremental updates';
	@override late final _Translations$forecast$legend$en legend = _Translations$forecast$legend$en._(_root);
	@override late final _Translations$forecast$usage$en usage = _Translations$forecast$usage$en._(_root);
	@override late final _Translations$forecast$heatmapInfo$en heatmapInfo = _Translations$forecast$heatmapInfo$en._(_root);
	@override late final _Translations$forecast$cycles$en cycles = _Translations$forecast$cycles$en._(_root);
	@override late final _Translations$forecast$top5$en top5 = _Translations$forecast$top5$en._(_root);
}

// Path: consultHistory
class _Translations$consultHistory$en extends Translations$consultHistory$ja {
	_Translations$consultHistory$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Consultation history';
	@override String get deleteAll => 'Delete all';
	@override String get deleteAllTitle => 'Delete everything?';
	@override String get deleteAllBody => 'All of your saved consultation records will be erased. This can\'t be undone.';
	@override String get delete => 'Delete';
	@override String get deleteOneTitle => 'Delete this record?';
	@override String get filterAll => 'All';
	@override String get filterFav => '★ Favorites';
	@override String get emptyAll => 'No consultation history yet';
	@override String get emptyFav => 'No favorites yet';
	@override String get emptyAllHint => 'Tap a place on the Map, or start a consultation from Daily Transit, and it\'ll be saved here.';
	@override String get emptyFavHint => 'Tap the ☆ on a record and it gathers here.';
	@override String withWhomPrefix({required Object name}) => 'With: ${name}';
	@override String get undecidedShort => 'Undecided';
	@override String get modeDaily => 'Outing / Event';
	@override String get fav => 'Add to favorites';
	@override String get unfav => 'Remove from favorites';
}

// Path: consultCredit
class _Translations$consultCredit$en extends Translations$consultCredit$ja {
	_Translations$consultCredit$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get signinTitle => 'Sign-in required';
	@override String signinBody({required Object provider}) => 'Buying credits requires signing in with ${provider}.\n\nOnce you sign in, your balance carries over even after you change or reinstall on a new device. The free features work without signing in.';
	@override String signinCta({required Object provider}) => 'Sign in with ${provider}';
	@override String get signinFailed => 'Sign-in failed';
	@override String get buyFailed => 'The purchase didn\'t go through. Please try again in a little while.';
	@override String get heading => 'Stella consultation credits';
	@override String balanceFree({required Object n}) => 'Free consultations this week: ${n} left';
	@override String balancePaid({required Object n}) => ' · ${n} purchased left';
	@override String get proUnlimited => '✦ Cosmic Pro makes it unlimited →';
	@override String get preparing => 'Credits aren\'t on sale just yet.\nPlease check back a little later.';
	@override String get fallbackProduct => 'Credits';
}

// Path: consultPlacePicker
class _Translations$consultPlacePicker$en extends Translations$consultPlacePicker$ja {
	_Translations$consultPlacePicker$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get prompt => 'Tap or search to choose a place';
	@override String get loading => 'Loading…';
	@override String get selectedPoint => 'Selected point';
	@override String coordName({required Object lat, required Object lng}) => 'Selected point (${lat}°, ${lng}°)';
	@override String get consultHere => 'Consult about this place';
}

// Path: consultResult
class _Translations$consultResult$en extends Translations$consultResult$ja {
	_Translations$consultResult$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Consultation result';
	@override String get back => 'Back';
	@override String get shareTooltip => 'Share';
	@override String get connError => 'We couldn\'t reach the connection just now. You can try again.';
	@override String get kindDirection => 'Direction';
	@override String get kindPlace => 'Place';
	@override String get noReading => '(no reading)';
	@override String get viewOnMap => 'View on the map';
	@override String distanceFromHome({required Object dir, required Object dist}) => '${dir} ~${dist} km';
	@override String get loading => 'Stella is reading the stars…';
	@override String get retry => 'Try again';
	@override String get voiceUnavailable => 'Stella\'s voice didn\'t reach you just now';
	@override String get aboutReading => 'About this reading';
	@override String get factorsTitle => 'The astrological factors of this place';
	@override String kmFactor({required Object factor, required Object km}) => '  ${factor}: ~${km} km';
	@override String get distanceNote => 'Distance doesn\'t decide whether an energy is present. The planets are immensely far away; a few hundred kilometers on the ground only change whether you\'re within range.';
	@override String nearbyCount({required Object n}) => ' (about ${n} nearby)';
	@override String sparseHint({required Object countText}) => 'There are few candidate places near here${countText}. Widening the radius or changing the direction makes them easier to find.';
	@override late final _Translations$consultResult$exhaust$en exhaust = _Translations$consultResult$exhaust$en._(_root);
	@override late final _Translations$consultResult$suggest$en suggest = _Translations$consultResult$suggest$en._(_root);
	@override String get refreshLoading => 'Looking for another place…';
	@override String get refresh => 'See another candidate place';
	@override late final _Translations$consultResult$delta$en delta = _Translations$consultResult$delta$en._(_root);
	@override String get interpNote => 'The grounds for this candidate — its evidence — are shown at the top, under "Consultation result." Stella is sharing one way of reading them. If something feels off, lay your own interpretation alongside it. What you see here is one of many possible readings.';
	@override String get deltaInterpNote => 'Stella shows this shift 30 minutes later as one interpretation, with the line movements above as its evidence. If anything feels off, widen the reading with your own sense of it. What you see here is no more than one interpretation among many.';
	@override late final _Translations$consultResult$pro$en pro = _Translations$consultResult$pro$en._(_root);
	@override late final _Translations$consultResult$block$en block = _Translations$consultResult$block$en._(_root);
	@override late final _Translations$consultResult$shareSheet$en shareSheet = _Translations$consultResult$shareSheet$en._(_root);
	@override String get returnChip => 'Back to consultation result';
}

// Path: consultStart
class _Translations$consultStart$en extends Translations$consultStart$ja {
	_Translations$consultStart$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get useProWeekly => 'Use a Pro weekly credit';
	@override String get usePaid => 'Use a paid credit';
	@override String get useCredit => 'Use a credit';
	@override String get useFree => 'Use a free credit';
	@override String get proWeeklyLabel => 'Pro weekly credit';
	@override String get freeLabel => 'Free credit';
	@override String remaining({required Object n, required Object limit}) => '${n} / ${limit} left';
	@override String get checkingRemaining => 'Checking how many are left…';
	@override String get refillProMonday => 'Refills every Monday (Cosmic Pro active)';
	@override String get refillMonday => 'Refills every Monday';
	@override String get paidLabel => 'Paid credit';
	@override String paidRemaining({required Object n}) => '${n} left';
	@override String get neverExpires => 'Never expires (purchased credits stay even if you switch devices)';
	@override String get dontShowAgain => 'Don\'t show this again';
	@override String get buyCredits => 'Buy credits';
	@override String get start => 'Start the consultation';
}

// Path: consultInput
class _Translations$consultInput$en extends Translations$consultInput$ja {
	_Translations$consultInput$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get screenTitle => 'Stella Consultation';
	@override late final _Translations$consultInput$section$en section = _Translations$consultInput$section$en._(_root);
	@override late final _Translations$consultInput$proTimePick$en proTimePick = _Translations$consultInput$proTimePick$en._(_root);
	@override String get whomHint => 'e.g. with my wife / on my own / with someone I like';
	@override String get wishHint => 'The feeling you most want to hold onto right now, in a few words';
	@override late final _Translations$consultInput$whomExamples$en whomExamples = _Translations$consultInput$whomExamples$en._(_root);
	@override late final _Translations$consultInput$wishExamples$en wishExamples = _Translations$consultInput$wishExamples$en._(_root);
	@override late final _Translations$consultInput$picker$en picker = _Translations$consultInput$picker$en._(_root);
	@override late final _Translations$consultInput$theme$en theme = _Translations$consultInput$theme$en._(_root);
	@override late final _Translations$consultInput$mode$en mode = _Translations$consultInput$mode$en._(_root);
	@override late final _Translations$consultInput$scope$en scope = _Translations$consultInput$scope$en._(_root);
	@override late final _Translations$consultInput$when$en when = _Translations$consultInput$when$en._(_root);
	@override late final _Translations$consultInput$timeBand$en timeBand = _Translations$consultInput$timeBand$en._(_root);
	@override late final _Translations$consultInput$hourPicker$en hourPicker = _Translations$consultInput$hourPicker$en._(_root);
	@override String timeRowSelected({required Object time}) => '${time} selected (you can see the changes 30 minutes later)';
	@override String radiusBand({required Object min, required Object max}) => '${min}–${max} km';
	@override String radiusSingle({required Object km}) => '${km} km';
	@override String get submit => 'Start consultation';
	@override String get noHomeNote => 'No current residence is set. "Direction," "Radius from home," and "Within my country" become available once you set your current residence. "Specific place" works right now.';
	@override String presetCard({required Object name}) => 'Looking at ${name}';
	@override String get introNote => 'Choose when, where, and what you\'ll do, and Stella reads — clearly — what kind of energy works at that time and place, from a vast body of astrological data.';
	@override late final _Translations$consultInput$about$en about = _Translations$consultInput$about$en._(_root);
}

// Path: mapAcg
class _Translations$mapAcg$en extends Translations$mapAcg$ja {
	_Translations$mapAcg$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get pillRelocate => 'Relocate';
	@override String get pillAspect => 'Aspect';
	@override late final _Translations$mapAcg$sub$en sub = _Translations$mapAcg$sub$en._(_root);
	@override late final _Translations$mapAcg$frameLabel$en frameLabel = _Translations$mapAcg$frameLabel$en._(_root);
	@override String get consultHere => 'Consult about this place';
	@override late final _Translations$mapAcg$guide$en guide = _Translations$mapAcg$guide$en._(_root);
}

// Path: mapVp
class _Translations$mapVp$en extends Translations$mapVp$ja {
	_Translations$mapVp$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override List<String> get slotDefaults => [
		'Workplace',
		'Favorite',
		'Spot',
		'Place',
	];
	@override String get slotFallback => 'Spot';
	@override String saveLimitFree({required Object free, required Object pro}) => 'You can save up to ${free} places.\nWith Cosmic Pro, you can save up to ${pro}.';
	@override String saveLimitFull({required Object max}) => 'You can save up to ${max} places.\nPlease delete a place you no longer need before adding another.';
	@override String get savedSlots => 'Saved slots';
	@override String get registeredPlaces => 'Registered places';
	@override String get noSlots => '(no slots)';
	@override String get moveToCurrent => 'Go to current location';
	@override String get saveThisPoint => 'Save this point';
	@override String get registerThisPoint => 'Register this point';
	@override String get subMoveUp => 'Move up';
	@override String get subMoveDown => 'Move down';
	@override String get subChangeIcon => 'Change icon';
	@override String get subRename => 'Rename';
	@override String get subDelete => 'Delete';
	@override String get iconPickerTitle => 'Choose an icon';
	@override late final _Translations$mapVp$help$en help = _Translations$mapVp$help$en._(_root);
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
	@override String get currentAddress => 'Current residence';
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
	@override String signinBody({required Object provider}) => 'Signing in with ${provider} is required to use Cosmic Pro.\n\nOnce you sign in, your purchases carry over even after changing or reinstalling on a device. Free features can be used without signing in.';
	@override String get purchaseVerifyFailed => 'Your purchase completed, but entitlement verification failed. Please wait a moment and try "Restore purchases".';
	@override String purchaseError({required Object e}) => 'An error occurred during the process.\n${e}';
	@override String restoreErrorMsg({required Object e}) => 'An error occurred while restoring.\n${e}';
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

// Path: appSettings
class _Translations$appSettings$en extends Translations$appSettings$ja {
	_Translations$appSettings$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get language => 'Language';
	@override String get langTitle => 'Select language';
	@override String get fontSize => 'Text size';
	@override String get fontSizeTitle => 'Text size';
	@override String get fontStandard => 'Standard';
	@override String get fontLarge => 'Large';
	@override String get fontMax => 'Largest';
	@override String get fontCaveat => 'Larger sizes may cause text and icons to overlap or become harder to read on some screens, such as Map and Galaxy.';
}

// Path: aiConsent
class _Translations$aiConsent$en extends Translations$aiConsent$ja {
	_Translations$aiConsent$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Your Astrolabe for When & Where';
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

// Path: consultShare.mode
class _Translations$consultShare$mode$en extends Translations$consultShare$mode$ja {
	_Translations$consultShare$mode$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get migration => 'Migration';
	@override String get travel => 'Travel';
	@override String get daily => 'Outings & events';
}

// Path: consultShare.scope
class _Translations$consultShare$scope$en extends Translations$consultShare$scope$ja {
	_Translations$consultShare$scope$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get point => 'Specific place';
	@override String get bearing => 'By direction';
	@override String get radius => 'Radius from home';
	@override String get region => 'Selected area';
	@override String get country => 'Within my country';
	@override String get world => 'Worldwide';
}

// Path: aiReport.reasons
class _Translations$aiReport$reasons$en extends Translations$aiReport$reasons$ja {
	_Translations$aiReport$reasons$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$aiReport$reasons$inappropriate$en inappropriate = _Translations$aiReport$reasons$inappropriate$en._(_root);
	@override late final _Translations$aiReport$reasons$misinformation$en misinformation = _Translations$aiReport$reasons$misinformation$en._(_root);
	@override late final _Translations$aiReport$reasons$ethics$en ethics = _Translations$aiReport$reasons$ethics$en._(_root);
	@override late final _Translations$aiReport$reasons$quality$en quality = _Translations$aiReport$reasons$quality$en._(_root);
	@override late final _Translations$aiReport$reasons$hallucination$en hallucination = _Translations$aiReport$reasons$hallucination$en._(_root);
	@override late final _Translations$aiReport$reasons$uncomfortable$en uncomfortable = _Translations$aiReport$reasons$uncomfortable$en._(_root);
	@override late final _Translations$aiReport$reasons$other$en other = _Translations$aiReport$reasons$other$en._(_root);
}

// Path: sanctuary.guide
class _Translations$sanctuary$guide$en extends Translations$sanctuary$guide$ja {
	_Translations$sanctuary$guide$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => '✦ About retaking your title';
	@override String get lead => 'With Cosmic Pro, you can receive your title again as many times as you like.';
	@override String get body1 => 'That said, the "epithet" drawn from your Sun and Moon signs never changes. What changes is only the "title (class)" shaped by your answers to the questions.';
	@override String get body2 => 'Each title is deeply tied to its questions. Retake it when you feel a change within yourself or in your surroundings, and later — looking back through "Title history" — you can trace your growth and your shifts.';
	@override String get body3 => 'Of course, you\'re welcome to retake it every day. We simply mention, gently, that this too is one way to use it.';
	@override String get back => 'Back';
}

// Path: mapDaily.tagline
class _Translations$mapDaily$tagline$en extends Translations$mapDaily$tagline$ja {
	_Translations$mapDaily$tagline$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get neutral => 'Let\'s check today\'s movement';
	@override String get love => 'A day when relational energy moves on many sides';
	@override String get money => 'A day when the energy of material abundance flows';
	@override String get work => 'A day when the energy of your social role moves';
	@override String get healing => 'A day when the energy of reflection and integration flows';
	@override String get communication => 'A day when the energy of dialogue and intellect moves';
}

// Path: mapDaily.angle
class _Translations$mapDaily$angle$en extends Translations$mapDaily$angle$ja {
	_Translations$mapDaily$angle$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get asc => 'Eastern horizon (ASC)';
	@override String get mc => 'Zenith (MC)';
	@override String get dsc => 'Western horizon (DSC)';
	@override String get ic => 'Nadir (IC)';
}

// Path: mapDaily.angleHint
class _Translations$mapDaily$angleHint$en extends Translations$mapDaily$angleHint$ja {
	_Translations$mapDaily$angleHint$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String asc({required Object compass}) => 'The time it begins to rise — appearing on the ${compass} horizon';
	@override String mc({required Object compass}) => 'The time it climbs highest — its peak in the ${compass} sky';
	@override String dsc({required Object compass}) => 'The time it sets — descending to the ${compass} horizon';
	@override String get ic => 'The time it passes underground — felt as an inner movement';
}

// Path: mapDaily.usage
class _Translations$mapDaily$usage$en extends Translations$mapDaily$usage$ja {
	_Translations$mapDaily$usage$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'How to read today\'s movement';
	@override String get summary => 'On this screen, matched to the purpose you intend,\nyou can read "when to act" — guidance on timing.';
	@override String get vpTitle => '[Reference point (VIEWPOINT)]';
	@override String get vpBody => 'The dropdown on the right is the "reference point."\nYou can choose your birthplace (the point you registered as your current residence)\nor a point you registered as a VIEWPOINT.\nThis screen shows where and when the planets reach each "sky direction"\nin the sky above your chosen reference point.';
	@override String get diffTitle => '[⚠ Different from the Map screen\'s directions]';
	@override String get diffBody => '· Map screen = "surface directions" (16 directions)\n　which way along the ground you head from the reference point\n　(going to a land in the east / heading to a land in the north — geography)\n\n· This screen = "sky directions" (4 angles)\n　where a planet sits in the sky right above the reference point\n　(eastern horizon / overhead zenith / western horizon / straight below)\n\nEven the same "east" means "a land in the east" on the Map,\nand "the eastern horizon (where a planet rises)" on this screen.';
	@override String get timeTitle => '[Reading time and sky direction]';
	@override String get timeBody => 'It shows the times today when each planet passes the 4 sky directions (angles)\nin the sky above your chosen reference point:\n\n· ASC (eastern horizon) — the moment a planet rises\n· MC  (overhead = zenith) — the moment a planet passes its highest point\n· DSC (western horizon) — the moment a planet sets\n· IC  (straight below = underground) — the moment a planet is on the far side of the Earth\n\nYou can read guidance on the time to act — "when a love theme moves," "when a turning point at work comes," and so on.';
	@override String get comboTitle => '[Combining with the Map score bar]';
	@override String get comboBody => 'The strength of the energy in each surface direction\ncan be checked from the Map\'s score bar (16 directions).\nThere\'s a detailed explanation in the i button under the "Total / Overall" label.\n\nCombine the score bar (the strength of surface directions) with\nthis screen (sky direction × time), and Solara works out\nthe best "direction × time" for the future you wish for.';
}

// Path: mapFortune.srcShort
class _Translations$mapFortune$srcShort$en extends Translations$mapFortune$srcShort$ja {
	_Translations$mapFortune$srcShort$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get combined => 'Total';
	@override String get transit => 'TR';
	@override String get progressed => 'PR';
}

// Path: mapFortune.srcFull
class _Translations$mapFortune$srcFull$en extends Translations$mapFortune$srcFull$ja {
	_Translations$mapFortune$srcFull$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get combined => 'Total';
	@override String get transit => 'Transit';
	@override String get progressed => 'Progressed';
}

// Path: mapFortune.catMeta
class _Translations$mapFortune$catMeta$en extends Translations$mapFortune$catMeta$ja {
	_Translations$mapFortune$catMeta$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get healing => 'A theme of rest, recovery, and intuition';
	@override String get money => 'A theme of flourishing, joy, and self-affirmation';
	@override String get love => 'A theme of love, passion, and closeness';
	@override String get work => 'A theme of responsibility, action, and growth';
	@override String get communication => 'A theme of conveying, dialogue, and intellect';
}

// Path: mapFortune.usage
class _Translations$mapFortune$usage$en extends Translations$mapFortune$usage$ja {
	_Translations$mapFortune$usage$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'How to use the Map';
	@override String get dirTitle => '[Reading a direction]';
	@override String get dirBody => 'Centered on your reference point (VIEWPOINT), it scores and shows the energy of each of the 16 surface directions\n(N, NNE, NE, ENE, E…).\nYou can judge "which land or direction to turn your attention toward."\n\nIt isn\'t only a display of which way to go.\nGoing toward a direction is, of course, one action you can take toward it. But there\'s also turning your attention there, calling out, placing a cherished item to match the direction as you leave home, being mindful of the direction you face when you speak, which seat you take in a shop and which way you turn, the direction you take a deep breath — you are free to decide.\nThrough the action you choose, the planets\' energy will reach you.\nThe planets are always watching over you, from a vast vantage point.\n\nTap the score bar to switch category\n(Overall → Healing → Abundance → Love → Work → Talk).\nChoose the category you want, and you\'ll see which directions that energy comes through most strongly.';
	@override String get regTitle => '[Registering a reference point]';
	@override String get regPre => 'You can register a reference point from the ';
	@override String get regPost => ' (VIEWPOINT) button on the left of the map screen.\nShow the place you want at the center of the map, open the panel, and tap "Save this point" — that point is then saved as a VIEWPOINT.\n\nYou can switch between your saved reference points anytime, from the top of the search results or the dropdown inside the "Daily" chip in the bottom menu.';
	@override String get findTitle => '[Finding a place]';
	@override String get findBody => 'Search for shopping, a meeting spot, a shop, and so on from the search button, and you can check which planets that point is receiving energy from right now.';
	@override String get timeTitle => '[Reading the time]';
	@override String get timeBody => 'From the "Daily" chip in the bottom menu you can read "guidance on the time to act."\n* The "Daily" chip screen deals with "sky directions" (where and when a planet comes in the sky); it\'s separate from this Map\'s "surface directions" (which land to head toward).\n\nCombine the score bar (the strength of surface directions) with the "Daily" chip (sky direction × time), and Solara works out the best "direction × time" for the future you wish for.';
}

// Path: mapFortune.catPlanets
class _Translations$mapFortune$catPlanets$en extends Translations$mapFortune$catPlanets$ja {
	_Translations$mapFortune$catPlanets$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Categories and their planets';
	@override String get intro => 'Each category extracts the aspects of its related planet pairs and scores them per direction, with pair weighting applied.\n(How the pair weighting works is explained in detail below.)';
	@override String get weightTitle => '[How pair weighting works]';
	@override String get weightBody => 'A category\'s score extracts the aspects of its related planet pairs and sums them, weighted by each pair\'s "centrality."\n\n· Lead pair (weight 2.0)\n　The planet pair that carries the category\'s central theme.\n　e.g. Love = Venus×Mars / Work = Saturn×Sun\n　→ when the aspect appears, it counts with 2× the influence.\n\n· Sub pair (weight 0.5)\n　An aspect where only one of the planets relates to the category.\n　e.g. for Love, "Venus×Jupiter" (only Venus carries love)\n　→ counts with a modest 0.5× influence.\n\n· Outside the pair (weight 0)\n　An aspect where neither planet relates to the category.\n　→ it isn\'t reflected in that category\'s score.\n\nThis "weighting" yields a precise score that reflects the category\'s "central theme."\nA plain sum without pair weights would blur each category\'s character, so we refine it with weighted calculation.';
	@override String get overallTitle => '[How it relates to Overall]';
	@override String get overallBody => 'When "Overall" is selected on the top score bar, the number is the straight sum of all planets and all aspects.\nNo category weighting is applied (= no pair weights).\n\nThe per-category views (Healing / Abundance / Love / Work / Talk), on the other hand, apply the pair weights above.\nAnd a single aspect can be counted in more than one category\n(e.g. Venus×Jupiter → counts for both Love and Abundance).\n\nSo "the plain sum of the 5 categories ≠ Overall."\nThe two are numbers for seeing energy from different angles; neither is more correct.\n· Per-category = see the category\'s "concentration"\n· Overall = see the "total volume"';
}

// Path: galaxy.phaseDesc
class _Translations$galaxy$phaseDesc$en extends Translations$galaxy$phaseDesc$ja {
	_Translations$galaxy$phaseDesc$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get newMoon => 'A time of beginnings.\nThe sky is at its darkest, and the stars show clearest.\nA time to set a new intention and plant seeds.';
	@override String get crescent => 'A time of sprouting.\nA thin light appears in the western sky.\nA time to begin moving, little by little, toward the intention you planted at the new moon.';
	@override String get firstQuarter => 'A time to act.\nThe half-moon reaches the zenith; decision and action are called for.\nA turning point for shaping the intention that has sprouted.';
	@override String get gibbous13 => 'A time of swelling.\nThe moon\'s waxing momentum nears its peak.\nA time when things fall into place and expression grows full.';
	@override String get fullMoon => 'A time of fulfillment and release.\nThe night the moon shines brightest.\nAwareness and completion arrive.\nA time to look again at what you hold, and give thanks.';
	@override String get waningGibbous18 => 'A time of sharing.\nThe moon begins to wane.\nA time to share what you learned at the full moon with others.';
	@override String get lastQuarter => 'A time of letting go.\nA half-moon floats, turned the other way.\nA time to clear away what\'s no longer needed, and loosen your grip.';
	@override String get waning26 => 'A time of rest.\nA faint moon lingers in the sky.\nA time to quietly set yourself in order for the next cycle.';
	@override String get flowing => 'The moon\'s cycle is flowing.';
}

// Path: galaxy.events
class _Translations$galaxy$events$en extends Translations$galaxy$events$ja {
	_Translations$galaxy$events$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'About the moon events';
	@override String get intro => 'Through this cycle, in step with the moon\'s waxing and waning,\nthree turning points come to you.';
	@override String get newTitle => '🌑 New moon event';
	@override String get newBody => 'The starting point — on the new moon, you set an "intention."\nYou put into words what you want to hold dear this cycle.\nEverything begins here.';
	@override String get fullTitle => '🌕 Full moon event';
	@override String get fullBody => 'On the full moon, a midway check-in on the intention you set (a look back).\n* It won\'t appear unless you set an intention at the new moon.';
	@override String get catTitle => '✦ Catasterism event';
	@override String get catBody => 'Arriving the day before the next new moon or later — the close of the cycle.\nA letting-go, and the forming of a constellation that is yours alone.\n* This, too, assumes you set an intention at the new moon.';
	@override String get notifyTitle => '🔔 We recommend turning notifications on';
	@override String get notifyBody => 'Each event visits on "that day" only.\nTurn notifications on in Sanctuary,\nand we\'ll let you know the morning of.\n\nThe full moon and catasterism assume a new-moon intention,\nso the main thing is not to miss the new moon.';
}

// Path: galaxy.guide
class _Translations$galaxy$guide$en extends Translations$galaxy$guide$ja {
	_Translations$galaxy$guide$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'What is the Galaxy screen?';
	@override String get intro => 'In step with the moon\'s cycle (about 29.5 days),\nyour daily tarot readings\nare recorded here as "stars."\n\nOne cycle = one constellation completed.\nThe rhythm of your inner life remains, in the shape of a constellation.';
	@override String get cycleTitle => '🌌 CYCLE tab (the current cycle)';
	@override String get cycleBody => 'Shows where you are now in this moon cycle.\nThe "dots" of your daily readings line up along a spiral,\nadvancing toward completion.\n\n· Top-right number: which day of the cycle (e.g. 23 of 30)\n· Top-left moon badge: today\'s phase (← you are here)\n· Drag to rotate in 3D\n· Tap a dot to see that day\'s reading\n· On new- and full-moon days, a special overlay\n　invites you to set or look back on your intention';
	@override String get atlasTitle => '🌟 Star Atlas tab (your past constellations)';
	@override String get atlasBody => 'A collection of completed past cycles (= constellations).\nEach one is a constellation your own inner life has woven.\n\n· Each card is a constellation woven from one cycle of readings\n· Tap a card to replay it + see details\n　(name, period, rarity)\n· Rarity: a 5-level star rating (★)\n　the higher the rarity, the rarer the combination that appeared';
	@override String get meaningTitle => 'What the moon cycle means';
	@override String get meaningBody => '🌑 New moon → a beginning. A time to plant seeds.\n🌕 Full moon → fulfillment and release. A time of awareness.\n\nOver one cycle, your inner life becomes a single constellation.\nDraw your daily card on the Tarot tab,\nand let it grow, slowly.';
}

// Path: forecast.legend
class _Translations$forecast$legend$en extends Translations$forecast$legend$ja {
	_Translations$forecast$legend$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get relLowRed => 'red = year\'s low';
	@override String get relLowGreen => 'green = year\'s low';
	@override String get relHighGreen => 'green = year\'s high';
	@override String get relHighRed => 'red = year\'s high';
	@override String relRange({required Object low, required Object high, required Object min, required Object max}) => '${low}  /  ${high}  (min: ${min} → max: ${max})';
	@override String get absLowRed => 'red = 45 or below';
	@override String get absLowGreen => 'green = 45 or below';
	@override String get absHighGreen => 'green = 85 or above';
	@override String get absHighRed => 'red = 85 or above';
	@override String absScale({required Object low, required Object high}) => '${low}  /  yellow = 65  /  ${high}  (fixed scale)';
	@override String catRank({required Object rank}) => 'color = category #${rank} / depth = score level';
}

// Path: forecast.usage
class _Translations$forecast$usage$en extends Translations$forecast$usage$ja {
	_Translations$forecast$usage$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'How to use FORECAST';
	@override String get intro => 'This shows the rhythm of your stars over the year ahead (365 days).\nYou can take in each day\'s overall and per-category scores at a glance,\nand see ahead of time which days move easily and which call for care.';
	@override String get s1Title => '[1-year heatmap]';
	@override String get s1Body => 'A 12-month × 31-day grid colors each day by its score.\nChange how it reads with the mode (relative / absolute /\ncategory), the color direction (🟢 high /\n🔴 high), and the rank (#1 / #2).\nSee the i button to the right of the heatmap for more.';
	@override String get s2Title => '[Selected-day detail]';
	@override String get s2Body => 'Tap a day on the heatmap and that day\'s directional score\nand per-category ranking appear below.';
	@override String get s3Title => '[Your star cycles]';
	@override String get s3Body => 'Shows each category\'s "seasons" (a season of connection /\nabundance / healing, and so on). Only ongoing stretches that\narrive from today onward. A compass for longer-term plans.';
	@override String get s4Title => '[Highlights — Top 5]';
	@override String get s4Body => 'Shows the top 5 days per category — for pinpointing\n"when to act" in the short term.';
	@override String get s5Title => '[How this relates to the Map numbers]';
	@override String get s5Body => 'The FORECAST numbers and the numbers on the Map for the same day\nwon\'t match — they\'re different calculations.\n\n· FORECAST = computed from your birth data alone.\n　Wherever you are on Earth, whatever the hour, it doesn\'t change —\n　it traces the energy flowing through you across a whole year.\n\n· Map = computed from where you are now + this very moment.\n　Because it includes the ASC (horizon) and MC (zenith),\n　the numbers change as the place changes, and even the same day\n　reads differently at 12:00 and 19:00\n　(the ASC moves about 15°/hour).\n\nNeither is right or wrong — they\'re two lenses reading the same you\nfrom different angles.\n· Use FORECAST to catch the "times that move easily,"\n· Use the Map to read "that place, that hour" in detail.\nUse them together that way.';
}

// Path: forecast.heatmapInfo
class _Translations$forecast$heatmapInfo$en extends Translations$forecast$heatmapInfo$ja {
	_Translations$forecast$heatmapInfo$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'How to read the 1-year heatmap';
	@override String get s1Title => '[Three color modes]';
	@override String get s1Body => '■ Relative mode (default)\nNormalized from the year\'s low → high.\nThe relatively higher days among your 365 show brighter.\nIt maximizes the day-to-day contrast.\n\n■ Absolute mode\nColors by the absolute score. Low values are dark,\nhigh values are bright. Use it when comparing across\nyears or with other people.\n\n■ Category mode\nColors each day by its strongest category:\n　🟢 Healing　🟡 Abundance　🩷 Love\n　🔵 Work　🟣 Talk\n\nA stretch of the same color is a time when that category\'s\n"wave" is rolling in.\n· 🩷 in a row → a season of connection (relational energy flows)\n· 🟡 in a row → a season of abundance\n· 🟢 in a row → a season of healing\n· 🔵 in a row → a season of work\n· 🟣 in a row → a season of expression\n\nThese "seasons" are also listed with start and end dates in the\n"Your star cycles" section below\n(only stretches of 7 days or more).';
	@override String get s2Title => '[Color direction (🟢 high / 🔴 high)]';
	@override String get s2Body => 'Active in "relative" and "absolute" modes.\n· 🟢 high: high score = green, low score = red\n· 🔴 high: high score = red, low score = green (inverted)\n\nTo avoid any good/bad verdict, you choose for yourself\nwhich color direction you want to see.';
	@override String get s3Title => '[Rank (#1 / #2)]';
	@override String get s3Body => 'Active in "category" mode.\n· #1: paints with the day\'s strongest category color\n· #2: paints with the second-strongest category color\n\nChecking both reveals the "lead" and the "support"\nwithin a single day.';
	@override String get footer => '* Even for the same day, this is a different measure from the number you\'d open on the Map\n(a calculation independent of place and time).\nFor details, see "How this relates to the Map numbers" under the ❓ button at the top.';
}

// Path: forecast.cycles
class _Translations$forecast$cycles$en extends Translations$forecast$cycles$ja {
	_Translations$forecast$cycles$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Your star cycles';
	@override String get hint => 'Shows stretches arriving from today onward (7+ days running)';
	@override String get empty => 'No stretches arriving from today onward';
	@override String get infoTitle => 'What are star cycles?';
	@override String get s1Title => '[What it means]';
	@override String get s1Body => 'Over the year ahead, it shows the "stretches" where each category\'s\n(Love / Abundance / Healing /\nWork / Talk) energy flows strongly.\n\ne.g. "💗 Season of love 6/15 – 7/2 (18 days)"\n　 → from 6/15 to 7/2, relational energy\n　   runs strong without a break';
	@override String get s2Title => '[Conditions for showing]';
	@override String get s2Body => '· Only stretches arriving from today onward\n　(past stretches are hidden)\n· Counted as a "stretch" only when strong for 7+ days running\n　(short waves aren\'t shown)\n· One nearest entry per category';
	@override String get s3Title => '[How to use it]';
	@override String get s3Body => 'For longer-term "when to act" planning.\nCheck a specific day within the stretch on the Map screen,\nand you\'ll see the direction and timing at that place and hour.';
	@override String get footer => '* Even for the same stretch\'s score, this is a different measure from the number you\'d open on the Map\n(a calculation independent of place and time).\nFor details, see "How this relates to the Map numbers" under the ❓ button at the top.';
}

// Path: forecast.top5
class _Translations$forecast$top5$en extends Translations$forecast$top5$ja {
	_Translations$forecast$top5$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Highlights Top 5';
	@override String year({required Object year}) => '${year}';
	@override String get infoTitle => 'How to read Highlights — Top 5';
	@override String get s1Title => '[What it means]';
	@override String get s1Body => 'Within the year shown (1/1–12/31), it shows the 5 days\nwhere the selected category scores highest.';
	@override String get s2Title => '[Switching category]';
	@override String get s2Body => 'Choose from Overall / Love / Abundance / Healing / Work / Talk.\nThe top 5 days for the chosen category appear.';
	@override String get s3Title => '[Rank markers]';
	@override String get s3Body => '👑 #1 / 🥈 #2 / 🥉 #3 / ⭐ #4 / ✨ #5';
	@override String get s4Title => '[Reading a row]';
	@override String get s4Body => 'Date — the selected category\'s score that day.\nTap to jump to the selected-day detail.\n(That day\'s rising direction is shown in the selected-day detail.)';
	@override String get s5Title => '[How to use it]';
	@override String get s5Body => 'For short-term, pinpoint "where to move" planning.\nThe #1 day especially is a day when moving on that\ncategory\'s theme lets its energy flow strongest.';
	@override String get footer => '* Even for the same day, this is a different measure from the number you\'d open on the Map\n(a calculation independent of place and time).\nFor details, see "How this relates to the Map numbers" under the ❓ button at the top.';
}

// Path: consultResult.exhaust
class _Translations$consultResult$exhaust$en extends Translations$consultResult$exhaust$ja {
	_Translations$consultResult$exhaust$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get allQuiet => 'With these conditions, no place is strongly drawing you right now.';
	@override String get noFresh => 'No further new candidate places turned up.';
	@override String get emptyPool => 'No candidates were found within this range.';
	@override String get fallback => 'We didn\'t force any more candidates into being.';
	@override String get tipsLead => 'Changing the conditions might surface more:';
	@override String get noCredit => '* No credits were used for this notice.';
}

// Path: consultResult.suggest
class _Translations$consultResult$suggest$en extends Translations$consultResult$suggest$ja {
	_Translations$consultResult$suggest$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get widenRadius => 'Widen the radius';
	@override String get bearing => 'Search by direction';
	@override String get point => 'Pick a specific place';
	@override String get world => 'Open it up to the whole world';
}

// Path: consultResult.delta
class _Translations$consultResult$delta$en extends Translations$consultResult$delta$ja {
	_Translations$consultResult$delta$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String open({required Object m}) => 'See the change ${m} minutes later';
	@override String close({required Object m}) => 'Close the change ${m} minutes later';
	@override String get infoTitle => 'About "the change 30 minutes later"';
	@override String infoBody({required Object m}) => 'The star lines of astrocartography move moment by moment as the Earth turns.\nThe "angle lines"—where a planet sits directly overhead or on the horizon—travel about 7.5° in ${m} minutes: roughly 800 km westward at mid-latitudes.\n\nSo even in the same place, the lead of the moment can quietly change between the time you chose and ${m} minutes later. Mars\'s line drawing away, Venus\'s line drawing near—knowing that shift in advance lets you see how to use your time there: the heart of it early on, or warming toward the end.\n\nWe read this not as fortune, good or bad, but as a shift in the quality of the energy. You can see it when you set a time with Cosmic Pro · Outing.';
	@override String get approaching => 'drawing near';
	@override String get entering => 'moving in';
	@override String get receding => 'drawing away';
	@override String get leaving => 'moving out';
	@override String get steady => 'steady';
	@override String chip({required Object planet, required Object angle, required Object label}) => '${planet} ${angle} · ${label}';
}

// Path: consultResult.pro
class _Translations$consultResult$pro$en extends Translations$consultResult$pro$ja {
	_Translations$consultResult$pro$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get consultLabel => 'Stella Consultation';
	@override String get consultDesc => 'With Cosmic Pro you can read it as many times as you like.';
	@override String get migrationLabel => 'Migration & travel consultations';
	@override String get migrationDesc => 'With Cosmic Pro, consultations beyond Outing / Event are unlimited too.';
	@override String get refreshLabel => 'Drawing fresh candidates';
	@override String get refreshDesc => 'Compare as many other candidates as you like.';
	@override String get weeklyLabel => 'Stella Consultation';
	@override String get weeklyDesc => 'You\'ve used up this week\'s free consultations. With Cosmic Pro it\'s unlimited, and reads more deeply with thinking.';
}

// Path: consultResult.block
class _Translations$consultResult$block$en extends Translations$consultResult$block$ja {
	_Translations$consultResult$block$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get proOnlyModeTitle => 'This mode is part of Cosmic Pro';
	@override String get proOnlyModeBody => 'Consultations beyond Outing / Event (migration & travel) can be read with Cosmic Pro.';
	@override String get proOnlyRefreshTitle => 'Drawing fresh candidates is part of Cosmic Pro';
	@override String get proOnlyRefreshBody => 'Compare as many other candidates as you like.';
	@override String get proWeeklyTitle => 'You\'ve reached this week\'s Pro consultation limit';
	@override String get proWeeklyBody => 'Cosmic Pro lets you consult Stella up to 100 times a week. It refills on Monday. To keep going right away, you can buy extra credits.';
	@override String get proSyncTitle => 'Syncing your Pro status';
	@override String get proSyncBody => 'We\'re re-checking your Cosmic Pro billing status with the store. No credits have been used. Please wait a moment, then try again.';
	@override String get exhaustedTitle => 'You\'ve used up your consultation credits';
	@override String get exhaustedBody => 'Free Stella consultations refill each week. To keep going right away, you can buy extra credits, or go unlimited with Cosmic Pro.';
	@override String get buyCredits => 'Buy extra credits';
	@override String get goUnlimited => '✦ Go unlimited with Cosmic Pro';
	@override String get seePro => '✦ See Cosmic Pro';
}

// Path: consultResult.shareSheet
class _Translations$consultResult$shareSheet$en extends Translations$consultResult$shareSheet$ja {
	_Translations$consultResult$shareSheet$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get copyText => 'Copy as text';
	@override String get copyTextSub => 'Copy the consultation result, formatted, to the clipboard';
	@override String get shareImage => 'Share as an image';
	@override String get shareImageSub => 'Turn the result screen into a PNG and share it your usual way';
	@override String get copied => 'Copied to the clipboard';
	@override String failed({required Object e}) => 'Sharing failed: ${e}';
}

// Path: consultInput.section
class _Translations$consultInput$section$en extends Translations$consultInput$section$ja {
	_Translations$consultInput$section$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get occasion => 'What\'s the occasion?';
	@override String get when => 'When?';
	@override String get timeBand => 'Time of day (optional)';
	@override String get where => 'Where?';
	@override String get radiusDaily => 'Distance from your current residence';
	@override String get radiusBand => 'Distance band from your current residence';
	@override String get region => 'Region block';
	@override String get point => 'Pick a place';
	@override String get theme => 'Which theme shall we read?';
	@override String get whom => 'With whom? (optional)';
	@override String get wish => 'What do you hope for? / Your wish (optional)';
}

// Path: consultInput.proTimePick
class _Translations$consultInput$proTimePick$en extends Translations$consultInput$proTimePick$ja {
	_Translations$consultInput$proTimePick$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Setting the time for Outings + the 30-minute shift';
	@override String get desc => 'Set the time you\'ll go in one-hour steps, and read how the flow of the place shifts 30 minutes later. CCG lines move as the Earth turns, so even in the same place the lead of the moment changes between the first and second half.';
}

// Path: consultInput.whomExamples
class _Translations$consultInput$whomExamples$en extends Translations$consultInput$whomExamples$ja {
	_Translations$consultInput$whomExamples$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override List<String> get love => [
		'On my own',
		'With my partner',
		'With someone I like',
	];
	@override List<String> get money => [
		'On my own',
		'With family',
		'With my partner',
	];
	@override List<String> get work => [
		'On my own',
		'With a colleague',
		'With teammates',
	];
	@override List<String> get communication => [
		'With a friend',
		'With companions',
		'On my own',
	];
	@override List<String> get healing => [
		'On my own',
		'With my partner',
		'With family',
	];
	@override List<String> get newStart => [
		'On my own',
		'With my partner',
		'With family',
	];
	@override List<String> get fallback => [
		'On my own',
		'With my partner',
		'With a friend',
		'With family',
	];
}

// Path: consultInput.wishExamples
class _Translations$consultInput$wishExamples$en extends Translations$consultInput$wishExamples$ja {
	_Translations$consultInput$wishExamples$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override List<String> get love => [
		'Deepen this bond',
		'Meet someone good',
		'Connect heart to heart',
	];
	@override List<String> get money => [
		'Draw in abundance',
		'Build a foundation for work',
		'Live with stability',
	];
	@override List<String> get work => [
		'Move forward at work',
		'Take on a new challenge',
		'Find a place I can focus',
	];
	@override List<String> get communication => [
		'Widen my horizons',
		'Deepen my learning',
		'Find fresh inspiration',
	];
	@override List<String> get healing => [
		'Rest my heart',
		'Refresh my mood',
		'Spend calm time',
	];
	@override List<String> get newStart => [
		'Change the current',
		'Take a new step',
		'Begin anew',
	];
	@override List<String> get fallback => [
		'Take a step forward',
		'Change the current',
	];
}

// Path: consultInput.picker
class _Translations$consultInput$picker$en extends Translations$consultInput$picker$ja {
	_Translations$consultInput$picker$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get searchHint => 'Search by address / place name';
	@override String get clearSearch => 'Clear';
	@override String get fromViewpoint => '🔭 From your ViewPoints';
	@override String get fromLocations => '📍 From your saved Locations';
	@override String get pickOnMap => 'Pick on the map';
	@override String get clearSelection => 'Clear selection';
}

// Path: consultInput.theme
class _Translations$consultInput$theme$en extends Translations$consultInput$theme$ja {
	_Translations$consultInput$theme$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get love => 'Love & relationships';
	@override String get money => 'Abundance & money';
	@override String get work => 'Work & career';
	@override String get communication => 'Talk & learning';
	@override String get healing => 'Healing & rest';
	@override String get newStart => 'Change & new beginnings';
}

// Path: consultInput.mode
class _Translations$consultInput$mode$en extends Translations$consultInput$mode$ja {
	_Translations$consultInput$mode$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get daily => 'Outing /\nEvent';
	@override String get travel => 'Travel';
	@override String get migration => 'Migration';
}

// Path: consultInput.scope
class _Translations$consultInput$scope$en extends Translations$consultInput$scope$ja {
	_Translations$consultInput$scope$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get point => 'Specific place';
	@override String get bearing => 'Direction';
	@override String get radius => 'Radius from home';
	@override String get region => 'Region';
	@override String get country => 'Within my country';
	@override String get world => 'Worldwide';
}

// Path: consultInput.when
class _Translations$consultInput$when$en extends Translations$consultInput$when$ja {
	_Translations$consultInput$when$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get today => 'Today';
	@override String get date => 'Pick a date';
	@override String get specificDay => 'A specific day';
	@override String get range => 'Date range';
	@override String get undecided => 'Timing undecided';
	@override String get within6mo => 'Within 6 months';
	@override String get within1yr => 'Within a year';
	@override String get in3yr => 'Around 3 years';
	@override String get in5yrPlus => '5+ years ahead';
}

// Path: consultInput.timeBand
class _Translations$consultInput$timeBand$en extends Translations$consultInput$timeBand$ja {
	_Translations$consultInput$timeBand$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get morning => 'Morning';
	@override String get midday => 'Midday';
	@override String get evening => 'Evening';
	@override String get night => 'Night';
	@override String get lateNight => 'Late night';
}

// Path: consultInput.hourPicker
class _Translations$consultInput$hourPicker$en extends Translations$consultInput$hourPicker$ja {
	_Translations$consultInput$hourPicker$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Set the time (hourly)';
	@override String get sub => 'Reads the flow of the place at that time, and the change 30 minutes later';
	@override String confirm({required Object time}) => 'Set to ${time}';
}

// Path: consultInput.about
class _Translations$consultInput$about$en extends Translations$consultInput$about$ja {
	_Translations$consultInput$about$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'What is Stella Consultation?';
	@override String get intro => 'Just choose "when, where, and what you\'ll do." Solara lays a planet-scale star map over that plan and reads the energy that works on you at that time and place — it\'s the heart of Solara.\nThe vast celestial calculations an astrologer would normally take a long time to read, Stella performs in an instant, and hands to you in words that stay close to you rather than in technical jargon.';
	@override String get bullets => '• It maps "where and what you do, and what effect it draws out," in the light of your wish.\n• No good/bad verdicts, no rankings. Rather than "good/bad," it tells you what quality of flow it is — a quality that gives you a push, or one that invites you to face something.\n• Outings, travel, migration — to match the scale. With Cosmic Pro you can set the time in one-hour steps, and even read how the flow of a place shifts 30 minutes later.';
	@override String get dataTitle => 'The data Stella Consultation reads';
	@override String get dataIntro => 'Solara\'s star-line calculation is 10 planets × 4 angles (ASC · MC · DSC · IC) × 3 aspects (conjunction · square · trine / sextile) = 120 lines per frame. It layers several frames and calculates latitude bands, the 12 houses, and progressions.';
	@override String get freeHead => '— Even with Outing / Event (Free), it goes this far —';
	@override String get freeList => '• The 10 planets of the birth chart (natal) / the 10 transiting planets of today\n• Astrocartography (Astro*Carto*Graphy / the lines of your birth)\n• Cyclocartography (Cyclo*Carto*Graphy / the moving lines of this very moment)\n• All aspect lines — conjunction, square, trine, sextile (theme planets × 4 angles × 3 aspects)\n• Zenith and nadir bands (latitude energy bands)\n• Relocation for that land (the reshuffling of ASC / MC / the 12 houses + which house each theme planet falls in)\n• Inner seasons (the progressed Moon and Sun, the turning points of the solar arc) / local timing (the times planets cross the angles)\n…Stella overlays all of this across candidate points worldwide and maps the places and directions that resonate with your wish.';
	@override String get proHead => '— With Cosmic Pro, further —';
	@override String get proList => '• Migration scale = the lifelong, unchanging natal ACG + the life-chapters of progression\n• Travel scale = the moving lines for each travel day (sampling several days of the period)\n• Set the time in one-hour steps → even how the lines move 30 minutes later';
	@override String get devHead => '— From the maker of Solara —';
	@override String get devBody => 'This level of detail is possible because I — someone who has practiced astrology myself — handle everything directly, from design to development. Rather than asking someone else to "please read it this way here," an astrologer gives it form directly; so the meaning of the stars can dwell in every small detail. May this star map stay close beside your every day.';
}

// Path: mapAcg.sub
class _Translations$mapAcg$sub$en extends Translations$mapAcg$sub$ja {
	_Translations$mapAcg$sub$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get zenith => 'Zenith';
	@override String get nadir => 'Nadir';
	@override String get zenithBand => 'Zenith band';
	@override String get nadirBand => 'Nadir band';
}

// Path: mapAcg.frameLabel
class _Translations$mapAcg$frameLabel$en extends Translations$mapAcg$frameLabel$ja {
	_Translations$mapAcg$frameLabel$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get transit => 'TRANSIT — planetary positions this very moment';
	@override String get progressed => 'PROGRESSED — secondary progression (1 day = 1 year)';
	@override String get solarArc => 'SOLAR ARC — all planets shifted by the solar arc';
}

// Path: mapAcg.guide
class _Translations$mapAcg$guide$en extends Translations$mapAcg$guide$ja {
	_Translations$mapAcg$guide$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'How to use ASTRO*CARTO*GRAPHY / CYCLO*CARTO*GRAPHY';
	@override String get jimLewis => '— The celestial map upon the Earth, left to us by Jim Lewis —';
	@override String get acgHead => '[What is ACG (AstroCartoGraphy)?]';
	@override String get acgBody => 'A method systematized by the astrologer Jim Lewis in the 1970s.\nIt projects the planetary positions at your birth as "lines" on a world map,\nshowing which planet rises in which land\n(a map that never changes throughout your life).';
	@override String get ccgHead => '[What is CCG (CycloCartoGraphy)?]';
	@override String get ccgBody => 'An evolution Jim Lewis systematized in 1982 as a sequel to ACG.\nInstead of your birth moment, it projects the planetary positions of "this very moment" or a time you specify. The lines move with Earth\'s rotation,\nand the starscape rewrites itself moment by moment.\nSolara\'s Transit / Prog / S.Arc frames\ncorrespond to this CCG.';
	@override String get framesHead => '[The 4 frames (top pills, all free)]';
	@override String get framesBody => '• Natal … positions at birth (ACG, unchanging for life)\n• Transit / Prog / S.Arc … positions that move with time (CCG)\n\nThe i button beside each pill has a detailed explanation of each.';
	@override String get linesHead => '[Lines & markers on the map]';
	@override String get linesBody => 'Shows planet × angle lines and zenith / nadir markers.\nTap a line or marker to see the meaning of that point\nand a message specific to the planet.\nThe i button beside each pill (angle / zenith / nadir)\nhas a detailed explanation.';
	@override String get proHead => '[Pro features]';
	@override String get proBody => '• Aspect lines (120): adds square / trine / sextile\n　to the main lines\n• Relocate: treat the tapped point as a relocation destination and\n　compare the moving star lines, ASC/MC, and houses\n• Zenith band / Nadir band: Lewis-style band display that applies around the whole latitude\n\nAll are unlocked with Cosmic Pro.';
	@override String get usageHead => '[How to make use of it]';
	@override String get usageBody => 'For choosing destinations for travel, moving, or business trips.\nEven the same action flows with different energy depending on the land. Layer on the 16-direction scores (the directional-energy fan), and "where" and "when" rise together upon the map and the clock.';
}

// Path: mapVp.help
class _Translations$mapVp$help$en extends Translations$mapVp$help$ja {
	_Translations$mapVp$help$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'VIEWPOINT and LOCATIONS';
	@override String get vpHead => '[📍 VIEWPOINT]';
	@override String get vpBody => 'The reference point (observation point) for calculating directional scores.\nThe map draws how each planet\'s energy descends across the 16 directions as seen from here.\n\nIt\'s used in the dropdown at the top of the search-results list, and in the VIEWPOINT switcher on the Daily chip screen.';
	@override String get locHead => '[🌐 LOCATIONS]';
	@override String get locBody => 'Points shown as markers on the map\n(a list of places you visit often).\nOnce registered, the marker stays on the map,\nso you can see how places relate to each other at a glance.\n\nTapping the "LOCATIONS" tile button at the bottom\nof the Map screen lets you see, in a list,\nthe energy scores of your LOCATIONS (registered places)\nas viewed from the VIEWPOINT.\nRegister the places you visit often, and you\'ll see\nthings like "this park has a high Healing score today" or\n"this café has a high Love score today" —\na handy way to see how strong today\'s energy is\nat each registered place.';
	@override String get usageTitle => 'How to use';
	@override String get registerHead => '[Saving]';
	@override String get registerBody => 'Both VIEWPOINT and LOCATIONS can hold up to 5 entries each\n(including your home 🏠).\nYour home is placed in the first slot automatically from your profile,\nso you can add up to 4 more.\n\nShow the place you want to save at the center of the map,\nthen tap "Save this point" on the VIEWPOINT tab,\nor "Register this point" on the LOCATIONS tab,\nto save it to the current tab.';
	@override String get iconNameHead => '[Change icon / name]';
	@override String get iconNameBody => 'From the ⋯ button at the right of each slot, open the submenu\nto change the name and the icon.\nYou can choose from 32 icons.';
	@override String get reorderHead => '[Reorder]';
	@override String get reorderBody => 'Also in the ⋯ menu, use ↑ ↓ to reorder.\nSlots higher up appear earlier in the list.\n(Your home 🏠 is fixed at the top and can\'t be moved or deleted.)';
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
	@override String get relocateBody => 'Treats the point you tap on the map as a relocation destination. You can check, all together: (1) which planets\' lines move closer or farther compared with your current residence, (2) the sign changes of ASC / MC, and (3) the 12-house transitions of the 10 planets. Cosmic Pro only.';
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
	@override String get viewpointBody => 'The "VIEWPOINT" dropdown switches the reference point for\ndistance and direction scores.\nYou can choose the map center (current location), your current residence,\nor a VIEWPOINT you\'ve saved.';
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
	@override String get body => 'To use Solara, you\'ll need to agree to the items described above. Without your consent, the app can\'t be used.\n\nPlease take another look, or feel free to uninstall Solara. At this point we have not received any of your data, including any personal information, so you can uninstall with complete peace of mind.';
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
	@override String get body => 'When you tap "Agree and Begin," the fact that you agreed to the items described above is recorded on your device. It won\'t be shown again. (If the terms change, we may show this notice once more.)\n\nIf you do not agree, please tap "Decline" at the bottom of the screen and uninstall Solara. At this point, we have not received any of your data, including any personal information.';
}

// Path: aiReport.reasons.inappropriate
class _Translations$aiReport$reasons$inappropriate$en extends Translations$aiReport$reasons$inappropriate$ja {
	_Translations$aiReport$reasons$inappropriate$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Inappropriate content';
	@override String get hint => 'Discriminatory, violent, sexual, or otherwise offensive expression';
}

// Path: aiReport.reasons.misinformation
class _Translations$aiReport$reasons$misinformation$en extends Translations$aiReport$reasons$misinformation$ja {
	_Translations$aiReport$reasons$misinformation$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Wrong expert advice';
	@override String get hint => 'Definitive medical/financial/legal claims like "guaranteed to cure" or "sure to profit"';
}

// Path: aiReport.reasons.ethics
class _Translations$aiReport$reasons$ethics$en extends Translations$aiReport$reasons$ethics$ja {
	_Translations$aiReport$reasons$ethics$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Ethics violation';
	@override String get hint => 'Asserting what\'s in someone\'s mind (mind-reading), inappropriate as an astrological interpretation';
}

// Path: aiReport.reasons.quality
class _Translations$aiReport$reasons$quality$en extends Translations$aiReport$reasons$quality$ja {
	_Translations$aiReport$reasons$quality$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Quality issue';
	@override String get hint => 'Garbled text, nonsense, empty, repetitive, or unfinished';
}

// Path: aiReport.reasons.hallucination
class _Translations$aiReport$reasons$hallucination$en extends Translations$aiReport$reasons$hallucination$ja {
	_Translations$aiReport$reasons$hallucination$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Factual error';
	@override String get hint => 'Nonexistent place names, wrong astrology terms, fabrication';
}

// Path: aiReport.reasons.uncomfortable
class _Translations$aiReport$reasons$uncomfortable$en extends Translations$aiReport$reasons$uncomfortable$ja {
	_Translations$aiReport$reasons$uncomfortable$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Uncomfortable wording';
	@override String get hint => 'Overly dark, threatening, anxiety-inducing, or too pessimistic';
}

// Path: aiReport.reasons.other
class _Translations$aiReport$reasons$other$en extends Translations$aiReport$reasons$other$ja {
	_Translations$aiReport$reasons$other$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Other';
	@override String get hint => 'Anything not listed above';
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
			'consultShare.header' => '— A consultation with Stella · Solara —',
			'consultShare.metaLine' => ({required Object theme, required Object mode, required Object scope}) => 'Theme: ${theme} / Setting: ${mode} / Scope: ${scope}',
			'consultShare.withWhom' => ({required Object v}) => 'With whom: ${v}',
			'consultShare.wish' => ({required Object v}) => 'Wish: ${v}',
			'consultShare.captionIntro' => ({required Object theme}) => 'I asked Stella about "${theme}" on Solara.',
			'consultShare.candidates' => ({required Object names}) => 'Candidates: ${names}',
			'consultShare.mode.migration' => 'Migration',
			'consultShare.mode.travel' => 'Travel',
			'consultShare.mode.daily' => 'Outings & events',
			'consultShare.scope.point' => 'Specific place',
			'consultShare.scope.bearing' => 'By direction',
			'consultShare.scope.radius' => 'Radius from home',
			'consultShare.scope.region' => 'Selected area',
			'consultShare.scope.country' => 'Within my country',
			'consultShare.scope.world' => 'Worldwide',
			'locationPicker.hint' => 'Move the map to adjust the pin',
			'dateStepper.date' => 'Date',
			'dateStepper.time' => 'Time',
			'dateStepper.backToToday' => 'Back to today',
			'dateStepper.year' => 'Year',
			'dateStepper.month' => 'Month',
			'dateStepper.day' => 'Day',
			'dateStepper.hourDialogTitle' => 'Time (0–23)',
			'dateStepper.hourSuffix' => 'h',
			'solaraAuth.appleAccount' => 'Apple account',
			'solaraAuth.googleAccount' => 'Google account',
			'solaraAuth.appleOnlyPlatform' => 'Sign in with Apple is only available on iOS / macOS',
			'solaraAuth.appleUnavailable' => 'Sign in with Apple isn\'t available on this device',
			'solaraAuth.appleNoUserId' => 'Couldn\'t retrieve your Apple user ID',
			'solaraAuth.googleSignInFailed' => 'Google sign-in failed',
			'philosophy.title' => 'Design Philosophy',
			'moonOverlay.pressAgainSkip' => 'Press again to start with "No particular theme"',
			'galaxyArchive.proLabel' => 'Search & filter the archive',
			'galaxyArchive.proDesc' => 'Filter your completed cycles by name, rarity, and order.\nThe more your records build up, the easier they are to look back on.',
			'galaxyArchive.searchHint' => 'Search by name (e.g. Wing / Dragon)',
			'galaxyArchive.searchHintLocked' => 'Search — Cosmic Pro',
			'galaxyArchive.sortNewest' => 'Newest first',
			'galaxyArchive.sortOldest' => 'Oldest first',
			'galaxyArchive.sortRarity' => 'By rarity',
			'galaxyArchive.sortTooltip' => 'Sort order',
			'galaxyArchive.selectedLabel' => 'Selected:',
			'galaxyArchive.clear' => 'Clear',
			'galaxyActions.copied' => 'Copied as text',
			'galaxyActions.replayLabel' => 'Replay',
			'galaxyActions.replaySub' => 'Watch the lines being drawn',
			'galaxyActions.formationLabel' => 'Play the formation',
			'galaxyActions.formationSub' => 'Play the 8-second catasterism scene',
			'galaxyActions.copyLabel' => 'Copy as text',
			'galaxyActions.copySub' => 'To the clipboard as Markdown',
			'starAtlas.resultCount' => ({required Object shown, required Object total}) => '${shown} / ${total}',
			'starAtlas.noMatch' => 'No cycles match your filters',
			'shareConstellation.shareText' => ({required Object name}) => 'My constellation "${name}" has formed.\n#Solara',
			'shareConstellation.shareFailed' => ({required Object e}) => 'Share failed: ${e}',
			'shareConstellation.appBarTitle' => 'Share constellation',
			'shareConstellation.shareButton' => '✦ Share constellation card',
			'celestialBar.ingress' => 'Ingress',
			'celestialBar.retrograde' => 'Retrograde',
			'celestialBar.retrogradeEnd' => 'Direct',
			'celestialBar.eclipse' => 'Eclipse',
			'celestialBar.conjunction' => 'Conjunction',
			'celestialBar.nodeShift' => 'Node shift',
			'mapWelcome.addHomeTitle' => '✦ Register your current location and receive 3 free credits',
			'mapWelcome.addHomeSub' => 'We\'ll read the stars from where you are now — and you can use it for Stella consultations too.',
			'mapWelcome.addHomeCta' => 'Set current location',
			'mapWelcome.signinTitle' => '✦ Sign in with Google / Apple and receive 3 more free credits',
			'mapWelcome.signinSub' => 'Signing in carries your records over, so a new device or a reinstall is nothing to worry about.',
			'mapWelcome.signinCta' => 'Sign in',
			'mapWelcome.stellaTitle' => '✦ Welcome. We\'ve given you 3 free credits',
			'mapWelcome.stellaSub' => 'These consultation tickets don\'t reset weekly. Why not ask Stella about your stars and your place?',
			'mapWelcome.stellaCta' => 'Ask Stella',
			'mapOverlay.searchHint' => 'Search for a place...',
			'mapOverlay.vpLabel' => 'VP:',
			'mapOverlay.currentLocation' => '📍 Current location',
			'mapOverlay.home' => 'Home',
			'mapOverlay.today' => 'Today',
			'mapOverlay.birthplace' => 'Birthplace',
			'consultEntry.loading' => 'Loading…',
			'consultEntry.getCoords' => 'Copy coords',
			'consultEntry.coordsCopied' => 'Coordinates copied',
			'consultEntry.nearestLines' => 'Nearest lines',
			'consultEntry.consultHere' => 'Consult about this place',
			'planetIntroPopup.frameNatal' => 'NATAL',
			'planetIntroPopup.frameTransit' => 'TRANSIT',
			'planetIntroPopup.frameProgressed' => 'PROGRESSED',
			'planetIntroPopup.basics' => ({required Object name}) => '${name} basics',
			'planetIntroPopup.preparing' => 'An interpretation for this planet is still being prepared.',
			'mapAspect.orb' => 'Orb ',
			'mapAspect.nature' => 'Nature',
			'mapAspect.theme' => 'Theme',
			'mapAspect.reading' => 'Reading',
			'proDialog.isFeature' => ({required Object label}) => '${label} is a Pro feature',
			'proDialog.upgrade' => 'Upgrade to Pro',
			'proDialog.close' => 'Close',
			'proDialog.secTitle' => '✦ Device security check',
			'proDialog.unavailableHere' => ({required Object label}) => '${label} isn\'t available on this device right now',
			'proDialog.compromisedBody' => 'We\'ve detected signs of tampering or analysis tools (rooting, Frida, jailbreak, emulator, etc.) on this device.\n\nPro features are locked because we can\'t provide them safely here.\nFree features remain available as usual.',
			'observe.loading1' => 'The stars are weaving their words for you',
			'observe.loading2' => 'Listening closely to the planets\' whispers',
			'observe.loading3' => 'Unraveling the mystery of the cards',
			'observe.loading4' => 'Crystallizing what today means for you',
			'observe.tapToDraw' => '👆 Tap to draw a card',
			'observe.alreadyDrawn' => '✓ Today\'s card already drawn',
			'observe.offlineMode' => '⚠ Offline mode (simplified)',
			'observe.failTitle' => 'Couldn\'t load the reading.',
			'observe.failBody' => 'Please check your connection and try again.',
			'observe.stellaNote' => 'Stella shows this as one interpretation drawn from the cards. If something feels off, feel free to expand on it with your own reading. What\'s shown here is only one of many interpretations.',
			'observe.posUpright' => 'Upright',
			'observe.posReversed' => 'Reversed',
			'observe.posShortUpright' => 'Up',
			'observe.posShortReversed' => 'Rev',
			'observe.cancel' => 'Cancel',
			'observe.delete' => 'Delete',
			'observe.creditTitleFree' => 'Use a free credit',
			'observe.creditTitlePaid' => 'Use a paid credit',
			'observe.creditTitleNone' => 'No credits',
			'observe.catLine' => ({required Object label}) => 'Category: ${label}',
			'observe.freeCredits' => 'Free credits',
			'observe.freeRemaining' => ({required Object remaining, required Object limit}) => '${remaining} / ${limit} left',
			'observe.freeChecking' => 'Checking remaining',
			'observe.weeklyRefill' => 'Refills every Monday',
			'observe.paidCredits' => 'Paid credits',
			'observe.paidRemaining' => ({required Object n}) => '${n} left',
			'observe.noExpiry' => 'No expiry (purchased credits carry across devices)',
			'observe.buyCredits' => 'Buy credits',
			'observe.draw' => 'Draw',
			'observe.todayTheme' => 'Today\'s theme',
			'observe.themeOptional' => ({required Object n}) => 'Optional · ${n}/200',
			'observe.alreadyDrawnHint' => 'Already drawn today (come back tomorrow)',
			'observe.themeExample' => 'e.g. I\'m unsure whether to start a new project',
			'observe.qProFeature' => 'Tarot with a question',
			'observe.qProDesc' => 'Add a "theme for today" in 200 characters or less, and Stella reads the cards in tune with it. Cosmic Pro also unlocks a deeper reading.',
			'observe.addTheme' => 'Draw with today\'s theme',
			'observe.qProHint' => 'Cosmic Pro opens the theme field, and Stella reads in tune with it.',
			'observe.readCategory' => 'Category to read',
			'observe.onceADay' => 'Tarot is once a day',
			'observe.catCreditNonOverall' => 'Choosing a category other than Overall uses a credit.',
			'observe.catCreditWithCount' => ({required Object free, required Object purExtra}) => 'Choosing a category uses 1 credit (${free} free left${purExtra})',
			'observe.purExtra' => ({required Object n}) => ' · ${n} purchased',
			'observe.catCreditSimple' => 'Choosing a category uses 1 credit',
			'observe.overallFree' => 'Overall uses no credits',
			'observe.fullText' => 'Show full text for easy reading',
			'observe.confirm' => 'Confirm',
			'observe.deleteAllConfirm' => 'Delete all history?',
			'observe.tabCurrentCycle' => 'This cycle',
			'observe.tabPastCycle' => 'Past cycles',
			'observe.limitNote' => '* History keeps up to 50 entries. The oldest are removed automatically.',
			'observe.countLine' => ({required Object visible, required Object total}) => '${visible} / ${total}',
			'observe.emptyHistory' => 'No history yet\n\nDraw a card on the TAROT DRAW tab\nto record it here',
			'observe.noMatch' => 'No cards match your filters',
			'observe.home' => 'Home',
			'observe.hasQuestion' => 'Has a question',
			'observe.memoHintSync' => 'Note a coincidence or insight...',
			'observe.noPastCycles' => 'No past cycles yet\n\nWhen the moon fills and a new cycle begins,\nyour tarot history until then remains here.',
			'observe.dateCount' => ({required Object date, required Object count}) => '${date} · ${count}',
			'observe.noTarotInCycle' => 'No tarot history in this cycle',
			'observe.memoHintPast' => 'Note what you noticed back then...',
			'observe.filterProFeature' => 'Search & filter history',
			'observe.filterProDesc' => 'Narrow your past card history by keyword, arcana, or element.\nThe moment you\'re after, found in an instant.',
			'observe.searchHint' => 'Search card name, reading, question, synchronicity',
			'observe.searchProLocked' => 'Search — Cosmic Pro',
			'observe.majorArcana' => 'Major Arcana',
			'observe.minorArcana' => 'Minor Arcana',
			'horoDisplay.filterHint' => 'Left check = toggle ON/OFF / Right label = open description',
			'horoDisplay.secPlacement' => 'Placement features',
			'horoDisplay.secNatal' => 'When natal (N)',
			'horoDisplay.secTransit' => 'When transit-active (T)',
			'horoDisplay.secProgress' => 'When progressed (P)',
			'horoDisplay.active' => 'Active',
			'horoDisplay.soon' => 'Soon',
			'horoDisplay.daysLater' => ({required Object days}) => 'in ${days} days',
			'horoDisplay.legendSoft' => 'Soft',
			'horoDisplay.legendHard' => 'Hard',
			'horoDisplay.neutral' => 'Neutral',
			'horoDisplay.legendNatal' => 'Natal',
			'horoDisplay.legendTransit' => 'Transit',
			'horoDisplay.legendProgress' => 'Progress',
			'horoDisplay.backdropSub' => 'Set it up in SANCTUARY to also see your own personal horoscope',
			'horoDisplay.orb' => ({required Object deg}) => 'Orb ${deg}°',
			'horoDisplay.aspNature' => 'Nature',
			'horoDisplay.aspTheme' => 'Theme',
			'horoDisplay.aspReading' => 'Reading',
			'horoDisplay.noAspects' => 'No aspects',
			'horoDisplay.moreAspects' => ({required Object n}) => '... ${n} more',
			'horoDisplay.horoOfDate' => ({required Object date}) => 'Horoscope for ${date}',
			'horoDisplay.stellaNote' => 'Stella shows this as one interpretation, drawn from the aspects and houses of your horoscope. If something feels off, the evidence behind Stella\'s reading is right there in your horoscope — please feel free to expand on it with your own interpretation. What\'s shown here is only one of many readings.',
			'horoDisplay.birthDataNote' => 'Star readings reflect only your original birth details.\nEdits to BIRTH DATA are not reflected in star readings.',
			'horoDisplay.proOpenReading' => ({required Object name}) => 'Cosmic Pro also opens ${name}\'s reading',
			'horoDisplay.filterSecAspect' => 'Aspect nature',
			'horoDisplay.filterSoft' => 'Soft (harmony)',
			'horoDisplay.filterHard' => 'Hard (tension)',
			'horoDisplay.filterSecCategory' => 'Category',
			'horoDisplay.filterSecPlanetGroup' => 'Planet group',
			'horoDisplay.filterPersonal' => 'Personal planets',
			'horoDisplay.filterSocial' => 'Social planets',
			'horoDisplay.filterGenerational' => 'Generational planets',
			'horoPanel.tabBirth' => 'Birth',
			'horoPanel.tabProgress' => 'Progress',
			'horoPanel.tabTransit' => 'Transit',
			'horoPanel.tabPlanets' => 'Planets',
			'horoPanel.tabRelocate' => 'Base',
			'horoPanel.tabFilter' => 'Filter',
			'horoPanel.tabAspects' => 'Aspects',
			'horoPanel.progressUpdate' => 'Update progression',
			'horoPanel.transitUpdate' => 'Update transit',
			'horoPanel.dateLabel' => 'DATE',
			'horoPanel.timeLabel' => 'TIME',
			'horoPanel.placeLabel' => 'PLACE',
			'horoPanel.hourSuffix' => 'h',
			'horoPanel.minuteSuffix' => 'm',
			'horoPanel.birthDataNote' => '* BIRTH DATA resets when you leave the Horo screen',
			'horoPanel.nameLabel' => 'NAME',
			'horoPanel.nameHint' => 'Friend A\'s name (optional)',
			'horoPanel.birthDateLabel' => 'DATE',
			'horoPanel.birthTimeLabel' => 'TIME',
			'horoPanel.unknown' => 'Unknown',
			'horoPanel.birthCityHint' => 'City/town level is fine for the birthplace — no street address needed',
			'horoPanel.birthplaceLabel' => 'BIRTHPLACE',
			'horoPanel.calcCta' => '✨ Calculate with this data',
			'horoPanel.clipboardInvalid' => 'No valid "latitude, longitude" on the clipboard',
			'horoPanel.pasteCoords' => 'Paste coordinates',
			'horoPanel.copyHint' => 'Tap a point on the Map → "Copy coords" to copy',
			'horoPanel.autoFetch' => '— (auto-fetched after you enter coordinates)',
			'horoPanel.latLabel' => 'LAT',
			'horoPanel.latHint' => 'e.g. 35.6762',
			'horoPanel.lngLabel' => 'LNG',
			'horoPanel.lngHint' => 'e.g. 139.6503',
			'horoPanel.tzLabel' => 'TZ',
			'horoScreen.thisTheme' => 'this theme',
			'horoScreen.proReadLabel' => ({required Object name}) => 'Stella\'s reading of ${name}',
			'horoScreen.proReadDesc' => ({required Object name}) => 'Stella reads today\'s star positions through the theme of "${name}". All 5 categories and deeper readings are unlocked with Cosmic Pro.',
			'horoScreen.fortuneApiError' => 'Couldn\'t connect to the Fortune API',
			'horoScreen.modeNatal' => 'NATAL',
			'horoScreen.modeNT' => 'N+T',
			'horoScreen.modeNP' => 'N+P',
			'horoScreen.modeAstro' => '✦ Star reading',
			'horoScreen.houseEssence' => 'Essence',
			'horoScreen.houseEssenceTip' => 'Houses based on your birthplace',
			'horoScreen.houseReality' => 'Reality',
			'horoScreen.houseRealityTipHome' => 'Houses based on your current residence (relocation)',
			'horoScreen.houseRealityTipNoHome' => 'Please set your current residence in the Sanctuary',
			'relocPanel.headerSub' => ({required Object from, required Object to}) => 'From ${from} to ${to}: how the planets near and leave the angles',
			'relocPanel.loading' => 'Stella is reading the stars of this place…',
			'relocPanel.failTitle' => 'Couldn\'t load the reading.',
			'relocPanel.failBody' => 'Please check your connection and try again.',
			'relocPanel.secAngleSign' => 'The angles\' signs change',
			'relocPanel.secPlanetAngle' => 'How close the 10 planets are to the angles',
			'relocPanel.angleHead' => ({required Object angle, required Object domain}) => '${angle} (${domain})',
			'relocPanel.axisLabel' => ({required Object angle}) => '${angle} axis',
			'relocPanel.tagHouseShift' => '◆ House shift',
			'relocPanel.tagCloser' => '▲ Approaching',
			'relocPanel.tagFarther' => '▽ Receding',
			'relocPanel.tagSame' => '・ Almost no change',
			'relocPanel.needChart' => 'Set your birth time and current residence to read which angle the planets draw near here.',
			'relocPanel.samePlace' => 'Your birthplace and current residence are almost the same spot. The farther you move, the more clearly the distance between planets and angles changes.',
			'relocPanel.footnote' => '* The closer a planet is to an angle (ASC/MC/DSC/IC), the more that planet\'s theme comes forward in that land. Not a good/bad verdict, but a leaning toward "stronger / gentler".',
			'mapReloc.consultHere' => 'Consult about this place',
			'mapReloc.deltaTitle' => ({required Object base}) => 'Star lines that shift here, compared with your ${base}',
			'mapReloc.linesTitle' => ({required Object n}) => 'Points on lines (nearby ${n})',
			'mapReloc.moreLines' => ({required Object n}) => '${n} more',
			'mapReloc.titleIntegrated' => ({required Object coord}) => 'Integrated — ${coord}',
			'mapReloc.titleRelocate' => ({required Object coord}) => 'Relocation layer — ${coord}',
			'mapReloc.titleTapped' => ({required Object coord}) => 'Tapped point — ${coord}',
			'mapReloc.getCoords' => 'Copy coords',
			'mapReloc.baseToTap' => ({required Object base}) => '${base} → tapped point',
			'mapReloc.noChange' => 'No change',
			'mapReloc.personalPlanet' => 'Personal planet',
			'mapReloc.coordsCopied' => 'Coordinates copied',
			'mapReloc.signSuffix' => ({required Object sign}) => '${sign}',
			'mapSearch.results' => ({required Object n}) => 'Results (${n})',
			'mapSearch.rankDistance' => 'Nearby',
			'mapSearch.rankRelevance' => 'Popular',
			'mapSearch.rankHelpTitle' => 'How to narrow results',
			'mapSearch.rankDistanceHead' => '[Nearby]',
			'mapSearch.rankDistanceBody' => 'Fetches in order of nearness to the map\'s center (e.g. your current residence).\nEven lesser-known places rank high if they\'re nearby.',
			'mapSearch.rankRelevanceHead' => '[Popular]',
			'mapSearch.rankRelevanceBody' => 'Prioritizes places well-known on Google.\nWell-known candidates rank high even if somewhat far.',
			'mapSearch.rankNote' => '* This isn\'t a re-sort — the candidates fetched themselves change.',
			'mapSearch.bearing' => ({required Object dir}) => '${dir}',
			'mapSearch.categoryBreakdown' => 'Category breakdown',
			'mapSearch.saveViewpoint' => '📍 Save as VIEWPOINT',
			'mapSearch.savedViewpoint' => '✓ Saved as VIEWPOINT',
			'mapSearch.saveLocation' => '🏠 Save as LOCATION',
			'mapSearch.savedLocation' => '✓ Saved as LOCATION',
			'mapSearch.moveHere' => '✈ Move here',
			'mapSearch.openGoogleMaps' => '🗺 View on Google Maps',
			'mapSearch.consultStella' => '✦ Consult Stella',
			'mapSearch.googleMapsFailed' => 'Couldn\'t open Google Maps',
			'mapDir.mainContrib' => 'Main contributing aspects',
			'mapDir.twoEnergies' => 'About the two energies',
			'mapDir.guidanceBoth' => 'Both energies are present in this direction at once.\nA place of deep experience where both flow and friction take effect.\nWhich to ride, or to observe both — the choice is yours.',
			'mapDir.guidanceSoft' => 'Soft energy is dominant in this direction.\nA place where it\'s easy to ride the flow.\nWhether to move receptively or to consciously choose your direction is up to you.',
			'mapDir.guidanceHard' => 'Hard energy is dominant in this direction.\nA place of friction and transformation.\nWhether to look again, to confront, or to keep your distance is your choice.',
			'mapDir.guidanceQuiet' => 'Both energies in this direction are quiet right now.\nA time when special effects are hard to feel.\nA place to stay natural, without forcing meaning onto it.',
			'aiReport.reportLink' => 'Report inappropriate content',
			'aiReport.sheetTitle' => 'Report AI output',
			'aiReport.sheetIntro' => 'Tell us what was wrong. We\'ll review it and use it to improve the AI\'s quality.',
			'aiReport.detailHint' => 'Details (optional, up to 500 characters)',
			'aiReport.submit' => 'Submit',
			'aiReport.cancel' => 'Cancel',
			'aiReport.thanks' => 'Thank you for your report. We\'ll review it.',
			'aiReport.sendFailed' => 'Sending failed. Please try again where you have a good signal.',
			'aiReport.reasons.inappropriate.label' => 'Inappropriate content',
			'aiReport.reasons.inappropriate.hint' => 'Discriminatory, violent, sexual, or otherwise offensive expression',
			'aiReport.reasons.misinformation.label' => 'Wrong expert advice',
			'aiReport.reasons.misinformation.hint' => 'Definitive medical/financial/legal claims like "guaranteed to cure" or "sure to profit"',
			'aiReport.reasons.ethics.label' => 'Ethics violation',
			'aiReport.reasons.ethics.hint' => 'Asserting what\'s in someone\'s mind (mind-reading), inappropriate as an astrological interpretation',
			'aiReport.reasons.quality.label' => 'Quality issue',
			'aiReport.reasons.quality.hint' => 'Garbled text, nonsense, empty, repetitive, or unfinished',
			'aiReport.reasons.hallucination.label' => 'Factual error',
			'aiReport.reasons.hallucination.hint' => 'Nonexistent place names, wrong astrology terms, fabrication',
			'aiReport.reasons.uncomfortable.label' => 'Uncomfortable wording',
			'aiReport.reasons.uncomfortable.hint' => 'Overly dark, threatening, anxiety-inducing, or too pessimistic',
			'aiReport.reasons.other.label' => 'Other',
			'aiReport.reasons.other.hint' => 'Anything not listed above',
			'mapScreen.vpOffscreen' => 'VIEWPOINT is off-screen. Zoom out, or check the 16-direction status from the score bar at the top-left.',
			'mapScreen.geoServiceOff' => 'Location services are OFF on your device. Please turn them on in Settings.',
			'mapScreen.geoDeniedForever' => 'Location access is permanently denied. Please allow it from the Settings app.',
			'mapScreen.geoDenied' => 'Location access was denied.',
			'mapScreen.geoGetting' => 'Getting your current location…',
			'mapScreen.geoFailed' => ({required Object e}) => 'Couldn\'t get your current location: ${e}',
			'mapScreen.coordsCopied' => ({required Object coords}) => 'Coordinates copied: ${coords}',
			'mapScreen.searching' => 'Searching…',
			'mapScreen.calculating' => 'Calculating…',
			'mapScreen.tappedPoint' => 'Tapped point',
			'mapScreen.proBandLabel' => 'Zenith / Nadir bands',
			'mapScreen.proAspectLabel' => 'Aspect lines (120)',
			'mapScreen.proRelocateLabel' => 'Relocation simulation',
			'mapScreen.proAcgLabel' => 'Advanced ACG',
			'mapScreen.proBandDesc' => 'A Lewis-style display showing, as bands, the latitudes where a planet passes directly overhead (zenith) or underfoot (nadir). You can read career and home themes by "latitude".',
			'mapScreen.proAspectDesc' => 'In addition to the 40 conjunction lines, shows all 120 aspect lines including squares, trines, and sextiles.',
			'mapScreen.proRelocateDesc' => 'Treats the tapped point on the map as a relocation destination, recalculating ASC / MC / the 12 houses and comparing them side by side with your current residence.',
			'mapScreen.proAcgDesc' => 'A feature unlocked with Cosmic Pro.',
			'mapScreen.creditBannerTitle' => '✦ Register your birth details and current residence to get 3 free credits',
			'mapScreen.creditBannerSub' => 'Set them up in SANCTUARY to also see the direction scores for each place',
			'mapScreen.setupCta' => 'Set up →',
			'mapScreen.vpHelpTitle' => 'Choosing your VIEWPOINT (the 16-direction reference point)',
			'mapScreen.vpHelpIntro' => 'Tapping a chip switches the reference point (VP) for the 16-direction score\nto that place. The map view doesn\'t move.\nIf you search without entering a place name, candidates are returned from\naround the map\'s center (the VP is a separate axis).',
			'mapScreen.vpHelpGpsHead' => '[📍 Current location]',
			'mapScreen.vpHelpGpsBody' => 'For when you want to see "which way to head, right now".\nUses GPS to get your current location and makes that spot the viewpoint.\nFor "the directions here and now" while moving or traveling.',
			'mapScreen.vpHelpHomeHead' => '[🏠 Home / saved VP]',
			'mapScreen.vpHelpHomeBody' => 'Using your own base (home, school, workplace, etc.) as the viewpoint.\nYou can read it as "what energy this searched place receives\nas seen from my home, school, or workplace".',
			'mapScreen.vpHelpChoiceHead' => 'Which to choose is up to you',
			'mapScreen.vpHelpChoiceBody' => 'In astrology, "where to place the viewpoint" changes with the theme you want\nto see. For everyday guidance, home; for a decision in the moment of action,\nyour current location; for a place to put down roots while traveling, that land.\nUsing them by purpose, the "meaning of direction" comes into fuller relief.',
			'mapScreen.vpHelpOffscreenHead' => 'When the VP goes off-screen',
			'mapScreen.vpHelpOffscreenBody' => 'When the searched place and the VP are far apart, the 16-direction fan\ngoes off-screen and can\'t be seen. Zoom out, or tap the score bar (band)\nat the top-left, and you can check today\'s direction status even off-screen.',
			'mapScreen.vpSlotDefaults.0' => 'Workplace',
			'mapScreen.vpSlotDefaults.1' => 'Favorite',
			'mapScreen.vpSlotDefaults.2' => 'Spot',
			'mapScreen.vpSlotDefaults.3' => 'Place',
			'mapScreen.locSlotDefaults.0' => 'Place 1',
			'mapScreen.locSlotDefaults.1' => 'Place 2',
			'mapScreen.locSlotDefaults.2' => 'Place 3',
			'mapScreen.locSlotDefaults.3' => 'Place 4',
			'homeEdit.addressLabel' => 'Address / place name',
			'homeEdit.placeHint' => 'e.g. Dallas, Texas',
			'homeEdit.notFound' => 'No results found',
			'homeEdit.connError' => 'Connection error',
			'resetPicker.title' => '✦ Start of day',
			'resetPicker.subtitle' => 'Tarot\'s "once a day" and the moon rituals (new moon, full moon, catasterism) roll over to a new day when this time passes.\n(Star readings switch at midnight.)',
			'resetPicker.unitHour' => 'h',
			'resetPicker.unitMinute' => 'm',
			'resetPicker.cancel' => 'Cancel',
			'resetPicker.confirm' => 'Done',
			'orbOverlay.reset' => 'Reset',
			'orbOverlay.scopeNote' => 'This setting applies to aspect and pattern detection on the Horoscope screen. It does not affect the Map\'s direction scores or Daily Transit.',
			'legalMenu.heading' => '✦ Legal',
			'legalMenu.eula' => 'Terms of Service (EULA)',
			'legalMenu.openFailed' => ({required Object url}) => 'Couldn\'t open the link: ${url}',
			'account.signInBenefit' => 'Sign in to carry Pro across devices',
			'account.signInBenefitSub' => 'Keep Cosmic Pro even when you change or add devices. Your records stay on this device even without signing in.',
			'account.signInApple' => ' Sign in with Apple',
			'account.signInGoogle' => 'Sign in with Google',
			'account.signedInWith' => ({required Object provider}) => 'Signed in with ${provider}',
			'account.signOut' => 'Sign out',
			'account.deleting' => 'Deleting…',
			'account.deleteAccount' => 'Delete account from Solara',
			'account.signInFailed' => ({required Object e}) => 'Sign-in failed: ${e}',
			'account.signedOut' => 'Signed out',
			'account.deleteTitle' => 'Delete your account?',
			'account.deleteBody' => 'This deletes your sign-in info and the subscription records on our server.\n\n· For Apple sign-in, you\'ll be asked to sign in with Apple again to confirm deletion (to fully revoke the link).\n· If you have a paid plan, please cancel it separately from the App Store / Google Play (deletion does not auto-cancel).\n· Your on-device records (consultation history, titles, Galaxy) stay on this device.\n· This action can\'t be undone.',
			'account.cancel' => 'Cancel',
			'account.deleteConfirm' => 'Delete',
			'account.deleted' => 'Your account has been deleted.',
			'account.deleteFailed' => ({required Object e}) => 'Deletion failed: ${e}',
			'shareCard.appBar' => 'Share your title',
			'shareCard.noClassData' => 'No class data',
			'shareCard.shareText' => ({required Object title, required Object cls}) => 'My title is "${title}" — ${cls}\n#Solara',
			'shareCard.shareFailed' => ({required Object e}) => 'Share failed: ${e}',
			'titleHow.title' => '✦ How titles work',
			'titleHow.s1Title' => 'Birth date → Epithet',
			'titleHow.s1Body' => 'From the combination of your Sun sign × Moon sign, one of 144 "epithets" is set.\nThis one is uniquely yours — the diagnosis never changes it.',
			'titleHow.s2Title' => '28 questions → 5-axis score',
			'titleHow.s2Body' => 'As you answer the PART 1 (everyday) and PART 2 (destiny) questions by choosing cards on intuition, points are added to five axes (Power, Mind, Spirit, Shadow, Heart).\nYour highest-scoring axis becomes your "temperament".',
			'titleHow.s3Title' => 'PART 3 → Court (role)',
			'titleHow.s3Body' => 'Across the 4 court-card questions, whichever of page, knight, queen, king you pick two or more times becomes your court. If they\'re scattered, it becomes "mixed".',
			'titleHow.s4Title' => 'Axis × Court → 25 classes',
			'titleHow.s4Body' => '5 axes × 5 courts = 25 kinds of class (Knight, Sage, Astrologer, Ninja…), from which the one class that fits you is chosen.',
			'titleHow.s5Title' => 'Light side / Shadow side',
			'titleHow.s5Body' => 'Tap the result screen to flip between the front (Light) and back (Shadow).\nLight is your strengths; Shadow is a humor-tinged "oh, that\'s so me".',
			'titleHow.s6Title' => 'Tiebreak — astrological seed',
			'titleHow.s6Body' => 'When axes or courts tie, one is chosen from your Sun sign × Moon sign (144 combinations).\nThe real lead is the cards you chose — pick different cards and you get a different result.\nThe astrological seed only plays "the final tiebreaker for when the judge is stuck".',
			'titleHow.footer' => '* You can take the diagnosis again anytime. Temperament moves with the mood of the day — enjoy it as a mirror reflecting "the you of now".',
			'titleHist.clearTitle' => 'Delete all history?',
			'titleHist.clearBody' => 'Your saved title (class) history will be erased. This can\'t be undone.\nYour current title stays in the Sanctuary.',
			'titleHist.cancel' => 'Cancel',
			'titleHist.delete' => 'Delete',
			'titleHist.guideTitle' => 'What "Title history" is',
			'titleHist.guideIntro' => 'Here, the changes in the "title (class)" you diagnosed in the Sanctuary are recorded, newest first.',
			'titleHist.guideClassEpithetHead' => '[Title (class) and epithet]',
			'titleHist.guideClassEpithet' => '· Epithet … the name drawn from your Sun sign × Moon sign that stays with you for life.\n· Title (class) … "the you of now", shaped by your answers. It changes through re-diagnosis as your inner life and circumstances shift.',
			'titleHist.guideRediagnoseHead' => '[About re-diagnosis]',
			'titleHist.guideRediagnose' => 'You can retake it from "Retake the diagnosis" in the Sanctuary.\n· Free … up to once\n· Cosmic Pro … as many times as you like (even daily)\nRetake it at moments of change, and your history stacks up here so you can trace the path of your growth.',
			'titleHist.guideStanceHead' => '[Solara\'s stance]',
			'titleHist.guideStance' => 'We never weaken a past title as "you used to be…". Every title stands equally, as the you of that moment.',
			'titleHist.emptyTitle' => 'No title history yet',
			'titleHist.emptyBody' => 'Each time you retake the diagnosis in the Sanctuary,\nyour past classes will remain here.',
			'titleHist.noteHint' => 'Leave a note for yourself about the situation or feelings when your title changed',
			'profileEdit.title' => '✦ Birth details',
			'profileEdit.nickname' => 'Nickname',
			'profileEdit.nicknameHint' => 'Enter a nickname',
			'profileEdit.birthDate' => 'Date of birth',
			'profileEdit.birthDateRequired' => 'Please enter your date of birth',
			'profileEdit.birthTime' => 'Birth time',
			'profileEdit.hourHint' => 'Hour',
			'profileEdit.minuteHint' => 'Min',
			'profileEdit.hourItem' => ({required Object h}) => '${h}',
			'profileEdit.minuteItem' => ({required Object m}) => '${m}',
			'profileEdit.timeUnknown' => 'I don\'t know my birth time',
			'profileEdit.timeUnknownNote' => 'The reading uses planetary positions and aspects. House, ASC and MC readings are omitted.',
			'profileEdit.birthPlace' => 'Birthplace',
			'profileEdit.cityLevelHint' => 'City/town level is fine — no street address needed',
			'profileEdit.placeHint' => 'e.g. Dallas, Texas',
			'profileEdit.placeRequired' => 'Please enter your birthplace',
			'profileEdit.search' => 'Search',
			'profileEdit.latitude' => 'Latitude',
			'profileEdit.longitude' => 'Longitude',
			'profileEdit.tzResolving' => 'Resolving timezone…',
			'profileEdit.tzAuto' => ({required Object tz}) => 'Timezone: ${tz} (DST auto)',
			'profileEdit.tzFixed' => ({required Object tz}) => 'Timezone: UTC+${tz} (fixed)',
			'profileEdit.language' => 'Language',
			'profileEdit.langDevice' => 'Device',
			'profileEdit.langDeviceSub' => 'System default',
			'profileEdit.langEnglishSub' => 'English',
			'profileEdit.save' => 'Save',
			'titleDiag.ceremonyDash' => '— The Title Ceremony —',
			'titleDiag.ceremony' => 'The Title Ceremony',
			'titleDiag.introBody' => 'The cards reflect who you are.\nAnswer the 28 questions with your intuition.',
			'titleDiag.begin' => 'Begin',
			'titleDiag.later' => 'Later',
			'titleDiag.forging1' => 'Reading your stars…',
			'titleDiag.forging2' => 'Weaving your destiny…',
			'titleDiag.forging3' => 'Engraving your title…',
			'titleDiag.goWithThis' => 'Go with this',
			'titleDiag.compareWithPrevious' => '✦ Compare with your previous class',
			'titleDiag.prevReturnTitle' => '✦ Return to your previous class?',
			'titleDiag.adoptPrevious' => '✦ Keep the previous class',
			'titleDiag.keepNew' => 'Keep the new class',
			'sanctuary.creditPro' => ({required Object remaining, required Object limit, required Object pur}) => '✦ Pro ${remaining} / ${limit} ・ Purchased ${pur} (refills Monday)',
			'sanctuary.creditProSyncing' => ({required Object pur}) => '✦ Pro balance syncing ・ Purchased ${pur}',
			'sanctuary.creditFree' => ({required Object free, required Object pur}) => '✦ Credits ─ Free ${free} ・ Purchased ${pur}',
			'sanctuary.set' => 'Set ›',
			'sanctuary.unset' => 'Not set ›',
			'sanctuary.birthInfo' => 'Birth details',
			'sanctuary.home' => 'Home (current residence)',
			'sanctuary.receiveTitle' => '✦ Receive your title',
			'sanctuary.shareTitleCard' => '✦ Share your title card',
			'sanctuary.rediagnose' => 'Retake the diagnosis',
			'sanctuary.rediagnoseProOnly' => 'Retaking is Cosmic Pro only',
			'sanctuary.needProfile' => 'Please set your birth details first',
			'sanctuary.rediagnoseProFeature' => 'Retaking your class',
			'sanctuary.rediagnoseProDesc' => 'The "you of now" keeps changing.\nWith Cosmic Pro you can retake the diagnosis any time,\nand line up your past classes side by side in the history gallery.',
			'sanctuary.guide.title' => '✦ About retaking your title',
			'sanctuary.guide.lead' => 'With Cosmic Pro, you can receive your title again as many times as you like.',
			'sanctuary.guide.body1' => 'That said, the "epithet" drawn from your Sun and Moon signs never changes. What changes is only the "title (class)" shaped by your answers to the questions.',
			'sanctuary.guide.body2' => 'Each title is deeply tied to its questions. Retake it when you feel a change within yourself or in your surroundings, and later — looking back through "Title history" — you can trace your growth and your shifts.',
			'sanctuary.guide.body3' => 'Of course, you\'re welcome to retake it every day. We simply mention, gently, that this too is one way to use it.',
			'sanctuary.guide.back' => 'Back',
			'sanctuary.consultHistory' => 'Consultation history',
			'sanctuary.titleHistory' => 'Title history',
			'sanctuary.proPerks1' => 'All tarot categories · Deeper star readings · Map relocation & 120 lines',
			'sanctuary.proPerks2' => 'Time-specific outings · Unlimited title retakes · 5-year Forecast, and more',
			'sanctuary.proPaywallNote' => 'See plans and pricing on the paywall · Cancel anytime',
			'sanctuary.proActive' => 'Cosmic Pro active',
			'sanctuary.proActiveDesc' => 'All features are unlocked.',
			'sanctuary.plansTerms' => 'Plans & terms',
			'sanctuary.restoreNotFound' => 'No purchases to restore were found.',
			'sanctuary.restoreDone' => 'Your purchases have been restored.',
			'sanctuary.restoreError' => ({required Object e}) => 'An error occurred while restoring: ${e}',
			'sanctuary.orbSetting' => 'Horoscope orbs',
			'sanctuary.orbStandard' => 'Standard ›',
			'sanctuary.orbCustom' => 'Custom ›',
			'sanctuary.dayStart' => 'Start of day',
			'sanctuary.notifyNeedPermission' => 'Please allow notifications in your device settings',
			'mapDaily.birthplace' => 'Birthplace',
			'mapDaily.worldScale' => 'See on a world scale',
			'mapDaily.consultStella' => 'Consult Stella',
			'mapDaily.consultStellaSub' => 'Read places from the planets',
			'mapDaily.tabToday' => 'Today',
			'mapDaily.tabTomorrow' => 'Tomorrow',
			'mapDaily.allCategories' => 'All categories',
			'mapDaily.todayTop' => ({required Object label}) => 'Today\'s TOP — ${label}',
			'mapDaily.tagline.neutral' => 'Let\'s check today\'s movement',
			'mapDaily.tagline.love' => 'A day when relational energy moves on many sides',
			'mapDaily.tagline.money' => 'A day when the energy of material abundance flows',
			'mapDaily.tagline.work' => 'A day when the energy of your social role moves',
			'mapDaily.tagline.healing' => 'A day when the energy of reflection and integration flows',
			'mapDaily.tagline.communication' => 'A day when the energy of dialogue and intellect moves',
			'mapDaily.subLabelOuter' => 'Outward phase',
			'mapDaily.subLabelInner' => 'Inward phase',
			'mapDaily.subLabelMixed' => 'Outward + inward phases mixed',
			'mapDaily.recommendedActions' => 'Example actions (for reference)',
			_ => null,
		} ?? switch (path) {
			'mapDaily.otherActionsNote' => '* Feel free to think up other actions too, using these as a guide',
			'mapDaily.loading' => 'Reading the planets\' motion',
			'mapDaily.failed' => 'Couldn\'t fetch the data',
			'mapDaily.retry' => 'Try again',
			'mapDaily.quietDay' => 'A quiet day.\nNo special movement is visible.',
			'mapDaily.noFilterMatch' => 'No events match this filter.\nPlease change the filter.',
			'mapDaily.viewOnMap' => 'See this time on the Map',
			'mapDaily.transitPass' => ({required Object planet, required Object angle}) => '${planet} passing ${angle}',
			'mapDaily.transitTitle' => ({required Object planet, required Object angle}) => '${planet} passing ${angle}',
			'mapDaily.angle.asc' => 'Eastern horizon (ASC)',
			'mapDaily.angle.mc' => 'Zenith (MC)',
			'mapDaily.angle.dsc' => 'Western horizon (DSC)',
			'mapDaily.angle.ic' => 'Nadir (IC)',
			'mapDaily.angleHint.asc' => ({required Object compass}) => 'The time it begins to rise — appearing on the ${compass} horizon',
			'mapDaily.angleHint.mc' => ({required Object compass}) => 'The time it climbs highest — its peak in the ${compass} sky',
			'mapDaily.angleHint.dsc' => ({required Object compass}) => 'The time it sets — descending to the ${compass} horizon',
			'mapDaily.angleHint.ic' => 'The time it passes underground — felt as an inner movement',
			'mapDaily.zenithBias' => '★ Near zenith',
			'mapDaily.nadirBias' => '★ Near nadir',
			'mapDaily.latitudeBand' => ({required Object lat, required Object orb}) => 'Your latitude band now (lat ${lat}°, orb ±${orb}°)',
			'mapDaily.zenithBand' => 'Zenith band',
			'mapDaily.nadirBand' => 'Nadir band',
			'mapDaily.usage.title' => 'How to read today\'s movement',
			'mapDaily.usage.summary' => 'On this screen, matched to the purpose you intend,\nyou can read "when to act" — guidance on timing.',
			'mapDaily.usage.vpTitle' => '[Reference point (VIEWPOINT)]',
			'mapDaily.usage.vpBody' => 'The dropdown on the right is the "reference point."\nYou can choose your birthplace (the point you registered as your current residence)\nor a point you registered as a VIEWPOINT.\nThis screen shows where and when the planets reach each "sky direction"\nin the sky above your chosen reference point.',
			'mapDaily.usage.diffTitle' => '[⚠ Different from the Map screen\'s directions]',
			'mapDaily.usage.diffBody' => '· Map screen = "surface directions" (16 directions)\n　which way along the ground you head from the reference point\n　(going to a land in the east / heading to a land in the north — geography)\n\n· This screen = "sky directions" (4 angles)\n　where a planet sits in the sky right above the reference point\n　(eastern horizon / overhead zenith / western horizon / straight below)\n\nEven the same "east" means "a land in the east" on the Map,\nand "the eastern horizon (where a planet rises)" on this screen.',
			'mapDaily.usage.timeTitle' => '[Reading time and sky direction]',
			'mapDaily.usage.timeBody' => 'It shows the times today when each planet passes the 4 sky directions (angles)\nin the sky above your chosen reference point:\n\n· ASC (eastern horizon) — the moment a planet rises\n· MC  (overhead = zenith) — the moment a planet passes its highest point\n· DSC (western horizon) — the moment a planet sets\n· IC  (straight below = underground) — the moment a planet is on the far side of the Earth\n\nYou can read guidance on the time to act — "when a love theme moves," "when a turning point at work comes," and so on.',
			'mapDaily.usage.comboTitle' => '[Combining with the Map score bar]',
			'mapDaily.usage.comboBody' => 'The strength of the energy in each surface direction\ncan be checked from the Map\'s score bar (16 directions).\nThere\'s a detailed explanation in the i button under the "Total / Overall" label.\n\nCombine the score bar (the strength of surface directions) with\nthis screen (sky direction × time), and Solara works out\nthe best "direction × time" for the future you wish for.',
			'mapFortune.srcShort.combined' => 'Total',
			'mapFortune.srcShort.transit' => 'TR',
			'mapFortune.srcShort.progressed' => 'PR',
			'mapFortune.srcFull.combined' => 'Total',
			'mapFortune.srcFull.transit' => 'Transit',
			'mapFortune.srcFull.progressed' => 'Progressed',
			'mapFortune.header' => ({required Object src, required Object cat}) => '${src} / ${cat}',
			'mapFortune.legendTSoft' => 'T-soft',
			'mapFortune.legendTHard' => 'T-hard',
			'mapFortune.legendPSoft' => 'P-soft',
			'mapFortune.legendPHard' => 'P-hard',
			'mapFortune.catMeta.healing' => 'A theme of rest, recovery, and intuition',
			'mapFortune.catMeta.money' => 'A theme of flourishing, joy, and self-affirmation',
			'mapFortune.catMeta.love' => 'A theme of love, passion, and closeness',
			'mapFortune.catMeta.work' => 'A theme of responsibility, action, and growth',
			'mapFortune.catMeta.communication' => 'A theme of conveying, dialogue, and intellect',
			'mapFortune.usage.title' => 'How to use the Map',
			'mapFortune.usage.dirTitle' => '[Reading a direction]',
			'mapFortune.usage.dirBody' => 'Centered on your reference point (VIEWPOINT), it scores and shows the energy of each of the 16 surface directions\n(N, NNE, NE, ENE, E…).\nYou can judge "which land or direction to turn your attention toward."\n\nIt isn\'t only a display of which way to go.\nGoing toward a direction is, of course, one action you can take toward it. But there\'s also turning your attention there, calling out, placing a cherished item to match the direction as you leave home, being mindful of the direction you face when you speak, which seat you take in a shop and which way you turn, the direction you take a deep breath — you are free to decide.\nThrough the action you choose, the planets\' energy will reach you.\nThe planets are always watching over you, from a vast vantage point.\n\nTap the score bar to switch category\n(Overall → Healing → Abundance → Love → Work → Talk).\nChoose the category you want, and you\'ll see which directions that energy comes through most strongly.',
			'mapFortune.usage.regTitle' => '[Registering a reference point]',
			'mapFortune.usage.regPre' => 'You can register a reference point from the ',
			'mapFortune.usage.regPost' => ' (VIEWPOINT) button on the left of the map screen.\nShow the place you want at the center of the map, open the panel, and tap "Save this point" — that point is then saved as a VIEWPOINT.\n\nYou can switch between your saved reference points anytime, from the top of the search results or the dropdown inside the "Daily" chip in the bottom menu.',
			'mapFortune.usage.findTitle' => '[Finding a place]',
			'mapFortune.usage.findBody' => 'Search for shopping, a meeting spot, a shop, and so on from the search button, and you can check which planets that point is receiving energy from right now.',
			'mapFortune.usage.timeTitle' => '[Reading the time]',
			'mapFortune.usage.timeBody' => 'From the "Daily" chip in the bottom menu you can read "guidance on the time to act."\n* The "Daily" chip screen deals with "sky directions" (where and when a planet comes in the sky); it\'s separate from this Map\'s "surface directions" (which land to head toward).\n\nCombine the score bar (the strength of surface directions) with the "Daily" chip (sky direction × time), and Solara works out the best "direction × time" for the future you wish for.',
			'mapFortune.catPlanets.title' => 'Categories and their planets',
			'mapFortune.catPlanets.intro' => 'Each category extracts the aspects of its related planet pairs and scores them per direction, with pair weighting applied.\n(How the pair weighting works is explained in detail below.)',
			'mapFortune.catPlanets.weightTitle' => '[How pair weighting works]',
			'mapFortune.catPlanets.weightBody' => 'A category\'s score extracts the aspects of its related planet pairs and sums them, weighted by each pair\'s "centrality."\n\n· Lead pair (weight 2.0)\n　The planet pair that carries the category\'s central theme.\n　e.g. Love = Venus×Mars / Work = Saturn×Sun\n　→ when the aspect appears, it counts with 2× the influence.\n\n· Sub pair (weight 0.5)\n　An aspect where only one of the planets relates to the category.\n　e.g. for Love, "Venus×Jupiter" (only Venus carries love)\n　→ counts with a modest 0.5× influence.\n\n· Outside the pair (weight 0)\n　An aspect where neither planet relates to the category.\n　→ it isn\'t reflected in that category\'s score.\n\nThis "weighting" yields a precise score that reflects the category\'s "central theme."\nA plain sum without pair weights would blur each category\'s character, so we refine it with weighted calculation.',
			'mapFortune.catPlanets.overallTitle' => '[How it relates to Overall]',
			'mapFortune.catPlanets.overallBody' => 'When "Overall" is selected on the top score bar, the number is the straight sum of all planets and all aspects.\nNo category weighting is applied (= no pair weights).\n\nThe per-category views (Healing / Abundance / Love / Work / Talk), on the other hand, apply the pair weights above.\nAnd a single aspect can be counted in more than one category\n(e.g. Venus×Jupiter → counts for both Love and Abundance).\n\nSo "the plain sum of the 5 categories ≠ Overall."\nThe two are numbers for seeing energy from different angles; neither is more correct.\n· Per-category = see the category\'s "concentration"\n· Overall = see the "total volume"',
			'galaxy.todayMoon' => ({required Object name}) => 'Today\'s moon: ${name}',
			'galaxy.phaseDesc.newMoon' => 'A time of beginnings.\nThe sky is at its darkest, and the stars show clearest.\nA time to set a new intention and plant seeds.',
			'galaxy.phaseDesc.crescent' => 'A time of sprouting.\nA thin light appears in the western sky.\nA time to begin moving, little by little, toward the intention you planted at the new moon.',
			'galaxy.phaseDesc.firstQuarter' => 'A time to act.\nThe half-moon reaches the zenith; decision and action are called for.\nA turning point for shaping the intention that has sprouted.',
			'galaxy.phaseDesc.gibbous13' => 'A time of swelling.\nThe moon\'s waxing momentum nears its peak.\nA time when things fall into place and expression grows full.',
			'galaxy.phaseDesc.fullMoon' => 'A time of fulfillment and release.\nThe night the moon shines brightest.\nAwareness and completion arrive.\nA time to look again at what you hold, and give thanks.',
			'galaxy.phaseDesc.waningGibbous18' => 'A time of sharing.\nThe moon begins to wane.\nA time to share what you learned at the full moon with others.',
			'galaxy.phaseDesc.lastQuarter' => 'A time of letting go.\nA half-moon floats, turned the other way.\nA time to clear away what\'s no longer needed, and loosen your grip.',
			'galaxy.phaseDesc.waning26' => 'A time of rest.\nA faint moon lingers in the sky.\nA time to quietly set yourself in order for the next cycle.',
			'galaxy.phaseDesc.flowing' => 'The moon\'s cycle is flowing.',
			'galaxy.events.title' => 'About the moon events',
			'galaxy.events.intro' => 'Through this cycle, in step with the moon\'s waxing and waning,\nthree turning points come to you.',
			'galaxy.events.newTitle' => '🌑 New moon event',
			'galaxy.events.newBody' => 'The starting point — on the new moon, you set an "intention."\nYou put into words what you want to hold dear this cycle.\nEverything begins here.',
			'galaxy.events.fullTitle' => '🌕 Full moon event',
			'galaxy.events.fullBody' => 'On the full moon, a midway check-in on the intention you set (a look back).\n* It won\'t appear unless you set an intention at the new moon.',
			'galaxy.events.catTitle' => '✦ Catasterism event',
			'galaxy.events.catBody' => 'Arriving the day before the next new moon or later — the close of the cycle.\nA letting-go, and the forming of a constellation that is yours alone.\n* This, too, assumes you set an intention at the new moon.',
			'galaxy.events.notifyTitle' => '🔔 We recommend turning notifications on',
			'galaxy.events.notifyBody' => 'Each event visits on "that day" only.\nTurn notifications on in Sanctuary,\nand we\'ll let you know the morning of.\n\nThe full moon and catasterism assume a new-moon intention,\nso the main thing is not to miss the new moon.',
			'galaxy.guide.title' => 'What is the Galaxy screen?',
			'galaxy.guide.intro' => 'In step with the moon\'s cycle (about 29.5 days),\nyour daily tarot readings\nare recorded here as "stars."\n\nOne cycle = one constellation completed.\nThe rhythm of your inner life remains, in the shape of a constellation.',
			'galaxy.guide.cycleTitle' => '🌌 CYCLE tab (the current cycle)',
			'galaxy.guide.cycleBody' => 'Shows where you are now in this moon cycle.\nThe "dots" of your daily readings line up along a spiral,\nadvancing toward completion.\n\n· Top-right number: which day of the cycle (e.g. 23 of 30)\n· Top-left moon badge: today\'s phase (← you are here)\n· Drag to rotate in 3D\n· Tap a dot to see that day\'s reading\n· On new- and full-moon days, a special overlay\n　invites you to set or look back on your intention',
			'galaxy.guide.atlasTitle' => '🌟 Star Atlas tab (your past constellations)',
			'galaxy.guide.atlasBody' => 'A collection of completed past cycles (= constellations).\nEach one is a constellation your own inner life has woven.\n\n· Each card is a constellation woven from one cycle of readings\n· Tap a card to replay it + see details\n　(name, period, rarity)\n· Rarity: a 5-level star rating (★)\n　the higher the rarity, the rarer the combination that appeared',
			'galaxy.guide.meaningTitle' => 'What the moon cycle means',
			'galaxy.guide.meaningBody' => '🌑 New moon → a beginning. A time to plant seeds.\n🌕 Full moon → fulfillment and release. A time of awareness.\n\nOver one cycle, your inner life becomes a single constellation.\nDraw your daily card on the Tarot tab,\nand let it grow, slowly.',
			'forecast.error' => 'Couldn\'t fetch the forecast. Please check your network connection.',
			'forecast.pro5yrLabel' => 'The 5-year flow',
			'forecast.pro5yrDesc' => 'A 5-year heatmap — this year plus the years ahead — to take in the larger flow of your life.',
			'forecast.daysCount' => ({required Object n}) => '(${n} days)',
			'forecast.calculating' => 'Calculating the planets\' motion…',
			'forecast.noData' => 'No data',
			'forecast.displayPeriod' => 'Period',
			'forecast.yearBest' => 'Best of the year',
			'forecast.yearLabels.0' => 'This year',
			'forecast.yearLabels.1' => 'Next year',
			'forecast.yearLabels.2' => 'In 2 years',
			'forecast.yearLabels.3' => 'In 3 years',
			'forecast.yearLabels.4' => 'In 4 years',
			'forecast.plusYears' => ({required Object n}) => '+${n} yrs',
			'forecast.monthRange' => ({required Object fy, required Object fm, required Object ly, required Object lm}) => '${fy}/${fm} – ${ly}/${lm}',
			'forecast.heatmap1yr' => '1-year heatmap',
			'forecast.segRelative' => 'Relative',
			'forecast.segAbsolute' => 'Absolute',
			'forecast.segCategory' => 'Category',
			'forecast.highGreen' => '🟢↑high',
			'forecast.highRed' => '🔴↑high',
			'forecast.rankNth' => ({required Object n}) => '#${n}',
			'forecast.metricOverall' => 'Overall',
			'forecast.metricTopDir' => 'Rising direction',
			'forecast.metricDirScore' => 'Direction score',
			'forecast.categoryBy' => 'By category',
			'forecast.lastFetch' => ({required Object ts}) => 'Last fetched: ${ts}  /  monthly incremental updates',
			'forecast.legend.relLowRed' => 'red = year\'s low',
			'forecast.legend.relLowGreen' => 'green = year\'s low',
			'forecast.legend.relHighGreen' => 'green = year\'s high',
			'forecast.legend.relHighRed' => 'red = year\'s high',
			'forecast.legend.relRange' => ({required Object low, required Object high, required Object min, required Object max}) => '${low}  /  ${high}  (min: ${min} → max: ${max})',
			'forecast.legend.absLowRed' => 'red = 45 or below',
			'forecast.legend.absLowGreen' => 'green = 45 or below',
			'forecast.legend.absHighGreen' => 'green = 85 or above',
			'forecast.legend.absHighRed' => 'red = 85 or above',
			'forecast.legend.absScale' => ({required Object low, required Object high}) => '${low}  /  yellow = 65  /  ${high}  (fixed scale)',
			'forecast.legend.catRank' => ({required Object rank}) => 'color = category #${rank} / depth = score level',
			'forecast.usage.title' => 'How to use FORECAST',
			'forecast.usage.intro' => 'This shows the rhythm of your stars over the year ahead (365 days).\nYou can take in each day\'s overall and per-category scores at a glance,\nand see ahead of time which days move easily and which call for care.',
			'forecast.usage.s1Title' => '[1-year heatmap]',
			'forecast.usage.s1Body' => 'A 12-month × 31-day grid colors each day by its score.\nChange how it reads with the mode (relative / absolute /\ncategory), the color direction (🟢 high /\n🔴 high), and the rank (#1 / #2).\nSee the i button to the right of the heatmap for more.',
			'forecast.usage.s2Title' => '[Selected-day detail]',
			'forecast.usage.s2Body' => 'Tap a day on the heatmap and that day\'s directional score\nand per-category ranking appear below.',
			'forecast.usage.s3Title' => '[Your star cycles]',
			'forecast.usage.s3Body' => 'Shows each category\'s "seasons" (a season of connection /\nabundance / healing, and so on). Only ongoing stretches that\narrive from today onward. A compass for longer-term plans.',
			'forecast.usage.s4Title' => '[Highlights — Top 5]',
			'forecast.usage.s4Body' => 'Shows the top 5 days per category — for pinpointing\n"when to act" in the short term.',
			'forecast.usage.s5Title' => '[How this relates to the Map numbers]',
			'forecast.usage.s5Body' => 'The FORECAST numbers and the numbers on the Map for the same day\nwon\'t match — they\'re different calculations.\n\n· FORECAST = computed from your birth data alone.\n　Wherever you are on Earth, whatever the hour, it doesn\'t change —\n　it traces the energy flowing through you across a whole year.\n\n· Map = computed from where you are now + this very moment.\n　Because it includes the ASC (horizon) and MC (zenith),\n　the numbers change as the place changes, and even the same day\n　reads differently at 12:00 and 19:00\n　(the ASC moves about 15°/hour).\n\nNeither is right or wrong — they\'re two lenses reading the same you\nfrom different angles.\n· Use FORECAST to catch the "times that move easily,"\n· Use the Map to read "that place, that hour" in detail.\nUse them together that way.',
			'forecast.heatmapInfo.title' => 'How to read the 1-year heatmap',
			'forecast.heatmapInfo.s1Title' => '[Three color modes]',
			'forecast.heatmapInfo.s1Body' => '■ Relative mode (default)\nNormalized from the year\'s low → high.\nThe relatively higher days among your 365 show brighter.\nIt maximizes the day-to-day contrast.\n\n■ Absolute mode\nColors by the absolute score. Low values are dark,\nhigh values are bright. Use it when comparing across\nyears or with other people.\n\n■ Category mode\nColors each day by its strongest category:\n　🟢 Healing　🟡 Abundance　🩷 Love\n　🔵 Work　🟣 Talk\n\nA stretch of the same color is a time when that category\'s\n"wave" is rolling in.\n· 🩷 in a row → a season of connection (relational energy flows)\n· 🟡 in a row → a season of abundance\n· 🟢 in a row → a season of healing\n· 🔵 in a row → a season of work\n· 🟣 in a row → a season of expression\n\nThese "seasons" are also listed with start and end dates in the\n"Your star cycles" section below\n(only stretches of 7 days or more).',
			'forecast.heatmapInfo.s2Title' => '[Color direction (🟢 high / 🔴 high)]',
			'forecast.heatmapInfo.s2Body' => 'Active in "relative" and "absolute" modes.\n· 🟢 high: high score = green, low score = red\n· 🔴 high: high score = red, low score = green (inverted)\n\nTo avoid any good/bad verdict, you choose for yourself\nwhich color direction you want to see.',
			'forecast.heatmapInfo.s3Title' => '[Rank (#1 / #2)]',
			'forecast.heatmapInfo.s3Body' => 'Active in "category" mode.\n· #1: paints with the day\'s strongest category color\n· #2: paints with the second-strongest category color\n\nChecking both reveals the "lead" and the "support"\nwithin a single day.',
			'forecast.heatmapInfo.footer' => '* Even for the same day, this is a different measure from the number you\'d open on the Map\n(a calculation independent of place and time).\nFor details, see "How this relates to the Map numbers" under the ❓ button at the top.',
			'forecast.cycles.title' => 'Your star cycles',
			'forecast.cycles.hint' => 'Shows stretches arriving from today onward (7+ days running)',
			'forecast.cycles.empty' => 'No stretches arriving from today onward',
			'forecast.cycles.infoTitle' => 'What are star cycles?',
			'forecast.cycles.s1Title' => '[What it means]',
			'forecast.cycles.s1Body' => 'Over the year ahead, it shows the "stretches" where each category\'s\n(Love / Abundance / Healing /\nWork / Talk) energy flows strongly.\n\ne.g. "💗 Season of love 6/15 – 7/2 (18 days)"\n　 → from 6/15 to 7/2, relational energy\n　   runs strong without a break',
			'forecast.cycles.s2Title' => '[Conditions for showing]',
			'forecast.cycles.s2Body' => '· Only stretches arriving from today onward\n　(past stretches are hidden)\n· Counted as a "stretch" only when strong for 7+ days running\n　(short waves aren\'t shown)\n· One nearest entry per category',
			'forecast.cycles.s3Title' => '[How to use it]',
			'forecast.cycles.s3Body' => 'For longer-term "when to act" planning.\nCheck a specific day within the stretch on the Map screen,\nand you\'ll see the direction and timing at that place and hour.',
			'forecast.cycles.footer' => '* Even for the same stretch\'s score, this is a different measure from the number you\'d open on the Map\n(a calculation independent of place and time).\nFor details, see "How this relates to the Map numbers" under the ❓ button at the top.',
			'forecast.top5.title' => 'Highlights Top 5',
			'forecast.top5.year' => ({required Object year}) => '${year}',
			'forecast.top5.infoTitle' => 'How to read Highlights — Top 5',
			'forecast.top5.s1Title' => '[What it means]',
			'forecast.top5.s1Body' => 'Within the year shown (1/1–12/31), it shows the 5 days\nwhere the selected category scores highest.',
			'forecast.top5.s2Title' => '[Switching category]',
			'forecast.top5.s2Body' => 'Choose from Overall / Love / Abundance / Healing / Work / Talk.\nThe top 5 days for the chosen category appear.',
			'forecast.top5.s3Title' => '[Rank markers]',
			'forecast.top5.s3Body' => '👑 #1 / 🥈 #2 / 🥉 #3 / ⭐ #4 / ✨ #5',
			'forecast.top5.s4Title' => '[Reading a row]',
			'forecast.top5.s4Body' => 'Date — the selected category\'s score that day.\nTap to jump to the selected-day detail.\n(That day\'s rising direction is shown in the selected-day detail.)',
			'forecast.top5.s5Title' => '[How to use it]',
			'forecast.top5.s5Body' => 'For short-term, pinpoint "where to move" planning.\nThe #1 day especially is a day when moving on that\ncategory\'s theme lets its energy flow strongest.',
			'forecast.top5.footer' => '* Even for the same day, this is a different measure from the number you\'d open on the Map\n(a calculation independent of place and time).\nFor details, see "How this relates to the Map numbers" under the ❓ button at the top.',
			'consultHistory.title' => 'Consultation history',
			'consultHistory.deleteAll' => 'Delete all',
			'consultHistory.deleteAllTitle' => 'Delete everything?',
			'consultHistory.deleteAllBody' => 'All of your saved consultation records will be erased. This can\'t be undone.',
			'consultHistory.delete' => 'Delete',
			'consultHistory.deleteOneTitle' => 'Delete this record?',
			'consultHistory.filterAll' => 'All',
			'consultHistory.filterFav' => '★ Favorites',
			'consultHistory.emptyAll' => 'No consultation history yet',
			'consultHistory.emptyFav' => 'No favorites yet',
			'consultHistory.emptyAllHint' => 'Tap a place on the Map, or start a consultation from Daily Transit, and it\'ll be saved here.',
			'consultHistory.emptyFavHint' => 'Tap the ☆ on a record and it gathers here.',
			'consultHistory.withWhomPrefix' => ({required Object name}) => 'With: ${name}',
			'consultHistory.undecidedShort' => 'Undecided',
			'consultHistory.modeDaily' => 'Outing / Event',
			'consultHistory.fav' => 'Add to favorites',
			'consultHistory.unfav' => 'Remove from favorites',
			'consultCredit.signinTitle' => 'Sign-in required',
			'consultCredit.signinBody' => ({required Object provider}) => 'Buying credits requires signing in with ${provider}.\n\nOnce you sign in, your balance carries over even after you change or reinstall on a new device. The free features work without signing in.',
			'consultCredit.signinCta' => ({required Object provider}) => 'Sign in with ${provider}',
			'consultCredit.signinFailed' => 'Sign-in failed',
			'consultCredit.buyFailed' => 'The purchase didn\'t go through. Please try again in a little while.',
			'consultCredit.heading' => 'Stella consultation credits',
			'consultCredit.balanceFree' => ({required Object n}) => 'Free consultations this week: ${n} left',
			'consultCredit.balancePaid' => ({required Object n}) => ' · ${n} purchased left',
			'consultCredit.proUnlimited' => '✦ Cosmic Pro makes it unlimited →',
			'consultCredit.preparing' => 'Credits aren\'t on sale just yet.\nPlease check back a little later.',
			'consultCredit.fallbackProduct' => 'Credits',
			'consultPlacePicker.prompt' => 'Tap or search to choose a place',
			'consultPlacePicker.loading' => 'Loading…',
			'consultPlacePicker.selectedPoint' => 'Selected point',
			'consultPlacePicker.coordName' => ({required Object lat, required Object lng}) => 'Selected point (${lat}°, ${lng}°)',
			'consultPlacePicker.consultHere' => 'Consult about this place',
			'consultResult.title' => 'Consultation result',
			'consultResult.back' => 'Back',
			'consultResult.shareTooltip' => 'Share',
			'consultResult.connError' => 'We couldn\'t reach the connection just now. You can try again.',
			'consultResult.kindDirection' => 'Direction',
			'consultResult.kindPlace' => 'Place',
			'consultResult.noReading' => '(no reading)',
			'consultResult.viewOnMap' => 'View on the map',
			'consultResult.distanceFromHome' => ({required Object dir, required Object dist}) => '${dir} ~${dist} km',
			'consultResult.loading' => 'Stella is reading the stars…',
			'consultResult.retry' => 'Try again',
			'consultResult.voiceUnavailable' => 'Stella\'s voice didn\'t reach you just now',
			'consultResult.aboutReading' => 'About this reading',
			'consultResult.factorsTitle' => 'The astrological factors of this place',
			'consultResult.kmFactor' => ({required Object factor, required Object km}) => '  ${factor}: ~${km} km',
			'consultResult.distanceNote' => 'Distance doesn\'t decide whether an energy is present. The planets are immensely far away; a few hundred kilometers on the ground only change whether you\'re within range.',
			'consultResult.nearbyCount' => ({required Object n}) => ' (about ${n} nearby)',
			'consultResult.sparseHint' => ({required Object countText}) => 'There are few candidate places near here${countText}. Widening the radius or changing the direction makes them easier to find.',
			'consultResult.exhaust.allQuiet' => 'With these conditions, no place is strongly drawing you right now.',
			'consultResult.exhaust.noFresh' => 'No further new candidate places turned up.',
			'consultResult.exhaust.emptyPool' => 'No candidates were found within this range.',
			'consultResult.exhaust.fallback' => 'We didn\'t force any more candidates into being.',
			'consultResult.exhaust.tipsLead' => 'Changing the conditions might surface more:',
			'consultResult.exhaust.noCredit' => '* No credits were used for this notice.',
			'consultResult.suggest.widenRadius' => 'Widen the radius',
			'consultResult.suggest.bearing' => 'Search by direction',
			'consultResult.suggest.point' => 'Pick a specific place',
			'consultResult.suggest.world' => 'Open it up to the whole world',
			'consultResult.refreshLoading' => 'Looking for another place…',
			'consultResult.refresh' => 'See another candidate place',
			'consultResult.delta.open' => ({required Object m}) => 'See the change ${m} minutes later',
			'consultResult.delta.close' => ({required Object m}) => 'Close the change ${m} minutes later',
			'consultResult.delta.infoTitle' => 'About "the change 30 minutes later"',
			'consultResult.delta.infoBody' => ({required Object m}) => 'The star lines of astrocartography move moment by moment as the Earth turns.\nThe "angle lines"—where a planet sits directly overhead or on the horizon—travel about 7.5° in ${m} minutes: roughly 800 km westward at mid-latitudes.\n\nSo even in the same place, the lead of the moment can quietly change between the time you chose and ${m} minutes later. Mars\'s line drawing away, Venus\'s line drawing near—knowing that shift in advance lets you see how to use your time there: the heart of it early on, or warming toward the end.\n\nWe read this not as fortune, good or bad, but as a shift in the quality of the energy. You can see it when you set a time with Cosmic Pro · Outing.',
			'consultResult.delta.approaching' => 'drawing near',
			'consultResult.delta.entering' => 'moving in',
			'consultResult.delta.receding' => 'drawing away',
			'consultResult.delta.leaving' => 'moving out',
			'consultResult.delta.steady' => 'steady',
			'consultResult.delta.chip' => ({required Object planet, required Object angle, required Object label}) => '${planet} ${angle} · ${label}',
			'consultResult.interpNote' => 'The grounds for this candidate — its evidence — are shown at the top, under "Consultation result." Stella is sharing one way of reading them. If something feels off, lay your own interpretation alongside it. What you see here is one of many possible readings.',
			'consultResult.deltaInterpNote' => 'Stella shows this shift 30 minutes later as one interpretation, with the line movements above as its evidence. If anything feels off, widen the reading with your own sense of it. What you see here is no more than one interpretation among many.',
			'consultResult.pro.consultLabel' => 'Stella Consultation',
			'consultResult.pro.consultDesc' => 'With Cosmic Pro you can read it as many times as you like.',
			'consultResult.pro.migrationLabel' => 'Migration & travel consultations',
			'consultResult.pro.migrationDesc' => 'With Cosmic Pro, consultations beyond Outing / Event are unlimited too.',
			'consultResult.pro.refreshLabel' => 'Drawing fresh candidates',
			'consultResult.pro.refreshDesc' => 'Compare as many other candidates as you like.',
			'consultResult.pro.weeklyLabel' => 'Stella Consultation',
			'consultResult.pro.weeklyDesc' => 'You\'ve used up this week\'s free consultations. With Cosmic Pro it\'s unlimited, and reads more deeply with thinking.',
			'consultResult.block.proOnlyModeTitle' => 'This mode is part of Cosmic Pro',
			'consultResult.block.proOnlyModeBody' => 'Consultations beyond Outing / Event (migration & travel) can be read with Cosmic Pro.',
			'consultResult.block.proOnlyRefreshTitle' => 'Drawing fresh candidates is part of Cosmic Pro',
			'consultResult.block.proOnlyRefreshBody' => 'Compare as many other candidates as you like.',
			'consultResult.block.proWeeklyTitle' => 'You\'ve reached this week\'s Pro consultation limit',
			'consultResult.block.proWeeklyBody' => 'Cosmic Pro lets you consult Stella up to 100 times a week. It refills on Monday. To keep going right away, you can buy extra credits.',
			'consultResult.block.proSyncTitle' => 'Syncing your Pro status',
			'consultResult.block.proSyncBody' => 'We\'re re-checking your Cosmic Pro billing status with the store. No credits have been used. Please wait a moment, then try again.',
			'consultResult.block.exhaustedTitle' => 'You\'ve used up your consultation credits',
			'consultResult.block.exhaustedBody' => 'Free Stella consultations refill each week. To keep going right away, you can buy extra credits, or go unlimited with Cosmic Pro.',
			'consultResult.block.buyCredits' => 'Buy extra credits',
			'consultResult.block.goUnlimited' => '✦ Go unlimited with Cosmic Pro',
			'consultResult.block.seePro' => '✦ See Cosmic Pro',
			'consultResult.shareSheet.copyText' => 'Copy as text',
			'consultResult.shareSheet.copyTextSub' => 'Copy the consultation result, formatted, to the clipboard',
			'consultResult.shareSheet.shareImage' => 'Share as an image',
			'consultResult.shareSheet.shareImageSub' => 'Turn the result screen into a PNG and share it your usual way',
			'consultResult.shareSheet.copied' => 'Copied to the clipboard',
			'consultResult.shareSheet.failed' => ({required Object e}) => 'Sharing failed: ${e}',
			'consultResult.returnChip' => 'Back to consultation result',
			'consultStart.useProWeekly' => 'Use a Pro weekly credit',
			'consultStart.usePaid' => 'Use a paid credit',
			'consultStart.useCredit' => 'Use a credit',
			'consultStart.useFree' => 'Use a free credit',
			'consultStart.proWeeklyLabel' => 'Pro weekly credit',
			'consultStart.freeLabel' => 'Free credit',
			'consultStart.remaining' => ({required Object n, required Object limit}) => '${n} / ${limit} left',
			'consultStart.checkingRemaining' => 'Checking how many are left…',
			'consultStart.refillProMonday' => 'Refills every Monday (Cosmic Pro active)',
			'consultStart.refillMonday' => 'Refills every Monday',
			'consultStart.paidLabel' => 'Paid credit',
			'consultStart.paidRemaining' => ({required Object n}) => '${n} left',
			'consultStart.neverExpires' => 'Never expires (purchased credits stay even if you switch devices)',
			'consultStart.dontShowAgain' => 'Don\'t show this again',
			'consultStart.buyCredits' => 'Buy credits',
			'consultStart.start' => 'Start the consultation',
			'consultInput.screenTitle' => 'Stella Consultation',
			'consultInput.section.occasion' => 'What\'s the occasion?',
			'consultInput.section.when' => 'When?',
			'consultInput.section.timeBand' => 'Time of day (optional)',
			'consultInput.section.where' => 'Where?',
			'consultInput.section.radiusDaily' => 'Distance from your current residence',
			'consultInput.section.radiusBand' => 'Distance band from your current residence',
			'consultInput.section.region' => 'Region block',
			'consultInput.section.point' => 'Pick a place',
			'consultInput.section.theme' => 'Which theme shall we read?',
			'consultInput.section.whom' => 'With whom? (optional)',
			'consultInput.section.wish' => 'What do you hope for? / Your wish (optional)',
			'consultInput.proTimePick.label' => 'Setting the time for Outings + the 30-minute shift',
			'consultInput.proTimePick.desc' => 'Set the time you\'ll go in one-hour steps, and read how the flow of the place shifts 30 minutes later. CCG lines move as the Earth turns, so even in the same place the lead of the moment changes between the first and second half.',
			'consultInput.whomHint' => 'e.g. with my wife / on my own / with someone I like',
			'consultInput.wishHint' => 'The feeling you most want to hold onto right now, in a few words',
			'consultInput.whomExamples.love.0' => 'On my own',
			'consultInput.whomExamples.love.1' => 'With my partner',
			'consultInput.whomExamples.love.2' => 'With someone I like',
			'consultInput.whomExamples.money.0' => 'On my own',
			'consultInput.whomExamples.money.1' => 'With family',
			'consultInput.whomExamples.money.2' => 'With my partner',
			'consultInput.whomExamples.work.0' => 'On my own',
			'consultInput.whomExamples.work.1' => 'With a colleague',
			'consultInput.whomExamples.work.2' => 'With teammates',
			'consultInput.whomExamples.communication.0' => 'With a friend',
			'consultInput.whomExamples.communication.1' => 'With companions',
			'consultInput.whomExamples.communication.2' => 'On my own',
			'consultInput.whomExamples.healing.0' => 'On my own',
			'consultInput.whomExamples.healing.1' => 'With my partner',
			'consultInput.whomExamples.healing.2' => 'With family',
			'consultInput.whomExamples.newStart.0' => 'On my own',
			'consultInput.whomExamples.newStart.1' => 'With my partner',
			'consultInput.whomExamples.newStart.2' => 'With family',
			'consultInput.whomExamples.fallback.0' => 'On my own',
			'consultInput.whomExamples.fallback.1' => 'With my partner',
			'consultInput.whomExamples.fallback.2' => 'With a friend',
			'consultInput.whomExamples.fallback.3' => 'With family',
			'consultInput.wishExamples.love.0' => 'Deepen this bond',
			'consultInput.wishExamples.love.1' => 'Meet someone good',
			'consultInput.wishExamples.love.2' => 'Connect heart to heart',
			'consultInput.wishExamples.money.0' => 'Draw in abundance',
			'consultInput.wishExamples.money.1' => 'Build a foundation for work',
			'consultInput.wishExamples.money.2' => 'Live with stability',
			'consultInput.wishExamples.work.0' => 'Move forward at work',
			'consultInput.wishExamples.work.1' => 'Take on a new challenge',
			'consultInput.wishExamples.work.2' => 'Find a place I can focus',
			'consultInput.wishExamples.communication.0' => 'Widen my horizons',
			'consultInput.wishExamples.communication.1' => 'Deepen my learning',
			'consultInput.wishExamples.communication.2' => 'Find fresh inspiration',
			'consultInput.wishExamples.healing.0' => 'Rest my heart',
			'consultInput.wishExamples.healing.1' => 'Refresh my mood',
			'consultInput.wishExamples.healing.2' => 'Spend calm time',
			'consultInput.wishExamples.newStart.0' => 'Change the current',
			'consultInput.wishExamples.newStart.1' => 'Take a new step',
			'consultInput.wishExamples.newStart.2' => 'Begin anew',
			'consultInput.wishExamples.fallback.0' => 'Take a step forward',
			'consultInput.wishExamples.fallback.1' => 'Change the current',
			'consultInput.picker.searchHint' => 'Search by address / place name',
			'consultInput.picker.clearSearch' => 'Clear',
			'consultInput.picker.fromViewpoint' => '🔭 From your ViewPoints',
			'consultInput.picker.fromLocations' => '📍 From your saved Locations',
			'consultInput.picker.pickOnMap' => 'Pick on the map',
			'consultInput.picker.clearSelection' => 'Clear selection',
			'consultInput.theme.love' => 'Love & relationships',
			'consultInput.theme.money' => 'Abundance & money',
			'consultInput.theme.work' => 'Work & career',
			'consultInput.theme.communication' => 'Talk & learning',
			'consultInput.theme.healing' => 'Healing & rest',
			'consultInput.theme.newStart' => 'Change & new beginnings',
			'consultInput.mode.daily' => 'Outing /\nEvent',
			'consultInput.mode.travel' => 'Travel',
			'consultInput.mode.migration' => 'Migration',
			'consultInput.scope.point' => 'Specific place',
			'consultInput.scope.bearing' => 'Direction',
			'consultInput.scope.radius' => 'Radius from home',
			'consultInput.scope.region' => 'Region',
			'consultInput.scope.country' => 'Within my country',
			'consultInput.scope.world' => 'Worldwide',
			'consultInput.when.today' => 'Today',
			'consultInput.when.date' => 'Pick a date',
			'consultInput.when.specificDay' => 'A specific day',
			'consultInput.when.range' => 'Date range',
			'consultInput.when.undecided' => 'Timing undecided',
			'consultInput.when.within6mo' => 'Within 6 months',
			'consultInput.when.within1yr' => 'Within a year',
			'consultInput.when.in3yr' => 'Around 3 years',
			'consultInput.when.in5yrPlus' => '5+ years ahead',
			'consultInput.timeBand.morning' => 'Morning',
			'consultInput.timeBand.midday' => 'Midday',
			'consultInput.timeBand.evening' => 'Evening',
			'consultInput.timeBand.night' => 'Night',
			'consultInput.timeBand.lateNight' => 'Late night',
			'consultInput.hourPicker.title' => 'Set the time (hourly)',
			'consultInput.hourPicker.sub' => 'Reads the flow of the place at that time, and the change 30 minutes later',
			'consultInput.hourPicker.confirm' => ({required Object time}) => 'Set to ${time}',
			'consultInput.timeRowSelected' => ({required Object time}) => '${time} selected (you can see the changes 30 minutes later)',
			'consultInput.radiusBand' => ({required Object min, required Object max}) => '${min}–${max} km',
			'consultInput.radiusSingle' => ({required Object km}) => '${km} km',
			'consultInput.submit' => 'Start consultation',
			'consultInput.noHomeNote' => 'No current residence is set. "Direction," "Radius from home," and "Within my country" become available once you set your current residence. "Specific place" works right now.',
			'consultInput.presetCard' => ({required Object name}) => 'Looking at ${name}',
			'consultInput.introNote' => 'Choose when, where, and what you\'ll do, and Stella reads — clearly — what kind of energy works at that time and place, from a vast body of astrological data.',
			'consultInput.about.title' => 'What is Stella Consultation?',
			'consultInput.about.intro' => 'Just choose "when, where, and what you\'ll do." Solara lays a planet-scale star map over that plan and reads the energy that works on you at that time and place — it\'s the heart of Solara.\nThe vast celestial calculations an astrologer would normally take a long time to read, Stella performs in an instant, and hands to you in words that stay close to you rather than in technical jargon.',
			'consultInput.about.bullets' => '• It maps "where and what you do, and what effect it draws out," in the light of your wish.\n• No good/bad verdicts, no rankings. Rather than "good/bad," it tells you what quality of flow it is — a quality that gives you a push, or one that invites you to face something.\n• Outings, travel, migration — to match the scale. With Cosmic Pro you can set the time in one-hour steps, and even read how the flow of a place shifts 30 minutes later.',
			'consultInput.about.dataTitle' => 'The data Stella Consultation reads',
			'consultInput.about.dataIntro' => 'Solara\'s star-line calculation is 10 planets × 4 angles (ASC · MC · DSC · IC) × 3 aspects (conjunction · square · trine / sextile) = 120 lines per frame. It layers several frames and calculates latitude bands, the 12 houses, and progressions.',
			'consultInput.about.freeHead' => '— Even with Outing / Event (Free), it goes this far —',
			'consultInput.about.freeList' => '• The 10 planets of the birth chart (natal) / the 10 transiting planets of today\n• Astrocartography (Astro*Carto*Graphy / the lines of your birth)\n• Cyclocartography (Cyclo*Carto*Graphy / the moving lines of this very moment)\n• All aspect lines — conjunction, square, trine, sextile (theme planets × 4 angles × 3 aspects)\n• Zenith and nadir bands (latitude energy bands)\n• Relocation for that land (the reshuffling of ASC / MC / the 12 houses + which house each theme planet falls in)\n• Inner seasons (the progressed Moon and Sun, the turning points of the solar arc) / local timing (the times planets cross the angles)\n…Stella overlays all of this across candidate points worldwide and maps the places and directions that resonate with your wish.',
			'consultInput.about.proHead' => '— With Cosmic Pro, further —',
			'consultInput.about.proList' => '• Migration scale = the lifelong, unchanging natal ACG + the life-chapters of progression\n• Travel scale = the moving lines for each travel day (sampling several days of the period)\n• Set the time in one-hour steps → even how the lines move 30 minutes later',
			'consultInput.about.devHead' => '— From the maker of Solara —',
			'consultInput.about.devBody' => 'This level of detail is possible because I — someone who has practiced astrology myself — handle everything directly, from design to development. Rather than asking someone else to "please read it this way here," an astrologer gives it form directly; so the meaning of the stars can dwell in every small detail. May this star map stay close beside your every day.',
			'mapAcg.pillRelocate' => 'Relocate',
			'mapAcg.pillAspect' => 'Aspect',
			'mapAcg.sub.zenith' => 'Zenith',
			'mapAcg.sub.nadir' => 'Nadir',
			'mapAcg.sub.zenithBand' => 'Zenith band',
			'mapAcg.sub.nadirBand' => 'Nadir band',
			'mapAcg.frameLabel.transit' => 'TRANSIT — planetary positions this very moment',
			'mapAcg.frameLabel.progressed' => 'PROGRESSED — secondary progression (1 day = 1 year)',
			'mapAcg.frameLabel.solarArc' => 'SOLAR ARC — all planets shifted by the solar arc',
			'mapAcg.consultHere' => 'Consult about this place',
			'mapAcg.guide.title' => 'How to use ASTRO*CARTO*GRAPHY / CYCLO*CARTO*GRAPHY',
			'mapAcg.guide.jimLewis' => '— The celestial map upon the Earth, left to us by Jim Lewis —',
			'mapAcg.guide.acgHead' => '[What is ACG (AstroCartoGraphy)?]',
			'mapAcg.guide.acgBody' => 'A method systematized by the astrologer Jim Lewis in the 1970s.\nIt projects the planetary positions at your birth as "lines" on a world map,\nshowing which planet rises in which land\n(a map that never changes throughout your life).',
			'mapAcg.guide.ccgHead' => '[What is CCG (CycloCartoGraphy)?]',
			'mapAcg.guide.ccgBody' => 'An evolution Jim Lewis systematized in 1982 as a sequel to ACG.\nInstead of your birth moment, it projects the planetary positions of "this very moment" or a time you specify. The lines move with Earth\'s rotation,\nand the starscape rewrites itself moment by moment.\nSolara\'s Transit / Prog / S.Arc frames\ncorrespond to this CCG.',
			'mapAcg.guide.framesHead' => '[The 4 frames (top pills, all free)]',
			'mapAcg.guide.framesBody' => '• Natal … positions at birth (ACG, unchanging for life)\n• Transit / Prog / S.Arc … positions that move with time (CCG)\n\nThe i button beside each pill has a detailed explanation of each.',
			'mapAcg.guide.linesHead' => '[Lines & markers on the map]',
			'mapAcg.guide.linesBody' => 'Shows planet × angle lines and zenith / nadir markers.\nTap a line or marker to see the meaning of that point\nand a message specific to the planet.\nThe i button beside each pill (angle / zenith / nadir)\nhas a detailed explanation.',
			'mapAcg.guide.proHead' => '[Pro features]',
			'mapAcg.guide.proBody' => '• Aspect lines (120): adds square / trine / sextile\n　to the main lines\n• Relocate: treat the tapped point as a relocation destination and\n　compare the moving star lines, ASC/MC, and houses\n• Zenith band / Nadir band: Lewis-style band display that applies around the whole latitude\n\nAll are unlocked with Cosmic Pro.',
			'mapAcg.guide.usageHead' => '[How to make use of it]',
			'mapAcg.guide.usageBody' => 'For choosing destinations for travel, moving, or business trips.\nEven the same action flows with different energy depending on the land. Layer on the 16-direction scores (the directional-energy fan), and "where" and "when" rise together upon the map and the clock.',
			'mapVp.slotDefaults.0' => 'Workplace',
			'mapVp.slotDefaults.1' => 'Favorite',
			'mapVp.slotDefaults.2' => 'Spot',
			'mapVp.slotDefaults.3' => 'Place',
			'mapVp.slotFallback' => 'Spot',
			'mapVp.saveLimitFree' => ({required Object free, required Object pro}) => 'You can save up to ${free} places.\nWith Cosmic Pro, you can save up to ${pro}.',
			'mapVp.saveLimitFull' => ({required Object max}) => 'You can save up to ${max} places.\nPlease delete a place you no longer need before adding another.',
			'mapVp.savedSlots' => 'Saved slots',
			'mapVp.registeredPlaces' => 'Registered places',
			'mapVp.noSlots' => '(no slots)',
			'mapVp.moveToCurrent' => 'Go to current location',
			'mapVp.saveThisPoint' => 'Save this point',
			'mapVp.registerThisPoint' => 'Register this point',
			'mapVp.subMoveUp' => 'Move up',
			'mapVp.subMoveDown' => 'Move down',
			'mapVp.subChangeIcon' => 'Change icon',
			'mapVp.subRename' => 'Rename',
			'mapVp.subDelete' => 'Delete',
			'mapVp.iconPickerTitle' => 'Choose an icon',
			'mapVp.help.title' => 'VIEWPOINT and LOCATIONS',
			'mapVp.help.vpHead' => '[📍 VIEWPOINT]',
			'mapVp.help.vpBody' => 'The reference point (observation point) for calculating directional scores.\nThe map draws how each planet\'s energy descends across the 16 directions as seen from here.\n\nIt\'s used in the dropdown at the top of the search-results list, and in the VIEWPOINT switcher on the Daily chip screen.',
			'mapVp.help.locHead' => '[🌐 LOCATIONS]',
			'mapVp.help.locBody' => 'Points shown as markers on the map\n(a list of places you visit often).\nOnce registered, the marker stays on the map,\nso you can see how places relate to each other at a glance.\n\nTapping the "LOCATIONS" tile button at the bottom\nof the Map screen lets you see, in a list,\nthe energy scores of your LOCATIONS (registered places)\nas viewed from the VIEWPOINT.\nRegister the places you visit often, and you\'ll see\nthings like "this park has a high Healing score today" or\n"this café has a high Love score today" —\na handy way to see how strong today\'s energy is\nat each registered place.',
			'mapVp.help.usageTitle' => 'How to use',
			'mapVp.help.registerHead' => '[Saving]',
			'mapVp.help.registerBody' => 'Both VIEWPOINT and LOCATIONS can hold up to 5 entries each\n(including your home 🏠).\nYour home is placed in the first slot automatically from your profile,\nso you can add up to 4 more.\n\nShow the place you want to save at the center of the map,\nthen tap "Save this point" on the VIEWPOINT tab,\nor "Register this point" on the LOCATIONS tab,\nto save it to the current tab.',
			'mapVp.help.iconNameHead' => '[Change icon / name]',
			'mapVp.help.iconNameBody' => 'From the ⋯ button at the right of each slot, open the submenu\nto change the name and the icon.\nYou can choose from 32 icons.',
			'mapVp.help.reorderHead' => '[Reorder]',
			'mapVp.help.reorderBody' => 'Also in the ⋯ menu, use ↑ ↓ to reorder.\nSlots higher up appear earlier in the list.\n(Your home 🏠 is fixed at the top and can\'t be moved or deleted.)',
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
			'mapMenu.popup.relocateBody' => 'Treats the point you tap on the map as a relocation destination. You can check, all together: (1) which planets\' lines move closer or farther compared with your current residence, (2) the sign changes of ASC / MC, and (3) the 12-house transitions of the 10 planets. Cosmic Pro only.',
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
			'locations.currentAddress' => 'Current residence',
			'locations.mapCenter' => 'Map center',
			'locations.renameTitle' => 'Enter a name for this place',
			'locations.cancel' => 'Cancel',
			'locations.bearing' => ({required Object dir}) => '${dir}',
			'locations.emptyTitle' => 'No places saved yet',
			'locations.addCurrent' => '📍 Save current location',
			_ => null,
		} ?? switch (path) {
			'locations.menuRename' => '✏ Rename',
			'locations.menuDelete' => '🗑 Delete',
			'locations.guide.title' => 'How to use LOCATIONS',
			'locations.guide.intro' => 'See, at a glance, the energy of your LOCATIONS (saved places)\nas viewed from the VIEWPOINT (your chosen center point) you registered.\nSave the places you care about as LOCATIONS,\nand you can read today\'s energy for each at a glance.\n\nRegister the places you visit often, and you\'ll see\nthings like "this park has a high Healing score today" or\n"this café has a high Love score today" —\na handy way to see how strong today\'s energy is\nat each saved place.',
			'locations.guide.dateTimeHead' => '[Date & time]',
			'locations.guide.dateTimeBody' => 'Change the "date" and "time" at the top to recalculate\nthe scores for that moment. The "Back to today" button\nreturns you to the present.',
			'locations.guide.viewpointHead' => '[Switch VIEWPOINT]',
			'locations.guide.viewpointBody' => 'The "VIEWPOINT" dropdown switches the reference point for\ndistance and direction scores.\nYou can choose the map center (current location), your current residence,\nor a VIEWPOINT you\'ve saved.',
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
			'paywall.signinBody' => ({required Object provider}) => 'Signing in with ${provider} is required to use Cosmic Pro.\n\nOnce you sign in, your purchases carry over even after changing or reinstalling on a device. Free features can be used without signing in.',
			'paywall.purchaseVerifyFailed' => 'Your purchase completed, but entitlement verification failed. Please wait a moment and try "Restore purchases".',
			'paywall.purchaseError' => ({required Object e}) => 'An error occurred during the process.\n${e}',
			'paywall.restoreErrorMsg' => ({required Object e}) => 'An error occurred while restoring.\n${e}',
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
			'appSettings.language' => 'Language',
			'appSettings.langTitle' => 'Select language',
			'appSettings.fontSize' => 'Text size',
			'appSettings.fontSizeTitle' => 'Text size',
			'appSettings.fontStandard' => 'Standard',
			'appSettings.fontLarge' => 'Large',
			'appSettings.fontMax' => 'Largest',
			'appSettings.fontCaveat' => 'Larger sizes may cause text and icons to overlap or become harder to read on some screens, such as Map and Galaxy.',
			'aiConsent.subtitle' => 'Your Astrolabe for When & Where',
			'aiConsent.agree' => 'Agree and Begin',
			'aiConsent.decline' => 'Decline',
			'aiConsent.back' => 'Back',
			'aiConsent.linkOpenFailed' => ({required Object url}) => 'Couldn\'t open the link: ${url}',
			'aiConsent.declineDialog.title' => 'Consent is required to use Solara',
			'aiConsent.declineDialog.body' => 'To use Solara, you\'ll need to agree to the items described above. Without your consent, the app can\'t be used.\n\nPlease take another look, or feel free to uninstall Solara. At this point we have not received any of your data, including any personal information, so you can uninstall with complete peace of mind.',
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
			'aiConsent.consentHandling.body' => 'When you tap "Agree and Begin," the fact that you agreed to the items described above is recorded on your device. It won\'t be shown again. (If the terms change, we may show this notice once more.)\n\nIf you do not agree, please tap "Decline" at the bottom of the screen and uninstall Solara. At this point, we have not received any of your data, including any personal information.',
			_ => null,
		};
	}
}

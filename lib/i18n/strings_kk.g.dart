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
class TranslationsKk extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsKk({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.kk,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <kk>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsKk _root = this; // ignore: unused_field

	@override 
	TranslationsKk $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsKk(meta: meta ?? this.$meta);

	// Translations
	@override String get appName => 'Рикошырыш';
	@override late final _Translations$homePage$kk homePage = _Translations$homePage$kk._(_root);
	@override late final _Translations$playPage$kk playPage = _Translations$playPage$kk._(_root);
	@override late final _Translations$settingsPage$kk settingsPage = _Translations$settingsPage$kk._(_root);
	@override late final _Translations$gameOverPage$kk gameOverPage = _Translations$gameOverPage$kk._(_root);
	@override late final _Translations$restartGameDialog$kk restartGameDialog = _Translations$restartGameDialog$kk._(_root);
	@override late final _Translations$tutorialPage$kk tutorialPage = _Translations$tutorialPage$kk._(_root);
	@override late final _Translations$shopPage$kk shopPage = _Translations$shopPage$kk._(_root);
}

// Path: homePage
class _Translations$homePage$kk extends Translations$homePage$en {
	_Translations$homePage$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get playButton => 'Ойнау';
	@override String get settingsButton => 'Баптау';
	@override String get tutorialButton => 'Нұсқаулық';
	@override String get shopButton => 'дүкен';
}

// Path: playPage
class _Translations$playPage$kk extends Translations$playPage$en {
	_Translations$playPage$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String highScore({required Object p}) => 'Үздік: ${p}';
	@override String get coins => 'Монеталар';
	@override String get undo => 'Қозғалысты болдырмау';
}

// Path: settingsPage
class _Translations$settingsPage$kk extends Translations$settingsPage$en {
	_Translations$settingsPage$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Баптау';
	@override String get appInfo => 'Қолданба ақпары';
	@override String licenseNotice({required Object buildYear}) => 'Ricochlime  Copyright (C) 2023-${buildYear}  Adil Hanney\nБұл бағдарлама еш кепілдіксіз жеткізіледі. Ол еркін екенін ескере отырып, сіз оны кейбір шарттардың аясында еркін тарата аласыз.';
	@override String get bgmVolume => 'Музыканың дыбыс деңгейі';
	@override String get sfxVolume => 'Дыбыс әсерлерінің көлемі';
	@override String get showFpsCounter => 'FPS есептегішін көрсету';
	@override String get stylizedPageTransitions => 'Стильденген беттердің ауысуы';
	@override String get hyperlegibleFont => 'Оқуға оңай шрифт';
	@override String get biggerBullets => 'Үлкенірек оқтар';
	@override String get gameplay => 'Ойын барысы';
	@override String get accessibility => 'Қол жетімділік';
	@override String get maxFps => 'Максималды FPS';
	@override String get showUndoButton => 'Қозғалысты қайтаруға рұқсат беріңіз';
}

// Path: gameOverPage
class _Translations$gameOverPage$kk extends Translations$gameOverPage$en {
	_Translations$gameOverPage$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ойын бітті!';
	@override String highScoreNotBeaten({required Object p}) => '${p} ұпай жинадыңыз!';
	@override TextSpan highScoreBeaten({required InlineSpan pOld, required InlineSpan pNew}) => TextSpan(children: [
		const TextSpan(text: 'Енді үздік нәтижеңіз '),
		pOld,
		const TextSpan(text: ' '),
		pNew,
		const TextSpan(text: ' ұпай!'),
	]);
	@override String get restartGameButton => 'Жаңадан бастау';
	@override String get homeButton => 'Мәзір';
	@override String get continueWithCoins => 'Жалғастыру үшін 100';
}

// Path: restartGameDialog
class _Translations$restartGameDialog$kk extends Translations$restartGameDialog$en {
	_Translations$restartGameDialog$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ойынды қайта бастау керек пе?';
	@override String get areYouSure => 'Қайта іске қосқыңыз келетініне сенімдісіз бе? Мұны қайтара алмайсыз';
	@override String get waitCancel => 'Күте тұрыңыз, бас тартыңыз!';
	@override String get yesImSure => 'Иә мен сенімдімін!';
}

// Path: tutorialPage
class _Translations$tutorialPage$kk extends Translations$tutorialPage$en {
	_Translations$tutorialPage$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get tutorial => 'Нұсқаулық';
	@override String get bounceOffWalls => 'Қабырғадан ыршыған оқ көбірек шырышқа тие алады.';
	@override String get tapSpeedUp => 'Оқ қозғалысын тездету үшін экранды түртіңіз.';
	@override String get dragAndRelease => 'Мақсатқа апару және ату үшін босату арқылы құбыжықтарды жеңіңіз.';
	@override String get goldMonsters => 'Алтын құбыжықты жеңгеннен кейін сіз тиын аласыз.';
	@override String get greenMonsters => 'Жасыл құбыжықты жеңгеннен кейін сіз қосымша оқ аласыз.';
	@override String get skullLine => 'Бас сүйегінің сызығына жеткен құбыжық келесі кезекте оны жеңбесеңіз, ойын аяқталды дегенді білдіреді.';
	@override String get useCoinsInShop => 'Дүкенде жаңа заттардың құлпын ашу үшін тиындарды сақтаңыз...';
	@override String get orUseCoinsToContinue => '...немесе оларды ойын аяқталғаннан кейін жалғастыру үшін пайдаланыңыз.';
	@override String get moreMonsters => 'Сіз ілгерілеген сайын құбыжықтардың көбірек қатарлары пайда болады, сондықтан қауіпті аймақ ұлғаяды.';
}

// Path: shopPage
class _Translations$shopPage$kk extends Translations$shopPage$en {
	_Translations$shopPage$kk._(TranslationsKk root) : this._root = root, super.internal(root);

	final TranslationsKk _root; // ignore: unused_field

	// Translations
	@override String get buy5000Coins => '5000 тиын сатып алыңыз';
	@override String get buy1000Coins => '1000 тиын сатып алыңыз';
	@override String get restorePurchases => 'Сатып алуларды қалпына келтіріңіз';
	@override String get premium => 'Премиум';
	@override String get bulletShapes => 'Оқ пішіндері';
	@override String get bulletColors => 'Оқ түсті';
	@override String get title => 'дүкен';
}

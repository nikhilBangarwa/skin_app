import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
  ];

  late Map<String, String> _localizedStrings;

  Future<bool> load() async {
    try {
      String jsonString = await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });
      return true;
    } catch (e) {
      _localizedStrings = {};
      return false;
    }
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Type-safe translation getters mapped to JSON keys
  String get appName => translate('appName');
  String get splashTagline => translate('splashTagline');
  String get welcomeTitle => translate('welcomeTitle');
  String get welcomeSubtitle => translate('welcomeSubtitle');
  String get continueButton => translate('continueButton');
  String get readyToScan => translate('readyToScan');
  String get analyzeYourSkin => translate('analyzeYourSkin');
  String get heroDescription => translate('heroDescription');
  String get startScan => translate('startScan');
  String get streakLabel => translate('streakLabel');
  String get daysSuffix => translate('daysSuffix');
  String get improvementLabel => translate('improvementLabel');
  String get ptsSuffix => translate('ptsSuffix');
  String get overviewMetrics => translate('overviewMetrics');
  String get viewAll => translate('viewAll');
  String get settingsTitle => translate('settingsTitle');
  String get themeSettings => translate('themeSettings');
  String get languageSettings => translate('languageSettings');
  String get notificationsSettings => translate('notificationsSettings');
  String get privacyPolicy => translate('privacyPolicy');
  String get termsConditions => translate('termsConditions');
  String get selectLanguageTitle => translate('selectLanguageTitle');
  String get selectLanguageSubtitle => translate('selectLanguageSubtitle');
  String get notificationPermissionTitle => translate('notificationPermissionTitle');
  String get notificationPermissionSubtitle => translate('notificationPermissionSubtitle');
  String get allowNotifications => translate('allowNotifications');
  String get notNow => translate('notNow');
  String get noFaceDetected => translate('noFaceDetected');
  String get multipleFacesDetected => translate('multipleFacesDetected');
  String get faceNotCentered => translate('faceNotCentered');
  String get imageTooDark => translate('imageTooDark');
  String get faceTooFar => translate('faceTooFar');
  String get blurryImage => translate('blurryImage');
  String get calibrating => translate('calibrating');
  String get routineMorning => translate('routineMorning');
  String get routineNight => translate('routineNight');
  String get savePdf => translate('savePdf');
  String get reScan => translate('reScan');
  String get login => translate('login');
  String get signup => translate('signup');
  String get email => translate('email');
  String get password => translate('password');
  String get confirmPassword => translate('confirmPassword');
  String get forgotPassword => translate('forgotPassword');
  String get continueWithGoogle => translate('continueWithGoogle');
  String get or => translate('or');
  String get loginSubtitle => translate('loginSubtitle');
  String get welcomeBack => translate('welcomeBack');
  String get welcomeBackSubtitle => translate('welcomeBackSubtitle');
  String get noAccountText => translate('noAccountText');
  String get haveAccountText => translate('haveAccountText');
  String get emailError => translate('emailError');
  String get emailValidError => translate('emailValidError');
  String get passwordError => translate('passwordError');
  String get passwordLengthError => translate('passwordLengthError');
  String get confirmPasswordError => translate('confirmPasswordError');
  String get passwordsMatchError => translate('passwordsMatchError');
  String get poweredBy => translate('poweredBy');
  String get step1Text => translate('step1Text');
  String get step2Text => translate('step2Text');
  String get step3Text => translate('step3Text');
  String get step4Text => translate('step4Text');
  String get step1Title => translate('step1Title');
  String get step2Title => translate('step2Title');
  String get step3Title => translate('step3Title');
  String get step4Title => translate('step4Title');
  String get enterName => translate('enterName');
  String get enterAge => translate('enterAge');
  String get selectGender => translate('selectGender');
  String get genderMale => translate('genderMale');
  String get genderFemale => translate('genderFemale');
  String get genderOther => translate('genderOther');
  String get skinTypeDry => translate('skinTypeDry');
  String get skinTypeDryDesc => translate('skinTypeDryDesc');
  String get skinTypeOily => translate('skinTypeOily');
  String get skinTypeOilyDesc => translate('skinTypeOilyDesc');
  String get skinTypeCombination => translate('skinTypeCombination');
  String get skinTypeCombinationDesc => translate('skinTypeCombinationDesc');
  String get skinTypeNormal => translate('skinTypeNormal');
  String get skinTypeNormalDesc => translate('skinTypeNormalDesc');
  String get concernDullness => translate('concernDullness');
  String get concernAcne => translate('concernAcne');
  String get concernWrinkles => translate('concernWrinkles');
  String get concernRedness => translate('concernRedness');
  String get concernDarkCircles => translate('concernDarkCircles');
  String get concernPores => translate('concernPores');
  String get concernSensitivity => translate('concernSensitivity');
  String get concernUnevenTone => translate('concernUnevenTone');
  String get calibrationTitle => translate('calibrationTitle');
  String get lastScan => translate('lastScan');
  String get skinProgress => translate('skinProgress');
  String get hydration => translate('hydration');
  String get yourSkinProfile => translate('yourSkinProfile');
  String get smartInsights => translate('smartInsights');
  String get uvAlertTitle => translate('uvAlertTitle');
  String get uvAlertDesc => translate('uvAlertDesc');
  String get hydrationReminderTitle => translate('hydrationReminderTitle');
  String get hydrationReminderDesc => translate('hydrationReminderDesc');
  String get totalScans => translate('totalScans');
  String get avgScore => translate('avgScore');
  String get bestScore => translate('bestScore');
  String get exportData => translate('exportData');
  String get deleteAccount => translate('deleteAccount');
  String get signOut => translate('signOut');
  String get appSettings => translate('appSettings');
  String get moveCloser => translate('moveCloser');
  String get moveBack => translate('moveBack');
  String get centerFace => translate('centerFace');
  String get increaseLighting => translate('increaseLighting');
  String get aiCalibrating => translate('aiCalibrating');
  String get profileCreated => translate('profileCreated');
  String get preferencesSaved => translate('preferencesSaved');
  String get aiCalibrationComplete => translate('aiCalibrationComplete');
  String get healthy => translate('healthy');
  String get improving => translate('improving');
  String get needsAttention => translate('needsAttention');
  String get highConcern => translate('highConcern');
  String get aiSummaryTitle => translate('aiSummaryTitle');
  String get dailyRoutine => translate('dailyRoutine');
  String get morningRoutine => translate('morningRoutine');
  String get nightRoutine => translate('nightRoutine');
  String get savePdfReport => translate('savePdfReport');
  String get reScanButton => translate('reScanButton');
  String get save => translate('save');
  String get back => translate('back');
  String get getStarted => translate('getStarted');
  String get almostThere => translate('almostThere');
  String get reviewProfileSub => translate('reviewProfileSub');
  String get profileSummary => translate('profileSummary');
  String get aiAlgorithm => translate('aiAlgorithm');
  String get calibratingProfile => translate('calibratingProfile');
  String get calibrationDesc => translate('calibrationDesc');
  String get genderIdentity => translate('genderIdentity');
  String get preferredName => translate('preferredName');
  String get ageLabel => translate('ageLabel');
  String get selectSkinTypeTitle => translate('selectSkinTypeTitle');
  String get selectSkinTypeSubtitle => translate('selectSkinTypeSubtitle');
  String get selectConcernsTitle => translate('selectConcernsTitle');
  String get selectConcernsSubtitle => translate('selectConcernsSubtitle');
  String get home => translate('home');
  String get history => translate('history');
  String get scan => translate('scan');
  String get insights => translate('insights');
  String get profile => translate('profile');
  String get completed => translate('completed');
  String get noScansYet => translate('noScansYet');
  String get noScansYetDesc => translate('noScansYetDesc');
  String get startFirstScan => translate('startFirstScan');
  String get scanReportsHistory => translate('scanReportsHistory');
  String get exportNoRecords => translate('exportNoRecords');
  String get exportSuccess => translate('exportSuccess');
  String get exportError => translate('exportError');
  String get deleteAccountConfirmTitle => translate('deleteAccountConfirmTitle');
  String get deleteAccountConfirmDesc => translate('deleteAccountConfirmDesc');
  String get deleteAccountConfirmButton => translate('deleteAccountConfirmButton');
  String get deleteAccountError => translate('deleteAccountError');
  String get scanYourFace => translate('scanYourFace');
  String get scanSubtitle => translate('scanSubtitle');
  String get imageSelected => translate('imageSelected');
  String get positionFace => translate('positionFace');
  String get cameraOffline => translate('cameraOffline');
  String get tipsTitle => translate('tipsTitle');
  String get tipLighting => translate('tipLighting');
  String get tipCentered => translate('tipCentered');
  String get tipNoFilters => translate('tipNoFilters');
  String get tipNoGlasses => translate('tipNoGlasses');
  String get gallery => translate('gallery');
  String get flip => translate('flip');
  String get stepQuality => translate('stepQuality');
  String get stepStructure => translate('stepStructure');
  String get stepMarkers => translate('stepMarkers');
  String get stepReport => translate('stepReport');
  String get runningDiagnostics => translate('runningDiagnostics');
  String get diagnosticsSubtitle => translate('diagnosticsSubtitle');
  String get validationFailedTitle => translate('validationFailedTitle');
  String get tryAgainButton => translate('tryAgainButton');
  String get unableToAnalyzeFormat => translate('unableToAnalyzeFormat');
  String get imageTooDarkError => translate('imageTooDarkError');
  String get imageTooBrightError => translate('imageTooBrightError');
  String get imageBlurryError => translate('imageBlurryError');
  String get errorProcessingImage => translate('errorProcessingImage');
  String get summaryExcellent => translate('summaryExcellent');
  String get summaryGood => translate('summaryGood');
  String get summaryAttention => translate('summaryAttention');
  String get indicatorAcneDesc => translate('indicatorAcneDesc');
  String get indicatorDarkCirclesDesc => translate('indicatorDarkCirclesDesc');
  String get indicatorPigmentationDesc => translate('indicatorPigmentationDesc');
  String get indicatorRednessDesc => translate('indicatorRednessDesc');
  String get indicatorTextureDesc => translate('indicatorTextureDesc');
  String get scanResults => translate('scanResults');
  String get aiAnalysisReport => translate('aiAnalysisReport');
  String get skinScoreIndicator => translate('skinScoreIndicator');
  String get beforeVsAfterTrend => translate('beforeVsAfterTrend');
  String get initialBaselineReport => translate('initialBaselineReport');
  String get trendComparison => translate('trendComparison');
  String get indicatorSeverityDetails => translate('indicatorSeverityDetails');
  String get analyzedCount => translate('analyzedCount');
  String get primaryConcernsMapped => translate('primaryConcernsMapped');
  String get severityDetailPrefix => translate('severityDetailPrefix');
  String get dailyRoutineSuggestions => translate('dailyRoutineSuggestions');
  String get scanAgain => translate('scanAgain');
  String get saveReport => translate('saveReport');
  String get reportSaved => translate('reportSaved');
  String get addedToHistory => translate('addedToHistory');
  String get unableToGeneratePdf => translate('unableToGeneratePdf');
  String get unableToSaveReport => translate('unableToSaveReport');
  String get pdfReportTitle => translate('pdfReportTitle');
  String get pdfReportSub => translate('pdfReportSub');
  String get pdfScoreText => translate('pdfScoreText');
  String get pdfConfidenceText => translate('pdfConfidenceText');
  String get pdfSummaryHeader => translate('pdfSummaryHeader');
  String get pdfConcernsHeader => translate('pdfConcernsHeader');
  String get pdfRoutineHeader => translate('pdfRoutineHeader');
  String get pdfShareText => translate('pdfShareText');
  String get cleanseMildFaceWash => translate('cleanseMildFaceWash');
  String get acneMildMorning => translate('acneMildMorning');
  String get acneModerateMorning => translate('acneModerateMorning');
  String get acneSevereMorning => translate('acneSevereMorning');
  String get darkCirclesMorning1 => translate('darkCirclesMorning1');
  String get darkCirclesMorning2 => translate('darkCirclesMorning2');
  String get pigmentationMorning1 => translate('pigmentationMorning1');
  String get pigmentationMorning2 => translate('pigmentationMorning2');
  String get rednessMorning1 => translate('rednessMorning1');
  String get rednessMorning2 => translate('rednessMorning2');
  String get textureMorning1 => translate('textureMorning1');
  String get textureMorning2 => translate('textureMorning2');
  String get doubleCleanse => translate('doubleCleanse');
  String get acneMildNight => translate('acneMildNight');
  String get acneModerateNight => translate('acneModerateNight');
  String get acneSevereNight => translate('acneSevereNight');
  String get darkCirclesNight1 => translate('darkCirclesNight1');
  String get darkCirclesNight2 => translate('darkCirclesNight2');
  String get pigmentationNight => translate('pigmentationNight');
  String get rednessNight1 => translate('rednessNight1');
  String get rednessNight2 => translate('rednessNight2');
  String get textureNight => translate('textureNight');
  String get summaryBreakoutSevere => translate('summaryBreakoutSevere');
  String get summaryAcneModerate => translate('summaryAcneModerate');
  String get summaryDarkCirclesProminent => translate('summaryDarkCirclesProminent');
  String get summaryPigmentationSPF => translate('summaryPigmentationSPF');
  String get summaryRednessCalming => translate('summaryRednessCalming');
  String get summaryTextureExfoliation => translate('summaryTextureExfoliation');
  String get summaryHealthyBalanced => translate('summaryHealthyBalanced');
  String get severityMild => translate('severityMild');
  String get severityModerate => translate('severityModerate');
  String get severitySevere => translate('severitySevere');
  String get preferences => translate('preferences');
  String get legal => translate('legal');
  String get logOut => translate('logOut');
  String get logOutConfirm => translate('logOutConfirm');
  String get cancel => translate('cancel');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SkinAI';

  @override
  String get welcomeTitle => 'Welcome to SkinAI';

  @override
  String get welcomeSubtitle => 'Let\'s create your personalized skin profile';

  @override
  String get continueButton => 'Continue';

  @override
  String get readyToScan => 'Ready to scan?';

  @override
  String get analyzeYourSkin => 'Analyze Your Skin';

  @override
  String get heroDescription =>
      'Scan your face to get AI-powered insights and personalized recommendations.';

  @override
  String get startScan => 'Start Scan';

  @override
  String get streakLabel => 'Scan Streak';

  @override
  String get daysSuffix => 'days';

  @override
  String get improvementLabel => 'Improvement';

  @override
  String get ptsSuffix => 'pts';

  @override
  String get overviewMetrics => 'Overview Metrics';

  @override
  String get viewAll => 'View All';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeSettings => 'App Theme';

  @override
  String get languageSettings => 'Language';

  @override
  String get notificationsSettings => 'Manage Notifications';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsConditions => 'Terms & Conditions';

  @override
  String get selectLanguageTitle => 'Select Language';

  @override
  String get selectLanguageSubtitle =>
      'Choose your preferred language for the app experience.';

  @override
  String get notificationPermissionTitle => 'Stay Notified';

  @override
  String get notificationPermissionSubtitle =>
      'Get reminders to scan your skin, daily skincare tips, and alerts when your analysis is ready.';

  @override
  String get allowNotifications => 'Allow Notifications';

  @override
  String get notNow => 'Not Now';

  @override
  String get noFaceDetected =>
      'No face detected. Please upload a clear front-facing selfie.';

  @override
  String get multipleFacesDetected =>
      'Only one face should be visible in the photo.';

  @override
  String get faceNotCentered => 'Face not centered';

  @override
  String get imageTooDark => 'Image too dark';

  @override
  String get faceTooFar => 'Face too far away';

  @override
  String get blurryImage => 'Blurry image detected';

  @override
  String get calibrating => 'AI Calibrating...';

  @override
  String get routineMorning => 'Morning Routine';

  @override
  String get routineNight => 'Night Routine';

  @override
  String get savePdf => 'Save PDF Report';

  @override
  String get reScan => 'Re-Scan';
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationProvider extends ChangeNotifier {
  static const String _localeKey = 'locale_lang';
  static const String _permissionKey = 'notification_permission_shown';
  static const String _languageSelectedKey = 'language_selected';

  Locale _locale = const Locale('en');
  bool _notificationPermissionShown = false;
  bool _languageSelected = false;

  Locale get locale => _locale;
  bool get notificationPermissionShown => _notificationPermissionShown;
  bool get languageSelected => _languageSelected;

  LocalizationProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationPermissionShown = prefs.getBool(_permissionKey) ?? false;
      _languageSelected = prefs.getBool(_languageSelectedKey) ?? false;

      final savedLang = prefs.getString(_localeKey);
      if (savedLang != null) {
        _locale = Locale(savedLang);
      } else {
        // Auto-detect device language
        final systemLocale = PlatformDispatcher.instance.locale;
        if (systemLocale.languageCode == 'hi') {
          _locale = const Locale('hi');
        } else {
          _locale = const Locale('en');
        }
      }
      notifyListeners();
    } catch (_) {
      // Fallback to default Locale('en') if storage isn't ready
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    _locale = newLocale;
    _languageSelected = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, newLocale.languageCode);
      await prefs.setBool(_languageSelectedKey, true);
    } catch (_) {}
  }

  Future<void> markNotificationPermissionShown() async {
    _notificationPermissionShown = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_permissionKey, true);
    } catch (_) {}
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
      syncColors();
      notifyListeners();
    } catch (_) {
      // Fallback in case of storage failure
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    syncColors();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.light) {
        await prefs.setString(_themeKey, 'light');
      } else if (mode == ThemeMode.dark) {
        await prefs.setString(_themeKey, 'dark');
      } else {
        await prefs.remove(_themeKey);
      }
    } catch (_) {}
  }

  void syncColors() {
    if (_themeMode == ThemeMode.light) {
      AppColors.updateTheme(false);
    } else if (_themeMode == ThemeMode.dark) {
      AppColors.updateTheme(true);
    } else {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      AppColors.updateTheme(brightness == Brightness.dark);
    }
  }
}

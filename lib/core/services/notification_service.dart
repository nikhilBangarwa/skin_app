import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _key = 'notifications_enabled';
  bool _enabled = false;

  bool get enabled => _enabled;

  NotificationProvider() {
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_key) ?? false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _enabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, enabled);
    } catch (_) {}
  }

  Future<bool> requestNotificationPermission() async {
    await setNotificationsEnabled(true);
    return true;
  }
}

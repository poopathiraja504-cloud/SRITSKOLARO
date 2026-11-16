import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _preferenceKey = 'srit.theme.darkMode';
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getBool(_preferenceKey);
    if (saved != null) _mode = saved ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _mode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_preferenceKey, value);
  }
}

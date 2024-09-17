import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifer with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeNotifer(){
    loadPreference();
  }

  void toggleThemes(bool isDark) {
    _isDark = isDark;
    savePreference();
    notifyListeners();
  }

  Future<void> savePreference() async {
    final preference = await SharedPreferences.getInstance();
    await preference.setBool('isDark', _isDark);
  }

  Future<void>loadPreference() async {
    final preference = await SharedPreferences.getInstance();
    _isDark = preference.getBool('isDark') ?? false;
    notifyListeners();
  }
}
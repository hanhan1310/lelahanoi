import 'package:flutter/material.dart';
import 'package:lelahanoi/public/l10n/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const _key = 'app_language';

  AppStrings _strings = AppStrings.en;
  String _currentCode = 'en';

  AppStrings get strings => _strings;
  String get currentCode => _currentCode;

  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'vi': 'Tiếng Việt',
    'de': 'Deutsch',
  };

  LanguageProvider() {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'en';
    setLanguage(code);
  }

  Future<void> setLanguage(String code) async {
    switch (code) {
      case 'vi':
        _strings = AppStrings.vi;
        break;
      case 'de':
        _strings = AppStrings.de;
        break;
      default:
        _strings = AppStrings.en;
        code = 'en';
    }
    _currentCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    notifyListeners();
  }
}

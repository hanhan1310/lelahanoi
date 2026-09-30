import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lelahanoi/core/l10n/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageState {
  final AppStrings strings;
  final String currentCode;

  const LanguageState({required this.strings, required this.currentCode});
}

class LanguageCubit extends Cubit<LanguageState> {
  static const _key = 'app_language';

  AppStrings get strings => state.strings;
  String get currentCode => state.currentCode;

  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'vi': 'Tiếng Việt',
    'de': 'Deutsch',
  };

  LanguageCubit()
      : super(const LanguageState(strings: AppStrings.en, currentCode: 'en')) {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'en';
    await setLanguage(code);
  }

  Future<void> setLanguage(String code) async {
    late final AppStrings strings;
    switch (code) {
      case 'vi':
        strings = AppStrings.vi;
        break;
      case 'de':
        strings = AppStrings.de;
        break;
      default:
        strings = AppStrings.en;
        code = 'en';
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    emit(LanguageState(strings: strings, currentCode: code));
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/strings.dart';

class LocaleService {
  static const _kLocale = 'qcart_locale';

  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier(const Locale('en'));

  static bool get isArabic => localeNotifier.value.languageCode == 'ar';
  static String get code => localeNotifier.value.languageCode;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocale) ?? 'en';
    localeNotifier.value = Locale(saved);
  }

  static Future<void> setLocale(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, langCode);
    localeNotifier.value = Locale(langCode);
  }

  static void toggle() {
    setLocale(isArabic ? 'en' : 'ar');
  }

  static String t(String key) => AppStrings.t(key, code);
}

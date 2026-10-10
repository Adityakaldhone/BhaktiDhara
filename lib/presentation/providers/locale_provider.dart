import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported language codes in Nitya Aarti.
const _supportedLanguageCodes = {'mr', 'hi', 'en'};

const _userLanguageKey = 'user_selected_language';

/// Detects and returns the best matching initial locale from the user's mobile device settings.
Locale getInitialDeviceLocale() {
  // 1. Check preferred device locales in order of user priority
  final deviceLocales = PlatformDispatcher.instance.locales;
  for (final loc in deviceLocales) {
    if (_supportedLanguageCodes.contains(loc.languageCode)) {
      return Locale(loc.languageCode);
    }
  }

  // 2. Check primary device locale
  final primaryCode = PlatformDispatcher.instance.locale.languageCode;
  if (_supportedLanguageCodes.contains(primaryCode)) {
    return Locale(primaryCode);
  }

  // 3. Fallback default
  return const Locale('en');
}

/// The language the user explicitly picked in the app, or null if they never
/// have. Loaded before `runApp` so the first frame is already in that language.
Future<String?> loadUserLanguageCode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_userLanguageKey);
    return _supportedLanguageCodes.contains(code) ? code : null;
  } catch (_) {
    return null;
  }
}

/// Startup language: the user's own choice wins; otherwise follow the device.
Locale resolveStartupLocale(String? userLanguageCode) {
  return userLanguageCode != null
      ? Locale(userLanguageCode)
      : getInitialDeviceLocale();
}

/// Overridden in `main` with the result of [loadUserLanguageCode].
final userLanguageCodeProvider = Provider<String?>((ref) => null);

/// The active application language. Follows the device language until the
/// user picks one by hand via [selectAppLanguage]; that choice is remembered.
final localeProvider = StateProvider<Locale>((ref) {
  return resolveStartupLocale(ref.read(userLanguageCodeProvider));
});

/// Applies a language the user picked by hand and remembers it across launches.
void selectAppLanguage(WidgetRef ref, Locale locale) {
  ref.read(localeProvider.notifier).state = locale;
  _saveUserLanguage(locale.languageCode);
}

Future<void> _saveUserLanguage(String code) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userLanguageKey, code);
  } catch (_) {}
}

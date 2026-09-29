import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported language codes in Nitya Aarti.
const _supportedLanguageCodes = {'mr', 'hi', 'en'};

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

/// StateProvider for managing the active application language (Locale).
/// Automatically detects the user's mobile device language on startup.
final localeProvider = StateProvider<Locale>((ref) {
  return getInitialDeviceLocale();
});

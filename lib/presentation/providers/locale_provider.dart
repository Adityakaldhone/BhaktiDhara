import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// StateProvider for managing the current application language (Locale).
/// Default is English ('en').
final localeProvider = StateProvider<Locale>((ref) {
  return const Locale('en'); // Default to English
});

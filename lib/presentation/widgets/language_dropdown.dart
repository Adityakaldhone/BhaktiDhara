import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../providers/locale_provider.dart';

/// Compact language pill (मराठी / हिंदी / English) for screen headers.
class LanguageDropdown extends ConsumerWidget {
  const LanguageDropdown({super.key});

  static const _languages = [
    ('हिंदी', Locale('hi')),
    ('मराठी', Locale('mr')),
    ('English', Locale('en')),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider).languageCode;
    final currentName = switch (current) {
      'en' => 'English',
      'hi' => 'हिंदी',
      _ => 'मराठी',
    };

    return PopupMenuButton<Locale>(
      tooltip: current == 'en' ? 'Language' : 'भाषा',
      onSelected: (locale) => selectAppLanguage(ref, locale),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
      ),
      color: MandirTheme.surfaceWhite,
      elevation: 6,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final (label, locale) in _languages)
          PopupMenuItem<Locale>(
            value: locale,
            child: Row(
              children: [
                Icon(
                  current == locale.languageCode
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: current == locale.languageCode
                      ? MandirTheme.primarySaffron
                      : MandirTheme.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.mukta(
                    fontSize: 16,
                    fontWeight: current == locale.languageCode
                        ? FontWeight.bold
                        : FontWeight.w600,
                    color: current == locale.languageCode
                        ? MandirTheme.secondaryMaroon
                        : MandirTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.language,
              size: 18,
              color: MandirTheme.primarySaffron,
            ),
            const SizedBox(width: 6),
            Text(
              currentName,
              style: GoogleFonts.mukta(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: MandirTheme.secondaryMaroon,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: MandirTheme.primarySaffron,
            ),
          ],
        ),
      ),
    );
  }
}

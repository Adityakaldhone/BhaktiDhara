import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme.dart';
import '../../jaap/jaap_colors.dart';
import '../../jaap/jaap_strings.dart';
import 'diya_lamp.dart';

enum SankalpChoice { keepChanting, done }

/// "Sankalp Purna" card shown when the daily goal is met. Never auto-dismisses:
/// the user chooses to keep chanting or finish.
Future<SankalpChoice> showSankalpPurnaDialog(
  BuildContext context, {
  required JaapStrings strings,
  required int streak,
  int? milestone,
}) async {
  final choice = await showGeneralDialog<SankalpChoice>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xFF3E2723).withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 400),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(curved), child: child),
      );
    },
    pageBuilder: (dialogContext, _, _) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBF2), JaapColors.sandalStart],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              boxShadow: [
                BoxShadow(
                  color: JaapColors.glowGold.withValues(alpha: 0.6),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DiyaLamp(size: 96, flicker: true),
                const SizedBox(height: 8),
                Text(
                  strings.sankalpPurna,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.yatraOne(
                    fontSize: 36,
                    color: MandirTheme.secondaryMaroon,
                  ),
                ),
                if (streak > 0)
                  Text(
                    strings.streakDays(streak),
                    style: GoogleFonts.mukta(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: MandirTheme.primarySaffron,
                    ),
                  ),
                if (milestone != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      strings.milestoneReached(strings.compact(milestone)),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.mukta(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: JaapColors.counterGold,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  strings.blessing,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mukta(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: MandirTheme.textDark,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, SankalpChoice.done),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(
                      strings.done,
                      style: GoogleFonts.mukta(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext, SankalpChoice.keepChanting),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MandirTheme.secondaryMaroon,
                      side: const BorderSide(color: MandirTheme.goldenAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(
                      strings.keepChanting,
                      style: GoogleFonts.mukta(fontSize: 19, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  return choice ?? SankalpChoice.keepChanting;
}

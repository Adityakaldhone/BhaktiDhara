import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme.dart';
import '../../jaap/jaap_colors.dart';
import '../../jaap/jaap_strings.dart';
import '../../providers/jaap_providers.dart';
import '../../providers/locale_provider.dart';
import '../../screens/jaap_counter_screen.dart';
import 'diya_lamp.dart';
import 'jaap_sheets.dart';

/// Home-screen entry point: shows the streak and today's progress and opens
/// the deity sheet, then the counter once a mantra is chosen.
class JaapDashboardCard extends ConsumerWidget {
  const JaapDashboardCard({super.key});

  /// Shows the deity list sheet first. Selecting a deity (or Continue / Begin)
  /// opens the counter with that mantra.
  static Future<void> open(BuildContext context, WidgetRef ref) async {
    final lang = ref.read(localeProvider).languageCode;
    final wasOnboarded = ref.read(jaapProvider).progress.isOnboarded;
    final mantraId = await showJaapEntrySheet(
      context,
      ref,
      lang,
      isOnboarding: !wasOnboarded,
    );
    if (mantraId == null || !context.mounted) return;

    final notifier = ref.read(jaapProvider.notifier);
    final progress = ref.read(jaapProvider).progress;
    if (!progress.isOnboarded) {
      await notifier.completeOnboarding(
        mantraId: mantraId,
        dailyGoalMalas: progress.dailyGoalMalas,
      );
    } else {
      notifier.selectMantra(mantraId);
    }
    notifier.startSession();
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JaapCounterScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jaap = ref.watch(jaapProvider);
    final s = JaapStrings(ref.watch(localeProvider).languageCode);
    final onboarded = jaap.progress.isOnboarded;
    final streak = jaap.currentStreak;

    final String subtitle;
    if (!onboarded) {
      subtitle = s.cardTagline;
    } else if (jaap.goalMetToday) {
      subtitle = s.goalDoneToday;
    } else {
      subtitle = s.todayProgress(jaap.malasToday, jaap.progress.dailyGoalMalas);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => open(context, ref),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF8E8), JaapColors.sandalStart, Color(0xFFFBE3B8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: MandirTheme.goldenAccent.withValues(alpha: 0.55),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8A5A2B).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DiyaLamp(size: 36, lit: onboarded && streak > 0),
                      if (onboarded && streak > 0)
                        Text(
                          '$streak',
                          style: GoogleFonts.mukta(
                            fontSize: 15,
                            height: 1.0,
                            fontWeight: FontWeight.w800,
                            color: MandirTheme.secondaryMaroon,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mukta(
                          fontSize: 20,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: MandirTheme.secondaryMaroon,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mukta(
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: JaapColors.inkSoft,
                        ),
                      ),
                      if (onboarded && streak > 0)
                        Text(
                          s.streakDays(streak),
                          style: GoogleFonts.mukta(
                            fontSize: 13.5,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: MandirTheme.primarySaffron,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minHeight: 52, maxWidth: 132),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: MandirTheme.cardPrimaryButton,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    onboarded && jaap.todayCount > 0 ? s.continueJaap : s.start,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.mukta(
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

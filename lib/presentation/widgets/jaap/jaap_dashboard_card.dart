import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme.dart';
import '../../jaap/jaap_strings.dart';
import '../../providers/jaap_providers.dart';
import '../../providers/locale_provider.dart';
import '../../screens/jaap_counter_screen.dart';
import 'diya_lamp.dart';

/// Home-screen entry point: shows the streak and today's progress and opens
/// the counter (or onboarding for first-time users) in one tap.
class JaapDashboardCard extends ConsumerWidget {
  const JaapDashboardCard({super.key});

  /// Every visit starts a fresh round on the ring. The counter screen shows
  /// onboarding itself when needed, so this works before progress has loaded.
  static void open(BuildContext context, WidgetRef ref) {
    ref.read(jaapProvider.notifier).startSession();
    Navigator.push(
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
          borderRadius: BorderRadius.circular(20),
          onTap: () => open(context, ref),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF3D6), Color(0xFFFBE3B8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8C98A), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8A5A2B).withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DiyaLamp(size: 38, lit: onboarded && streak > 0),
                      if (onboarded && streak > 0)
                        Text(
                          '$streak',
                          style: GoogleFonts.mukta(
                            fontSize: 16,
                            height: 1.0,
                            fontWeight: FontWeight.w800,
                            color: MandirTheme.secondaryMaroon,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '📿 ${s.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mukta(
                          fontSize: 20,
                          height: 1.2,
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
                          color: MandirTheme.textDark,
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
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: MandirTheme.cardPrimaryButton,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    onboarded && jaap.todayCount > 0 ? s.continueJaap : s.start,
                    style: GoogleFonts.mukta(
                      fontSize: 15,
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

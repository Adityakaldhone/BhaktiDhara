import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme.dart';
import '../../greeting/greeting_strings.dart';
import '../../providers/greeting_card_providers.dart';
import '../../providers/locale_provider.dart';
import '../../screens/greeting_card_screen.dart';

/// Home-screen entry: today's card thumbnail; tapping anywhere opens the
/// preview to change and send the card.
class GreetingDashboardCard extends ConsumerWidget {
  const GreetingDashboardCard({super.key});

  static void _openPreview(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GreetingCardScreen()),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(statusCardsEnabledProvider).valueOrNull == false) {
      return const SizedBox.shrink();
    }
    final s = GreetingStrings(ref.watch(localeProvider).languageCode);
    final card = ref.watch(greetingCardProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('greeting-dashboard-card'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openPreview(context),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
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
                  width: 40,
                  height: 72,
                  child: CardPreview(data: card, radius: 8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.dashboardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mukta(
                          fontSize: 19,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: MandirTheme.secondaryMaroon,
                        ),
                      ),
                      Text(
                        s.dashboardHint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mukta(
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: MandirTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('greeting-dashboard-view'),
                  onPressed: () => _openPreview(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: MandirTheme.cardPrimaryButton,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                  child: Text(s.view, style: GoogleFonts.mukta(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme.dart';
import '../../../data/datasources/jaap_mantra_catalog.dart';
import '../../../domain/entities/jaap_mantra.dart';
import '../../../domain/entities/jaap_progress.dart';
import '../../jaap/jaap_colors.dart';
import '../../jaap/jaap_strings.dart';
import '../../providers/jaap_providers.dart';

/// Large, tappable mantra row used in onboarding and the mantra picker.
class JaapMantraTile extends StatelessWidget {
  final JaapMantra mantra;
  final String langCode;
  final bool selected;
  final VoidCallback onTap;

  const JaapMantraTile({
    super.key,
    required this.mantra,
    required this.langCode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? const Color(0xFFFFF1D0) : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 74),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? MandirTheme.goldenAccent
                    : MandirTheme.goldenAccent.withValues(alpha: 0.28),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: MandirTheme.imageSurface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? MandirTheme.goldenAccent.withValues(alpha: 0.6)
                          : Colors.transparent,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      MandirTheme.getDeityImageAsset(mantra.deity),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.spa_rounded,
                        size: 26,
                        color: MandirTheme.secondaryMaroon.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mantra.localizedName(langCode),
                        style: GoogleFonts.mukta(
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: MandirTheme.textDark,
                        ),
                      ),
                      Text(
                        mantra.devanagari.split('\n').first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansDevanagari(
                          fontSize: 15,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: JaapColors.mantraMaroon,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: MandirTheme.goldenAccent,
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _sheetHandle() => Container(
  width: 40,
  height: 4,
  margin: const EdgeInsets.only(bottom: 14),
  decoration: BoxDecoration(
    color: MandirTheme.goldenAccent.withValues(alpha: 0.45),
    borderRadius: BorderRadius.circular(3),
  ),
);

Widget _sheetTitle(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Text(
    text,
    style: GoogleFonts.mukta(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: MandirTheme.secondaryMaroon,
    ),
  ),
);

/// Entry / change sheet: deity list. Tap a row to confirm immediately, or
/// highlight one and press Continue / Begin.
Future<String?> showJaapEntrySheet(
  BuildContext context,
  WidgetRef ref,
  String langCode, {
  bool isOnboarding = false,
}) {
  final s = JaapStrings(langCode);
  final initialId =
      ref.read(jaapProvider).progress.mantraId ?? JaapMantraCatalog.defaultMantraId;

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    isDismissible: !isOnboarding,
    enableDrag: !isOnboarding,
    backgroundColor: JaapColors.sandalStart,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      var selectedId = initialId;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.82,
            maxChildSize: 0.95,
            minChildSize: 0.55,
            builder: (context, scrollController) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    _sheetHandle(),
                    _sheetTitle(isOnboarding ? s.welcomeTitle : s.changeMantra),
                    if (isOnboarding)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          s.welcomeSubtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.mukta(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: JaapColors.inkSoft,
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: JaapMantraCatalog.all.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final mantra = JaapMantraCatalog.all[i];
                          return JaapMantraTile(
                            mantra: mantra,
                            langCode: langCode,
                            selected: mantra.id == selectedId,
                            onTap: () {
                              // Highlight, then open the counter immediately.
                              setSheetState(() => selectedId = mantra.id);
                              Navigator.pop(sheetContext, mantra.id);
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        key: const ValueKey('jaap-entry-continue'),
                        // Continue / Begin with the highlighted (or default) mantra.
                        onPressed: () =>
                            Navigator.pop(sheetContext, selectedId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MandirTheme.secondaryMaroon,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isOnboarding ? s.start : s.continueJaap,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.mukta(
                            fontSize: 20,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> showJaapMantraPicker(
  BuildContext context,
  WidgetRef ref,
  String langCode,
) async {
  final chosen = await showJaapEntrySheet(context, ref, langCode);
  if (chosen == null) return;
  ref.read(jaapProvider.notifier).selectMantra(chosen);
}

/// Row of big goal buttons (1 / 3 / 5 / 11 / 21 malas).
class JaapGoalSelector extends StatelessWidget {
  final int selected;
  final String langCode;
  final ValueChanged<int> onSelected;

  const JaapGoalSelector({
    super.key,
    required this.selected,
    required this.langCode,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final s = JaapStrings(langCode);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (final goal in JaapProgress.goalOptions)
          Semantics(
            button: true,
            selected: goal == selected,
            child: GestureDetector(
              onTap: () => onSelected(goal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 96,
                height: 76,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: goal == selected
                      ? MandirTheme.primarySaffron
                      : MandirTheme.cardBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: goal == selected
                        ? MandirTheme.primarySaffron
                        : MandirTheme.cardBorder,
                    width: 1.5,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.goalMalas(goal),
                        style: GoogleFonts.mukta(
                          fontSize: 19,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          color: goal == selected
                              ? Colors.white
                              : MandirTheme.textDark,
                        ),
                      ),
                      Text(
                        s.goalJaaps(goal),
                        style: GoogleFonts.mukta(
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: goal == selected
                              ? Colors.white.withValues(alpha: 0.9)
                              : MandirTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> showJaapSettingsSheet(
  BuildContext context,
  WidgetRef ref,
  String langCode,
) {
  final s = JaapStrings(langCode);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: JaapColors.sandalStart,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final jaap = ref.watch(jaapProvider);
        final p = jaap.progress;
        final notifier = ref.read(jaapProvider.notifier);
        final shownGoal = p.pendingGoalMalas ?? p.dailyGoalMalas;

        Widget toggle(
          String label,
          IconData icon,
          bool value,
          ValueChanged<bool> onChanged,
        ) {
          return SwitchListTile(
            value: value,
            onChanged: onChanged,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            activeThumbColor: Colors.white,
            activeTrackColor: MandirTheme.primarySaffron,
            secondary: Icon(icon, color: MandirTheme.goldenAccent, size: 28),
            title: Text(
              label,
              style: GoogleFonts.mukta(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: MandirTheme.textDark,
              ),
            ),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                _sheetTitle(s.settings),
                toggle(
                  s.vibration,
                  Icons.vibration_rounded,
                  p.vibrationOn,
                  (v) => notifier.updateSettings(vibrationOn: v),
                ),
                toggle(
                  s.bellSound,
                  Icons.notifications_active_rounded,
                  p.bellOn,
                  (v) => notifier.updateSettings(bellOn: v),
                ),
                toggle(
                  s.tickSound,
                  Icons.music_note_rounded,
                  p.tickSoundOn,
                  (v) => notifier.updateSettings(tickSoundOn: v),
                ),
                toggle(
                  s.keepScreenOn,
                  Icons.light_mode_rounded,
                  p.keepScreenOn,
                  (v) => notifier.updateSettings(keepScreenOn: v),
                ),
                const Divider(height: 28),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    s.dailyGoal,
                    style: GoogleFonts.mukta(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: MandirTheme.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                JaapGoalSelector(
                  selected: shownGoal,
                  langCode: langCode,
                  onSelected: notifier.setDailyGoal,
                ),
                if (p.pendingGoalMalas != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    s.goalFromTomorrow,
                    style: GoogleFonts.mukta(
                      fontSize: 15,
                      color: MandirTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

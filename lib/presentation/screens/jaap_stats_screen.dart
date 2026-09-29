import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../data/datasources/jaap_mantra_catalog.dart';
import '../../domain/logic/jaap_streak.dart';
import '../jaap/jaap_colors.dart';
import '../jaap/jaap_strings.dart';
import '../providers/jaap_providers.dart';
import '../providers/locale_provider.dart';
import '../widgets/jaap/diya_lamp.dart';
import '../widgets/premium_blurred_gate.dart';

/// "Meri Sadhana" — streak, lifetime count, this week, this month and
/// milestones. Per-mantra totals and past months are premium.
class JaapStatsScreen extends ConsumerWidget {
  const JaapStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jaap = ref.watch(jaapProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final s = JaapStrings(lang);

    return Scaffold(
      backgroundColor: JaapColors.sandalStart,
      appBar: AppBar(
        backgroundColor: JaapColors.sandalStart,
        leading: IconButton(
          iconSize: 30,
          tooltip: s.back,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(s.mySadhana),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildTopTiles(jaap, s),
          const SizedBox(height: 14),
          _buildTodayCard(jaap, s),
          const SizedBox(height: 14),
          _buildWeek(jaap, s),
          const SizedBox(height: 14),
          _section(
            title: '${s.monthName(JaapCalendar.parse(jaap.today).month)} '
                '${JaapCalendar.parse(jaap.today).year}',
            child: _MonthCalendar(jaap: jaap, strings: s, anyDayInMonth: jaap.today),
          ),
          const SizedBox(height: 14),
          _buildMilestones(jaap, s),
          const SizedBox(height: 14),
          PremiumBlurredGate(
            langCode: lang,
            title: s.lockedTitle,
            subtitle: s.lockedSubtitle,
            child: Column(
              children: [
                _buildMantraTotals(jaap, s, lang),
                const SizedBox(height: 14),
                _buildPreviousMonth(jaap, s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTiles(JaapState jaap, JaapStrings s) {
    return Row(
      children: [
        Expanded(
          child: _tile(
            icon: DiyaLamp(size: 34, lit: jaap.currentStreak > 0),
            value: '${jaap.currentStreak}',
            label: s.streak,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tile(
            icon: const Text('📿', style: TextStyle(fontSize: 28)),
            value: s.compact(jaap.progress.lifetimeCount),
            label: s.lifetime,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tile(
            icon: const Text('🏆', style: TextStyle(fontSize: 28)),
            value: '${jaap.bestStreak}',
            label: s.bestStreak,
          ),
        ),
      ],
    );
  }

  Widget _tile({required Widget icon, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          SizedBox(height: 36, child: Center(child: icon)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.mukta(
                fontSize: 28,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: JaapColors.counterGold,
              ),
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.mukta(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: MandirTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayCard(JaapState jaap, JaapStrings s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Text(
            s.today,
            style: GoogleFonts.mukta(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: MandirTheme.secondaryMaroon,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${JaapStrings.grouped(jaap.todayCount)} ${s.jaap} · '
                  '${s.goalMalas(jaap.malasToday)} · ${s.minutes(jaap.todaySeconds)}',
                  style: GoogleFonts.mukta(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: MandirTheme.textDark,
                  ),
                ),
                if (jaap.todayAudioCount > 0)
                  Text(
                    s.tappedVsAudio(
                      jaap.todayCount - jaap.todayAudioCount,
                      jaap.todayAudioCount,
                    ),
                    style: GoogleFonts.mukta(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: MandirTheme.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeek(JaapState jaap, JaapStrings s) {
    final days = [for (var i = 6; i >= 0; i--) JaapCalendar.shift(jaap.today, -i)];
    final counts = [for (final d in days) jaap.progress.countOn(d)];
    final maxCount = counts.fold<int>(jaap.progress.dailyGoalJaaps, (a, b) => b > a ? b : a);

    return _section(
      title: s.thisWeek,
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      counts[i] == 0 ? '' : s.compact(counts[i]),
                      style: GoogleFonts.mukta(fontSize: 12, color: MandirTheme.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 22,
                      height: 4 + 96 * (counts[i] / maxCount),
                      decoration: BoxDecoration(
                        color: jaap.progress.completedDays.contains(days[i])
                            ? MandirTheme.primarySaffron
                            : MandirTheme.chipBorder,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.weekdayInitials[JaapCalendar.parse(days[i]).weekday - 1],
                      style: GoogleFonts.mukta(
                        fontSize: 16,
                        fontWeight: days[i] == jaap.today ? FontWeight.w800 : FontWeight.w600,
                        color: days[i] == jaap.today
                            ? MandirTheme.primarySaffron
                            : MandirTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestones(JaapState jaap, JaapStrings s) {
    final lifetime = jaap.progress.lifetimeCount;
    final next = JaapStreak.nextMilestone(lifetime);
    return _section(
      title: s.milestones,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in JaapStreak.milestones)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: lifetime >= m ? const Color(0xFFFFF1D0) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: lifetime >= m ? MandirTheme.goldenAccent : MandirTheme.cardBorder,
                      width: lifetime >= m ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    '${lifetime >= m ? '✅' : '🔸'} ${s.compact(m)}',
                    style: GoogleFonts.mukta(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: lifetime >= m ? MandirTheme.secondaryMaroon : MandirTheme.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 14),
            Text(
              s.nextMilestone(s.compact(next)),
              style: GoogleFonts.mukta(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: MandirTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: lifetime / next,
                minHeight: 12,
                backgroundColor: MandirTheme.chipBackground,
                color: MandirTheme.primarySaffron,
              ),
            ),
          ],
          if (jaap.protectorAvailable) ...[
            const SizedBox(height: 14),
            Text(
              s.protectorAvailable,
              style: GoogleFonts.mukta(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MandirTheme.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMantraTotals(JaapState jaap, JaapStrings s, String lang) {
    final totals = jaap.progress.perMantraTotals;
    final mantras = [...JaapMantraCatalog.all]
      ..sort((a, b) => (totals[b.id] ?? 0).compareTo(totals[a.id] ?? 0));
    return _section(
      title: s.mantraTotals,
      child: Column(
        children: [
          for (final m in mantras)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      m.localizedName(lang),
                      style: GoogleFonts.mukta(fontSize: 17, color: MandirTheme.textDark),
                    ),
                  ),
                  Text(
                    JaapStrings.grouped(totals[m.id] ?? 0),
                    style: GoogleFonts.mukta(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: JaapColors.counterGold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviousMonth(JaapState jaap, JaapStrings s) {
    final today = JaapCalendar.parse(jaap.today);
    final prev = DateTime(today.year, today.month - 1, 1);
    final prevKey = '${prev.year.toString().padLeft(4, '0')}-'
        '${prev.month.toString().padLeft(2, '0')}-01';
    return _section(
      title: '${s.monthName(prev.month)} ${prev.year}',
      child: _MonthCalendar(jaap: jaap, strings: s, anyDayInMonth: prevKey),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: MandirTheme.cardBackground,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: MandirTheme.cardBorder),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF8A5A2B).withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );

Widget _section({required String title, required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.mukta(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: MandirTheme.secondaryMaroon,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

/// Month grid (Monday first). Completed days show a lit diya, forgiven days
/// a shield, today is outlined.
class _MonthCalendar extends StatelessWidget {
  final JaapState jaap;
  final JaapStrings strings;
  final String anyDayInMonth;

  const _MonthCalendar({
    required this.jaap,
    required this.strings,
    required this.anyDayInMonth,
  });

  @override
  Widget build(BuildContext context) {
    final ref = JaapCalendar.parse(anyDayInMonth);
    final first = DateTime(ref.year, ref.month, 1);
    final daysInMonth = DateTime(ref.year, ref.month + 1, 0).day;
    final leading = first.weekday - DateTime.monday;
    final firstKey = JaapCalendar.shift(anyDayInMonth, 1 - ref.day);

    final cells = <Widget>[
      for (final d in strings.weekdayInitials)
        Center(
          child: Text(
            d,
            style: GoogleFonts.mukta(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: MandirTheme.textMuted,
            ),
          ),
        ),
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _dayCell(JaapCalendar.shift(firstKey, day - 1), day),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: cells,
    );
  }

  Widget _dayCell(String key, int day) {
    final completed = jaap.progress.completedDays.contains(key);
    final protectedDay = jaap.progress.protectedDays.contains(key);
    final isToday = key == jaap.today;
    final isFuture = key.compareTo(jaap.today) > 0;

    Widget content;
    if (completed) {
      content = const DiyaLamp(size: 26);
    } else if (protectedDay) {
      content = const Text('🛡️', style: TextStyle(fontSize: 18));
    } else {
      content = Text(
        '$day',
        style: GoogleFonts.mukta(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isFuture
              ? MandirTheme.textMuted.withValues(alpha: 0.4)
              : MandirTheme.textDark,
        ),
      );
    }

    return Container(
      alignment: Alignment.center,
      decoration: isToday
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MandirTheme.primarySaffron, width: 2),
            )
          : null,
      child: content,
    );
  }
}

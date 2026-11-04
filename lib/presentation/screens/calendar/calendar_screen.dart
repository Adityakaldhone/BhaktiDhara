import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tithi_engine/tithi_engine.dart';

import '../../../core/theme/theme.dart';
import '../../../services/tithi_engine_service.dart';
import '../../calendar/calendar_strings.dart';
import '../../providers/calendar_provider.dart';
import 'calendar_day_sheet.dart';

/// Mahalaxmi-style monthly Panchang calendar screen.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final s = CalendarStrings(lang);

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: MandirTheme.surfaceWhite,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: MandirTheme.primarySaffron),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          s.title,
          style: GoogleFonts.mukta(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: MandirTheme.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: _CalendarBody(s: s, lang: lang),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────

class _CalendarBody extends ConsumerWidget {
  const _CalendarBody({required this.s, required this.lang});
  final CalendarStrings s;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(calendarMonthProvider);
    final snapshotsAsync = ref.watch(calendarMonthSnapshotsProvider);

    return snapshotsAsync.when(
      loading: () => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: MandirTheme.primarySaffron),
            const SizedBox(height: 16),
            Text(
              s.loading,
              style: GoogleFonts.mukta(
                fontSize: 16,
                color: MandirTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: GoogleFonts.mukta(color: MandirTheme.textMuted),
        ),
      ),
      data: (snapshots) => _CalendarContent(
        month: month,
        snapshots: snapshots,
        s: s,
        lang: lang,
      ),
    );
  }
}

// ── Calendar content ──────────────────────────────────────────────────────

class _CalendarContent extends ConsumerWidget {
  const _CalendarContent({
    required this.month,
    required this.snapshots,
    required this.s,
    required this.lang,
  });

  final DateTime month;
  final Map<int, TithiDaySnapshot> snapshots;
  final CalendarStrings s;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final isCurrentMonth =
        today.year == month.year && today.month == month.month;

    // Gather festival days for this month
    final festivalDays = <int>{};
    final monthFestivals = <MapEntry<int, String>>[];
    snapshots.forEach((day, snap) {
      if (snap.observances.isNotEmpty) {
        festivalDays.add(day);
        for (final f in snap.observances) {
          monthFestivals.add(MapEntry(day, f.name));
        }
      }
    });

    // Hindu month name from day 1 snapshot
    String hinduMonth = '';
    final day1 = snapshots[1];
    if (day1 != null) {
      hinduMonth = _hinduMonthName(day1.sunriseTithi, lang);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Month navigation header
              _MonthHeader(
                month: month,
                hinduMonth: hinduMonth,
                s: s,
                lang: lang,
                onPrev: () => _changeMonth(ref, -1),
                onNext: () => _changeMonth(ref, 1),
                onToday: isCurrentMonth
                    ? null
                    : () => ref
                        .read(calendarMonthProvider.notifier)
                        .state = DateTime(today.year, today.month, 1),
              ),
              // Weekday labels
              _WeekdayHeader(s: s),
              // Calendar grid
              _CalendarGrid(
                month: month,
                snapshots: snapshots,
                festivalDays: festivalDays,
                today: today,
                s: s,
                lang: lang,
              ),
              const Divider(color: MandirTheme.cardBorder, height: 1),
              const SizedBox(height: 16),
              // Festival list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    s.monthFestivals,
                    style: GoogleFonts.mukta(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: MandirTheme.textDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        // Month festivals list
        if (monthFestivals.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                s.noMonthFestivals,
                style: GoogleFonts.mukta(
                  fontSize: 15,
                  color: MandirTheme.textMuted,
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final entry = monthFestivals[i];
                final dayNum = entry.key;
                final festName = entry.value;
                final snap = snapshots[dayNum];
                final tithi = snap?.sunriseTithi;
                return _FestivalListItem(
                  day: dayNum,
                  month: month,
                  festName: festName,
                  tithi: tithi,
                  s: s,
                );
              },
              childCount: monthFestivals.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  void _changeMonth(WidgetRef ref, int delta) {
    final current = ref.read(calendarMonthProvider);
    ref.read(calendarMonthProvider.notifier).state = DateTime(
      current.year,
      current.month + delta,
      1,
    );
  }

  String _hinduMonthName(TithiInfo tithi, String lang) {
    final m = tithi.month;
    if (lang == 'en') return m.displayName;
    return _hinduMonthMr(m.name);
  }

  String _hinduMonthMr(String name) {
    const map = {
      'Chaitra': 'चैत्र',
      'Vaishakha': 'वैशाख',
      'Jyeshtha': 'ज्येष्ठ',
      'Ashadha': 'आषाढ',
      'Shravana': 'श्रावण',
      'Bhadrapada': 'भाद्रपद',
      'Ashvina': 'आश्विन',
      'Kartika': 'कार्तिक',
      'Margashirsha': 'मार्गशीर्ष',
      'Pausha': 'पौष',
      'Magha': 'माघ',
      'Phalguna': 'फाल्गुन',
    };
    return map[name] ?? name;
  }
}

// ── Month header ──────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.hinduMonth,
    required this.s,
    required this.lang,
    required this.onPrev,
    required this.onNext,
    this.onToday,
  });

  final DateTime month;
  final String hinduMonth;
  final CalendarStrings s;
  final String lang;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) {
    final monthName = s.monthNames[month.month - 1];
    final year = month.year.toString();

    return Container(
      color: MandirTheme.surfaceWhite,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded,
                color: MandirTheme.primarySaffron, size: 30),
            onPressed: onPrev,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$monthName $year',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mukta(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: MandirTheme.textDark,
                  ),
                ),
                if (hinduMonth.isNotEmpty)
                  Text(
                    hinduMonth,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mukta(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: MandirTheme.primarySaffron,
                    ),
                  ),
                if (onToday != null)
                  GestureDetector(
                    onTap: onToday,
                    child: Text(
                      s.today,
                      style: GoogleFonts.mukta(
                        fontSize: 12,
                        color: MandirTheme.goldenAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded,
                color: MandirTheme.primarySaffron, size: 30),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

// ── Weekday header row ────────────────────────────────────────────────────

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.s});
  final CalendarStrings s;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MandirTheme.surfaceWhite,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Row(
        children: List.generate(7, (i) {
          final isSun = i == 0;
          return Expanded(
            child: Center(
              child: Text(
                s.weekdays[i],
                style: GoogleFonts.mukta(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSun
                      ? const Color(0xFFB71C1C)
                      : MandirTheme.textMuted,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Calendar grid ─────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.snapshots,
    required this.festivalDays,
    required this.today,
    required this.s,
    required this.lang,
  });

  final DateTime month;
  final Map<int, TithiDaySnapshot> snapshots;
  final Set<int> festivalDays;
  final DateTime today;
  final CalendarStrings s;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    // weekday: 1=Mon…7=Sun. We want Sunday=0.
    final startOffset = firstDayOfMonth.weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Container(
      color: MandirTheme.backgroundCream,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final day = cellIndex - startOffset + 1;
              if (day < 1 || day > daysInMonth) {
                return const Expanded(child: SizedBox());
              }
              return Expanded(
                child: _CalendarCell(
                  day: day,
                  month: month,
                  snapshot: snapshots[day],
                  isFestival: festivalDays.contains(day),
                  isToday: today.year == month.year &&
                      today.month == month.month &&
                      today.day == day,
                  isSunday: col == 0,
                  lang: lang,
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

// ── Calendar cell ─────────────────────────────────────────────────────────

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.day,
    required this.month,
    required this.snapshot,
    required this.isFestival,
    required this.isToday,
    required this.isSunday,
    required this.lang,
  });

  final int day;
  final DateTime month;
  final TithiDaySnapshot? snapshot;
  final bool isFestival;
  final bool isToday;
  final bool isSunday;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final isKrishna = snapshot?.sunriseTithi.paksha == Paksha.krishna;

    Color cellBg = isKrishna
        ? const Color(0xFFF0EBF8)
        : MandirTheme.backgroundCream;
    final textColor = isSunday
        ? const Color(0xFFB71C1C)
        : MandirTheme.textDark;
    final tithiColor = isSunday
        ? const Color(0xFFB71C1C).withValues(alpha: 0.7)
        : MandirTheme.textMuted;

    final tithi = snapshot?.sunriseTithi;
    final tithiShort = tithi != null ? _shortTithi(tithi, lang) : '';

    return GestureDetector(
      onTap: () {
        final date = DateTime(month.year, month.month, day);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CalendarDaySheet(date: date),
        );
      },
      child: Container(
        height: 62,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday ? Colors.transparent : cellBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            // Saffron circle for today
            if (isToday)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: MandirTheme.primarySaffron,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    day.toString(),
                    style: GoogleFonts.mukta(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isToday ? Colors.white : textColor,
                      height: 1,
                    ),
                  ),
                  if (tithiShort.isNotEmpty)
                    Text(
                      tithiShort,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.mukta(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: isToday
                            ? Colors.white.withValues(alpha: 0.85)
                            : tithiColor,
                        height: 1.2,
                      ),
                    ),
                ],
              ),
            ),
            // Festival red dot
            if (isFestival)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isToday
                        ? Colors.white
                        : const Color(0xFFB71C1C),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _shortTithi(TithiInfo tithi, String lang) {
    final num = tithi.tithiInPaksha.toString();
    final name = tithi.tithiName;
    final short = name.length > 6 ? name.substring(0, 6) : name;
    return '$num/$short';
  }
}

// ── Festival list item ────────────────────────────────────────────────────

class _FestivalListItem extends StatelessWidget {
  const _FestivalListItem({
    required this.day,
    required this.month,
    required this.festName,
    required this.tithi,
    required this.s,
  });

  final int day;
  final DateTime month;
  final String festName;
  final TithiInfo? tithi;
  final CalendarStrings s;

  @override
  Widget build(BuildContext context) {
    final date = DateTime(month.year, month.month, day);
    final tithiStr = tithi != null
        ? '${tithi!.tithiInPaksha}/${tithi!.tithiName}'
        : '';

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CalendarDaySheet(date: date),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: MandirTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MandirTheme.cardBorder),
        ),
        child: Row(
          children: [
            // Day badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: MandirTheme.primarySaffron.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: GoogleFonts.mukta(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: MandirTheme.primarySaffron,
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
                    festName,
                    style: GoogleFonts.mukta(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: MandirTheme.cardTitle,
                    ),
                  ),
                  if (tithiStr.isNotEmpty)
                    Text(
                      tithiStr,
                      style: GoogleFonts.mukta(
                        fontSize: 13,
                        color: MandirTheme.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: MandirTheme.arrowIcon,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tithi_engine/tithi_engine.dart';

import '../../../core/theme/theme.dart';
import '../../../domain/logic/nakshatra_engine.dart';
import '../../../domain/logic/rahu_kaal_engine.dart';
import '../../../services/tithi_engine_service.dart';
import '../../calendar/calendar_strings.dart';
import '../../providers/calendar_provider.dart';

/// Bottom sheet displayed when the user taps a date in the calendar grid.
class CalendarDaySheet extends ConsumerWidget {
  const CalendarDaySheet({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = Localizations.localeOf(context).languageCode;
    final s = CalendarStrings(lang);
    final snapshotAsync = ref.watch(calendarDaySnapshotProvider(date));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: MandirTheme.backgroundCream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MandirTheme.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              _SheetHeader(date: date, lang: lang, s: s),
              const Divider(height: 1, color: MandirTheme.cardBorder),
              // Body
              Expanded(
                child: snapshotAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: MandirTheme.primarySaffron,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: GoogleFonts.mukta(color: MandirTheme.textMuted),
                    ),
                  ),
                  data: (snap) => snap == null
                      ? Center(
                          child: Text(
                            s.loading,
                            style: GoogleFonts.mukta(
                                color: MandirTheme.textMuted),
                          ),
                        )
                      : _SheetBody(
                          date: date,
                          snapshot: snap,
                          lang: lang,
                          s: s,
                          scrollCtrl: scrollCtrl,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.date,
    required this.lang,
    required this.s,
  });

  final DateTime date;
  final String lang;
  final CalendarStrings s;

  @override
  Widget build(BuildContext context) {
    final dayName = s.dayNames[date.weekday % 7];
    final monthName = s.monthNames[date.month - 1];
    final day = date.day.toString();
    final year = date.year.toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: MandirTheme.primarySaffron,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                day,
                style: GoogleFonts.mukta(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: GoogleFonts.mukta(
                    fontSize: 14,
                    color: MandirTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$monthName $year',
                  style: GoogleFonts.mukta(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: MandirTheme.textDark,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.date,
    required this.snapshot,
    required this.lang,
    required this.s,
    required this.scrollCtrl,
  });

  final DateTime date;
  final TithiDaySnapshot snapshot;
  final String lang;
  final CalendarStrings s;
  final ScrollController scrollCtrl;

  @override
  Widget build(BuildContext context) {
    final tithi = snapshot.sunriseTithi;
    final offset = snapshot.offset;
    final sunriseLocal = snapshot.sunriseUtc.add(offset);
    final sunsetLocal = snapshot.sunsetUtc.add(offset);

    // Nakshatra & Yoga (computed at solar noon of the day)
    final noon = DateTime.utc(date.year, date.month, date.day, 6); // ~noon IST
    final nIdx = NakshatraEngine.nakshatraIndex(noon);
    final yIdx = NakshatraEngine.yogaIndex(noon);

    // Rahu Kaal & Gulika
    final weekday = date.weekday; // 1=Mon…7=Sun
    final (rahuStart, rahuEnd) =
        RahuKaalEngine.rahuKaal(sunriseLocal, sunsetLocal, weekday);
    final (gulikaStart, gulikaEnd) =
        RahuKaalEngine.gulikaKaal(sunriseLocal, sunsetLocal, weekday);

    // Karana
    final karana = snapshot.sunriseKarana;
    final karanaName = karana != null ? _karanaName(karana.halfIndex) : '—';

    // Tithi end time
    final sunriseSegment = snapshot.sunriseSegment;
    final tithiEndLocal = sunriseSegment.endIsTransition
        ? sunriseSegment.endUtc.add(offset)
        : null;

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _InfoCard(children: [
          _InfoRow(
            label: s.tithi,
            value: _tithiDisplay(tithi, lang, s),
            icon: Icons.brightness_3_outlined,
          ),
          if (tithiEndLocal != null)
            _InfoRow(
              label: s.tithiEnd,
              value: DateFormat('HH:mm').format(tithiEndLocal),
              icon: Icons.schedule,
            ),
          _InfoRow(
            label: s.paksha,
            value: tithi.paksha == Paksha.shukla ? s.shuklaPaksha : s.krishnaPaksha,
            icon: Icons.nights_stay_outlined,
          ),
        ]),
        const SizedBox(height: 10),
        _InfoCard(children: [
          _InfoRow(
            label: s.nakshatra,
            value: NakshatraEngine.nakshatraName(nIdx, lang),
            icon: Icons.star_outline_rounded,
          ),
          _InfoRow(
            label: s.yoga,
            value: NakshatraEngine.yogaName(yIdx, lang),
            icon: Icons.auto_awesome_outlined,
          ),
          _InfoRow(
            label: s.karana,
            value: karanaName,
            icon: Icons.schedule_outlined,
          ),
        ]),
        const SizedBox(height: 10),
        _InfoCard(children: [
          _InfoRow(
            label: s.sunrise,
            value: DateFormat('HH:mm').format(sunriseLocal),
            icon: Icons.wb_sunny_outlined,
          ),
          _InfoRow(
            label: s.sunset,
            value: DateFormat('HH:mm').format(sunsetLocal),
            icon: Icons.nightlight_round_outlined,
          ),
        ]),
        const SizedBox(height: 10),
        _InfoCard(children: [
          _InfoRow(
            label: s.rahuKaal,
            value: RahuKaalEngine.format(rahuStart, rahuEnd, lang),
            icon: Icons.remove_circle_outline,
            valueColor: const Color(0xFFB71C1C),
          ),
          _InfoRow(
            label: s.gulikaKaal,
            value: RahuKaalEngine.format(gulikaStart, gulikaEnd, lang),
            icon: Icons.do_not_disturb_outlined,
            valueColor: const Color(0xFFB71C1C),
          ),
        ]),
        const SizedBox(height: 12),
        // Festivals
        Text(
          s.festivals,
          style: GoogleFonts.mukta(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: MandirTheme.textDark,
          ),
        ),
        const SizedBox(height: 6),
        if (snapshot.observances.isEmpty)
          Text(
            s.noFestivals,
            style: GoogleFonts.mukta(
              fontSize: 15,
              color: MandirTheme.textMuted,
            ),
          )
        else
          ...snapshot.observances.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _FestivalChip(name: f.name),
            ),
          ),
      ],
    );
  }

  String _tithiDisplay(TithiInfo tithi, String lang, CalendarStrings s) {
    final num = tithi.tithiInPaksha;
    final name = tithi.tithiName;
    if (lang == 'en') return '$num. $name';
    return '$num. $name';
  }

  String _karanaName(int halfIndex) {
    // 60 half-tithis; first 7 are variable (0-6), then 4 fixed repeat
    final variableKaranas = [
      'Bava', 'Balava', 'Kaulava', 'Taitila', 'Garija', 'Vanija', 'Vishti',
    ];
    const fixedKaranas = ['Shakuni', 'Chatushpada', 'Naga', 'Kimstughna'];

    final idx = halfIndex.clamp(0, 59);
    if (idx == 0) return fixedKaranas[3]; // Kimstughna
    if (idx == 57) return fixedKaranas[0]; // Shakuni
    if (idx == 58) return fixedKaranas[1]; // Chatushpada
    if (idx == 59) return fixedKaranas[2]; // Naga
    return variableKaranas[(idx - 1) % 7];
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MandirTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MandirTheme.cardBorder),
      ),
      child: Column(
        children: List.generate(
          children.length * 2 - 1,
          (i) => i.isEven
              ? children[i ~/ 2]
              : const Divider(height: 1, indent: 16, endIndent: 16, color: MandirTheme.cardBorder),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: MandirTheme.primarySaffron),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.mukta(
              fontSize: 15,
              color: MandirTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.mukta(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: valueColor ?? MandirTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _FestivalChip extends StatelessWidget {
  const _FestivalChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MandirTheme.primarySaffron.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: MandirTheme.primarySaffron.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.celebration_outlined,
            size: 16,
            color: MandirTheme.primarySaffron,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.mukta(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: MandirTheme.cardTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

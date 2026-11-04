import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/birth_profile.dart';
import '../../services/kundali/kundali_service.dart';
import '../../services/kundali/vedic_astro_engine.dart';
import '../kundali/kundali_strings.dart';
import '../kundali/north_indian_chart.dart';
import '../providers/locale_provider.dart';
import 'kundali_screen.dart';

enum _ChartKind { lagna, chandra, navamsa }

class KundaliResultScreen extends ConsumerStatefulWidget {
  const KundaliResultScreen({super.key, required this.profile});

  final BirthProfile profile;

  @override
  ConsumerState<KundaliResultScreen> createState() => _KundaliResultScreenState();
}

class _KundaliResultScreenState extends ConsumerState<KundaliResultScreen> {
  late final KundaliData _data = KundaliService.calculate(widget.profile);
  late final Duration _offset = KundaliService.birthOffset(widget.profile);
  _ChartKind _kind = _ChartKind.lagna;

  List<List<ChartToken>> _houses(KundaliStrings s, int firstRashi) {
    final houses = List.generate(12, (_) => <ChartToken>[]);
    int houseOfRashi(int rashi) => (rashi - firstRashi + 12) % 12;

    if (_kind != _ChartKind.chandra) {
      final lagnaRashi =
          _kind == _ChartKind.navamsa ? _data.lagnaNavamsa : _data.lagnaRashi;
      houses[houseOfRashi(lagnaRashi)].add(ChartToken(s.lagnaShort, highlight: true));
    }
    for (final g in _data.grahas) {
      final rashi = _kind == _ChartKind.navamsa ? g.navamsaRashi : g.rashi;
      final label = g.isRetrograde
          ? '${s.grahaShort(g.graha)}(${s.retroMark})'
          : s.grahaShort(g.graha);
      houses[houseOfRashi(rashi)].add(ChartToken(
        label,
        highlight: _kind == _ChartKind.chandra && g.graha == Graha.moon,
      ));
    }
    return houses;
  }

  @override
  Widget build(BuildContext context) {
    final s = KundaliStrings(ref.watch(localeProvider).languageCode);
    final p = widget.profile;
    final firstRashi = switch (_kind) {
      _ChartKind.lagna => _data.lagnaRashi,
      _ChartKind.chandra => _data.moon.rashi,
      _ChartKind.navamsa => _data.lagnaNavamsa,
    };

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            KundaliHeader(title: p.name),
            const SizedBox(height: 4),
            _BirthSummary(profile: p, offset: _offset, s: s),
            const SizedBox(height: 16),
            _KindSelector(
              selected: _kind,
              labels: {
                _ChartKind.lagna: s.lagnaChart,
                _ChartKind.chandra: s.chandraChart,
                _ChartKind.navamsa: s.navamsaChart,
              },
              onChanged: (k) => setState(() => _kind = k),
            ),
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: NorthIndianChart(
                  firstRashi: firstRashi,
                  houses: _houses(s, firstRashi),
                  formatNumber: s.num,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.chartNote,
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(fontSize: 12.5, color: MandirTheme.textMuted),
            ),
            const SizedBox(height: 20),
            _KeyFacts(data: _data, s: s),
            const SizedBox(height: 24),
            _SectionTitle(s.grahaPositions),
            const SizedBox(height: 8),
            _PlanetTable(data: _data, s: s),
            const SizedBox(height: 24),
            _SectionTitle(s.vimshottari),
            const SizedBox(height: 8),
            _DashaList(data: _data, s: s),
          ],
        ),
      ),
    );
  }
}

class _BirthSummary extends StatelessWidget {
  const _BirthSummary({required this.profile, required this.offset, required this.s});

  final BirthProfile profile;
  final Duration offset;
  final KundaliStrings s;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.mukta(fontSize: 14.5, color: MandirTheme.cardSubtitle, height: 1.35);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${s.date(profile.birthLocal)} • ${s.time(profile.birthLocal)}', style: style),
        Text(profile.place.label, style: style),
        Text(
          '${s.utcOffset}: ${s.offset(offset)}',
          style: style.copyWith(color: MandirTheme.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}

class _KindSelector extends StatelessWidget {
  const _KindSelector({required this.selected, required this.labels, required this.onChanged});

  final _ChartKind selected;
  final Map<_ChartKind, String> labels;
  final ValueChanged<_ChartKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MandirTheme.chipBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MandirTheme.chipBorder),
      ),
      child: Row(
        children: [
          for (final kind in _ChartKind.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(kind),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kind == selected ? MandirTheme.primarySaffron : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    labels[kind]!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mukta(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: kind == selected ? Colors.white : MandirTheme.chipText,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KeyFacts extends StatelessWidget {
  const _KeyFacts({required this.data, required this.s});

  final KundaliData data;
  final KundaliStrings s;

  @override
  Widget build(BuildContext context) {
    final moon = data.moon;
    final facts = [
      (s.lagna, s.rashiName(data.lagnaRashi), s.degrees(data.lagnaLongitude % 30)),
      (s.rashi, s.rashiName(moon.rashi), s.degrees(moon.degreeInRashi)),
      (
        s.nakshatra,
        s.nakshatraName(moon.nakshatra),
        '${s.pada} ${s.num(moon.pada)} • ${s.grahaName(KundaliData.nakshatraLord(moon.nakshatra))}',
      ),
      (s.suryaRashi, s.rashiName(data.sun.rashi), s.degrees(data.sun.degreeInRashi)),
    ];

    return KundaliFlatCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < facts.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16, color: MandirTheme.cardBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      facts[i].$1,
                      style: GoogleFonts.mukta(fontSize: 15, color: MandirTheme.textMuted),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        facts[i].$2,
                        style: GoogleFonts.mukta(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: MandirTheme.cardTitle,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        facts[i].$3,
                        style: GoogleFonts.mukta(fontSize: 13, color: MandirTheme.cardSubtitle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.mukta(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: MandirTheme.textDark,
        ),
      );
}

class _PlanetTable extends StatelessWidget {
  const _PlanetTable({required this.data, required this.s});

  final KundaliData data;
  final KundaliStrings s;

  @override
  Widget build(BuildContext context) {
    final head = GoogleFonts.mukta(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: MandirTheme.textMuted,
    );
    final cell = GoogleFonts.mukta(fontSize: 14.5, color: MandirTheme.textDark, height: 1.25);

    TableRow row(List<Widget> cells, {Color? color}) => TableRow(
          decoration: BoxDecoration(color: color),
          children: [
            for (final c in cells)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: c),
          ],
        );

    return KundaliFlatCard(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.25),
          1: FlexColumnWidth(1.35),
          2: FlexColumnWidth(1.6),
          3: IntrinsicColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          row([
            Text(s.graha, style: head),
            Text(s.sign, style: head),
            Text(s.nakshatra, style: head),
            Text(s.house, style: head, textAlign: TextAlign.center),
          ]),
          row([
            Text(s.lagna, style: cell.copyWith(fontWeight: FontWeight.w700, color: MandirTheme.primarySaffron)),
            _twoLine(s.rashiName(data.lagnaRashi), s.degrees(data.lagnaLongitude % 30), cell),
            _twoLine(
              s.nakshatraName(nakshatraOf(data.lagnaLongitude)),
              '${s.pada} ${s.num(padaOf(data.lagnaLongitude))}',
              cell,
            ),
            Text(s.num(1), style: cell, textAlign: TextAlign.center),
          ], color: MandirTheme.chipBackground.withValues(alpha: 0.5)),
          for (final g in data.grahas)
            row([
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: s.grahaName(g.graha), style: cell.copyWith(fontWeight: FontWeight.w700)),
                  if (g.isRetrograde)
                    TextSpan(
                      text: ' (${s.retroMark})',
                      style: cell.copyWith(color: MandirTheme.primarySaffron, fontSize: 13),
                    ),
                ]),
              ),
              _twoLine(s.rashiName(g.rashi), s.degrees(g.degreeInRashi), cell),
              _twoLine(s.nakshatraName(g.nakshatra), '${s.pada} ${s.num(g.pada)}', cell),
              Text(s.num(data.houseOf(g)), style: cell, textAlign: TextAlign.center),
            ]),
        ],
      ),
    );
  }

  Widget _twoLine(String top, String bottom, TextStyle style) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(top, style: style),
          Text(bottom, style: style.copyWith(fontSize: 12.5, color: MandirTheme.textMuted)),
        ],
      );
}

class _DashaList extends StatefulWidget {
  const _DashaList({required this.data, required this.s});

  final KundaliData data;
  final KundaliStrings s;

  @override
  State<_DashaList> createState() => _DashaListState();
}

class _DashaListState extends State<_DashaList> {
  late final List<VimshottariPeriod> _mahas = widget.data.mahadashas();
  late int? _expanded = _mahas.indexWhere((m) => m.contains(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final now = DateTime.now();

    return KundaliFlatCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < _mahas.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: MandirTheme.cardBorder),
            _periodTile(
              _mahas[i],
              isCurrent: _mahas[i].contains(now),
              expanded: _expanded == i,
              onTap: () => setState(() => _expanded = _expanded == i ? null : i),
            ),
            if (_expanded == i)
              Container(
                color: MandirTheme.chipBackground.withValues(alpha: 0.45),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        s.antardasha,
                        style: GoogleFonts.mukta(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: MandirTheme.textMuted,
                        ),
                      ),
                    ),
                    for (final a in KundaliData.antardashas(_mahas[i])
                        .where((a) => a.end.isAfter(widget.data.birthUtc)))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${s.grahaName(_mahas[i].lord)} – ${s.grahaName(a.lord)}',
                                style: GoogleFonts.mukta(
                                  fontSize: 14,
                                  fontWeight: a.contains(now) ? FontWeight.w800 : FontWeight.w500,
                                  color: a.contains(now)
                                      ? MandirTheme.primarySaffron
                                      : MandirTheme.textDark,
                                ),
                              ),
                            ),
                            Text(
                              '${s.monthYear(a.start)} – ${s.monthYear(a.end)}',
                              style: GoogleFonts.mukta(fontSize: 13, color: MandirTheme.cardSubtitle),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _periodTile(
    VimshottariPeriod m, {
    required bool isCurrent,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    final s = widget.s;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        s.grahaName(m.lord),
                        style: GoogleFonts.mukta(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: isCurrent ? MandirTheme.primarySaffron : MandirTheme.textDark,
                          height: 1.2,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                          decoration: const ShapeDecoration(
                            color: MandirTheme.primarySaffron,
                            shape: StadiumBorder(),
                          ),
                          child: Text(
                            s.current,
                            style: GoogleFonts.mukta(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${s.date(m.start.isBefore(widget.data.birthUtc) ? widget.data.birthUtc : m.start)}'
                    ' – ${s.date(m.end)}',
                    style: GoogleFonts.mukta(fontSize: 13.5, color: MandirTheme.cardSubtitle),
                  ),
                ],
              ),
            ),
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: MandirTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

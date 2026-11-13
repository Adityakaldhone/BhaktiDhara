import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tithi_engine/tithi_engine.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/panchang_city.dart';
import '../../services/tithi_engine_names.dart';
import '../../services/tithi_engine_service.dart';
import '../providers/panchang_provider.dart';
import 'panchang_strings.dart';

const _verifiedColor = Color(0xFF2E7D32);

String _digits(String s, String lang) {
  if (lang == 'en') return s;
  const dev = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
  return s.replaceAllMapped(RegExp(r'\d'), (m) => dev[int.parse(m[0]!)]);
}

/// "15 सप्टें, मंगळ" style date for a civil (UTC-midnight) engine date.
String engineDateLabel(DateTime d, String lang, {bool withYear = false}) {
  const monthsMr = ['जाने', 'फेब्रु', 'मार्च', 'एप्रि', 'मे', 'जून', 'जुलै', 'ऑग', 'सप्टें', 'ऑक्टो', 'नोव्हें', 'डिसें'];
  const monthsHi = ['जन', 'फ़र', 'मार्च', 'अप्रै', 'मई', 'जून', 'जुला', 'अग', 'सितं', 'अक्टू', 'नवं', 'दिसं'];
  const monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const daysMr = ['सोम', 'मंगळ', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'];
  const daysHi = ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'];
  const daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final months = lang == 'en' ? monthsEn : (lang == 'hi' ? monthsHi : monthsMr);
  final days = lang == 'en' ? daysEn : (lang == 'hi' ? daysHi : daysMr);
  final year = withYear ? ' ${d.year}' : '';
  return _digits(
      '${d.day} ${months[d.month - 1]}$year, ${days[d.weekday - 1]}', lang);
}

String _clock(DateTime local, String lang) {
  final h12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final hm =
      '${h12.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '${_digits(hm, lang)} ${local.hour >= 12 ? 'PM' : 'AM'}';
}

/// Accuracy tier, month system and the live tithi, shown on the Today card.
class PanchangEngineStatus extends StatelessWidget {
  const PanchangEngineStatus({
    super.key,
    required this.snapshot,
    required this.s,
  });

  final TithiDaySnapshot snapshot;
  final PanchangStrings s;

  @override
  Widget build(BuildContext context) {
    final names = TithiEngineNames(s.lang);
    final verified = snapshot.source == LocationSource.cityCorrected;
    final current = snapshot.currentTithi;
    final showLive = current != null &&
        current.tithiNumber != snapshot.sunriseTithi.tithiNumber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _Chip(
              icon: verified ? Icons.verified_rounded : Icons.public_rounded,
              text: names.locationSource(snapshot.source),
              color: verified ? _verifiedColor : MandirTheme.textMuted,
            ),
            _Chip(
              icon: Icons.calendar_view_month_rounded,
              text: s.monthSystemNote(names.monthSystem(snapshot.monthSystem)),
              color: MandirTheme.secondaryMaroon,
            ),
          ],
        ),
        if (showLive) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.brightness_3_rounded,
                  size: 16, color: MandirTheme.primarySaffron),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  s.liveTithi(
                      '${names.pakshaShort(current.paksha)} ${names.tithi(current.tithiNumber)}'),
                  style: GoogleFonts.mukta(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8D5A00),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.mukta(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Next festivals and monthly vrats, computed offline with muhurta rules.
class UpcomingObservancesCard extends ConsumerWidget {
  const UpcomingObservancesCard({super.key, required this.s});

  final PanchangStrings s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(upcomingObservancesProvider);
    final items = itemsAsync.valueOrNull ?? const <FestivalDate>[];
    final city = ref.watch(selectedPanchangCityProvider);
    final selected = ref.watch(selectedPanchangDateProvider);
    final engine = ref.watch(tithiEngineServiceProvider);
    final system = engine.monthSystemFor(city);
    final names = TithiEngineNames(s.lang);
    final from = DateTime.utc(selected.year, selected.month, selected.day);

    return Container(
      key: const Key('panchang-upcoming-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8D4),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFFBA471A),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.upcomingTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2C1E14),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            s.upcomingHint,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8C7565),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF0E4D4), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                if (itemsAsync.isLoading && items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFBA471A),
                        ),
                      ),
                    ),
                  ),
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 52,
                      endIndent: 4,
                      color: Color(0xFFF6ECE0),
                    ),
                  _ObservanceRow(
                    fd: items[i],
                    label: names.observance(items[i].id, items[i].name),
                    tithi: names.tithiLabel(engine.displayInfo(items[i], system)),
                    muhurta: items[i].muhurtaStart == null || items[i].muhurtaEnd == null
                        ? null
                        : '${names.muhurtaRule(items[i].muhurta)}: '
                            '${_clock(items[i].muhurtaStart!.add(engine.offsetOf(city)), s.lang)} – '
                            '${_clock(items[i].muhurtaEnd!.add(engine.offsetOf(city)), s.lang)}',
                    days: items[i].date.difference(from).inDays,
                    s: s,
                    onTap: () => ref.read(selectedPanchangDateProvider.notifier).state =
                        DateTime(items[i].date.year, items[i].date.month, items[i].date.day),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('panchang-tithi-finder-button'),
              onTap: () => showTithiFinderSheet(context, s.lang),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF1D7BD), width: 1.1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Color(0xFF8D3F1B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.tithiFinder,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8D3F1B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObservanceRow extends StatelessWidget {
  const _ObservanceRow({
    required this.fd,
    required this.label,
    required this.tithi,
    required this.muhurta,
    required this.days,
    required this.s,
    required this.onTap,
  });

  final FestivalDate fd;
  final String label;
  final String tithi;
  final String? muhurta;
  final int days;
  final PanchangStrings s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final monthStr =
        engineDateLabel(fd.date, s.lang).split(' ')[1].replaceAll(',', '');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        child: Row(
          children: [
            Container(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECDD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _digits('${fd.date.day}', s.lang),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF6D3214),
                      height: 1.1,
                    ),
                  ),
                  Text(
                    monthStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8C5332),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C1E14),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fd.recurring ? '$tithi • ${s.monthly}' : tithi,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8C7565),
                      height: 1.2,
                    ),
                  ),
                  if (muhurta != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      muhurta!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFBA471A),
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.inDays(days),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8C7565),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFFB5A495),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showTithiFinderSheet(BuildContext context, String lang) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TithiFinderSheet(lang: lang),
  );
}

/// Tithi → Gregorian date, adhika-aware, plus the next occurrence.
class TithiFinderSheet extends ConsumerStatefulWidget {
  const TithiFinderSheet({super.key, required this.lang});

  final String lang;

  @override
  ConsumerState<TithiFinderSheet> createState() => _TithiFinderSheetState();
}

class _TithiFinderSheetState extends ConsumerState<TithiFinderSheet> {
  late LunarMonth _month;
  Paksha _paksha = Paksha.shukla;
  int _day = 1;
  late int _year;

  PanchangStrings get s => PanchangStrings(widget.lang);
  TithiEngineNames get names => TithiEngineNames(widget.lang);

  @override
  void initState() {
    super.initState();
    final snap = ref.read(tithiDaySnapshotProvider).valueOrNull;
    _month = snap?.sunriseTithi.month ?? LunarMonth.chaitra;
    _paksha = snap?.sunriseTithi.paksha ?? Paksha.shukla;
    _day = snap?.sunriseTithi.tithiInPaksha ?? 1;
    _year = ref.read(selectedPanchangDateProvider).year;
  }

  void _open(DateTime d) {
    ref.read(selectedPanchangDateProvider.notifier).state =
        DateTime(d.year, d.month, d.day);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final engine = ref.watch(tithiEngineServiceProvider);
    final PanchangCity city = ref.watch(selectedPanchangCityProvider);
    final tithi =
        _paksha == Paksha.shukla ? Tithi.shukla(_day) : Tithi.krishna(_day);

    ({List<DateTime> regular, DateTime? adhika})? found;
    DateTime? next;
    try {
      found = engine.findTithiDates(city, _month, tithi, _year);
      next = engine.findNext(city, _month, tithi);
    } catch (_) {
      found = null;
    }

    final system = names.monthSystem(engine.monthSystemFor(city));

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.78,
      child: Material(
        color: const Color(0xFFFFFBF2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.tithiFinder,
              style: GoogleFonts.mukta(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: MandirTheme.textDark,
              ),
            ),
            Text(
              '${s.finderHint}\n${s.monthSystemNote(system)} • ${city.localizedName(widget.lang)}',
              style: GoogleFonts.mukta(fontSize: 14, color: MandirTheme.textMuted),
            ),
            const SizedBox(height: 14),
            _label(s.finderMonth),
            DropdownButtonFormField<LunarMonth>(
              key: const Key('tithi-finder-month'),
              initialValue: _month,
              decoration: _decoration(),
              items: [
                for (final m in LunarMonth.values)
                  DropdownMenuItem(value: m, child: Text(names.month(m))),
              ],
              onChanged: (m) => setState(() => _month = m ?? _month),
            ),
            const SizedBox(height: 12),
            _label(s.finderPaksha),
            SegmentedButton<Paksha>(
              segments: [
                for (final p in Paksha.values)
                  ButtonSegment(value: p, label: Text(names.paksha(p))),
              ],
              selected: {_paksha},
              onSelectionChanged: (v) => setState(() => _paksha = v.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor:
                    MandirTheme.primarySaffron.withValues(alpha: 0.15),
                selectedForegroundColor: MandirTheme.secondaryMaroon,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(s.finderTithi),
                      DropdownButtonFormField<int>(
                        key: const Key('tithi-finder-tithi'),
                        initialValue: _day,
                        decoration: _decoration(),
                        items: [
                          for (var d = 1; d <= 15; d++)
                            DropdownMenuItem(
                              value: d,
                              child: Text(names.tithi(
                                  _paksha == Paksha.shukla ? d : d + 15)),
                            ),
                        ],
                        onChanged: (d) => setState(() => _day = d ?? _day),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(s.finderYear),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0CEB5)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.remove),
                              onPressed: _year > 1901
                                  ? () => setState(() => _year--)
                                  : null,
                            ),
                            Expanded(
                              child: Text(
                                _digits('$_year', widget.lang),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.mukta(
                                    fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.add),
                              onPressed: _year < 2099
                                  ? () => setState(() => _year++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (found != null) ...[
              _label(s.finderDates),
              if (found.regular.isEmpty)
                Text(s.finderNone,
                    style: GoogleFonts.mukta(
                        fontSize: 15, color: MandirTheme.textMuted))
              else
                for (final d in found.regular)
                  _ResultTile(
                      date: d, lang: widget.lang, onTap: () => _open(d)),
              if (found.adhika != null) ...[
                const SizedBox(height: 8),
                _label(s.finderAdhika),
                _ResultTile(
                  date: found.adhika!,
                  lang: widget.lang,
                  onTap: () => _open(found!.adhika!),
                ),
              ],
            ],
            if (next != null) ...[
              const SizedBox(height: 8),
              _label(s.finderNext),
              _ResultTile(
                date: next,
                lang: widget.lang,
                highlight: true,
                onTap: () => _open(next!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: GoogleFonts.mukta(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: MandirTheme.primarySaffron,
          ),
        ),
      );

  InputDecoration _decoration() => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0CEB5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0CEB5)),
        ),
      );
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.date,
    required this.lang,
    required this.onTap,
    this.highlight = false,
  });

  final DateTime date;
  final String lang;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      color: highlight ? const Color(0xFFFFF3D6) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: highlight ? const Color(0xFFD4AF37) : const Color(0xFFEBD9BD),
        ),
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.event_available_rounded,
            color: MandirTheme.primarySaffron),
        title: Text(
          engineDateLabel(date, lang, withYear: true),
          style: GoogleFonts.mukta(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.chevron_right,
            color: MandirTheme.primarySaffron),
        onTap: onTap,
      ),
    );
  }
}

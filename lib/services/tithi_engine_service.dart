import 'package:flutter/foundation.dart';
import 'package:tithi_engine/data/all.dart';
import 'package:tithi_engine/tithi_engine.dart';

import '../domain/entities/panchang_city.dart';

/// A karana (half-tithi) span, used for Karana and Bhadra (Vishti).
class KaranaSpan {
  /// Half-tithi index 0–59 (see `TithiEngineNames.karanaIndexOf`).
  final int halfIndex;
  final DateTime startUtc;
  final DateTime endUtc;

  const KaranaSpan(this.halfIndex, this.startUtc, this.endUtc);
}

/// Everything the engine knows about one panchang day at one place.
class TithiDaySnapshot {
  final DateTime date;
  final Duration offset;
  final MonthSystem monthSystem;
  final LocationSource source;

  /// Tithi prevailing at sunrise (the tithi of the day).
  final TithiInfo sunriseTithi;

  /// Tithi at this very moment; only set when the snapshot is for today.
  final TithiInfo? currentTithi;

  /// Tithi segments from ~1.5 days before to 2 days after sunrise.
  final List<TithiSegment> segments;

  final DateTime sunriseUtc;
  final DateTime sunsetUtc;
  final DateTime nextSunriseUtc;

  /// Annual festivals and monthly vrats observed on [date].
  final List<FestivalDate> observances;

  const TithiDaySnapshot({
    required this.date,
    required this.offset,
    required this.monthSystem,
    required this.source,
    required this.sunriseTithi,
    required this.currentTithi,
    required this.segments,
    required this.sunriseUtc,
    required this.sunsetUtc,
    required this.nextSunriseUtc,
    required this.observances,
  });

  /// Wall-clock time at the city for a UTC instant.
  DateTime local(DateTime utc) => utc.add(offset);

  /// Segment of the tithi that prevails at sunrise.
  TithiSegment get sunriseSegment => segments.firstWhere(
        (s) => !s.startUtc.isAfter(sunriseUtc) && s.endUtc.isAfter(sunriseUtc),
        orElse: () => segments.first,
      );

  /// Tithi that follows the sunrise tithi.
  TithiSegment? get nextSegment {
    final i = segments.indexOf(sunriseSegment);
    return i + 1 < segments.length ? segments[i + 1] : null;
  }

  /// A tithi that begins and ends between two sunrises never touches a
  /// sunrise (kshaya tithi).
  TithiSegment? get kshayaSegment {
    final next = nextSegment;
    if (next == null || next.endUtc.isAfter(nextSunriseUtc)) return null;
    return next;
  }

  /// Half-tithi karanas covering the panchang day (sunrise → next sunrise).
  List<KaranaSpan> get karanas {
    final spans = <KaranaSpan>[];
    for (final seg in segments) {
      if (!seg.startIsTransition || !seg.endIsTransition) continue;
      final mid = seg.startUtc.add(seg.endUtc.difference(seg.startUtc) ~/ 2);
      final first = (seg.tithi.tithiNumber - 1) * 2;
      for (final span in [
        KaranaSpan(first, seg.startUtc, mid),
        KaranaSpan(first + 1, mid, seg.endUtc),
      ]) {
        if (span.endUtc.isAfter(sunriseUtc) &&
            span.startUtc.isBefore(nextSunriseUtc)) {
          spans.add(span);
        }
      }
    }
    return spans;
  }

  /// Karana prevailing at sunrise.
  KaranaSpan? get sunriseKarana {
    for (final k in karanas) {
      if (!k.startUtc.isAfter(sunriseUtc) && k.endUtc.isAfter(sunriseUtc)) {
        return k;
      }
    }
    return karanas.isEmpty ? null : karanas.first;
  }
}

/// Wraps `package:tithi_engine` (Swiss-Ephemeris-verified tithi, lunar month,
/// sunrise/sunset and festival dates) for the app's [PanchangCity] model.
class TithiEngineService {
  TithiEngineService({
    this.convention = SunriseConvention.upperLimb,
    this.backgroundPreload = true,
  });

  /// Sunrise definition; upper limb matches Drik Panchang.
  final SunriseConvention convention;

  /// Whether [preloadYear] scans in a background isolate. Widget tests run in
  /// a fake-async zone that never observes an isolate finishing.
  final bool backgroundPreload;

  late final Panchang _amant = Panchang([registerAllCities],
      system: MonthSystem.amant, convention: convention);
  late final Panchang _purnimant = Panchang([registerAllCities],
      system: MonthSystem.purnimant, convention: convention);

  final Map<String, List<FestivalDate>> _yearCache = {};

  /// North Indian regions count months Purnimant; Maharashtra, Gujarat, the
  /// South and the diaspora default to Amant.
  static const _purnimantRegions = {
    'उत्तर प्रदेश',
    'मध्य प्रदेश',
    'उत्तराखंड',
    'दिल्ली NCR',
    'राजस्थान',
    'बिहार',
    'हरियाणा',
    'पंजाब',
    'हिमाचल प्रदेश',
    'झारखंड',
    'छत्तीसगड',
    'जम्मू आणि काश्मीर',
  };

  MonthSystem monthSystemFor(PanchangCity city) =>
      _purnimantRegions.contains(city.stateOrCountry)
          ? MonthSystem.purnimant
          : MonthSystem.amant;

  Panchang panchangFor(MonthSystem system) =>
      system == MonthSystem.amant ? _amant : _purnimant;

  Duration offsetOf(PanchangCity city) =>
      Duration(minutes: (city.timezoneOffsetHours * 60).round());

  static const _engineAliases = {
    'bengaluru': 'Bangalore',
    'delhi': 'Delhi',
    'new_york': 'New York',
    'san_francisco': 'San Francisco',
  };

  /// The engine's city name for [city], when it has Swiss correction tables.
  String? engineCityName(PanchangCity city) {
    final candidates = [
      _engineAliases[city.id],
      city.nameEn.split('(').first.trim(),
      city.id.replaceAll('_', ' '),
    ];
    for (final c in candidates) {
      if (c == null || c.isEmpty) continue;
      final resolved = resolveCityName(c);
      if (resolved != null && City.tryOf(resolved) != null) return resolved;
    }
    return null;
  }

  /// Named supported city when possible, otherwise raw coordinates (which
  /// still snap to a supported city's 0.1° cell when one is close enough).
  Location locationFor(PanchangCity city) {
    final name = engineCityName(city);
    if (name != null) return Location.city(name);
    return Location.at(city.latitude, city.longitude, offset: offsetOf(city));
  }

  PanchangAt _at(PanchangCity city, [MonthSystem? system]) =>
      panchangFor(system ?? monthSystemFor(city)).at(locationFor(city));

  TithiDaySnapshot day(DateTime date, PanchangCity city, {DateTime? now}) {
    final system = monthSystemFor(city);
    final at = _at(city, system);
    final offset = offsetOf(city);
    final d = DateTime.utc(date.year, date.month, date.day);

    final sunrise = at.sunrise(d);
    final sunset = at.sunset(d);
    final nextSunrise = at.sunrise(d.add(const Duration(days: 1)));
    final segments = at.tithiSegments(
      sunrise.subtract(const Duration(hours: 36)),
      sunrise.add(const Duration(hours: 48)),
      offset: offset,
    );

    TithiInfo? current;
    if (now != null) {
      final localNow = now.toUtc().add(offset);
      if (localNow.year == d.year &&
          localNow.month == d.month &&
          localNow.day == d.day) {
        current = at.tithiAtInstant(now.toUtc(), offset: offset);
      }
    }

    final observances = yearObservances(city, d.year)
        .where((f) => _sameDay(f.date, d))
        .toList();

    return TithiDaySnapshot(
      date: d,
      offset: offset,
      monthSystem: system,
      source: at.source,
      sunriseTithi: at.tithiOnDate(d),
      currentTithi: current,
      segments: segments,
      sunriseUtc: sunrise,
      sunsetUtc: sunset,
      nextSunriseUtc: nextSunrise,
      observances: observances,
    );
  }

  String _yearKey(PanchangCity city, int year) =>
      '${locationFor(city).key}|${monthSystemFor(city).name}|$year';

  /// Annual festivals (muhurta-aware) plus monthly vrats for [year], sorted.
  /// The first call per city-year scans the whole year (a few hundred ms);
  /// call [preloadYear] beforehand to do that off the UI thread.
  List<FestivalDate> yearObservances(PanchangCity city, int year) =>
      _yearCache[_yearKey(city, year)] ??= _buildYear(city, year);

  /// Fills the [yearObservances] cache for [year] in a background isolate.
  Future<void> preloadYear(PanchangCity city, int year) async {
    final key = _yearKey(city, year);
    if (_yearCache.containsKey(key)) return;
    if (!backgroundPreload) {
      _yearCache[key] = _buildYear(city, year);
      return;
    }
    final list = await compute(_buildYearIsolate, (city, year, convention));
    _yearCache[key] ??= list;
  }

  static List<FestivalDate> _buildYearIsolate(
          (PanchangCity, int, SunriseConvention) args) =>
      TithiEngineService(convention: args.$3)._buildYear(args.$1, args.$2);

  List<FestivalDate> _buildYear(PanchangCity city, int year) {
    final at = _at(city);
    final list = <FestivalDate>[];
    for (final f in observanceDefs) {
      if (f.recurring) {
        list.addAll(at.recurringDates(f, year));
      } else {
        final fd = at.dateFor(f, year);
        if (fd != null) list.add(fd);
      }
    }
    // A monthly vrat that coincides with an annual festival of the same
    // tithi (e.g. Purnima on Guru Purnima) is redundant.
    list.removeWhere((r) =>
        r.recurring &&
        list.any((a) =>
            !a.recurring &&
            a.tithiNumber == r.tithiNumber &&
            _sameDay(a.date, r.date)));
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// Next [count] observances on or after [from] (spans the year boundary).
  List<FestivalDate> upcoming(
    PanchangCity city, {
    required DateTime from,
    int count = 8,
    bool includeMonthly = true,
  }) {
    final start = DateTime.utc(from.year, from.month, from.day);
    final all = [
      ...yearObservances(city, start.year),
      ...yearObservances(city, start.year + 1),
    ].where((f) =>
        !f.date.isBefore(start) && (includeMonthly || !f.recurring));
    return all.take(count).toList();
  }

  /// Month of [fd] expressed in the city's month system. `dateFor` always
  /// reports Purnimant months, while `recurringDates` already uses [system].
  TithiInfo displayInfo(FestivalDate fd, MonthSystem system) =>
      TithiInfo.fromStored(
        tithiNumber: fd.tithiNumber,
        month: fd.month,
        storedSystem: fd.recurring ? system : MonthSystem.purnimant,
        isAdhika: fd.isAdhika,
        displaySystem: system,
      );

  /// Gregorian dates of a tithi in [year], with the month read in the city's
  /// system. Adhika months only exist in some years, so they may be empty.
  ({List<DateTime> regular, DateTime? adhika}) findTithiDates(
    PanchangCity city,
    LunarMonth month,
    Tithi tithi,
    int year,
  ) {
    final at = _at(city);
    final adhika = at.findDate(month, tithi, year, isAdhika: true);
    return (
      regular: at.findDates(month, tithi, year),
      // findDate echoes the regular date in years without that adhika month.
      adhika: adhika != null && at.tithiOnDate(adhika).isAdhika ? adhika : null,
    );
  }

  /// Next occurrence of a tithi on or after [from] (defaults to today).
  DateTime? findNext(
    PanchangCity city,
    LunarMonth month,
    Tithi tithi, {
    DateTime? from,
  }) {
    final f = from ?? DateTime.now();
    // The engine indexes days from a UTC epoch, so a local midnight would be
    // read as the previous day.
    final start = DateTime.utc(f.year, f.month, f.day);
    final at = _at(city);
    // findNext can skip an occurrence in adhika years; findDates cannot.
    final candidates = [
      at.findNext(month, tithi, from: start),
      ...at.findDates(month, tithi, start.year),
      ...at.findDates(month, tithi, start.year + 1),
    ].whereType<DateTime>().where((d) => !d.isBefore(start)).toList()
      ..sort();
    return candidates.isEmpty ? null : candidates.first;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Engine festivals (minus regional variants) plus Maharashtrian and
  /// monthly observances. Months follow the Purnimant convention, as the
  /// engine's own festival table does.
  static final List<FestivalDef> observanceDefs = [
    ...festivals.where((f) =>
        f.enabledByDefault &&
        f.id != 'ganesh_chaturthi' &&
        (f.tradition.name == 'general' || f.id == 'janmashtami_smarta')),
    ..._extraDefs,
  ];

  static const _extraDefs = <FestivalDef>[
    // Ganesh sthapana follows the madhyahna rule; the engine's entry uses
    // sunrise and lands a day late when Chaturthi starts after sunrise.
    FestivalDef(id: 'ganesh_chaturthi', name: 'Ganesh Chaturthi', month: LunarMonth.bhadrapada, paksha: Paksha.shukla, tithiInPaksha: 4, muhurta: MuhurtaRule.madhyahna),
    FestivalDef(id: 'gudi_padwa', name: 'Gudi Padwa', month: LunarMonth.chaitra, paksha: Paksha.shukla, tithiInPaksha: 1, muhurta: MuhurtaRule.sunrise),
    FestivalDef(id: 'hanuman_jayanti', name: 'Hanuman Jayanti', month: LunarMonth.chaitra, paksha: Paksha.shukla, tithiInPaksha: 15, muhurta: MuhurtaRule.sunrise),
    FestivalDef(id: 'vat_purnima', name: 'Vat Purnima', month: LunarMonth.jyeshtha, paksha: Paksha.shukla, tithiInPaksha: 15, muhurta: MuhurtaRule.sunrise),
    FestivalDef(id: 'ashadhi_ekadashi', name: 'Ashadhi Ekadashi', month: LunarMonth.ashadha, paksha: Paksha.shukla, tithiInPaksha: 11, muhurta: MuhurtaRule.sunrise),
    FestivalDef(id: 'nag_panchami', name: 'Nag Panchami', month: LunarMonth.shravana, paksha: Paksha.shukla, tithiInPaksha: 5, muhurta: MuhurtaRule.sunrise),
    FestivalDef(id: 'hartalika', name: 'Hartalika', month: LunarMonth.bhadrapada, paksha: Paksha.shukla, tithiInPaksha: 3, muhurta: MuhurtaRule.sunrise),
    FestivalDef(id: 'rishi_panchami', name: 'Rishi Panchami', month: LunarMonth.bhadrapada, paksha: Paksha.shukla, tithiInPaksha: 5, muhurta: MuhurtaRule.madhyahna),
    FestivalDef(id: 'anant_chaturdashi', name: 'Anant Chaturdashi', month: LunarMonth.bhadrapada, paksha: Paksha.shukla, tithiInPaksha: 14, muhurta: MuhurtaRule.sunrise),
    FestivalDef(id: 'kojagiri_purnima', name: 'Kojagiri Purnima', month: LunarMonth.ashvina, paksha: Paksha.shukla, tithiInPaksha: 15, muhurta: MuhurtaRule.nishita),
    FestivalDef(id: 'dhanteras', name: 'Dhanteras', month: LunarMonth.kartika, paksha: Paksha.krishna, tithiInPaksha: 13, muhurta: MuhurtaRule.pradosh),
    FestivalDef(id: 'naraka_chaturdashi', name: 'Naraka Chaturdashi', month: LunarMonth.kartika, paksha: Paksha.krishna, tithiInPaksha: 14, muhurta: MuhurtaRule.sunrise),
    FestivalDef(id: 'bali_pratipada', name: 'Diwali Padwa', month: LunarMonth.kartika, paksha: Paksha.shukla, tithiInPaksha: 1, muhurta: MuhurtaRule.sunrise),
    FestivalDef(id: 'kartiki_ekadashi', name: 'Kartiki Ekadashi', month: LunarMonth.kartika, paksha: Paksha.shukla, tithiInPaksha: 11, muhurta: MuhurtaRule.sunrise),
    FestivalDef(id: 'tulsi_vivah', name: 'Tulsi Vivah', month: LunarMonth.kartika, paksha: Paksha.shukla, tithiInPaksha: 12, muhurta: MuhurtaRule.pradosh),
    FestivalDef(id: 'tripuri_purnima', name: 'Tripuri Purnima', month: LunarMonth.kartika, paksha: Paksha.shukla, tithiInPaksha: 15, muhurta: MuhurtaRule.pradosh),
    FestivalDef(id: 'datta_jayanti', name: 'Datta Jayanti', month: LunarMonth.margashirsha, paksha: Paksha.shukla, tithiInPaksha: 15, muhurta: MuhurtaRule.pradosh),
    FestivalDef(id: 'maghi_ganesh_jayanti', name: 'Maghi Ganesh Jayanti', month: LunarMonth.magha, paksha: Paksha.shukla, tithiInPaksha: 4, muhurta: MuhurtaRule.madhyahna),
    FestivalDef(id: 'vasant_panchami', name: 'Vasant Panchami', month: LunarMonth.magha, paksha: Paksha.shukla, tithiInPaksha: 5, muhurta: MuhurtaRule.madhyahna),
    FestivalDef(id: 'ratha_saptami', name: 'Ratha Saptami', month: LunarMonth.magha, paksha: Paksha.shukla, tithiInPaksha: 7, muhurta: MuhurtaRule.sunrise),
    FestivalDef(id: 'sankashti_chaturthi', name: 'Sankashti Chaturthi', month: LunarMonth.chaitra, paksha: Paksha.krishna, tithiInPaksha: 4, muhurta: MuhurtaRule.sunrise, recurring: true),
    FestivalDef(id: 'vinayaki_chaturthi', name: 'Vinayaki Chaturthi', month: LunarMonth.chaitra, paksha: Paksha.shukla, tithiInPaksha: 4, muhurta: MuhurtaRule.sunrise, recurring: true),
    FestivalDef(id: 'pradosh_shukla', name: 'Pradosh (Shukla)', month: LunarMonth.chaitra, paksha: Paksha.shukla, tithiInPaksha: 13, muhurta: MuhurtaRule.sunrise, recurring: true),
    FestivalDef(id: 'pradosh_krishna', name: 'Pradosh (Krishna)', month: LunarMonth.chaitra, paksha: Paksha.krishna, tithiInPaksha: 13, muhurta: MuhurtaRule.sunrise, recurring: true),
    FestivalDef(id: 'masik_shivaratri', name: 'Masik Shivaratri', month: LunarMonth.chaitra, paksha: Paksha.krishna, tithiInPaksha: 14, muhurta: MuhurtaRule.sunrise, recurring: true),
  ];
}

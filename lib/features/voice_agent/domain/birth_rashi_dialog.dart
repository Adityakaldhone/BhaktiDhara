import 'package:timezone/timezone.dart' as tz;

import '../../../domain/entities/horoscope.dart';
import '../../../services/kundali/kundali_service.dart';
import '../../../services/kundali/vedic_astro_engine.dart';
import '../data/voice_agent_service.dart';

/// In-memory birth lookup, using the same parsing vocabulary as the API.
class BirthRashiDialog {
  BirthRashiDialog(this.spec);
  final Map<String, dynamic> spec;
  static const action = 'find_birth_rashi';

  bool matches(String key, String query) =>
      RegExp(spec[key] as String, caseSensitive: false).hasMatch(query);
  bool requested(String query, String? pending) {
    final topic = matches('sign_terms', query);
    final implicit = RegExp(
      (spec['implicit_uncertainty'] as String).replaceFirst(
        '{uncertain}',
        spec['uncertain'] as String,
      ),
      caseSensitive: false,
    );
    return !matches('switch', query) &&
        ((pending == 'ask_rashi' && implicit.hasMatch(query)) ||
            (topic && matches('uncertain', query)) ||
            (topic &&
                matches('discover', query) &&
                !matches('reading', query)) ||
            (pending == 'ask_rashi' && _date(_normalize(query)) != null));
  }

  late final Map<String, int> _months = {
    for (final (index, names) in (spec['months'] as List).indexed)
      for (final name in names as List) name as String: index + 1,
  };
  late final String _monthPattern = _months.keys.map(RegExp.escape).join('|');
  static const _day = r'([0-9]{1,2})(?:st|nd|rd|th)?';
  late final _dates = [
    RegExp(spec['date_iso'] as String),
    RegExp(spec['date_numeric'] as String),
    RegExp('(?:^|[^0-9])$_day\\s+($_monthPattern)[ ,]+([0-9]{4})(?![0-9])'),
    RegExp('($_monthPattern)\\s+$_day[ ,]+([0-9]{4})(?![0-9])'),
  ];

  (RegExpMatch, DateTime?)? _date(String query) {
    for (final (format, pattern) in _dates.indexed) {
      final m = pattern.firstMatch(query);
      if (m == null) continue;
      final a = m[1]!, b = m[2]!, c = m[3]!;
      final (year, month, day) = switch (format) {
        0 => (int.parse(a), int.parse(b), int.parse(c)),
        1 when int.parse(b) > 12 => (int.parse(c), int.parse(a), int.parse(b)),
        1 => (int.parse(c), int.parse(b), int.parse(a)),
        2 => (int.parse(c), _months[b]!, int.parse(a)),
        _ => (int.parse(c), _months[a]!, int.parse(b)),
      };
      final date = DateTime.utc(year, month, day);
      final ambiguous =
          format == 1 &&
          int.parse(a) <= 12 &&
          int.parse(b) <= 12 &&
          day != month;
      final valid =
          !ambiguous &&
          year >= 1850 &&
          date.day == day &&
          date.month == month &&
          !date.isAfter(DateTime.now());
      return (m, valid ? date : null);
    }
    return null;
  }

  (bool, String?) _time(String query) {
    for (final key in ['clock_phrases', 'clock_words']) {
      for (final entry in (spec[key] as Map).entries) {
        query = query.replaceAll(
          RegExp(r'\b' + RegExp.escape(entry.key) + r'\b'),
          entry.value,
        );
      }
    }
    for (final entry in (spec['clock_minutes'] as Map).entries) {
      final pattern = RegExp(
        r'\b(\d{1,2})\s+' + RegExp.escape(entry.key) + r'\b',
      );
      query = query.replaceAllMapped(pattern, (m) => '${m[1]}:${entry.value}');
    }
    for (final m in RegExp(spec['time'] as String).allMatches(query)) {
      final prefix = m[1], h = m[2]!, minutes = m[3], suffix = m[4];
      if (prefix == null && minutes == null && suffix == null) continue;
      var hour = int.parse(h);
      final minute = int.parse(minutes ?? '0');
      final marker = suffix?.replaceAll('.', '');
      if (prefix != null || marker == 'am' || marker == 'pm') {
        if (hour < 1 || hour > 12) return (true, null);
        final pm =
            marker == 'pm' ||
            const {
              'दुपारी',
              'दोपहर',
              'रात्री',
              'रात',
              'संध्याकाळी',
              'शाम',
            }.contains(prefix);
        hour = hour % 12 + (pm ? 12 : 0);
      } else if (minutes == null || (h.length == 1 && hour != 0)) {
        return (true, null);
      }
      if (hour > 23 || minute > 59) return (true, null);
      return (
        true,
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      );
    }
    return (false, null);
  }

  String? _zone(String text) {
    final id = RegExp(r'[A-Za-z_]+(?:/[A-Za-z_+0-9-]+)+').firstMatch(text)?[0];
    if (id != null) {
      KundaliService.ensureTimezones();
      if (tz.timeZoneDatabase.locations.containsKey(id)) return id;
    }
    String? found;
    for (final entry in (spec['zones'] as Map).entries) {
      final place = RegExp(
        r'(?:^|[\s,(])(?:' + entry.value + r')(?=$|[\s.,)!?।])',
        caseSensitive: false,
      );
      if (place.hasMatch(text)) {
        if (found != null) return null;
        found = entry.key as String;
      }
    }
    return found;
  }

  String _normalize(String text) => text.toLowerCase().replaceAllMapped(
    RegExp(r'[०-९]'),
    (m) => (m[0]!.codeUnitAt(0) - 0x966).toString(),
  );

  bool containsFacts(String text) =>
      matches("personal_details", text) ||
      _time(text.toLowerCase()).$1 ||
      RegExp(r'[0-9०-९]').hasMatch(text) ||
      _zone(text) != null ||
      matches('uncertain', text);

  VoiceAgentResult turn(
    String text,
    String locale, [
    Map<String, String>? prior,
  ]) {
    final state = {...?prior};
    final lang = locale.split('-').first;
    VoiceAgentResult reply(
      String key, {
      Rashi? sign,
      Rashi? first,
      Rashi? last,
      bool ask = true,
    }) {
      final template = spec['replies'][key][lang] as String;
      return VoiceAgentResult(
        status: ask
            ? 'needs_clarification'
            : sign == null
            ? 'answered'
            : 'action_ready',
        transcript: text,
        locale: locale,
        choices: const [],
        responseText: template
            .replaceAll('{sign}', sign?.localizedName(lang) ?? '')
            .replaceAll('{first}', first?.localizedName(lang) ?? '')
            .replaceAll('{last}', last?.localizedName(lang) ?? ''),
        action: sign == null
            ? VoiceAction(type: ask ? action : 'none')
            : VoiceAction(
                type: 'open_horoscope',
                featureKey: 'birth_rashi',
                rashiId: sign.id,
                rashiName: sign.localizedName(lang),
              ),
        birthDetails: ask ? {...state, 'step': key} : null,
      );
    }

    var query = _normalize(text);
    if (matches('cancel', query)) return reply('cancel', ask: false);
    if (prior != null &&
        matches('uncertain', query) &&
        (matches('missing_date', query) ||
            (state['step'] == 'date' && !matches('unknown_time', query)))) {
      return reply('missing_date', ask: false);
    }
    if (matches('unknown_time', query)) state.remove('time');
    final zone = _zone(text);
    if (zone != null) state['zone'] = zone;
    final dateInput = _date(query);
    if (dateInput != null) {
      final (match, date) = dateInput;
      query = query.replaceRange(match.start, match.end, ' ');
      if (date == null) {
        state.remove('date');
        return reply('date');
      }
      state['date'] = date.toIso8601String().split('T').first;
    }
    final (suppliedTime, clock) = _time(query);
    if (suppliedTime && clock == null) {
      state.remove('time');
      return reply('invalid_time');
    }
    if (clock != null) state['time'] = clock;
    final date = DateTime.tryParse(state['date'] ?? '');
    if (date == null) {
      return reply(prior == null && state.isEmpty ? 'start' : 'date');
    }
    if (state['zone'] == null) return reply('zone');
    KundaliService.ensureTimezones();
    final location = tz.getLocation(state['zone']!);
    final start = tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
    ).toUtc();
    final end = tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day + 1,
    ).toUtc().subtract(const Duration(microseconds: 1));
    Rashi signAt(DateTime utc) {
      final longitude =
          VedicAstroEngine.tropicalLongitude(Graha.moon, utc) -
          VedicAstroEngine.lahiriAyanamsa(utc);
      return kAllRashis[(longitude % 360) ~/ 30];
    }

    var first = signAt(start), last = signAt(end);
    if (state['time'] case final String clockTime) {
      final parts = clockTime.split(':').map(int.parse).toList();
      final wall = DateTime.utc(
        date.year,
        date.month,
        date.day,
        parts[0],
        parts[1],
      );
      // A local wall time can occur twice, or be skipped, on a clock-change day.
      final offsets = {
        for (final utc in [start, end])
          tz.TZDateTime.from(utc, location).timeZoneOffset,
      };
      final instants = [
        for (final offset in offsets)
          if (tz.TZDateTime.from(
                wall.subtract(offset),
                location,
              ).timeZoneOffset ==
              offset)
            wall.subtract(offset),
      ];
      if (instants.isEmpty) {
        state.remove('time');
        return reply('invalid_time');
      }
      first = signAt(instants.first);
      last = signAt(instants.last);
      if (first != last) {
        return reply('uncertain', first: first, last: last, ask: false);
      }
    }
    if (first == last) return reply('result', sign: first, ask: false);
    final unknown =
        matches('unknown_time', query) ||
        const {'time', 'invalid_time'}.contains(state['step']) &&
            matches('uncertain', query);
    return reply(
      unknown ? 'uncertain' : 'time',
      first: first,
      last: last,
      ask: !unknown,
    );
  }
}

part of 'gemini_horoscope_service.dart';

/// Position providers return geocentric Lahiri ecliptic longitudes in degrees.
/// Daylight times use UTC and the city supplied by the user.
abstract class HoroscopeEphemeris {
  const HoroscopeEphemeris();

  String get name;

  ({double sun, double moon}) siderealLongitudes(DateTime timeUtc);

  ({DateTime sunrise, DateTime sunset})? daylight(
    DateTime dayStartUtc,
    HoroscopeCity city,
  ) => _approximateDaylight(dayStartUtc, city);
}

class HoroscopeCity {
  HoroscopeCity({
    required this.name,
    required this.latitude,
    required this.longitude,
  }) {
    if (name.trim().isEmpty) throw ArgumentError.value(name, 'name');
    if (!latitude.isFinite || latitude.abs() > 90) {
      throw ArgumentError.value(latitude, 'latitude');
    }
    if (!longitude.isFinite || longitude.abs() > 180) {
      throw ArgumentError.value(longitude, 'longitude');
    }
  }

  final String name;
  final double latitude;
  final double longitude;
}

typedef HoroscopeLine = ({String label, String text, double? score});
typedef _TransitWindow = ({DateTime start, DateTime end});
typedef _LunarTransit = ({int firstSign, int lastSign, DateTime? ingressUtc});

enum HoroscopeSectionKind {
  general,
  lifeAspects,
  actions,
  luckyElements,
  spiritual,
}

class HoroscopeSection {
  HoroscopeSection(this.kind, this.title, List<HoroscopeLine> lines)
    : lines = List.unmodifiable(lines);

  final HoroscopeSectionKind kind;
  final String title;
  final List<HoroscopeLine> lines;
}

class HoroscopePage {
  HoroscopePage._({
    required this.reading,
    required this.symbol,
    required this.signTitle,
    required this.dateAndDay,
    required this.sunSignDates,
    required this.element,
    required this.rulingPlanet,
    required this.headline,
    required this.mood,
    required this.moodScore,
    required this.ephemerisSource,
    required this.transitNote,
    required this.moonIngressUtc,
    required this.muhuratUtc,
    required this.fullSections,
    required this.summarySections,
  });

  final HoroscopeReading reading;
  final String symbol;
  final String signTitle;
  final String dateAndDay;
  final String sunSignDates;
  final String element;
  final String rulingPlanet;
  final String headline;
  final String mood;
  final double moodScore;
  final String ephemerisSource;
  final String transitNote;
  final DateTime? moonIngressUtc;
  final ({DateTime start, DateTime end})? muhuratUtc;
  final List<HoroscopeSection> fullSections;
  final List<HoroscopeSection> summarySections;
}

class _HoroscopeContent {
  const _HoroscopeContent({
    required this.reading,
    required this.rashi,
    required this.rashiIndex,
    required this.language,
    required this.start,
    required this.days,
    required this.lead,
    required this.overview,
  });

  final HoroscopeReading reading;
  final Rashi rashi;
  final int rashiIndex;
  final String language;
  final DateTime start;
  final List<List<_MoonSample>> days;
  final _HouseReading lead;
  final String overview;
}

HoroscopePage _buildPage({
  required _HoroscopeContent content,
  required _LunarTransit transit,
  required int? lastDaySign,
  required HoroscopeCity? city,
  required _TransitWindow? muhurat,
  required String source,
}) {
  final index = content.rashiIndex;
  final reading = content.reading;
  final language = content.language;
  String text(_LocalizedText value) => value.inLanguage(language);
  HoroscopeLine line(_LocalizedText label, String value, {double? score}) =>
      (label: text(label), text: value, score: score);
  final body = content.overview;
  final houseIndex = (content.days.first[1].sign - index) % 12;
  final transitNote = _transitNote(transit, index, lastDaySign, language);
  final headline = _headline(houseIndex, index, transit, lastDaySign, language);
  final moodScore = switch (reading.auspiciousPercentage) {
    >= 77 => 4.0,
    >= 70 => 3.5,
    _ => 3.0,
  };
  final mood = text(switch (moodScore) {
    4.0 => const _LocalizedText(
      'Favorable & active',
      'अनुकूल और सक्रिय',
      'अनुकूल आणि सक्रिय',
    ),
    3.5 => const _LocalizedText(
      'Steady & balanced',
      'स्थिर और संतुलित',
      'स्थिर आणि संतुलित',
    ),
    _ => const _LocalizedText(
      'Quiet & reflective',
      'शांत और विचारशील',
      'शांत आणि चिंतनशील',
    ),
  });

  double aspectScore(Set<int> focusHouses) {
    final samples = content.days.expand((day) => day);
    final points = samples.fold<double>(0, (sum, moon) {
      final house = (moon.sign - index) % 12 + 1;
      final base = _traditionalIndex(moon, index) >= 77 ? 3.5 : 3.0;
      return sum + base + (focusHouses.contains(house) ? 0.5 : 0);
    });
    return (2 * points / (content.days.length * 3)).round() / 2;
  }

  final aspectRows = [
    line(
      const _LocalizedText(
        'Career & business',
        'करियर और व्यवसाय',
        'करिअर आणि व्यवसाय',
      ),
      reading.career,
      score: aspectScore({3, 6, 10, 11}),
    ),
    line(
      const _LocalizedText(
        'Finance & wealth',
        'धन और वित्त',
        'धन आणि आर्थिक व्यवहार',
      ),
      text(_financeNotes[houseIndex]),
      score: aspectScore({2, 8, 10, 11}),
    ),
    line(
      const _LocalizedText(
        'Love & relationships',
        'प्रेम और रिश्ते',
        'प्रेम आणि नाती',
      ),
      reading.love,
      score: aspectScore({4, 5, 7, 11}),
    ),
    line(
      const _LocalizedText(
        'Health & well-being',
        'स्वास्थ्य और दिनचर्या',
        'आरोग्य आणि दिनक्रम',
      ),
      reading.health,
      score: aspectScore({1, 4, 6, 12}),
    ),
  ];
  final action = HoroscopeSection(
    HoroscopeSectionKind.actions,
    text(
      const _LocalizedText(
        'Do’s and don’ts',
        'क्या करें और क्या न करें',
        'कृतीसाठी मार्गदर्शन',
      ),
    ),
    [
      line(_doLabel, text(content.lead.action)),
      line(_avoidLabel, text(content.lead.avoid)),
    ],
  );
  final ruler = _rulerForSign(index);
  final lucky = [
    line(
      const _LocalizedText('Lucky color', 'शुभ रंग', 'शुभ रंग'),
      text(ruler.color),
    ),
    line(
      const _LocalizedText('Lucky number', 'शुभ अंक', 'शुभ अंक'),
      '${ruler.number}',
    ),
    if (muhurat != null)
      line(
        const _LocalizedText(
          'Abhijit Muhurat',
          'अभिजित मुहूर्त',
          'अभिजित मुहूर्त',
        ),
        '${_timeIst(muhurat.start, language)} – ${_timeIst(muhurat.end, language)} IST · ${city!.name}',
      ),
    line(
      const _LocalizedText('Lucky direction', 'शुभ दिशा', 'शुभ दिशा'),
      text(ruler.direction),
    ),
  ];
  final generalTitle = text(
    const _LocalizedText('General prediction', 'राशिफल', 'राशीभविष्य'),
  );
  final aspectTitle = text(
    const _LocalizedText('Life aspects', 'जीवन के पहलू', 'जीवनाचे पैलू'),
  );
  final luckyTitle = text(
    const _LocalizedText('Lucky elements', 'शुभ संकेत', 'शुभ संकेत'),
  );
  final sentenceEnd = language == 'hi' ? '।' : '.';
  final shortSummary = body.split(sentenceEnd).first.trim() + sentenceEnd;
  final laterTopic = text(
    _houseReadings[(transit.lastSign - index) % 12].topic,
  );
  final laterFocus = switch (language) {
    'hi' => ' दिन आगे बढ़ने पर $laterTopic पर ध्यान जा सकता है।',
    'mr' => ' दिवस पुढे सरकत असताना $laterTopic याकडे लक्ष जाऊ शकते.',
    _ => ' Later, your focus may turn to $laterTopic.',
  };
  final intro =
      shortSummary +
      (lastDaySign == null &&
              transit.ingressUtc != null &&
              content.days.first[1].sign != transit.lastSign
          ? laterFocus
          : '');
  final everydayToday = _weekdays[content.start.weekday - DateTime.monday];
  final rashi = content.rashi;
  final localizedRashi = text(
    _LocalizedText(rashi.nameEn, rashi.nameHi, rashi.nameMr),
  );
  final englishSign = _signs[index].western;
  final vedicSign = _signs[index].vedic;
  final signTitle = language == 'en'
      ? '$englishSign / $vedicSign (${_signs[index].local})'
      : '$localizedRashi ($englishSign)';
  final signDate = _sunDates[index];
  final dateAndDay = content.days.length == 7
      ? reading.dateText
      : language == 'en'
      ? '${text(everydayToday)}, ${_englishMonths[content.start.month - 1]} '
            '${content.start.day}, ${content.start.year}'
      : '${text(everydayToday)}, ${reading.dateText}';

  return HoroscopePage._(
    reading: reading,
    symbol: _signs[index].symbol,
    signTitle: signTitle,
    dateAndDay: dateAndDay,
    sunSignDates:
        '${text(const _LocalizedText('Western Sun-sign dates', 'पाश्चात्य सूर्य राशि की तिथियाँ', 'पाश्चात्य सूर्य राशीच्या तारखा'))} · '
        '${_shortDate(signDate.$1, signDate.$2, language)} – ${_shortDate(signDate.$3, signDate.$4, language)}',
    element: text(_elements[index % 4]),
    rulingPlanet: text(ruler.name),
    headline: headline,
    mood: mood,
    moodScore: moodScore,
    ephemerisSource: source,
    transitNote: transitNote,
    moonIngressUtc: lastDaySign == null ? transit.ingressUtc : null,
    muhuratUtc: muhurat,
    fullSections: List.unmodifiable([
      HoroscopeSection(HoroscopeSectionKind.general, generalTitle, [
        line(const _LocalizedText('', '', ''), body),
        line(
          const _LocalizedText('Moon transit', 'चंद्र गोचर', 'चंद्र गोचर'),
          transitNote,
        ),
      ]),
      HoroscopeSection(
        HoroscopeSectionKind.lifeAspects,
        aspectTitle,
        aspectRows,
      ),
      action,
      HoroscopeSection(HoroscopeSectionKind.luckyElements, luckyTitle, lucky),
      HoroscopeSection(
        HoroscopeSectionKind.spiritual,
        text(
          const _LocalizedText('Vedic remedies', 'वैदिक उपाय', 'वैदिक उपाय'),
        ),
        [
          line(
            const _LocalizedText('Mantra', 'मंत्र', 'मंत्र'),
            '${text(ruler.mantra)} · ${text(const _LocalizedText('11 recitations', '११ बार जप', '११ वेळा जप'))}',
          ),
          line(
            const _LocalizedText('Simple remedy', 'सरल उपाय', 'सोपे उपाय'),
            text(ruler.remedy),
          ),
        ],
      ),
    ]),
    summarySections: List.unmodifiable([
      HoroscopeSection(HoroscopeSectionKind.general, generalTitle, [
        line(const _LocalizedText('', '', ''), intro),
      ]),
      HoroscopeSection(HoroscopeSectionKind.lifeAspects, aspectTitle, [
        for (final row in aspectRows)
          (label: row.label, text: '', score: row.score),
      ]),
      action,
      HoroscopeSection(
        HoroscopeSectionKind.luckyElements,
        luckyTitle,
        lucky.take(lucky.length - 1).toList(),
      ),
    ]),
  );
}

_LunarTransit _lunarTransit(DateTime startUtc, HoroscopeEphemeris ephemeris) {
  int signAt(DateTime instant) =>
      (_degrees(ephemeris.siderealLongitudes(instant).moon) / 30).floor();

  var low = startUtc;
  var high = startUtc
      .add(const Duration(days: 1))
      .subtract(const Duration(microseconds: 1));
  final first = signAt(low);
  final last = signAt(high);
  if (first == last) {
    return (firstSign: first, lastSign: last, ingressUtc: null);
  }

  // The Moon moves less than one whole sign in a civil day. Bisect that crossing.
  while (high.difference(low) > const Duration(seconds: 1)) {
    final mid = low.add(high.difference(low) ~/ 2);
    if (signAt(mid) == first) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return (firstSign: first, lastSign: last, ingressUtc: high);
}

String _transitNote(
  _LunarTransit transit,
  int index,
  int? lastDaySign,
  String language,
) {
  String sign(int i) {
    final item = _signs[i];
    final name = language == 'en' ? item.western : item.local;
    final house = (i - index) % 12 + 1;
    return switch (language) {
      'hi' => '$name (भाव $house)',
      'mr' => '$name (भाव $house)',
      _ => '$name (house $house)',
    };
  }

  final first = sign(transit.firstSign);
  if (lastDaySign != null) {
    final end = sign(lastDaySign);
    return switch (language) {
      'hi' =>
        'सोमवार की शुरुआत में चंद्रमा $first में और रविवार दोपहर में $end में रहेगा।',
      'mr' =>
        'सोमवारच्या सुरुवातीला चंद्र $first येथे आणि रविवारी दुपारी $end येथे असेल.',
      _ =>
        'The Moon starts Monday in $first and reaches $end by the Sunday afternoon sample.',
    };
  }
  final ingress = transit.ingressUtc;
  if (ingress == null) {
    return switch (language) {
      'hi' => 'चंद्रमा पूरे दिन $first में रहेगा।',
      'mr' => 'चंद्र दिवसभर $first येथे राहील.',
      _ => 'The Moon stays in $first throughout the day.',
    };
  }
  final last = sign(transit.lastSign);
  final time = _timeIst(ingress, language);
  return switch (language) {
    'hi' =>
      'दिन की शुरुआत में चंद्रमा $first में रहेगा और लगभग $time IST पर $last में प्रवेश करेगा।',
    'mr' =>
      'दिवसाच्या सुरुवातीला चंद्र $first येथे असेल आणि सुमारे $time IST ला $last येथे प्रवेश करेल.',
    _ => 'The Moon starts in $first and enters $last around $time IST.',
  };
}

String _headline(
  int houseIndex,
  int rashiIndex,
  _LunarTransit transit,
  int? lastDaySign,
  String language,
) {
  final firstHouse = (transit.firstSign - rashiIndex) % 12;
  final laterHouse = (transit.lastSign - rashiIndex) % 12;
  if (lastDaySign == null && firstHouse == 9 && laterHouse == 10) {
    return const _LocalizedText(
      'Career momentum builds as your network comes into focus',
      'काम में बढ़त के साथ सहयोग के रास्ते खुल सकते हैं',
      'कामाला गती मिळेल, ओळखींच्या वर्तुळातून सहकार्याची शक्यता',
    ).inLanguage(language);
  }
  return _headlines[houseIndex].inLanguage(language);
}

_TransitWindow? _abhijitWindow(
  HoroscopeEphemeris ephemeris,
  DateTime dayStartUtc,
  HoroscopeCity city,
) {
  final daylight = ephemeris.daylight(dayStartUtc, city);
  if (daylight == null) return null;
  final duration = daylight.sunset.difference(daylight.sunrise);
  if (duration <= Duration.zero) return null;
  final fifteenth = duration ~/ 15;
  return (
    start: daylight.sunrise.add(fifteenth * 7),
    end: daylight.sunrise.add(fifteenth * 8),
  );
}

// Find horizon crossings at standard apparent sunrise/sunset, using the
// geometric solar center at -0.833 degrees and a sea-level horizon.
({DateTime sunrise, DateTime sunset})? _approximateDaylight(
  DateTime dayStartUtc,
  HoroscopeCity city,
) {
  const horizon = -0.833;
  final latitude = city.latitude * _rad;

  double relativeAltitude(DateTime utc) {
    final days =
        utc.difference(_j2000Utc).inMicroseconds / Duration.microsecondsPerDay;
    final t = days / 36525;
    final solar = _sunLongitude(t) * _rad;
    final obliquity = (23.439291 - 0.0130042 * t) * _rad;
    final ra = math.atan2(
      math.cos(obliquity) * math.sin(solar),
      math.cos(solar),
    );
    final declination = math.asin(math.sin(obliquity) * math.sin(solar));
    final gst = _degrees(
      280.46061837 +
          360.98564736629 * days +
          t * t * (0.000387933 - t / 38710000),
    );
    final hourAngle = (gst + city.longitude) * _rad - ra;
    final altitude = math.asin(
      math.sin(latitude) * math.sin(declination) +
          math.cos(latitude) * math.cos(declination) * math.cos(hourAngle),
    );
    return altitude / _rad - horizon;
  }

  DateTime crossing(DateTime low, DateTime high, bool rising) {
    while (high.difference(low) > const Duration(seconds: 1)) {
      final mid = low.add(high.difference(low) ~/ 2);
      if ((relativeAltitude(mid) >= 0) == rising) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return high;
  }

  var previous = dayStartUtc;
  var previousAltitude = relativeAltitude(previous);
  DateTime? sunrise;
  for (var hour = 1; hour <= 24; hour++) {
    final current = dayStartUtc.add(Duration(hours: hour));
    final altitude = relativeAltitude(current);
    if (sunrise == null && previousAltitude < 0 && altitude >= 0) {
      sunrise = crossing(previous, current, true);
    }
    if (sunrise != null && previousAltitude > 0 && altitude <= 0) {
      return (sunrise: sunrise, sunset: crossing(previous, current, false));
    }
    previous = current;
    previousAltitude = altitude;
  }
  return null;
}

String _timeIst(DateTime utc, String language) {
  final time = utc.toUtc().add(_istOffset).add(const Duration(seconds: 30));
  final minutes = time.minute.toString().padLeft(2, '0');
  if (language != 'en') {
    return '${time.hour.toString().padLeft(2, '0')}:$minutes';
  }
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '$hour:$minutes ${time.hour < 12 ? 'AM' : 'PM'}';
}

String _shortDate(int month, int day, String language) {
  final name = _months[month - 1].inLanguage(language);
  return language == 'en' ? '${_englishMonths[month - 1]} $day' : '$day $name';
}

const _signs = [
  (western: 'Aries', vedic: 'Mesha', local: 'मेष', symbol: '♈'),
  (western: 'Taurus', vedic: 'Vrishabha', local: 'वृषभ', symbol: '♉'),
  (western: 'Gemini', vedic: 'Mithuna', local: 'मिथुन', symbol: '♊'),
  (western: 'Cancer', vedic: 'Karka', local: 'कर्क', symbol: '♋'),
  (western: 'Leo', vedic: 'Simha', local: 'सिंह', symbol: '♌'),
  (western: 'Virgo', vedic: 'Kanya', local: 'कन्या', symbol: '♍'),
  (western: 'Libra', vedic: 'Tula', local: 'तुला', symbol: '♎'),
  (western: 'Scorpio', vedic: 'Vrishchika', local: 'वृश्चिक', symbol: '♏'),
  (western: 'Sagittarius', vedic: 'Dhanu', local: 'धनु', symbol: '♐'),
  (western: 'Capricorn', vedic: 'Makara', local: 'मकर', symbol: '♑'),
  (western: 'Aquarius', vedic: 'Kumbha', local: 'कुंभ', symbol: '♒'),
  (western: 'Pisces', vedic: 'Meena', local: 'मीन', symbol: '♓'),
];

// Conventional Western Sun-sign date ranges are display metadata. The
// Moon-sign reading instead uses the selected Janma Rashi.
const _sunDates = [
  (3, 21, 4, 19),
  (4, 20, 5, 20),
  (5, 21, 6, 20),
  (6, 21, 7, 22),
  (7, 23, 8, 22),
  (8, 23, 9, 22),
  (9, 23, 10, 22),
  (10, 23, 11, 21),
  (11, 22, 12, 21),
  (12, 22, 1, 19),
  (1, 20, 2, 18),
  (2, 19, 3, 20),
];

const _englishMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _weekdays = [
  _LocalizedText('Monday', 'सोमवार', 'सोमवार'),
  _LocalizedText('Tuesday', 'मंगलवार', 'मंगळवार'),
  _LocalizedText('Wednesday', 'बुधवार', 'बुधवार'),
  _LocalizedText('Thursday', 'गुरुवार', 'गुरुवार'),
  _LocalizedText('Friday', 'शुक्रवार', 'शुक्रवार'),
  _LocalizedText('Saturday', 'शनिवार', 'शनिवार'),
  _LocalizedText('Sunday', 'रविवार', 'रविवार'),
];

const _elements = [
  _LocalizedText('Fire', 'अग्नि', 'अग्नी'),
  _LocalizedText('Earth', 'पृथ्वी', 'पृथ्वी'),
  _LocalizedText('Air', 'वायु', 'वायू'),
  _LocalizedText('Water', 'जल', 'जल'),
];

const _headlines = [
  _LocalizedText(
    'One clear priority can set the pace',
    'एक स्पष्ट प्राथमिकता दिन को दिशा दे सकती है',
    'एक स्पष्ट प्राधान्य दिवसाला दिशा देऊ शकते',
  ),
  _LocalizedText(
    'A practical step brings household plans into focus',
    'घर की योजनाओं को स्पष्ट करने का समय',
    'घरचे नियोजन स्पष्ट करण्याची संधी',
  ),
  _LocalizedText(
    'A short conversation can move things forward',
    'एक छोटी बातचीत से काम आगे बढ़ सकता है',
    'थोडक्यात बोलल्याने काम पुढे जाऊ शकते',
  ),
  _LocalizedText(
    'Making time for home can lighten the rest of the day',
    'घर के लिए थोड़ा समय बाकी दिन को सहज बना सकता है',
    'घरासाठी थोडा वेळ दिल्याने दिवस हलका वाटू शकतो',
  ),
  _LocalizedText(
    'A fresh idea is worth trying',
    'नए विचार को आज़माने का मौका',
    'नवी कल्पना आजमावण्याची संधी',
  ),
  _LocalizedText(
    'Small completions make room for important work',
    'छोटे काम पूरे करने से ज़रूरी काम के लिए समय निकलेगा',
    'छोटी कामे उरकल्याने महत्त्वाच्या कामाला वेळ मिळेल',
  ),
  _LocalizedText(
    'A shared decision can move forward',
    'साझा फैसले में प्रगति की गुंजाइश',
    'सामायिक निर्णय पुढे जाण्याची शक्यता',
  ),
  _LocalizedText(
    'A closer look may clarify a pending matter',
    'लंबित बात को समझने का मौका',
    'राहिलेल्या गोष्टीचा उलगडा होण्याची संधी',
  ),
  _LocalizedText(
    'A new perspective opens up an option',
    'नया नज़रिया एक और रास्ता दिखा सकता है',
    'नव्या दृष्टीने आणखी एक मार्ग दिसू शकतो',
  ),
  _LocalizedText(
    'Work with a clear finish line gains momentum',
    'स्पष्ट लक्ष्य वाले काम में बढ़त संभव है',
    'स्पष्ट उद्दिष्ट असलेल्या कामाला गती मिळू शकते',
  ),
  _LocalizedText(
    'Friends and colleagues can help move a plan along',
    'दोस्तों और सहकर्मियों का सहयोग काम आ सकता है',
    'मित्रांचे आणि सहकाऱ्यांचे सहकार्य उपयोगी पडू शकते',
  ),
  _LocalizedText(
    'A quieter pace makes room to reset',
    'धीमी रफ़्तार में खुद के लिए समय मिल सकता है',
    'संथ गतीत स्वतःसाठी वेळ मिळू शकतो',
  ),
];

const _financeNotes = [
  _LocalizedText(
    'Pick one spending priority before making new commitments.',
    'नए खर्च तय करने से पहले एक प्राथमिकता चुनें।',
    'नवे खर्च ठरवण्याआधी एक प्राधान्य निवडा.',
  ),
  _LocalizedText(
    'Review recurring bills and check whether any household costs have changed.',
    'नियमित बिल देखें और घर के खर्च में आए बदलाव नोट करें।',
    'नियमित बिले पाहा आणि घरखर्चातील बदल नोंदवा.',
  ),
  _LocalizedText(
    'Follow up on an outstanding payment or clarify the terms of a quote.',
    'लंबित भुगतान की जानकारी लें या किसी अनुमानित खर्च की शर्तें साफ़ करें।',
    'प्रलंबित देयकाचा पाठपुरावा करा किंवा खर्चाच्या अंदाजातील अटी स्पष्ट करा.',
  ),
  _LocalizedText(
    'Set aside room in your budget for an upcoming household expense.',
    'आने वाले किसी घरेलू खर्च के लिए बजट में जगह रखें।',
    'आगामी घरगुती खर्चासाठी अंदाजपत्रकात जागा ठेवा.',
  ),
  _LocalizedText(
    'Decide how much to put aside for a hobby or an outing before browsing options.',
    'शौक या घूमने के विकल्प देखने से पहले उसकी खर्च सीमा तय करें।',
    'छंद किंवा सहलीचे पर्याय पाहण्याआधी खर्चाची मर्यादा ठरवा.',
  ),
  _LocalizedText(
    'Check whether subscriptions and small recurring costs still serve a purpose.',
    'देखें कि सदस्यता और छोटे नियमित खर्च अब भी काम के हैं या नहीं।',
    'सदस्यत्वे आणि छोटे नियमित खर्च अजून उपयोगाचे आहेत का ते पाहा.',
  ),
  _LocalizedText(
    'Discuss how to split a shared expense before anyone pays.',
    'साझा खर्च करने से पहले तय करें कि कौन कितना देगा।',
    'सामायिक खर्च करण्यापूर्वी प्रत्येकाचा वाटा ठरवा.',
  ),
  _LocalizedText(
    'Set aside a moment to sort out a reimbursement or shared bill.',
    'किसी वापसी भुगतान या साझा बिल को सुलझाने के लिए समय रखें।',
    'खर्चाची परतफेड किंवा सामायिक बिल निकाली काढण्यासाठी वेळ ठेवा.',
  ),
  _LocalizedText(
    'Compare the full cost of a course or trip before booking.',
    'बुकिंग से पहले पाठ्यक्रम या यात्रा का पूरा खर्च देखें।',
    'नोंदणीपूर्वी अभ्यासक्रम किंवा प्रवासाचा एकूण खर्च पाहा.',
  ),
  _LocalizedText(
    'Confirm invoice amounts and payment dates for work you have finished.',
    'पूरे किए हुए काम की रकम और भुगतान की तारीख तय करें।',
    'पूर्ण केलेल्या कामाची रक्कम आणि देय तारीख तपासा.',
  ),
  _LocalizedText(
    'Agree on your share of a group plan so social spending stays comfortable.',
    'सामूहिक योजना में अपना हिस्सा तय करें ताकि खर्च सहज रहे।',
    'गटाच्या योजनेत आपला वाटा ठरवा, म्हणजे खर्च आवाक्यात राहील.',
  ),
  _LocalizedText(
    'Review a small expense you can pause and clear one overdue item.',
    'देखें कि कौन-सा छोटा खर्च रोक सकते हैं और एक लंबित भुगतान निपटाएँ।',
    'कोणता छोटा खर्च थांबवता येईल ते पाहा आणि एक प्रलंबित देयक भरा.',
  ),
];

class _Ruler {
  const _Ruler(
    this.name,
    this.color,
    this.number,
    this.direction,
    this.mantra,
    this.remedy,
  );

  final _LocalizedText name;
  final _LocalizedText color;
  final int number;
  final _LocalizedText direction;
  final _LocalizedText mantra;
  final _LocalizedText remedy;
}

const _east = _LocalizedText('East', 'पूर्व', 'पूर्व');
const _north = _LocalizedText('North', 'उत्तर', 'उत्तर');
const _west = _LocalizedText('West', 'पश्चिम', 'पश्चिम');
const _south = _LocalizedText('South', 'दक्षिण', 'दक्षिण');

// Display associations from the sign's traditional ruler. These values
// are app editorial defaults. Muhurat is computed separately from daylight.
const _rulers = [
  _Ruler(
    _LocalizedText('Mars (Mangal)', 'मंगल', 'मंगळ'),
    _LocalizedText('Red', 'लाल', 'लाल'),
    9,
    _south,
    _LocalizedText('Om Angarakaya Namaha', 'ॐ अंगारकाय नमः', 'ॐ अंगारकाय नमः'),
    _LocalizedText(
      'Offer red flowers during prayer or donate a little jaggery.',
      'पूजा में लाल फूल अर्पित करें या थोड़ा गुड़ दान करें।',
      'पूजेत लाल फुले अर्पण करा किंवा थोडा गूळ दान करा.',
    ),
  ),
  _Ruler(
    _LocalizedText('Venus (Shukra)', 'शुक्र', 'शुक्र'),
    _LocalizedText('Ivory', 'सफेद', 'पांढरा'),
    6,
    _north,
    _LocalizedText('Om Shukraya Namaha', 'ॐ शुक्राय नमः', 'ॐ शुक्राय नमः'),
    _LocalizedText(
      'Offer a white flower or share a small sweet with someone.',
      'सफेद फूल अर्पित करें या किसी के साथ थोड़ा मिष्ठान बाँटें।',
      'पांढरे फूल अर्पण करा किंवा एखाद्याला थोडा गोड पदार्थ द्या.',
    ),
  ),
  _Ruler(
    _LocalizedText('Mercury (Budha)', 'बुध', 'बुध'),
    _LocalizedText('Green', 'हरा', 'हिरवा'),
    5,
    _east,
    _LocalizedText('Om Budhaya Namaha', 'ॐ बुधाय नमः', 'ॐ बुधाय नमः'),
    _LocalizedText(
      'Read a few lines from a devotional text you value.',
      'अपनी पसंद के किसी भक्तिपूर्ण ग्रंथ की कुछ पंक्तियाँ पढ़ें।',
      'आवडीच्या भक्तिग्रंथातील काही ओळी वाचा.',
    ),
  ),
  _Ruler(
    _LocalizedText('Moon (Chandra)', 'चंद्र', 'चंद्र'),
    _LocalizedText('Pearl white', 'मोती जैसा सफेद', 'मोत्यासारखा पांढरा'),
    2,
    _north,
    _LocalizedText('Om Chandraya Namaha', 'ॐ चन्द्राय नमः', 'ॐ चन्द्राय नमः'),
    _LocalizedText(
      'Offer a white flower during your evening prayer.',
      'संध्या की प्रार्थना में सफेद फूल अर्पित करें।',
      'संध्याकाळच्या प्रार्थनेत पांढरे फूल अर्पण करा.',
    ),
  ),
  _Ruler(
    _LocalizedText('Sun (Surya)', 'सूर्य', 'सूर्य'),
    _LocalizedText('Gold', 'सुनहरा', 'सोनेरी'),
    1,
    _south,
    _LocalizedText('Om Suryaya Namaha', 'ॐ सूर्याय नमः', 'ॐ सूर्याय नमः'),
    _LocalizedText(
      'Offer water to Surya in the morning if it is part of your practice.',
      'अपनी परंपरा के अनुसार सुबह सूर्य को जल अर्पित करें।',
      'आपल्या परंपरेनुसार सकाळी सूर्याला अर्घ्य द्या.',
    ),
  ),
  _Ruler(
    _LocalizedText('Jupiter (Guru)', 'गुरु', 'गुरू'),
    _LocalizedText('Yellow', 'पीला', 'पिवळा'),
    3,
    _east,
    _LocalizedText(
      'Om Brihaspataye Namaha',
      'ॐ बृहस्पतये नमः',
      'ॐ बृहस्पतये नमः',
    ),
    _LocalizedText(
      'Offer yellow flowers or make time to teach someone a useful skill.',
      'पीले फूल अर्पित करें या किसी को कोई उपयोगी बात सिखाएँ।',
      'पिवळी फुले अर्पण करा किंवा एखाद्याला उपयोगाची गोष्ट शिकवा.',
    ),
  ),
  _Ruler(
    _LocalizedText('Saturn (Shani)', 'शनि', 'शनी'),
    _LocalizedText('Indigo', 'गहरा नीला', 'गडद निळा'),
    8,
    _west,
    _LocalizedText(
      'Om Shanaishcharaya Namaha',
      'ॐ शनैश्चराय नमः',
      'ॐ शनैश्चराय नमः',
    ),
    _LocalizedText(
      'Offer a few moments of service to someone who could use help.',
      'किसी ज़रूरतमंद की मदद के लिए कुछ समय दें।',
      'मदतीची गरज असलेल्या व्यक्तीसाठी काही वेळ द्या.',
    ),
  ),
];

_Ruler _rulerForSign(int index) =>
    _rulers[const [0, 1, 2, 3, 4, 2, 1, 0, 5, 6, 6, 5][index]];

HoroscopePage _serverHoroscopePage(
  Map<String, dynamic> data,
  Rashi rashi,
  String period,
  HoroscopeCity? city,
) {
  final json = data['presentation'] as Map<String, dynamic>;
  final rawMuhurat = json['muhuratUtc'] as Map<String, dynamic>?;
  final rawIngress = json['moonIngressUtc'] as String?;
  final muhurat = rawMuhurat == null
      ? null
      : (
          start: DateTime.parse(rawMuhurat['start'] as String).toUtc(),
          end: DateTime.parse(rawMuhurat['end'] as String).toUtc(),
        );
  if (muhurat != null &&
      (city == null || !muhurat.start.isBefore(muhurat.end))) {
    throw const FormatException('Invalid city-specific horoscope window');
  }

  List<HoroscopeSection> sections(
    String key,
    List<HoroscopeSectionKind> order,
  ) {
    final rows = json[key] as List<dynamic>;
    if (rows.length != order.length) {
      throw const FormatException('Incomplete horoscope sections');
    }
    return List.unmodifiable([
      for (var index = 0; index < order.length; index++)
        _serverSection(
          rows[index] as Map<String, dynamic>,
          expected: order[index],
        ),
    ]);
  }

  return HoroscopePage._(
    reading: HoroscopeReading.fromJson(
      data,
      rashiId: rashi.id,
      period: period,
      dateText: data['dateText'] as String,
      isAiGenerated: data['isAiGenerated'] as bool,
    ),
    symbol: json['symbol'] as String,
    signTitle: json['signTitle'] as String,
    dateAndDay: json['dateAndDay'] as String,
    sunSignDates: json['sunSignDates'] as String,
    element: json['element'] as String,
    rulingPlanet: json['rulingPlanet'] as String,
    headline: json['headline'] as String,
    mood: json['mood'] as String,
    moodScore: (json['moodScore'] as num).toDouble(),
    ephemerisSource: json['ephemerisSource'] as String,
    transitNote: json['transitNote'] as String,
    moonIngressUtc: rawIngress == null
        ? null
        : DateTime.parse(rawIngress).toUtc(),
    muhuratUtc: muhurat,
    fullSections: sections('fullSections', HoroscopeSectionKind.values),
    summarySections: sections('summarySections', const [
      HoroscopeSectionKind.general,
      HoroscopeSectionKind.lifeAspects,
      HoroscopeSectionKind.actions,
      HoroscopeSectionKind.luckyElements,
    ]),
  );
}

HoroscopeSection _serverSection(
  Map<String, dynamic> data, {
  required HoroscopeSectionKind expected,
}) {
  if (data['kind'] != expected.name) {
    throw const FormatException('Invalid horoscope section order');
  }
  final lines = (data['lines'] as List<dynamic>).cast<Map<String, dynamic>>();
  if (lines.isEmpty) throw const FormatException('Empty horoscope section');
  return HoroscopeSection(expected, data['title'] as String, [
    for (final line in lines)
      (
        label: line['label'] as String,
        text: line['text'] as String,
        score: (line['score'] as num?)?.toDouble(),
      ),
  ]);
}

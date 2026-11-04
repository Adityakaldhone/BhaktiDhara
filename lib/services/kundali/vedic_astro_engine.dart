import 'dart:math' as math;

/// The nine grahas in traditional order. Index order is relied on by
/// the string tables in `kundali_strings.dart`.
enum Graha { sun, moon, mars, mercury, jupiter, venus, saturn, rahu, ketu }

class GrahaPosition {
  const GrahaPosition({
    required this.graha,
    required this.longitude,
    required this.isRetrograde,
  });

  final Graha graha;

  /// Sidereal (Lahiri) longitude, 0–360°.
  final double longitude;
  final bool isRetrograde;

  /// 0 = Mesha … 11 = Meena.
  int get rashi => longitude ~/ 30;
  double get degreeInRashi => longitude % 30;
  int get nakshatra => nakshatraOf(longitude);
  int get pada => padaOf(longitude);
  int get navamsaRashi => navamsaOf(longitude);
}

class VimshottariPeriod {
  const VimshottariPeriod(this.lord, this.start, this.end);

  final Graha lord;
  final DateTime start;
  final DateTime end;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);
}

class KundaliData {
  const KundaliData({
    required this.birthUtc,
    required this.ayanamsa,
    required this.lagnaLongitude,
    required this.grahas,
  });

  final DateTime birthUtc;
  final double ayanamsa;

  /// Sidereal ascendant longitude, 0–360°.
  final double lagnaLongitude;
  final List<GrahaPosition> grahas;

  int get lagnaRashi => lagnaLongitude ~/ 30;
  int get lagnaNavamsa => navamsaOf(lagnaLongitude);
  GrahaPosition get moon => grahas[Graha.moon.index];
  GrahaPosition get sun => grahas[Graha.sun.index];

  /// Whole-sign house (1–12) of [g] counted from the Lagna.
  int houseOf(GrahaPosition g) => (g.rashi - lagnaRashi + 12) % 12 + 1;

  /// The nine Vimshottari mahadashas starting from the one running at birth.
  List<VimshottariPeriod> mahadashas() {
    const span = 360 / 27;
    final moonLon = moon.longitude;
    final startIndex = moon.nakshatra % 9;
    final elapsed = (moonLon % span) / span;
    final firstYears = _dashaYears[_dashaOrder[startIndex]]!;
    var cursor = _addYears(birthUtc, -elapsed * firstYears);
    return List.generate(9, (i) {
      final lord = _dashaOrder[(startIndex + i) % 9];
      final end = _addYears(cursor, _dashaYears[lord]!.toDouble());
      final period = VimshottariPeriod(lord, cursor, end);
      cursor = end;
      return period;
    });
  }

  /// The nine antardashas inside [maha].
  static List<VimshottariPeriod> antardashas(VimshottariPeriod maha) {
    final mahaYears = _dashaYears[maha.lord]!;
    final startIndex = _dashaOrder.indexOf(maha.lord);
    var cursor = maha.start;
    return List.generate(9, (i) {
      final lord = _dashaOrder[(startIndex + i) % 9];
      final end = _addYears(cursor, mahaYears * _dashaYears[lord]! / 120);
      final period = VimshottariPeriod(lord, cursor, end);
      cursor = end;
      return period;
    });
  }

  /// Lord of nakshatra [index] (0–26) in the Vimshottari scheme.
  static Graha nakshatraLord(int index) => _dashaOrder[index % 9];
}

int nakshatraOf(double siderealLon) => (siderealLon / (360 / 27)).floor() % 27;
int padaOf(double siderealLon) =>
    ((siderealLon % (360 / 27)) / (360 / 108)).floor() + 1;
int navamsaOf(double siderealLon) => (siderealLon * 9 / 30).floor() % 12;

const _dashaOrder = [
  Graha.ketu, Graha.venus, Graha.sun, Graha.moon, Graha.mars,
  Graha.rahu, Graha.jupiter, Graha.saturn, Graha.mercury,
];

const _dashaYears = {
  Graha.ketu: 7, Graha.venus: 20, Graha.sun: 6, Graha.moon: 10,
  Graha.mars: 7, Graha.rahu: 18, Graha.jupiter: 16, Graha.saturn: 19,
  Graha.mercury: 17,
};

DateTime _addYears(DateTime t, double years) =>
    t.add(Duration(milliseconds: (years * 365.25 * 86400000).round()));

/// Sidereal Vedic chart calculator.
///
/// Sun and planets use the JPL Keplerian elements valid for 1800–2050
/// (Standish), the Moon uses the main terms of Meeus ch. 47, Rahu is the mean
/// node and the ayanamsa is Lahiri. Positions are good to a few arcminutes,
/// which is ample for rashi, nakshatra-pada and whole-sign houses.
class VedicAstroEngine {
  const VedicAstroEngine();

  KundaliData calculate({
    required DateTime birthUtc,
    required double latitude,
    required double longitude,
  }) {
    final utc = birthUtc.toUtc();
    final jd = _julianDay(utc);
    final ayanamsa = lahiriAyanamsa(utc);

    double sid(double tropical) => _norm(tropical - ayanamsa);

    final grahas = <GrahaPosition>[];
    for (final g in Graha.values) {
      final lon = _tropicalLongitude(g, jd);
      final retro = switch (g) {
        Graha.sun || Graha.moon || Graha.rahu || Graha.ketu => false,
        _ => _signedDelta(
              _tropicalLongitude(g, jd + 0.5),
              _tropicalLongitude(g, jd - 0.5),
            ) <
            0,
      };
      grahas.add(GrahaPosition(graha: g, longitude: sid(lon), isRetrograde: retro));
    }

    return KundaliData(
      birthUtc: utc,
      ayanamsa: ayanamsa,
      lagnaLongitude: sid(_ascendant(jd, latitude, longitude)),
      grahas: grahas,
    );
  }

  /// Lahiri ayanamsa, matching the formula `tithi_engine` uses for Panchang.
  static double lahiriAyanamsa(DateTime utc) {
    final year = utc.year + (utc.month - 1) / 12.0 + (utc.day - 1) / 365.25;
    final t = (year - 2000) / 100.0;
    return 23.8571 + 1.3970 * t + 0.0003 * t * t;
  }

  /// Tropical longitude (mean equinox of date) for [g].
  static double tropicalLongitude(Graha g, DateTime utc) =>
      _tropicalLongitude(g, _julianDay(utc.toUtc()));

  static double _tropicalLongitude(Graha g, double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    switch (g) {
      case Graha.moon:
        return _moonLongitude(t);
      case Graha.rahu:
        return _meanNode(t);
      case Graha.ketu:
        return _norm(_meanNode(t) + 180);
      case Graha.sun:
        final e = _helio(_earth, t);
        return _norm(_deg(math.atan2(-e.y, -e.x)) + _precession(t));
      default:
        final e = _helio(_earth, t);
        final p = _helio(_elements[g]!, t);
        return _norm(_deg(math.atan2(p.y - e.y, p.x - e.x)) + _precession(t));
    }
  }

  static double _ascendant(double jd, double lat, double lon) {
    final t = (jd - 2451545.0) / 36525.0;
    final gmst = 280.46061837 +
        360.98564736629 * (jd - 2451545.0) +
        0.000387933 * t * t -
        t * t * t / 38710000;
    final theta = _rad(_norm(gmst + lon));
    final eps = _rad(23.439291 - 0.0130042 * t);
    final phi = _rad(lat.clamp(-66.0, 66.0));
    final asc = math.atan2(
      math.cos(theta),
      -(math.sin(theta) * math.cos(eps) + math.tan(phi) * math.sin(eps)),
    );
    return _norm(_deg(asc));
  }

  /// General precession in longitude from J2000 to date, degrees.
  static double _precession(double t) => (5028.796195 * t + 1.1054348 * t * t) / 3600;

  static double _meanNode(double t) => _norm(125.0445479 -
      1934.1362891 * t +
      0.0020754 * t * t +
      t * t * t / 467441 -
      t * t * t * t / 60616000);

  static double _moonLongitude(double t) {
    final t2 = t * t, t3 = t2 * t, t4 = t3 * t;
    final lp = 218.3164477 + 481267.88123421 * t - 0.0015786 * t2 + t3 / 538841 - t4 / 65194000;
    final d = 297.8501921 + 445267.1114034 * t - 0.0018819 * t2 + t3 / 545868 - t4 / 113065000;
    final m = 357.5291092 + 35999.0502909 * t - 0.0001536 * t2 + t3 / 24490000;
    final mp = 134.9633964 + 477198.8675055 * t + 0.0087414 * t2 + t3 / 69699 - t4 / 14712000;
    final f = 93.2720950 + 483202.0175233 * t - 0.0036539 * t2 - t3 / 3526000 + t4 / 863310000;
    final e = 1 - 0.002516 * t - 0.0000074 * t2;

    var sum = 0.0;
    for (final row in _moonTerms) {
      final arg = row[0] * d + row[1] * m + row[2] * mp + row[3] * f;
      var coeff = row[4].toDouble();
      final mAbs = row[1].abs();
      if (mAbs == 1) coeff *= e;
      if (mAbs == 2) coeff *= e * e;
      sum += coeff * math.sin(_rad(arg));
    }
    final a1 = 119.75 + 131.849 * t;
    final a2 = 53.09 + 479264.290 * t;
    sum += 3958 * math.sin(_rad(a1)) + 1962 * math.sin(_rad(lp - f)) + 318 * math.sin(_rad(a2));
    return _norm(lp + sum / 1e6);
  }

  static ({double x, double y}) _helio(List<double> el, double t) {
    final a = el[0] + el[6] * t;
    final ecc = el[1] + el[7] * t;
    final inc = _rad(el[2] + el[8] * t);
    final l = el[3] + el[9] * t;
    final peri = el[4] + el[10] * t;
    final node = el[5] + el[11] * t;

    final w = _rad(peri - node);
    final om = _rad(node);
    final mAnom = _rad(_norm(l - peri));

    var ea = mAnom + ecc * math.sin(mAnom);
    for (var i = 0; i < 8; i++) {
      ea -= (ea - ecc * math.sin(ea) - mAnom) / (1 - ecc * math.cos(ea));
    }
    final xp = a * (math.cos(ea) - ecc);
    final yp = a * math.sqrt(1 - ecc * ecc) * math.sin(ea);

    final cw = math.cos(w), sw = math.sin(w);
    final co = math.cos(om), so = math.sin(om);
    final ci = math.cos(inc);
    return (
      x: (cw * co - sw * so * ci) * xp + (-sw * co - cw * so * ci) * yp,
      y: (cw * so + sw * co * ci) * xp + (-sw * so + cw * co * ci) * yp,
    );
  }

  static double _julianDay(DateTime utc) =>
      utc.millisecondsSinceEpoch / 86400000.0 + 2440587.5;

  static double _signedDelta(double a, double b) => (a - b + 540) % 360 - 180;
  static double _norm(double deg) => (deg % 360 + 360) % 360;
  static double _rad(double deg) => deg * math.pi / 180;
  static double _deg(double rad) => rad * 180 / math.pi;
}

// a, e, I, L, long.peri, long.node, then their rates per Julian century.
const _earth = [
  1.00000261, 0.01671123, -0.00001531, 100.46457166, 102.93768193, 0.0,
  0.00000562, -0.00004392, -0.01294668, 35999.37244981, 0.32327364, 0.0,
];

const _elements = {
  Graha.mercury: [
    0.38709927, 0.20563593, 7.00497902, 252.25032350, 77.45779628, 48.33076593,
    0.00000037, 0.00001906, -0.00594749, 149472.67411175, 0.16047689, -0.12534081,
  ],
  Graha.venus: [
    0.72333566, 0.00677672, 3.39467605, 181.97909950, 131.60246718, 76.67984255,
    0.00000390, -0.00004107, -0.00078890, 58517.81538729, 0.00268329, -0.27769418,
  ],
  Graha.mars: [
    1.52371034, 0.09339410, 1.84969142, -4.55343205, -23.94362959, 49.55953891,
    0.00001847, 0.00007882, -0.00813131, 19140.30268499, 0.44441088, -0.29257343,
  ],
  Graha.jupiter: [
    5.20288700, 0.04838624, 1.30439695, 34.39644051, 14.72847983, 100.47390909,
    -0.00011607, -0.00013253, -0.00183714, 3034.74612775, 0.21252668, 0.20469106,
  ],
  Graha.saturn: [
    9.53667594, 0.05386179, 2.48599187, 49.95424423, 92.59887831, 113.66242448,
    -0.00125060, -0.00050991, 0.00193609, 1222.49362201, -0.41897216, -0.28867794,
  ],
};

// Meeus Table 47.A: multiples of D, M, M', F and the sine coefficient (1e-6°).
const _moonTerms = [
  [0, 0, 1, 0, 6288774], [2, 0, -1, 0, 1274027], [2, 0, 0, 0, 658314],
  [0, 0, 2, 0, 213618], [0, 1, 0, 0, -185116], [0, 0, 0, 2, -114332],
  [2, 0, -2, 0, 58793], [2, -1, -1, 0, 57066], [2, 0, 1, 0, 53322],
  [2, -1, 0, 0, 45758], [0, 1, -1, 0, -40923], [1, 0, 0, 0, -34720],
  [0, 1, 1, 0, -30383], [2, 0, 0, -2, 15327], [0, 0, 1, 2, -12528],
  [0, 0, 1, -2, 10980], [4, 0, -1, 0, 10675], [0, 0, 3, 0, 10034],
  [4, 0, -2, 0, 8548], [2, 1, -1, 0, -7888], [2, 1, 0, 0, -6766],
  [1, 0, -1, 0, -5163], [1, 1, 0, 0, 4987], [2, -1, 1, 0, 4036],
  [2, 0, 2, 0, 3994], [4, 0, 0, 0, 3861], [2, 0, -3, 0, 3665],
  [0, 1, -2, 0, -2689], [2, 0, -1, 2, -2602], [2, -1, -2, 0, 2390],
  [1, 0, 1, 0, -2348], [2, -2, 0, 0, 2236], [0, 1, 2, 0, -2120],
  [0, 2, 0, 0, -2069], [2, -2, -1, 0, 2048], [2, 0, 1, -2, -1773],
  [2, 0, 0, 2, -1595], [4, -1, -1, 0, 1215], [0, 0, 2, 2, -1110],
  [3, 0, -1, 0, -892], [2, 1, 1, 0, -810], [4, -1, -2, 0, 759],
  [0, 2, -1, 0, -713], [2, 2, -1, 0, -700], [2, 1, -2, 0, 691],
  [2, -1, 0, -2, 596], [4, 0, 1, 0, 549], [0, 0, 4, 0, 537],
  [4, -1, 0, 0, 520], [1, 0, -2, 0, -487], [2, 1, 0, -2, -399],
  [0, 0, 2, -2, -381], [1, 1, 1, 0, 351], [3, 0, -2, 0, -340],
  [4, 0, -3, 0, 330], [2, -1, 2, 0, 327], [0, 2, 1, 0, -323],
  [1, 1, -1, 0, 299], [2, 0, 3, 0, 294],
];

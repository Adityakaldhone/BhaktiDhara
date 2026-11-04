import 'dart:math' as math;

import 'package:astronomia/angle.dart' as angle;
import 'package:astronomia/astronomia.dart' as astro;
import 'package:astronomia/eclipse.dart' as eclipse;
import 'package:astronomia/globe.dart' as globe;
import 'package:astronomia/moonposition.dart' as moonpos;
import 'package:astronomia/planetposition.dart' as planetpos;
import 'package:astronomia/semidiameter.dart' as semidiameter;
import 'package:astronomia/solar.dart' as solar;

enum GrahanKind { surya, chandra }

enum GrahanType { total, annular, hybrid, partial, penumbral }

/// One eclipse with its circumstances for a single observer.
class GrahanEvent {
  const GrahanEvent({
    required this.kind,
    required this.type,
    required this.greatestUtc,
    required this.magnitude,
    required this.visible,
    this.sparshUtc,
    this.madhyaUtc,
    this.mokshaUtc,
    this.totalStartUtc,
    this.totalEndUtc,
    this.visibleFromUtc,
    this.visibleToUtc,
    this.localMagnitude,
  });

  final GrahanKind kind;

  /// Global type; for a solar eclipse seen partially here, see [localMagnitude].
  final GrahanType type;
  final DateTime greatestUtc;
  final double magnitude;

  /// Whether any eclipsed phase is above the horizon at the observer.
  final bool visible;

  /// First contact (स्पर्श), greatest (मध्य) and last contact (मोक्ष).
  /// Solar: local contacts, null when the eclipse misses the place entirely.
  /// Lunar: umbral contacts (penumbral for a penumbral-only eclipse).
  final DateTime? sparshUtc;
  final DateTime? madhyaUtc;
  final DateTime? mokshaUtc;

  /// Totality (or annularity) — lunar only.
  final DateTime? totalStartUtc;
  final DateTime? totalEndUtc;

  /// Part of the eclipse that is above the horizon here.
  final DateTime? visibleFromUtc;
  final DateTime? visibleToUtc;

  /// Fraction of the Sun's diameter covered at the local maximum (solar only).
  final double? localMagnitude;

  /// Penumbral lunar eclipses are not observed (no sutak, no rituals).
  bool get isObserved => type != GrahanType.penumbral;

  /// Sutak: 12 hours (4 prahar) before a solar and 9 hours (3 prahar) before
  /// a lunar eclipse — only where the eclipse is visible.
  DateTime? get sutakUtc {
    if (!visible || !isObserved || sparshUtc == null) return null;
    return sparshUtc!.subtract(Duration(hours: kind == GrahanKind.surya ? 12 : 9));
  }

  /// Relaxed sutak for children, the elderly and the unwell.
  DateTime? get relaxedSutakUtc {
    if (sutakUtc == null) return null;
    return sparshUtc!.subtract(Duration(hours: kind == GrahanKind.surya ? 4 : 3));
  }

  /// Stable id for reminders and list keys.
  String get id => '${kind.name}_${greatestUtc.millisecondsSinceEpoch ~/ 60000}';
}

class GrahanEngine {
  GrahanEngine();

  final planetpos.Planet _earth = planetpos.Planet(planetpos.planetEarth);

  /// Eclipses whose greatest phase falls in [fromUtc, toUtc), oldest first,
  /// with circumstances for the observer at [latitude], [longitude] (degrees,
  /// east positive).
  List<GrahanEvent> between(
    DateTime fromUtc,
    DateTime toUtc, {
    required double latitude,
    required double longitude,
  }) {
    final events = <GrahanEvent>[];
    final seen = <int>{};
    const lunation = 1 / 12.3685;
    final startYear = _decimalYear(fromUtc) - lunation;
    final endYear = _decimalYear(toUtc) + lunation;

    for (var y = startYear; y <= endYear; y += lunation) {
      final s = eclipse.solar(y);
      if (s.type != eclipse.none) {
        final key = (s.jmax * 24).round();
        if (seen.add(key)) {
          final e = _solarEvent(s, latitude, longitude);
          if (!e.greatestUtc.isBefore(fromUtc) && e.greatestUtc.isBefore(toUtc)) {
            events.add(e);
          }
        }
      }
      final l = eclipse.lunar(y);
      if (l.type != eclipse.none) {
        final key = (l.jmax * 24).round() + 1;
        if (seen.add(key)) {
          final e = _lunarEvent(l, latitude, longitude);
          if (!e.greatestUtc.isBefore(fromUtc) && e.greatestUtc.isBefore(toUtc)) {
            events.add(e);
          }
        }
      }
    }
    events.sort((a, b) => a.greatestUtc.compareTo(b.greatestUtc));
    return events;
  }

  // ── Lunar ────────────────────────────────────────────────────────────────

  GrahanEvent _lunarEvent(
    ({
      int type,
      double jmax,
      double gamma,
      double rho,
      double sigma,
      double mag,
      double sdTotal,
      double sdPartial,
      double sdPenumbral,
    }) l,
    double lat,
    double lon,
  ) {
    final type = switch (l.type) {
      eclipse.total => GrahanType.total,
      eclipse.umbral => GrahanType.partial,
      _ => GrahanType.penumbral,
    };
    final maxUt = l.jmax - _deltaT(l.jmax) / 86400;
    final semi = type == GrahanType.penumbral ? l.sdPenumbral : l.sdPartial;
    final start = maxUt - semi;
    final end = maxUt + semi;

    final window = _aboveHorizonWindow(start, end, (jd) => _moonAltitude(jd, lat, lon));

    return GrahanEvent(
      kind: GrahanKind.chandra,
      type: type,
      greatestUtc: _toDate(maxUt),
      magnitude: l.mag,
      visible: window != null,
      sparshUtc: _toDate(start),
      madhyaUtc: _toDate(maxUt),
      mokshaUtc: _toDate(end),
      totalStartUtc: type == GrahanType.total ? _toDate(maxUt - l.sdTotal) : null,
      totalEndUtc: type == GrahanType.total ? _toDate(maxUt + l.sdTotal) : null,
      visibleFromUtc: window == null ? null : _toDate(window.$1),
      visibleToUtc: window == null ? null : _toDate(window.$2),
    );
  }

  double _moonAltitude(double jdUt, double lat, double lon) {
    final jde = jdUt + _deltaT(jdUt) / 86400;
    final n = astro.nutation(jde);
    final eps = astro.meanObliquity(jde) + n.dEps;
    final m = moonpos.position(jde);
    final eq = astro.eclToEq(m.lon + n.dPsi, m.lat, math.sin(eps), math.cos(eps));
    final theta = astro.apparent(jdUt) * 2 * math.pi / 86400;
    return astro.eqToHz(eq.ra, eq.dec, _rad(lat), -_rad(lon), theta).alt;
  }

  // ── Solar ────────────────────────────────────────────────────────────────

  GrahanEvent _solarEvent(
    ({int type, bool central, double jmax, double gamma, double u, double p, double mag}) s,
    double lat,
    double lon,
  ) {
    final type = switch (s.type) {
      eclipse.total => GrahanType.total,
      eclipse.annular => GrahanType.annular,
      eclipse.annularTotal => GrahanType.hybrid,
      _ => GrahanType.partial,
    };
    final maxUt = s.jmax - _deltaT(s.jmax) / 86400;
    final observer = globe.parallaxConstants(_rad(lat), 0);
    final dt = _deltaT(s.jmax);

    _SolarSample sample(double jdUt) => _solarSample(jdUt, dt, lat, lon, observer);
    bool eclipsed(_SolarSample x) => x.separation < x.sunRadius + x.moonRadius;

    // Local partial phase can lie up to ~3.5 h either side of global maximum.
    const step = 1 / 1440;
    double? first, last;
    _SolarSample? best;
    for (var jd = maxUt - 4 / 24; jd <= maxUt + 4 / 24; jd += step) {
      final x = sample(jd);
      if (!eclipsed(x)) continue;
      first ??= jd;
      last = jd;
      if (best == null || x.separation < best.separation) best = x;
    }

    final globalMag = type == GrahanType.partial ? s.mag : 1.0;
    if (first == null || last == null || best == null) {
      return GrahanEvent(
        kind: GrahanKind.surya,
        type: type,
        greatestUtc: _toDate(maxUt),
        magnitude: globalMag,
        visible: false,
      );
    }

    double refine(double outside, double inside) {
      for (var i = 0; i < 12; i++) {
        final mid = (outside + inside) / 2;
        if (eclipsed(sample(mid))) {
          inside = mid;
        } else {
          outside = mid;
        }
      }
      return inside;
    }

    final start = refine(first - step, first);
    final end = refine(last + step, last);
    final localMag =
        (best.sunRadius + best.moonRadius - best.separation) / (2 * best.sunRadius);
    final window = _aboveHorizonWindow(start, end, (jd) => sample(jd).sunAltitude);

    return GrahanEvent(
      kind: GrahanKind.surya,
      type: type,
      greatestUtc: _toDate(maxUt),
      magnitude: globalMag,
      visible: window != null,
      sparshUtc: _toDate(start),
      madhyaUtc: _toDate(best.jdUt),
      mokshaUtc: _toDate(end),
      visibleFromUtc: window == null ? null : _toDate(window.$1),
      visibleToUtc: window == null ? null : _toDate(window.$2),
      localMagnitude: localMag.clamp(0.0, 1.1),
    );
  }

  _SolarSample _solarSample(
    double jdUt,
    double deltaT,
    double lat,
    double lon,
    ({double rhsSinPhiPrime, double rhoCosPrime}) observer,
  ) {
    final jde = jdUt + deltaT / 86400;
    final n = astro.nutation(jde);
    final eps = astro.meanObliquity(jde) + n.dEps;
    final sinEps = math.sin(eps), cosEps = math.cos(eps);
    final westLon = -_rad(lon);

    final sunEcl = solar.apparentVSOP87(_earth, jde);
    final sunEq = astro.eclToEq(sunEcl.lon, sunEcl.lat, sinEps, cosEps);
    final moonEcl = moonpos.position(jde);
    final moonEq = astro.eclToEq(moonEcl.lon + n.dPsi, moonEcl.lat, sinEps, cosEps);

    final theta = astro.apparent(jdUt) * 2 * math.pi / 86400;
    final sunTopo = astro.topocentric(
      sunEq.ra,
      sunEq.dec,
      sunEcl.range,
      observer.rhsSinPhiPrime,
      observer.rhoCosPrime,
      theta - westLon - sunEq.ra,
      math.sin(astro.horizontal(sunEcl.range)),
    );
    final moonTopo = astro.topocentric(
      moonEq.ra,
      moonEq.dec,
      moonEcl.delta / astro.au,
      observer.rhsSinPhiPrime,
      observer.rhoCosPrime,
      theta - westLon - moonEq.ra,
      math.sin(moonpos.parallax(moonEcl.delta)),
    );

    return _SolarSample(
      jdUt: jdUt,
      separation: angle.sepHav(sunTopo.ra, sunTopo.dec, moonTopo.ra, moonTopo.dec),
      sunRadius: semidiameter.semidiameter(semidiameter.sunSd, sunEcl.range),
      moonRadius: semidiameter.semidiameter(semidiameter.moonSd, moonEcl.delta),
      sunAltitude: astro.eqToHz(sunTopo.ra, sunTopo.dec, _rad(lat), westLon, theta).alt,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Visible part of [start, end] where `altitude(jd)` is above the
  /// rise/set threshold (−0.833° for refraction + semidiameter), sampled per
  /// minute; null when never visible.
  (double, double)? _aboveHorizonWindow(
    double start,
    double end,
    double Function(double jdUt) altitude,
  ) {
    const threshold = -0.833 * math.pi / 180;
    const step = 1 / 1440;
    double? from, to;
    for (var jd = start; jd <= end + step / 2; jd += step) {
      final t = math.min(jd, end);
      if (altitude(t) > threshold) {
        from ??= t;
        to = t;
      }
    }
    return from == null ? null : (from, to!);
  }

  static double _deltaT(double jd) {
    final year = astro.jdeToJulianYear(jd);
    if (year >= 1620 && year <= 2010) return astro.interp10A(jd);
    return astro.polyAfter2000(year);
  }

  static double _decimalYear(DateTime utc) =>
      utc.year + (utc.difference(DateTime.utc(utc.year)).inHours / (24 * 365.25));

  static DateTime _toDate(double jdUt) => DateTime.fromMillisecondsSinceEpoch(
        ((jdUt - 2440587.5) * 86400000).round(),
        isUtc: true,
      );

  static double _rad(double deg) => deg * math.pi / 180;
}

class _SolarSample {
  const _SolarSample({
    required this.jdUt,
    required this.separation,
    required this.sunRadius,
    required this.moonRadius,
    required this.sunAltitude,
  });

  final double jdUt;
  final double separation;
  final double sunRadius;
  final double moonRadius;
  final double sunAltitude;
}

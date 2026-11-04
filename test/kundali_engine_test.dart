import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/domain/entities/birth_profile.dart';
import 'package:nitya_aarti/services/kundali/kundali_service.dart';
import 'package:nitya_aarti/services/kundali/vedic_astro_engine.dart';

/// Reference values from Swiss Ephemeris 2.10 (Lahiri, mean node, whole sign).
/// Order: Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn, Rahu.
const _cases = [
  (
    utc: [1998, 11, 9, 2, 17], lat: 27.7172, lon: 85.324, asc: 223.618,
    lons: [202.632, 89.285, 145.661, 225.293, 324.357, 205.136, 5.05, 123.36],
    retro: [false, false, false, false, true, false, true],
  ),
  (
    utc: [1990, 5, 15, 9, 0], lat: 18.52, lon: 73.855, asc: 148.369,
    lons: [30.55, 271.894, 324.515, 14.302, 75.792, 348.95, 271.526, 287.62],
    retro: [false, false, false, true, false, false, true],
  ),
  (
    utc: [1943, 3, 10, 4, 30], lat: 19.07, lon: 72.88, asc: 22.665,
    lons: [325.671, 13.908, 278.177, 305.355, 82.117, 352.574, 43.463, 120.842],
    retro: [false, false, false, false, true, false, false],
  ),
  (
    utc: [2026, 10, 30, 14, 34], lat: 40.71, lon: -74.0, asc: 229.704,
    lons: [192.95, 73.311, 113.683, 203.85, 119.918, 182.731, 345.141, 301.913],
    retro: [false, false, false, true, false, true, true],
  ),
];

double _diff(double a, double b) => ((a - b + 540) % 360 - 180).abs();

void main() {
  group('VedicAstroEngine matches Swiss Ephemeris', () {
    for (final c in _cases) {
      test(c.utc.take(3).join('-'), () {
        final u = c.utc;
        final k = const VedicAstroEngine().calculate(
          birthUtc: DateTime.utc(u[0], u[1], u[2], u[3], u[4]),
          latitude: c.lat,
          longitude: c.lon,
        );
        expect(_diff(k.lagnaLongitude, c.asc), lessThan(0.02));
        for (var i = 0; i < 8; i++) {
          // Jupiter/Saturn use the coarser JPL elements (≈10′ worst case).
          final tolerance = (i == 4 || i == 6) ? 0.2 : 0.03;
          expect(_diff(k.grahas[i].longitude, c.lons[i]), lessThan(tolerance),
              reason: Graha.values[i].name);
        }
        for (var i = 0; i < 7; i++) {
          expect(k.grahas[i].isRetrograde, c.retro[i], reason: Graha.values[i].name);
        }
        expect(
          _diff(k.grahas[Graha.ketu.index].longitude, k.grahas[Graha.rahu.index].longitude + 180),
          lessThan(1e-9),
        );
      });
    }
  });

  test('birth time uses historical Indian war time (+6:30 in 1943)', () {
    final profile = BirthProfile(
      id: 'x',
      name: 'Test',
      birthLocal: DateTime(1943, 3, 10, 11, 0),
      place: const BirthPlace(
        name: 'Mumbai',
        region: '',
        latitude: 19.07,
        longitude: 72.88,
        timezone: 'Asia/Kolkata',
      ),
    );
    expect(KundaliService.birthUtc(profile), DateTime.utc(1943, 3, 10, 4, 30));
  });

  test('Vimshottari mahadashas are contiguous and span 120 years', () {
    final k = const VedicAstroEngine().calculate(
      birthUtc: DateTime.utc(1990, 5, 15, 9),
      latitude: 18.52,
      longitude: 73.855,
    );
    final mahas = k.mahadashas();
    expect(mahas.first.lord, KundaliData.nakshatraLord(k.moon.nakshatra));
    expect(mahas.first.contains(k.birthUtc), isTrue);
    for (var i = 1; i < mahas.length; i++) {
      expect(mahas[i].start, mahas[i - 1].end);
    }
    final years = mahas.last.end.difference(mahas.first.start).inDays / 365.25;
    expect(years, closeTo(120, 0.01));
    final antars = KundaliData.antardashas(mahas[1]);
    expect(antars.first.start, mahas[1].start);
    expect(antars.last.end.difference(mahas[1].end).inSeconds.abs(), lessThan(5));
  });
}

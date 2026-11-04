import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/services/grahan/grahan_engine.dart';

const _mumbaiLat = 19.076, _mumbaiLon = 72.8777;

void _near(DateTime? actual, DateTime expected, {int minutes = 3}) {
  expect(actual, isNotNull);
  expect(actual!.difference(expected).inMinutes.abs(), lessThanOrEqualTo(minutes),
      reason: 'got $actual, expected $expected');
}

GrahanEvent _find(List<GrahanEvent> events, GrahanKind kind, DateTime day) =>
    events.firstWhere((e) =>
        e.kind == kind && e.greatestUtc.difference(day).inHours.abs() < 36);

void main() {
  late List<GrahanEvent> events;

  setUpAll(() {
    events = GrahanEngine().between(
      DateTime.utc(2019, 12, 1),
      DateTime.utc(2026, 12, 31),
      latitude: _mumbaiLat,
      longitude: _mumbaiLon,
    );
  });

  test('finds every eclipse in the window', () {
    // NASA catalogue, Dec 2019 – Dec 2026: 15 solar + 16 lunar (incl. penumbral).
    expect(events.where((e) => e.kind == GrahanKind.surya).length, 15);
    expect(events.where((e) => e.kind == GrahanKind.chandra).length, 16);
  });

  test('annular solar eclipse of 26 Dec 2019 as seen from Mumbai', () {
    final e = _find(events, GrahanKind.surya, DateTime.utc(2019, 12, 26, 5));
    expect(e.type, GrahanType.annular);
    expect(e.visible, isTrue);
    _near(e.sparshUtc, DateTime.utc(2019, 12, 26, 2, 34));
    _near(e.mokshaUtc, DateTime.utc(2019, 12, 26, 5, 25));
    expect(e.localMagnitude, closeTo(0.84, 0.05));
    _near(e.sutakUtc, e.sparshUtc!.subtract(const Duration(hours: 12)), minutes: 0);
  });

  test('25 Oct 2022 partial solar eclipse sets while in progress in Mumbai', () {
    final e = _find(events, GrahanKind.surya, DateTime.utc(2022, 10, 25, 11));
    expect(e.visible, isTrue);
    _near(e.sparshUtc, DateTime.utc(2022, 10, 25, 11, 19));
    expect(e.visibleToUtc!.isBefore(e.mokshaUtc!), isTrue);
  });

  test('total lunar eclipse of 7 Sep 2025 matches NASA contact times', () {
    final e = _find(events, GrahanKind.chandra, DateTime.utc(2025, 9, 7, 18));
    expect(e.type, GrahanType.total);
    expect(e.visible, isTrue);
    _near(e.sparshUtc, DateTime.utc(2025, 9, 7, 16, 27));
    _near(e.totalStartUtc, DateTime.utc(2025, 9, 7, 17, 31));
    _near(e.madhyaUtc, DateTime.utc(2025, 9, 7, 18, 12));
    _near(e.totalEndUtc, DateTime.utc(2025, 9, 7, 18, 53));
    _near(e.mokshaUtc, DateTime.utc(2025, 9, 7, 19, 57));
    expect(e.sutakUtc, e.sparshUtc!.subtract(const Duration(hours: 9)));
  });

  test('3 Mar 2026 lunar eclipse is visible only after moonrise', () {
    final e = _find(events, GrahanKind.chandra, DateTime.utc(2026, 3, 3, 11));
    expect(e.visible, isTrue);
    expect(e.visibleFromUtc!.isAfter(e.sparshUtc!), isTrue);
  });

  test('8 Apr 2024 solar eclipse is not visible from India', () {
    final e = _find(events, GrahanKind.surya, DateTime.utc(2024, 4, 8, 18));
    expect(e.type, GrahanType.total);
    expect(e.visible, isFalse);
    expect(e.sutakUtc, isNull);
  });

  test('penumbral lunar eclipses carry no sutak', () {
    final e = _find(events, GrahanKind.chandra, DateTime.utc(2020, 1, 10, 19));
    expect(e.type, GrahanType.penumbral);
    expect(e.visible, isTrue);
    expect(e.isObserved, isFalse);
    expect(e.sutakUtc, isNull);
  });
}

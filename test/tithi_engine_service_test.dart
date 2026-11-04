import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/domain/entities/panchang_city.dart';
import 'package:nitya_aarti/domain/logic/panchang_timing.dart';
import 'package:nitya_aarti/services/gemini_panchang_service.dart';
import 'package:nitya_aarti/services/tithi_engine_service.dart';
import 'package:tithi_engine/tithi_engine.dart';

PanchangCity _city(String id) =>
    kPopularPanchangCities.firstWhere((c) => c.id == id);

void main() {
  final service = TithiEngineService();

  test('app cities resolve to Swiss-corrected engine cities', () {
    expect(service.engineCityName(_city('pune')), 'Pune');
    expect(service.engineCityName(_city('bengaluru')), 'Bangalore');
    expect(service.engineCityName(_city('ujjain')), 'Ujjain');
    expect(service.locationFor(_city('nashik')).source,
        LocationSource.cityCorrected);
  });

  test('uncatalogued coordinates fall back to Meeus astronomy', () {
    const remote = PanchangCity(
      id: 'test_village',
      nameMr: 'गाव',
      nameHi: 'गाँव',
      nameEn: 'Test Village',
      stateOrCountry: 'महाराष्ट्र',
      latitude: 20.4321,
      longitude: 76.1234,
    );
    expect(service.locationFor(remote).source, LocationSource.meeusRaw);
    final snap = service.day(DateTime(2026, 9, 15), remote);
    expect(snap.sunriseTithi.tithiNumber, inInclusiveRange(1, 30));
  });

  test('Maharashtra uses Amant months, Uttar Pradesh uses Purnimant', () {
    expect(service.monthSystemFor(_city('pune')), MonthSystem.amant);
    expect(service.monthSystemFor(_city('varanasi')), MonthSystem.purnimant);
  });

  test('Ganesh Chaturthi 2026 follows the madhyahna rule (14 Sep)', () {
    final fd = service
        .yearObservances(_city('pune'), 2026)
        .firstWhere((f) => f.id == 'ganesh_chaturthi');
    expect(fd.date, DateTime.utc(2026, 9, 14));
    expect(fd.muhurta, MuhurtaRule.madhyahna);
    expect(fd.muhurtaStart, isNotNull);
  });

  test('day snapshot is internally consistent', () {
    final snap = service.day(DateTime(2026, 9, 15), _city('pune'));
    expect(snap.sunriseTithi.tithiNumber, 4);
    expect(snap.sunriseTithi.month, LunarMonth.bhadrapada);
    expect(snap.sunriseSegment.tithi.tithiNumber, 4);
    expect(snap.sunriseSegment.endUtc.isAfter(snap.sunriseUtc), isTrue);
    expect(snap.sunsetUtc.isAfter(snap.sunriseUtc), isTrue);
    expect(snap.nextSegment?.tithi.tithiNumber, 5);
    expect(snap.sunriseKarana, isNotNull);
  });

  test('live tithi is only computed for the current day', () {
    final now = DateTime.utc(2026, 9, 15, 12);
    final today = service.day(DateTime(2026, 9, 15), _city('pune'), now: now);
    final other = service.day(DateTime(2026, 9, 20), _city('pune'), now: now);
    expect(today.currentTithi, isNotNull);
    expect(other.currentTithi, isNull);
  });

  test('upcoming observances are ordered and start from the given day', () {
    final list = service.upcoming(_city('pune'),
        from: DateTime(2026, 10, 30), count: 10);
    expect(list, hasLength(10));
    for (var i = 1; i < list.length; i++) {
      expect(list[i].date.isBefore(list[i - 1].date), isFalse);
    }
    expect(list.first.date.isBefore(DateTime.utc(2026, 10, 30)), isFalse);
  });

  test('tithi finder is adhika-aware', () {
    final jyeshtha = service.findTithiDates(
        _city('pune'), LunarMonth.jyeshtha, Tithi.shukla(11), 2026);
    expect(jyeshtha.regular, [DateTime.utc(2026, 6, 25)]);
    expect(jyeshtha.adhika, DateTime.utc(2026, 5, 27));

    final kartika = service.findTithiDates(
        _city('pune'), LunarMonth.kartika, Tithi.shukla(11), 2026);
    expect(kartika.regular, [DateTime.utc(2026, 11, 20)]);
    expect(kartika.adhika, isNull);
  });

  test('findNext returns the nearest occurrence', () {
    expect(
      service.findNext(_city('pune'), LunarMonth.kartika, Tithi.shukla(11),
          from: DateTime(2026, 10, 30)),
      DateTime.utc(2026, 11, 20),
    );
  });

  test('GeminiPanchangService fallback uses engine values', () async {
    final panchang = GeminiPanchangService(engine: service);
    final p = await panchang.getPanchang(
      date: DateTime(2026, 9, 14),
      city: _city('pune'),
      langCode: 'mr',
    );
    expect(p.tithi, 'तृतीया');
    expect(p.paksha, 'शुक्ल पक्ष');
    expect(p.maas, 'भाद्रपद');
    expect(p.tithiEndTime, contains('नंतर चतुर्थी'));
    // Backend/AI festival text is kept when present, so only the tithi is fixed.
    expect(p.festivalName, contains('चतुर्थी'));
    expect(p.shakaSamvat, '१९४८');
    expect(PanchangWindow.parse(p.rahuKaal), isNotNull);
    expect(PanchangWindow.parse(p.durmuhurat), isNotNull);

    final en = await panchang.getPanchang(
      date: DateTime(2026, 9, 14),
      city: _city('pune'),
      langCode: 'en',
    );
    expect(en.tithi, 'Tritiya');
    expect(en.sunrise, matches(RegExp(r'^\d{2}:\d{2} AM$')));
  });

  test('background preload matches the synchronous year scan', () async {
    final fresh = TithiEngineService();
    await fresh.preloadYear(_city('mumbai'), 2027);
    final preloaded = fresh.yearObservances(_city('mumbai'), 2027);
    final direct = TithiEngineService().yearObservances(_city('mumbai'), 2027);
    expect(preloaded.map((f) => '${f.id}@${f.date}'),
        direct.map((f) => '${f.id}@${f.date}'));
  });

  test('festival month is shown in the city month system', () {
    final diwali = service
        .yearObservances(_city('pune'), 2026)
        .firstWhere((f) => f.id == 'diwali');
    expect(service.displayInfo(diwali, MonthSystem.amant).month,
        LunarMonth.ashvina);
    expect(service.displayInfo(diwali, MonthSystem.purnimant).month,
        LunarMonth.kartika);
  });
}

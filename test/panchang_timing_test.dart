import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/domain/entities/panchang.dart';
import 'package:nitya_aarti/domain/logic/panchang_timing.dart';

PanchangData _panchang({String bhadra = 'नाही'}) => PanchangData(
      date: DateTime(2026, 9, 28),
      formattedDate: '',
      dayName: '',
      vikramSamvat: '',
      shakaSamvat: '',
      samvatsara: '',
      ayana: '',
      ritu: '',
      maas: '',
      paksha: '',
      tithi: '',
      tithiEndTime: '',
      vaar: '',
      vaarGraha: '',
      nakshatra: '',
      nakshatraEndTime: '',
      yoga: '',
      yogaEndTime: '',
      karana: '',
      karanaEndTime: '',
      sunrise: '',
      sunset: '',
      moonrise: '',
      moonset: '',
      suryaRashi: '',
      chandraRashi: '',
      brahmaMuhurat: '०४:३५ AM - ०५:२३ AM',
      amritKaal: '०६:१५ AM - ०७:४५ AM',
      abhijitMuhurat: '११:४८ AM - १२:३६ PM',
      vijayaMuhurat: '०२:१२ PM - ०३:०० PM',
      godhuliMuhurat: '०६:१० PM - ०६:३५ PM',
      rahuKaal: '१०:३० AM - १२:०० PM',
      yamaganda: '०३:०० PM - ०४:३० PM',
      gulikaKaal: '०७:३० AM - ०९:०० AM',
      durmuhurat: '०८:३५ AM - ०९:२४ AM',
      bhadra: bhadra,
      festivalName: '',
      vrat: '',
      festivalDescription: '',
      dailyMantra: '',
      specialGuidance: '',
    );

int _m(int h, int m) => h * 60 + m;

void main() {
  group('PanchangWindow.parse', () {
    test('reads Devanagari digits with AM/PM', () {
      final w = PanchangWindow.parse('११:४८ AM - १२:३६ PM')!;
      expect(w.start, _m(11, 48));
      expect(w.end, _m(12, 36));
    });

    test('reads ASCII digits, 12 AM and lowercase meridiem', () {
      final w = PanchangWindow.parse('12:15 am - 1:05 am')!;
      expect(w.start, _m(0, 15));
      expect(w.end, _m(1, 5));
    });

    test('reads 24-hour times and windows crossing midnight', () {
      final w = PanchangWindow.parse('23:30 - 00:45')!;
      expect(w.start, _m(23, 30));
      expect(w.end, _m(24, 45));
    });

    test('returns null for text that is not a range', () {
      expect(PanchangWindow.parse('नाही'), isNull);
      expect(PanchangWindow.parse('Till 12:30 PM'), isNull);
      expect(PanchangWindow.parse(''), isNull);
    });
  });

  group('panchangSlots', () {
    test('lists all windows in day order with untimed ones last', () {
      final slots = panchangSlots(_panchang());
      expect(slots.map((s) => s.kind), [
        PanchangSlotKind.brahma,
        PanchangSlotKind.amrit,
        PanchangSlotKind.gulika,
        PanchangSlotKind.durmuhurat,
        PanchangSlotKind.rahu,
        PanchangSlotKind.abhijit,
        PanchangSlotKind.vijaya,
        PanchangSlotKind.yamaganda,
        PanchangSlotKind.godhuli,
        PanchangSlotKind.bhadra,
      ]);
      expect(slots.last.raw, 'नाही');
    });

    test('splits a range into its displayed start and end', () {
      final abhijit = panchangSlots(_panchang())
          .firstWhere((s) => s.kind == PanchangSlotKind.abhijit);
      expect(abhijit.rangeParts, ('११:४८ AM', '१२:३६ PM'));
      expect(abhijit.isGood, isTrue);
    });
  });

  group('panchangNow', () {
    final slots = panchangSlots(_panchang());

    test('a bad window wins over an overlapping good one', () {
      final now = panchangNow(slots, _m(11, 50))!;
      expect(now.kind, PanchangNowKind.avoid);
      expect(now.slot.kind, PanchangSlotKind.rahu);
    });

    test('reports an ongoing good window', () {
      final now = panchangNow(slots, _m(12, 10))!;
      expect(now.kind, PanchangNowKind.good);
      expect(now.slot.kind, PanchangSlotKind.abhijit);
    });

    test('otherwise points to the next good window', () {
      final now = panchangNow(slots, _m(13, 0))!;
      expect(now.kind, PanchangNowKind.nextGood);
      expect(now.slot.kind, PanchangSlotKind.vijaya);
    });

    test('is null once every good window has passed', () {
      expect(panchangNow(slots, _m(22, 0)), isNull);
    });
  });
}

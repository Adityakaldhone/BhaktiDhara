import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/services/kundali/guna_milan.dart';
import 'package:nitya_aarti/services/kundali/vedic_astro_engine.dart';

KundaliData _chart({required double moon, double lagna = 0, double mars = 300}) => KundaliData(
      birthUtc: DateTime.utc(2000),
      ayanamsa: 23.85,
      lagnaLongitude: lagna,
      grahas: [
        for (final g in Graha.values)
          GrahaPosition(
            graha: g,
            longitude: switch (g) {
              Graha.moon => moon,
              Graha.mars => mars,
              _ => 0,
            },
            isRetrograde: false,
          ),
      ],
    );

Map<Koota, double> _scores(MilanResult r) => {for (final k in r.kootas) k.koota: k.score};

void main() {
  test('same nakshatra and pada: 28 gunas with uncancelled Nadi dosha', () {
    final r = GunaMilan.match(boy: _chart(moon: 45), girl: _chart(moon: 45));
    expect(r.total, 28);
    expect(r.nadiDosha, isTrue);
    expect(r.nadiCancelled, isFalse);
    expect(r.verdict, MilanVerdict.good);
  });

  test('same nakshatra, different pada cancels Nadi dosha', () {
    final r = GunaMilan.match(boy: _chart(moon: 45), girl: _chart(moon: 50));
    expect(r.nadiDosha, isTrue);
    expect(r.nadiCancelled, isTrue);
  });

  test('Ashwini groom with Bharani bride scores 34', () {
    final r = GunaMilan.match(boy: _chart(moon: 5), girl: _chart(moon: 15));
    expect(_scores(r), {
      Koota.varna: 1,
      Koota.vashya: 2,
      Koota.tara: 3,
      Koota.yoni: 2,
      Koota.maitri: 5,
      Koota.gana: 6,
      Koota.bhakoot: 7,
      Koota.nadi: 8,
    });
    expect(r.total, 34);
    expect(r.verdict, MilanVerdict.excellent);
  });

  test('Mesha–Kanya (6-8) gives Bhakoot and Nadi dosha', () {
    final r = GunaMilan.match(boy: _chart(moon: 10), girl: _chart(moon: 160));
    expect(_scores(r), {
      Koota.varna: 1,
      Koota.vashya: 1,
      Koota.tara: 1.5,
      Koota.yoni: 0,
      Koota.maitri: 0.5,
      Koota.gana: 6,
      Koota.bhakoot: 0,
      Koota.nadi: 0,
    });
    expect(r.total, 10);
    expect(r.bhakootDosha && !r.bhakootCancelled, isTrue);
    expect(r.verdict, MilanVerdict.notRecommended);
  });

  test('Bhakoot dosha is cancelled when both rashis share a lord', () {
    // Mesha and Vrishchika are 6-8 apart and both ruled by Mars.
    final r = GunaMilan.match(boy: _chart(moon: 10), girl: _chart(moon: 220));
    expect(r.bhakootDosha, isTrue);
    expect(r.bhakootCancelled, isTrue);
  });

  test('Manglik from Lagna and from Moon', () {
    final m = ManglikStatus.of(_chart(lagna: 0, moon: 200, mars: 100));
    expect(m.houseFromLagna, 4);
    expect(m.houseFromMoon, 10);
    expect(m.fromLagna, isTrue);
    expect(m.fromMoon, isFalse);

    final none = ManglikStatus.of(_chart(lagna: 0, moon: 0, mars: 70));
    expect(none.isManglik, isFalse);
  });

  test('tables are consistent and totals stay within 0–36', () {
    expect(GunaMilan.nadiOf(0), 0);
    expect(GunaMilan.nadiOf(13), 1); // Chitra – Madhya
    expect(GunaMilan.nadiOf(26), 2); // Revati – Antya
    expect(GunaMilan.ganaOf(8), 2); // Ashlesha – Rakshasa
    expect(GunaMilan.yoniOf(26), 1); // Revati – Elephant

    final rnd = Random(7);
    for (var i = 0; i < 2000; i++) {
      final a = _chart(moon: rnd.nextDouble() * 360);
      final b = _chart(moon: rnd.nextDouble() * 360);
      final r = GunaMilan.match(boy: a, girl: b);
      expect(r.total, inInclusiveRange(0, 36));
      for (final k in r.kootas) {
        expect(k.score, inInclusiveRange(0, k.max));
      }
      // Yoni and Graha Maitri do not depend on who is the groom.
      final swapped = GunaMilan.match(boy: b, girl: a);
      expect(swapped[Koota.yoni].score, r[Koota.yoni].score);
      expect(swapped[Koota.maitri].score, r[Koota.maitri].score);
    }
  });
}

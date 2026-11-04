import 'vedic_astro_engine.dart';

/// The eight Ashtakoota kootas. A koota's maximum gunas equal `index + 1`.
enum Koota { varna, vashya, tara, yoni, maitri, gana, bhakoot, nadi }

enum MilanVerdict { notRecommended, average, good, excellent }

class KootaResult {
  const KootaResult(this.koota, this.score, this.boy, this.girl);

  final Koota koota;
  final double score;

  /// Category index of each partner for this koota: varna, vashya group, tara
  /// (1–9), yoni animal, rashi lord ([Graha] index), gana, rashi or nadi.
  final int boy;
  final int girl;

  int get max => koota.index + 1;
}

/// Mars placement for Mangal dosha, counted as whole-sign houses.
class ManglikStatus {
  const ManglikStatus({required this.houseFromLagna, required this.houseFromMoon});

  factory ManglikStatus.of(KundaliData k) {
    final mars = k.grahas[Graha.mars.index].rashi;
    return ManglikStatus(
      houseFromLagna: (mars - k.lagnaRashi + 12) % 12 + 1,
      houseFromMoon: (mars - k.moon.rashi + 12) % 12 + 1,
    );
  }

  static const _doshaHouses = {1, 2, 4, 7, 8, 12};

  final int houseFromLagna;
  final int houseFromMoon;

  bool get fromLagna => _doshaHouses.contains(houseFromLagna);
  bool get fromMoon => _doshaHouses.contains(houseFromMoon);
  bool get isManglik => fromLagna || fromMoon;
}

class MilanResult {
  const MilanResult({
    required this.kootas,
    required this.boyManglik,
    required this.girlManglik,
    required this.nadiCancelled,
    required this.bhakootCancelled,
  });

  final List<KootaResult> kootas;
  final ManglikStatus boyManglik;
  final ManglikStatus girlManglik;

  /// Traditional exceptions (parihar) that neutralise a zero-scoring koota.
  final bool nadiCancelled;
  final bool bhakootCancelled;

  double get total => kootas.fold(0.0, (sum, k) => sum + k.score);
  KootaResult operator [](Koota k) => kootas[k.index];

  bool get nadiDosha => this[Koota.nadi].score == 0;
  bool get bhakootDosha => this[Koota.bhakoot].score == 0;
  bool get manglikMatch => boyManglik.isManglik == girlManglik.isManglik;

  MilanVerdict get verdict {
    final t = total;
    if (t < 18) return MilanVerdict.notRecommended;
    if (t <= 24) return MilanVerdict.average;
    if (t <= 32) return MilanVerdict.good;
    return MilanVerdict.excellent;
  }
}

/// Ashtakoota (North Indian) guna milan from the Moon's rashi and nakshatra.
class GunaMilan {
  const GunaMilan._();

  static MilanResult match({required KundaliData boy, required KundaliData girl}) {
    final bm = boy.moon, gm = girl.moon;
    final bRashi = bm.rashi, gRashi = gm.rashi;
    final bNak = bm.nakshatra, gNak = gm.nakshatra;

    final bVarna = _varna[bRashi], gVarna = _varna[gRashi];

    final bVashya = vashyaOf(bm.longitude), gVashya = vashyaOf(gm.longitude);

    final bTara = taraFrom(gNak, bNak), gTara = taraFrom(bNak, gNak);
    final goodTaras = [bTara, gTara].where((t) => !_badTaras.contains(t)).length;

    final bYoni = yoniOf(bNak), gYoni = yoniOf(gNak);

    final bLord = _rashiLord[bRashi], gLord = _rashiLord[gRashi];

    final bGana = ganaOf(bNak), gGana = ganaOf(gNak);

    final bNadi = nadiOf(bNak), gNadi = nadiOf(gNak);

    final kootas = [
      KootaResult(Koota.varna, bVarna <= gVarna ? 1 : 0, bVarna, gVarna),
      KootaResult(Koota.vashya, _vashyaScore[bVashya][gVashya], bVashya, gVashya),
      KootaResult(Koota.tara, goodTaras * 1.5, bTara, gTara),
      KootaResult(Koota.yoni, _yoniScore[bYoni][gYoni].toDouble(), bYoni, gYoni),
      KootaResult(Koota.maitri, maitriScore(bLord, gLord), bLord.index, gLord.index),
      KootaResult(Koota.gana, _ganaScore[bGana][gGana].toDouble(), bGana, gGana),
      KootaResult(Koota.bhakoot, bhakootScore(bRashi, gRashi), bRashi, gRashi),
      KootaResult(Koota.nadi, bNadi == gNadi ? 0 : 8, bNadi, gNadi),
    ];

    return MilanResult(
      kootas: kootas,
      boyManglik: ManglikStatus.of(boy),
      girlManglik: ManglikStatus.of(girl),
      nadiCancelled: bNadi == gNadi &&
          ((bRashi == gRashi && bNak != gNak) || (bNak == gNak && bm.pada != gm.pada)),
      bhakootCancelled: bhakootScore(bRashi, gRashi) == 0 &&
          (bLord == gLord ||
              (_friendship(bLord, gLord) == 2 && _friendship(gLord, bLord) == 2)),
    );
  }

  /// 0 Chatushpada, 1 Manava, 2 Jalachara, 3 Vanachara, 4 Keeta.
  static int vashyaOf(double moonLon) {
    final rashi = moonLon ~/ 30;
    final firstHalf = moonLon % 30 < 15;
    return switch (rashi) {
      0 || 1 => 0,
      2 || 5 || 6 || 10 => 1,
      3 || 11 => 2,
      4 => 3,
      7 => 4,
      8 => firstHalf ? 1 : 0,
      _ => firstHalf ? 0 : 2, // Makara
    };
  }

  /// Tara (1–9) of nakshatra [to] counted from nakshatra [from].
  static int taraFrom(int from, int to) => (to - from + 27) % 27 % 9 + 1;

  static int yoniOf(int nakshatra) => _yoni[nakshatra % 27];

  /// 0 Deva, 1 Manushya, 2 Rakshasa.
  static int ganaOf(int nakshatra) => _gana[nakshatra % 27];

  /// 0 Aadi, 1 Madhya, 2 Antya — the zig-zag pattern over each six nakshatras.
  static int nadiOf(int nakshatra) => const [0, 1, 2, 2, 1, 0][nakshatra % 6];

  static double maitriScore(Graha a, Graha b) {
    if (a == b) return 5;
    final x = _friendship(a, b), y = _friendship(b, a);
    final hi = x > y ? x : y, lo = x > y ? y : x;
    return switch ((hi, lo)) {
      (2, 2) => 5,
      (2, 1) => 4,
      (1, 1) => 3,
      (2, 0) => 1,
      (1, 0) => 0.5,
      _ => 0,
    };
  }

  static double bhakootScore(int boyRashi, int girlRashi) {
    final n = (boyRashi - girlRashi + 12) % 12 + 1;
    return const {2, 12, 5, 9, 6, 8}.contains(n) ? 0 : 7;
  }

  /// Naisargika relationship of [a] towards [b]: 2 friend, 1 neutral, 0 enemy.
  static int _friendship(Graha a, Graha b) => _friends[a.index][b.index];
}

const _badTaras = {3, 5, 7};

// Mesha … Meena → 0 Brahmin, 1 Kshatriya, 2 Vaishya, 3 Shudra.
const _varna = [1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0];

const _rashiLord = [
  Graha.mars, Graha.venus, Graha.mercury, Graha.moon, Graha.sun, Graha.mercury,
  Graha.venus, Graha.mars, Graha.jupiter, Graha.saturn, Graha.saturn, Graha.jupiter,
];

// Rows / columns: Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn.
const _friends = [
  [2, 2, 2, 1, 2, 0, 0],
  [2, 2, 1, 2, 1, 1, 1],
  [2, 2, 2, 0, 2, 1, 1],
  [2, 0, 1, 2, 1, 2, 1],
  [2, 2, 2, 0, 2, 0, 1],
  [0, 0, 1, 2, 1, 2, 2],
  [0, 0, 0, 2, 1, 2, 2],
];

// Boy (rows) × girl (columns) in vashya group order.
const _vashyaScore = [
  [2.0, 1.0, 1.0, 0.5, 1.0],
  [1.0, 2.0, 0.5, 0.0, 1.0],
  [1.0, 0.5, 2.0, 1.0, 1.0],
  [0.5, 0.0, 1.0, 2.0, 0.0],
  [1.0, 1.0, 1.0, 0.0, 2.0],
];

// Animal per nakshatra: 0 Horse, 1 Elephant, 2 Sheep, 3 Serpent, 4 Dog, 5 Cat,
// 6 Rat, 7 Cow, 8 Buffalo, 9 Tiger, 10 Deer, 11 Monkey, 12 Mongoose, 13 Lion.
const _yoni = [
  0, 1, 2, 3, 3, 4, 5, 2, 5, 6, 6, 7, 8, 9,
  8, 9, 10, 10, 4, 11, 12, 11, 13, 0, 13, 7, 1,
];

const _yoniScore = [
  [4, 2, 2, 3, 2, 2, 2, 1, 0, 1, 3, 3, 2, 1],
  [2, 4, 3, 3, 2, 2, 2, 2, 3, 1, 2, 3, 2, 0],
  [2, 3, 4, 2, 1, 2, 1, 3, 3, 1, 2, 0, 3, 1],
  [3, 3, 2, 4, 2, 1, 1, 1, 1, 2, 2, 2, 0, 2],
  [2, 2, 1, 2, 4, 2, 1, 2, 2, 1, 0, 2, 1, 1],
  [2, 2, 2, 1, 2, 4, 0, 2, 2, 1, 3, 3, 2, 1],
  [2, 2, 1, 1, 1, 0, 4, 2, 2, 2, 2, 2, 1, 2],
  [1, 2, 3, 1, 2, 2, 2, 4, 3, 0, 3, 2, 2, 1],
  [0, 3, 3, 1, 2, 2, 2, 3, 4, 1, 2, 2, 2, 1],
  [1, 1, 1, 2, 1, 1, 2, 0, 1, 4, 1, 1, 2, 1],
  [3, 2, 2, 2, 0, 3, 2, 3, 2, 1, 4, 2, 2, 1],
  [3, 3, 0, 2, 2, 3, 2, 2, 2, 1, 2, 4, 3, 2],
  [2, 2, 3, 0, 1, 2, 1, 2, 2, 2, 2, 3, 4, 2],
  [1, 0, 1, 2, 1, 1, 2, 1, 1, 1, 1, 2, 2, 4],
];

const _gana = [
  0, 1, 2, 1, 0, 1, 0, 0, 2, 2, 1, 1, 0, 2,
  0, 2, 0, 2, 2, 1, 1, 0, 2, 2, 1, 1, 0,
];

// Boy (rows) × girl (columns): Deva, Manushya, Rakshasa.
const _ganaScore = [
  [6, 6, 0],
  [5, 6, 0],
  [1, 0, 6],
];

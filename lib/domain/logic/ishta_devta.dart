import '../../data/datasources/bhakti_deity_catalog.dart';
import '../entities/aarti_item.dart';
import '../entities/bhakti_deity.dart';
import '../entities/lyric_stanza.dart';

/// SharedPreferences key holding the chosen [BhaktiDeity.key].
const kIshtaPrefsKey = 'ishta_devta_key';

/// Most-chosen deities, shown first on the Ishta Devta picker; every other
/// deity follows in catalog order.
const kIshtaDeityKeys = [
  'Lord Ganesha',
  'Goddess Tuljabhavani',
  'Khatu Shyam',
  'Radha',
  'Banke Bihari',
  'Lord Shiva',
  'Lord Hanuman',
  'Lord Vitthal',
  'Lord Jyotiba',
  'Lord Bhairavnath',
  'Goddess Durga',
  'Lord Krishna',
  'Lord Rama',
  'Sai Baba',
  'Goddess Lakshmi',
  'Swami Samarth',
  'Lord Datta',
];

List<BhaktiDeity> ishtaDeities() => [
      for (final key in kIshtaDeityKeys)
        ...kBhaktiDeities.where((d) => d.key == key),
      ...kBhaktiDeities.where((d) => !kIshtaDeityKeys.contains(d.key)),
    ];

/// The deity saved as Ishta Devta, or Shri Ganesh when none was picked.
BhaktiDeity ishtaOrDefault(String? key) => kBhaktiDeities.firstWhere(
      (d) => d.key == key,
      orElse: () => kBhaktiDeities.firstWhere((d) => d.key == kIshtaDeityKeys.first),
    );

/// The aarti opened for [deity] after it is picked: its first item tagged
/// Aarti, otherwise its first item of any kind.
AartiItem? mainAartiFor(BhaktiDeity deity, List<AartiItem> catalog) {
  final items = catalog.where((i) => deity.matches(i.deity)).toList();
  if (items.isEmpty) return null;
  return items.firstWhere(
    (i) => i.tags.any((t) => t.toLowerCase() == 'aarti'),
    orElse: () => items.first,
  );
}

/// Fallback invocation aarti ensuring NO deity is ever hidden from the devotee.
AartiItem fallbackAartiFor(BhaktiDeity deity) {
  final slug = deity.key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return AartiItem(
    id: 'smaran_$slug',
    title: '${deity.nameEn} Nitya Smaran',
    titleHi: '${deity.nameHi} नित्य स्मरण व आरती',
    titleMr: '${deity.nameMr} नित्य स्मरण व आरती',
    deity: deity.key,
    deityHi: deity.nameHi,
    deityMr: deity.nameMr,
    singer: 'Traditional',
    tags: const ['Aarti', 'Mantra', 'Smaran'],
    youtubeVideoId: 'AETFvQonfV8',
    durationText: '3:30',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    about: 'Sacred daily remembrance and aarti of ${deity.nameEn}.',
    aboutHi: '${deity.nameHi} का नित्य मंगल स्मरण, ध्यान एवं पावन आरती।',
    aboutMr: '${deity.nameMr} यांचे नित्य मंगल स्मरण, ध्यान व पावन आरती.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'ॐ सर्वमंगलमांगल्ये शिवे सर्वार्थसाधिके ।\nशरण्ये त्र्यम्बके गौरि नारायणि नमोऽस्तु ते ॥\n\nकर्पूरगौरं करुणावतारं संसारसारं भुजगेन्द्रहारम् ।\nसदावसन्तं हृदयारविन्दे भवं भवानीसहितं नमामि ॥',
        transliteration: 'Om Sarva mangala mangalye shive sarvartha sadhike,\nSharanye tryambake gauri narayani namostu te.\n\nKarpuragauram karunavataram sansarasaram bhujagendraharam,\nSada vasantam hridayaravinde bhavam bhavanisahitam namami.',
      ),
    ],
  );
}

/// Guarantees an aarti is always available so the deity is NEVER hidden.
AartiItem safeMainAartiFor(BhaktiDeity deity, List<AartiItem> catalog) {
  return mainAartiFor(deity, catalog) ?? fallbackAartiFor(deity);
}

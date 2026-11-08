import '../../domain/entities/aarti_item.dart';
import '../../domain/entities/lyric_stanza.dart';
import 'catalog.dart';

/// Aartis, chalisas, mantras and stotras for the Uttarakhand Char Dham, temple
/// and folk deities (Kedarnath, Badrinath, Golu Devta, ...) shown in the
/// Bhakti darshan and Sacred Collection.
final List<AartiItem> kUttarakhandDeitiesCatalog = [
  for (final row in _rows) _buildItem(row),
];

AartiItem _buildItem(_UkRow row) {
  final deity = _deities[row.deity]!;
  final slug = row.deity.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  final videoSlug = row.videoId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
  return AartiItem(
    id: 'uk_${slug}_$videoSlug',
    title: row.title,
    titleHi: row.titleHi,
    titleMr: row.titleHi,
    deity: row.deity,
    deityHi: deity.nameHi,
    deityMr: deity.nameMr,
    singer: row.singer,
    tags: row.tags,
    youtubeVideoId: row.videoId,
    durationText: '5:00',
    accentColorHex: deity.accentColorHex,
    deityEmoji: deity.emoji,
    about: '${row.title} — devotion to ${deity.nameEn}.',
    aboutHi: '${row.titleHi} — ${deity.nameHi} की भक्ति।',
    aboutMr: '${row.titleHi} — ${deity.nameMr} यांची भक्ती.',
    lyrics: row.lyricsFromId != null
        ? kDevotionalCatalog.firstWhere((i) => i.id == row.lyricsFromId).lyrics
        : [
            LyricStanza(
              startTimeMs: 0,
              devanagari: row.devanagari,
              transliteration: row.transliteration,
            ),
          ],
  );
}

class _UkDeity {
  final String nameEn;
  final String nameHi;
  final String nameMr;
  final String accentColorHex;
  final String emoji;

  const _UkDeity(this.nameEn, this.nameHi, this.nameMr, this.accentColorHex, this.emoji);
}

class _UkRow {
  final String deity;
  final List<String> tags;
  final String title;
  final String titleHi;
  final String videoId;
  final String singer;

  /// Reuse the lyrics of an existing catalog item with this id.
  final String? lyricsFromId;
  final String devanagari;
  final String transliteration;

  const _UkRow(
    this.deity,
    this.tags,
    this.title,
    this.titleHi,
    this.videoId,
    this.singer, {
    this.lyricsFromId,
    this.devanagari = '',
    this.transliteration = '',
  });
}

const _shiv = '#1565C0';
const _vishnu = '#0D47A1';
const _mata = '#C62828';
const _lokdev = '#AD1457';

const Map<String, _UkDeity> _deities = {
  'Kedarnath': _UkDeity('Kedarnath', 'श्री केदारनाथ', 'श्री केदारनाथ', _shiv, '🔱'),
  'Badrinath': _UkDeity('Badrinath', 'श्री बद्रीनाथ', 'श्री बद्रीनाथ', _vishnu, '🪷'),
  'Gangotri': _UkDeity('Gangotri', 'गंगोत्री (माँ गंगा)', 'गंगोत्री (गंगा माता)', '#0277BD', '🌊'),
  'Yamunotri': _UkDeity('Yamunotri', 'यमुनोत्री (माँ यमुना)', 'यमुनोत्री (यमुना माता)', '#283593', '🌊'),
  'Jageshwar Mahadev': _UkDeity('Jageshwar Mahadev', 'जागेश्वर महादेव', 'जागेश्वर महादेव', _shiv, '🔱'),
  'Neelkanth Mahadev': _UkDeity('Neelkanth Mahadev', 'नीलकंठ महादेव', 'नीलकंठ महादेव', _shiv, '🔱'),
  'Baleshwar Mahadev': _UkDeity('Baleshwar Mahadev', 'बालेश्वर महादेव', 'बालेश्वर महादेव', _shiv, '🔱'),
  'Kartik Swami': _UkDeity('Kartik Swami', 'कार्तिक स्वामी', 'कार्तिक स्वामी', '#E65100', '🦚'),
  'Narsingh Devta': _UkDeity('Narsingh Devta', 'नरसिंह देवता', 'नरसिंह देवता', _vishnu, '🦁'),
  'Nanda Devi': _UkDeity('Nanda Devi', 'माँ नंदा देवी', 'नंदा देवी', _mata, '🏔️'),
  'Surkanda Devi': _UkDeity('Surkanda Devi', 'माँ सुरकंडा देवी', 'सुरकंडा देवी', _mata, '🌺'),
  'Dhari Devi': _UkDeity('Dhari Devi', 'माँ धारी देवी', 'धारी देवी', _mata, '🌺'),
  'Chandrabadni Devi': _UkDeity('Chandrabadni Devi', 'माँ चंद्रबदनी', 'चंद्रबदनी देवी', _mata, '🌺'),
  'Golu Devta': _UkDeity('Golu Devta', 'गोलू देवता', 'गोलू देवता', _lokdev, '🔔'),
  'Mahasu Devta': _UkDeity('Mahasu Devta', 'महासू देवता', 'महासू देवता', _lokdev, '⚔️'),
};

const _aarti = ['Aarti'];
const _chalisa = ['Chalisa'];
const _mantra = ['Mantra'];
const _stotra = ['Stotra'];
const _stuti = ['Stuti', 'Stotra'];

const _shivAarti = 'Om Jai Shiv Omkara (Shiv Aarti)';
const _shivAartiHi = 'ॐ जय शिव ओंकारा (शिव आरती)';
const _shivChalisa = 'Shri Shiv Chalisa (Jai Girijapati Deen Dayala)';
const _shivChalisaHi = 'श्री शिव चालीसा (जय गिरिजापति दीन दयाला)';
const _jyotirlinga = 'Dvadasha Jyotirlinga Stotram';
const _jyotirlingaHi = 'द्वादश ज्योतिर्लिंग स्तोत्रम्';

const List<_UkRow> _rows = [
  // ── Kedarnath ───────────────────────────────────────────────────────────
  _UkRow('Kedarnath', _aarti, 'Shri Kedarnath Aarti (Jai Kedar Udar Shankar)', 'श्री केदारनाथ आरती (जय केदार उदार शंकर)', 'L-t1V35G-HY', 'Shemaroo Bhakti'),
  _UkRow('Kedarnath', _stotra, 'Shri Kedarnath Suprabhatam', 'श्री केदारनाथ सुप्रभातम्', 'SY8LfusHEwc', 'Pt. Mritunjay Hiremath'),
  _UkRow('Kedarnath', _stotra, _jyotirlinga, _jyotirlingaHi, 'QgkBIoUeAa0', 'Pt. Mritunjay Hiremath'),
  _UkRow('Kedarnath', _aarti, _shivAarti, _shivAartiHi, 'BhwOproElxU', 'Anuradha Paudwal', lyricsFromId: 'shiv_aarti'),
  _UkRow('Kedarnath', _chalisa, _shivChalisa, _shivChalisaHi, 'DhTsvZavDNM', 'Suresh Wadkar'),

  // ── Badrinath ───────────────────────────────────────────────────────────
  _UkRow('Badrinath', _aarti, 'Shri Badrinath Aarti (Pawan Mand Sugandh Sheetal)', 'श्री बद्रीनाथ आरती (पवन मंद सुगंध शीतल)', '-UEgquPjKlI', 'Anuradha Paudwal'),
  _UkRow('Badrinath', _stotra, 'Shri Badrinath Ashtakam', 'श्री बद्रीनाथ अष्टकम्', '8vnaZ3wskBo', 'Rajshri Soul'),
  _UkRow('Badrinath', _stotra, 'Shri Badrinarayan Stotram (Shridhar Swami)', 'श्री बद्रीनारायण स्तोत्रम् (श्रीधर स्वामी)', 'DXix2UR7tN0', 'Prakash Ketkar'),
  _UkRow('Badrinath', _mantra, 'Om Namo Narayanaya (108 Times)', 'ॐ नमो नारायणाय (108 बार)', 'Tvy4Wt7zsNg', 'Quiet Space',
      devanagari: 'ॐ नमो नारायणाय।', transliteration: 'Om Namo Narayanaya.'),

  // ── Gangotri (Ganga) ────────────────────────────────────────────────────
  _UkRow('Gangotri', _aarti, 'Ganga Aarti (Om Jai Gange Mata)', 'गंगा आरती (ॐ जय गंगे माता)', 'Y5kIExTTtvY', 'Anuradha Paudwal',
      lyricsFromId: 'ganga_jai_gange_mata_aarti'),
  _UkRow('Gangotri', _chalisa, 'Shri Ganga Chalisa', 'श्री गंगा चालीसा', 'zePrQdOZdus', 'Anuradha Paudwal'),
  _UkRow('Gangotri', _stotra, 'Ganga Stotram (Devi Sureshvari Bhagavati Gange)', 'श्री गंगा स्तोत्रम् (देवि सुरेश्वरि भगवति गंगे)', 'wvw6pBcviLo', 'Shemaroo Bhakti'),
  _UkRow('Gangotri', _stotra, 'Gangashtakam (Adi Shankaracharya)', 'गंगाष्टकम् (आदि शंकराचार्य)', '5Z7sZ0riNrI', 'Mantra Sagaraa'),
  _UkRow('Gangotri', _stotra, 'Gangashtakam (Valmiki)', 'गंगाष्टकम् (वाल्मीकि)', 'Gcf2EmWWML0', 'Anuradha Paudwal & Pt. Sanjeev Abhyankar'),
  _UkRow('Gangotri', _stotra, 'Ganga Lahari (Panditaraja Jagannatha)', 'गंगा लहरी (पण्डितराज जगन्नाथ)', 'yY13vYa5_cM', 'Swami Govindadev Giri'),

  // ── Yamunotri (Yamuna) ──────────────────────────────────────────────────
  _UkRow('Yamunotri', _aarti, 'Yamuna Aarti (Om Jai Yamuna Mata)', 'यमुना आरती (ॐ जय यमुना माता)', 'T9qBYe0kF9k', 'T-Series Bhakti Sagar'),
  _UkRow('Yamunotri', _chalisa, 'Shri Yamuna Chalisa', 'श्री यमुना चालीसा', 'Qi23pxtWc1A', 'Raftaar News'),
  _UkRow('Yamunotri', _stotra, 'Yamunashtakam (Vallabhacharya)', 'यमुनाष्टकम् (वल्लभाचार्य)', 'X5JXjHFTBcY', 'NakshatraPedia'),

  // ── Jageshwar Mahadev ───────────────────────────────────────────────────
  _UkRow('Jageshwar Mahadev', _aarti, 'Aarti Jageshwar Ji Ki', 'आरती जागेश्वर जी की', 'spDb9eUVgZk', 'Beauty of Jageshwar Dham'),
  _UkRow('Jageshwar Mahadev', _stotra, _jyotirlinga, _jyotirlingaHi, 'QgkBIoUeAa0', 'Pt. Mritunjay Hiremath'),
  _UkRow('Jageshwar Mahadev', _aarti, _shivAarti, _shivAartiHi, 'BhwOproElxU', 'Anuradha Paudwal', lyricsFromId: 'shiv_aarti'),
  _UkRow('Jageshwar Mahadev', _chalisa, _shivChalisa, _shivChalisaHi, 'DhTsvZavDNM', 'Suresh Wadkar'),

  // ── Neelkanth Mahadev ───────────────────────────────────────────────────
  _UkRow('Neelkanth Mahadev', _stotra, 'Parvati Vallabha Ashtakam (Bhaje Parvati Vallabham Neelkantham)', 'पार्वतीवल्लभ अष्टकम् (भजे पार्वतीवल्लभं नीलकण्ठम्)', 'ehd2G7x3EwU', 'Madhvi Madhukar'),
  _UkRow('Neelkanth Mahadev', _stotra, 'Neelkanth Ashtakam (Namo Namah Shivaya)', 'नीलकण्ठ अष्टकम् (नमो नमः शिवाय)', '2qxZxnDurvU', 'Nothing but Shiva'),
  _UkRow('Neelkanth Mahadev', _stotra, 'Shri Neelkanth Stotram', 'श्री नीलकण्ठ स्तोत्रम्', 'UmXgRnrsuR8', 'Mantra Tantra Yantra'),
  _UkRow('Neelkanth Mahadev', _aarti, _shivAarti, _shivAartiHi, 'BhwOproElxU', 'Anuradha Paudwal', lyricsFromId: 'shiv_aarti'),
  _UkRow('Neelkanth Mahadev', _chalisa, _shivChalisa, _shivChalisaHi, 'DhTsvZavDNM', 'Suresh Wadkar'),

  // ── Baleshwar Mahadev ───────────────────────────────────────────────────
  _UkRow('Baleshwar Mahadev', _aarti, _shivAarti, _shivAartiHi, 'BhwOproElxU', 'Anuradha Paudwal', lyricsFromId: 'shiv_aarti'),
  _UkRow('Baleshwar Mahadev', _chalisa, _shivChalisa, _shivChalisaHi, 'DhTsvZavDNM', 'Suresh Wadkar'),

  // ── Kartik Swami ────────────────────────────────────────────────────────
  _UkRow('Kartik Swami', _stotra, 'Shri Subrahmanya Bhujangam', 'श्री सुब्रह्मण्य भुजङ्गम्', 'iBmCao3u3ho', 'Sringeri Sharada Peetham'),
  _UkRow('Kartik Swami', _stotra, 'Pradnya Vivardhan Kartikeya Stotram', 'प्रज्ञाविवर्धन कार्तिकेय स्तोत्रम्', 'dkVnDPJiUi4', 'Bhakti Mantras India'),
  _UkRow('Kartik Swami', _stotra, 'Skanda Shashti Kavacham', 'स्कन्द षष्ठि कवचम्', 'ElVaIJJmpBk', 'K. S. Chithra'),

  // ── Narsingh Devta ──────────────────────────────────────────────────────
  _UkRow('Narsingh Devta', _aarti, 'Om Jai Narsingh Hare (Narsingh Aarti)', 'ॐ जय नरसिंह हरे (नरसिंह आरती)', '2TWYZumGZcA', 'Tilak'),
  _UkRow('Narsingh Devta', _chalisa, 'Shri Narsingh Chalisa', 'श्री नरसिंह चालीसा', 'NOZtCz1kaUI', 'Anuradha Paudwal'),
  _UkRow('Narsingh Devta', _stotra, 'Narasimha Kavacham', 'नरसिंह कवचम्', 'aai1k4SX_uk', 'ISKCON Bangalore'),
  _UkRow('Narsingh Devta', _stotra, 'Lakshmi Narasimha Karavalamba Stotram', 'लक्ष्मी नृसिंह करावलम्ब स्तोत्रम्', 'M7oL2YrT7YI', 'T. S. Ranganathan'),
  _UkRow('Narsingh Devta', _mantra, 'Narasimha Mantraraja (Ugram Viram)', 'नृसिंह मन्त्रराज (उग्रं वीरं)', 'DWyDQQbhHPo', 'ISKCON Bangalore',
      devanagari: 'उग्रं वीरं महाविष्णुं ज्वलन्तं सर्वतोमुखम्।\nनृसिंहं भीषणं भद्रं मृत्युमृत्युं नमाम्यहम्॥',
      transliteration: 'Ugram Viram Mahavishnum Jvalantam Sarvatomukham,\nNrisimham Bhishanam Bhadram Mrityumrityum Namamyaham.'),

  // ── Nanda Devi ──────────────────────────────────────────────────────────
  _UkRow('Nanda Devi', _stuti, 'Maa Nanda Stuti (Ayi Shive Bhave Shankara Priye)', 'माँ नंदा स्तुति (अयि शिवे भवे शंकर प्रिये)', 'WCiOeXl8ViY', 'Shail Dhwani'),

  // ── Surkanda Devi ───────────────────────────────────────────────────────
  _UkRow('Surkanda Devi', _stuti, 'Bhagwati Surkanda Stuti', 'भगवती सुरकंडा स्तुति', 'vWKD3Q3LxsA', 'Acharya Praveen Uniyal'),

  // ── Dhari Devi ──────────────────────────────────────────────────────────
  _UkRow('Dhari Devi', _aarti, 'Om Jai Dhari Mata (Dhari Mata Ki Aarti)', 'ॐ जय धारी माता (धारी माता की आरती)', 'BKvvvfa_6CU', 'Sant Vani'),
  _UkRow('Dhari Devi', _chalisa, 'Dhari Devi Chalisa', 'धारी देवी चालीसा', '7fmJvyy97U8', 'Rishi Arts'),

  // ── Chandrabadni Devi ───────────────────────────────────────────────────
  _UkRow('Chandrabadni Devi', _stuti, 'Maa Chandrabadni Stuti (Acharya Praveen Uniyal)', 'माँ चंद्रबदनी स्तुति (आचार्य प्रवीण उनियाल)', 'feQNPvfl3-o', 'Acharya Praveen Uniyal'),
  _UkRow('Chandrabadni Devi', _stuti, 'Maa Chandrabadni Stuti (Bharat Sagar)', 'माँ चंद्रबदनी स्तुति (भरत सागर)', 'oWxFP84shAs', 'Bharat Sagar'),

  // ── Golu Devta ──────────────────────────────────────────────────────────
  _UkRow('Golu Devta', _aarti, 'Shri Golu Devta Ki Aarti (Jai Gwal Dev)', 'श्री गोलू देवता की आरती (जय ग्वल देव)', 'uXWSqNklWiE', 'Jyotsna Jyoti Pant'),
  _UkRow('Golu Devta', _chalisa, 'Shri Goljyu Chalisa', 'श्री गोल्ज्यू चालीसा', '1ivXdmCQxE4', 'Raftaar News'),
  _UkRow('Golu Devta', _mantra, 'Golu Devta Jaap Maha Mantra', 'गोलू देवता जाप महामंत्र', 'cfa_T6mMF0s', 'Nanda Bhakti'),

  // ── Mahasu Devta ────────────────────────────────────────────────────────
  _UkRow('Mahasu Devta', _chalisa, 'Shri Mahasu Devta Chalisa', 'श्री महासू देवता चालीसा', 'nu_d9YZeh5c', 'Acharya Ashish Gaur'),
  _UkRow('Mahasu Devta', _stuti, 'Shri Mahasu Stuti', 'श्री महासू स्तुति', 'RXSCkPPQ5sE', 'Jai Mahasu Series'),
  _UkRow('Mahasu Devta', _mantra, 'Mahasu Mantra (1 Hour Jaap)', 'महासू मंत्र (1 घंटा जाप)', 's-iB8u0cppI', 'Blue Sky Films'),
];

import '../../domain/entities/jaap_mantra.dart';

/// Preset mantras for the Naam Jaap counter.
///
/// Texts must be proof-read by a pandit / Sanskrit reviewer before each
/// release (see §17.5 of docs/features/jaap_mala_counter.md).
///
/// `assets/sounds/jaap/<id>.m4a` are text-to-speech placeholders. Replace
/// them with licensed recordings of one clean repetition each.
class JaapMantraCatalog {
  static const String defaultMantraId = 'shri_ram';

  static const List<JaapMantra> all = [
    JaapMantra(
      id: 'radha',
      deity: 'Radha',
      devanagari: 'राधा राधा',
      transliteration: 'Radha Radha',
      name: {'mr': 'राधा राधा', 'hi': 'राधा राधा', 'en': 'Radha Radha'},
    ),
    JaapMantra(
      id: 'swami_samarth',
      deity: 'Swami Samarth',
      devanagari: 'श्री स्वामी समर्थ',
      transliteration: 'Shri Swami Samarth',
      name: {'mr': 'श्री स्वामी समर्थ', 'hi': 'श्री स्वामी समर्थ', 'en': 'Shri Swami Samarth'},
    ),
    JaapMantra(
      id: 'shri_ram',
      deity: 'Lord Rama',
      devanagari: 'श्री राम जय राम जय जय राम',
      transliteration: 'Shri Ram Jay Ram Jay Jay Ram',
      name: {'mr': 'श्रीराम जप', 'hi': 'श्री राम जप', 'en': 'Shri Ram'},
      freeAudio: true,
    ),
    JaapMantra(
      id: 'ganesha',
      deity: 'Lord Ganesha',
      devanagari: 'ॐ गं गणपतये नमः',
      transliteration: 'Om Gam Ganapataye Namah',
      name: {'mr': 'श्री गणेश', 'hi': 'श्री गणेश', 'en': 'Lord Ganesha'},
    ),
    JaapMantra(
      id: 'om_namah_shivaya',
      deity: 'Lord Shiva',
      devanagari: 'ॐ नमः शिवाय',
      transliteration: 'Om Namah Shivaya',
      name: {'mr': 'महादेव', 'hi': 'महादेव', 'en': 'Lord Shiva'},
      freeAudio: true,
    ),
    JaapMantra(
      id: 'vasudevaya',
      deity: 'Lord Vishnu',
      devanagari: 'ॐ नमो भगवते वासुदेवाय',
      transliteration: 'Om Namo Bhagavate Vasudevaya',
      name: {'mr': 'श्री विष्णू', 'hi': 'श्री विष्णु', 'en': 'Lord Vishnu'},
    ),
    JaapMantra(
      id: 'jai_shri_ram',
      deity: 'Lord Rama',
      devanagari: 'जय श्री राम',
      transliteration: 'Jai Shri Ram',
      name: {'mr': 'जय श्री राम', 'hi': 'जय श्री राम', 'en': 'Jai Shri Ram'},
    ),
    JaapMantra(
      id: 'hare_krishna',
      deity: 'Lord Krishna',
      devanagari: 'हरे कृष्ण हरे कृष्ण कृष्ण कृष्ण हरे हरे ।\n'
          'हरे राम हरे राम राम राम हरे हरे ॥',
      transliteration: 'Hare Krishna Hare Krishna Krishna Krishna Hare Hare\n'
          'Hare Rama Hare Rama Rama Rama Hare Hare',
      name: {'mr': 'हरे कृष्ण महामंत्र', 'hi': 'हरे कृष्ण महामंत्र', 'en': 'Hare Krishna Mahamantra'},
    ),
    JaapMantra(
      id: 'om_namo_narayanaya',
      deity: 'Lord Vishnu',
      devanagari: 'ॐ नमो नारायणाय',
      transliteration: 'Om Namo Narayanaya',
      name: {'mr': 'ॐ नमो नारायणाय', 'hi': 'ॐ नमो नारायणाय', 'en': 'Om Namo Narayanaya'},
    ),
    JaapMantra(
      id: 'gayatri',
      deity: 'Gayatri',
      devanagari: 'ॐ भूर्भुवः स्वः ।\n'
          'तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि ।\n'
          'धियो यो नः प्रचोदयात् ॥',
      transliteration: 'Om Bhur Bhuvah Svah\n'
          'Tat Savitur Varenyam Bhargo Devasya Dhimahi\n'
          'Dhiyo Yo Nah Prachodayat',
      name: {'mr': 'गायत्री मंत्र', 'hi': 'गायत्री मंत्र', 'en': 'Gayatri Mantra'},
    ),
    JaapMantra(
      id: 'shani_mantra',
      deity: 'Lord Shani',
      devanagari: 'ॐ नीलांजन समाभासं रविपुत्रं यमाग्रजम् ।\n'
          'छाया मार्तण्ड सम्भूतं तं नमामि शनैश्चरम् ॥',
      transliteration: 'Om Neelanjana Samabhasam Raviputram Yamagrajam\n'
          'Chhaya Martanda Sambhutam Tam Namami Shanaishcharam',
      name: {'mr': 'शनि मंत्र', 'hi': 'शनि मंत्र', 'en': 'Shani Mantra'},
    ),
    JaapMantra(
      id: 'hanuman',
      deity: 'Lord Hanuman',
      devanagari: 'ॐ हं हनुमते नमः',
      transliteration: 'Om Ham Hanumate Namah',
      name: {'mr': 'श्री हनुमान', 'hi': 'श्री हनुमान', 'en': 'Lord Hanuman'},
    ),
    JaapMantra(
      id: 'durga',
      deity: 'Goddess Durga',
      devanagari: 'ॐ दुं दुर्गायै नमः',
      transliteration: 'Om Dum Durgayai Namah',
      name: {'mr': 'दुर्गा माता', 'hi': 'दुर्गा माँ', 'en': 'Goddess Durga'},
    ),
    JaapMantra(
      id: 'datta',
      deity: 'Lord Datta',
      devanagari: 'श्री गुरुदेव दत्त',
      transliteration: 'Shri Gurudev Datta',
      name: {'mr': 'श्री दत्त', 'hi': 'श्री दत्त', 'en': 'Lord Datta'},
    ),
    JaapMantra(
      id: 'vitthal',
      deity: 'Lord Vitthal',
      devanagari: 'राम कृष्ण हरी',
      transliteration: 'Ram Krishna Hari',
      name: {'mr': 'विठ्ठल', 'hi': 'विट्ठल', 'en': 'Lord Vitthal'},
    ),
    JaapMantra(
      id: 'sai_ram',
      deity: 'Sai Baba',
      devanagari: 'ॐ साई राम',
      transliteration: 'Om Sai Ram',
      name: {'mr': 'साईबाबा', 'hi': 'साईं बाबा', 'en': 'Sai Baba'},
    ),
    JaapMantra(
      id: 'mahamrityunjaya',
      deity: 'Lord Shiva',
      devanagari: 'ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम् ।\n'
          'उर्वारुकमिव बन्धनान् मृत्योर्मुक्षीय माऽमृतात् ॥',
      transliteration: 'Om Tryambakam Yajamahe Sugandhim Pushtivardhanam\n'
          'Urvarukamiva Bandhanan Mrityor Mukshiya Maamritat',
      name: {'mr': 'महामृत्युंजय मंत्र', 'hi': 'महामृत्युंजय मंत्र', 'en': 'Mahamrityunjaya Mantra'},
    ),
  ];

  static JaapMantra byId(String? id) => all.firstWhere(
        (m) => m.id == id,
        orElse: () => all.firstWhere(
          (m) => m.id == defaultMantraId,
          orElse: () => all.first,
        ),
      );
}

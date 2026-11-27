import '../../../data/datasources/bhakti_deity_catalog.dart';
import '../../../domain/entities/aarti_item.dart';
import '../../../data/datasources/bundled_song_catalog.dart';
import '../../../domain/entities/aarti_item.dart';
import '../../../domain/entities/bhakti_deity.dart';
import '../data/voice_agent_service.dart';

/// Matches voice titles against items the app can actually open.
class VoiceCatalog {
  static final _play = RegExp(
    r'(^|\s)(play|listen|hear|start|वाजवा|लावा|ऐका|चलाओ|सुनाओ|सुना|सुनना|सुननी|ऐकायचं|ऐकायचे|ऐकायचंय|sunna|sunni|aikaycha|aikaychay|chalao|sunao)(?=\s|$)',
  );
  static final _requestWords = RegExp(
    r'^(?:(?:please|could you|can you|could we|can we|i would like to|i d like to|i want to|please let me|mujhe|mala|मला|मुझे|कृपया|जरा|play|open|ओपन|ओपेन|प्ले|शो|show|read|listen to|hear|lyrics of|the) )+|'
    r'(?: (?:please|for me|sunna hai|sunni hai|aikaycha aahe|aikaychay|सुनना है|सुननी है|ऐकायचं आहे|ऐकायचे आहे|ऐकायचंय|वाचायचं आहे|पढ़ना है|lyrics|वाजवा|लावा|ऐका|उघडा|दाखवा|चलाओ|सुनाओ|खोलो|दिखाओ|करो|करा|do|chalao|sunao|kholo|dikhao|opan|open))+$',
  );
  static const _aliases = {
    'pasaydan': 'pasayadan',
    'pasaydaan': 'pasayadan',
    'pasay adan': 'pasayadan',
    'पसायदान': 'pasayadan',
    'ata vishwatmake deve': 'pasayadan',
    'आता विश्वात्मके देवे': 'pasayadan',
    'shani aarti': 'shani_aarti',
    'shani dev aarti': 'shani_aarti',
    'shani dev ki aarti': 'shani_aarti',
    'shanidev aarti': 'shani_aarti',
    'shani deva aarti': 'shani_aarti',
    'शनि देव आरती': 'shani_aarti',
    'शनिदेव आरती': 'shani_aarti',
    'शनी देव आरती': 'shani_aarti',
    'शनीची आरती': 'shani_aarti',
    'शनिदेवाची आरती': 'shani_aarti',
    'शनि देव की आरती': 'shani_aarti',
  };
  static const _genericNames = {
    'aarti',
    'आरती',
    'भजन',
    'bhajan',
    'stotra',
    'स्तोत्र',
    'song',
    'chalisa',
    'चालीसा',
    'mantra',
    'मंत्र',
    'lyrics',
    'music',
  };

  /// STT often yields Hindi “ओपन” or glued “shivarti” instead of “open shiv aarti”.
  static String _spoken(String text) {
    var query = normalizeVoiceTitle(text)
        .replaceAll('ओपन', 'open')
        .replaceAll('ओपेन', 'open')
        .replaceAll('प्ले', 'play')
        .replaceAll('शो', 'show');
    for (final alias in const [
      'shiva', 'shiv', 'ganesha', 'ganesh', 'ganpati', 'hanuman', 'krishna',
      'rama', 'ram', 'durga', 'lakshmi', 'vitthal', 'datta',
    ]) {
      query = query.replaceAllMapped(
        RegExp('(?<=^|\\s)$alias(?:a+r+t[iy]|aarati|arrti)(?=\\s|\$)', caseSensitive: false),
        (_) => '$alias aarti',
      );
    }
    return query.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _title(String text) =>
      _spoken(text).replaceAll(_requestWords, '').trim();

  static bool wantsLyrics(String text) =>
      RegExp(r'lyrics|read |वाचा|वाचाय|पढ़|शब्द').hasMatch(text.toLowerCase());

  static bool wantsPlayback(String text) =>
      _play.hasMatch(normalizeVoiceTitle(text));

  static CatalogVideo? video(String text) {
    final query = _title(text);
    if (query.isEmpty || _genericNames.contains(query)) return null;
    return catalogVideosByTitle[query];
  }

  static final _aartiWord = RegExp(
    r'(?:a+r+t[iy]|aarati|आरती|आरत्या|आरतियाँ|आरतिया)',
    caseSensitive: false,
  );

  /// Extra spoken aliases so mixed “shiv aarti” resolves to Lord Shiva.
  static const _deityExtras = <String, List<String>>{
    'Lord Shiva': ['shiv', 'shiva', 'mahadev', 'bholenath', 'शिव', 'महादेव', 'भोलेनाथ'],
    'Lord Ganesha': ['ganesh', 'ganesha', 'ganpati', 'गणेश', 'गणपती'],
    'Lord Hanuman': ['hanuman', 'maruti', 'हनुमान', 'मारुती'],
    'Lord Krishna': ['krishna', 'kanha', 'कृष्ण', 'कान्हा'],
    'Lord Rama': ['ram', 'rama', 'राम', 'श्रीराम'],
    'Goddess Durga': ['durga', 'दुर्गा'],
    'Goddess Lakshmi': ['lakshmi', 'laxmi', 'लक्ष्मी'],
    'Lord Vitthal': ['vitthal', 'vithoba', 'विठ्ठल', 'विट्ठल'],
    'Lord Datta': ['datta', 'dattatreya', 'दत्त'],
    'Swami Samarth': ['swami samarth', 'स्वामी समर्थ'],
  };

  static BhaktiDeity? matchDeity(String text) {
    final query = _spoken(text);
    BhaktiDeity? best;
    var bestLen = 0;
    for (final deity in kBhaktiDeities) {
      final names = <String>{
        deity.key,
        deity.nameEn,
        deity.nameHi,
        deity.nameMr,
        ...deity.aliases,
        ...?_deityExtras[deity.key],
      };
      for (final name in names) {
        final normalized = normalizeVoiceTitle(name);
        if (normalized.isEmpty) continue;
        if (RegExp(
              '(?:^|\\s)${RegExp.escape(normalized)}(?:\\s|\$)',
            ).hasMatch(query) &&
            normalized.length > bestLen) {
          best = deity;
          bestLen = normalized.length;
        }
      }
    }
    return best;
  }

  static bool isGenericDeityAarti(String text, BhaktiDeity deity) {
    final spoken = _spoken(text);
    if (!_aartiWord.hasMatch(spoken)) return false;
    var leftover = _title(spoken);
    leftover = leftover.replaceAll(_aartiWord, ' ');
    final names = <String>{
      deity.key,
      deity.nameEn,
      deity.nameHi,
      deity.nameMr,
      ...deity.aliases,
      ...?_deityExtras[deity.key],
    };
    final sorted = names.map(normalizeVoiceTitle).where((n) => n.isNotEmpty).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final name in sorted) {
      leftover = leftover.replaceAll(
        RegExp('(?:^|\\s)${RegExp.escape(name)}(?:\\s|\$)'),
        ' ',
      );
    }
    leftover = leftover
        .replaceAll(
          RegExp(
            r'(?:^|\s)(?:all|list|collection|of|for|the|a|an|my|me|please|saari|saare|sabhi|sare|sari|सारी|सारे|सभी|सर्व|सगळ्या|ki|chi|जी|ji|dev|devta|lord|goddess|mata|show|open|ओपन|ओपेन|प्ले|शो|play|browse|see|find|get|give|do|karo|kara|करो|करा|kholo|dikhao)(?=\s|$)',
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return leftover.isEmpty;
  }

  static List<AartiItem> forDeity(BhaktiDeity deity, List<AartiItem> catalog) {
    return catalog
        .where(
          (item) =>
              deity.matches(item.deity) ||
              item.deity == deity.key ||
              normalizeVoiceTitle(item.deity).contains(
                normalizeVoiceTitle(deity.nameEn).split(' ').last,
              ) ||
              item.deityHi.contains(deity.nameHi) ||
              item.deityMr.contains(deity.nameMr),
        )
        .toList();
  }

  /// When the user asks for a deity's aartis (e.g. “open shiv aarti”), open the
  /// deity list if there are multiple hymns; open the single hymn if only one.
  static VoiceAgentResult? deityAartiList(
    String text,
    List<AartiItem> catalog,
    String locale,
  ) {
    final deity = matchDeity(text);
    if (deity == null || !isGenericDeityAarti(text, deity)) return null;
    final matches = forDeity(deity, catalog);
    if (matches.length == 1) {
      return result(matches.first, text, locale);
    }
    // Multiple or catalog mismatch: still open the deity list screen.
    final language = locale.split('-').first;
    final name = deity.localizedName(language);
    return VoiceAgentResult(
      status: 'action_ready',
      transcript: text,
      locale: locale,
      responseText: switch (language) {
        'hi' => '$name की आरतियाँ खोल रहे हैं।',
        'mr' => '$name च्या आरत्या उघडत आहे.',
        _ => 'Opening aartis for $name.',
      },
      action: VoiceAction(
        type: 'open_deity_aarti_list',
        deityKey: deity.key,
        featureKey: 'catalog',
      ),
      choices: const [],
    );
  }

  static AartiItem? find(
    String text,
    List<AartiItem> catalog, {
    String locale = 'mr-IN',
  }) {
    final query = _title(text);
    if (query.isEmpty || _genericNames.contains(query)) return null;

    for (final item in catalog) {
      if (normalizeVoiceTitle(item.localizedTitle(locale.split('-').first)) ==
          query) {
        return item;
      }
    }
    final alias = _aliases[query] ?? query;
    for (final item in catalog) {
      if (item.id == alias ||
          [item.title, item.titleMr, item.titleHi].any((title) {
            final normalized = normalizeVoiceTitle(title);
            return normalized == query ||
                (alias != query && normalized == alias);
          })) {
        return item;
      }
    }
    return null;
  }

  static VoiceAgentResult videoResult(
    CatalogVideo video,
    String text,
    String locale,
  ) {
    final title = video.song.song;
    return VoiceAgentResult(
      status: 'action_ready',
      transcript: text,
      locale: locale,
      responseText: switch (locale) {
        'hi-IN' => '$title का वीडियो खोल रहे हैं।',
        'mr-IN' => '$title चा व्हिडिओ उघडत आहे.',
        _ => 'Opening the video for $title.',
      },
      action: VoiceAction(
        type: 'open_song_video',
        songId: video.song.id,
        title: title,
      ),
      choices: const [],
    );
  }

  static VoiceAgentResult result(AartiItem item, String text, String locale) {
    final language = locale.split('-').first;
    final title = item.localizedTitle(language);
    var command = normalizeVoiceTitle(text);
    for (final name in [item.title, item.titleMr, item.titleHi]) {
      if (name.isNotEmpty) command = command.replaceAll(normalizeVoiceTitle(name), ' ');
    }
    final play = _play.hasMatch(command);
    return VoiceAgentResult(
      status: 'action_ready',
      transcript: text,
      locale: locale,
      responseText: switch (language) {
        'mr' => '$title उघडत आहे.',
        'hi' => '$title खोल रहे हैं।',
        _ => 'Opening $title.',
      },
      action: VoiceAction(
        type: play ? 'play_aarti' : 'open_aarti',
        aartiId: item.id,
        title: title,
      ),
      choices: const [],
    );
  }
}

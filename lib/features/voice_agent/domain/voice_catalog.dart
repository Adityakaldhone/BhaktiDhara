import '../../../domain/entities/aarti_item.dart';
import '../../../data/datasources/bundled_song_catalog.dart';
import '../data/voice_agent_service.dart';

/// Matches voice titles against items the app can actually open.
class VoiceCatalog {
  static final _play = RegExp(
    r'(^|\s)(play|listen|hear|start|वाजवा|लावा|ऐका|चलाओ|सुनाओ|सुना|सुनना|सुननी|ऐकायचं|ऐकायचे|ऐकायचंय|sunna|sunni|aikaycha|aikaychay|chalao|sunao)(?=\s|$)',
  );
  static final _requestWords = RegExp(
    r'^(?:(?:please|could you|can you|could we|can we|i would like to|i d like to|i want to|please let me|mujhe|mala|मला|मुझे|कृपया|जरा|play|open|show|read|listen to|hear|lyrics of|the) )+|'
    r'(?: (?:please|for me|sunna hai|sunni hai|aikaycha aahe|aikaychay|सुनना है|सुननी है|ऐकायचं आहे|ऐकायचे आहे|ऐकायचंय|वाचायचं आहे|पढ़ना है|lyrics|वाजवा|लावा|ऐका|उघडा|दाखवा|चलाओ|सुनाओ|खोलो|दिखाओ|chalao|sunao|kholo|dikhao))+$',
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

  static String _title(String text) =>
      normalizeVoiceTitle(text).replaceAll(_requestWords, '').trim();

  static bool wantsLyrics(String text) =>
      RegExp(r'lyrics|read |वाचा|वाचाय|पढ़|शब्द').hasMatch(text.toLowerCase());

  static bool wantsPlayback(String text) =>
      _play.hasMatch(normalizeVoiceTitle(text));

  static CatalogVideo? video(String text) {
    final query = _title(text);
    if (query.isEmpty || _genericNames.contains(query)) return null;
    return catalogVideosByTitle[query];
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

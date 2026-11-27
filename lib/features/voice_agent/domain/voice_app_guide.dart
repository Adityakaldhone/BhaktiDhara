import 'dart:convert';
import 'birth_rashi_dialog.dart';

import 'package:flutter/services.dart';

import '../../../domain/entities/aarti_item.dart';
import '../../../domain/entities/horoscope.dart';
import '../../../domain/entities/devotional_song_item.dart';
import '../data/voice_agent_service.dart';

/// Uses the same reviewed feature descriptions as the server and training set.
class VoiceAppGuide {
  VoiceAppGuide._(Map<String, dynamic> data)
    : birthRashi = BirthRashiDialog(
        data['birth_rashi'] as Map<String, dynamic>,
      ),
      _screenPatterns = (data['feature_screen_patterns'] as List)
          .cast<String>()
          .map(RegExp.new)
          .toList(),
      _priority = (data['topic_priority'] as List).cast<List>(),
      _jaapValues = data['jaap_values'] as Map<String, dynamic>,
      _featureExplanation = RegExp(data['feature_explanation'] as String),
      _appScope = RegExp(data['app_scope'] as String),
      _featureNavigation = RegExp(data['feature_navigation_hint'] as String),
      _topics = Map<String, dynamic>.from(data['topics'] as Map),
      _rashiAnswer = RegExp(data['rashi_answer'] as String),
      _routes = data['routes'] as Map<String, dynamic>,
      _catalogClues = data['catalog_clues'] as Map<String, dynamic>,
      _catalogQuestions = data['catalog_questions'] as Map<String, dynamic>,
      _catalogReplies = data['catalog_replies'] as Map<String, dynamic>,
      _exclude = RegExp(data['exclude'] as String),
      _decline = RegExp(data['decline'] as String),
      _modelQuestion = RegExp(data['model_questions'] as String);

  static final Future<VoiceAppGuide> instance = rootBundle
      .loadString('backend/app/voice_agent/app_help.json')
      .then(
        (source) => VoiceAppGuide._(jsonDecode(source) as Map<String, dynamic>),
      );

  final BirthRashiDialog birthRashi;
  final List<RegExp> _screenPatterns;
  final List<List> _priority;
  final RegExp _featureNavigation;
  final Map<String, dynamic> _jaapValues;
  String? jaapField(String query) {
    for (final entry in _jaapValues.entries) {
      if (RegExp(entry.value['pattern'] as String).hasMatch(query)) {
        return entry.key;
      }
    }
    return null;
  }

  VoiceAgentResult jaapAnswer(
    String field,
    int value,
    String text,
    String locale,
  ) {
    final reply =
        _jaapValues[field]['reply'][locale.split('-').first] as String;
    return VoiceAgentResult(
      status: 'answered',
      transcript: text,
      locale: locale,
      action: VoiceAction(
        type: 'answer_app_question',
        featureKey: 'jaap_stats',
        field: field,
      ),
      choices: const [],
      responseText: reply.replaceAll('{n}', value.toString()),
    );
  }

  final RegExp _featureExplanation;
  final RegExp _appScope;
  bool asksAboutFeature(String query) => _featureExplanation.hasMatch(query);
  static Set<String> _words(String text) => RegExp(r'[a-z0-9\u0900-\u097f]+')
      .allMatches(text.toLowerCase())
      .map((m) => m[0]!)
      .where((w) => w.length >= 4)
      .toSet();
  late final _answerWords = {
    for (final entry in _topics.entries)
      entry.key: _words((entry.value['reply'] as Map).values.join(' ')),
  };
  late final _uniqueWords = {
    for (final entry in _answerWords.entries)
      entry.key: entry.value.difference({
        for (final other in _answerWords.entries)
          if (other.key != entry.key) ...other.value,
      }),
  };
  late final _screenNames = <String, String>{
    for (final entry in _topics.entries)
      if (entry.value['screen_action'] != null)
        for (final name in [
          ...(entry.value['labels'] as Map).values,
          ...?entry.value['aliases'] as List?,
        ])
          _spokenKey(name as String): entry.key,
  };
  late final _questionExamples = <String, String>{
    for (final entry in _topics.entries)
      for (final example in (entry.value['examples'] as List).cast<String>())
        _spokenKey(example): entry.key,
  };

  bool supportsScreen(String topic, String kind, String query) =>
      _featureNavigation.hasMatch(query) &&
      _topics[topic]?['screen_action'] == kind;

  VoiceAgentResult openTopic(String key, String text, String locale) {
    final info = _topics[key];
    final kind = info['screen_action'] as String;
    if (_routes.containsKey(kind)) return routeResult(kind, text, locale);
    final lang = locale.split('-').first;
    final name = info['labels'][lang];
    return VoiceAgentResult(
      status: 'action_ready',
      transcript: text,
      locale: locale,
      action: VoiceAction(type: kind),
      choices: const [],
      responseText: lang == 'en'
          ? 'Opening $name.'
          : lang == 'hi'
          ? '$name खोल रहे हैं।'
          : '$name उघडत आहे.',
    );
  }

  final Map<String, dynamic> _topics;
  final Map<String, dynamic> _routes;
  final Map<String, dynamic> _catalogClues;
  final Map<String, dynamic> _catalogQuestions;
  final Map<String, dynamic> _catalogReplies;
  final RegExp _rashiAnswer;
  Rashi? signAnswer(String query) {
    final word = _rashiAnswer.firstMatch(query)?.group(1);
    final id = kRashiAliasToId[word];
    return id == null ? null : resolveRashi(id);
  }

  final RegExp _exclude;
  final RegExp _decline;
  final RegExp _modelQuestion;

  bool declines(String query) =>
      _decline.hasMatch(query) ||
      (_exclude.hasMatch(query) &&
          [
            'language',
            'feedback',
            'reminders',
          ].any((key) => _mentions(key, query)));

  bool _mentions(String key, String query) =>
      RegExp(_topics[key]['terms'] as String).hasMatch(query);

  List<String> candidates(String query) {
    if (_exclude.hasMatch(query)) return const [];
    final matches = _topics.keys.where((key) => _mentions(key, query)).toList();
    for (final entry in _screenNames.entries) {
      if (!matches.contains(entry.value) &&
          RegExp(
            r'(?:^|[ ,])' + RegExp.escape(entry.key) + r'(?:$|[ ,.?!।])',
          ).hasMatch(query)) {
        matches.add(entry.value);
      }
    }
    for (final pair in _priority) {
      if (matches.contains(pair.first)) matches.remove(pair.last);
    }
    if (matches.length > 1) matches.remove('more');
    if (matches.isEmpty && _appScope.hasMatch(query)) {
      final words = _words(query);
      matches.addAll(
        _uniqueWords.keys.where(
          (key) => words.intersection(_uniqueWords[key]!).length >= 2,
        ),
      );
    }
    return matches;
  }

  bool asksForInstructions(String query) => _modelQuestion.hasMatch(query);

  bool supportsRoute(String kind, String query) {
    final cues = _routes[kind]?['cues'] as String?;
    return cues != null &&
        !_exclude.hasMatch(query) &&
        RegExp(cues).hasMatch(query);
  }

  static String _spokenKey(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[?!.।]+$'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  late final Map<String, String> _routeExamples = {
    for (final entry in _routes.entries)
      for (final example in (entry.value['examples'] as List).cast<String>())
        _spokenKey(example): entry.key,
  };

  VoiceAgentResult? navigation(String query, String text, String locale) {
    for (final pattern in _screenPatterns) {
      final subject = pattern.firstMatch(query)?.group(1);
      final topic = subject == null ? null : _screenNames[_spokenKey(subject)];
      if (topic != null) return openTopic(topic, text, locale);
    }
    final example = _routeExamples[_spokenKey(query)];
    if (example != null) return routeResult(example, text, locale);
    for (final entry in _routes.entries) {
      final route = entry.value as Map<String, dynamic>;
      if (RegExp(route['pattern'] as String).hasMatch(query)) {
        return routeResult(entry.key, text, locale);
      }
    }
    return null;
  }

  VoiceAgentResult routeResult(String kind, String text, String locale) {
    final route = _routes[kind] as Map<String, dynamic>;
    return VoiceAgentResult(
      status: route['status'] as String? ?? 'action_ready',
      transcript: text,
      locale: locale,
      responseText: route['reply'][locale.split('-').first] as String,
      action: VoiceAction(type: kind),
      choices: const [],
    );
  }

  String? publishedTopic(String query) =>
      _exclude.hasMatch(query) ? null : _questionExamples[_spokenKey(query)];

  String? match(String query, List<String> candidates) {
    for (final key in candidates) {
      if (RegExp(_topics[key]['questions'] as String).hasMatch(query)) {
        return key;
      }
    }
    return null;
  }

  Set<String> catalogClues(String query) => {
    for (final entry in _catalogClues.entries)
      if (RegExp(entry.value as String).hasMatch(query)) entry.key,
  };

  (String, String)? catalogQuestion(String query) {
    final clean = query.replaceAll(RegExp(r'[ ?!।.]+$'), '');
    for (final entry in _catalogQuestions.entries) {
      for (final pattern in (entry.value as List).cast<String>()) {
        final match = RegExp(
          '^(?:$pattern)'
          r'$',
        ).firstMatch(clean);
        if (match != null) {
          for (var i = 1; i <= match.groupCount; i++) {
            final title = match.group(i);
            if (title != null) return (entry.key, title);
          }
        }
      }
    }
    return null;
  }

  VoiceAgentResult catalogAnswer(
    AartiItem item,
    String field,
    String text,
    String locale,
  ) {
    final lang = locale.split('-').first;
    final title = item.localizedTitle(lang);
    final value = switch (field) {
      'singer' => item.singer,
      'duration' => item.durationText,
      'about' => switch (lang) {
        'hi' => item.aboutHi,
        'mr' => item.aboutMr,
        _ => item.about,
      },
      _ => '',
    };
    return _catalogResult(
      field: field,
      value: value,
      title: title,
      hasAudio: item.youtubeVideoId.isNotEmpty,
      text: text,
      locale: locale,
      aartiId: item.id,
    );
  }

  VoiceAgentResult videoAnswer(
    DevotionalSongItem song,
    String field,
    String text,
    String locale,
  ) => _catalogResult(
    field: field,
    value: switch (field) {
      'singer' => song.artist,
      'duration' => song.durationText,
      _ => '',
    },
    title: song.song,
    hasAudio: song.videoId.isNotEmpty,
    text: text,
    locale: locale,
    songId: song.id,
  );

  VoiceAgentResult _catalogResult({
    required String field,
    required String value,
    required String title,
    required bool hasAudio,
    required String text,
    required String locale,
    String? aartiId,
    String? songId,
  }) {
    final lang = locale.split('-').first;
    final reply = switch (field) {
      'audio' => hasAudio ? 'audio_yes' : 'audio_no',
      'singer' || 'duration' || 'about' when value.isEmpty => 'missing',
      _ => field,
    };
    final template = _catalogReplies[reply][lang] as String;
    return VoiceAgentResult(
      status: 'answered',
      transcript: text,
      locale: locale,
      responseText: template
          .replaceAll('{title}', title)
          .replaceAll('{value}', value),
      action: VoiceAction(
        type: 'answer_app_question',
        featureKey: 'catalog',
        aartiId: aartiId,
        songId: songId,
        field: field,
      ),
      choices: const [],
    );
  }

  bool hasTopic(String key) => _topics.containsKey(key);

  String topicReply(String key, String locale) {
    final replies = _topics[key]['reply'] as Map<String, dynamic>;
    return (replies[locale.split('-').first] ?? replies['mr']) as String;
  }

  VoiceAgentResult answer(String key, String text, String locale) {
    return VoiceAgentResult(
      status: 'answered',
      transcript: text,
      locale: locale,
      responseText: topicReply(key, locale),
      action: VoiceAction(type: 'answer_app_question', featureKey: key),
      choices: const [],
    );
  }
}

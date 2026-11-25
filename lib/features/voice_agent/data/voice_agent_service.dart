import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../domain/entities/aarti_item.dart';
import '../../../domain/entities/jaap_progress.dart';
import '../../../domain/logic/jaap_streak.dart';
import '../../../services/backend_service.dart';
import '../domain/voice_catalog.dart';
import '../domain/home_voice_commands.dart';
import '../domain/birth_rashi_dialog.dart';
import '../domain/voice_app_guide.dart';
import '../domain/local_voice_intent_parser.dart';

/// Represents a single action payload returned by the voice agent
class VoiceAction {
  final String type;
  final String? rashiId;
  final String? rashiName;
  final String? aartiId;
  final String? songId;
  final String? title;
  final String? youtubeVideoId;
  final bool? hasAudio;
  final String? field;
  final String? featureKey;
  final int? chapter;
  final String? query;
  final String? mantraId;
  final String? languageCode;

  const VoiceAction({
    required this.type,
    this.rashiId,
    this.rashiName,
    this.aartiId,
    this.songId,
    this.title,
    this.youtubeVideoId,
    this.hasAudio,
    this.field,
    this.featureKey,
    this.chapter,
    this.query,
    this.mantraId,
    this.languageCode,
  });

  factory VoiceAction.fromJson(Map<String, dynamic> json) {
    return VoiceAction(
      type: json['type'] as String? ?? 'none',
      rashiId: json['rashi_id'] as String?,
      rashiName: json['rashi_name'] as String?,
      aartiId: json['aarti_id'] as String?,
      songId: json['song_id'] as String?,
      title: json['title'] as String?,
      youtubeVideoId: json['youtube_video_id'] as String?,
      hasAudio: json['has_audio'] as bool?,
      field: json['field'] as String?,
      featureKey: json['feature_key'] as String?,
      chapter: json['chapter'] as int?,
      query: json['query'] as String?,
      mantraId: json['mantra_id'] as String?,
      languageCode: json['language_code'] as String?,
    );
  }
}

/// Result returned by the BhaktiDhara Voice Agent service
class VoiceAgentResult {
  final String status;
  final String transcript;
  final String locale;
  final String responseText;
  final VoiceAction action;
  final Map<String, String>? birthDetails;
  final List<Map<String, dynamic>> choices;

  const VoiceAgentResult({
    required this.status,
    required this.transcript,
    required this.locale,
    required this.responseText,
    required this.action,
    required this.choices,
    this.birthDetails,
  });

  factory VoiceAgentResult.fromJson(Map<String, dynamic> json) {
    return VoiceAgentResult(
      status: json['status'] as String? ?? 'unsupported',
      transcript: json['transcript'] as String? ?? '',
      locale: json['locale'] as String? ?? 'mr-IN',
      responseText: json['response_text'] as String? ?? '',
      action: VoiceAction.fromJson(
        json['action'] as Map<String, dynamic>? ?? {},
      ),
      birthDetails: (json['birth_details'] as Map?)?.cast<String, String>(),
      choices:
          (json['choices'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}

class VoiceAgentService {
  /// Base URL candidates:
  /// 1. adb reverse tcp:8000 on Android device -> http://127.0.0.1:8000
  /// 2. Android emulator -> http://10.0.2.2:8000
  /// 3. Production backend -> BackendService.backendUrl
  static List<String> get candidateUrls {
    const port = int.fromEnvironment('BHAKTI_VOICE_PORT', defaultValue: 8000);
    return [
      'http://127.0.0.1:$port',
      'http://10.0.2.2:$port',
      if (BackendService.backendUrl.isNotEmpty) BackendService.backendUrl,
    ];
  }

  static Future<HomeCommand?> predictHomeCommand(
    String text,
    String locale, {
    http.Client? client,
  }) async {
    if (!HomeCommand.mightReferToHome(text)) return null;
    final guide = await VoiceAppGuide.instance;
    final query = text.trim().toLowerCase();
    if (guide.declines(query) || guide.publishedTopic(query) != null)
      return null;
    for (final base in candidateUrls) {
      try {
        final uri = Uri.parse('$base/api/v1/voice-agent/home-control');
        final health = await (client?.get ?? http.get)(
          uri.resolve('health'),
        ).timeout(const Duration(seconds: 2));
        if (health.statusCode != 200) continue;
        final response = await (client?.post ?? http.post)(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text, 'locale_hint': locale}),
        ).timeout(const Duration(seconds: 25));
        if (response.statusCode == 200) {
          final action = jsonDecode(utf8.decode(response.bodyBytes))['action'];
          if (action is Map && action['type'] == 'answer_app_question') {
            final key = action['feature_key'];
            if (key is String &&
                key.startsWith('home_') &&
                guide.hasTopic(key)) {
              return HomeExplanation(
                guide.answer(key, text, locale).responseText,
              );
            }
          }
          return HomeCommand.fromPrediction(action);
        }
      } catch (_) {
        // Another configured server or the regular voice resolver may be available.
      }
    }
    return null;
  }

  /// Sends user voice transcript or text query to the self-hosted voice agent.
  /// Falls back to on-device deterministic parsing when the backend is unreachable.
  static Future<VoiceAgentResult?> processVoiceCommand(
    String text, {
    String? localeHint,
    String? pendingAction,
    Map<String, String>? birthDetails,
    Future<List<AartiItem>> Function()? loadCatalog,
    Future<JaapProgress> Function()? loadJaapProgress,
    http.Client? client,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return null;

    final hint = switch (localeHint?.split('-').first) {
      'hi' => 'hi-IN',
      'en' => 'en-IN',
      _ => 'mr-IN',
    };
    final guide = await VoiceAppGuide.instance;
    final query = clean.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final birth = guide.birthRashi;
    final collecting = pendingAction == BirthRashiDialog.action;
    if (((collecting || pendingAction == 'ask_rashi') &&
            birth.matches('cancel', query)) ||
        birth.requested(query, pendingAction) ||
        (collecting &&
            !birth.matches('switch', query) &&
            birth.containsFacts(clean))) {
      return birth.turn(clean, hint, collecting ? birthDetails : null);
    }
    if (guide.declines(query)) return notFound(clean, hint);
    if (pendingAction == 'ask_rashi') {
      final sign = guide.signAnswer(query);
      if (sign != null) {
        return LocalVoiceIntentParser.horoscope(sign, clean, hint);
      }
    }
    final field = guide.jaapField(query);
    if (field != null) {
      if (loadJaapProgress != null) {
        try {
          final progress = await loadJaapProgress();
          final today = JaapCalendar.dayKey(DateTime.now());
          final count = switch (field) {
            'streak' => JaapStreak.current(
              completed: progress.completedDays,
              protected: progress.protectedDays,
              today: today,
            ),
            'lifetime_count' => progress.lifetimeCount,
            _ => progress.countOn(today),
          };
          return guide.jaapAnswer(field, count, clean, hint);
        } catch (_) {
          // My Sadhana can still show the user's activity if the read fails.
        }
      }
      return guide.openTopic('jaap_stats', clean, hint);
    }
    final published = guide.publishedTopic(query);
    if (published != null) return guide.answer(published, clean, hint);
    final topics = guide.candidates(query);
    final question = guide.catalogQuestion(query);
    final clues = guide.catalogClues(query);
    final indirectCatalog = question == null && clues.isNotEmpty;
    final topic = guide.match(query, topics);
    if (topic != null && question == null) {
      return guide.answer(topic, clean, hint);
    }
    final askModel = topics.isNotEmpty && guide.asksForInstructions(query);
    if (askModel && topics.length == 1 && question == null) {
      return guide.answer(topics.single, clean, hint);
    }
    final featureQuestion = topics.isNotEmpty && guide.asksAboutFeature(query);
    final local = LocalVoiceIntentParser.parse(clean, localeHint: hint);
    List<AartiItem>? catalog;
    if (loadCatalog != null) {
      try {
        catalog = await loadCatalog();
        final item = VoiceCatalog.find(
          question?.$2 ?? clean,
          catalog,
          locale: hint,
        );
        if (question != null && item != null) {
          return guide.catalogAnswer(item, question.$1, clean, hint);
        }
        if (!askModel && !indirectCatalog && item != null) {
          return VoiceCatalog.result(item, clean, hint);
        }
      } catch (_) {
        // The backend can still resolve catalog entries during a load failure.
      }
    }
    if (question != null ||
        (!askModel && !indirectCatalog && !VoiceCatalog.wantsLyrics(clean))) {
      final video = VoiceCatalog.video(question?.$2 ?? clean);
      if (video != null && question != null) {
        return guide.videoAnswer(video.song, question.$1, clean, hint);
      }
      if (video != null &&
          (local.action.type == 'search_aarti' ||
              VoiceCatalog.wantsPlayback(clean))) {
        return VoiceCatalog.videoResult(video, clean, hint);
      }
    }
    if (question != null && catalog != null) {
      if (const {'about', 'availability'}.contains(question.$1) &&
          (topic != null || topics.length == 1)) {
        return guide.answer(topic ?? topics.single, clean, hint);
      }
      if (question.$1 != 'availability' || topics.isEmpty) {
        return notFound(clean, hint);
      }
    }
    if ((question == null || question.$1 == 'availability') &&
        !askModel &&
        !indirectCatalog) {
      final route = guide.navigation(query, clean, hint);
      if (route != null) return route;
      if (!featureQuestion &&
          local.action.type == 'open_horoscope' &&
          local.action.rashiId == null) {
        return guide.routeResult('ask_rashi', clean, hint);
      }
      if (!featureQuestion && local.action.type != 'search_aarti') return local;
    }
    if (question?.$1 == 'duration' && local.action.type == 'open_jaap_stats') {
      return local;
    }

    if (collecting && !birth.matches('switch', query)) {
      return birth.turn(clean, hint, birthDetails);
    }
    final body = jsonEncode({
      'text': clean,
      'locale_hint': hint,
      if (pendingAction != null) 'pending_action': pendingAction,
    });

    for (final base in candidateUrls) {
      try {
        final uri = Uri.parse('$base/api/v1/voice-agent/text');
        // Probe unreachable demo addresses quickly, while giving a reachable model
        // enough time to load its weights and generate a structured answer.
        final health = await (client?.get ?? http.get)(
          uri.resolve('health'),
        ).timeout(const Duration(seconds: 2));
        if (health.statusCode >= 500) continue;
        final response = await (client?.post ?? http.post)(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        ).timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map<String, dynamic>) {
            final result = VoiceAgentResult.fromJson(decoded);
            if (result.action.type == 'answer_app_question') {
              final key = result.action.featureKey;
              if (key == 'catalog' &&
                  question != null &&
                  result.action.field == question.$1 &&
                  result.action.aartiId != null &&
                  catalog == null) {
                return result;
              }
              final field = result.action.field;
              if (key == 'catalog' &&
                  indirectCatalog &&
                  field != null &&
                  clues.contains(field)) {
                for (final item in catalog ?? const <AartiItem>[]) {
                  if (item.id == result.action.aartiId) {
                    return guide.catalogAnswer(item, field, clean, hint);
                  }
                }
                if (catalog == null && result.action.aartiId != null) {
                  return result;
                }
              }
              if (key != null && topics.contains(key)) {
                return guide.answer(key, clean, hint);
              }
              return notFound(clean, hint);
            }
            if (askModel || indirectCatalog || question != null) {
              return notFound(clean, hint);
            }
            if (topics.length == 1 &&
                guide.supportsScreen(
                  topics.single,
                  result.action.type,
                  query,
                )) {
              return guide.openTopic(topics.single, clean, hint);
            }
            switch (result.action.type) {
              case 'open_notifications':
              case 'open_feedback':
              case 'open_more':
              case 'open_bhajans':
                return guide.supportsRoute(result.action.type, query)
                    ? result
                    : notFound(clean, hint);
              case 'open_premium':
              case 'open_mandir':
              case 'open_akhand_diya':
              case 'set_language':
              case 'open_aarti_reminders':
              case 'open_language_settings':
              case 'none':
              case 'search_aarti':
                return notFound(clean, hint);
              case 'open_aarti':
              case 'play_aarti':
                if (catalog == null && loadCatalog == null) return result;
                return catalog?.any(
                          (item) => item.id == result.action.aartiId,
                        ) ==
                        true
                    ? result
                    : notFound(clean, hint);
              case BirthRashiDialog.action:
                return pendingAction == 'ask_rashi'
                    ? birth.turn(clean, hint)
                    : notFound(clean, hint);
              case 'ask_rashi':
                return guide.routeResult('ask_rashi', clean, hint);
              case 'open_horoscope':
                final sign = LocalVoiceIntentParser.matchRashiInText(clean);
                return sign == null
                    ? guide.routeResult('ask_rashi', clean, hint)
                    : LocalVoiceIntentParser.horoscope(sign, clean, hint);
              case 'open_panchang':
              case 'start_jaap':
              case 'open_jaap_stats':
              case 'open_calendar':
              case 'open_granth':
              case 'open_kundali':
              case 'open_milan':
              case 'open_ishta_devta':
              case 'open_greetings':
              case 'open_grahan':
                return result;
              default:
                return notFound(clean, hint);
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Voice agent connecting to $base failed: $e');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('Voice agent backend unavailable — using local intent parser');
    }
    if (featureQuestion && topics.length == 1) {
      return guide.answer(topics.single, clean, hint);
    }
    return notFound(clean, hint);
  }

  static VoiceAgentResult notFound(String text, String locale) =>
      VoiceAgentResult(
        status: 'not_found',
        transcript: text,
        locale: locale,
        responseText: switch (locale) {
          'hi-IN' => 'मुझे भक्तिधारा में इसका कोई विकल्प नहीं मिला।',
          'mr-IN' => 'भक्तिधारामध्ये यासाठी काही सापडले नाही.',
          _ => 'I couldn’t find a matching item or feature in BhaktiDhara.',
        },
        action: const VoiceAction(type: 'none'),
        choices: const [],
      );
}

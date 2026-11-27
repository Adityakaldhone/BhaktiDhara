import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/jaap_mantra_catalog.dart';
import '../../../data/datasources/bundled_song_catalog.dart';
import '../../../presentation/screens/deity_video_watch_screen.dart';
import '../../../domain/entities/aarti_item.dart';
import '../../../domain/entities/horoscope.dart';
import '../../../presentation/providers/bhakti_darshan_providers.dart';
import '../../../presentation/providers/horoscope_provider.dart';
import '../../../presentation/providers/locale_provider.dart';
import '../../../presentation/screens/altar_screen.dart';
import '../../../presentation/screens/bhajan_screen.dart';
import '../../../presentation/screens/calendar/calendar_screen.dart';
import '../../../presentation/screens/grahan_screen.dart';
import '../../../presentation/screens/greetings_screen.dart';
import '../../../data/datasources/bhakti_deity_catalog.dart';
import '../../../presentation/providers/granth_providers.dart';
import '../../../presentation/screens/deity_aarti_list_screen.dart';
import '../../../presentation/screens/granth_catalog_screen.dart';
import '../../../presentation/screens/granth_chapter_list_screen.dart';
import '../../../presentation/screens/horoscope_screen.dart';
import '../../../presentation/screens/ishta_devta_screen.dart';
import '../../../presentation/screens/jaap_counter_screen.dart';
import '../../../presentation/screens/jaap_stats_screen.dart';
import '../../../presentation/screens/kundali_screen.dart';
import '../../../presentation/screens/milan_screen.dart';
import '../../../presentation/screens/more_screen.dart';
import '../../../presentation/screens/panchang_screen.dart';
import '../../../presentation/screens/request_deity_aarti_screen.dart';
import '../../../presentation/widgets/language_dropdown.dart';
import '../../../presentation/widgets/premium_blurred_gate.dart';
import '../../../presentation/widgets/remote_notices.dart';
import '../../../presentation/widgets/nitya_pin_sheet.dart';
import '../../../presentation/widgets/request_deity_section.dart';
import '../../mandir/screens/real_garbhagriha_screen.dart';
import '../data/bhakti_wake_controller.dart';
import '../data/voice_agent_service.dart';
import 'local_voice_intent_parser.dart';

class VoiceActionDispatcher {
  /// Executes the structured action returned by the voice agent.
  static Future<bool> execute({
    required BuildContext context,
    required WidgetRef ref,
    required VoiceAction action,
    required String transcript,
  }) async {
    if (!context.mounted) return false;

    switch (action.type) {
      case 'set_language':
        final code = action.languageCode;
        if (code == null || !const {'mr', 'hi', 'en'}.contains(code)) {
          return false;
        }
        selectAppLanguage(ref, Locale(code));
        return true;

      case 'open_language_settings':
        final selected = await LanguageDropdown.pickLanguage(context);
        if (selected != null && context.mounted) {
          selectAppLanguage(ref, selected);
        }
        return true;

      case 'open_bhajans':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BhajanScreen()),
        );
        return true;

      case 'open_more':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MoreScreen()),
        );
        return true;

      case 'open_notifications':
        await showHomeNotificationsSheet(context, ref);
        return true;

      case 'open_aarti_reminders':
        await showAartiReminderSettingsSheet(context);
        return true;

      case 'open_premium':
        showPremiumPaywallSheet(
          context,
          ref,
          ref.read(localeProvider).languageCode,
        );
        return true;

      case 'open_feedback':
        await MoreScreen.showFeedback(context);
        return true;

      case 'open_horoscope':
        final resolved =
            resolveRashi(action.rashiId) ??
            resolveRashi(action.rashiName) ??
            LocalVoiceIntentParser.matchRashiInText(transcript);
        if (resolved != null) {
          ref.read(selectedRashiProvider.notifier).state = resolved;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                HoroscopeScreen(initialRashiId: resolved?.id ?? action.rashiId),
          ),
        );
        return true;

      case 'open_panchang':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PanchangScreen(focusField: action.field),
          ),
        );
        return true;

      case 'open_mandir':
      case 'open_akhand_diya':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RealGarbhagrihaScreen()),
        );
        return true;

      case 'start_jaap':
        final requestedId = action.mantraId?.trim();
        final mantraId = JaapMantraCatalog.all.any((m) => m.id == requestedId)
            ? requestedId
            : LocalVoiceIntentParser.matchJaapMantra(transcript.toLowerCase());
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JaapCounterScreen(
              initialMantraId: mantraId,
              skipEntrySheet: true,
            ),
          ),
        );
        return true;

      case 'open_jaap_stats':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JaapStatsScreen()),
        );
        return true;

      case 'open_calendar':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CalendarScreen()),
        );
        return true;

      case 'open_granth':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GranthCatalogScreen(hintChapter: action.chapter),
          ),
        );
        return true;

      case 'open_granth_book':
        final slug = action.bookSlug?.trim();
        if (slug == null || slug.isEmpty) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GranthCatalogScreen(hintChapter: action.chapter),
            ),
          );
          return true;
        }
        final books = await ref.read(granthBooksProvider.future);
        final matched = books.where((b) => b.slug == slug);
        final book = matched.isEmpty ? null : matched.first;
        if (book == null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GranthCatalogScreen(hintChapter: action.chapter),
            ),
          );
          return true;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GranthChapterListScreen(book: book)),
        );
        return true;

      case 'open_request_deity':
        final spoken = '${action.query ?? ''} $transcript'.toLowerCase();
        final kind = spoken.contains('aarti') || spoken.contains('आरती')
            ? DeityRequestKind.aarti
            : DeityRequestKind.deity;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDeityAartiScreen(
              initialText: action.query ?? '',
              initialKind: kind,
              source: 'voice',
            ),
          ),
        );
        return true;

      case 'open_deity_aarti_list':
        final key = action.deityKey?.trim();
        if (key == null || key.isEmpty) return false;
        final matchedDeities = kBhaktiDeities.where(
          (d) => d.key == key || d.matches(key),
        );
        final deity = matchedDeities.isEmpty ? null : matchedDeities.first;
        if (deity == null) return false;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeityAartiListScreen(deity: deity.key),
          ),
        );
        return true;

      case 'set_wake_word':
        final enabled = action.enabled ?? true;
        await ref.read(bhaktiWakeProvider).setEnabled(enabled);
        return true;

      case 'open_kundali':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KundaliScreen()),
        );
        return true;

      case 'open_milan':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MilanScreen()),
        );
        return true;

      case 'open_ishta_devta':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const IshtaDevtaScreen()),
        );
        return true;

      case 'open_greetings':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GreetingsScreen()),
        );
        return true;

      case 'open_grahan':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GrahanScreen()),
        );
        return true;

      case 'open_song_video':
        final video = catalogVideosById[action.songId];
        if (video == null) return false;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeityVideoWatchScreen(
              initialSong: video.song,
              allSongs: bundledSongCollections[video.deity]!,
              deityTitle: video.deity,
            ),
          ),
        );
        return true;

      case 'open_aarti':
      case 'play_aarti':
        final catalog = ref.read(bhaktiContentProvider);
        AartiItem? targetItem;
        for (final item in catalog) {
          if (item.id == action.aartiId) {
            targetItem = item;
            break;
          }
        }

        if (targetItem != null && context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AartiAltarScreen(
                aarti: targetItem!,
                autoplay: action.type == 'play_aarti',
              ),
            ),
          );
          return true;
        }
        break;

      default:
        break;
    }

    return false;
  }
}

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
import '../../../presentation/screens/granth_catalog_screen.dart';
import '../../../presentation/screens/horoscope_screen.dart';
import '../../../presentation/screens/ishta_devta_screen.dart';
import '../../../presentation/screens/jaap_counter_screen.dart';
import '../../../presentation/screens/jaap_stats_screen.dart';
import '../../../presentation/screens/kundali_form_screen.dart';
import '../../../presentation/screens/milan_screen.dart';
import '../../../presentation/screens/more_screen.dart';
import '../../../presentation/screens/panchang_screen.dart';
import '../../../presentation/widgets/language_dropdown.dart';
import '../../../presentation/widgets/premium_blurred_gate.dart';
import '../../../presentation/widgets/remote_notices.dart';
import '../../../presentation/widgets/nitya_pin_sheet.dart';
import '../../mandir/screens/real_garbhagriha_screen.dart';
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
          MaterialPageRoute(builder: (_) => const PanchangScreen()),
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
          MaterialPageRoute(builder: (_) => const GranthCatalogScreen()),
        );
        return true;

      case 'open_kundali':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KundaliFormScreen()),
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

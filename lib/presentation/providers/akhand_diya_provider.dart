import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_service.dart';
import '../../domain/entities/aarti_item.dart';
import '../../domain/entities/bhakti_deity.dart';
import '../../domain/logic/akhand_diya.dart';
import '../../domain/logic/ishta_devta.dart';
import '../../services/akhand_diya_service.dart';
import '../../services/backend_service.dart';
import 'aarti_providers.dart';
import 'locale_provider.dart';
import 'nitya_onboarding_providers.dart';

/// The deity whose Akhand Jyot burns on Home: the Ishta Devta, else Ganesh.
final jyotDeityProvider = Provider<BhaktiDeity>(
  (ref) => ishtaOrDefault(ref.watch(ishtaDevtaProvider)),
);

/// The aarti that feeds the Akhand Jyot; null while the catalog loads.
final jyotAartiProvider = Provider<AartiItem?>((ref) {
  final catalog = ref.watch(aartiCatalogProvider).valueOrNull;
  if (catalog == null) return null;
  return mainAartiFor(ref.watch(jyotDeityProvider), catalog);
});

/// Akhand Jyot state; null until loaded from SharedPreferences.
class AkhandDiyaNotifier extends StateNotifier<AkhandDiyaState?> {
  AkhandDiyaNotifier(this._ref) : super(null) {
    _load();
  }

  final Ref _ref;
  final _loaded = Completer<AkhandDiyaState>();

  Future<AkhandDiyaState> get ready => _loaded.future;

  Future<void> _load() async {
    final saved = await AkhandDiyaService.load();
    if (!_loaded.isCompleted) _loaded.complete(saved);
    if (mounted) state ??= saved;
  }

  /// Fills the diya to 100% and moves the streak on. [source] is where the
  /// ghee came from: `first_light` or `aarti`.
  Future<AkhandDiyaState> refill({required String source, String? aartiId}) async {
    final now = DateTime.now();
    final before = state ?? await ready;
    final next = before.refilled(now);
    state = next;

    final deity = _ref.read(jyotDeityProvider);
    final firstLight = !before.everLit;
    final props = <String, Object>{
      'source': source,
      'streak': next.streakDays,
      'ghee_before': before.gheePercent(now).round(),
      'revived': before.everLit && before.level(now) == JyotLevel.out && next.streakDays > 1,
    };
    BackendService.trackEvent(
      firstLight ? 'diya_lit' : 'diya_refilled',
      item: deity.key,
      props: {...props, 'refilled_at': now.toUtc().toIso8601String()},
    );
    AnalyticsService.logFunnelEvent(
      firstLight ? FunnelEvent.diyaLit : FunnelEvent.diyaRefilled,
      parameters: {...props, 'revived': props['revived'].toString(), 'deity': deity.key},
    );

    await AkhandDiyaService.save(
      next,
      lang: _ref.read(localeProvider).languageCode,
      deity: deity,
      aartiId: _ref.read(jyotAartiProvider)?.id ?? aartiId,
    );
    return next;
  }
}

final akhandDiyaProvider = StateNotifierProvider<AkhandDiyaNotifier, AkhandDiyaState?>(
  (ref) => AkhandDiyaNotifier(ref),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/bhakti_deity_catalog.dart';
import '../../data/repositories/deity_affinity_repository.dart';
import '../../domain/entities/bhakti_deity.dart';
import '../../domain/entities/remote_devotional_catalog.dart';
import '../../domain/logic/deity_affinity_ranker.dart';
import '../../domain/logic/festival_featured_deities.dart';
import '../../services/backend_service.dart';
import 'aarti_favorites_provider.dart';

List<BhaktiDeity>? _cachedRemoteDeitiesRef;
Map<String, String> _canonicalDeityMap = const {};

Map<String, String> _buildCanonicalDeityMap(List<BhaktiDeity> remoteDeities) {
  final merged = mergeDeityCatalogs(kBhaktiDeities, remoteDeities);
  final map = <String, String>{};
  for (final d in merged) {
    map.putIfAbsent(d.key, () => d.key);
    for (final alias in d.aliases) {
      map.putIfAbsent(alias, () => d.key);
    }
  }
  return map;
}

/// Resolves catalog deity names and aliases to one key, so "Gayatri" and
/// "Goddess Gayatri" share the same history.
String canonicalDeityKey(String rawDeity) {
  final remoteDeities = BackendService.remoteCatalog.deities;
  if (!identical(_cachedRemoteDeitiesRef, remoteDeities)) {
    _cachedRemoteDeitiesRef = remoteDeities;
    _canonicalDeityMap = _buildCanonicalDeityMap(remoteDeities);
  }
  return _canonicalDeityMap[rawDeity] ?? rawDeity;
}

class DeityAffinityState {
  final Map<String, DeityUsage> usage;

  /// Top band shown in the Sacred Collection. Only changes on [DeityAffinityNotifier.refreshTop].
  final List<String> top;

  const DeityAffinityState({this.usage = const {}, this.top = const []});

  DeityAffinityState copyWith({Map<String, DeityUsage>? usage, List<String>? top}) {
    return DeityAffinityState(usage: usage ?? this.usage, top: top ?? this.top);
  }
}

final deityAffinityRepositoryProvider = Provider<DeityAffinityRepository>((ref) {
  return DeityAffinityRepository();
});

final deityAffinityClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class DeityAffinityNotifier extends StateNotifier<DeityAffinityState> {
  final DeityAffinityRepository _repository;
  final DateTime Function() _now;
  late final Future<void> _loaded;

  DeityAffinityNotifier(this._repository, this._now)
      : super(const DeityAffinityState()) {
    _loaded = _load();
  }

  Future<void> _load() async {
    final saved = await _repository.load();
    if (!mounted) return;
    state = DeityAffinityState(usage: saved.usage, top: saved.top);
    await refreshTop();
  }

  /// Records that the devotee opened a deity's aarti collection.
  Future<void> recordOpen(String rawDeity) async {
    await _loaded;
    if (!mounted) return;
    final key = canonicalDeityKey(rawDeity);
    final now = _now().millisecondsSinceEpoch;
    final usage = state.usage[key] ?? const DeityUsage();
    final opens = usage.openTimes;
    if (opens.isNotEmpty &&
        now - opens.last < DeityAffinityRanker.repeatOpenWindow.inMilliseconds) {
      return;
    }
    _put(key, usage.copyWith(openTimes: _capped([...opens, now])));
    await _persist();
  }

  /// Records foreground time spent on one of the deity's aartis.
  Future<void> recordSession(
    String rawDeity,
    Duration dwell, {
    bool completed = false,
  }) async {
    if (!completed && dwell < DeityAffinityRanker.minCountedDwell) return;
    await _loaded;
    if (!mounted) return;
    final key = canonicalDeityKey(rawDeity);
    final usage = state.usage[key] ?? const DeityUsage();
    final meaningful = completed || dwell >= DeityAffinityRanker.meaningfulDwell;
    _put(
      key,
      usage.copyWith(
        dwellSeconds: usage.dwellSeconds + dwell.inSeconds,
        sessionTimes: meaningful
            ? _capped([...usage.sessionTimes, _now().millisecondsSinceEpoch])
            : null,
      ),
    );
    await _persist();
  }

  /// Recomputes the top band. Call only when the devotee lands on Home, never
  /// while the list is on screen.
  Future<void> refreshTop() async {
    if (!mounted) return;
    final top = DeityAffinityRanker.rankTop(state.usage, state.top, _now());
    if (_sameList(top, state.top)) return;
    state = state.copyWith(top: top);
    await _persist();
  }

  void _put(String key, DeityUsage usage) {
    state = state.copyWith(usage: {...state.usage, key: usage});
  }

  Future<void> _persist() => _repository.save(state.usage, state.top);

  static List<int> _capped(List<int> times) {
    const cap = DeityAffinityRanker.historyCap;
    return times.length > cap ? times.sublist(times.length - cap) : times;
  }

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

final deityAffinityProvider =
    StateNotifierProvider<DeityAffinityNotifier, DeityAffinityState>((ref) {
  return DeityAffinityNotifier(
    ref.watch(deityAffinityRepositoryProvider),
    ref.watch(deityAffinityClockProvider),
  );
});

/// Deities promoted to the top of the Sacred Collection, skipping any already
/// pinned in My Daily Aartis so the same deity isn't shown twice up top.
///
/// Festival featured deities (e.g. Tulsi Mata on Tulsi Vivah) are prepended
/// ahead of affinity-ranked tops.
final sacredTopDeitiesProvider = Provider<List<String>>((ref) {
  final affinityTop = ref.watch(deityAffinityProvider.select((s) => s.top));
  final featured =
      festivalFeaturedDeityKeys(ref.watch(deityAffinityClockProvider)());
  if (affinityTop.isEmpty && featured.isEmpty) return const [];

  final dailyDeities = ref
      .watch(nityaAartisListProvider)
      .map((item) => canonicalDeityKey(item.deity))
      .toSet();

  final ordered = <String>[];
  final seen = <String>{};
  for (final key in [...featured, ...affinityTop]) {
    if (dailyDeities.contains(key)) continue;
    if (seen.add(key)) ordered.add(key);
  }
  return ordered;
});

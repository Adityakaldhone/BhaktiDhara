import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/bhajan_catalog.dart';
import '../../data/datasources/bhakti_deity_catalog.dart';
import '../../data/datasources/catalog.dart';
import '../../data/repositories/recent_deities_repository.dart';
import '../../domain/entities/aarti_item.dart';
import '../../domain/entities/bhakti_deity.dart';

/// Every aarti, bhajan, mantra and stotra across the catalogs, de-duplicated by id.
final bhaktiContentProvider = Provider<List<AartiItem>>((ref) {
  final seen = <String>{};
  return [
    for (final item in [...kDevotionalCatalog, ...kBhajanCatalog])
      if (seen.add(item.id)) item,
  ];
});

/// Repository for persisting recent deity order.
final recentDeitiesRepositoryProvider = Provider<RecentDeitiesRepository>((ref) {
  return RecentDeitiesRepository();
});

/// Preloaded initial recent deities list (can be overridden in ProviderScope for synchronous startup).
final initialRecentDeitiesProvider = Provider<List<String>>((ref) => const []);

/// Incremented whenever a deity is opened from Sacred Collection to force the carousel to index 0.
final bhaktiCarouselResetTriggerProvider = StateProvider<int>((ref) => 0);

/// Manages the cached LRU list of deity keys opened from Sacred Collection.
class RecentDeitiesNotifier extends StateNotifier<List<String>> {
  final RecentDeitiesRepository _repository;
  final Ref _ref;

  RecentDeitiesNotifier(this._repository, this._ref, List<String> initial)
      : super(initial) {
    if (initial.isEmpty) {
      _loadFromPrefs();
    }
  }

  Future<void> _loadFromPrefs() async {
    final cached = await _repository.loadRecentDeities();
    if (cached.isNotEmpty && mounted) {
      state = cached;
    }
  }

  /// Records that a deity's card was opened from Sacred Collection.
  /// Moves this deity to index 0, shifts previous deities down, resets carousel to index 0, and caches in SharedPreferences.
  Future<void> recordDeityOpened(String rawDeity) async {
    // 1. Resolve canonical deity key matching rawDeity
    final match = kBhaktiDeities.cast<BhaktiDeity?>().firstWhere(
      (d) => d != null && d.matches(rawDeity),
      orElse: () => null,
    );
    final canonicalKey = match?.key ?? rawDeity;

    // 2. Put this deity key at index 0 (LRU move to front)
    final updated = List<String>.from(state);
    updated.remove(canonicalKey);
    updated.insert(0, canonicalKey);
    state = updated;

    // 3. Update pinned deity key and reset the Bhakti tab carousel to 1st index
    _ref.read(pinnedDeityKeyProvider.notifier).state = canonicalKey;
    _ref.read(bhaktiCarouselResetTriggerProvider.notifier).state++;
    _ref.read(selectedDeityIndexProvider.notifier).state = 0;

    // 4. Persist updated order to SharedPreferences
    await _repository.saveRecentDeities(updated);
  }
}

/// Provider for the list of recently opened deity keys.
final recentDeitiesProvider =
    StateNotifierProvider<RecentDeitiesNotifier, List<String>>((ref) {
  final repo = ref.watch(recentDeitiesRepositoryProvider);
  final initial = ref.watch(initialRecentDeitiesProvider);
  return RecentDeitiesNotifier(repo, ref, initial);
});

/// Deity key to show first in the carousel (e.g. last opened from Sacred Collection).
final pinnedDeityKeyProvider = StateProvider<String?>((ref) {
  final recent = ref.watch(recentDeitiesProvider);
  return recent.isNotEmpty ? recent.first : null;
});

/// Deities that have content, in display order with recently opened deities first.
final bhaktiDeitiesProvider = Provider<List<BhaktiDeity>>((ref) {
  final content = ref.watch(bhaktiContentProvider);
  final recentKeys = ref.watch(recentDeitiesProvider);
  final pinnedKey = ref.watch(pinnedDeityKeyProvider);

  final available = kBhaktiDeities
      .where((d) => content.any((item) => d.matches(item.deity)))
      .toList();

  // Combine recent keys with pinnedKey if pinnedKey is set and not already present
  final keysToOrder = List<String>.from(recentKeys);
  if (pinnedKey != null && !keysToOrder.contains(pinnedKey)) {
    keysToOrder.insert(0, pinnedKey);
  }

  if (keysToOrder.isEmpty) {
    return available;
  }

  final ordered = <BhaktiDeity>[];
  final remaining = List<BhaktiDeity>.from(available);

  for (final key in keysToOrder) {
    final index = remaining.indexWhere((d) => d.matches(key));
    if (index != -1) {
      ordered.add(remaining.removeAt(index));
    }
  }
  // Append remaining deities in their default order
  ordered.addAll(remaining);

  return ordered;
});

/// Index of the deity currently shown inside the mandap.
final selectedDeityIndexProvider = StateProvider<int>((ref) => 0);

/// All catalog items for a deity key.
final deityContentProvider =
    Provider.family<List<AartiItem>, String>((ref, deityKey) {
  final deity = kBhaktiDeities.firstWhere((d) => d.key == deityKey);
  return ref
      .watch(bhaktiContentProvider)
      .where((item) => deity.matches(item.deity))
      .toList();
});

/// Category buttons available for a deity, in [BhaktiCategory] order.
final deityCategoriesProvider =
    Provider.family<List<BhaktiCategory>, String>((ref, deityKey) {
  if (deityKey == 'Lord Ganesha' || deityKey == 'Ganesha') {
    return const [
      BhaktiCategory.chalisa,
      BhaktiCategory.mantra,
      BhaktiCategory.stotra,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Lord Shiva' || deityKey == 'Shiva' || deityKey == 'Mahadev') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.chalisa,
      BhaktiCategory.mantra,
      BhaktiCategory.stotra,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Lord Hanuman' || deityKey == 'Hanuman') {
    return const [
      BhaktiCategory.chalisa,
      BhaktiCategory.mantra,
      BhaktiCategory.stotra,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Swami Samarth' || deityKey == 'Shri Swami Samarth') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.mantra,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Lord Khandoba' || deityKey == 'Khandoba') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Gondavalekar Maharaj' || deityKey == 'Brahmachaitanya Gondavalekar Maharaj') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Goddess Lakshmi' || deityKey == 'Lakshmi' || deityKey == 'Mahalakshmi') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.stotra,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Lord Rama' || deityKey == 'Rama' || deityKey == 'Prabhu Shri Ram') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.stotra,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Goddess Renuka Mata' ||
      deityKey == 'Renuka Mata' ||
      deityKey == 'Renuka Yellamma' ||
      deityKey == 'Yellamma') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Chandra Dev' || deityKey == 'Chandra') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Lord Siddhanath' || deityKey == 'Siddhanath') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Lord Vitthal' || deityKey == 'Vitthal' || deityKey == 'Shri Vitthal') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Lord Vishnu' || deityKey == 'Vishnu' || deityKey == 'Shri Vishnu') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Goddess Narmada' || deityKey == 'Narmada' || deityKey == 'Narmada Mata') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Lord Venkatesh' ||
      deityKey == 'Venkatesh' ||
      deityKey == 'Shri Venkatesh' ||
      deityKey == 'Venkateswara' ||
      deityKey == 'Balaji') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Sant Balumama' ||
      deityKey == 'Balumama' ||
      deityKey == 'Sadguru Balumama') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.mantra,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Goddess Durga' ||
      deityKey == 'Durga' ||
      deityKey == 'Durga Mata' ||
      deityKey == 'Maa Durga') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.chalisa,
      BhaktiCategory.mantra,
      BhaktiCategory.stotra,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Radha' ||
      deityKey == 'Radha Rani' ||
      deityKey == 'Shri Radha') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Goddess Gayatri' ||
      deityKey == 'Gayatri' ||
      deityKey == 'Gayatri Mata') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.chalisa,
      BhaktiCategory.mantra,
      BhaktiCategory.stotra,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Lord Krishna' ||
      deityKey == 'Krishna' ||
      deityKey == 'Shri Krishna') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.chalisa,
      BhaktiCategory.mantra,
      BhaktiCategory.stotra,
      BhaktiCategory.song,
    ];
  }
  if (deityKey == 'Lord Datta' ||
      deityKey == 'Datta' ||
      deityKey == 'Shri Datta' ||
      deityKey == 'Dattatreya' ||
      deityKey == 'Shri Dattatreya') {
    return const [
      BhaktiCategory.aarti,
      BhaktiCategory.chalisa,
      BhaktiCategory.mantra,
      BhaktiCategory.stotra,
      BhaktiCategory.song,
    ];
  }
  final items = ref.watch(deityContentProvider(deityKey));
  return BhaktiCategory.values
      .where((c) => items.any((item) => c.matchesTags(item.tags)))
      .toList();
});

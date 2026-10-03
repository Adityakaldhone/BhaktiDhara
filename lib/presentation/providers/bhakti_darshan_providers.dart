import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/bhajan_catalog.dart';
import '../../data/datasources/bhakti_deity_catalog.dart';
import '../../data/datasources/catalog.dart';
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

/// Deity key to show first in the carousel (e.g. last opened from Sacred Collection).
final pinnedDeityKeyProvider = StateProvider<String?>((ref) => null);

/// Deities that have content, in display order with the pinned deity first.
final bhaktiDeitiesProvider = Provider<List<BhaktiDeity>>((ref) {
  final content = ref.watch(bhaktiContentProvider);
  final pinnedKey = ref.watch(pinnedDeityKeyProvider);

  final deities = kBhaktiDeities
      .where((d) => content.any((item) => d.matches(item.deity)))
      .toList();

  if (pinnedKey != null) {
    final index = deities.indexWhere((d) => d.matches(pinnedKey));
    if (index > 0) deities.insert(0, deities.removeAt(index));
  }
  return deities;
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
  final items = ref.watch(deityContentProvider(deityKey));
  return BhaktiCategory.values
      .where((c) => items.any((item) => c.matchesTags(item.tags)))
      .toList();
});

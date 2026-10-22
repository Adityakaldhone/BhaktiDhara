import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/aarti_item.dart';
import 'aarti_providers.dart';

const _kFavoritesPrefKey = 'bhaktidhara_nitya_aartis_v1';

/// Repository for persisting the devotee's Daily / Nitya Aarti favorites.
class AartiFavoritesRepository {
  Future<List<String>> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_kFavoritesPrefKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFavorites(List<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kFavoritesPrefKey, ids);
    } catch (_) {}
  }
}

final aartiFavoritesRepositoryProvider = Provider<AartiFavoritesRepository>((ref) {
  return AartiFavoritesRepository();
});

class AartiFavoritesNotifier extends StateNotifier<List<String>> {
  final AartiFavoritesRepository _repo;

  AartiFavoritesNotifier(this._repo) : super(const []) {
    _init();
  }

  Future<void> _init() async {
    final loaded = await _repo.loadFavorites();
    state = loaded;
  }

  Future<void> toggle(String id) async {
    final current = [...state];
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.insert(0, id);
    }
    state = current;
    await _repo.saveFavorites(current);
  }

  bool isFavorite(String id) => state.contains(id);
}

final aartiFavoritesProvider =
    StateNotifierProvider<AartiFavoritesNotifier, List<String>>((ref) {
  final repo = ref.watch(aartiFavoritesRepositoryProvider);
  return AartiFavoritesNotifier(repo);
});

/// Returns the full [AartiItem]s that the user has marked as their Nitya Aarti.
final nityaAartisListProvider = Provider<List<AartiItem>>((ref) {
  final favoriteIds = ref.watch(aartiFavoritesProvider);
  if (favoriteIds.isEmpty) return const [];

  final catalogAsync = ref.watch(aartiCatalogProvider);
  return catalogAsync.maybeWhen(
    data: (allAartis) {
      final map = {for (final a in allAartis) a.id: a};
      return favoriteIds
          .where(map.containsKey)
          .map((id) => map[id]!)
          .toList();
    },
    orElse: () => const [],
  );
});

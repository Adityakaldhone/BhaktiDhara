import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/greeting_photo_store.dart';
import '../../data/repositories/greeting_repository.dart';
import '../../domain/entities/app_remote_config.dart';
import '../../domain/entities/greeting_image.dart';
import 'locale_provider.dart';
import 'remote_config_provider.dart';

/// Remote kill switch (`feature_flags.status_cards`). On by default, so the
/// feature keeps working if the server has never sent the flag.
final greetingsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(featureEnabledProvider(AppRemoteConfig.statusCards)),
);

/// Remote switch for the user's photo circle (`feature_flags.status_card_photo`).
final greetingPhotoEnabledProvider = Provider<bool>((ref) {
  if (!GreetingPhotoStore.supported) return false;
  return ref.watch(featureEnabledProvider(AppRemoteConfig.statusCardPhoto));
});

final greetingRepositoryProvider = Provider<GreetingRepository>((ref) => GreetingRepository());

final greetingCategoriesProvider = FutureProvider<List<GreetingCategory>>((ref) {
  return ref.watch(greetingRepositoryProvider).fetchCategories(ref.watch(localeProvider).languageCode);
});

/// Slug of the chip selected at the top of the greetings screen.
const kDefaultGreetingCategory = 'morning';
const kFavoritesCategory = '__favorites__';
final selectedGreetingCategoryProvider = StateProvider<String>((ref) => kDefaultGreetingCategory);

@immutable
class GreetingFeedState {
  final List<GreetingImage> images;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final bool failed;
  final int nextOffset;

  const GreetingFeedState({
    this.images = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = false,
    this.failed = false,
    this.nextOffset = 0,
  });

  GreetingFeedState copyWith({
    List<GreetingImage>? images,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    bool? failed,
    int? nextOffset,
  }) {
    return GreetingFeedState(
      images: images ?? this.images,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      failed: failed ?? this.failed,
      nextOffset: nextOffset ?? this.nextOffset,
    );
  }
}

/// Paged images of one category. Rebuilt when the language changes or the
/// user becomes premium, so unlocked images get their HD links.
class GreetingFeedNotifier extends StateNotifier<GreetingFeedState> {
  GreetingFeedNotifier(this._repo, {required this.category, required this.lang, required this.premium})
      : super(const GreetingFeedState()) {
    refresh();
  }

  final GreetingRepository _repo;
  final String category;
  final String lang;
  final bool premium;

  Future<void> refresh() async {
    state = state.copyWith(loading: state.images.isEmpty, failed: false);
    try {
      final page = await _repo.fetchImages(category: category, lang: lang, premium: premium);
      if (!mounted) return;
      state = GreetingFeedState(
        images: page.images,
        loading: false,
        hasMore: page.hasMore,
        nextOffset: page.nextOffset,
      );
    } catch (_) {
      if (mounted) state = state.copyWith(loading: false, failed: state.images.isEmpty);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await _repo.fetchImages(
        category: category,
        lang: lang,
        premium: premium,
        offset: state.nextOffset,
      );
      if (!mounted) return;
      final seen = state.images.map((i) => i.id).toSet();
      state = state.copyWith(
        images: [...state.images, ...page.images.where((i) => seen.add(i.id))],
        loadingMore: false,
        hasMore: page.hasMore,
        nextOffset: page.nextOffset,
      );
    } catch (_) {
      if (mounted) state = state.copyWith(loadingMore: false);
    }
  }
}

final greetingFeedProvider =
    StateNotifierProvider.autoDispose.family<GreetingFeedNotifier, GreetingFeedState, String>((ref, category) {
  return GreetingFeedNotifier(
    ref.watch(greetingRepositoryProvider),
    category: category,
    lang: ref.watch(localeProvider).languageCode,
    premium: ref.watch(premiumAccessProvider),
  );
});

final greetingFavoritesRepositoryProvider =
    Provider<GreetingFavoritesRepository>((ref) => GreetingFavoritesRepository());

class GreetingFavoritesNotifier extends StateNotifier<List<GreetingImage>> {
  GreetingFavoritesNotifier(this._repo) : super(const []) {
    _repo.load().then((loaded) {
      if (mounted && state.isEmpty) state = loaded;
    });
  }

  final GreetingFavoritesRepository _repo;

  bool contains(int id) => state.any((i) => i.id == id);

  void toggle(GreetingImage image) {
    state = contains(image.id)
        ? state.where((i) => i.id != image.id).toList()
        : [image, ...state];
    unawaited(_repo.save(state));
  }
}

final greetingFavoritesProvider =
    StateNotifierProvider<GreetingFavoritesNotifier, List<GreetingImage>>((ref) {
  return GreetingFavoritesNotifier(ref.watch(greetingFavoritesRepositoryProvider));
});

final greetingPhotoStoreProvider = Provider<GreetingPhotoStore>((ref) => GreetingPhotoStore());

/// Version of the user's saved photo; null when there is none.
class GreetingPhotoNotifier extends StateNotifier<int?> {
  GreetingPhotoNotifier(this._store) : super(null) {
    _store.stamp().then((stamp) {
      if (mounted && state == null) state = stamp;
    });
  }

  final GreetingPhotoStore _store;

  /// False when [raw] isn't a usable image.
  Future<bool> set(Uint8List raw) async {
    final saved = await _store.save(raw);
    if (saved && mounted) state = DateTime.now().millisecondsSinceEpoch;
    return saved;
  }

  Future<void> remove() async {
    state = null;
    await _store.delete();
  }
}

final greetingPhotoProvider = StateNotifierProvider<GreetingPhotoNotifier, int?>((ref) {
  return GreetingPhotoNotifier(ref.watch(greetingPhotoStoreProvider));
});

/// The photo bytes for a [greetingPhotoProvider] version.
final greetingPhotoBytesProvider = FutureProvider.family<Uint8List?, int>((ref, stamp) {
  return ref.watch(greetingPhotoStoreProvider).read();
});

/// Tracks IDs of greeting cards unlocked individually via rewarded ads.
class UnlockedGreetingsNotifier extends StateNotifier<Set<int>> {
  UnlockedGreetingsNotifier() : super(const {}) {
    _load();
  }

  static const _prefKey = 'rewarded_unlocked_greeting_ids';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKey) ?? const [];
      if (mounted) {
        state = list.map(int.tryParse).whereType<int>().toSet();
      }
    } catch (_) {}
  }

  Future<void> unlock(int id) async {
    if (state.contains(id)) return;
    state = {...state, id};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, state.map((i) => i.toString()).toList());
    } catch (_) {}
  }

  bool isUnlocked(int id) => state.contains(id);
}

final unlockedGreetingsProvider =
    StateNotifierProvider<UnlockedGreetingsNotifier, Set<int>>((ref) {
  return UnlockedGreetingsNotifier();
});

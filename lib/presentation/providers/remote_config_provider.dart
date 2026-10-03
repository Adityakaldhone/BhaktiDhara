import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_remote_config.dart';
import '../../services/backend_service.dart';
import 'locale_provider.dart';
import 'premium_provider.dart';

/// Admin "App Remote Control" settings. Starts from the cached config loaded
/// in `main()` and refreshes from the server on launch and on app resume.
class RemoteConfigNotifier extends StateNotifier<AppRemoteConfig> {
  RemoteConfigNotifier() : super(BackendService.remoteConfig) {
    refresh();
  }

  Future<void> refresh() async {
    final fresh = await BackendService.fetchRemoteConfig();
    if (mounted) state = fresh;
  }
}

final remoteConfigProvider =
    StateNotifierProvider<RemoteConfigNotifier, AppRemoteConfig>((ref) => RemoteConfigNotifier());

/// Whether an admin feature toggle (see [AppRemoteConfig] flag names) is on.
final featureEnabledProvider = Provider.family<bool, String>(
  (ref, flag) => ref.watch(remoteConfigProvider).isEnabled(flag),
);

/// Whether premium content is unlocked: the user is VIP, or the admin has
/// switched the paywall off so everything is free.
final premiumAccessProvider = Provider<bool>((ref) {
  return ref.watch(isPremiumProvider) ||
      !ref.watch(featureEnabledProvider(AppRemoteConfig.premiumPaywall));
});

final appVersionProvider = FutureProvider<String>((ref) => BackendService.getAppVersion());

final announcementsProvider = FutureProvider<List<AppAnnouncement>>((ref) {
  return BackendService.fetchAnnouncements(ref.watch(localeProvider).languageCode);
});

/// IDs of announcements the user closed, remembered across launches.
class DismissedAnnouncementsNotifier extends StateNotifier<Set<int>> {
  DismissedAnnouncementsNotifier() : super(const {}) {
    _load();
  }

  static const _key = 'dismissed_announcement_ids';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_key) ?? const [];
      if (mounted) state = {...state, ...ids.map(int.tryParse).whereType<int>()};
    } catch (_) {}
  }

  Future<void> dismiss(int id) async {
    state = {...state, id};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, state.map((e) => '$e').toList());
    } catch (_) {}
  }
}

final dismissedAnnouncementsProvider =
    StateNotifierProvider<DismissedAnnouncementsNotifier, Set<int>>(
  (ref) => DismissedAnnouncementsNotifier(),
);

/// The `latest_version` the user chose "Later" on, so the optional update
/// banner stays hidden until an even newer version is published.
class DismissedUpdateNotifier extends StateNotifier<String> {
  DismissedUpdateNotifier() : super('') {
    _load();
  }

  static const _key = 'dismissed_update_version';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_key) ?? '';
      if (mounted && state.isEmpty) state = v;
    } catch (_) {}
  }

  Future<void> dismiss(String version) async {
    state = version;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, version);
    } catch (_) {}
  }
}

final dismissedUpdateProvider =
    StateNotifierProvider<DismissedUpdateNotifier, String>((ref) => DismissedUpdateNotifier());

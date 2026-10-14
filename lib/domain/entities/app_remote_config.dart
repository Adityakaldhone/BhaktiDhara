/// Admin-controlled settings served by `/api/v1/config`.
class AppRemoteConfig {
  const AppRemoteConfig({
    this.minSupportedVersion = '',
    this.latestVersion = '',
    this.updateUrl = '',
    this.forceUpdate = false,
    this.maintenanceMode = false,
    this.maintenanceMessage = '',
    this.featureFlags = const {},
  });

  static const horoscope = 'horoscope';
  static const panchang = 'panchang';
  static const jaap = 'jaap';
  static const bhajan = 'bhajan';
  static const ads = 'ads';
  static const premiumPaywall = 'premium_paywall';
  static const statusCards = 'status_cards';
  static const statusCardPhoto = 'status_card_photo';

  final String minSupportedVersion;
  final String latestVersion;
  final String updateUrl;
  final bool forceUpdate;
  final bool maintenanceMode;
  final String maintenanceMessage;
  final Map<String, bool> featureFlags;

  /// A flag the server hasn't sent counts as enabled, so features keep
  /// working offline or against an older backend.
  bool isEnabled(String flag) => featureFlags[flag] ?? true;

  /// Returns true if the user must update immediately before using the app.
  /// Triggers only when [forceUpdate] is enabled AND the current version is below
  /// the minimum supported version (or latest version if min_supported_version is empty).
  bool mustUpdate(String currentVersion) {
    final cur = currentVersion.trim();
    if (cur.isEmpty || !forceUpdate) return false;

    final threshold = minSupportedVersion.isNotEmpty ? minSupportedVersion : latestVersion;
    if (threshold.isNotEmpty && compareVersions(cur, threshold) < 0) {
      return true;
    }
    return false;
  }

  /// Returns true if an optional update is available (latestVersion > currentVersion).
  bool canUpdate(String currentVersion) {
    final cur = currentVersion.trim();
    return cur.isNotEmpty &&
        latestVersion.isNotEmpty &&
        compareVersions(cur, latestVersion) < 0;
  }

  factory AppRemoteConfig.fromJson(Map<String, dynamic> json) {
    final flags = json['feature_flags'];
    return AppRemoteConfig(
      minSupportedVersion: _str(json['min_supported_version']),
      latestVersion: _str(json['latest_version']),
      updateUrl: _str(json['update_url']),
      forceUpdate: json['force_update'] == true,
      maintenanceMode: json['maintenance_mode'] == true,
      maintenanceMessage: _str(json['maintenance_message']),
      featureFlags: flags is Map
          ? {
              for (final e in flags.entries)
                if (e.value is bool) e.key.toString(): e.value as bool,
            }
          : const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'min_supported_version': minSupportedVersion,
        'latest_version': latestVersion,
        'update_url': updateUrl,
        'force_update': forceUpdate,
        'maintenance_mode': maintenanceMode,
        'maintenance_message': maintenanceMessage,
        'feature_flags': featureFlags,
      };

  static String _str(Object? v) => v?.toString().trim() ?? '';

  /// Compares dotted versions numerically ("1.0.10" > "1.0.9");
  /// Also compares build numbers if present ("1.0.7+8" > "1.0.7+7").
  /// Returns <0, 0 or >0.
  static int compareVersions(String a, String b) {
    final cleanA = a.trim();
    final cleanB = b.trim();
    if (cleanA.isEmpty || cleanB.isEmpty) return 0;
    if (cleanA == cleanB) return 0;

    final partsA = cleanA.split('+');
    final partsB = cleanB.split('+');

    List<int> parseDots(String v) => v
        .split('.')
        .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();

    final semA = parseDots(partsA[0]);
    final semB = parseDots(partsB[0]);

    final maxLen = semA.length > semB.length ? semA.length : semB.length;
    for (var i = 0; i < maxLen; i++) {
      final x = i < semA.length ? semA[i] : 0;
      final y = i < semB.length ? semB[i] : 0;
      if (x != y) return x.compareTo(y);
    }

    // If semver is equal, compare build numbers if both provide them
    if (partsA.length > 1 && partsB.length > 1) {
      final buildA = int.tryParse(partsA[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final buildB = int.tryParse(partsB[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (buildA != buildB) return buildA.compareTo(buildB);
    }

    return 0;
  }
}

/// A live in-app announcement from `/api/v1/announcements`.
class AppAnnouncement {
  const AppAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    this.link = '',
  });

  final int id;
  final String title;
  final String body;
  final String link;

  static AppAnnouncement? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final title = json['title']?.toString().trim() ?? '';
    if (id is! int || title.isEmpty) return null;
    return AppAnnouncement(
      id: id,
      title: title,
      body: json['body']?.toString().trim() ?? '',
      link: json['link']?.toString().trim() ?? '',
    );
  }
}

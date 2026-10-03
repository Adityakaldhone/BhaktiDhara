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

  bool mustUpdate(String currentVersion) =>
      forceUpdate &&
      minSupportedVersion.isNotEmpty &&
      compareVersions(currentVersion, minSupportedVersion) < 0;

  bool canUpdate(String currentVersion) =>
      latestVersion.isNotEmpty && compareVersions(currentVersion, latestVersion) < 0;

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

  /// Compares dotted versions numerically ("1.0.10" > "1.0.9"); ignores any
  /// "+build" suffix. Returns <0, 0 or >0.
  static int compareVersions(String a, String b) {
    List<int> parts(String v) => v
        .split('+')
        .first
        .split('.')
        .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final pa = parts(a), pb = parts(b);
    for (var i = 0; i < pa.length || i < pb.length; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
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

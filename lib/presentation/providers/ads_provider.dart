import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_remote_config.dart';
import 'premium_provider.dart';
import 'remote_config_provider.dart';

/// Ads are shown unless the admin switched them off or the user is VIP.
final showAdsProvider = Provider<bool>((ref) {
  return !kIsWeb &&
      ref.watch(featureEnabledProvider(AppRemoteConfig.ads)) &&
      !ref.watch(isPremiumProvider);
});

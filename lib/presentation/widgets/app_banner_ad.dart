import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/theme/theme.dart';
import '../providers/ads_provider.dart';

/// Standard 320×50 banner pinned at the bottom of a screen. Takes no space
/// until an ad has loaded, and none at all for VIP users.
class AppBannerAd extends ConsumerStatefulWidget {
  const AppBannerAd({super.key, required this.adUnitId});

  final String adUnitId;

  @override
  ConsumerState<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends ConsumerState<AppBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!ref.read(showAdsProvider)) return;
    _ad = BannerAd(
      adUnitId: widget.adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _ad = null;
        },
        onPaidEvent: AnalyticsService.onPaidEvent('banner'),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null || !ref.watch(showAdsProvider)) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: Container(
        color: MandirTheme.backgroundCream,
        alignment: Alignment.center,
        height: ad.size.height.toDouble(),
        child: SizedBox(
          width: ad.size.width.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}

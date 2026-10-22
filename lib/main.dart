import 'core/analytics/clarity_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'core/theme/theme.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/premium_provider.dart';
import 'presentation/providers/remote_config_provider.dart';
import 'presentation/providers/subscription_provider.dart';
import 'presentation/providers/horoscope_provider.dart';
import 'presentation/providers/review_provider.dart';
import 'data/repositories/recent_deities_repository.dart';
import 'presentation/providers/bhakti_darshan_providers.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/widgets/remote_notices.dart';
import 'services/app_update_service.dart';
import 'services/backend_service.dart';
import 'services/push_notification_service.dart';
import 'services/rewarded_ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load essential local preferences concurrently in a single batch (sub-50ms)
  final results = await Future.wait([
    loadUserLanguageCode(),
    createReviewServiceOverride(),
    RecentDeitiesRepository.getInitialRecentDeities(),
    BackendService.loadCachedRemoteConfig(),
  ]);

  final userLanguageCode = results[0] as String?;
  final reviewOverride = results[1] as Override;
  final cachedRecentDeities = results[2] as List<String>;

  runApp(
    ClarityService.wrapWithClarity(
      projectId: _clarityProjectId,
      child: ProviderScope(
        overrides: [
          reviewOverride,
          userLanguageCodeProvider.overrideWithValue(userLanguageCode),
          initialRecentDeitiesProvider.overrideWithValue(cachedRecentDeities),
        ],
        child: const NityaAartiApp(),
      ),
    ),
  );
}

const _clarityProjectId = 'yrz6tdkktv';

class NityaAartiApp extends ConsumerStatefulWidget {
  const NityaAartiApp({super.key});

  @override
  ConsumerState<NityaAartiApp> createState() => _NityaAartiAppState();
}

class _NityaAartiAppState extends ConsumerState<NityaAartiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. Initialize AdMob and preload ads quietly in background without delaying frame 0
      if (!kIsWeb) {
        MobileAds.instance.initialize();
        RewardedAdService.instance.preload();
      }

      // 2. Background analytics ping & Clarity session tagging
      final userLang = ref.read(userLanguageCodeProvider);
      BackendService.sendAnonymousPing(
        locale: resolveStartupLocale(userLang).languageCode,
      );
      BackendService.getAnonymousDeviceId().then(ClarityService.setUserId);

      // 3. Eagerly initialize subscription & 7-day free trial state
      ref.read(subscriptionProvider);
      await PushNotificationService.init();
      if (!mounted) return;
      _syncPushTopics();
      PushNotificationService.handlePendingTap();
      // 4. Silently check for background flexible updates via Google Play
      AppUpdateService.tryPlayStoreFlexibleUpdate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(remoteConfigProvider.notifier).refresh();
      ref.invalidate(appVersionProvider);
      ref.invalidate(announcementsProvider);
    }
  }

  void _syncPushTopics() {
    final rashi = ref.read(selectedRashiProvider);
    final isMorningOn = ref.read(morningReminderEnabledProvider);
    PushNotificationService.syncTopics(
      locale: ref.read(localeProvider).languageCode,
      isVip: ref.read(isPremiumProvider),
      rashiId: rashi.id,
      morningReminderEnabled: isMorningOn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    ref.listen(localeProvider, (_, _) => _syncPushTopics());
    ref.listen(isPremiumProvider, (_, _) => _syncPushTopics());
    ref.listen(selectedRashiProvider, (_, _) => _syncPushTopics());
    ref.listen(morningReminderEnabledProvider, (_, _) => _syncPushTopics());

    return MaterialApp(
      title: 'BhaktiDhara: Aarti & Chalisa',
      debugShowCheckedModeBanner: false,
      navigatorKey: PushNotificationService.navigatorKey,
      theme: MandirTheme.lightTheme,
      locale: currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('hi'), // Hindi
        Locale('mr'), // Marathi
      ],
      builder: (context, child) => ForceUpdateGate(child: child!),
      home: const MandirDashboardScreen(),
    );
  }
}

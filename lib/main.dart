import 'core/analytics/analytics_service.dart';
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
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/widgets/remote_notices.dart';
import 'services/app_update_service.dart';
import 'services/backend_service.dart';
import 'services/push_notification_service.dart';
import 'services/rewarded_ad_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AnalyticsService.init();

  // Instant launch: Render widget tree immediately on frame 0 without blocking on disk/network I/O
  runApp(
    ClarityService.wrapWithClarity(
      projectId: _clarityProjectId,
      child: const ProviderScope(
        child: NityaAartiApp(),
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
      // 1. Asynchronously restore user-selected language if previously saved
      final savedLang = await loadUserLanguageCode();
      if (savedLang != null && mounted) {
        ref.read(localeProvider.notifier).state = Locale(savedLang);
      }

      // 2. Pre-warm remote config cache in background
      BackendService.loadCachedRemoteConfig();

      // 3. Initialize AdMob and preload ads quietly in background without delaying frame 0
      if (!kIsWeb) {
        MobileAds.instance.initialize();
        RewardedAdService.instance.preload();
      }

      // 4. Background analytics ping & Clarity session tagging
      final userLang = ref.read(userLanguageCodeProvider);
      BackendService.sendAnonymousPing(
        locale: resolveStartupLocale(userLang).languageCode,
      );
      BackendService.getAnonymousDeviceId().then(ClarityService.setUserId);
      AnalyticsService.logAppLaunch();
      BackendService.syncAppInstanceId(trigger: 'app_launch');

      // 5. Eagerly initialize subscription & 7-day free trial state
      ref.read(subscriptionProvider);
      await PushNotificationService.init();
      if (!mounted) return;
      _syncPushTopics();
      PushNotificationService.handlePendingTap();

      // 6. Silently check for background flexible updates via Google Play
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

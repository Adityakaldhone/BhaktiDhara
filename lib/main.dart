import 'core/analytics/analytics_service.dart';
import 'features/voice_agent/domain/home_voice_commands.dart';
import 'features/voice_agent/presentation/widgets/bhakti_wake_host.dart';
import 'core/analytics/clarity_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'core/theme/theme.dart';
import 'presentation/providers/ads_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/premium_provider.dart';
import 'presentation/providers/remote_catalog_provider.dart';
import 'presentation/providers/remote_config_provider.dart';
import 'presentation/providers/subscription_provider.dart';
import 'presentation/providers/horoscope_provider.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/language_selection_screen.dart';
import 'presentation/widgets/remote_notices.dart';
import 'services/aarti_reminder_service.dart';
import 'services/akhand_diya_service.dart';
import 'services/app_open_ad_service.dart';
import 'services/app_update_service.dart';
import 'services/backend_service.dart';
import 'services/push_notification_service.dart';
import 'services/rewarded_interstitial_ad_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep decoded image memory bounded on Android 11 and lower-RAM devices.
  PaintingBinding.instance.imageCache
    ..maximumSize = 120
    ..maximumSizeBytes = 40 << 20;
  AnalyticsService.init();

  // Instant launch: Render widget tree immediately on frame 0 without blocking on disk/network I/O
  runApp(
    const bool.fromEnvironment('PERF_NO_CLARITY')
        ? const ProviderScope(child: NityaAartiApp())
        : ClarityService.wrapWithClarity(
            projectId: _clarityProjectId,
            child: const ProviderScope(child: NityaAartiApp()),
          ),
  );
}

const _clarityProjectId = 'yrz6tdkktv';

class NityaAartiApp extends ConsumerStatefulWidget {
  const NityaAartiApp({super.key});

  @override
  ConsumerState<NityaAartiApp> createState() => _NityaAartiAppState();
}

class _NityaAartiAppState extends ConsumerState<NityaAartiApp>
    with WidgetsBindingObserver {
  static const _resumeRefreshCooldown = Duration(seconds: 60);
  DateTime? _lastResumeRefreshAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. Asynchronously restore user-selected language if previously saved
      final isNewUser = await shouldShowLanguageSelection();
      AppOpenAdService.instance.setOnboardingPending(isNewUser);
      final savedLang = await loadUserLanguageCode();
      if (savedLang != null && mounted) {
        ref.read(localeProvider.notifier).state = Locale(savedLang);
      }

      // 2. Pre-warm remote config + catalog caches in background
      BackendService.loadCachedRemoteConfig();
      BackendService.loadCachedRemoteCatalog();
      ref.read(remoteCatalogProvider); // starts network refresh

      // 3. Initialize AdMob after startup UI & permission prompts settle so
      // Dynamite classloading & Chromium WebView don't stall Android <= 11 startup.
      if (!kIsWeb) {
        Future.delayed(const Duration(milliseconds: 2000), () async {
          await MobileAds.instance.initialize();
          if (!mounted) return;
          final adsEnabled = ref.read(showAdsProvider);
          RewardedInterstitialAdService.instance.preload(adsEnabled: adsEnabled);
          if (isNewUser) {
            AppOpenAdService.instance.preload(adsEnabled: adsEnabled);
          } else {
            AppOpenAdService.instance.showForExistingUserIfEligible(
              adsEnabled: adsEnabled,
              waitForLoad: true,
            );
          }
        });
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
      AartiReminderService.reapply(ref.read(localeProvider).languageCode);
      AkhandDiyaService.reapply(ref.read(localeProvider).languageCode);
      PushNotificationService.handlePendingTap();

      // 6. Google Play in-app update (staggered by 4s to prevent startup GMS Binder lock contention)
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          AppUpdateService.checkForUpdateAutomatically();
        }
      });
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
      if (mounted) {
        AppOpenAdService.instance.showForExistingUserIfEligible(
          adsEnabled: ref.read(showAdsProvider),
        );
      }
      final now = DateTime.now();
      if (_lastResumeRefreshAt != null &&
          now.difference(_lastResumeRefreshAt!) < _resumeRefreshCooldown) {
        return;
      }
      _lastResumeRefreshAt = now;
      ref.read(remoteConfigProvider.notifier).refresh();
      ref.read(remoteCatalogProvider.notifier).refresh();
      ref.invalidate(appVersionProvider);
      ref.invalidate(announcementsProvider);
      ref.invalidate(inAppNotificationsProvider);
      AppUpdateService.checkForUpdateAutomatically();
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
      scaffoldMessengerKey: AppUpdateService.scaffoldMessengerKey,
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
      builder: (context, child) => ForceUpdateGate(
        child: kEnableBhaktiAi
            ? BhaktiWakeHost(
                navigator: PushNotificationService.navigatorKey,
                child: child!,
              )
            : child!,
      ),
      home: const _StartupGate(),
    );
  }
}

/// Shows the language picker on first launch, the dashboard afterwards.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  final Future<bool> _showLanguageSelection = shouldShowLanguageSelection();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _showLanguageSelection,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(backgroundColor: MandirTheme.backgroundCream);
        }
        return snapshot.data!
            ? const LanguageSelectionScreen()
            : const MandirDashboardScreen();
      },
    );
  }
}

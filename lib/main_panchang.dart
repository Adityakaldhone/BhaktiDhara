import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/analytics/analytics_service.dart';
import 'core/analytics/clarity_service.dart';
import 'core/theme/theme.dart';
import 'l10n/app_localizations.dart';
import 'presentation/providers/horoscope_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/premium_provider.dart';
import 'presentation/providers/remote_config_provider.dart';
import 'presentation/providers/subscription_provider.dart';
import 'presentation/screens/language_selection_screen.dart';
import 'presentation/screens/panchang_app_dashboard_screen.dart';
import 'presentation/widgets/remote_notices.dart';
import 'services/app_update_service.dart';
import 'services/backend_service.dart';
import 'services/interstitial_ad_service.dart';
import 'services/push_notification_service.dart';
import 'services/rewarded_ad_service.dart';

/// Entry point for the standalone "Sampurna Panchang & Rashifal" app.
/// Package: com.kaldhone.panchang
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AnalyticsService.init();

  runApp(
    ClarityService.wrapWithClarity(
      projectId: _clarityProjectId,
      child: const ProviderScope(
        child: SampurnaPanchangApp(),
      ),
    ),
  );
}

const _clarityProjectId = 'yrz6tdkktv';

class SampurnaPanchangApp extends ConsumerStatefulWidget {
  const SampurnaPanchangApp({super.key});

  @override
  ConsumerState<SampurnaPanchangApp> createState() => _SampurnaPanchangAppState();
}

class _SampurnaPanchangAppState extends ConsumerState<SampurnaPanchangApp>
    with WidgetsBindingObserver {
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

      // 3. Initialize AdMob and preload ads quietly in background
      if (!kIsWeb) {
        MobileAds.instance.initialize();
        RewardedAdService.instance.preload();
        InterstitialAdService.instance.preload();
      }

      // 4. Background analytics ping & Clarity session tagging
      final userLang = ref.read(userLanguageCodeProvider);
      BackendService.sendAnonymousPing(
        locale: resolveStartupLocale(userLang).languageCode,
      );
      BackendService.getAnonymousDeviceId().then(ClarityService.setUserId);
      AnalyticsService.logAppLaunch();
      BackendService.syncAppInstanceId(trigger: 'panchang_app_launch');

      // 5. Eagerly initialize subscription & 7-day free trial state
      ref.read(subscriptionProvider);
      await PushNotificationService.init();
      if (!mounted) return;
      _syncPushTopics();
      PushNotificationService.handlePendingTap();

      // 6. Google Play in-app update
      AppUpdateService.checkForUpdateAutomatically();
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

    final appTitle = currentLocale.languageCode == 'hi'
        ? 'संपूर्ण पंचांग एवं राशिफल'
        : (currentLocale.languageCode == 'mr'
            ? 'संपूर्ण पंचांग आणि राशीभविष्य'
            : 'Sampurna Panchang & Rashifal');

    return MaterialApp(
      title: appTitle,
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
      builder: (context, child) => ForceUpdateGate(child: child!),
      home: const _PanchangStartupGate(),
    );
  }
}

/// Shows the language picker on first launch, the Panchang dashboard afterwards.
class _PanchangStartupGate extends StatefulWidget {
  const _PanchangStartupGate();

  @override
  State<_PanchangStartupGate> createState() => _PanchangStartupGateState();
}

class _PanchangStartupGateState extends State<_PanchangStartupGate> {
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
            : const PanchangAppDashboardScreen();
      },
    );
  }
}


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'core/theme/theme.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/premium_provider.dart';
import 'presentation/providers/subscription_provider.dart';
import 'presentation/providers/horoscope_provider.dart';
import 'presentation/providers/review_provider.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'services/backend_service.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    MobileAds.instance.initialize();
  }
  // Send anonymous install/active user heartbeat in background (fire-and-forget)
  BackendService.sendAnonymousPing(locale: getInitialDeviceLocale().languageCode);

  // Initialise the review service (tracks distinct open-days, loads prefs)
  final reviewOverride = await createReviewServiceOverride();

  runApp(
    // ProviderScope is required for Riverpod
    ProviderScope(
      overrides: [reviewOverride],
      child: const NityaAartiApp(),
    ),
  );
}

class NityaAartiApp extends ConsumerStatefulWidget {
  const NityaAartiApp({super.key});

  @override
  ConsumerState<NityaAartiApp> createState() => _NityaAartiAppState();
}

class _NityaAartiAppState extends ConsumerState<NityaAartiApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Eagerly initialize subscription & 7-day free trial state
      ref.read(subscriptionProvider);
      await PushNotificationService.init();
      if (!mounted) return;
      _syncPushTopics();
      PushNotificationService.handlePendingTap();
    });
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
      title: 'Digital Mandir',
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
      home: const MandirDashboardScreen(),
    );
  }
}

import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datasources/bhajan_catalog.dart';
import '../data/datasources/catalog.dart';
import '../data/datasources/marathi_aarti_catalog.dart';
import '../domain/entities/aarti_item.dart';
import '../domain/entities/horoscope.dart';
import '../firebase_options.dart';
import '../presentation/screens/altar_screen.dart';
import '../presentation/screens/bhajan_screen.dart';
import '../presentation/screens/horoscope_screen.dart';
import '../presentation/screens/jaap_counter_screen.dart';
import '../presentation/screens/panchang_screen.dart';
import 'backend_service.dart';

/// Runs in a separate isolate when a push arrives while the app is terminated
/// or in the background. Notification-type messages are displayed by the OS.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Firebase Cloud Messaging integration: permissions, token sync with the
/// backend, topic targeting (language / VIP / platform) and tap deep-links.
class PushNotificationService {
  PushNotificationService._();

  /// Attached to [MaterialApp.navigatorKey] so taps can open screens.
  static final navigatorKey = GlobalKey<NavigatorState>();

  static const _channel = AndroidNotificationChannel(
    'bhaktidhara_general',
    'BhaktiDhara updates',
    description: 'Aarti reminders, festival alerts and announcements',
    importance: Importance.high,
  );

  static const _topicsKey = 'push_subscribed_topics';
  static const _allTopics = {'all', 'lang_mr', 'lang_hi', 'lang_en', 'vip', 'free', 'android', 'ios'};

  static final _local = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _permissionGranted = false;
  static String? _token;
  static Map<String, dynamic>? _pendingTap;

  static String? get token => _token;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Initializes Firebase + notifications. Safe to call once at startup; never throws.
  static Future<void> init() async {
    if (_initialized || !_supported) return;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload == null || payload.isEmpty) return;
          try {
            _handleTap(Map<String, dynamic>.from(jsonDecode(payload) as Map));
          } catch (_) {}
        },
      );
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
      _permissionGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      // iOS shows banners natively in the foreground; Android needs a local notification.
      await messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleTap(m.data));
      messaging.onTokenRefresh.listen(_onToken);

      final initial = await messaging.getInitialMessage();
      if (initial != null) _pendingTap = initial.data;

      _initialized = true;
      await _onToken(await _safeGetToken(messaging));
    } catch (e) {
      debugPrint('Push init failed: $e');
    }
  }

  static Future<String?> _safeGetToken(FirebaseMessaging messaging) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS && await messaging.getAPNSToken() == null) {
        // APNs token arrives shortly after launch on real devices; null on simulators.
        await Future<void>.delayed(const Duration(seconds: 3));
        if (await messaging.getAPNSToken() == null) return null;
      }
      return await messaging.getToken();
    } catch (e) {
      debugPrint('FCM token unavailable: $e');
      return null;
    }
  }

  static Future<void> _onToken(String? token) async {
    if (token == null || token.isEmpty) return;
    _token = token;
    await BackendService.registerPushToken(token, enabled: _permissionGranted);
  }

  /// Subscribes the device to targeting topics and drops stale ones
  /// (e.g. after a language change, VIP upgrade, or Rashi selection).
  static Future<void> syncTopics({
    required String locale,
    required bool isVip,
    String? rashiId,
    bool morningReminderEnabled = true,
  }) async {
    if (!_initialized) return;
    final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    final allKnown = {
      ..._allTopics,
      'morning_horoscope',
      for (final r in kAllRashis) 'rashi_${r.id}',
    };
    final wanted = {
      'all',
      'lang_$locale',
      isVip ? 'vip' : 'free',
      platform,
      if (morningReminderEnabled) 'morning_horoscope',
      if (rashiId != null && rashiId.isNotEmpty) 'rashi_${rashiId.toLowerCase()}',
    }.intersection(allKnown);

    try {
      final prefs = await SharedPreferences.getInstance();
      final current = (prefs.getStringList(_topicsKey) ?? const []).toSet();
      if (current.length == wanted.length && current.containsAll(wanted)) return;
      final messaging = FirebaseMessaging.instance;
      for (final topic in current.difference(wanted)) {
        await messaging.unsubscribeFromTopic(topic);
      }
      for (final topic in wanted.difference(current)) {
        await messaging.subscribeToTopic(topic);
      }
      await prefs.setStringList(_topicsKey, wanted.toList());
    } catch (e) {
      debugPrint('Topic sync failed: $e');
    }
  }

  /// Call after the first frame so a notification that launched the app can navigate.
  static void handlePendingTap() {
    final data = _pendingTap;
    _pendingTap = null;
    if (data != null) _handleTap(data);
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final notification = message.notification;
    if (notification == null) return;
    await _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFFF9933),
          styleInformation: BigTextStyleInformation(notification.body ?? ''),
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static void _handleTap(Map<String, dynamic> data) {
    final campaignId = data['campaignId']?.toString();
    BackendService.trackEvent('push_open', item: campaignId ?? 'unknown');

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingTap = data;
      return;
    }
    final screen = _screenFor(data);
    if (screen != null) {
      navigator.push(MaterialPageRoute(builder: (_) => screen));
    }
  }

  static Widget? _screenFor(Map<String, dynamic> data) {
    switch (data['route']?.toString()) {
      case 'panchang':
        return const PanchangScreen();
      case 'jaap':
        return const JaapCounterScreen();
      case 'horoscope':
        return HoroscopeScreen(
          initialRashiId: data['rashi']?.toString() ?? data['rashiId']?.toString(),
          focusSection: data['focus']?.toString(),
        );
      case 'bhajan':
        return const BhajanScreen();
      case 'aarti':
        final aarti = _findAarti(data['aartiId']?.toString());
        return aarti == null ? null : AartiAltarScreen(aarti: aarti);
      default:
        return null;
    }
  }

  /// Displays an immediate local notification simulating the 6:00 AM curiosity push.
  static Future<void> showMorningHoroscopePreview({
    required String rashiId,
    required String rashiName,
    required String langCode,
  }) async {
    final title = langCode == 'mr'
        ? '🚩 आजचे राशीभविष्य: $rashiName राशीसाठी मोठे ग्रहसंकेत!'
        : (langCode == 'hi'
            ? '🚩 आज का राशिफल: $rashiName राशि के लिए बड़े ग्रह संकेत!'
            : '🚩 Daily Horoscope: Auspicious signs for $rashiName!');

    final body = langCode == 'mr'
        ? 'आज धनलाभ व प्रगतीचे मोठे योग! पण दुपारी ही एक चूक टाळा... ➔ ॲपमध्ये पहा'
        : (langCode == 'hi'
            ? 'आज धन लाभ व उन्नति के योग! लेकिन दोपहर बाद यह गलती न करें... ➔ ऐप में देखें'
            : 'Planetary alignments favor progress today! But avoid this one mistake... ➔ Open');

    await _local.show(
      id: 60000 + rashiId.hashCode.abs() % 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFFF9933),
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      payload: jsonEncode({
        'route': 'horoscope',
        'rashi': rashiId,
        'focus': 'caution',
      }),
    );
  }

  static AartiItem? _findAarti(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final item in [...kDevotionalCatalog, ...kMarathiAartiCatalog, ...kBhajanCatalog]) {
      if (item.id == id) return item;
    }
    return null;
  }
}

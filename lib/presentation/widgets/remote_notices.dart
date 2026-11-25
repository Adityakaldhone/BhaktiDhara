import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/app_remote_config.dart';
import '../../services/app_update_service.dart';
import '../../services/backend_service.dart';
import '../../services/push_notification_service.dart';
import '../providers/locale_provider.dart';
import '../providers/remote_config_provider.dart';
import '../screens/force_update_screen.dart';

String _t(String lang, {required String en, required String hi, required String mr}) =>
    lang == 'en' ? en : (lang == 'hi' ? hi : mr);

Future<void> _open(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

/// Replaces the entire app tree with the un-dismissible [ForceUpdateScreen]
/// when the admin forces an update or this build is below `min_supported_version`.
class ForceUpdateGate extends ConsumerWidget {
  const ForceUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigProvider);
    final version = ref.watch(appVersionProvider).valueOrNull;

    if (version != null && config.mustUpdate(version)) {
      return const ForceUpdateScreen();
    }
    return child;
  }
}

final _showUpdateBannerProvider = Provider<bool>((ref) {
  final config = ref.watch(remoteConfigProvider);
  final version = ref.watch(appVersionProvider).valueOrNull;
  return version != null &&
      config.canUpdate(version) &&
      !config.mustUpdate(version) &&
      ref.watch(dismissedUpdateProvider) != config.latestVersion;
});

/// Whether [AppNoticeBanners] currently shows anything.
final appNoticesVisibleProvider = Provider<bool>((ref) {
  return ref.watch(remoteConfigProvider).maintenanceMode || ref.watch(_showUpdateBannerProvider);
});

/// Undismissed announcements + inbox messages waiting on home.
final homeInboxBadgeCountProvider = Provider<int>((ref) {
  final dismissed = ref.watch(dismissedAnnouncementsProvider);
  final announcements =
      (ref.watch(announcementsProvider).valueOrNull ?? const <AppAnnouncement>[])
          .where((a) => !dismissed.contains(a.id))
          .length;
  final inbox =
      (ref.watch(inAppNotificationsProvider).valueOrNull ?? const <InAppNotification>[])
          .length;
  return announcements + inbox;
});

/// Maintenance notice and optional "new version" prompt, shown above every tab.
class AppNoticeBanners extends ConsumerWidget {
  const AppNoticeBanners({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigProvider);
    final showUpdate = ref.watch(_showUpdateBannerProvider);
    final lang = ref.watch(localeProvider).languageCode;
    if (!config.maintenanceMode && !showUpdate) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (config.maintenanceMode)
          _Banner(
            icon: Icons.construction_rounded,
            color: const Color(0xFF8B1D18),
            text: config.maintenanceMessage.isNotEmpty
                ? config.maintenanceMessage
                : _t(lang,
                    en: 'We are upgrading the mandir servers. Some online features may be unavailable.',
                    hi: 'मंदिर सर्वर अपग्रेड हो रहे हैं। कुछ ऑनलाइन सुविधाएं अभी उपलब्ध नहीं हो सकतीं।',
                    mr: 'मंदिर सर्व्हर अपग्रेड होत आहेत. काही ऑनलाइन सुविधा सध्या उपलब्ध नसतील.'),
          ),
        if (showUpdate)
          _Banner(
            icon: Icons.system_update_rounded,
            color: MandirTheme.primarySaffron,
            text: _t(lang,
                en: 'A new version (${config.latestVersion}) is available.',
                hi: 'नया संस्करण (${config.latestVersion}) उपलब्ध है।',
                mr: 'नवीन आवृत्ती (${config.latestVersion}) उपलब्ध आहे.'),
            actionLabel: _t(lang, en: 'Update', hi: 'अपडेट', mr: 'अपडेट'),
            onAction: () async {
              final didUpdate = await AppUpdateService.tryPlayStoreFlexibleUpdate();
              if (!didUpdate) {
                await AppUpdateService.openStore(customUrl: config.updateUrl);
              }
            },
            onClose: () =>
                ref.read(dismissedUpdateProvider.notifier).dismiss(config.latestVersion),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.text,
    this.actionLabel,
    this.onAction,
    this.onClose,
  });

  final IconData icon;
  final Color color;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.mukta(
                  fontSize: 15,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.mukta(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            if (onClose != null)
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact bell on the home header; opens the inbox sheet.
class HomeNotificationsButton extends ConsumerWidget {
  const HomeNotificationsButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(homeInboxBadgeCountProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final size = compact ? 36.0 : 40.0;

    return Tooltip(
      message: _t(lang, en: 'Notifications', hi: 'सूचनाएं', mr: 'सूचना'),
      child: Material(
        color: MandirTheme.surfaceWhite,
        shape: const CircleBorder(),
        elevation: 1.5,
        shadowColor: Colors.black26,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => showHomeNotificationsSheet(context, ref),
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  count > 0 ? Icons.notifications_rounded : Icons.notifications_none_rounded,
                  color: MandirTheme.secondaryMaroon,
                  size: compact ? 20 : 22,
                ),
                if (count > 0)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      height: 16,
                      decoration: BoxDecoration(
                        color: MandirTheme.primarySaffron,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: GoogleFonts.mukta(
                          fontSize: 10,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens announcements + per-device inbox without crowding the home scroll.
Future<void> showHomeNotificationsSheet(BuildContext context, WidgetRef ref) {
  final lang = ref.read(localeProvider).languageCode;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MandirTheme.backgroundCream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Consumer(
            builder: (context, sheetRef, _) {
              final dismissed = sheetRef.watch(dismissedAnnouncementsProvider);
              final announcements =
                  (sheetRef.watch(announcementsProvider).valueOrNull ??
                          const <AppAnnouncement>[])
                      .where((a) => !dismissed.contains(a.id))
                      .toList();
              final inbox = sheetRef.watch(inAppNotificationsProvider).valueOrNull ??
                  const <InAppNotification>[];
              final loading = sheetRef.watch(announcementsProvider).isLoading ||
                  sheetRef.watch(inAppNotificationsProvider).isLoading;

              return Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MandirTheme.chipBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_rounded,
                          color: MandirTheme.secondaryMaroon,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _t(lang, en: 'Notifications', hi: 'सूचनाएं', mr: 'सूचना'),
                            style: GoogleFonts.mukta(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: MandirTheme.secondaryMaroon,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded, color: MandirTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8DCC8)),
                  Expanded(
                    child: loading && announcements.isEmpty && inbox.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(
                                color: MandirTheme.primarySaffron,
                              ),
                            ),
                          )
                        : announcements.isEmpty && inbox.isEmpty
                            ? ListView(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                                children: [
                                  const Icon(
                                    Icons.notifications_off_outlined,
                                    size: 48,
                                    color: MandirTheme.textMuted,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _t(
                                      lang,
                                      en: 'No notifications right now.',
                                      hi: 'अभी कोई सूचना नहीं है।',
                                      mr: 'सध्या कोणतीही सूचना नाही.',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.mukta(
                                      fontSize: 16,
                                      color: MandirTheme.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : ListView(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                                children: [
                                  for (final n in inbox)
                                    _InAppInboxCard(
                                      notification: n,
                                      onShown: () {
                                        if (!n.opened) {
                                          BackendService.openInAppNotification(n.id);
                                        }
                                      },
                                      onOpen: () {
                                        final data = n.toPushData();
                                        if (data['route'] == null) return;
                                        Navigator.of(context).maybePop();
                                        PushNotificationService.openFromData(data);
                                      },
                                      onDismiss: () async {
                                        await BackendService.dismissInAppNotification(n.id);
                                        sheetRef.invalidate(inAppNotificationsProvider);
                                      },
                                    ),
                                  for (final a in announcements)
                                    _AnnouncementCard(
                                      announcement: a,
                                      lang: lang,
                                      onDismiss: () => sheetRef
                                          .read(dismissedAnnouncementsProvider.notifier)
                                          .dismiss(a.id),
                                    ),
                                ],
                              ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.lang,
    required this.onDismiss,
  });

  final AppAnnouncement announcement;
  final String lang;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF3D6), Color(0xFFFBE3B8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8C98A), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text('📢', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    style: GoogleFonts.mukta(
                      fontSize: 18,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: MandirTheme.secondaryMaroon,
                    ),
                  ),
                  if (a.body.isNotEmpty)
                    Text(
                      a.body,
                      style: GoogleFonts.mukta(
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: MandirTheme.textDark,
                      ),
                    ),
                  if (a.link.isNotEmpty)
                    TextButton(
                      onPressed: () => _open(a.link),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: MandirTheme.primarySaffron,
                      ),
                      child: Text(
                        _t(lang, en: 'Open →', hi: 'खोलें →', mr: 'उघडा →'),
                        style: GoogleFonts.mukta(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 20, color: MandirTheme.textMuted),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _InAppInboxCard extends StatefulWidget {
  const _InAppInboxCard({
    required this.notification,
    required this.onShown,
    required this.onDismiss,
    this.onOpen,
  });

  final InAppNotification notification;
  final VoidCallback onShown;
  final Future<void> Function() onDismiss;
  final VoidCallback? onOpen;

  @override
  State<_InAppInboxCard> createState() => _InAppInboxCardState();
}

class _InAppInboxCardState extends State<_InAppInboxCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onShown());
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final canOpen = n.route.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: canOpen ? widget.onOpen : null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF81C784), width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text('🔔', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: GoogleFonts.mukta(
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: MandirTheme.secondaryMaroon,
                        ),
                      ),
                      if (n.body.isNotEmpty)
                        Text(
                          n.body,
                          style: GoogleFonts.mukta(
                            fontSize: 15,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                            color: MandirTheme.textDark,
                          ),
                        ),
                      if (canOpen)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Tap to open →',
                            style: GoogleFonts.mukta(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: MandirTheme.primarySaffron,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => widget.onDismiss(),
                  icon: const Icon(Icons.close_rounded, size: 20, color: MandirTheme.textMuted),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/app_remote_config.dart';
import '../providers/locale_provider.dart';
import '../providers/remote_config_provider.dart';

import '../../services/app_update_service.dart';
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

/// Live admin announcements on the home tab; each can be closed for good.
class AnnouncementCards extends ConsumerWidget {
  const AnnouncementCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissed = ref.watch(dismissedAnnouncementsProvider);
    final items = (ref.watch(announcementsProvider).valueOrNull ?? const <AppAnnouncement>[])
        .where((a) => !dismissed.contains(a.id))
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final lang = ref.watch(localeProvider).languageCode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          for (final a in items)
            Padding(
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
                      onPressed: () =>
                          ref.read(dismissedAnnouncementsProvider.notifier).dismiss(a.id),
                      icon: const Icon(Icons.close_rounded, size: 20, color: MandirTheme.textMuted),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

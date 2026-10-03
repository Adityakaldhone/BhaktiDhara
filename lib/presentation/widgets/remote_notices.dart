import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/app_remote_config.dart';
import '../providers/locale_provider.dart';
import '../providers/remote_config_provider.dart';

const _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.kaldhone.bhaktidhara';

String _t(String lang, {required String en, required String hi, required String mr}) =>
    lang == 'en' ? en : (lang == 'hi' ? hi : mr);

String? _updateUrl(AppRemoteConfig config) {
  if (config.updateUrl.isNotEmpty) return config.updateUrl;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return _playStoreUrl;
  return null;
}

Future<void> _open(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

/// Replaces the whole app with an update screen when the admin forces an
/// update and this build is below `min_supported_version`.
class ForceUpdateGate extends ConsumerWidget {
  const ForceUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigProvider);
    final version = ref.watch(appVersionProvider).valueOrNull;
    if (version == null || !config.mustUpdate(version)) return child;

    final lang = ref.watch(localeProvider).languageCode;
    final url = _updateUrl(config);
    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/decorations/om.png', height: 64, width: 64),
                const SizedBox(height: 20),
                Text(
                  _t(lang,
                      en: 'Update required',
                      hi: 'अपडेट आवश्यक है',
                      mr: 'अपडेट आवश्यक आहे'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.yatraOne(fontSize: 26, color: MandirTheme.secondaryMaroon),
                ),
                const SizedBox(height: 12),
                Text(
                  _t(lang,
                      en: 'This version of BhaktiDhara is no longer supported. Please update to continue.',
                      hi: 'भक्तिधारा का यह संस्करण अब समर्थित नहीं है। जारी रखने के लिए कृपया अपडेट करें।',
                      mr: 'भक्तिधाराची ही आवृत्ती आता समर्थित नाही. पुढे सुरू ठेवण्यासाठी कृपया अपडेट करा.'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mukta(fontSize: 17, color: MandirTheme.textDark, height: 1.35),
                ),
                if (url != null) ...[
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () => _open(url),
                    style: FilledButton.styleFrom(
                      backgroundColor: MandirTheme.primarySaffron,
                      minimumSize: const Size(220, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    child: Text(
                      _t(lang, en: 'Update now', hi: 'अभी अपडेट करें', mr: 'आता अपडेट करा'),
                      style: GoogleFonts.mukta(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final _showUpdateBannerProvider = Provider<bool>((ref) {
  final config = ref.watch(remoteConfigProvider);
  final version = ref.watch(appVersionProvider).valueOrNull;
  return version != null &&
      config.canUpdate(version) &&
      ref.watch(dismissedUpdateProvider) != config.latestVersion &&
      _updateUrl(config) != null;
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
            onAction: () => _open(_updateUrl(config)!),
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

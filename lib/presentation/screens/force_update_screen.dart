import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../services/app_update_service.dart';
import '../providers/locale_provider.dart';
import '../providers/remote_config_provider.dart';

/// Full-screen, non-dismissible devotional Force Update Screen.
/// Displayed when the user's installed build is below `min_supported_version`
/// or when the admin has enabled `force_update`.
class ForceUpdateScreen extends ConsumerStatefulWidget {
  const ForceUpdateScreen({super.key});

  @override
  ConsumerState<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends ConsumerState<ForceUpdateScreen> {
  bool _isCheckingAgain = false;
  bool _hasAttemptedImmediate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoTriggerImmediateUpdate());
  }

  Future<void> _autoTriggerImmediateUpdate() async {
    if (_hasAttemptedImmediate || !mounted) return;
    _hasAttemptedImmediate = true;
    // Attempt Google Play's native in-app immediate update modal
    await AppUpdateService.tryPlayStoreImmediateUpdate();
  }

  Future<void> _handleUpdateTap() async {
    final config = ref.read(remoteConfigProvider);
    // 1. Try Google Play immediate update modal first
    final handled = await AppUpdateService.tryPlayStoreImmediateUpdate();
    if (handled) return;

    // 2. Fall back to opening the store (market:// or https://)
    await AppUpdateService.openStore(customUrl: config.updateUrl);
  }

  Future<void> _handleCheckAgain() async {
    if (_isCheckingAgain) return;
    setState(() => _isCheckingAgain = true);

    try {
      ref.invalidate(appVersionProvider);
      await ref.read(remoteConfigProvider.notifier).refresh();
      // If still here and on Android, re-check Play Store
      await AppUpdateService.tryPlayStoreImmediateUpdate();
    } finally {
      if (mounted) {
        setState(() => _isCheckingAgain = false);
      }
    }
  }

  String _t(String lang, {required String en, required String hi, required String mr}) {
    if (lang == 'hi') return hi;
    if (lang == 'mr') return mr;
    return en;
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final config = ref.watch(remoteConfigProvider);
    final version = ref.watch(appVersionProvider).valueOrNull ?? '...';

    final targetVersion = config.minSupportedVersion.isNotEmpty
        ? config.minSupportedVersion
        : (config.latestVersion.isNotEmpty ? config.latestVersion : '');

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: MandirTheme.backgroundCream,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF3D6),
                MandirTheme.backgroundCream,
                Color(0xFFF9E7C4),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sacred glowing emblem
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: MandirTheme.primarySaffron.withValues(alpha: 0.25),
                            blurRadius: 24,
                            spreadRadius: 4,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFE5A93C),
                          width: 2.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        'assets/decorations/om.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Update Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: MandirTheme.primarySaffron.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: MandirTheme.primarySaffron.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.system_security_update_rounded,
                            size: 18,
                            color: MandirTheme.primarySaffron,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _t(
                              lang,
                              en: 'Mandatory Update',
                              hi: 'महत्वपूर्ण अपडेट आवश्यक',
                              mr: 'महत्त्वाचे अपडेट आवश्यक',
                            ),
                            style: GoogleFonts.mukta(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: MandirTheme.primarySaffron,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    Text(
                      _t(
                        lang,
                        en: 'Update BhaktiDhara',
                        hi: 'भक्तिधारा अपडेट करें',
                        mr: 'भक्तिधारा अपडेट करा',
                      ),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.yatraOne(
                        fontSize: 28,
                        color: MandirTheme.secondaryMaroon,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subtitle / Reason
                    Text(
                      _t(
                        lang,
                        en: 'A required update is available with new devotional features, enhanced security, and mandir improvements. Please update to continue your spiritual journey.',
                        hi: 'नए दिव्य भजनों, मंत्रों, पंचांग और सुरक्षा सुधारों के साथ एक आवश्यक अपडेट उपलब्ध है। अपनी साधना जारी रखने के लिए कृपया अभी अपडेट करें।',
                        mr: 'नवीन दिव्य भजने, मंत्र, पंचांग आणि सुरक्षा सुधारणांसह आवश्यक अपडेट उपलब्ध आहे. आपली भक्ती अखंड सुरू ठेवण्यासाठी कृपया आता अपडेट करा.',
                      ),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.mukta(
                        fontSize: 16,
                        height: 1.45,
                        color: MandirTheme.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Version comparison card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFECD4A4)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                _t(lang, en: 'Current Version', hi: 'वर्तमान संस्करण', mr: 'सध्याची आवृत्ती'),
                                style: GoogleFonts.mukta(
                                  fontSize: 12,
                                  color: MandirTheme.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'v$version',
                                style: GoogleFonts.mukta(
                                  fontSize: 15,
                                  color: const Color(0xFF8B1D18),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 28,
                            width: 1,
                            color: const Color(0xFFE5D2B3),
                          ),
                          Column(
                            children: [
                              Text(
                                _t(lang, en: 'Required Version', hi: 'आवश्यक संस्करण', mr: 'आवश्यक आवृत्ती'),
                                style: GoogleFonts.mukta(
                                  fontSize: 12,
                                  color: MandirTheme.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                targetVersion.isNotEmpty ? 'v$targetVersion+' : 'Latest',
                                style: GoogleFonts.mukta(
                                  fontSize: 15,
                                  color: const Color(0xFF1B6A28),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Primary Update Button
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFE65100),
                            MandirTheme.primarySaffron,
                            Color(0xFFD84315),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: MandirTheme.primarySaffron.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _handleUpdateTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        icon: const Icon(Icons.shop_rounded, size: 24),
                        label: Text(
                          _t(
                            lang,
                            en: 'Update Now via Google Play',
                            hi: 'Google Play से अभी अपडेट करें',
                            mr: 'Google Play वरून आता अपडेट करा',
                          ),
                          style: GoogleFonts.mukta(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Check Again / Refresh button
                    TextButton.icon(
                      onPressed: _isCheckingAgain ? null : _handleCheckAgain,
                      style: TextButton.styleFrom(
                        foregroundColor: MandirTheme.secondaryMaroon,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      icon: _isCheckingAgain
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  MandirTheme.secondaryMaroon,
                                ),
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        _isCheckingAgain
                            ? _t(lang, en: 'Checking...', hi: 'जांच रहे हैं...', mr: 'तपासत आहे...')
                            : _t(
                                lang,
                                en: 'Already updated? Check again',
                                hi: 'अपडेट कर चुके हैं? पुनः जांचें',
                                mr: 'अपडेट केले आहे? पुन्हा तपासा',
                              ),
                        style: GoogleFonts.mukta(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

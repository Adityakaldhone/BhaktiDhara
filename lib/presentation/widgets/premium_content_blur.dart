import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../providers/remote_config_provider.dart';
import 'premium_blurred_gate.dart';

/// Specifically designed to blur ONLY the body/content portion of a card
/// while keeping the card title, icon, and frame 100% visible and sharp.
///
/// Tap anywhere on the blurred area to open the subscription paywall sheet.
class BlurredContentGate extends ConsumerWidget {
  final Widget child;
  final String langCode;
  final double borderRadius;
  final double blurAmount;
  final String? customLockText;

  const BlurredContentGate({
    super.key,
    required this.child,
    required this.langCode,
    this.borderRadius = 10,
    this.blurAmount = 5.5,
    this.customLockText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumAccessProvider);
    if (isPremium) return child;

    final unlockText = customLockText ??
        (langCode == 'en'
            ? 'Tap to Unlock'
            : (langCode == 'hi'
                ? 'अनलॉक करने हेतु टैप करें'
                : 'अनलॉक करण्यासाठी टॅप करा'));

    return GestureDetector(
      onTap: () => showPremiumPaywallSheet(context, ref, langCode),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blurred underlying content
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: blurAmount,
                sigmaY: blurAmount,
              ),
              child: IgnorePointer(child: child),
            ),
          ),

          // Frosted glass gradient overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFFFBF2).withValues(alpha: 0.15),
                      const Color(0xFFFFFBF2).withValues(alpha: 0.70),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Sleek frosted lock badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B1D18), Color(0xFFD84315)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B1D18).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFFFFD54F),
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  unlockText,
                  style: GoogleFonts.mukta(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Blurs ONLY the content body of a card while keeping the title/header visible.
class PremiumContentBlur extends ConsumerWidget {
  final Widget child;
  final String langCode;

  /// If true, shows a compact inline "Unlock Premium" badge on the blur overlay
  /// instead of the full floating card. Useful inside list items.
  final bool compact;

  const PremiumContentBlur({
    super.key,
    required this.child,
    required this.langCode,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumAccessProvider);

    // Premium users see everything crystal clear
    if (isPremium) return child;

    return Stack(
      children: [
        // The content — blurred
        ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: IgnorePointer(child: child),
          ),
        ),

        // Gradient fade for refined frosted glass effect
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFFBF2).withValues(alpha: 0.05),
                    const Color(0xFFFFFBF2).withValues(alpha: 0.45),
                    const Color(0xFFFFFBF2).withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Compact "🔒 Premium" tap badge
        Positioned.fill(
          child: Center(
            child: GestureDetector(
              onTap: () => showPremiumPaywallSheet(context, ref, langCode),
              child: compact
                  ? _compactBadge(context)
                  : _floatingBadge(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _compactBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B1D18), Color(0xFFD84315)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B1D18).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, color: Color(0xFFFFD54F), size: 16),
          const SizedBox(width: 6),
          Text(
            langCode == 'en'
                ? 'Unlock Premium'
                : (langCode == 'hi'
                      ? 'प्रीमियम अनलॉक करें'
                      : 'प्रीमियम अनलॉक करा'),
            style: GoogleFonts.mukta(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingBadge(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B1D18).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFD4AF37),
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                langCode == 'en'
                    ? 'Premium Content'
                    : (langCode == 'hi'
                          ? 'प्रीमियम सामग्री'
                          : 'प्रीमियम सामग्री'),
                style: GoogleFonts.mukta(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7A0C08),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            langCode == 'en'
                ? '7 days free trial • then ₹33/mo'
                : (langCode == 'hi'
                      ? '7 दिन मुफ्त ट्रायल • फिर ₹33/मा.'
                      : '७ दिवस मोफत ट्रायल • मग ₹३३/मा.'),
            style: GoogleFonts.mukta(
              fontSize: 12.5,
              color: MandirTheme.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B1D18), Color(0xFFE65100)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B1D18).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_open_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  langCode == 'en'
                      ? 'Start Free Trial'
                      : (langCode == 'hi'
                            ? 'मुफ्त ट्रायल शुरू करें'
                            : 'मोफत ट्रायल सुरू करा'),
                  style: GoogleFonts.mukta(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

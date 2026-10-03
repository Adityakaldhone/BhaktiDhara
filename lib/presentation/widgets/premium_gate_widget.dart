import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/remote_config_provider.dart';
import 'premium_blurred_gate.dart';

/// Wraps any widget: if user is free, the child is blurred and a premium
/// upgrade banner is overlaid. If premium, just shows the child as-is.
class PremiumGateWidget extends ConsumerWidget {
  const PremiumGateWidget({
    super.key,
    required this.child,
    this.blurSigma = 6.0,
    this.lockLabel,
  });

  final Widget child;
  final double blurSigma;
  final String? lockLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumAccessProvider);
    if (isPremium) return child;

    return Stack(
      children: [
        // The actual content — blurred
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
            tileMode: TileMode.decal,
          ),
          child: IgnorePointer(child: child),
        ),

        // Semi-transparent gradient overlay
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00FFF8EE), // transparent top
                  Color(0xCCFFF3DC), // amber-cream at bottom
                  Color(0xEEFFF0CC),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // Premium lock overlay card
        Positioned.fill(
          child: Center(
            child: _PremiumUnlockCard(hint: lockLabel),
          ),
        ),
      ],
    );
  }
}

class _PremiumUnlockCard extends ConsumerWidget {
  const _PremiumUnlockCard({this.hint});
  final String? hint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8B1D18), // deep maroon
              Color(0xFFB8460F), // saffron-rust
              Color(0xFFD4AF37), // gold edge
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B1D18).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _showPremiumSheet(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lock icon with glow
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 32,
                      color: Color(0xFFFFE680),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    '🙏 भक्ती प्रीमियम',
                    style: GoogleFonts.mukta(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFE680),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    hint ?? 'संपूर्ण ज्ञान अनलॉक करा',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mukta(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE680),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.currency_rupee_rounded,
                          size: 16,
                          color: Color(0xFF6B1A15),
                        ),
                        Text(
                          '51 / महिना',
                          style: GoogleFonts.mukta(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6B1A15),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'खाली टॅप करा • अनलॉक करा',
                    style: GoogleFonts.mukta(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Beautiful full-screen premium upgrade bottom sheet
void _showPremiumSheet(BuildContext context, WidgetRef ref) {
  // Delegate to the main multi-plan paywall
  showPremiumPaywallSheet(context, ref, 'mr');
}

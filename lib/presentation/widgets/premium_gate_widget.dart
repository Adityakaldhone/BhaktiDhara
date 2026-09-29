import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/premium_provider.dart';

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
    final isPremium = ref.watch(isPremiumProvider);
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
                          '20 / महिना',
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PremiumUpgradeSheet(ref: ref),
  );
}

class _PremiumUpgradeSheet extends StatelessWidget {
  const _PremiumUpgradeSheet({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8EE), Color(0xFFFFF0CC)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // OM + title
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8B1D18), Color(0xFFD4AF37)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B1D18).withValues(alpha: 0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Text(
                  'ॐ',
                  style: GoogleFonts.mukta(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'भक्ती प्रीमियम',
                style: GoogleFonts.mukta(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7A0C08),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'संपूर्ण पंचांग • राशीभविष्य • आत्मिक ज्ञान',
                textAlign: TextAlign.center,
                style: GoogleFonts.mukta(
                  fontSize: 13,
                  color: const Color(0xFF8B6040),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Feature bullets
              _featureTile(
                icon: '📅',
                title: 'संपूर्ण पंचांग',
                subtitle: 'पंच-अंग, मुहूर्त, राहु काळ, सण-उत्सव सर्व माहिती',
              ),
              _featureTile(
                icon: '🔮',
                title: 'संपूर्ण राशीभविष्य',
                subtitle: 'प्रेम, करिअर, आरोग्य, उपाय — सर्व विभाग अनलॉक',
              ),
              _featureTile(
                icon: '🪔',
                title: 'AI ज्योतिष सल्ला',
                subtitle: 'Gemini AI द्वारे वैयक्तिक भविष्य व मार्गदर्शन',
              ),
              _featureTile(
                icon: '🙏',
                title: 'विज्ञापन-मुक्त अनुभव',
                subtitle: 'कोणत्याही जाहिरातीशिवाय शुद्ध भक्ती अनुभव',
              ),
              const SizedBox(height: 24),

              // Price card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8B1D18), Color(0xFFB8460F)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD4AF37),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B1D18).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'मासिक प्लान',
                          style: GoogleFonts.mukta(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹20',
                              style: GoogleFonts.mukta(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFE680),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '/ महिना',
                                style: GoogleFonts.mukta(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'फक्त ₹0.66 प्रतिदिन! 🎉',
                          style: GoogleFonts.mukta(
                            fontSize: 12,
                            color: const Color(0xFFFFE680),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.local_offer_rounded,
                            color: Color(0xFFFFE680),
                            size: 20,
                          ),
                          Text(
                            'BEST\nVALUE',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.mukta(
                              fontSize: 10,
                              color: const Color(0xFFFFE680),
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Subscribe button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF4A1208),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    // TODO: integrate RevenueCat / Google Play Billing here
                    // For now, unlock as demo
                    ref.read(isPremiumProvider.notifier).unlockPremium();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Text('🙏 ', style: TextStyle(fontSize: 20)),
                            Text(
                              'भक्ती प्रीमियम अनलॉक झाले! जय श्रीराम 🚩',
                              style: GoogleFonts.mukta(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF7A0C08),
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    '🙏 प्रीमियम सुरू करा — ₹20/महिना',
                    style: GoogleFonts.mukta(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'आता नको, नंतर करेन',
                  style: GoogleFonts.mukta(
                    fontSize: 13,
                    color: const Color(0xFF8B6040),
                  ),
                ),
              ),

              const SizedBox(height: 4),
              Text(
                '• कधीही रद्द करता येते • सुरक्षित भुगतान •',
                textAlign: TextAlign.center,
                style: GoogleFonts.mukta(
                  fontSize: 11,
                  color: const Color(0xFFAA9070),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureTile({
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6C8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.mukta(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A1208),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.mukta(
                    fontSize: 12.5,
                    color: const Color(0xFF7A5A40),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFFD4AF37),
            size: 20,
          ),
        ],
      ),
    );
  }
}

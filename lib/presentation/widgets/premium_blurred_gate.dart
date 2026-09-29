import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../providers/premium_provider.dart';
import '../../services/backend_service.dart';

/// Wraps sensitive / deep astrological content with a frosted blur and an aesthetic
/// ₹20/month Premium unlock gate for free users.
///
/// If [isPremiumProvider] is true, renders [child] completely unblurred.
class PremiumBlurredGate extends ConsumerWidget {
  final Widget child;
  final String title;
  final String subtitle;
  final String langCode;

  const PremiumBlurredGate({
    super.key,
    required this.child,
    required this.title,
    required this.subtitle,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    // If user has unlocked Premium, show everything sharp and crystal clear!
    if (isPremium) {
      return child;
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // The partially blurred content
        ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: IgnorePointer(child: child),
          ),
        ),

        // Gradient fade over the blur for a refined frosted glass effect
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFFBF2).withValues(alpha: 0.15),
                    const Color(0xFFFFFBF2).withValues(alpha: 0.75),
                    const Color(0xFFFFFBF2).withValues(alpha: 0.96),
                  ],
                  stops: const [0.0, 0.35, 0.95],
                ),
              ),
            ),
          ),
        ),

        // Floating Unlock Premium Banner Card
        Padding(
          padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B1D18).withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Crown / Sparkle Emblem
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8F00).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Special Offer Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3D6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF8B1D18),
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _getOfferText(langCode),
                        style: GoogleFonts.mukta(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7A0C08),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mukta(
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                    color: MandirTheme.textDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mukta(
                    fontSize: 13,
                    color: MandirTheme.textMuted,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Big Golden CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B1D18), Color(0xFFE65100)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF8B1D18,
                          ).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () =>
                          showPremiumPaywallSheet(context, ref, langCode),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_open_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _getButtonText(langCode),
                              style: GoogleFonts.mukta(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                                height: 1.25,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getOfferText(String lang) {
    switch (lang) {
      case 'hi':
        return 'विशेष ऑफर: सिर्फ ₹20 / महीना';
      case 'en':
        return 'Special Offer: Just ₹20 / month';
      case 'mr':
      default:
        return 'विशेष ऑफर: फक्त ₹२० / महिना';
    }
  }

  String _getButtonText(String lang) {
    switch (lang) {
      case 'hi':
        return 'प्रीमियम अनलॉक करें — ₹20';
      case 'en':
        return 'Unlock Premium — ₹20';
      case 'mr':
      default:
        return 'प्रीमियम अनलॉक करा — ₹२०';
    }
  }
}

/// Opens the royal BhaktiDhara Premium bottom sheet with full details and instant activation.
void showPremiumPaywallSheet(
  BuildContext context,
  WidgetRef ref,
  String langCode,
) {
  final isPremium = ref.read(isPremiumProvider);
  if (!isPremium) BackendService.trackEvent('paywall_view', item: 'blurred_gate');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBF2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header Emblem & Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3D6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFF8B1D18),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langCode == 'en'
                          ? 'BhaktiDhara Premium'
                          : (langCode == 'hi'
                                ? 'भक्तिधारा प्रीमियम'
                                : 'भक्तिधारा प्रीमियम'),
                      style: GoogleFonts.mukta(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7A0C08),
                        height: 1.1,
                      ),
                    ),
                    Text(
                      langCode == 'en'
                          ? 'Divine Astrology & Sacred Panchang'
                          : (langCode == 'hi'
                                ? 'दैनिक ज्योतिष व संपूर्ण पंचांग'
                                : 'दैनिक ज्योतिष व संपूर्ण पंचांग'),
                      style: GoogleFonts.mukta(
                        fontSize: 12.5,
                        color: MandirTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Benefit Points
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEDCC7)),
              ),
              child: Column(
                children: [
                  _buildBenefitRow(
                    icon: Icons.auto_awesome,
                    title: langCode == 'en'
                        ? 'Full 12 Rashi Forecast'
                        : (langCode == 'hi'
                              ? 'संपूर्ण 12 राशियों का विस्तृत राशिफल'
                              : 'संपूर्ण १२ राशींचे सविस्तर भविष्य'),
                    subtitle: langCode == 'en'
                        ? 'Career, Wealth, Family & Health predictions'
                        : (langCode == 'hi'
                              ? 'करियर, धन, परिवार व स्वास्थ्य की भविष्यवाणी'
                              : 'करिअर, धन, कुटुंब व आरोग्याची अचूक माहिती'),
                  ),
                  const Divider(height: 16, color: Color(0xFFF3E7D5)),
                  _buildBenefitRow(
                    icon: Icons.wb_sunny_rounded,
                    title: langCode == 'en'
                        ? 'All Sacred Muhurats & Kaal'
                        : (langCode == 'hi'
                              ? 'सभी शुभ मुहूर्त, अभिजित व राहु काल'
                              : 'सर्व शुभ मुहूर्त, अभिजीत व राहु काळ'),
                    subtitle: langCode == 'en'
                        ? 'Accurate timings calculated for your city'
                        : (langCode == 'hi'
                              ? 'आपके शहर के अनुसार सटीक गणितीय समय'
                              : 'आपल्या शहरासाठी अचूक स्थानिक वेळ'),
                  ),
                  const Divider(height: 16, color: Color(0xFFF3E7D5)),
                  _buildBenefitRow(
                    icon: Icons.shield_rounded,
                    title: langCode == 'en'
                        ? 'Astrological Remedies & Mantras'
                        : (langCode == 'hi'
                              ? 'दैनिक अचूक ज्योतिषीय उपाय व मंत्र'
                              : 'दैनिक अचूक ज्योतिषीय उपाय व प्रभावी मंत्र'),
                    subtitle: langCode == 'en'
                        ? 'Deity worship guidance and lucky charms'
                        : (langCode == 'hi'
                              ? 'ईष्टदेव उपासना व भाग्यशाली रत्न मार्गदर्शन'
                              : 'इष्टदेवता उपासना व भाग्यशाली रत्न मार्गदर्शन'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pricing Highlight Box (Just ₹20 / month!)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF8E7), Color(0xFFFFECD1)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              langCode == 'en'
                                  ? 'Monthly Plan'
                                  : (langCode == 'hi'
                                        ? 'मासिक प्लान'
                                        : 'मासिक योजना'),
                              style: GoogleFonts.mukta(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: MandirTheme.textDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B1D18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                langCode == 'en' ? '80% OFF' : '८०% सूट',
                                style: GoogleFonts.mukta(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          langCode == 'en'
                              ? 'Cancel anytime • Instant access'
                              : (langCode == 'hi'
                                    ? 'कभी भी रद्द करें • तुरंत सक्रिय'
                                    : 'कधीही रद्द करू शकता • त्वरित अ‍ॅक्टिव्हेशन'),
                          style: GoogleFonts.mukta(
                            fontSize: 12,
                            color: MandirTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        langCode == 'en' ? '₹99' : '₹९९',
                        style: GoogleFonts.mukta(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        langCode == 'en' ? '₹20 / mo' : '₹२० / महिना',
                        style: GoogleFonts.mukta(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B1D18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Subscribe Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B1D18), Color(0xFFE65100)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B1D18).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    await ref.read(isPremiumProvider.notifier).unlockPremium();
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF8B1D18),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content: Row(
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                color: Color(0xFFFFD54F),
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  langCode == 'en'
                                      ? '🎉 Congratulations! Premium is now active!'
                                      : (langCode == 'hi'
                                            ? '🎉 बधाई! प्रीमियम सदस्यता सक्रिय हो गई है!'
                                            : '🎉 अभिनंदन! आपली प्रीमियम सदस्यता यशस्वीरीत्या सुरू झाली आहे!'),
                                  style: GoogleFonts.mukta(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          langCode == 'en'
                              ? 'Subscribe Now • Just ₹20'
                              : (langCode == 'hi'
                                    ? 'अभी सब्सक्राइब करें • सिर्फ ₹20'
                                    : 'आत्ताच सबस्क्राइब करा • फक्त ₹२०'),
                          style: GoogleFonts.mukta(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.25,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Developer / User Test Toggle button (so they can test both states easily)
            TextButton(
              onPressed: () async {
                if (isPremium) {
                  await ref.read(isPremiumProvider.notifier).resetPremium();
                } else {
                  await ref.read(isPremiumProvider.notifier).unlockPremium();
                }
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isPremium
                            ? '🔄 Free mode enabled (blur visible)'
                            : '⭐ Premium mode enabled (unblurred)',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Text(
                isPremium
                    ? (langCode == 'en'
                          ? '🧪 Switch to Free Mode (Test Blur)'
                          : '🧪 फ्री मोडवर परत जा (चाचणीसाठी)')
                    : (langCode == 'en'
                          ? 'Restore Purchase'
                          : 'खरेदी पुनर्प्राप्त करा (Restore)'),
                style: GoogleFonts.mukta(
                  fontSize: 12.5,
                  color: MandirTheme.textMuted,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildBenefitRow({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3D6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF8B1D18)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.mukta(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: MandirTheme.textDark,
                height: 1.1,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.mukta(
                fontSize: 12,
                color: MandirTheme.textMuted,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

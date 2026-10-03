import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/app_remote_config.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../services/backend_service.dart';
import '../providers/premium_provider.dart';
import '../providers/remote_config_provider.dart';
import '../providers/subscription_provider.dart';

/// Wraps sensitive / deep astrological content with a frosted blur and an aesthetic
/// Premium unlock gate for free users.
///
/// If [isPremiumProvider] is true, renders [child] completely unblurred.
///
/// ### Blur Behavior (per user request):
/// - Titles/headers of cards remain **visible**
/// - Only the **content below the title** gets blurred
/// - This creates a teaser effect — users see WHAT they're missing, not just a wall
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
    final isPremium = ref.watch(premiumAccessProvider);

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
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Text(
                                _getButtonText(langCode),
                                style: GoogleFonts.mukta(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
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
        return '7 दिन मुफ्त! फिर सिर्फ ₹33/महीना';
      case 'en':
        return '7 Days Free! Then just ₹33/month';
      case 'mr':
      default:
        return '७ दिवस मोफत! मग फक्त ₹३३/महिना';
    }
  }

  String _getButtonText(String lang) {
    switch (lang) {
      case 'hi':
        return 'मुफ्त ट्रायल शुरू करें — 7 दिन';
      case 'en':
        return 'Start Free Trial — 7 Days';
      case 'mr':
      default:
        return 'मोफत ट्रायल सुरू करा — ७ दिवस';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PREMIUM PAYWALL BOTTOM SHEET — Full multi-plan subscription UI
// ═══════════════════════════════════════════════════════════════════════════════

/// Opens the royal BhaktiDhara Premium bottom sheet with full plan selection,
/// ~~₹99~~ strikethrough pricing, 7-day free trial, and instant activation.
void showPremiumPaywallSheet(
  BuildContext context,
  WidgetRef ref,
  String langCode,
) {
  if (!ref.read(featureEnabledProvider(AppRemoteConfig.premiumPaywall))) return;
  final isPremium = ref.read(isPremiumProvider);
  if (!isPremium) {
    BackendService.trackEvent('paywall_view', item: 'subscription_sheet');
  }

  // Reset selected plan to the first (recommended annual)
  ref.read(selectedPlanIndexProvider.notifier).state = 0;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _SubscriptionPaywallSheet(langCode: langCode);
    },
  );
}

class _SubscriptionPaywallSheet extends ConsumerStatefulWidget {
  final String langCode;

  const _SubscriptionPaywallSheet({required this.langCode});

  @override
  ConsumerState<_SubscriptionPaywallSheet> createState() =>
      _SubscriptionPaywallSheetState();
}

class _SubscriptionPaywallSheetState
    extends ConsumerState<_SubscriptionPaywallSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      _shimmerController.value = 0.5;
    } else {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedPlanIndexProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final lang = widget.langCode;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
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
      child: SingleChildScrollView(
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

            // Header
            _buildHeader(lang),
            const SizedBox(height: 16),

            // Free Trial Banner
            _buildTrialBanner(lang),
            const SizedBox(height: 16),

            // Plan Cards
            ...List.generate(kSubscriptionPlans.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildPlanCard(
                  kSubscriptionPlans[index],
                  isSelected: selectedIndex == index,
                  index: index,
                  lang: lang,
                ),
              );
            }),
            const SizedBox(height: 12),

            // Benefits list
            _buildBenefits(lang),
            const SizedBox(height: 16),

            // Subscribe Button
            _buildSubscribeButton(lang, selectedIndex, isPremium),
            const SizedBox(height: 10),

            // Restore purchase + Dev toggle
            _buildFooterActions(lang, isPremium),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String lang) {
    return Row(
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
              lang == 'en'
                  ? 'BhaktiDhara Premium'
                  : 'भक्तिधारा प्रीमियम',
              style: GoogleFonts.mukta(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7A0C08),
                height: 1.1,
              ),
            ),
            Text(
              lang == 'en'
                  ? 'Divine Astrology & Sacred Panchang'
                  : (lang == 'hi'
                        ? 'दैनिक ज्योतिष व संपूर्ण पंचांग'
                        : 'दैवी ज्योतिष व पवित्र पंचांग'),
              style: GoogleFonts.mukta(
                fontSize: 12.5,
                color: MandirTheme.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrialBanner(String lang) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2E7D32),
                Color.lerp(
                  const Color(0xFF2E7D32),
                  const Color(0xFF43A047),
                  _shimmerController.value,
                )!,
                const Color(0xFF2E7D32),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    lang == 'en'
                        ? '🎉 7 Days FREE Trial on all plans!'
                        : (lang == 'hi'
                              ? '🎉 सभी प्लान्स पर 7 दिन मुफ्त ट्रायल!'
                              : '🎉 सर्व योजनांवर ७ दिवस मोफत ट्रायल!'),
                    style: GoogleFonts.mukta(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanCard(
    SubscriptionPlan plan, {
    required bool isSelected,
    required int index,
    required String lang,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedPlanIndexProvider.notifier).state = index;
        BackendService.trackEvent(
          'plan_select',
          item: plan.productId,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF8E7) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4AF37)
                : const Color(0xFFEEDCC7),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF8B1D18)
                      : const Color(0xFFBDAB8E),
                  width: isSelected ? 2.5 : 1.5,
                ),
                color: isSelected
                    ? const Color(0xFF8B1D18)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),

            // Plan name + per month
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.label(lang),
                        style: GoogleFonts.mukta(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: MandirTheme.textDark,
                        ),
                      ),
                      if (plan.isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD4AF37), Color(0xFFFF8F00)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lang == 'en'
                                ? '⭐ BEST VALUE'
                                : (lang == 'hi'
                                      ? '⭐ सर्वश्रेष्ठ'
                                      : '⭐ सर्वोत्तम'),
                            style: GoogleFonts.mukta(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (plan.durationMonths > 1)
                    Text(
                      lang == 'en'
                          ? '₹${plan.perMonth}/month'
                          : (lang == 'hi'
                                ? '₹${plan.perMonth}/महीना'
                                : '₹${plan.perMonth}/महिना'),
                      style: GoogleFonts.mukta(
                        fontSize: 13,
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            // Price column with strikethrough MRP
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Strikethrough MRP
                Text(
                  '₹${plan.mrpInr}',
                  style: GoogleFonts.mukta(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.red.shade400,
                    decorationThickness: 2,
                  ),
                ),
                // Actual price
                Text(
                  plan.durationMonths == 1
                      ? (lang == 'en'
                            ? '₹${plan.priceInr}/mo'
                            : '₹${plan.priceInr}/मा.')
                      : '₹${plan.priceInr}',
                  style: GoogleFonts.mukta(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8B1D18),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),

            // Discount badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF8B1D18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${plan.discountPercent}%',
                style: GoogleFonts.mukta(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefits(String lang) {
    return Container(
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
            title: lang == 'en'
                ? 'Full 12 Rashi Forecast'
                : (lang == 'hi'
                      ? 'संपूर्ण 12 राशियों का विस्तृत राशिफल'
                      : 'संपूर्ण १२ राशींचे सविस्तर भविष्य'),
            subtitle: lang == 'en'
                ? 'Career, Wealth, Family & Health predictions'
                : (lang == 'hi'
                      ? 'करियर, धन, परिवार व स्वास्थ्य की भविष्यवाणी'
                      : 'करिअर, धन, कुटुंब व आरोग्याची अचूक माहिती'),
          ),
          const Divider(height: 16, color: Color(0xFFF3E7D5)),
          _buildBenefitRow(
            icon: Icons.wb_sunny_rounded,
            title: lang == 'en'
                ? 'All Sacred Muhurats & Kaal'
                : (lang == 'hi'
                      ? 'सभी शुभ मुहूर्त, अभिजित व राहु काल'
                      : 'सर्व शुभ मुहूर्त, अभिजीत व राहु काळ'),
            subtitle: lang == 'en'
                ? 'Accurate timings calculated for your city'
                : (lang == 'hi'
                      ? 'आपके शहर के अनुसार सटीक गणितीय समय'
                      : 'आपल्या शहरासाठी अचूक स्थानिक वेळ'),
          ),
          const Divider(height: 16, color: Color(0xFFF3E7D5)),
          _buildBenefitRow(
            icon: Icons.shield_rounded,
            title: lang == 'en'
                ? 'Astrological Remedies & Mantras'
                : (lang == 'hi'
                      ? 'दैनिक अचूक ज्योतिषीय उपाय व मंत्र'
                      : 'दैनिक अचूक ज्योतिषीय उपाय व प्रभावी मंत्र'),
            subtitle: lang == 'en'
                ? 'Deity worship guidance and lucky charms'
                : (lang == 'hi'
                      ? 'ईष्टदेव उपासना व भाग्यशाली रत्न मार्गदर्शन'
                      : 'इष्टदेवता उपासना व भाग्यशाली रत्न मार्गदर्शन'),
          ),
          const Divider(height: 16, color: Color(0xFFF3E7D5)),
          _buildBenefitRow(
            icon: Icons.block_rounded,
            title: lang == 'en'
                ? 'Completely Ad-Free Experience'
                : (lang == 'hi'
                      ? 'पूर्णतः विज्ञापन-मुक्त अनुभव'
                      : 'पूर्णतः जाहिरात-मुक्त अनुभव'),
            subtitle: lang == 'en'
                ? 'No banners, no interruptions — pure devotion'
                : (lang == 'hi'
                      ? 'कोई बैनर नहीं, कोई बाधा नहीं — शुद्ध भक्ति'
                      : 'कोणतेही बॅनर नाही, कोणताही अडथळा नाही — शुद्ध भक्ती'),
          ),
          const Divider(height: 16, color: Color(0xFFF3E7D5)),
          _buildBenefitRow(
            icon: Icons.photo_library_rounded,
            title: lang == 'en'
                ? 'Unlimited Greeting Cards'
                : (lang == 'hi'
                      ? 'असीमित शुभकामना कार्ड'
                      : 'अमर्यादित शुभेच्छा कार्ड'),
            subtitle: lang == 'en'
                ? 'No watermark, custom backgrounds'
                : (lang == 'hi'
                      ? 'बिना वॉटरमार्क, कस्टम बैकग्राउंड'
                      : 'वॉटरमार्क नाही, कस्टम बॅकग्राउंड'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton(String lang, int selectedIndex, bool isPremium) {
    final plan = kSubscriptionPlans[selectedIndex];

    return SizedBox(
      width: double.infinity,
      height: 56,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _isPurchasing
              ? null
              : () async {
                  setState(() => _isPurchasing = true);
                  BackendService.trackEvent(
                    'subscribe_tap',
                    item: plan.productId,
                  );

                  final success = await ref
                      .read(subscriptionProvider.notifier)
                      .purchasePlan(plan);

                  if (mounted) {
                    setState(() => _isPurchasing = false);
                  }

                  if (success && mounted) {
                    Navigator.pop(context);
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
                                lang == 'en'
                                    ? '🎉 Premium is now active!'
                                    : (lang == 'hi'
                                          ? '🎉 प्रीमियम सक्रिय!'
                                          : '🎉 प्रीमियम सक्रिय!'),
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
                  } else if (mounted) {
                    final errorMsg =
                        ref.read(subscriptionProvider.notifier).lastError;
                    if (errorMsg != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red.shade900,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  errorMsg,
                                  style: GoogleFonts.mukta(
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 6),
                        ),
                      );
                    }
                  }
                },
          child: _isPurchasing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          _subscribeButtonText(lang, plan),
                          style: GoogleFonts.mukta(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _subscribeButtonText(String lang, SubscriptionPlan plan) {
    switch (lang) {
      case 'hi':
        return 'मुफ्त ट्रायल शुरू करें • ${plan.labelHi()} ₹${plan.priceInr}';
      case 'en':
        return 'Start Free Trial • ${plan.labelEn()} ₹${plan.priceInr}';
      case 'mr':
      default:
        return 'मोफत ट्रायल सुरू करा • ${plan.labelMr()} ₹${plan.priceInr}';
    }
  }

  Widget _buildFooterActions(String lang, bool isPremium) {
    return Column(
      children: [
        // Restore purchase
        TextButton(
          onPressed: () async {
            final restored = await ref
                .read(subscriptionProvider.notifier)
                .restorePurchase();
            if (mounted) {
              if (restored) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lang == 'en'
                          ? '✅ Purchase restored successfully!'
                          : (lang == 'hi'
                                ? '✅ खरीदी सफलतापूर्वक पुनर्प्राप्त!'
                                : '✅ खरेदी यशस्वीरीत्या पुनर्प्राप्त!'),
                    ),
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lang == 'en'
                          ? 'No previous purchase found'
                          : (lang == 'hi'
                                ? 'पिछली खरीदी नहीं मिली'
                                : 'मागील खरेदी सापडली नाही'),
                    ),
                    backgroundColor: Colors.orange.shade800,
                  ),
                );
              }
            }
          },
          child: Text(
            lang == 'en'
                ? 'Restore Purchase'
                : (lang == 'hi'
                      ? 'खरीदी पुनर्प्राप्त करें'
                      : 'खरेदी पुनर्प्राप्त करा'),
            style: GoogleFonts.mukta(
              fontSize: 13,
              color: MandirTheme.textMuted,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Legal footnote
        Text(
          lang == 'en'
              ? 'Cancel anytime. Payment via Google Play.\nNo charge during 7-day trial.'
              : (lang == 'hi'
                    ? 'कभी भी रद्द करें। Google Play से भुगतान।\n7 दिन ट्रायल में कोई शुल्क नहीं।'
                    : 'कधीही रद्द करा. Google Play द्वारे पेमेंट.\n७ दिवस ट्रायलमध्ये कोणतेही शुल्क नाही.'),
          textAlign: TextAlign.center,
          style: GoogleFonts.mukta(
            fontSize: 11,
            color: MandirTheme.textMuted.withValues(alpha: 0.5),
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

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

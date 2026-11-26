import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/app_remote_config.dart';
import '../providers/locale_provider.dart';
import '../providers/premium_provider.dart';
import '../providers/remote_config_provider.dart';
import 'premium_blurred_gate.dart';

/// Card that opens the subscription paywall to remove all ads.
/// Automatically hides for VIP users or when the paywall is remotely disabled.
class RemoveAdsCard extends ConsumerWidget {
  const RemoveAdsCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final paywallEnabled =
        ref.watch(featureEnabledProvider(AppRemoteConfig.premiumPaywall));
    if (isPremium || !paywallEnabled) {
      return const SizedBox.shrink();
    }

    final lang = ref.watch(localeProvider).languageCode;
    final title = switch (lang) {
      'hi' => 'सभी विज्ञापन हटाएं',
      'mr' => 'सर्व जाहिराती काढून टाका',
      _ => 'Remove all ads',
    };
    final subtitle = switch (lang) {
      'hi' => 'बिना रुकावट के विज्ञापन-मुक्त भक्ति अनुभव पाएं',
      'mr' => 'अखंड व जाहिरात-मुक्त भक्ती अनुभवासाठी VIP व्हा',
      _ => 'Go VIP for an uninterrupted, ad-free bhakti experience',
    };
    final cta = switch (lang) {
      'hi' => 'VIP बनें',
      'mr' => 'VIP व्हा',
      _ => 'Go VIP',
    };

    void onTap() => showPremiumPaywallSheet(context, ref, lang);

    if (compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF6E3), Color(0xFFFDE6BE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: MandirTheme.goldenAccent.withValues(alpha: 0.7),
                width: 1.1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: MandirTheme.secondaryMaroon,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.mukta(
                      fontSize: 15.5,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: MandirTheme.secondaryMaroon,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MandirTheme.secondaryMaroon,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    cta,
                    style: GoogleFonts.mukta(
                      fontSize: 12.5,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF6E3), Color(0xFFFDE6BE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: MandirTheme.goldenAccent.withValues(alpha: 0.7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8A5A2B).withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: MandirTheme.primarySaffron.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: MandirTheme.secondaryMaroon,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: MandirTheme.secondaryMaroon,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B5B4D),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: MandirTheme.secondaryMaroon,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  cta,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

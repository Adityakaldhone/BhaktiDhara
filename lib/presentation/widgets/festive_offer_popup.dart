import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/subscription_plan.dart';
import '../../services/backend_service.dart';
import '../../services/subscription_service.dart';
import '../providers/remote_config_provider.dart';
import '../providers/review_provider.dart';
import 'premium_blurred_gate.dart';

/// Admin-controlled festive offer popup on the home screen.
///
/// Each campaign (a new one starts every time the admin switches the toggle
/// on) is shown on at most [_maxShows] separate app launches, never twice in
/// the same launch, and never to users who already have premium access.
class FestiveOfferPopup {
  FestiveOfferPopup._();

  static const _maxShows = 2;
  static const _campaignKey = 'festive_popup_campaign';
  static const _countKey = 'festive_popup_shown_count';

  /// Used until Play has returned products; matches the Play Console offer.
  static const _defaultMonthlyOfferPrice = 9;

  static bool _handledThisLaunch = false;

  @visibleForTesting
  static void resetForTest() => _handledThisLaunch = false;

  /// First session is language → aarti only; the offer waits for a return visit.
  @visibleForTesting
  static bool deferForFirstSession(bool isFirstSession) => isFirstSession;

  static Future<void> maybeShow(
    BuildContext context,
    WidgetRef ref,
    String langCode,
  ) async {
    if (_handledThisLaunch) return;
    final config = ref.read(remoteConfigProvider);
    if (!config.showFestivePopup || ref.read(premiumAccessProvider)) return;
    // First session is language → aarti only. Do not burn a show-count slot.
    if (deferForFirstSession(ref.read(reviewServiceProvider).isFirstSession)) {
      _handledThisLaunch = true;
      return;
    }

    _handledThisLaunch = true;
    final campaign = config.festivePopupCampaign;
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getString(_campaignKey) == campaign
        ? prefs.getInt(_countKey) ?? 0
        : 0;
    if (shown >= _maxShows || !context.mounted) return;

    await prefs.setString(_campaignKey, campaign);
    await prefs.setInt(_countKey, shown + 1);
    BackendService.trackEvent('festive_popup_view', item: campaign);
    if (!context.mounted) return;

    final monthly = kSubscriptionPlans.firstWhere((p) => p.durationMonths == 1);
    final openOffer = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _FestiveOfferDialog(
        lang: langCode,
        monthlyPrice: monthly.priceInr,
        monthlyOfferPrice:
            SubscriptionService.instance.festiveOfferPrice(monthly.productId) ??
                _defaultMonthlyOfferPrice,
      ),
    );
    if (openOffer == true && context.mounted) {
      BackendService.trackEvent('festive_popup_click', item: campaign);
      showPremiumPaywallSheet(context, ref, langCode);
    }
  }
}

String _t(String lang, {required String en, required String hi, required String mr}) =>
    lang == 'en' ? en : (lang == 'hi' ? hi : mr);

const _gold = Color(0xFFE8C26A);
const _goldDeep = Color(0xFFB8862B);
const _maroon = Color(0xFF6E0F12);
const _maroonDeep = Color(0xFF3E0608);

class _FestiveOfferDialog extends StatelessWidget {
  const _FestiveOfferDialog({
    required this.lang,
    required this.monthlyPrice,
    required this.monthlyOfferPrice,
  });

  final String lang;
  final int monthlyPrice;
  final int monthlyOfferPrice;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context, true),
              child: _card(),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: _CloseButton(onTap: () => Navigator.pop(context, false)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [_gold, _goldDeep, _gold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA000).withValues(alpha: 0.45),
            blurRadius: 28,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          gradient: const RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.1,
            colors: [_maroon, _maroonDeep],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🔔', style: TextStyle(fontSize: 22)),
                Text('🪔', style: TextStyle(fontSize: 34)),
                Text('🔔', style: TextStyle(fontSize: 22)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _t(lang,
                  en: 'Diwali Special Offer',
                  hi: 'दिवाली विशेष ऑफर',
                  mr: 'दिवाळी विशेष ऑफर'),
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(
                fontSize: 30,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: _gold,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold, width: 1.2),
              ),
              child: Text(
                _t(lang,
                    en: 'Limited Time Offer',
                    hi: 'सीमित समय का ऑफर',
                    mr: 'मर्यादित काळासाठी ऑफर'),
                style: GoogleFonts.mukta(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFBE7C0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DiscountBadge(lang: lang),
                const SizedBox(width: 16),
                const Text('🎁', style: TextStyle(fontSize: 76)),
              ],
            ),
            const SizedBox(height: 12),
            _monthlyDeal(),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE08A), _gold, Color(0xFFD9A441)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                _t(lang,
                    en: 'Grab the Offer Now →',
                    hi: 'अभी ऑफर पाएं →',
                    mr: 'आत्ताच ऑफर मिळवा →'),
                textAlign: TextAlign.center,
                style: GoogleFonts.mukta(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _maroonDeep,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t(lang,
                  en: '*T&C apply',
                  hi: '*नियम व शर्तें लागू',
                  mr: '*नियम व अटी लागू'),
              style: GoogleFonts.mukta(
                fontSize: 12,
                color: const Color(0xFFFBE7C0).withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthlyDeal() {
    final base = GoogleFonts.mukta(
      fontSize: 17,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFFBE7C0),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.25),
        border: Border.all(color: _gold.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              style: base,
              children: [
                TextSpan(
                  text: _t(lang,
                      en: 'Monthly plan ',
                      hi: 'मासिक प्लान ',
                      mr: 'मासिक प्लान '),
                ),
                TextSpan(
                  text: '₹$monthlyPrice',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Color(0xFFFF6B6B),
                    decorationThickness: 2,
                  ),
                ),
                TextSpan(text: _t(lang, en: ' just ', hi: ' सिर्फ ', mr: ' फक्त ')),
                TextSpan(
                  text: '₹$monthlyOfferPrice',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _gold,
                  ),
                ),
                const TextSpan(
                  text: '*',
                  style: TextStyle(fontSize: 18, color: _gold),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            _t(lang,
                en: 'for the 1st month',
                hi: 'पहले महीने के लिए',
                mr: 'पहिल्या महिन्यासाठी'),
            style: base.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.mukta(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      height: 1.0,
    );
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF8B1D18),
        border: Border.all(color: _gold, width: 2.5),
        boxShadow: [
          BoxShadow(color: _gold.withValues(alpha: 0.4), blurRadius: 12),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _t(lang, en: 'Up to', hi: 'पाएं', mr: 'मिळवा'),
            style: style.copyWith(fontSize: 13),
          ),
          Text(
            '80%',
            style: style.copyWith(fontSize: 34, fontWeight: FontWeight.w800, color: _gold),
          ),
          Text(
            _t(lang, en: 'OFF', hi: 'तक छूट', mr: 'पर्यंत सूट'),
            style: style.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _maroonDeep,
            border: Border.all(color: _gold, width: 1.5),
          ),
          child: const Icon(Icons.close_rounded, color: _gold, size: 20),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/theme.dart';
import '../../services/review_service.dart';
import '../jaap/jaap_colors.dart';
import '../widgets/jaap/diya_lamp.dart';

/// The result of the devotional review pre-filter dialog.
enum ReviewDialogResult {
  /// User gave 4-5 stars → routed to Google Play In-App Review.
  ratedPositive,

  /// User gave 1-3 stars → feedback captured in-app.
  sentFeedback,

  /// User tapped "बाद में / Later" → cooldown snooze.
  later,

  /// Dialog was dismissed without action.
  dismissed,
}

/// Shows the aesthetically rich devotional pre-filter dialog.
///
/// This is the **sentiment gate** that ensures only happy devotees are
/// channelled to the Google Play Store, while unhappy ones are caught
/// in-app for constructive feedback.
///
/// Returns [ReviewDialogResult] so the caller can decide what to do.
Future<ReviewDialogResult> showDevotionalReviewDialog(
  BuildContext context, {
  required ReviewService reviewService,
  required String localeCode,
}) async {
  final result = await showGeneralDialog<ReviewDialogResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Review Dialog',
    barrierColor: const Color(0xFF3E2723).withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 450),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.8, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (dialogContext, _, _) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _DevotionalReviewCard(
          reviewService: reviewService,
          localeCode: localeCode,
        ),
      ),
    ),
  );
  return result ?? ReviewDialogResult.dismissed;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  INTERNAL STATEFUL CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _DevotionalReviewCard extends StatefulWidget {
  final ReviewService reviewService;
  final String localeCode;

  const _DevotionalReviewCard({
    required this.reviewService,
    required this.localeCode,
  });

  @override
  State<_DevotionalReviewCard> createState() => _DevotionalReviewCardState();
}

class _DevotionalReviewCardState extends State<_DevotionalReviewCard>
    with SingleTickerProviderStateMixin {
  int _selectedStars = 0;
  bool _showFeedbackForm = false;
  bool _submitting = false;
  final _feedbackController = TextEditingController();

  late final AnimationController _starGlow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void dispose() {
    _starGlow.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  String get _lang => widget.localeCode;

  // ── Localized strings ──────────────────────────────────────────────────
  String get _titleText {
    if (_lang == 'hi') return 'कैसा रहा आपका भक्ति अनुभव?';
    if (_lang == 'mr') return 'तुमचा भक्ती अनुभव कसा होता?';
    return 'How is your devotion journey?';
  }

  String get _subtitleText {
    if (_lang == 'hi') return 'भक्तिधारा के साथ आपकी साधना';
    if (_lang == 'mr') return 'भक्तिधारा सोबतची तुमची साधना';
    return 'Your spiritual journey with BhaktiDhara';
  }

  String get _positiveHeading {
    if (_lang == 'hi') return 'आपकी कृपा से अन्य भक्तों तक भी भक्ति पहुँचेगी!';
    if (_lang == 'mr') return 'तुमच्या कृपेने इतर भक्तांपर्यंतही भक्ती पोहोचेल!';
    return 'Your blessing will help other devotees find us!';
  }

  String get _rateOnPlayStore {
    if (_lang == 'hi') return 'Play Store पर आशीर्वाद दें';
    if (_lang == 'mr') return 'Play Store वर आशीर्वाद द्या';
    return 'Bless us on Play Store';
  }

  String get _negativeHeading {
    if (_lang == 'hi') return 'हम क्षमाप्रार्थी हैं। कृपया सुधार का सुझाव दें।';
    if (_lang == 'mr') return 'आम्हाला क्षमा करा. कृपया सुधारणा सुचवा.';
    return 'We sincerely apologize. Please share your suggestion.';
  }

  String get _feedbackHint {
    if (_lang == 'hi') return 'आपका सुझाव यहाँ लिखें...';
    if (_lang == 'mr') return 'तुमची सूचना येथे लिहा...';
    return 'Write your suggestion here...';
  }

  String get _sendFeedback {
    if (_lang == 'hi') return 'सुझाव भेजें';
    if (_lang == 'mr') return 'सूचना पाठवा';
    return 'Send Feedback';
  }

  String get _laterText {
    if (_lang == 'hi') return 'बाद में याद दिलाएं';
    if (_lang == 'mr') return 'नंतर आठवण करा';
    return 'Remind me later';
  }

  String get _alreadyRated {
    if (_lang == 'hi') return 'पहले ही रेटिंग दी है';
    if (_lang == 'mr') return 'आधीच रेटिंग दिली आहे';
    return 'Already rated';
  }

  String get _thankYou {
    if (_lang == 'hi') return 'आपके सुझाव के लिए धन्यवाद! 🙏';
    if (_lang == 'mr') return 'तुमच्या सूचनेबद्दल धन्यवाद! 🙏';
    return 'Thank you for your feedback! 🙏';
  }

  // ── Handlers ───────────────────────────────────────────────────────────
  void _onStarTap(int star) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedStars = star;
      _showFeedbackForm = false;
    });
    _starGlow.forward(from: 0);
  }

  Future<void> _onPositiveRate() async {
    setState(() => _submitting = true);
    await widget.reviewService.requestInAppReview();
    if (mounted) Navigator.pop(context, ReviewDialogResult.ratedPositive);
  }

  void _onShowFeedback() {
    setState(() => _showFeedbackForm = true);
  }

  Future<void> _onSendFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) return;

    setState(() => _submitting = true);

    // Send feedback via email
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'kaldhoneaditya1@gmail.com',
      queryParameters: {
        'subject': 'BhaktiDhara Feedback ($_selectedStars⭐)',
        'body': text,
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (_) {
      // Silently handle — feedback intent was recorded
    }

    await widget.reviewService.recordFeedbackSent();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: MandirTheme.secondaryMaroon,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            _thankYou,
            style: GoogleFonts.mukta(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
      Navigator.pop(context, ReviewDialogResult.sentFeedback);
    }
  }

  Future<void> _onAlreadyRated() async {
    await widget.reviewService.requestInAppReview();
    if (mounted) Navigator.pop(context, ReviewDialogResult.ratedPositive);
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFBF2), JaapColors.sandalStart],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFD4AF37),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: JaapColors.glowGold.withValues(alpha: 0.5),
              blurRadius: 36,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Diya ────────────────────────────────────────────────────
            const DiyaLamp(size: 72, flicker: true),
            const SizedBox(height: 10),

            // ── Title ───────────────────────────────────────────────────
            Text(
              _titleText,
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: MandirTheme.secondaryMaroon,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _subtitleText,
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: MandirTheme.textMuted,
              ),
            ),
            const SizedBox(height: 18),

            // ── Star Rating Row ─────────────────────────────────────────
            AnimatedBuilder(
              animation: _starGlow,
              builder: (context, child) => child!,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starIndex = i + 1;
                  final isSelected = starIndex <= _selectedStars;
                  return GestureDetector(
                    onTap: () => _onStarTap(starIndex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      child: AnimatedScale(
                        scale: isSelected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 44,
                          color: isSelected
                              ? const Color(0xFFD4AF37)
                              : const Color(0xFFCBBFA0),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // ── Dynamic content based on star selection ─────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              child: _selectedStars == 0
                  ? const SizedBox.shrink(key: ValueKey('empty'))
                  : _selectedStars >= 4
                      ? _buildPositiveSection()
                      : _showFeedbackForm
                          ? _buildFeedbackForm()
                          : _buildNegativeSection(),
            ),

            const SizedBox(height: 12),

            // ── Bottom actions ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // "Later" link
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () =>
                          Navigator.pop(context, ReviewDialogResult.later),
                  child: Text(
                    _laterText,
                    style: GoogleFonts.mukta(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: MandirTheme.textMuted,
                    ),
                  ),
                ),
                // "Already rated" link
                TextButton(
                  onPressed: _submitting ? null : _onAlreadyRated,
                  child: Text(
                    _alreadyRated,
                    style: GoogleFonts.mukta(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: MandirTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 4-5 star: channel to Play Store ────────────────────────────────────
  Widget _buildPositiveSection() {
    return Column(
      key: const ValueKey('positive'),
      children: [
        // Blessing text
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Text('🙏', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _positiveHeading,
                  style: GoogleFonts.mukta(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MandirTheme.textDark,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Big CTA Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : _onPositiveRate,
            icon: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.star_rounded, size: 22),
            label: Text(
              _rateOnPlayStore,
              style: GoogleFonts.mukta(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: MandirTheme.primarySaffron,
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: MandirTheme.primarySaffron.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 1-3 star: catch feedback in-app ────────────────────────────────────
  Widget _buildNegativeSection() {
    return Column(
      key: const ValueKey('negative'),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE0C097).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              const Text('🙏', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _negativeHeading,
                  style: GoogleFonts.mukta(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MandirTheme.textDark,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _onShowFeedback,
            icon: const Icon(Icons.feedback_outlined, size: 20),
            label: Text(
              _sendFeedback,
              style: GoogleFonts.mukta(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: MandirTheme.secondaryMaroon,
              side: const BorderSide(
                color: MandirTheme.goldenAccent,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Feedback text form ─────────────────────────────────────────────────
  Widget _buildFeedbackForm() {
    return Column(
      key: const ValueKey('feedback_form'),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE0C097).withValues(alpha: 0.4),
            ),
          ),
          child: TextField(
            controller: _feedbackController,
            maxLines: 4,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: GoogleFonts.mukta(
              fontSize: 15,
              color: MandirTheme.textDark,
            ),
            decoration: InputDecoration(
              hintText: _feedbackHint,
              hintStyle: GoogleFonts.mukta(
                fontSize: 14,
                color: MandirTheme.textMuted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : _onSendFeedback,
            icon: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 20),
            label: Text(
              _sendFeedback,
              style: GoogleFonts.mukta(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: MandirTheme.secondaryMaroon,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

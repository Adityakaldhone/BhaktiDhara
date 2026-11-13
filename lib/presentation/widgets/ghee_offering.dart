import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'akhand_jyot_flame.dart';

String _t(String lang, {required String en, required String hi, required String mr}) =>
    switch (lang) {
      'hi' => hi,
      'mr' => mr,
      _ => en,
    };

/// Floating aarti-screen pill counting down to today's ghee offering.
/// [secondsLeft] null hides it; 0 turns it into a tap-to-pour button.
class GheeTimerPill extends StatefulWidget {
  const GheeTimerPill({
    super.key,
    required this.secondsLeft,
    required this.totalSeconds,
    required this.bonusTick,
    required this.bonusSeconds,
    required this.lang,
    required this.onReady,
  });

  final ValueListenable<int?> secondsLeft;
  final int totalSeconds;

  /// Bumped on every pooja-tool bonus; each change plays a sparkle.
  final ValueListenable<int> bonusTick;
  final int bonusSeconds;
  final String lang;
  final VoidCallback onReady;

  @override
  State<GheeTimerPill> createState() => _GheeTimerPillState();
}

class _GheeTimerPillState extends State<GheeTimerPill> with SingleTickerProviderStateMixin {
  late final AnimationController _sparkle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    widget.bonusTick.addListener(_onBonus);
  }

  @override
  void dispose() {
    widget.bonusTick.removeListener(_onBonus);
    _sparkle.dispose();
    super.dispose();
  }

  void _onBonus() => _sparkle.forward(from: 0);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: widget.secondsLeft,
      builder: (context, left, _) {
        if (left == null) return const SizedBox.shrink();
        final ready = left <= 0;
        final lang = widget.lang;
        final label = ready
            ? _t(
                lang,
                en: '🪔 Pour today’s ghee into the Akhand Jyot',
                hi: '🪔 अखंड ज्योत में आज का घी डालें',
                mr: '🪔 अखंड ज्योतीत आजचे तूप अर्पण करा',
              )
            : _t(
                lang,
                en: '⏳ $left sec of aarti — or ring the diya/conch — for the Akhand Jyot',
                hi: '⏳ अखंड ज्योत के लिए $left सेकंड आरती करें या दीपक/शंख बजाएं',
                mr: '⏳ अखंड ज्योतीसाठी $left सेकंद आरती करा किंवा दीपक/शंख वाजवा',
              );

        final pill = GestureDetector(
          onTap: ready ? widget.onReady : null,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: ready
                    ? const [Color(0xFFD84315), Color(0xFFFF8F00)]
                    : const [Color(0xF27B1E1E), Color(0xF29B3412)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2B33C), width: 1.2),
              boxShadow: const [
                BoxShadow(color: Color(0x552E1104), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 26,
                  height: 26,
                  child: ready
                      ? const JyotFlame(size: 26, intensity: 1)
                      : TweenAnimationBuilder<double>(
                          tween: Tween(end: 1 - left / widget.totalSeconds),
                          duration: const Duration(milliseconds: 400),
                          builder: (_, v, _) => CircularProgressIndicator(
                            value: v,
                            strokeWidth: 3,
                            backgroundColor: Colors.white24,
                            color: const Color(0xFFFFD54F),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.mukta(
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        return AnimatedBuilder(
          animation: _sparkle,
          builder: (context, child) {
            final p = _sparkle.value;
            final active = _sparkle.isAnimating;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Transform.scale(
                  scale: active ? 1 + 0.06 * (1 - (2 * p - 1).abs()) : 1,
                  child: child,
                ),
                if (active)
                  Positioned(
                    top: -18 - 26 * p,
                    child: Opacity(
                      opacity: (1 - p).clamp(0.0, 1.0),
                      child: Text(
                        '✨ −${widget.bonusSeconds}s ✨',
                        style: GoogleFonts.mukta(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFFB300),
                          shadows: const [Shadow(color: Color(0x99000000), blurRadius: 4)],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
          child: pill,
        );
      },
    );
  }
}

/// Gold "aarti complete" sheet. Resolves true when the devotee pours the ghee.
/// [savesStreakOf] mentions a streak this refill will rescue.
Future<bool> showGheeRewardSheet(
  BuildContext context, {
  required String lang,
  int? savesStreakOf,
}) async {
  final poured = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _GheeRewardSheet(lang: lang, savesStreakOf: savesStreakOf),
  );
  return poured ?? false;
}

class _GheeRewardSheet extends StatelessWidget {
  const _GheeRewardSheet({required this.lang, required this.savesStreakOf});

  final String lang;
  final int? savesStreakOf;

  @override
  Widget build(BuildContext context) {
    final streak = savesStreakOf;
    return Container(
      padding: EdgeInsets.fromLTRB(22, 10, 22, 18 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF3C4), Color(0xFFF7D774), Color(0xFFE9B949)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFFB8862B), width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0x557B1E1E),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const JyotFlame(size: 104, intensity: 1),
          Text(
            _t(
              lang,
              en: '✨ Today’s aarti is complete!',
              hi: '✨ आज की आरती संपूर्ण!',
              mr: '✨ आजची आरती संपूर्ण!',
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.mukta(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF7B1E1E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t(
              lang,
              en: 'You have earned 24 hours of pure ghee.',
              hi: 'आपको 24 घंटे का शुद्ध घी प्राप्त हुआ।',
              mr: 'तुम्हाला २४ तासांचे शुद्ध तूप प्राप्त झाले.',
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.mukta(fontSize: 15, height: 1.3, color: const Color(0xFF5D3A1A)),
          ),
          if (streak != null) ...[
            const SizedBox(height: 6),
            Text(
              _t(
                lang,
                en: '🔥 Your $streak-day Jyot will be saved',
                hi: '🔥 आपकी $streak दिनों की ज्योत बच जाएगी',
                mr: '🔥 तुमची $streak दिवसांची ज्योत वाचेल',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFBF360C),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B1E1E), Color(0xFFB23A1A)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x557B1E1E), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: TextButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  Navigator.of(context).pop(true);
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFFE9B0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _t(
                    lang,
                    en: '🪔 Pour ghee into the Akhand Diya',
                    hi: '🪔 अखंड ज्योत में घी डालें',
                    mr: '🪔 अखंड ज्योत रिफिल करा',
                  ),
                  style: GoogleFonts.mukta(fontSize: 16.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

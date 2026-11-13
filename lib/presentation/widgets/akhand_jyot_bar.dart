import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/theme.dart';
import '../../domain/entities/bhakti_deity.dart';
import '../../domain/logic/akhand_diya.dart';
import '../../features/mandir/controllers/akhand_diya_controller.dart';
import '../../features/mandir/screens/real_garbhagriha_screen.dart';
import '../../services/akhand_diya_service.dart';
import '../../services/audio_service.dart';
import '../../services/backend_service.dart';
import '../../services/push_notification_service.dart';
import '../providers/akhand_diya_provider.dart';
import '../providers/locale_provider.dart';
import 'akhand_jyot_flame.dart';

String _t(String lang, {required String en, required String hi, required String mr}) =>
    switch (lang) {
      'hi' => hi,
      'mr' => mr,
      _ => en,
    };

/// "तूप पातळी: 82% • 19 तास 40 मिनिटे बाकी".
String gheeLevelText(String lang, AkhandDiyaController diya) {
  final pct = (diya.gheeRatio * 100).round();
  if (diya.everLit && pct == 0) {
    return _t(lang, en: 'Ghee finished', hi: 'घी समाप्त', mr: 'तूप संपले');
  }
  final left = formatGheeDuration(diya.remaining, lang);
  return _t(
    lang,
    en: 'Ghee level: $pct% • $left left',
    hi: 'घी स्तर: $pct% • $left बाकी',
    mr: 'तूप पातळी: $pct% • $left बाकी',
  );
}

String _headline(String lang, AkhandDiyaState diya, DateTime now, String deityName) {
  if (!diya.everLit) {
    return _t(
      lang,
      en: 'Light the Akhand Jyot in your home mandir',
      hi: 'अपने घर के मंदिर में अखंड ज्योत जलाएं',
      mr: 'घरातील मंदिरात अखंड ज्योत लावा',
    );
  }
  switch (diya.level(now)) {
    case JyotLevel.bright:
      return _t(
        lang,
        en: 'Akhand Jyot is shining bright',
        hi: 'अखंड ज्योत पूर्ण तेजस्वी है',
        mr: 'अखंड ज्योत पूर्ण तेजस्वी आहे',
      );
    case JyotLevel.medium:
      final evening = now.hour < 16;
      return _t(
        lang,
        en: 'Jyot is burning • Do aarti ${evening ? 'this evening' : 'tomorrow morning'}',
        hi: 'ज्योत जल रही है • ${evening ? 'शाम को' : 'कल सुबह'} आरती करें',
        mr: 'ज्योत तेवत आहे • ${evening ? 'संध्याकाळी' : 'उद्या सकाळी'} आरती करा',
      );
    case JyotLevel.low:
      return _t(
        lang,
        en: '⚠️ Ghee running low! Do a 1-minute aarti before the flame goes out',
        hi: '⚠️ घी कम हो रहा है! ज्योत बुझने से पहले 1 मिनट आरती करें',
        mr: '⚠️ तूप कमी होत आहे! ज्योत विझण्यापूर्वी 1 मिनिट आरती करा',
      );
    case JyotLevel.out:
      if (diya.canRevive(now)) {
        final n = diya.streakDays;
        return _t(
          lang,
          en: 'Your $n-day Akhand Jyot has gone quiet — do $deityName aarti now and save it!',
          hi: 'आपकी $n दिनों की अखंड ज्योत शांत हो गई है — अभी $deityName आरती करें और अपनी ज्योत को बचाएं!',
          mr: 'तुमची $n दिवसांची अखंड ज्योत शांत झाली आहे — आत्ताच $deityName आरती करा आणि ज्योत वाचवा!',
        );
      }
      return _t(
        lang,
        en: 'The Akhand Jyot has gone quiet — do aarti now to light it again',
        hi: 'अखंड ज्योत शांत हो गई है — अभी आरती करके पुनः प्रज्वलित करें',
        mr: 'अखंड ज्योत शांत झाली आहे — आत्ताच आरती करून पुन्हा प्रज्वलित करा',
      );
  }
}

/// Saffron-to-gold ghee level bar.
class GheeMeter extends StatelessWidget {
  const GheeMeter({super.key, required this.value, this.height = 7});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final low = v < 0.3;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1E0BE),
        borderRadius: BorderRadius.circular(height),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: v,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height),
            gradient: LinearGradient(
              colors: low
                  ? const [Color(0xFFD84315), Color(0xFFFF8F00)]
                  : const [Color(0xFFFF8F00), Color(0xFFE2B33C)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Walks into the 3D Garbhagriha of the Ishta Devta.
void openGarbhagriha(BuildContext context, WidgetRef ref, {required String source}) {
  final deity = ref.read(jyotDeityProvider);
  final diya = ref.read(akhandDiyaProvider);
  final now = DateTime.now();
  BackendService.trackEvent(
    'mandir_tap',
    item: deity.key,
    props: {
      'source': source,
      if (diya != null) 'level': diya.level(now).name,
      if (diya != null) 'ghee': diya.gheePercent(now).round(),
    },
  );
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => const RealGarbhagrihaScreen(),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: AppMotion.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: Tween(begin: 1.06, end: 1.0).animate(curved), child: child),
        );
      },
    ),
  );
}

/// Home banner: Ishta Devta, live flame, ghee level and the refill CTA.
class AkhandJyotBar extends ConsumerStatefulWidget {
  const AkhandJyotBar({super.key});

  @override
  ConsumerState<AkhandJyotBar> createState() => _AkhandJyotBarState();
}

class _AkhandJyotBarState extends ConsumerState<AkhandJyotBar> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => setState(() {}));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(akhandDiyaControllerProvider);
    final diya = controller.state;
    if (diya == null) return const SizedBox.shrink();
    final lang = ref.watch(localeProvider).languageCode;
    final deity = ref.watch(jyotDeityProvider);
    final now = DateTime.now();
    final level = diya.level(now);
    final pct = controller.gheeRatio * 100;
    final lit = controller.everLit;

    final borderColor = !lit
        ? MandirTheme.goldenAccent
        : switch (level) {
            JyotLevel.low => const Color(0xFFFF8F00),
            JyotLevel.out => const Color(0xFFB0A090),
            _ => MandirTheme.goldenAccent,
          };

    void onTap() {
      HapticFeedback.selectionClick();
      openGarbhagriha(context, ref, source: 'home_bar');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF8E8), Color(0xFFFCEBCB)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: level == JyotLevel.low && lit ? 1.6 : 1,
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x142E1104), blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                _Avatar(
                  deity: deity,
                  intensity: lit ? level.flameScale : 0,
                  flicker: level == JyotLevel.low,
                  day: lit && level != JyotLevel.out ? controller.streakDays : null,
                  lang: lang,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _headline(lang, diya, now, deity.localizedName(lang)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mukta(
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: level == JyotLevel.low && lit
                              ? const Color(0xFFBF360C)
                              : MandirTheme.secondaryMaroon,
                        ),
                      ),
                      if (lit) ...[
                        const SizedBox(height: 5),
                        GheeMeter(value: pct / 100),
                        const SizedBox(height: 3),
                        Text(
                          gheeLevelText(lang, controller),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.mukta(
                            fontSize: 11.5,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                            color: MandirTheme.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _Cta(lang: lang, diya: diya, now: now, onTap: onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.deity,
    required this.intensity,
    required this.flicker,
    required this.day,
    required this.lang,
  });

  final BhaktiDeity deity;
  final double intensity;
  final bool flicker;
  final int? day;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final dayLabel = day;
    return SizedBox(
      width: 66,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 2,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MandirTheme.imageSurface,
                border: Border.all(color: MandirTheme.goldenAccent, width: 1.4),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                deity.imageAsset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                cacheWidth: 144,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: JyotFlame(size: 32, intensity: intensity, flicker: flicker),
          ),
          if (dayLabel != null)
            Positioned(
              left: 4,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: MandirTheme.secondaryMaroon,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2B33C), width: 0.8),
                ),
                child: Text(
                  _t(lang, en: 'Day $dayLabel', hi: 'दिन $dayLabel', mr: 'दिवस $dayLabel'),
                  style: GoogleFonts.mukta(
                    fontSize: 9.5,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFFE9B0),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cta extends StatefulWidget {
  const _Cta({required this.lang, required this.diya, required this.now, required this.onTap});

  final String lang;
  final AkhandDiyaState diya;
  final DateTime now;
  final VoidCallback onTap;

  @override
  State<_Cta> createState() => _CtaState();
}

class _CtaState extends State<_Cta> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  bool get _urgent => widget.diya.everLit && widget.diya.gheePercent(widget.now) < 30;

  void _syncPulse() {
    final animate = _urgent && jyotAnimationsEnabled && !MediaQuery.of(context).disableAnimations;
    if (animate && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!animate && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(_Cta oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final diya = widget.diya;
    final pct = diya.gheePercent(widget.now);

    if (!diya.everLit) {
      return _pill(
        _t(lang, en: '🪔 Light', hi: '🪔 जलाएं', mr: '🪔 लावा'),
        filled: true,
      );
    }
    if (pct > 80) {
      return _pill(
        _t(lang, en: 'Offer ghee +', hi: 'घी अर्पण करें +', mr: 'तूप अर्पण करा +'),
        filled: false,
      );
    }
    if (!_urgent) {
      return _pill(_t(lang, en: 'Do aarti', hi: 'आरती करें', mr: 'आरती करा'), filled: true);
    }

    final label = diya.level(widget.now) == JyotLevel.out
        ? (diya.canRevive(widget.now)
            ? _t(lang, en: 'Save the Jyot!', hi: 'ज्योत बचाएं!', mr: 'ज्योत वाचवा!')
            : _t(lang, en: 'Light again', hi: 'फिर जलाएं', mr: 'पुन्हा लावा'))
        : _t(
            lang,
            en: 'Flame dimming! Do aarti',
            hi: 'ज्योत मंद हो रही है! आरती करें',
            mr: 'ज्योत मंद होत आहे! आरती करा',
          );
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.06 * _pulse.value,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5722).withValues(alpha: 0.25 + 0.35 * _pulse.value),
                blurRadius: 6 + 8 * _pulse.value,
              ),
            ],
          ),
          child: child,
        ),
      ),
      child: _pill(label, filled: true, urgent: true),
    );
  }

  Widget _pill(String label, {required bool filled, bool urgent = false}) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 96),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          gradient: filled
              ? LinearGradient(
                  colors: urgent
                      ? const [Color(0xFFD32F2F), Color(0xFFFF6D00)]
                      : const [Color(0xFFE65100), Color(0xFFFF9800)],
                )
              : null,
          color: filled ? null : const Color(0xFFFFF3D6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled ? Colors.transparent : MandirTheme.goldenAccent,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.mukta(
            fontSize: 11.5,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: filled ? Colors.white : MandirTheme.secondaryMaroon,
          ),
        ),
      ),
    );
  }
}

/// One-time card that lights the devotee's first Akhand Jyot.
class FirstLightDialog extends ConsumerStatefulWidget {
  const FirstLightDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) => const FirstLightDialog(),
      );

  /// Shows the card once per install, before the diya has ever been lit.
  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    final diya = ref.read(akhandDiyaProvider) ?? await ref.read(akhandDiyaProvider.notifier).ready;
    if (diya.everLit || await AkhandDiyaService.introSeen()) return;
    if (!context.mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    await AkhandDiyaService.markIntroSeen();
    BackendService.trackEvent('diya_intro_shown', item: ref.read(jyotDeityProvider).key);
    if (context.mounted) await show(context);
  }

  @override
  ConsumerState<FirstLightDialog> createState() => _FirstLightDialogState();
}

class _FirstLightDialogState extends ConsumerState<FirstLightDialog> {
  bool _lit = false;

  void _light() {
    if (_lit) return;
    HapticFeedback.heavyImpact();
    AudioService.ringTempleBell();
    setState(() => _lit = true);
    ref.read(akhandDiyaProvider.notifier).refill(source: 'first_light');
  }

  Future<void> _close() async {
    Navigator.of(context).pop();
    if (!_lit) {
      BackendService.trackEvent('diya_intro_later');
      return;
    }
    if (!await PushNotificationService.checkPermissionGranted()) {
      await PushNotificationService.requestNotificationPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final deity = ref.watch(jyotDeityProvider);
    final name = deity.localizedName(lang);

    final headline = _lit
        ? _t(
            lang,
            en: '🙏 Your Akhand Jyot is lit!',
            hi: '🙏 अखंड ज्योत प्रज्वलित हो गई!',
            mr: '🙏 अखंड ज्योत प्रज्वलित झाली!',
          )
        : _t(
            lang,
            en: 'Light the Akhand Jyot for $name in your home’s digital mandir',
            hi: 'अपने घर के डिजिटल मंदिर में $name के चरणों में अखंड ज्योत प्रज्वलित करें',
            mr: 'तुमच्या घरातील डिजिटल मंदिरात $name चरणी अखंड ज्योत प्रज्वलित करा',
          );
    final sub = _lit
        ? _t(
            lang,
            en: 'Do one aarti a day to refill the ghee. We’ll remind you before it runs low.',
            hi: 'रोज़ एक आरती करके घी भरें। घी कम होने से पहले हम आपको याद दिलाएंगे।',
            mr: 'रोज एक आरती करून तूप भरा. तूप कमी होण्यापूर्वी आम्ही आठवण करून देऊ.',
          )
        : _t(
            lang,
            en: 'One diya, one aarti a day — it keeps burning for 24 hours.',
            hi: 'एक दीया, रोज़ एक आरती — ज्योत 24 घंटे जलती रहेगी।',
            mr: 'एक दिवा, रोज एक आरती — ज्योत 24 तास तेवत राहील.',
          );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF8E8), Color(0xFFFBE3B8)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDCA65D), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x552E1104), blurRadius: 24, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MandirTheme.imageSurface,
                  border: Border.all(color: MandirTheme.goldenAccent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB300).withValues(alpha: _lit ? 0.6 : 0.15),
                      blurRadius: _lit ? 26 : 10,
                      spreadRadius: _lit ? 4 : 0,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  deity.imageAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _lit ? 1 : 0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => JyotFlame(size: 110, intensity: v),
              ),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: GoogleFonts.mukta(
                  fontSize: 17,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  color: MandirTheme.secondaryMaroon,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: GoogleFonts.mukta(fontSize: 13, height: 1.3, color: MandirTheme.textMuted),
              ),
              const SizedBox(height: 14),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _lit ? 1 : 0),
                duration: const Duration(milliseconds: 2000),
                curve: const Interval(0.35, 1, curve: Curves.easeInOut),
                builder: (_, v, _) {
                  final pct = (v * 100).round();
                  final span = formatGheeDuration(
                    Duration(minutes: (kGheeLife.inMinutes * v).round()),
                    lang,
                  );
                  return Column(
                    children: [
                      GheeMeter(value: v, height: 10),
                      const SizedBox(height: 5),
                      Text(
                        _t(
                          lang,
                          en: 'Ghee level: $pct% • $span',
                          hi: 'घी स्तर: $pct% • $span',
                          mr: 'तूप पातळी: $pct% • $span',
                        ),
                        style: GoogleFonts.mukta(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: MandirTheme.secondaryMaroon,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD84315), Color(0xFFFF8F00)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Color(0x40D84315), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: TextButton(
                    onPressed: _lit ? _close : _light,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _lit
                          ? _t(lang, en: 'Jai $name 🙏', hi: 'जय $name 🙏', mr: 'जय $name 🙏')
                          : _t(
                              lang,
                              en: '🪔 Light Akhand Diya',
                              hi: '🪔 ज्योत प्रज्वलित करें',
                              mr: '🪔 ज्योत प्रज्वलित करा',
                            ),
                      style: GoogleFonts.mukta(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              if (!_lit)
                TextButton(
                  onPressed: _close,
                  child: Text(
                    _t(lang, en: 'Later', hi: 'बाद में', mr: 'नंतर'),
                    style: GoogleFonts.mukta(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: MandirTheme.textMuted,
                    ),
                  ),
                )
              else
                const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

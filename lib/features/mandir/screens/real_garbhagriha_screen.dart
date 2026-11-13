import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/motion.dart';
import '../../../presentation/providers/akhand_diya_provider.dart';
import '../../../presentation/providers/locale_provider.dart';
import '../../../services/audio_service.dart';
import '../../../services/backend_service.dart';
import '../controllers/akhand_diya_controller.dart';
import '../../../presentation/screens/ishta_devta_screen.dart';
import '../widgets/mandir_aarti_session.dart';
import '../widgets/mandir_deity_picker.dart';
import '../widgets/mandir_painters.dart';
import '../widgets/mandir_stage.dart';

String _t(String lang, {required String en, required String hi, required String mr}) => switch (lang) {
  'hi' => hi,
  'mr' => mr,
  _ => en,
};

/// "24 घंटे 00 मिनट बाकी" for a ghee level of [ratio].
String _remainingText(String lang, double ratio) {
  final total = (ratio.clamp(0.0, 1.0) * kDiyaDecaySeconds).round();
  final h = total ~/ 3600;
  final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
  return _t(lang, en: '${h}h ${m}m left', hi: '$h घंटे $m मिनट बाकी', mr: '$h तास $m मिनिटे बाकी');
}

/// sin(πt): rises and falls back to zero.
class _BumpCurve extends Curve {
  const _BumpCurve();

  @override
  double transformInternal(double t) => math.sin(math.pi * t);
}

/// Width of each seva rail, including its margin from the screen edge.
const double _railWidth = 82;

/// Where every sanctum element sits on screen.
class _SanctumLayout {
  _SanctumLayout(this.size) {
    final w = size.width;
    final h = size.height;

    final archH = math.min(w * 0.88 * 1.25, h * 0.48);
    final archW = archH * 0.8;
    arch = Rect.fromLTWH((w - archW) / 2, h * 0.15, archW, archH);

    final pedestalY = arch.top + archH * 0.845;
    sinhasan = Rect.fromCenter(
      center: Offset(w / 2, pedestalY - archH * 0.035),
      width: archW * 0.52,
      height: archH * 0.1,
    );
    final murtiH = archH * 0.6;
    murti = Rect.fromLTWH(w / 2 - murtiH / 3, sinhasan.top + sinhasan.height * 0.35 - murtiH, murtiH * 2 / 3, murtiH);
    forehead = Offset(murti.center.dx, murti.top + murti.height * 0.2);
    feet = Rect.fromLTRB(
      murti.left + murti.width * 0.12,
      murti.top + murti.height * 0.8,
      murti.right - murti.width * 0.12,
      sinhasan.bottom,
    );

    altar = Rect.fromLTRB(-w * 0.02, arch.bottom + h * 0.005, w * 1.02, h);
    altarFloor = altar.top + altar.height * altarTop * 0.9;

    final dW = math.min(w * 0.46, altar.height * 0.62);
    final dH = dW / 1.5;
    diya = Rect.fromLTWH(w * 0.42 - dW / 2, altarFloor - dH, dW, dH);
    wick = Offset(diya.center.dx, diya.top + dH * 0.235);
    final fW = dW * 0.42;
    final fH = dW * 0.62;
    flame = Rect.fromLTWH(wick.dx - fW / 2, wick.dy - fH * 0.96, fW, fH);
    bowl = Offset(diya.center.dx + dW * 0.1, diya.top + dH * 0.29);

    final kW = dW * 0.68;
    final kH = kW / 1.094;
    kalash = Rect.fromLTWH(w * 0.68 - kW / 2, altarFloor - kH, kW, kH);
    spoutLocal = kalash.topLeft + Offset(kW * 0.05, kH * 0.28);

    naivedya = Rect.fromCenter(center: Offset(w * 0.68, sinhasan.bottom + w * 0.03), width: w * 0.2, height: w * 0.13);
    dhoop = Rect.fromLTWH(w * 0.24, sinhasan.bottom - h * 0.12, w * 0.09, h * 0.14);

    pillarLeft = Rect.fromLTWH(-w * 0.03, h * 0.07, w * 0.09, h * 0.93);
    pillarRight = Rect.fromLTWH(w * 0.94, h * 0.07, w * 0.09, h * 0.93);
    toran = Rect.fromLTWH(-w * 0.02, h * 0.085, w * 1.04, h * 0.075);
    final bellW = w * 0.14;
    bellLeft = Rect.fromLTWH(w * 0.17 - bellW / 2, h * 0.15, bellW, bellW * 1.25);
    bellRight = Rect.fromLTWH(w * 0.83 - bellW / 2, h * 0.15, bellW, bellW * 1.25);

    thaliWidth = math.min(w * 0.34, 150);
    thaliStart = Offset(w / 2, sinhasan.bottom + thaliWidth * 0.1);
  }

  /// Share of the altar height taken by the chowki's top surface.
  static const altarTop = 0.42;
  static const tiltAngle = -0.95;

  final Size size;
  late final Rect arch;
  late final Rect sinhasan;
  late final Rect murti;
  late final Offset forehead;
  late final Rect feet;
  late final Rect altar;

  /// Where the chowki's top surface meets its draped front.
  late final double altarFloor;
  late final Rect diya;
  late final Offset wick;
  late final Rect flame;
  late final Offset bowl;
  late final Rect kalash;
  late final Offset spoutLocal;
  late final Rect naivedya;
  late final Rect dhoop;
  late final Rect pillarLeft;
  late final Rect pillarRight;
  late final Rect toran;
  late final Rect bellLeft;
  late final Rect bellRight;
  late final double thaliWidth;
  late final Offset thaliStart;

  static Offset _rotate(Offset v, double a) =>
      Offset(v.dx * math.cos(a) - v.dy * math.sin(a), v.dx * math.sin(a) + v.dy * math.cos(a));

  /// Kalash pose while pouring: [amount] 0 at rest, 1 tilted over the diya.
  ({Offset center, double angle, Offset spout}) kalashPose(double amount) {
    final rest = kalash.center;
    final rel = spoutLocal - rest;
    final tiltedRel = _rotate(rel, tiltAngle);
    final target = bowl + Offset(kalash.width * 0.04, -kalash.height * 0.36) - tiltedRel;
    final center = Offset.lerp(rest, target, amount)!;
    final angle = tiltAngle * amount;
    return (center: center, angle: angle, spout: center + _rotate(rel, angle));
  }
}

/// The Garbhagriha: the devotee's Ishta Devta, the burning Akhand Diya and
/// every daily Mandir seva, behind a walk-in temple door.
class RealGarbhagrihaScreen extends ConsumerStatefulWidget {
  const RealGarbhagrihaScreen({super.key});

  @override
  ConsumerState<RealGarbhagrihaScreen> createState() => _RealGarbhagrihaScreenState();
}

class _RealGarbhagrihaScreenState extends ConsumerState<RealGarbhagrihaScreen> with TickerProviderStateMixin {
  final _audio = AudioService();

  late final AnimationController _pour = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  late final Animation<double> _surge = CurvedAnimation(
    parent: _pour,
    curve: const Interval(0.3, 1, curve: _BumpCurve()),
  );
  late final AnimationController _petals = _controller(5500);
  late final AnimationController _garland = _controller(1400);
  late final AnimationController _tilak = _controller(1100);
  late final AnimationController _blessing = _controller(2400);
  late final AnimationController _shankh = _controller(3200);
  late final AnimationController _naivedya = _controller(650);
  late final AnimationController _bellLeft = _controller(2200);
  late final AnimationController _bellRight = _controller(2200);
  late final AnimationController _rails = _controller(900);

  Timer? _railsDelay;
  Timer? _hintTimer;
  Timer? _completeTimer;
  double _ratioBeforePour = 1;
  bool _streamHapticFired = false;
  bool _aarti = false;
  bool _thaliHint = false;
  bool _aartiComplete = false;
  bool _tilakApplied = false;
  bool _naivedyaPlaced = false;
  double _bellLeftAmp = 0;
  double _bellRightAmp = 0;

  AnimationController _controller(int ms) => AnimationController(
    vsync: this,
    duration: Duration(milliseconds: ms),
  );

  String get _lang => ref.read(localeProvider).languageCode;

  @override
  void initState() {
    super.initState();
    _pour.addListener(_onPourTick);
    // Rails slide in as the temple doors finish opening.
    _railsDelay = Timer(const Duration(milliseconds: 1250), () {
      if (mounted) _rails.forward();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(akhandDiyaControllerProvider.notifier).ensureLit();
      BackendService.trackEvent('mandir_open', item: ref.read(jyotDeityProvider).key);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) _rails.value = 1;
  }

  @override
  void dispose() {
    _railsDelay?.cancel();
    _hintTimer?.cancel();
    _completeTimer?.cancel();
    _audio.dispose();
    for (final c in [_pour, _petals, _garland, _tilak, _blessing, _shankh, _naivedya, _bellLeft, _bellRight, _rails]) {
      c.dispose();
    }
    super.dispose();
  }

  void _track(String ritual) =>
      BackendService.trackEvent('mandir_ritual', item: ref.read(jyotDeityProvider).key, props: {'ritual': ritual});

  // ── Rituals ───────────────────────────────────────────────────────────────

  Future<void> _pourGhee() async {
    if (_pour.isAnimating) return;
    final diya = ref.read(akhandDiyaControllerProvider.notifier);
    _ratioBeforePour = diya.gheeRatio;
    _streamHapticFired = false;
    HapticFeedback.mediumImpact();
    _pour.forward(from: 0);
    _track('ghee');
    await diya.pourGheeAndRefill();
  }

  void _onPourTick() {
    if (!_streamHapticFired && _pour.value >= 0.32) {
      _streamHapticFired = true;
      HapticFeedback.heavyImpact();
    }
  }

  void _toggleAarti() {
    _hintTimer?.cancel();
    _completeTimer?.cancel();
    setState(() {
      _aarti = !_aarti;
      _thaliHint = _aarti;
      _aartiComplete = false;
    });
    if (_aarti) {
      _hintTimer = Timer(const Duration(milliseconds: 3200), () {
        if (mounted) setState(() => _thaliHint = false);
      });
    }
    HapticFeedback.mediumImpact();
    if (!_aarti) _onSingAlong(false);
    if (_aarti) _track('aarti');
  }

  /// The aarti ghanti accompanies the devotee only when no video is playing.
  void _onSingAlong(bool singing) {
    if (singing != _audio.bellPlaying.value) _audio.toggleBell();
  }

  Future<void> _onAartiComplete() async {
    _track('aarti_complete');
    _completeTimer?.cancel();
    setState(() => _aartiComplete = true);
    _completeTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _aartiComplete = false);
    });
    _garland.forward();
    _petals.forward(from: 0);
    _blessing.forward(from: 0);
    _shankh.forward(from: 0);
    HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    AudioService.ringTempleBell();
    _strikeBell(left: true);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (mounted) _strikeBell(left: false, direction: -1);
  }

  void _pushpanjali() {
    HapticFeedback.lightImpact();
    _garland.forward();
    _petals.forward(from: 0);
    _track('pushpanjali');
  }

  void _strikeBell({required bool left, double direction = 1, double strength = 1}) {
    final amp = 0.42 * strength.clamp(0.5, 1.6) * direction.sign;
    setState(() {
      if (left) {
        _bellLeftAmp = amp;
      } else {
        _bellRightAmp = amp;
      }
    });
    (left ? _bellLeft : _bellRight).forward(from: 0);
    HapticFeedback.mediumImpact();
    AudioService.ringTempleBell();
  }

  Future<void> _ghantaNaad() async {
    _track('ghanta');
    _strikeBell(left: true);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (mounted) _strikeBell(left: false, direction: -1);
  }

  Future<void> _shankhNaad() async {
    _shankh.forward(from: 0);
    _track('shankh');
    if (!_audio.conchPlaying.value) {
      unawaited(_audio.toggleConch());
    } else {
      HapticFeedback.heavyImpact();
    }
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (!mounted) return;
      HapticFeedback.vibrate();
    }
  }

  // ignore: unused_element
  void _applyTilak() {
    setState(() => _tilakApplied = true);
    _tilak.forward(from: 0);
    HapticFeedback.mediumImpact();
    _track('tilak');
  }

  // ignore: unused_element
  Future<void> _charanSparsh() async {
    _blessing.forward(from: 0);
    _track('charan_sparsh');
    HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 110));
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 110));
    HapticFeedback.mediumImpact();
  }

  void _placeNaivedya() {
    setState(() => _naivedyaPlaced = true);
    _naivedya.forward(from: 0);
    HapticFeedback.mediumImpact();
    _track('naivedya');
  }

  Future<void> _changeDeity() async {
    final choice = await showMandirDeityPicker(context);
    if (choice == null || !mounted) return;
    final (deity, aarti) = choice;
    changeIshtaDevta(ref, deity, aarti, source: 'mandir');
    setState(() {
      _tilakApplied = false;
      _naivedyaPlaced = false;
    });
    _garland.value = 0;
    _blessing.forward(from: 0);
    HapticFeedback.heavyImpact();
    _track('change_deity');
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final diya = ref.watch(akhandDiyaControllerProvider.notifier);
    final lang = ref.watch(localeProvider).languageCode;
    final deity = ref.watch(jyotDeityProvider);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final padding = MediaQuery.paddingOf(context);

    final leftSevas = [
      _Seva(SevaIcon.ghee, _t(lang, en: 'Offer ghee +', hi: 'घी अर्पण करें +', mr: 'तूप अर्पण करा +'), _pourGhee),
      _Seva(
        SevaIcon.aarti,
        _t(lang, en: 'Aarti thali', hi: 'आरती थाली', mr: 'आरती ताट'),
        _toggleAarti,
        active: _aarti,
      ),
      _Seva(SevaIcon.pushpanjali, _t(lang, en: 'Pushpanjali', hi: 'पुष्पांजलि', mr: 'पुष्पांजली'), _pushpanjali),
      _Seva(SevaIcon.ghanta, _t(lang, en: 'Ring bell', hi: 'घंटा नाद', mr: 'घंटानाद'), _ghantaNaad),
    ];
    final rightSevas = [
      _Seva(SevaIcon.shankh, _t(lang, en: 'Shankh naad', hi: 'शंखनाद', mr: 'शंखनाद'), _shankhNaad),
      _Seva(SevaIcon.naivedya, _t(lang, en: 'Naivedya bhog', hi: 'नैवेद्य भोग', mr: 'नैवेद्य'), _placeNaivedya),
      _Seva(SevaIcon.changeDeity, _t(lang, en: 'Change deity', hi: 'देवता बदलें', mr: 'देवता बदला'), _changeDeity),
      // TODO: temporarily hidden.
      // _Seva(SevaIcon.tilak, _t(lang, en: 'Kumkum tilak', hi: 'कुमकुम तिलक', mr: 'कुंकू तिलक'), _applyTilak),
      // _Seva(SevaIcon.charan, _t(lang, en: 'Charan sparsh', hi: 'चरण स्पर्श', mr: 'चरणस्पर्श'), _charanSparsh),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF140604),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final l = _SanctumLayout(constraints.biggest);
            final railTop = constraints.maxHeight * 0.47;
            return Stack(
              fit: StackFit.expand,
              children: [
                MandirStage(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _background(l, dpr),
                      _archLayer(l, dpr),
                      _deityLayer(l, dpr, deity.imageAsset),
                      _altarLayer(l, dpr, diya),
                      _outerLayer(l, dpr),
                      if (_aarti)
                        _AartiThali(start: l.thaliStart, width: l.thaliWidth, orbitCenter: l.murti.center, dpr: dpr),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: _GheeStatusBar(
                    lang: lang,
                    deityName: deity.localizedName(lang),
                    diya: diya,
                    pour: _pour,
                    ratioBeforePour: () => _ratioBeforePour,
                    onPour: _pourGhee,
                    topPadding: padding.top,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: padding.top + 118,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _thaliHint ? 1 : 0,
                      duration: AppMotion.entrance,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xCC2A0E06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Brass.gold.withValues(alpha: 0.7), width: 0.8),
                          ),
                          child: Text(
                            _t(
                              lang,
                              en: 'Move the thali freely with your finger',
                              hi: 'थाली को उंगली से किसी भी दिशा में घुमाएं',
                              mr: 'ताट बोटाने कोणत्याही दिशेने फिरवा',
                            ),
                            style: GoogleFonts.mukta(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFE9B0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: railTop,
                  bottom: padding.bottom + 10,
                  width: _railWidth,
                  child: _SevaRail(sevas: leftSevas, fromLeft: true, entrance: _rails),
                ),
                Positioned(
                  right: 0,
                  top: railTop,
                  bottom: padding.bottom + 10,
                  width: _railWidth,
                  child: _SevaRail(sevas: rightSevas, fromLeft: false, entrance: _rails),
                ),
                if (_aarti)
                  MandirAartiSession(
                    key: ValueKey(deity.key),
                    panel: _lyricsPanel(l, padding),
                    videoTop: padding.top + 118,
                    face: Rect.fromLTRB(
                      l.murti.center.dx - l.murti.width * 0.26,
                      l.murti.top,
                      l.murti.center.dx + l.murti.width * 0.26,
                      l.murti.top + l.murti.height * 0.45,
                    ),
                    onSingAlong: _onSingAlong,
                    onCompleted: _onAartiComplete,
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: padding.top + 118,
                  child: AnimatedSwitcher(
                    duration: AppMotion.entrance,
                    child: _aartiComplete
                        ? _AartiCompleteBanner(lang: lang, onPour: _pourGhee)
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The chowki's draped front, between the seva rails.
  Rect _lyricsPanel(_SanctumLayout l, EdgeInsets padding) {
    final bottom = l.size.height - padding.bottom - 8;
    final top = math.min(l.altarFloor + 6, bottom - 200);
    return Rect.fromLTRB(_railWidth, top, l.size.width - _railWidth, bottom);
  }

  Widget _background(_SanctumLayout l, double dpr) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MandirAssetImage(
          MandirAssets.sanctum,
          fallback: const SanctumWallPainter(),
          fit: BoxFit.cover,
          cacheWidth: (l.size.width * dpr).round(),
        ),
        _ClockPaint((c) => GodRaysPainter(c)),
        _ClockPaint((c) => PranaDustPainter(c)),
      ],
    );
  }

  Widget _archLayer(_SanctumLayout l, double dpr) {
    return Stack(
      children: [
        Positioned.fromRect(
          rect: l.arch.inflate(l.arch.width * 0.25),
          child: const DecoratedBox(
            decoration: BoxDecoration(gradient: RadialGradient(colors: [Color(0x55FFB74D), Color(0x00FFB74D)])),
          ),
        ),
        Positioned.fromRect(
          rect: l.arch,
          child: MandirAssetImage(
            MandirAssets.prabhavaliArch,
            fallback: const PrabhavaliArchPainter(),
            cacheWidth: (l.arch.width * dpr).round(),
          ),
        ),
      ],
    );
  }

  Widget _deityLayer(_SanctumLayout l, double dpr, String imageAsset) {
    final tilakSize = l.murti.width * 0.2;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fromRect(
          rect: l.sinhasan,
          child: const _GoldShimmer(
            child: CustomPaint(painter: SinhasanPainter(), size: Size.infinite),
          ),
        ),
        Positioned.fromRect(
          rect: l.murti,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 650),
            switchInCurve: AppMotion.easeOut,
            switchOutCurve: AppMotion.easeOut,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween(begin: 0.9, end: 1.0).animate(animation),
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
            child: _GoldShimmer(
              key: ValueKey(imageAsset),
              child: Image.asset(
                imageAsset,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                cacheWidth: (l.murti.width * dpr).round(),
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: l.murti,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _garland,
              builder: (_, _) => CustomPaint(painter: GarlandPainter(_garland.value)),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: Rect.fromCenter(center: l.forehead, width: tilakSize, height: tilakSize),
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _tilak,
              builder: (_, _) => CustomPaint(painter: TilakPainter(_tilakApplied ? math.max(_tilak.value, 0.02) : 0)),
            ),
          ),
        ),
        // TODO: temporarily hidden. Touch the murti directly: forehead for tilak, feet for charan sparsh.
        // Positioned.fromRect(
        //   rect: Rect.fromCenter(center: l.forehead, width: l.murti.width * 0.36, height: l.murti.height * 0.2),
        //   child: Semantics(
        //     button: true,
        //     label: _t(_lang, en: 'Apply tilak', hi: 'कुमकुम तिलक', mr: 'कुंकू तिलक'),
        //     child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _applyTilak),
        //   ),
        // ),
        // Positioned.fromRect(
        //   rect: l.feet,
        //   child: Semantics(
        //     button: true,
        //     label: _t(_lang, en: 'Charan sparsh', hi: 'चरण स्पर्श', mr: 'चरणस्पर्श'),
        //     child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _charanSparsh),
        //   ),
        // ),
        IgnorePointer(
          child: CustomPaint(
            painter: BlessingParticlesPainter(progress: _blessing, origin: l.feet.bottomCenter, spread: l.feet.width),
          ),
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: SoundRipplePainter(
              progress: _shankh,
              center: l.murti.center,
              maxRadius: l.size.longestSide * 0.75,
            ),
          ),
        ),
        IgnorePointer(child: CustomPaint(painter: PetalRainPainter(_petals))),
      ],
    );
  }

  Widget _altarLayer(_SanctumLayout l, double dpr, AkhandDiyaController diya) {
    final displayed = Listenable.merge([_pour, diya]);

    double shownRatio() {
      final p = _pour.value;
      if (p <= 0 || p >= 1) return diya.gheeRatio;
      final fill = const Interval(0.32, 0.78, curve: Curves.easeInOut).transform(p);
      return lerpDouble(_ratioBeforePour, 1, fill)!;
    }

    double pourAmount(double p) {
      final up = Curves.easeOutCubic.transform((p / 0.3).clamp(0.0, 1.0));
      final down = AppMotion.easeInOut.transform(((p - 0.8) / 0.2).clamp(0.0, 1.0));
      return up * (1 - down);
    }

    double flow(double p) {
      if (p < 0.28 || p > 0.8) return 0;
      if (p < 0.36) return (p - 0.28) / 0.08;
      if (p > 0.72) return (0.8 - p) / 0.08;
      return 1;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fromRect(rect: l.dhoop, child: _ClockPaint((c) => DhoopSmokePainter(c))),
        if (_naivedyaPlaced)
          Positioned.fromRect(
            rect: l.naivedya,
            child: AnimatedBuilder(
              animation: _naivedya,
              child: const CustomPaint(painter: NaivedyaPainter()),
              builder: (_, child) {
                final v = Curves.easeOutBack.transform(_naivedya.value);
                return Opacity(
                  opacity: _naivedya.value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - v) * -40),
                    child: Transform.scale(scale: 0.7 + 0.3 * v, child: child),
                  ),
                );
              },
            ),
          ),
        Positioned.fromRect(
          rect: l.altar,
          child: const CustomPaint(painter: AltarPainter(topFraction: _SanctumLayout.altarTop)),
        ),
        Positioned.fromRect(
          rect: l.diya.inflate(l.diya.width * 0.35),
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: displayed,
              builder: (_, _) {
                final glow = shownRatio();
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2),
                      colors: [
                        const Color(0xFFFFA726).withValues(alpha: 0.10 + 0.28 * glow + 0.2 * _surge.value),
                        const Color(0x00FFA726),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned.fromRect(
          rect: l.diya,
          child: Semantics(
            button: true,
            label: _t(_lang, en: 'Offer ghee', hi: 'घी अर्पण करें', mr: 'तूप अर्पण करा'),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _pourGhee,
              child: MandirAssetImage(
                MandirAssets.akhandDiya,
                fallback: const BrassDiyaPainter(),
                cacheWidth: (l.diya.width * dpr).round(),
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: l.flame,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: diya,
              builder: (context, _) {
                final r = diya.everLit ? diya.gheeRatio : 0.0;
                return _ClockPaint(
                  (c) => FlamePainter(clock: c, intensity: r <= 0 ? 0 : 0.45 + 0.55 * r, surge: _surge),
                );
              },
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _pour,
          builder: (context, _) {
            final p = _pour.value;
            final pose = l.kalashPose(pourAmount(p));
            final rest = l.kalash;
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fromRect(
                  rect: rest,
                  child: Transform.translate(
                    offset: pose.center - rest.center,
                    child: Transform.rotate(
                      angle: pose.angle,
                      child: Semantics(
                        button: true,
                        label: _t(_lang, en: 'Ghee kalash', hi: 'घी कलश', mr: 'तूप कलश'),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _pourGhee,
                          child: MandirAssetImage(
                            MandirAssets.gheeKalash,
                            fallback: const KalashPainter(),
                            cacheWidth: (rest.width * dpr).round(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: GheeStreamPainter(from: pose.spout, to: l.bowl, flow: flow(p), t: p * 2.6),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _outerLayer(_SanctumLayout l, double dpr) {
    Widget bell(bool left) {
      final rect = left ? l.bellLeft : l.bellRight;
      final ctrl = left ? _bellLeft : _bellRight;
      return Positioned.fromRect(
        rect: rect,
        child: Semantics(
          button: true,
          label: _t(_lang, en: 'Temple bell', hi: 'मंदिर की घंटी', mr: 'मंदिराची घंटा'),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _strikeBell(left: left, direction: left ? 1 : -1),
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              _strikeBell(left: left, direction: v == 0 ? 1 : v, strength: 0.6 + v.abs() / 1500);
            },
            child: AnimatedBuilder(
              animation: ctrl,
              child: MandirAssetImage(
                MandirAssets.templeBell,
                fallback: const TempleBellPainter(),
                cacheWidth: (rect.width * dpr).round(),
              ),
              builder: (_, child) {
                final tau = ctrl.value * 2.2;
                final amp = left ? _bellLeftAmp : _bellRightAmp;
                final swing = ctrl.isAnimating ? amp * math.sin(tau * math.pi * 6) * math.exp(-3.2 * tau) : 0.0;
                return Transform.rotate(angle: swing, alignment: Alignment.topCenter, child: child);
              },
            ),
          ),
        ),
      );
    }

    Widget ripple(bool left) {
      final rect = left ? l.bellLeft : l.bellRight;
      return IgnorePointer(
        child: CustomPaint(
          painter: SoundRipplePainter(
            progress: left ? _bellLeft : _bellRight,
            center: rect.bottomCenter.translate(0, -rect.height * 0.08),
            maxRadius: l.size.width * 0.24,
            rings: 3,
            squash: 0.55,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fromRect(
          rect: l.pillarLeft,
          child: const CustomPaint(painter: TemplePillarPainter(left: true)),
        ),
        Positioned.fromRect(
          rect: l.pillarRight,
          child: const CustomPaint(painter: TemplePillarPainter(left: false)),
        ),
        Positioned.fromRect(
          rect: l.toran,
          child: IgnorePointer(child: _ClockPaint((c) => ToranPainter(c))),
        ),
        ripple(true),
        ripple(false),
        bell(true),
        bell(false),
      ],
    );
  }
}

/// CustomPaint whose painter animates off the stage clock.
class _ClockPaint extends StatelessWidget {
  const _ClockPaint(this.painter);

  final CustomPainter Function(ValueListenable<double> clock) painter;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: painter(MandirClockScope.of(context)), size: Size.infinite),
    );
  }
}

/// Slow band of lamplight gliding across gold surfaces.
class _GoldShimmer extends StatelessWidget {
  const _GoldShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final clock = MandirClockScope.of(context);
    return AnimatedBuilder(
      animation: clock,
      child: RepaintBoundary(child: child),
      builder: (context, child) {
        final pos = math.sin(clock.value * 0.35) * 1.3;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(-1.6 + pos, -1),
            end: Alignment(1.6 + pos, 1),
            colors: const [
              Color(0x00FFE8A3),
              Color(0x00FFE8A3),
              Color(0x55FFF1C1),
              Color(0x00FFE8A3),
              Color(0x00FFE8A3),
            ],
            stops: const [0, 0.4, 0.5, 0.6, 1],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

/// Real brass aarti thali that follows the devotee's finger anywhere on
/// screen. It carries weight (eases after the hand), tilts with the swing,
/// and its flame trails the motion and sheds golden sparks.
class _AartiThali extends StatefulWidget {
  const _AartiThali({required this.start, required this.width, required this.orbitCenter, required this.dpr});

  final Offset start;
  final double width;

  /// The murti; a soft haptic marks every quarter turn around it.
  final Offset orbitCenter;
  final double dpr;

  @override
  State<_AartiThali> createState() => _AartiThaliState();
}

class _AartiThaliState extends State<_AartiThali> {
  static const _follow = 0.28;

  final List<AartiSpark> _sparks = [];
  late Offset _pos = widget.start;
  late Offset _target = widget.start;
  Offset _grab = Offset.zero;
  double _tilt = 0;
  double _lean = 0;
  double _orbitAngle = 0;
  double _travelled = 0;
  int _quarters = 0;
  int _sparkSeed = 0;
  ValueListenable<double>? _clock;
  double _lastT = 0;

  /// Plate centre within the thali box, as a share of its width.
  static const _plateCenterY = 0.56;
  static const _heightFactor = 0.85;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final clock = MandirClockScope.of(context);
    if (clock != _clock) {
      _clock?.removeListener(_step);
      _clock = clock..addListener(_step);
      _lastT = clock.value;
    }
    _orbitAngle = _angleAround(_pos);
  }

  @override
  void dispose() {
    _clock?.removeListener(_step);
    super.dispose();
  }

  double _angleAround(Offset p) => (p - widget.orbitCenter).direction;

  void _step() {
    final now = _clock!.value;
    final frames = ((now - _lastT) * 60).clamp(0.0, 3.0);
    _lastT = now;
    final k = 1 - math.pow(1 - _follow, frames).toDouble();

    final prev = _pos;
    _pos = Offset.lerp(_pos, _target, k)!;
    final vel = _pos - prev;
    final speed = vel.distance;

    _tilt += ((vel.dx * 0.012).clamp(-0.2, 0.2) - _tilt) * 0.2;
    _lean += ((-vel.dx / 9).clamp(-1.0, 1.0) - _lean) * 0.25;

    if (speed > 0.8) {
      final steps = math.max(1, (speed / 6).ceil());
      for (var i = 1; i <= steps; i++) {
        final p = Offset.lerp(prev, _pos, i / steps)!;
        _sparks.add(AartiSpark(p.translate(0, -widget.width * 0.32), now, _sparkSeed++));
      }
      final a = _angleAround(_pos);
      var delta = a - _orbitAngle;
      if (delta > math.pi) delta -= 2 * math.pi;
      if (delta < -math.pi) delta += 2 * math.pi;
      _orbitAngle = a;
      _travelled += delta.abs();
      final q = (_travelled / (math.pi / 2)).floor();
      if (q > _quarters) {
        _quarters = q;
        HapticFeedback.lightImpact();
      }
    }
    _sparks.removeWhere((s) => now - s.born > SparkTrailPainter.life);

    if (speed > 0.05 || _tilt.abs() > 0.002 || _lean.abs() > 0.01) setState(() {});
  }

  Offset _clamp(Offset p) {
    final size = (context.findRenderObject() as RenderBox?)?.size;
    if (size == null) return p;
    final w = widget.width;
    return Offset(
      p.dx.clamp(w * 0.5, size.width - w * 0.5),
      p.dy.clamp(w * _plateCenterY, size.height - w * (_heightFactor - _plateCenterY)),
    );
  }

  void _onStart(DragStartDetails d) {
    final grabbed = (d.localPosition - _pos).distance < widget.width * 0.6;
    // Off the plate, the thali glides to the finger and rides just above it.
    _grab = grabbed ? _pos - d.localPosition : Offset(0, -widget.width * 0.28);
    _target = _clamp(d.localPosition + _grab);
  }

  void _onUpdate(DragUpdateDetails d) => _target = _clamp(d.localPosition + _grab);

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = w * _heightFactor;
    final clock = _clock!;
    final dW = w * 0.48;
    final dH = dW / 1.5;
    final diyaTop = w * (_plateCenterY + 0.03) - dH * 0.88;
    final wickY = diyaTop + dH * 0.235;
    final fW = w * 0.22;
    final fH = w * 0.36;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.entrance,
      curve: AppMotion.easeOut,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.scale(scale: 0.85 + 0.15 * v, child: child),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: _onStart,
        onPanUpdate: _onUpdate,
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: CustomPaint(
                painter: SparkTrailPainter(clock: clock, sparks: _sparks),
              ),
            ),
            Positioned(
              left: _pos.dx - w / 2,
              top: _pos.dy - w * _plateCenterY,
              width: w,
              height: h,
              child: Transform.rotate(
                angle: _tilt,
                alignment: const Alignment(0, 0.3),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned.fill(child: CustomPaint(painter: AartiThaliPainter())),
                    Positioned(
                      left: (w - dW) / 2,
                      top: diyaTop,
                      width: dW,
                      height: dH,
                      child: MandirAssetImage(
                        MandirAssets.akhandDiya,
                        fallback: const BrassDiyaPainter(),
                        cacheWidth: (dW * widget.dpr).round(),
                      ),
                    ),
                    Positioned(
                      left: (w - fW) / 2,
                      top: wickY - fH * 0.96,
                      width: fW,
                      height: fH,
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: FlamePainter(clock: clock, intensity: 0.9, seed: 3, lean: _lean),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top status: deity, live ghee level, streak and the ghee CTA.
class _GheeStatusBar extends StatelessWidget {
  const _GheeStatusBar({
    required this.lang,
    required this.deityName,
    required this.diya,
    required this.pour,
    required this.ratioBeforePour,
    required this.onPour,
    required this.topPadding,
  });

  final String lang;
  final String deityName;
  final AkhandDiyaController diya;
  final Animation<double> pour;
  final double Function() ratioBeforePour;
  final VoidCallback onPour;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, topPadding + 6, 14, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE6140604), Color(0xB3140604), Color(0x00140604)],
          stops: [0, 0.7, 1],
        ),
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([pour, diya]),
        builder: (context, _) {
          final p = pour.value;
          final pouring = p > 0 && p < 1;
          final ratio = pouring
              ? lerpDouble(ratioBeforePour(), 1, const Interval(0.32, 0.78, curve: Curves.easeInOut).transform(p))!
              : diya.gheeRatio;
          final pct = (ratio * 100).round();
          final day = math.max(diya.streakDays, 1);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: const Color(0xFFFFE9B0),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deityName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.mukta(
                            fontSize: 18,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFFE9B0),
                          ),
                        ),
                        Text(
                          _t(
                            lang,
                            en: 'Present in the Garbhagriha',
                            hi: 'गर्भगृह में विराजमान',
                            mr: 'गर्भगृहात विराजमान',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.mukta(fontSize: 12, height: 1.1, color: const Color(0xCCFFE9B0)),
                        ),
                      ],
                    ),
                  ),
                  _DayBadge(
                    label: _t(lang, en: 'Day $day', hi: 'दिन $day', mr: 'दिवस $day'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GheeBar(value: ratio),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_t(lang, en: 'Ghee', hi: 'घी', mr: 'तूप')} $pct% • ${_remainingText(lang, ratio)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.mukta(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFE9B0),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        _GoldPill(
                          label: _t(lang, en: 'Offer ghee +', hi: 'घी अर्पण करें +', mr: 'तूप अर्पण करा +'),
                          onTap: onPour,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GheeBar extends StatelessWidget {
  const _GheeBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0x33FFE9B0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x55E2B33C), width: 0.6),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: v,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: v < 0.3
                  ? const [Color(0xFFD84315), Color(0xFFFF8F00)]
                  : const [Color(0xFFFF8F00), Color(0xFFFFD54F)],
            ),
            boxShadow: const [BoxShadow(color: Color(0x88FFB300), blurRadius: 6)],
          ),
        ),
      ),
    );
  }
}

class _DayBadge extends StatelessWidget {
  const _DayBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF7B1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Brass.gold, width: 0.8),
      ),
      child: Text(
        label,
        style: GoogleFonts.mukta(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFFFFE9B0)),
      ),
    );
  }
}

class _GoldPill extends StatelessWidget {
  const _GoldPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFFA000)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x66FF8F00), blurRadius: 10)],
          ),
          child: Text(
            label,
            style: GoogleFonts.mukta(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Shown when the aarti ends: the moment to offer ghee to the jyot.
class _AartiCompleteBanner extends StatelessWidget {
  const _AartiCompleteBanner({required this.lang, required this.onPour});

  final String lang;
  final VoidCallback onPour;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xE62A0E06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Brass.gold, width: 0.9),
          boxShadow: const [BoxShadow(color: Color(0x66FFB300), blurRadius: 16)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _t(lang, en: 'Aarti complete • Jai ho', hi: 'आरती संपन्न • जय हो', mr: 'आरती संपन्न • जय हो'),
                style: GoogleFonts.mukta(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFFFFE9B0)),
              ),
            ),
            const SizedBox(width: 10),
            _GoldPill(
              label: _t(lang, en: 'Offer ghee +', hi: 'घी अर्पण करें +', mr: 'तूप अर्पण करा +'),
              onTap: onPour,
            ),
          ],
        ),
      ),
    );
  }
}

class _Seva {
  const _Seva(this.icon, this.label, this.onTap, {this.active = false});

  final SevaIcon icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
}

/// One side's column of seva medallions, sliding in from its screen edge.
class _SevaRail extends StatelessWidget {
  const _SevaRail({required this.sevas, required this.fromLeft, required this.entrance});

  final List<_Seva> sevas;
  final bool fromLeft;
  final Animation<double> entrance;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < sevas.length; i++)
          AnimatedBuilder(
            animation: entrance,
            child: _SevaMedallion(seva: sevas[i]),
            builder: (context, child) {
              final start = i * 0.12;
              final v = AppMotion.easeOut.transform(((entrance.value - start) / (1 - start - 0.2)).clamp(0.0, 1.0));
              return Opacity(
                opacity: v,
                child: Transform.translate(offset: Offset((fromLeft ? -1 : 1) * (1 - v) * 60, 0), child: child),
              );
            },
          ),
      ],
    );
  }
}

class _SevaMedallion extends StatefulWidget {
  const _SevaMedallion({required this.seva});

  final _Seva seva;

  @override
  State<_SevaMedallion> createState() => _SevaMedallionState();
}

class _SevaMedallionState extends State<_SevaMedallion> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final seva = widget.seva;
    const size = 56.0;
    return Semantics(
      button: true,
      toggled: seva.active ? true : null,
      label: seva.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: seva.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: AppMotion.press,
          curve: AppMotion.easeOut,
          child: SizedBox(
            width: _railWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: AppMotion.state,
                  curve: AppMotion.easeOut,
                  width: size,
                  height: size,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        Color(0xFFFFE9A8),
                        Color(0xFF9A6B1C),
                        Color(0xFFF7D27A),
                        Color(0xFF7A5414),
                        Color(0xFFFFE9A8),
                      ],
                    ),
                    boxShadow: [
                      const BoxShadow(color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 3)),
                      if (seva.active) const BoxShadow(color: Color(0xAAFFB300), blurRadius: 18, spreadRadius: 2),
                    ],
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.4),
                        colors: seva.active
                            ? const [Color(0xFFB4470F), Color(0xFF6A1E05)]
                            : const [Color(0xFF6E2414), Color(0xFF2A0B05)],
                      ),
                      border: Border.all(color: const Color(0x66FFE9A8), width: 0.8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: CustomPaint(painter: SevaIconPainter(seva.icon)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: const Color(0xB3140604), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    seva.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.mukta(
                      fontSize: 10.5,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFE9B0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

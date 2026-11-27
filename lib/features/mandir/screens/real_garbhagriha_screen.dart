import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/theme/motion.dart';
import '../../../domain/entities/bhakti_deity.dart';
import '../widgets/mandir_murti.dart';
import '../../../presentation/providers/akhand_diya_provider.dart';
import '../../../presentation/providers/locale_provider.dart';
import '../../../services/audio_service.dart';
import '../../../services/backend_service.dart';
import '../controllers/akhand_diya_controller.dart';
import '../../../presentation/screens/ishta_devta_screen.dart';
import '../../voice_agent/domain/home_voice_commands.dart';
import '../../voice_agent/domain/mandir_voice_commands.dart';
import '../../voice_agent/presentation/widgets/bhakti_voice_modal.dart';
import '../widgets/mandir_aarti_session.dart';
import '../widgets/mandir_deity_picker.dart';
import '../widgets/mandir_painters.dart';
import '../widgets/mandir_stage.dart';

/// Shown once: the aarti thali demo-sweeps a half circle so devotees learn it moves.
const _kThaliCoachSeenKey = 'mandir_thali_coach_seen';
const _kDailySevasDateKey = 'mandir_sevas_date';
const _kDailySevasListKey = 'mandir_sevas_today';

String _todayKey() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

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

// Cache the capability check across visits. Use the lighter scene while an
// Android phone is reporting its capabilities, including on the first frame.
final mandirLightRenderingProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
  final info = await DeviceInfoPlugin().androidInfo;
  return info.isLowRamDevice || info.version.sdkInt <= 27 || info.physicalRamSize <= 3072;
});

const double _ritualLabelSize = 14;
const double _pickerHeight = 48;

/// Where every sanctum element sits on screen, proportioned so the photoreal
/// stone temple pillars, corner floor diyas, and raised chowki stay visible even
/// when the Aarti lyrics card opens.
class _SanctumLayout {
  _SanctumLayout(this.size, this.topPadding, {this.aarti = false}) {
    final w = size.width;
    final h = size.height;

    final minAltarH = aarti ? math.max(h * 0.28, 126.0) : h * 0.22;
    final preferredArchTop = aarti ? topPadding + 40 : topPadding + h * 0.11;
    final maxArchH = math.max(150.0, h - minAltarH - preferredArchTop);
    final archH = math.min(w * 1.08, math.min((h - topPadding) * (aarti ? 0.56 : 0.59), maxArchH));
    final archW = archH * 0.8;
    final archTop = math.max(h - minAltarH - archH, preferredArchTop);
    arch = Rect.fromLTWH((w - archW) / 2, archTop, archW, archH);

    final pedestalTopY = arch.top + archH * 0.82;
    sinhasan = Rect.fromCenter(
      center: Offset(w / 2, pedestalTopY + archH * 0.015),
      width: archW * 0.46,
      height: archH * 0.065,
    );
    final murtiH = archH * 0.64;
    murti = Rect.fromLTWH(w / 2 - murtiH / 3, sinhasan.top + sinhasan.height * 0.35 - murtiH, murtiH * 2 / 3, murtiH);
    feet = Rect.fromLTRB(
      murti.left + murti.width * 0.12,
      murti.top + murti.height * 0.78,
      murti.right - murti.width * 0.12,
      sinhasan.bottom,
    );

    altar = Rect.fromLTRB(0, arch.bottom - h * 0.01, w, h);
    platform = Rect.fromLTRB(w * .035, altar.top + altar.height * .30, w * .965, h);
    altarFloor = platform.top + platform.height * .33;

    rangoli = Rect.fromCenter(
      center: Offset(w / 2, altar.top + altar.height * 0.76),
      width: w * 0.65,
      height: altar.height * 0.30,
    );

    final dW = math.min(w * 0.32, altar.height * 0.82).clamp(76.0, 134.0);
    final dH = dW / 1.5;
    diya = Rect.fromLTWH(w * 0.41 - dW / 2, altarFloor - dH, dW, dH);
    wick = Offset(diya.center.dx, diya.top + dH * 0.235);
    final fW = dW * 0.42;
    final fH = dW * 0.40;
    flame = Rect.fromLTWH(wick.dx - fW / 2, wick.dy - fH * 0.96, fW, fH);
    bowl = Offset(diya.center.dx + dW * 0.1, diya.top + dH * 0.29);

    final kW = dW * 0.68;
    final kH = kW / 1.094;
    kalash = Rect.fromLTWH(w * 0.67 - kW / 2, altarFloor - kH, kW, kH);
    spoutLocal = kalash.topLeft + Offset(kW * 0.05, kH * 0.28);

    final plateW = math.min(w * .16, platform.height * .72);
    naivedya = Rect.fromLTWH(w * .81 - plateW / 2, altarFloor - plateW * .57, plateW, plateW * .55);
    dhoop = Rect.fromLTWH(w * 0.17, altarFloor - h * 0.13, w * 0.09, h * 0.13);

    final toranTop = math.max(h * 0.075, topPadding + 47);
    toran = Rect.fromLTWH(0, toranTop, w, h * 0.16);
    final bellW = archW * 0.16;
    final bellTop = toran.top + toran.height * 0.18;
    bellLeft = Rect.fromLTWH(w * 0.175 - bellW / 2, bellTop, bellW, bellW * 1.25);
    bellRight = Rect.fromLTWH(w * 0.825 - bellW / 2, bellTop, bellW, bellW * 1.25);

    thaliWidth = math.min(148, math.min(w * .3, h * .2));
    thaliStart = Offset(w * .64, sinhasan.bottom + thaliWidth * .08);
  }

  static const tiltAngle = -0.95;

  final Size size;
  final double topPadding;
  final bool aarti;
  late final Rect arch;
  late final Rect sinhasan;
  late final Rect murti;
  late final Rect feet;
  late final Rect altar;

  late final Rect platform;

  /// Contact line on the top of the offering platform.
  late final double altarFloor;
  late final Rect rangoli;
  late final Rect diya;
  late final Offset wick;
  late final Rect flame;
  late final Offset bowl;
  late final Rect kalash;
  late final Offset spoutLocal;
  late final Rect naivedya;
  late final Rect dhoop;
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

/// The Garbhagriha: the devotee's Ishta Devta seated inside a real stone-and-gold
/// sanctum behind carved teakwood doors, with living lamps, daily seva memory,
/// water and milk abhishek, Charan Sparsh, and synchronized Aarti.
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
  final _shrineClock = ValueNotifier<double>(0);
  double _pourStartedAt = 0;
  late final AnimationController _abhishek = _controller(3200);
  late final AnimationController _blessing = _controller(2400);
  late final AnimationController _shankh = _controller(3200);
  late final AnimationController _naivedya = _controller(650);
  late final AnimationController _dhoop = _controller(2200);
  late final AnimationController _bellLeft = _controller(2200);
  late final AnimationController _bellRight = _controller(2200);

  Timer? _completeTimer;
  Timer? _whisperTimer;
  double _ratioBeforePour = 1;
  bool _streamHapticFired = false;
  bool _aarti = false;
  bool _thaliCoach = false;

  /// `null` until prefs load — coach only runs once we know it was never shown.
  bool? _thaliCoachSeen;
  bool _aartiComplete = false;
  Abhishek _liquid = Abhishek.water;
  bool _naivedyaPlaced = false;
  bool _pureDarshan = false;
  double _bellLeftAmp = 0;
  double _bellRightAmp = 0;
  int _aartiRounds = 0;
  String? _whisperText;

  /// Daily Seva persistence so morning rituals remain visible all day.
  final Set<String> _dailySevas = <String>{};
  bool _sankalpCelebratedToday = false;
  late final HomeVoiceBinding _voiceBinding;
  late final MandirVoiceHandler? Function() _mandirVoiceEntry = _activeMandirVoiceHandler;

  AnimationController _controller(int ms) => AnimationController(
    vsync: this,
    duration: Duration(milliseconds: ms),
  );

  String get _lang => ref.read(localeProvider).languageCode;

  @override
  void initState() {
    super.initState();
    _voiceBinding = ref.read(homeVoiceBindingProvider)
      ..mandirHandler = _mandirVoice
      ..activeMandirHandler = _mandirVoiceEntry;
    _pour.addListener(_onPourTick);
    _enableWakelock();
    _loadPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(akhandDiyaControllerProvider.notifier).ensureLit();
      BackendService.trackEvent('mandir_open', item: ref.read(jyotDeityProvider).key);
    });
  }

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {}
  }

  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final today = _todayKey();
    final savedDate = prefs.getString(_kDailySevasDateKey);
    final savedList = savedDate == today
        ? (prefs.getStringList(_kDailySevasListKey) ?? const <String>[])
        : const <String>[];
    setState(() {
      _thaliCoachSeen = prefs.getBool(_kThaliCoachSeenKey) ?? false;
      _dailySevas
        ..clear()
        ..addAll(savedList);
      if (_dailySevas.contains('naivedya')) {
        _naivedyaPlaced = true;
        _naivedya.value = 1;
      }
      if (_dailySevas.contains('pushpanjali')) {
        _garland.value = 1;
      }
      _sankalpCelebratedToday = _completedSankalpCount >= 5;
    });
  }

  @override
  void dispose() {
    if (_voiceBinding.activeMandirHandler == _mandirVoiceEntry) {
      _voiceBinding.activeMandirHandler = null;
      _voiceBinding.mandirHandler = null;
    }
    _shrineClock.dispose();
    _completeTimer?.cancel();
    _whisperTimer?.cancel();
    _disableWakelock();
    _audio.dispose();
    for (final c in [
      _pour,
      _petals,
      _garland,
      _abhishek,
      _blessing,
      _shankh,
      _naivedya,
      _dhoop,
      _bellLeft,
      _bellRight,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _markThaliCoachSeen() async {
    if (_thaliCoachSeen == true && !_thaliCoach) return;
    if (mounted) {
      setState(() {
        _thaliCoachSeen = true;
        _thaliCoach = false;
      });
    } else {
      _thaliCoachSeen = true;
      _thaliCoach = false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kThaliCoachSeenKey, true);
  }

  // Honour today's saved progress from versions that offered tilak.
  bool get _hasAdornedMurti => _dailySevas.any(const {'pushpanjali', 'jalabhishek', 'dugdhabhishek', 'tilak'}.contains);

  int get _completedSankalpCount {
    var count = 0;
    if (_dailySevas.contains('ghee')) count++;
    if (_hasAdornedMurti) count++;
    if (_dailySevas.contains('ghanta') || _dailySevas.contains('shankh')) count++;
    if (_dailySevas.contains('aarti')) count++;
    if (_dailySevas.contains('naivedya')) count++;
    return count;
  }

  Future<void> _recordDailySeva(String sevaKey) async {
    final added = _dailySevas.add(sevaKey);
    if (added && mounted) setState(() {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDailySevasDateKey, _todayKey());
    await prefs.setStringList(_kDailySevasListKey, _dailySevas.toList());
    if (!_sankalpCelebratedToday && _completedSankalpCount >= 5 && mounted) {
      _sankalpCelebratedToday = true;
      _petals.forward(from: 0);
      _blessing.forward(from: 0);
      _showWhisper(
        _t(
          _lang,
          en: '🙏 Nitya Pooja complete • May divine grace stay with you today',
          hi: '🙏 नित्य पूजा संपन्न • ईश्वर की असीम कृपा बनी रहे',
          mr: '🙏 नित्य पूजा संपन्न • ईश्वराचा अखंड आशीर्वाद लाभो',
        ),
      );
    }
  }

  void _showWhisper(String msg) {
    _whisperTimer?.cancel();
    if (!mounted) return;
    setState(() => _whisperText = msg);
    _whisperTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _whisperText = null);
    });
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
    unawaited(_recordDailySeva('ghee'));
    await diya.pourGheeAndRefill();
  }

  void _onPourTick() {
    if (!_streamHapticFired && _pour.value >= 0.32) {
      _streamHapticFired = true;
      HapticFeedback.heavyImpact();
    }
  }

  void _toggleAarti() {
    _completeTimer?.cancel();
    final next = !_aarti;
    final showCoach = next && _thaliCoachSeen == false && !MediaQuery.disableAnimationsOf(context);
    setState(() {
      _aarti = next;
      _thaliCoach = showCoach;
      _aartiComplete = false;
      _aartiRounds = 0;
      if (next) _pureDarshan = false;
    });
    HapticFeedback.mediumImpact();
    if (!_aarti) _onSingAlong(false);
    if (_aarti) {
      _track('aarti');
      unawaited(_recordDailySeva('aarti'));
    }
  }

  /// The aarti ghanti accompanies the devotee only when no video is playing.
  void _onSingAlong(bool singing) {
    if (singing != _audio.bellPlaying.value) _audio.toggleBell();
  }

  void _onAartiRound(int round) {
    if (!mounted) return;
    setState(() => _aartiRounds = round);
    if (round == 3) {
      _blessing.forward(from: 0);
      _showWhisper(
        _t(
          _lang,
          en: '🪔 Three sacred parikramas offered • Jai Ho!',
          hi: '🪔 तीन पावन परिक्रमा पूर्ण • जय हो!',
          mr: '🪔 तीन पावन परिक्रमा पूर्ण • जय हो!',
        ),
      );
    }
  }

  Future<void> _onAartiComplete() async {
    _track('aarti_complete');
    unawaited(_recordDailySeva('aarti'));
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
    unawaited(_recordDailySeva('pushpanjali'));
    _showWhisper(
      _t(
        _lang,
        en: '🌸 Pushpanjali & fresh garland offered',
        hi: '🌸 पुष्पांजलि व ताज़ा पुष्पहार अर्पित',
        mr: '🌸 पुष्पांजली व ताजा पुष्पहार अर्पण',
      ),
    );
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
    unawaited(_recordDailySeva('ghanta'));
    _strikeBell(left: true);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (mounted) _strikeBell(left: false, direction: -1);
  }

  Future<void> _shankhNaad() async {
    _shankh.forward(from: 0);
    _track('shankh');
    unawaited(_recordDailySeva('shankh'));
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

  void _advanceAbhishek() {
    final elapsed = _shrineClock.value - _pourStartedAt;
    _abhishek.value = (elapsed * 1000 / _abhishek.duration!.inMilliseconds).clamp(0.0, 1.0);
    if (_abhishek.isCompleted) _shrineClock.removeListener(_advanceAbhishek);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _shrineClock.removeListener(_advanceAbhishek);
      if (_abhishek.value > 0 && !_abhishek.isCompleted) _abhishek.value = 1;
    }
  }

  void _offerAbhishek(Abhishek liquid, {required bool light}) {
    setState(() => _liquid = liquid);
    _shrineClock.removeListener(_advanceAbhishek);
    if (light && !MediaQuery.disableAnimationsOf(context)) {
      _abhishek.reset();
      _pourStartedAt = _shrineClock.value;
      _shrineClock.addListener(_advanceAbhishek);
    } else {
      _abhishek.forward(from: 0);
    }
    final milk = liquid == Abhishek.milk;
    final key = milk ? 'dugdhabhishek' : 'jalabhishek';
    HapticFeedback.selectionClick();
    _track(key);
    unawaited(_recordDailySeva(key));
    _showWhisper(
      milk
          ? _t(_lang, en: 'Milk offered', hi: 'दूध अर्पित', mr: 'दूध अर्पण केले')
          : _t(_lang, en: 'Water offered', hi: 'जल अर्पित', mr: 'जल अर्पण केले'),
    );
  }

  Future<void> _charanSparsh() async {
    _blessing.forward(from: 0);
    _track('charan_sparsh');
    unawaited(_recordDailySeva('charan_sparsh'));
    _showWhisper(
      _t(
        _lang,
        en: '🙏 Charan Sparsh · Divine blessings received',
        hi: '🙏 चरण स्पर्श · सदा कल्याण हो',
        mr: '🙏 चरणस्पर्श · ईश्वराचा आशीर्वाद लाभला',
      ),
    );
    HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 110));
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 110));
    HapticFeedback.mediumImpact();
  }

  void _flareDhoop() {
    _dhoop.forward(from: 0);
    HapticFeedback.selectionClick();
    _track('dhoop');
    _showWhisper(
      _t(
        _lang,
        en: '🪔 Fragrant dhoop & agarbatti lit',
        hi: '🪔 सुगंधित धूप व अगरबत्ती प्रज्वलित',
        mr: '🪔 सुगंधित धूप व अगरबत्ती प्रज्वलित',
      ),
    );
  }

  void _placeNaivedya() {
    setState(() => _naivedyaPlaced = true);
    _naivedya.forward(from: 0);
    HapticFeedback.mediumImpact();
    _track('naivedya');
    unawaited(_recordDailySeva('naivedya'));
    _showWhisper(
      _t(
        _lang,
        en: '🍬 Naivedya bhog offered with tulsi',
        hi: '🍬 तुलसी दल सहित नैवेद्य भोग अर्पित',
        mr: '🍬 तुळशीपत्रासह नैवेद्य अर्पण',
      ),
    );
  }

  Future<void> _changeDeity() async {
    final choice = await showMandirDeityPicker(context);
    if (choice == null || !mounted) return;
    final (deity, aarti) = choice;
    changeIshtaDevta(ref, deity, aarti, source: 'mandir');
    setState(() {
      _shrineClock.removeListener(_advanceAbhishek);
      _abhishek.reset();
      _naivedyaPlaced = false;
    });
    _garland.value = 0;
    _blessing.forward(from: 0);
    HapticFeedback.heavyImpact();
    _track('change_deity');
  }

  MandirVoiceHandler? _activeMandirVoiceHandler() {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return null;
    return _mandirVoice;
  }

  HomeVoiceReply? _mandirVoice(
    String text,
    String lang, {
    MandirCommand? prediction,
    String? pendingTopic,
  }) {
    if (!mounted) return null;
    final cmd = prediction ?? MandirCommand.parse(text, pendingTopic: pendingTopic);
    if (cmd == null || cmd is OtherMandir) return null;
    String say(String en, String hi, String mr) => _t(lang, en: en, hi: hi, mr: mr);
    HomeVoiceReply act(String message, VoidCallback apply) => voiceReply(
      message,
      apply: () {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) apply();
      },
    );
    HomeVoiceReply speak(String message, {String? pending}) => voiceReply(
      message,
      pendingAction: pending ?? cmd.pendingTopic,
    );
    final diya = ref.read(akhandDiyaControllerProvider.notifier);
    final deity = ref.read(jyotDeityProvider);

    return switch (cmd) {
      OfferGheeMandir() => act(
        say('Offering ghee to the lamp.', 'दीये में घी अर्पित कर रही हूँ।', 'दिव्याला तूप अर्पण करत आहे.'),
        _pourGhee,
      ),
      ReadGheeMandir() => speak(say(
        'The lamp has ${(diya.gheeRatio * 100).round()}% ghee left.',
        'दीये में ${(diya.gheeRatio * 100).round()}% घी बचा है।',
        'दिव्यात ${(diya.gheeRatio * 100).round()}% तूप शिल्लक आहे.',
      )),
      ReadTimeMandir() => speak('${_remainingText(lang, diya.gheeRatio)}.'),
      ReadStreakMandir() => () {
        final days = math.max(diya.streakDays, 1);
        return speak(say(
          'Your lamp streak is $days days.',
          'दीये का आपका क्रम $days दिन है।',
          'दिव्याचे सलग दिवस $days आहेत.',
        ));
      }(),
      RingBellMandir() => act(
        say('Ringing the temple bells.', 'मंदिर की घंटियाँ बजा रही हूँ।', 'मंदिरातील घंटा वाजवत आहे.'),
        _ghantaNaad,
      ),
      BlowConchMandir() => act(
        say('Sounding the conch.', 'शंख बजा रही हूँ।', 'शंख वाजवत आहे.'),
        _shankhNaad,
      ),
      OfferFlowersMandir() => act(
        say('Offering flowers to the deity.', 'देवता को फूल अर्पित कर रही हूँ।', 'देवाला फुले अर्पण करत आहे.'),
        _pushpanjali,
      ),
      OfferFoodMandir() => act(
        say('Placing naivedya before the deity.', 'देवता के सामने नैवेद्य रख रही हूँ।', 'देवासमोर नैवेद्य ठेवत आहे.'),
        _placeNaivedya,
      ),
      ReadFoodMandir() => (
        text: _naivedyaPlaced
            ? say(
                'Naivedya is already placed before the deity.',
                'देवता के सामने नैवेद्य पहले से रखा है।',
                'देवासमोर नैवेद्य आधीच ठेवलेला आहे.',
              )
            : say(
                'No food offering is placed yet.',
                'अभी नैवेद्य नहीं रखा गया है।',
                'सध्या नैवेद्य ठेवलेला नाही.',
              ),
        apply: null,
        pendingAction: null,
      ),
      StartAartiMandir() => _aarti
          ? (
              text: say(
                'The aarti thali is already open.',
                'आरती की थाली पहले से खुली है।',
                'आरतीचे ताट आधीच सुरू आहे.',
              ),
              apply: null,
              pendingAction: null,
            )
          : act(
              say('Opening the aarti thali.', 'आरती की थाली खोल रही हूँ।', 'आरतीचे ताट उघडत आहे.'),
              _toggleAarti,
            ),
      StopAartiMandir() => !_aarti
          ? (
              text: say(
                'The aarti thali is already closed.',
                'आरती की थाली पहले से बंद है।',
                'आरतीचे ताट आधीच बंद आहे.',
              ),
              apply: null,
              pendingAction: null,
            )
          : act(
              say('Closing the aarti thali.', 'आरती की थाली बंद कर रही हूँ।', 'आरतीचे ताट बंद करत आहे.'),
              _toggleAarti,
            ),
      ReadAartiMandir() => (
        text: _aarti
            ? say(
                'The aarti thali is open right now.',
                'आरती की थाली अभी खुली है।',
                'आरतीचे ताट सध्या सुरू आहे.',
              )
            : say(
                'The aarti thali is currently closed.',
                'आरती की थाली अभी बंद है।',
                'आरतीचे ताट सध्या बंद आहे.',
              ),
        apply: null,
        pendingAction: null,
      ),
      ChangeDeityMandir() => act(
        say(
          'Opening the deity picker. Choose the deity you want to seat.',
          'देवता चुनने की सूची खोल रही हूँ। अपने इच्छित देवता चुनें।',
          'देवता निवडण्याची यादी उघडत आहे. हवे ते दैवत निवडा.',
        ),
        _changeDeity,
      ),
      ReadDeityMandir() => (
        text: say(
          'The seated deity is ${deity.localizedName(lang)}.',
          'अभी ${deity.localizedName(lang)} विराजमान हैं।',
          'सध्या ${deity.localizedName(lang)} विराजमान आहेत.',
        ),
        apply: null,
        pendingAction: null,
      ),
      CancelMandir() => speak(say('Okay.', 'ठीक है।', 'ठीक आहे.')),
      ExplainMandirTopic(:final topic) => speak(
        _mandirGuideReply(topic, lang),
        pending: MandirCommand.clarificationTopics.contains(topic) ? topic : null,
      ),
      OtherMandir() => null,
    };
  }

  String _mandirGuideReply(String topic, String lang) => switch (topic) {
    'explain_ghee' => _t(
      lang,
      en: 'Tap Offer ghee or the ghee pot to refill the lamp. A full pot lasts 24 hours. Refilling can advance your streak once per calendar day.',
      hi: 'घी अर्पण करें या कलश दबाकर दीया भरें। पूरा कलश 24 घंटे चलता है। एक दिन में लगातार दिनों की गिनती एक बार बढ़ सकती है।',
      mr: 'तूप अर्पण करा किंवा कलशावर टॅप करून दिवा भरा. भरलेला कलश २४ तास पुरतो. सलग दिवसांची नोंद एका दिवशी एकदाच वाढू शकते.',
    ),
    'explain_bell' => _t(
      lang,
      en: 'Tap a hanging bell to ring it, or choose Ring bell to ring both in sequence.',
      hi: 'किसी लटकती घंटी को दबाएँ या दोनों घंटियाँ क्रम से बजाने के लिए घंटा नाद चुनें।',
      mr: 'एखाद्या लटकत्या घंटेवर टॅप करा किंवा दोन्ही क्रमाने वाजवण्यासाठी घंटानाद निवडा.',
    ),
    'explain_conch' => _t(
      lang,
      en: 'Choose Shankh naad on the right to sound the conch.',
      hi: 'दाईं ओर शंखनाद चुनकर शंख बजाएँ।',
      mr: 'उजवीकडील शंखनाद निवडून शंख वाजवा.',
    ),
    'explain_flowers' => _t(
      lang,
      en: 'Choose Pushpanjali to offer flowers. Petals fall and a garland appears around the deity.',
      hi: 'फूल चढ़ाने के लिए पुष्पांजलि चुनें। पंखुड़ियाँ गिरती हैं और देवता के चारों ओर माला दिखती है।',
      mr: 'फुले वाहण्यासाठी पुष्पांजली निवडा. पाकळ्या पडतात आणि देवाला हार दिसतो.',
    ),
    'explain_food' => _t(
      lang,
      en: 'Choose Naivedya on the right to place a food offering in front of the deity.',
      hi: 'देवता के सामने भोग रखने के लिए दाईं ओर नैवेद्य भोग चुनें।',
      mr: 'देवासमोर भोग ठेवण्यासाठी उजवीकडील नैवेद्य निवडा.',
    ),
    'explain_aarti' => _t(
      lang,
      en: 'Open Aarti thali and drag the thali with your finger. The lyrics panel lets you choose an aarti and move between verses.',
      hi: 'आरती थाली खोलें और उंगली से थाली घुमाएँ। बोलों के पैनल में आरती चुनें और पद बदलें।',
      mr: 'आरती ताट उघडा आणि बोटाने ताट फिरवा. बोलांच्या पॅनेलमध्ये आरती निवडा आणि कडवी बदला.',
    ),
    'explain_player' => _t(
      lang,
      en: 'With the thali open, use the arrows to move between verses. Choose Sing myself for manual singing, or Video for the recording when available. Drag the video to move it.',
      hi: 'थाली खुली हो तो तीरों से पद बदलें। स्वयं गाएं चुनकर खुद गाएँ या उपलब्ध हो तो वीडियो चुनें। वीडियो को खींचकर हटा सकते हैं।',
      mr: 'ताट उघडे असताना बाणांनी कडवे बदला. स्वतः गा निवडून स्वतः गा किंवा उपलब्ध असल्यास व्हिडिओ निवडा. व्हिडिओ ओढून हलवता येतो.',
    ),
    'explain_deity' => _t(
      lang,
      en: 'Choose Change deity, search for a name, then tap the deity. The picker also offers a request form for a missing deity.',
      hi: 'देवता बदलें दबाएँ, नाम खोजें और देवता चुनें। नाम न मिले तो सूची में अनुरोध फ़ॉर्म भी है।',
      mr: 'देवता बदला निवडा, नाव शोधा आणि दैवत निवडा. दैवत न मिळाल्यास यादीत विनंतीचा फॉर्मही आहे.',
    ),
    'overview' => _t(
      lang,
      en: 'Here you can have darshan, tend the lamp, offer flowers or naivedya, ring the bells, sound the conch and perform aarti.',
      hi: 'यहाँ दर्शन करें, दीये में घी भरें, फूल या भोग चढ़ाएँ, घंटी या शंख बजाएँ और आरती करें।',
      mr: 'इथे दर्शन घ्या, दिव्यात तूप घाला, फुले किंवा नैवेद्य अर्पण करा, घंटा किंवा शंख वाजवा आणि आरती करा.',
    ),
    'clarify_jyot' => _t(
      lang,
      en: 'For the lamp, do you want to refill ghee, check how much is left, remaining time, or your streak?',
      hi: 'ज्योत के लिए आप क्या चाहेंगे: घी भरें, कितना बचा है देखें, कितनी देर चलेगी, या streak?',
      mr: 'ज्योतीसाठी काय करू: तूप भरायचे, शिल्लक पहायची, किती वेळ पुरेल, की streak?',
    ),
    'clarify_aarti' => _t(
      lang,
      en: 'For aarti, do you want to open the thali, close it, check if it is open, or hear how it works?',
      hi: 'आरती के लिए आप क्या चाहेंगे: थाली खोलें, बंद करें, स्थिति देखें, या कैसे करें समझें?',
      mr: 'आरतीसाठी काय करू: ताट उघडायचे, बंद करायचे, स्थिती पहायची, की कसे करायचे सांगू?',
    ),
    'clarify_food' => _t(
      lang,
      en: 'For naivedya, do you want to place food, check if it is already placed, or hear how?',
      hi: 'नैवेद्य के लिए आप क्या चाहेंगे: भोग रखें, पहले से है या नहीं देखें, या कैसे करें?',
      mr: 'नैवेद्यासाठी काय करू: भोग ठेवायचा, आधीच आहे का ते पहायचे, की कसे करायचे?',
    ),
    'clarify_deity' => _t(
      lang,
      en: 'For the deity, do you want to change who is seated, hear the current name, or learn how to switch?',
      hi: 'देवता के लिए आप क्या चाहेंगे: बदलें, अभी कौन हैं बताएँ, या कैसे बदलें?',
      mr: 'दैवतासाठी काय करू: बदलायचे, सध्या कोण आहे सांगायचे, की कसे बदलायचे?',
    ),
    'clarify_offering' => _t(
      lang,
      en: 'What would you like to offer: ghee, flowers or naivedya?',
      hi: 'आप क्या चढ़ाना चाहेंगे: घी, फूल या नैवेद्य?',
      mr: 'काय अर्पण करू: तूप, फुले की नैवेद्य?',
    ),
    'clarify' => _t(
      lang,
      en: 'Which Mandir service do you mean?',
      hi: 'मंदिर की किस सेवा की बात कर रहे हैं?',
      mr: 'मंदिरातील कोणती सेवा हवी आहे?',
    ),
    'unavailable' => _t(
      lang,
      en: 'That service is unavailable in this Mandir. You can offer flowers or naivedya here.',
      hi: 'इस मंदिर में वह सेवा उपलब्ध नहीं है। यहाँ फूल या नैवेद्य अर्पित कर सकते हैं।',
      mr: 'या मंदिरात ती सेवा उपलब्ध नाही. इथे फुले किंवा नैवेद्य अर्पण करता येतो.',
    ),
    _ => _t(lang, en: 'Okay.', hi: 'ठीक है।', mr: 'ठीक आहे.'),
  };

  void _showSankalpSheet(String lang, AkhandDiyaController diya) {
    final streak = math.max(diya.streakDays, 1);
    final items = [
      (
        done: _dailySevas.contains('ghee'),
        title: _t(lang, en: 'Akhand Jyot & Ghee', hi: 'अखंड ज्योत व घी अर्पण', mr: 'अखंड ज्योत व तूप अर्पण'),
        sub: '${(diya.gheeRatio * 100).round()}% · ${_remainingText(lang, diya.gheeRatio)}',
        onTap: _pourGhee,
      ),
      (
        done: _hasAdornedMurti,
        title: _t(lang, en: 'Pushpanjali or Abhishek', hi: 'पुष्पांजलि या अभिषेक', mr: 'पुष्पांजली किंवा अभिषेक'),
        sub: _t(
          lang,
          en: 'Offer flowers, water or milk',
          hi: 'प्रभु को फूल, जल या दूध अर्पित करें',
          mr: 'प्रभूंना फुले, जल किंवा दूध अर्पण करा',
        ),
        onTap: _pushpanjali,
      ),
      (
        done: _dailySevas.contains('ghanta') || _dailySevas.contains('shankh'),
        title: _t(lang, en: 'Ghanta or Shankh Naad', hi: 'घंटा या शंखनाद', mr: 'घंटानाद किंवा शंखनाद'),
        sub: _t(
          lang,
          en: 'Awaken sacred temple resonance',
          hi: 'पावन ध्वनि से गर्भगृह गूंजाएं',
          mr: 'पावन नादाने गर्भगृह दुमदुमू द्या',
        ),
        onTap: _ghantaNaad,
      ),
      (
        done: _dailySevas.contains('aarti'),
        title: _t(lang, en: 'Perform Aarti', hi: 'पावन आरती उतारें', mr: 'पावन आरती करा'),
        sub: _t(
          lang,
          en: 'Wave the lit brass thali around the deity',
          hi: 'प्रभु की सजीव आरती थाली घुमाएं',
          mr: 'प्रभूंची आरती ताट फिरवा',
        ),
        onTap: _toggleAarti,
      ),
      (
        done: _dailySevas.contains('naivedya'),
        title: _t(lang, en: 'Naivedya Bhog', hi: 'नैवेद्य भोग अर्पण', mr: 'नैवेद्य अर्पण'),
        sub: _t(
          lang,
          en: 'Offer modaks, ladoo & tulsi',
          hi: 'मोदक, लड्डू व तुलसी अर्पित करें',
          mr: 'मोदक, लाडू व तुळस अर्पण करा',
        ),
        onTap: _placeNaivedya,
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3E1407), Color(0xFF180704)],
          ),
          border: Border(top: BorderSide(color: Brass.gold.withValues(alpha: 0.8), width: 1.2)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0x66FFE9B0), borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t(lang, en: 'Nitya Pooja Sankalp', hi: 'नित्य पूजा संकल्प', mr: 'नित्य पूजा संकल्प'),
                            style: GoogleFonts.mukta(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFFE08A),
                            ),
                          ),
                          Text(
                            _t(
                              lang,
                              en: '$_completedSankalpCount of 5 sevas offered today · Streak Day $streak',
                              hi: 'आज $_completedSankalpCount / 5 सेवा पूर्ण · अखंड ज्योत दिन $streak',
                              mr: 'आज $_completedSankalpCount / 5 सेवा पूर्ण · अखंड ज्योत दिवस $streak',
                            ),
                            style: GoogleFonts.mukta(fontSize: 12.5, color: const Color(0xCCFFE9B0)),
                          ),
                        ],
                      ),
                    ),
                    _DayBadge(
                      label: _t(
                        lang,
                        en: '$_completedSankalpCount/5',
                        hi: '$_completedSankalpCount/5',
                        mr: '$_completedSankalpCount/5',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final item in items)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      if (!item.done) item.onTap();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: item.done ? const Color(0x332E7D32) : const Color(0x22FFE9B0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: item.done ? const Color(0x9981C784) : const Color(0x44E2B33C),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: item.done ? const Color(0xFFA5D6A7) : Brass.gold,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: GoogleFonts.mukta(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFFE9B0),
                                  ),
                                ),
                                Text(
                                  item.sub,
                                  style: GoogleFonts.mukta(fontSize: 11.5, color: const Color(0xAAFFE9B0)),
                                ),
                              ],
                            ),
                          ),
                          if (!item.done)
                            Text(
                              _t(lang, en: 'Offer →', hi: 'अर्पण →', mr: 'अर्पण →'),
                              style: GoogleFonts.mukta(fontSize: 12, fontWeight: FontWeight.w800, color: Brass.gold),
                            ),
                        ],
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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final diya = ref.watch(akhandDiyaControllerProvider.notifier);
    final lang = ref.watch(localeProvider).languageCode;
    final deity = ref.watch(jyotDeityProvider);
    final light =
        ref.watch(mandirLightRenderingProvider).valueOrNull ??
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);
    final density = MediaQuery.devicePixelRatioOf(context);
    final dpr = light ? math.min(density, 1.75) : density;
    final padding = MediaQuery.paddingOf(context);
    final prahar = SanctumPrahar.fromHour(DateTime.now().hour);

    final ghee = _Seva(
      SevaIcon.ghee,
      _t(lang, en: 'Offer ghee +', hi: 'घी अर्पण करें +', mr: 'तूप अर्पण करा +'),
      _pourGhee,
    );
    final actions = [
      _Seva(
        SevaIcon.aarti,
        _t(lang, en: 'Aarti thali', hi: 'आरती थाली', mr: 'आरती ताट'),
        _toggleAarti,
        active: _aarti,
      ),
      _Seva(
        SevaIcon.pushpanjali,
        _t(lang, en: 'Pushpanjali', hi: 'पुष्पांजलि', mr: 'पुष्पांजली'),
        _pushpanjali,
        active: _dailySevas.contains('pushpanjali'),
      ),
      _Seva(SevaIcon.ghanta, _t(lang, en: 'Ring bell', hi: 'घंटा नाद', mr: 'घंटानाद'), _ghantaNaad),
      ghee,
      _Seva(SevaIcon.shankh, _t(lang, en: 'Shankh naad', hi: 'शंखनाद', mr: 'शंखनाद'), _shankhNaad),
      _Seva(
        SevaIcon.naivedya,
        _t(lang, en: 'Naivedya bhog', hi: 'नैवेद्य भोग', mr: 'नैवेद्य'),
        _placeNaivedya,
        active: _naivedyaPlaced,
      ),
      _Seva(
        SevaIcon.water,
        _t(lang, en: 'Jalabhishek', hi: 'जलाभिषेक', mr: 'जलाभिषेक'),
        () => _offerAbhishek(Abhishek.water, light: light),
        active: _dailySevas.contains('jalabhishek'),
      ),
      _Seva(
        SevaIcon.milk,
        _t(lang, en: 'Dugdhabhishek', hi: 'दुग्धाभिषेक', mr: 'दुग्धाभिषेक'),
        () => _offerAbhishek(Abhishek.milk, light: light),
        active: _dailySevas.contains('dugdhabhishek'),
      ),
      _Seva(SevaIcon.incense, _t(lang, en: 'Incense', hi: 'धूप', mr: 'धूप'), _flareDhoop),
      _Seva(SevaIcon.charan, _t(lang, en: 'Charan sparsh', hi: 'चरण स्पर्श', mr: 'चरणस्पर्श'), _charanSparsh),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF140604),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final labelHeight = MediaQuery.textScalerOf(context).scale(_ritualLabelSize) * 1.15;
            final trayHeight = _pickerHeight + 2 * math.max(66.0, 32 + 2 * labelHeight);
            final trayInset = _pureDarshan ? 0.0 : trayHeight + padding.bottom;
            final available = constraints.maxHeight - trayInset;
            final lyricsHeight = _aarti ? math.min(168.0, available * .30) : 0.0;
            final l = _SanctumLayout(Size(constraints.maxWidth, available - lyricsHeight), padding.top, aarti: _aarti);
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  bottom: trayInset + lyricsHeight,
                  child: MandirStage(
                    clock: _shrineClock,
                    lightRendering: light,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _background(l, dpr, prahar, light),
                        _archLayer(l, dpr, diya),
                        _deityLayer(l, dpr, deity, diya, light),
                        _altarLayer(l, dpr, diya, light),
                        _outerLayer(l, dpr),
                        if (_aarti)
                          RepaintBoundary(
                            child: _AartiThali(
                              start: l.thaliStart,
                              width: l.thaliWidth,
                              orbitCenter: l.murti.center,
                              dpr: dpr,
                              directDrag: light,
                              playCoach: _thaliCoach,
                              onCoachFinished: _markThaliCoachSeen,
                              onRoundCompleted: _onAartiRound,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: IgnorePointer(
                    ignoring: _pureDarshan,
                    child: AnimatedOpacity(
                      opacity: _pureDarshan ? 0.0 : 1.0,
                      duration: AppMotion.entrance,
                      child: _DarshanHeader(
                        lang: lang,
                        deityName: deity.localizedName(lang),
                        prahar: prahar,
                        onDeityTap: _changeDeity,
                        onSankalpTap: () => _showSankalpSheet(lang, diya),
                        onDarshanToggle: () => setState(() => _pureDarshan = true),
                        onVoiceTap: kEnableBhaktiAi ? () => BhaktiVoiceModal.show(context, ref) : null,
                        topPadding: padding.top,
                      ),
                    ),
                  ),
                ),
                if (_pureDarshan)
                  Positioned(
                    right: 14,
                    top: padding.top + 12,
                    child: GestureDetector(
                      onTap: () => setState(() => _pureDarshan = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xCC1E0904),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Brass.gold.withValues(alpha: 0.75), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.visibility_rounded, size: 16, color: Color(0xFFFFE08A)),
                            const SizedBox(width: 6),
                            Text(
                              _t(lang, en: 'Show Seva', hi: 'सेवा दिखाएं', mr: 'सेवा दाखवा'),
                              style: GoogleFonts.mukta(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFFE9B0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: padding.top + 55,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: (_thaliCoach && !_aartiComplete && _whisperText == null) ? 1 : 0,
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
                              en: 'Try it — drag the thali in circles',
                              hi: 'ऐसे उंगली से थाली घुमाएं',
                              mr: 'असे बोटाने ताट फिरवा',
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
                if (!_pureDarshan)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _RitualTray(
                      actions: actions,
                      height: trayHeight,
                      deityName: deity.localizedName(lang),
                      changeLabel: _t(lang, en: 'Change deity', hi: 'देवता बदलें', mr: 'देवता बदला'),
                      onChangeDeity: _changeDeity,
                    ),
                  ),
                if (_aarti)
                  MandirAartiSession(
                    key: ValueKey(deity.key),
                    panel: Rect.fromLTWH(8, l.size.height, l.size.width - 16, lyricsHeight),
                    videoTop: padding.top + 55,
                    face: Rect.fromLTRB(
                      l.murti.center.dx - l.murti.width * 0.26,
                      l.murti.top,
                      l.murti.center.dx + l.murti.width * 0.26,
                      l.murti.top + l.murti.height * 0.45,
                    ),
                    onSingAlong: _onSingAlong,
                    onCompleted: _onAartiComplete,
                  ),
                if (_aarti && _aartiRounds > 0 && !_aartiComplete && !_thaliCoach && _whisperText == null)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: padding.top + 55,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xCC2A0E06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Brass.gold.withValues(alpha: 0.65), width: 0.7),
                          ),
                          child: Text(
                            _t(
                              lang,
                              en: '🪔 Aarti Parikrama ${_aartiRounds.clamp(1, 3)}/3',
                              hi: '🪔 आरती परिक्रमा ${_aartiRounds.clamp(1, 3)}/3',
                              mr: '🪔 आरती परिक्रमा ${_aartiRounds.clamp(1, 3)}/3',
                            ),
                            style: GoogleFonts.mukta(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFE08A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: padding.top + 55,
                  child: AnimatedSwitcher(
                    duration: AppMotion.entrance,
                    child: _aartiComplete
                        ? _AartiCompleteBanner(lang: lang, onPour: _pourGhee)
                        : _whisperText != null
                        ? IgnorePointer(
                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 28),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xD9240B04),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Brass.gold.withValues(alpha: 0.75), width: 0.8),
                                ),
                                child: Text(
                                  _whisperText!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.mukta(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFFE9B0),
                                  ),
                                ),
                              ),
                            ),
                          )
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

  Widget _background(_SanctumLayout l, double dpr, SanctumPrahar prahar, bool light) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MandirAssetImage(
          MandirAssets.sanctum,
          fallback: const SanctumWallPainter(),
          fit: BoxFit.cover,
          cacheWidth: (l.size.width * dpr).round(),
        ),
        ColoredBox(color: prahar.ambientTint),
        _ClockPaint(
          (c) => FloorDiyasGlowPainter(
            light ? const AlwaysStoppedAnimation(0.0) : c,
            boost: prahar == SanctumPrahar.evening ? 1.3 : 1.0,
          ),
        ),
        if (!light) _ClockPaint((c) => PranaDustPainter(c)),
      ],
    );
  }

  Widget _archLayer(_SanctumLayout l, double dpr, AkhandDiyaController diya) {
    final haloAlpha = diya.everLit ? 0.36 : 0.18;
    return Stack(
      children: [
        Positioned.fromRect(
          rect: l.arch.inflate(l.arch.width * 0.25),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [Color.fromRGBO(255, 183, 77, haloAlpha), const Color(0x00FFB74D)]),
            ),
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

  Widget _deityLayer(_SanctumLayout l, double dpr, BhaktiDeity deity, AkhandDiyaController diya, bool light) {
    final auraIntensity = _aarti ? 1.35 : (diya.everLit ? 1.0 : 0.45);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fromRect(
          rect: l.murti.inflate(l.murti.width * 0.28),
          child: IgnorePointer(
            child: _ClockPaint(
              (c) => DivineAuraPainter(light ? const AlwaysStoppedAnimation(0.0) : c, intensity: auraIntensity),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: l.sinhasan,
          child: const RepaintBoundary(
            child: CustomPaint(painter: MurtiSeatShadowPainter(), size: Size.infinite),
          ),
        ),
        Positioned.fromRect(
          rect: l.murti,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 550),
            switchInCurve: AppMotion.easeOut,
            switchOutCurve: AppMotion.easeOut,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween(begin: 0.92, end: 1.0).animate(animation),
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
            child: RepaintBoundary(
              key: ValueKey((deity.key, deity.imageAsset, deity.imageUrl)),
              child: MandirMurti(
                deity: deity,
                decodeWidth: (l.size.width * .5 * dpr).round(),
                liquid: _liquid,
                lightRendering: light,
                progress: _abhishek,
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
          rect: l.feet,
          child: Semantics(
            button: true,
            label: _t(_lang, en: 'Charan sparsh', hi: 'चरण स्पर्श', mr: 'चरणस्पर्श'),
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _charanSparsh),
          ),
        ),
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
        IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: PetalRainPainter(_petals, count: light ? 18 : 35)),
          ),
        ),
      ],
    );
  }

  Widget _altarLayer(_SanctumLayout l, double dpr, AkhandDiyaController diya, bool light) {
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
        Positioned.fromRect(
          rect: l.rangoli,
          child: const IgnorePointer(
            child: RepaintBoundary(child: CustomPaint(painter: PadmaRangoliPainter())),
          ),
        ),
        Positioned.fromRect(
          rect: l.platform,
          child: const IgnorePointer(
            child: RepaintBoundary(child: CustomPaint(painter: AltarPainter(topFraction: .44))),
          ),
        ),
        Positioned.fromRect(
          rect: l.dhoop,
          child: Semantics(
            button: true,
            label: _t(_lang, en: 'Light incense', hi: 'धूप जलाएं', mr: 'धूप लावा'),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _flareDhoop,
              child: _ClockPaint((c) => DhoopSmokePainter(c, surge: _dhoop, lightRendering: light)),
            ),
          ),
        ),
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
        for (final vessel in [l.diya, l.kalash])
          Positioned.fromRect(
            rect: Rect.fromCenter(
              center: vessel.bottomCenter.translate(0, -vessel.height * .08),
              width: vessel.width * .82,
              height: vessel.height * .16,
            ),
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(radius: .5, colors: [Color(0x990D0602), Color(0x000D0602)]),
                  shape: BoxShape.rectangle,
                ),
              ),
            ),
          ),
        Positioned.fromRect(
          rect: l.diya.inflate(l.diya.width * 0.42),
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
                        const Color(0xFFFFA726).withValues(alpha: 0.12 + 0.30 * glow + 0.22 * _surge.value),
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
                cacheWidth: (l.size.width * 0.34 * dpr).round(),
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
                            cacheWidth: (l.size.width * 0.24 * dpr).round(),
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
          rect: l.toran,
          child: IgnorePointer(
            child: Image.asset(
              'assets/bhakti/garland_top.webp',
              fit: BoxFit.fill,
              cacheWidth: (l.toran.width * dpr).round(),
              excludeFromSemantics: true,
            ),
          ),
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

/// Real brass aarti thali driven by a lightweight ValueNotifier so dragging
/// at 60fps never rebuilds the gesture wrapper or static plate graphics.
class _AartiThali extends StatefulWidget {
  const _AartiThali({
    required this.start,
    required this.width,
    required this.orbitCenter,
    required this.dpr,
    required this.directDrag,
    this.playCoach = false,
    this.onCoachFinished,
    this.onRoundCompleted,
  });

  final Offset start;
  final double width;

  /// The murti; a soft haptic marks every quarter turn around it.
  final Offset orbitCenter;
  final double dpr;
  final bool directDrag;
  final bool playCoach;
  final VoidCallback? onCoachFinished;
  final ValueChanged<int>? onRoundCompleted;

  @override
  State<_AartiThali> createState() => _AartiThaliState();
}

class _AartiThaliState extends State<_AartiThali> with SingleTickerProviderStateMixin {
  static const _follow = 0.28;

  final List<AartiSpark> _sparks = [];
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  late Offset _pos = widget.start;
  late Offset _target = widget.start;
  Offset _grab = Offset.zero;
  double _tilt = 0;
  double _lean = 0;
  double _orbitAngle = 0;
  double _travelled = 0;
  int _quarters = 0;
  int _rounds = 0;
  int _sparkSeed = 0;
  ValueListenable<double>? _clock;
  double _lastT = 0;
  late final AnimationController _coach;
  bool _coaching = false;
  bool _coachStarted = false;
  bool _reducedMotion = false;
  Timer? _coachDelay;

  /// Plate centre within the thali box, as a share of its width.
  static const _plateCenterY = 0.56;
  static const _heightFactor = 0.85;

  @override
  void initState() {
    super.initState();
    _coach = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
      ..addListener(_onCoachTick)
      ..addStatusListener(_onCoachStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    final clock = MandirClockScope.of(context);
    if (clock != _clock) {
      _clock?.removeListener(_step);
      _clock = clock..addListener(_step);
      _lastT = clock.value;
    }
    _orbitAngle = _angleAround(_pos);
    _maybeStartCoach();
  }

  @override
  void didUpdateWidget(covariant _AartiThali oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playCoach && !oldWidget.playCoach) {
      _coachStarted = false;
      _maybeStartCoach();
    }
  }

  @override
  void dispose() {
    _coachDelay?.cancel();
    _coach
      ..removeListener(_onCoachTick)
      ..removeStatusListener(_onCoachStatus)
      ..dispose();
    _clock?.removeListener(_step);
    _frame.dispose();
    super.dispose();
  }

  void _maybeStartCoach() {
    if (_coachStarted || !widget.playCoach) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _coachStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onCoachFinished?.call();
      });
      return;
    }
    _coachStarted = true;
    _coaching = true;
    _coachDelay?.cancel();
    _coachDelay = Timer(const Duration(milliseconds: 420), () {
      if (mounted && widget.playCoach && _coaching) _coach.forward(from: 0);
    });
  }

  double _coachArc(double t) {
    if (t < 0.1) return 0;
    if (t < 0.52) return Curves.easeInOut.transform((t - 0.1) / 0.42);
    if (t < 0.92) return 1 - Curves.easeInOut.transform((t - 0.52) / 0.4);
    return 0;
  }

  Offset _coachPoint(double arc) {
    final center = widget.orbitCenter;
    final start = widget.start;
    final radius = math.max((start - center).distance, widget.width * 1.15);
    final startAngle = (start - center).direction;
    final angle = startAngle + arc * math.pi;
    return _clamp(Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle)));
  }

  void _onCoachTick() {
    if (!_coaching) return;
    _target = _coachPoint(_coachArc(_coach.value));
  }

  void _onCoachStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_coaching) return;
    _coaching = false;
    _target = widget.start;
    widget.onCoachFinished?.call();
    if (mounted) setState(() {});
  }

  void _stopCoachForUser() {
    if (!_coaching && !_coach.isAnimating) return;
    _coachDelay?.cancel();
    _coaching = false;
    _coach.stop();
    widget.onCoachFinished?.call();
    if (mounted) setState(() {});
  }

  double _angleAround(Offset p) => (p - widget.orbitCenter).direction;

  void _step({bool followFinger = false}) {
    final now = _clock!.value;
    final frames = ((now - _lastT) * 60).clamp(0.0, 3.0);
    _lastT = now;
    final k = followFinger ? 1.0 : 1 - math.pow(1 - _follow, frames).toDouble();

    final prev = _pos;
    _pos = Offset.lerp(_pos, _target, k)!;
    final vel = _pos - prev;
    final speed = vel.distance;

    _tilt += ((vel.dx * 0.012).clamp(-0.2, 0.2) - _tilt) * 0.2;
    _lean += ((-vel.dx / 9).clamp(-1.0, 1.0) - _lean) * 0.25;

    if (speed > 0.8) {
      final steps = _reducedMotion ? 0 : math.max(1, (speed / 6).ceil());
      for (var i = 1; i <= steps; i++) {
        final p = Offset.lerp(prev, _pos, i / steps)!;
        _sparks.add(AartiSpark(p.translate(0, -widget.width * 0.32), now, _sparkSeed++));
      }
      if (!_coaching) {
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
          final round = q ~/ 4;
          if (round > _rounds) {
            _rounds = round;
            widget.onRoundCompleted?.call(round);
          }
        }
      }
    }
    final hadSparks = _sparks.isNotEmpty;
    _sparks.removeWhere((s) => now - s.born > SparkTrailPainter.life);

    if (speed > 0.05 || _tilt.abs() > 0.002 || _lean.abs() > 0.01 || _coaching || hadSparks) {
      _frame.value++;
    }
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
    _stopCoachForUser();
    final grabbed = (d.localPosition - _pos).distance < widget.width * 0.6;
    _grab = grabbed ? _pos - d.localPosition : Offset(0, -widget.width * 0.28);
    _target = _clamp(d.localPosition + _grab);
  }

  void _onUpdate(DragUpdateDetails d) {
    _target = _clamp(d.localPosition + _grab);
    if (_reducedMotion || widget.directDrag) _step(followFinger: true);
  }

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

    final staticPlate = Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(
          child: RepaintBoundary(child: CustomPaint(painter: AartiThaliPainter())),
        ),
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
                painter: FlamePainter(clock: clock, intensity: 0.95, seed: 3, lean: _lean),
              ),
            ),
          ),
        ),
      ],
    );

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
        child: AnimatedBuilder(
          animation: _frame,
          child: staticPlate,
          builder: (context, plate) {
            final fingerPulse = _coaching ? (0.55 + 0.45 * math.sin(_coach.value * math.pi * 6)) : 0.0;
            return Stack(
              fit: StackFit.expand,
              children: [
                if (_sparks.isNotEmpty)
                  IgnorePointer(
                    child: CustomPaint(
                      painter: SparkTrailPainter(clock: clock, sparks: _sparks),
                    ),
                  ),
                if (_coaching)
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _ThaliCoachArcPainter(
                        center: widget.orbitCenter,
                        start: widget.start,
                        radius: math.max((widget.start - widget.orbitCenter).distance, w * 1.15),
                        progress: _coachArc(_coach.value),
                      ),
                    ),
                  ),
                Positioned(
                  left: _pos.dx - w / 2,
                  top: _pos.dy - w * _plateCenterY,
                  width: w,
                  height: h,
                  child: Transform.rotate(angle: _tilt, alignment: const Alignment(0, 0.3), child: plate),
                ),
                if (_coaching)
                  Positioned(
                    left: _pos.dx + w * 0.12,
                    top: _pos.dy + w * 0.08,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: fingerPulse.clamp(0.35, 1),
                        child: Icon(
                          Icons.touch_app_rounded,
                          size: w * 0.42,
                          color: const Color(0xFFFFE9B0).withValues(alpha: 0.95),
                          shadows: const [Shadow(color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 2))],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Soft gold arc under the first-time thali coach so the half-circle path reads clearly.
class _ThaliCoachArcPainter extends CustomPainter {
  _ThaliCoachArcPainter({required this.center, required this.start, required this.radius, required this.progress});

  final Offset center;
  final Offset start;
  final double radius;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final startAngle = (start - center).direction;
    final track = Paint()
      ..color = Brass.gold.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final drawn = Paint()
      ..color = Brass.gold.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startAngle, math.pi, false, track);
    if (progress > 0.01) {
      canvas.drawArc(rect, startAngle, math.pi * progress, false, drawn);
    }
  }

  @override
  bool shouldRepaint(covariant _ThaliCoachArcPainter old) =>
      old.progress != progress || old.center != center || old.radius != radius;
}

class _DarshanHeader extends StatelessWidget {
  const _DarshanHeader({
    required this.lang,
    required this.deityName,
    required this.prahar,
    required this.onDeityTap,
    required this.onSankalpTap,
    required this.onDarshanToggle,
    required this.topPadding,
    this.onVoiceTap,
  });
  final String lang, deityName;
  final SanctumPrahar prahar;
  final VoidCallback onDeityTap, onSankalpTap, onDarshanToggle;
  final VoidCallback? onVoiceTap;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFFFFE9BF);
    return Container(
      padding: EdgeInsets.fromLTRB(4, topPadding, 6, 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFA160E09), Color(0xD61B110C), Color(0x001B110C)],
          stops: [0, .72, 1],
        ),
      ),
      child: Row(
        children: [
          BackButton(color: ink),
          Expanded(
            child: InkWell(
              onTap: onDeityTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prahar.localizedLabel(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.mukta(color: Brass.gold, fontSize: 12),
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          deityName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.mukta(color: ink, fontSize: 22, height: 1.15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.expand_more, color: ink, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (onVoiceTap != null)
            IconButton(
              onPressed: onVoiceTap,
              tooltip: _t(lang, en: 'Bhakti AI', hi: 'भक्ति AI', mr: 'भक्ती AI'),
              icon: const Icon(Icons.mic_none_rounded, color: ink),
            ),
          IconButton(
            onPressed: onSankalpTap,
            tooltip: _t(lang, en: 'Daily sankalp', hi: 'नित्य पूजा संकल्प', mr: 'नित्य पूजा संकल्प'),
            icon: const Icon(Icons.event_available_outlined, color: ink),
          ),
          IconButton(
            onPressed: onDarshanToggle,
            tooltip: _t(lang, en: 'Pure darshan', hi: 'निर्मल दर्शन', mr: 'निर्मल दर्शन'),
            icon: const Icon(Icons.visibility_outlined, color: ink),
          ),
        ],
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

class _RitualTray extends StatelessWidget {
  const _RitualTray({
    required this.actions,
    required this.height,
    required this.deityName,
    required this.changeLabel,
    required this.onChangeDeity,
  });
  final double height;
  final String deityName;
  final String changeLabel;
  final VoidCallback onChangeDeity;
  final List<_Seva> actions;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF382318), Color(0xFF1D110B)],
        ),
        border: Border(top: BorderSide(color: Color(0xFFAA8650))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              SizedBox(
                height: _pickerHeight,
                child: Semantics(
                  button: true,
                  child: InkWell(
                    onTap: onChangeDeity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.temple_hindu_outlined, color: Brass.gold, size: 21),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              deityName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.mukta(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFFE9BF),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              changeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.mukta(fontSize: 15, fontWeight: FontWeight.w700, color: Brass.gold),
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18, color: Brass.gold),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              for (var row = 0; row < 2; row++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        for (final seva in actions.skip(row * 5).take(5))
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: _RitualButton(
                                label: seva.label,
                                onTap: seva.onTap,
                                active: seva.active,
                                primary: seva.icon == SevaIcon.ghee || seva.icon == SevaIcon.aarti,
                                icon: CustomPaint(size: const Size.square(22), painter: SevaIconPainter(seva.icon)),
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
      ),
    );
  }
}

class _RitualButton extends StatelessWidget {
  const _RitualButton({
    required this.label,
    required this.onTap,
    required this.icon,
    this.active = false,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final Widget icon;
  final bool active;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? const Color(0xFF8C4918)
        : primary
        ? const Color(0x666E2D10)
        : const Color(0x552E160C);
    final border = active
        ? Brass.gold
        : primary
        ? Brass.gold.withValues(alpha: 0.72)
        : const Color(0x55C59648);
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: active ? 1.2 : 0.8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(height: 2),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 84),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: GoogleFonts.mukta(
                            fontSize: _ritualLabelSize,
                            height: 1.08,
                            fontWeight: active || primary ? FontWeight.w700 : FontWeight.w400,
                            color: const Color(0xFFFFE9BF),
                          ),
                        ),
                      ),
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

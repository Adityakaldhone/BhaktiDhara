import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/jaap_mantra.dart';
import '../../domain/entities/jaap_progress.dart';
import '../../services/backend_service.dart';
import '../../services/jaap_chant_engine.dart';
import '../../services/jaap_feedback_service.dart';
import '../jaap/jaap_colors.dart';
import '../jaap/jaap_strings.dart';
import '../providers/jaap_providers.dart';
import '../providers/locale_provider.dart';
import '../widgets/jaap/diya_lamp.dart';
import '../widgets/jaap/jaap_background.dart';
import '../widgets/jaap/jaap_celebration.dart';
import '../widgets/jaap/jaap_sheets.dart';
import '../widgets/jaap/mala_ring.dart';
import '../widgets/jaap/petal_shower.dart';
import '../widgets/premium_blurred_gate.dart';
import 'jaap_stats_screen.dart';
import 'jaap_welcome_screen.dart';

enum _ChantState { off, playing, paused }

/// The digital mala. Almost the whole screen is one tap target.
class JaapCounterScreen extends ConsumerStatefulWidget {
  const JaapCounterScreen({super.key});

  @override
  ConsumerState<JaapCounterScreen> createState() => _JaapCounterScreenState();
}

class _JaapCounterScreenState extends ConsumerState<JaapCounterScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final Animation<double> _glow = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 70),
  ]).animate(_glowController);

  int _petalTrigger = 0;
  bool _celebrating = false;
  bool? _wakelockOn;
  _ChantState _chant = _ChantState.off;
  late final ChantAudioEngine _engine;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = ref.read(chantAudioEngineProvider);
    BackendService.trackEvent('jaap_open');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(jaapProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine.stop();
    _setWakelock(false);
    _pulse.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _setWakelock(bool on) {
    if (_wakelockOn == on) return;
    _wakelockOn = on;
    WakelockPlus.toggle(enable: on).catchError((_) {});
  }

  void _onTap() {
    if (_celebrating || _chant != _ChantState.off) return;
    _handleResult(ref.read(jaapProvider.notifier).tap());
  }

  void _onAudioBead() {
    if (!mounted) return;
    _handleResult(
      ref.read(jaapProvider.notifier).tap(fromAudio: true),
      fromAudio: true,
    );
  }

  Future<void> _startChant() async {
    final jaap = ref.read(jaapProvider);
    final lang = ref.read(localeProvider).languageCode;
    final mantra = jaap.mantra;
    if (!mantra.freeAudio && !jaap.isPremium) {
      showPremiumPaywallSheet(context, ref, lang);
      return;
    }
    setState(() => _chant = _ChantState.playing);
    try {
      await _engine.start(
        asset: mantra.audioAsset,
        repetitions: JaapProgress.beadsPerMala - jaap.beadIndex,
        onRepetition: _onAudioBead,
        onFinished: () {
          if (mounted) setState(() => _chant = _ChantState.off);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _chant = _ChantState.off);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: MandirTheme.secondaryMaroon,
          content: Text(
            JaapStrings(lang).audioError,
            style: GoogleFonts.mukta(fontSize: 18, color: Colors.white),
          ),
        ),
      );
    }
  }

  void _togglePause() {
    if (_chant == _ChantState.playing) {
      _engine.pause();
      setState(() => _chant = _ChantState.paused);
    } else if (_chant == _ChantState.paused) {
      _engine.resume();
      setState(() => _chant = _ChantState.playing);
    }
  }

  void _stopChant() {
    _engine.stop();
    if (mounted) setState(() => _chant = _ChantState.off);
  }

  void _handleResult(JaapTapResult? result, {bool fromAudio = false}) {
    if (result == null) return;
    final jaap = ref.read(jaapProvider);
    ref
        .read(jaapFeedbackProvider)
        .onTap(
          result,
          fromAudio
              ? jaap.progress.copyWith(tickSoundOn: false)
              : jaap.progress,
        );
    _pulse.forward(from: 0);
    if (result.outcome != JaapTapOutcome.bead) {
      _glowController.forward(from: 0);
    }

    final s = JaapStrings(ref.read(localeProvider).languageCode);
    if (result.outcome == JaapTapOutcome.goalComplete) {
      setState(() => _petalTrigger++);
      _celebrate(s, jaap.currentStreak, result.milestone);
    } else if (result.milestone != null) {
      setState(() => _petalTrigger++);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: MandirTheme.secondaryMaroon,
          content: Text(
            s.milestoneReached(s.compact(result.milestone!)),
            style: GoogleFonts.mukta(fontSize: 18, color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _celebrate(JaapStrings s, int streak, int? milestone) async {
    _celebrating = true;
    final wasPlaying = _chant == _ChantState.playing;
    if (wasPlaying) _togglePause();
    final choice = await showSankalpPurnaDialog(
      context,
      strings: s,
      streak: streak,
      milestone: milestone,
    );
    _celebrating = false;
    if (!mounted) return;
    if (choice == SankalpChoice.done) {
      _stopChant();
      Navigator.pop(context);
    } else if (wasPlaying && _chant == _ChantState.paused) {
      _togglePause();
    }
  }

  void _openMantraPicker(String lang) {
    if (_chant != _ChantState.off) _stopChant();
    showJaapMantraPicker(context, ref, lang);
  }

  void _onUndo() {
    if (ref.read(jaapProvider.notifier).undo()) {
      ref.read(jaapFeedbackProvider).onUndo(ref.read(jaapProvider).progress);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jaap = ref.watch(jaapProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final s = JaapStrings(lang);

    if (jaap.loaded && !jaap.progress.isOnboarded) {
      return const JaapWelcomeScreen();
    }
    if (jaap.loaded) _setWakelock(jaap.progress.keepScreenOn);

    final mantra = jaap.mantra;
    return Scaffold(
      body: JaapBackground(
        deity: mantra.deity,
        child: Stack(
          children: [
            SafeArea(
              child: !jaap.loaded
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: MandirTheme.primarySaffron,
                      ),
                    )
                  : Column(
                      children: [
                        _buildTopBar(s, lang, mantra),
                        if (mantra.isLong) _buildLongMantraCard(mantra),
                        Expanded(child: _buildTapZone(jaap, s, mantra)),
                        _buildBottomBar(s, jaap),
                      ],
                    ),
            ),
            Positioned.fill(child: PetalShower(trigger: _petalTrigger)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(JaapStrings s, String lang, JaapMantra mantra) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          IconButton(
            iconSize: 30,
            constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
            tooltip: s.back,
            color: MandirTheme.secondaryMaroon,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Center(
              child: Semantics(
                button: true,
                label: s.changeMantra,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _openMantraPicker(lang),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: MandirTheme.goldenAccent,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            mantra.localizedName(lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.mukta(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: MandirTheme.secondaryMaroon,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 30,
                          color: MandirTheme.secondaryMaroon,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            iconSize: 28,
            constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
            tooltip: s.settings,
            color: MandirTheme.secondaryMaroon,
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => showJaapSettingsSheet(context, ref, lang),
          ),
        ],
      ),
    );
  }

  Widget _buildLongMantraCard(JaapMantra mantra) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      constraints: const BoxConstraints(maxHeight: 120),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MandirTheme.cardBorder),
      ),
      child: SingleChildScrollView(
        child: Text(
          mantra.devanagari,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 20,
            height: 1.5,
            fontWeight: FontWeight.w700,
            color: JaapColors.mantraMaroon,
          ),
        ),
      ),
    );
  }

  Widget _buildTapZone(JaapState jaap, JaapStrings s, JaapMantra mantra) {
    final String? banner = jaap.protectorUsedYesterday
        ? s.protectorUsed
        : (jaap.showWelcomeBack ? s.welcomeBack : null);
    const total = JaapProgress.beadsPerMala;

    return GestureDetector(
      key: const ValueKey('jaap-tap-zone'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _onTap(),
      child: Column(
        children: [
          if (banner != null) _buildBanner(banner),
          if (!mantra.isLong) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                mantra.devanagari,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 28,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: JaapColors.mantraMaroon,
                ),
              ),
            ),
            Text(
              mantra.transliteration,
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: MandirTheme.textMuted,
              ),
            ),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: MalaRing(
                    beadIndex: jaap.beadIndex,
                    malaNumber: jaap.sessionMalas,
                    pulse: _pulse,
                    glow: _glow,
                    center: _buildCount(jaap, s, total),
                  ),
                ),
              ),
            ),
          ),
          _buildProgressRow(jaap, s),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 6),
            child: Text(
              _chant != _ChantState.off
                  ? s.chantAlongHint
                  : (jaap.sessionCount == 0
                        ? s.tapToBegin
                        : '~  ${s.tapAnywhere}  ~'),
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(
                fontSize: jaap.sessionCount == 0 || _chant != _ChantState.off
                    ? 19
                    : 16,
                fontWeight: FontWeight.w600,
                color: jaap.sessionCount == 0 || _chant != _ChantState.off
                    ? MandirTheme.primarySaffron
                    : MandirTheme.textMuted.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCount(JaapState jaap, JaapStrings s, int total) {
    final announcedBead = (jaap.beadIndex ~/ 10) * 10;
    return FractionallySizedBox(
      widthFactor: 0.6,
      heightFactor: 0.6,
      child: Semantics(
        container: true,
        liveRegion: true,
        excludeSemantics: true,
        label: s.beadSemantics(announcedBead, total, jaap.sessionMalas + 1),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _glow,
                child: Text(
                  s.malaComplete,
                  style: GoogleFonts.mukta(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: MandirTheme.primarySaffron,
                  ),
                ),
              ),
              Text(
                '${jaap.beadIndex}',
                key: const ValueKey('jaap-count'),
                style: GoogleFonts.mukta(
                  fontSize: 84,
                  height: 1.0,
                  fontWeight: FontWeight.w800,
                  color: JaapColors.counterGold,
                  shadows: [
                    Shadow(
                      color: JaapColors.glowGold.withValues(alpha: 0.8),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
              Text(
                s.ofBeads(total),
                style: GoogleFonts.mukta(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: MandirTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRow(JaapState jaap, JaapStrings s) {
    final goal = jaap.progress.dailyGoalMalas;
    final streak = jaap.currentStreak;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: _pill(
              leading: const Text('📿', style: TextStyle(fontSize: 22)),
              text: jaap.goalMetToday
                  ? '${s.malaProgress(jaap.malasToday, goal)} ✓'
                  : s.malaProgress(jaap.malasToday, goal),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: _pill(
              leading: DiyaLamp(size: 28, lit: streak > 0),
              text: streak > 0 ? s.streakDays(streak) : s.firstDay,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({required Widget leading, required String text}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: MandirTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.mukta(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: MandirTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(String text) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8C98A)),
      ),
      child: Row(
        children: [
          const Text('🙏', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.mukta(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: MandirTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(JaapStrings s, JaapState jaap) {
    ButtonStyle style() => OutlinedButton.styleFrom(
      foregroundColor: MandirTheme.secondaryMaroon,
      backgroundColor: Colors.white.withValues(alpha: 0.6),
      side: const BorderSide(color: MandirTheme.goldenAccent, width: 1.2),
      minimumSize: const Size.fromHeight(56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: GoogleFonts.mukta(fontSize: 18, fontWeight: FontWeight.w700),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChantControls(s, jaap),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: style(),
                  onPressed: jaap.sessionCount > 0 && _chant == _ChantState.off
                      ? _onUndo
                      : null,
                  icon: const Icon(Icons.undo_rounded, size: 24),
                  label: Text(s.undo),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: style(),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JaapStatsScreen()),
                  ),
                  icon: const Icon(Icons.insights_rounded, size: 24),
                  label: Text(
                    s.mySadhana,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChantControls(JaapStrings s, JaapState jaap) {
    final textStyle = GoogleFonts.mukta(
      fontSize: 19,
      fontWeight: FontWeight.w800,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );

    if (_chant == _ChantState.off) {
      final locked = !jaap.mantra.freeAudio && !jaap.isPremium;
      return SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton.icon(
          key: const ValueKey('jaap-chant-start'),
          onPressed: _startChant,
          style: ElevatedButton.styleFrom(
            backgroundColor: MandirTheme.secondaryMaroon,
            foregroundColor: Colors.white,
            shape: shape,
          ),
          icon: Icon(
            locked ? Icons.workspace_premium_rounded : Icons.headphones_rounded,
            size: 26,
            color: locked ? JaapColors.glowGold : Colors.white,
          ),
          label: Text(s.chantWithAudio, style: textStyle),
        ),
      );
    }

    final playing = _chant == _ChantState.playing;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 58,
            child: ElevatedButton.icon(
              onPressed: _togglePause,
              style: ElevatedButton.styleFrom(shape: shape),
              icon: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 30,
              ),
              label: Text(playing ? s.pause : s.resume, style: textStyle),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 58,
            child: OutlinedButton.icon(
              onPressed: _stopChant,
              style: OutlinedButton.styleFrom(
                foregroundColor: MandirTheme.secondaryMaroon,
                backgroundColor: Colors.white.withValues(alpha: 0.6),
                side: const BorderSide(
                  color: MandirTheme.goldenAccent,
                  width: 1.2,
                ),
                shape: shape,
              ),
              icon: const Icon(Icons.stop_rounded, size: 28),
              label: Text(s.stop, style: textStyle),
            ),
          ),
        ),
      ],
    );
  }
}

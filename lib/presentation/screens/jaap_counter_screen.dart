import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/theme/theme.dart';
import '../../data/datasources/jaap_mantra_catalog.dart';
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
import '../providers/review_provider.dart';
import 'jaap_stats_screen.dart';

enum _ChantState { off, playing, paused }

/// The digital mala. Almost the whole screen is one tap target.
class JaapCounterScreen extends ConsumerStatefulWidget {
  /// When set (e.g. voice "naam jaap radha"), skip the picker and use this mantra.
  final String? initialMantraId;

  /// Skip onboarding/entry sheet and go straight to counting.
  final bool skipEntrySheet;

  const JaapCounterScreen({
    super.key,
    this.initialMantraId,
    this.skipEntrySheet = false,
  });

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
  bool _entrySheetShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = ref.read(chantAudioEngineProvider);
    BackendService.trackEvent('jaap_open');
  }

  Future<void> _ensureOnboarded() async {
    if (_entrySheetShown) return;
    final jaap = ref.read(jaapProvider);
    if (!jaap.loaded) return;

    final voiceMantra = widget.initialMantraId?.trim();
    final skipSheet = widget.skipEntrySheet || (voiceMantra != null && voiceMantra.isNotEmpty);

    // Voice deep-link: select mantra and continue without the picker.
    if (skipSheet) {
      _entrySheetShown = true;
      final notifier = ref.read(jaapProvider.notifier);
      final mid = (voiceMantra != null && voiceMantra.isNotEmpty)
          ? voiceMantra
          : (jaap.progress.mantraId ?? JaapMantraCatalog.defaultMantraId);
      if (!jaap.progress.isOnboarded) {
        await notifier.completeOnboarding(
          mantraId: mid,
          dailyGoalMalas: jaap.progress.dailyGoalMalas,
        );
      } else {
        notifier.selectMantra(mid);
      }
      notifier.startSession();
      return;
    }

    if (jaap.progress.isOnboarded) return;
    _entrySheetShown = true;
    final lang = ref.read(localeProvider).languageCode;
    final mantraId = await showJaapEntrySheet(
      context,
      ref,
      lang,
      isOnboarding: true,
    );
    if (!mounted) return;
    if (mantraId == null) {
      Navigator.maybePop(context);
      return;
    }
    await ref.read(jaapProvider.notifier).completeOnboarding(
          mantraId: mantraId,
          dailyGoalMalas: ref.read(jaapProvider).progress.dailyGoalMalas,
        );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(jaapProvider.notifier).refresh();
      final jaap = ref.read(jaapProvider);
      if (jaap.loaded && jaap.progress.isOnboarded) {
        _setWakelock(jaap.progress.keepScreenOn, force: true);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine.stop();
    if (_wakelockOn == true) _setWakelock(false);
    _pulse.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _setWakelock(bool on, {bool force = false}) {
    if (!force && _wakelockOn == on) return;
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

    // Track mala completion for review eligibility
    ref.read(reviewServiceProvider).trackJaapMalaCompleted();

    final choice = await showSankalpPurnaDialog(
      context,
      strings: s,
      streak: streak,
      milestone: milestone,
    );
    _celebrating = false;
    if (!mounted) return;

    // After celebration, check if the devotee is eligible for a review prompt.
    // Directly launches Google Play's official native review sheet!
    final reviewService = ref.read(reviewServiceProvider);
    if (reviewService.isEligibleForPrompt()) {
      await reviewService.recordPromptShown();
      if (mounted) {
        await reviewService.requestInAppReview();
      }
    }

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
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureOnboarded());
      // No spinner — an indeterminate indicator never settles in tests.
      return const Scaffold(backgroundColor: JaapColors.sandalStart);
    }
    if (jaap.loaded) {
      _setWakelock(jaap.progress.keepScreenOn);
      ref.read(jaapFeedbackProvider).warmUp(jaap.progress);
    }

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
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
      child: Row(
        children: [
          IconButton(
            iconSize: 30,
            constraints: const BoxConstraints(minWidth: 52, minHeight: 56),
            tooltip: s.back,
            color: MandirTheme.secondaryMaroon,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Semantics(
              button: true,
              label: s.changeMantra,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => _openMantraPicker(lang),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: JaapColors.surfaceGlass,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: MandirTheme.goldenAccent.withValues(alpha: 0.55),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          mantra.localizedName(lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.mukta(
                            fontSize: 20,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            color: MandirTheme.secondaryMaroon,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 28,
                        color: MandirTheme.secondaryMaroon,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            iconSize: 28,
            constraints: const BoxConstraints(minWidth: 52, minHeight: 56),
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
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      constraints: const BoxConstraints(maxHeight: 110),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: JaapColors.surfaceGlass,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SingleChildScrollView(
        child: Text(
          mantra.devanagari,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 19,
            height: 1.45,
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
    final showStartHint = jaap.sessionCount == 0 || _chant != _ChantState.off;

    return GestureDetector(
      key: const ValueKey('jaap-tap-zone'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _onTap(),
      child: Column(
        children: [
          if (banner != null) _buildBanner(banner),
          if (!mantra.isLong) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                mantra.devanagari,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 30,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: JaapColors.mantraMaroon,
                ),
              ),
            ),
            Text(
              mantra.transliteration,
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: JaapColors.inkSoft.withValues(alpha: 0.75),
              ),
            ),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              _chant != _ChantState.off
                  ? s.chantAlongHint
                  : (jaap.sessionCount == 0 ? s.tapToBegin : s.tapAnywhere),
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(
                fontSize: showStartHint ? 19 : 16,
                fontWeight: FontWeight.w600,
                color: showStartHint
                    ? MandirTheme.primarySaffron
                    : JaapColors.inkSoft.withValues(alpha: 0.65),
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
                      color: JaapColors.glowGold.withValues(alpha: 0.45),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              Text(
                s.ofBeads(total),
                style: GoogleFonts.mukta(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: JaapColors.inkSoft.withValues(alpha: 0.7),
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
    final progress = jaap.goalMetToday
        ? '${s.malaProgress(jaap.malasToday, goal)} ✓'
        : s.malaProgress(jaap.malasToday, goal);
    final streakText = streak > 0 ? s.streakDays(streak) : s.firstDay;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          Expanded(
            child: Text(
              progress,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.mukta(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: JaapColors.inkSoft,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 18,
            color: MandirTheme.goldenAccent.withValues(alpha: 0.35),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DiyaLamp(size: 24, lit: streak > 0),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    streakText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.mukta(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: JaapColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(String text) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: JaapColors.surfaceGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MandirTheme.goldenAccent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 22,
            color: MandirTheme.primarySaffron.withValues(alpha: 0.9),
          ),
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
    final secondaryStyle = TextButton.styleFrom(
      foregroundColor: MandirTheme.secondaryMaroon,
      minimumSize: const Size.fromHeight(52),
      textStyle: GoogleFonts.mukta(fontSize: 17, fontWeight: FontWeight.w700),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChantControls(s, jaap),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  style: secondaryStyle,
                  onPressed: jaap.sessionCount > 0 && _chant == _ChantState.off
                      ? _onUndo
                      : null,
                  icon: const Icon(Icons.undo_rounded, size: 22),
                  label: Text(s.undo),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  style: secondaryStyle,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JaapStatsScreen()),
                  ),
                  icon: const Icon(Icons.insights_rounded, size: 22),
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
      borderRadius: BorderRadius.circular(16),
    );

    if (_chant == _ChantState.off) {
      final locked = !jaap.mantra.freeAudio && !jaap.isPremium;
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          key: const ValueKey('jaap-chant-start'),
          onPressed: _startChant,
          style: ElevatedButton.styleFrom(
            backgroundColor: MandirTheme.secondaryMaroon,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: shape,
          ),
          icon: Icon(
            locked ? Icons.workspace_premium_rounded : Icons.headphones_rounded,
            size: 24,
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
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _togglePause,
              style: ElevatedButton.styleFrom(
                backgroundColor: MandirTheme.secondaryMaroon,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: shape,
              ),
              icon: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 28,
              ),
              label: Text(playing ? s.pause : s.resume, style: textStyle),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 56,
            child: TextButton.icon(
              onPressed: _stopChant,
              style: TextButton.styleFrom(
                foregroundColor: MandirTheme.secondaryMaroon,
                shape: shape,
              ),
              icon: const Icon(Icons.stop_rounded, size: 26),
              label: Text(s.stop, style: textStyle),
            ),
          ),
        ),
      ],
    );
  }
}

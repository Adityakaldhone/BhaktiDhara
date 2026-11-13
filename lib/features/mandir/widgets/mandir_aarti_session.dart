import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/motion.dart';
import '../../../domain/entities/aarti_item.dart';
import '../../../presentation/providers/aarti_providers.dart';
import '../../../presentation/providers/akhand_diya_provider.dart';
import '../../../presentation/providers/locale_provider.dart';
import 'mandir_aarti_player.dart';
import 'mandir_painters.dart';

String _t(String lang, {required String en, required String hi, required String mr}) => switch (lang) {
  'hi' => hi,
  'mr' => mr,
  _ => en,
};

String _clock(int ms) {
  final s = ms ~/ 1000;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// The aarti being performed in the Garbhagriha: a floating YouTube window
/// the devotee can drag anywhere, and the lyrics on the chowki front that
/// follow the song. Without video it becomes "sing myself": lyrics advance
/// by hand over the aarti ghanti.
class MandirAartiSession extends ConsumerStatefulWidget {
  const MandirAartiSession({
    super.key,
    required this.panel,
    required this.videoTop,
    required this.face,
    required this.onSingAlong,
    required this.onCompleted,
  });

  /// Where the lyrics card sits.
  final Rect panel;

  /// Default top edge of the floating video.
  final double videoTop;

  /// The deity's face; the floating video is never left covering it.
  final Rect face;

  /// Reports whether the devotee is singing without the video.
  final ValueChanged<bool> onSingAlong;
  final VoidCallback onCompleted;

  @override
  ConsumerState<MandirAartiSession> createState() => _MandirAartiSessionState();
}

class _MandirAartiSessionState extends ConsumerState<MandirAartiSession> {
  AartiItem? _aarti;
  MandirAartiPlayer? _player;
  late bool _video = MandirAartiPlayer.supported;
  int _manualIndex = 0;
  int _shownIndex = -1;
  bool _completed = false;
  Offset? _videoPos;
  Timer? _scrollTimer;
  List<GlobalKey> _keys = const [];

  List<int> get _starts => _aarti?.lyrics.map((s) => s.startTimeMs).toList() ?? const [];

  bool get _timed => lyricsAreTimed(_starts);

  bool get _following => _video && _timed && _player != null;

  int get _index {
    final p = _player;
    if (_following && p != null) return stanzaAt(_starts, p.positionMs);
    return _manualIndex;
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual<AartiItem?>(jyotAartiProvider, (_, next) {
      if (_aarti == null && next != null) _setAarti(next);
    }, fireImmediately: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onSingAlong(!_video);
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _player?.dispose();
    super.dispose();
  }

  void _setAarti(AartiItem aarti) {
    _player?.dispose();
    _player = null;
    _aarti = aarti;
    _manualIndex = 0;
    _shownIndex = -1;
    _completed = false;
    _keys = List.generate(aarti.lyrics.length, (_) => GlobalKey());
    if (_video) _player = MandirAartiPlayer(aarti, onEnded: _complete)..addListener(_onPlayerTick);
    if (mounted) setState(() {});
  }

  void _onPlayerTick() {
    if (!mounted) return;
    if (_player?.failed ?? false) {
      _setVideo(false);
      return;
    }
    setState(() {});
  }

  void _setVideo(bool video) {
    if (video == _video) return;
    if (video && !MandirAartiPlayer.supported) return;
    HapticFeedback.selectionClick();
    setState(() {
      _video = video;
      _player?.dispose();
      _player = null;
      final aarti = _aarti;
      if (video && aarti != null) {
        _player = MandirAartiPlayer(aarti, onEnded: _complete)..addListener(_onPlayerTick);
      }
    });
    widget.onSingAlong(!video);
  }

  void _select(int i) {
    HapticFeedback.selectionClick();
    if (_following) {
      _player!.seekTo(_starts[i]);
    } else {
      setState(() => _manualIndex = i);
    }
  }

  void _step(int delta) {
    final n = _aarti?.lyrics.length ?? 0;
    final next = _index + delta;
    if (next >= n) {
      if (!_video) _complete();
      return;
    }
    if (next < 0) return;
    _select(next);
  }

  void _complete() {
    if (_completed || !mounted) return;
    setState(() => _completed = true);
    widget.onCompleted();
  }

  void _revealActive(int index) {
    if (index == _shownIndex) return;
    final first = _shownIndex < 0;
    _shownIndex = index;
    if (!first && _following) HapticFeedback.selectionClick();
    // Verses resize as they gain or lose focus; scroll once they have settled.
    _scrollTimer?.cancel();
    _scrollTimer = Timer(AppMotion.entrance + const Duration(milliseconds: 20), () {
      final ctx = index < _keys.length ? _keys[index].currentContext : null;
      if (!mounted || ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(ctx, alignment: 0.15, duration: AppMotion.entrance, curve: AppMotion.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final aarti = _aarti;
    if (aarti == null) return const SizedBox.shrink();
    final lang = ref.watch(localeProvider).languageCode;
    final deity = ref.watch(jyotDeityProvider);
    final catalog = ref.watch(aartiCatalogProvider).valueOrNull ?? const <AartiItem>[];
    final choices = catalog.where((i) => deity.matches(i.deity) && i.lyrics.isNotEmpty).toList();
    final index = math.min(_index, math.max(aarti.lyrics.length - 1, 0));
    _revealActive(index);

    return LayoutBuilder(
      builder: (context, constraints) {
        final player = _player;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fromRect(
              rect: widget.panel,
              child: _LyricsCard(
                aarti: aarti,
                choices: choices,
                lang: lang,
                index: index,
                keys: _keys,
                video: _video,
                canVideo: MandirAartiPlayer.supported,
                player: player,
                onChoose: (a) {
                  if (a.id != aarti.id) _setAarti(a);
                },
                onSelect: _select,
                onStep: _step,
                onVideo: _setVideo,
              ),
            ),
            if (_video && player?.web != null) _floatingVideo(constraints.biggest, player!, lang),
          ],
        );
      },
    );
  }

  Widget _floatingVideo(Size screen, MandirAartiPlayer player, String lang) {
    final face = widget.face;
    const gap = 6.0;
    final w = (screen.width - face.right - gap * 2).clamp(130.0, 240.0);
    final h = w * 9 / 16 + 26;
    Offset clamp(Offset p) => Offset(
      p.dx.clamp(gap, math.max(gap, screen.width - w - gap)),
      p.dy.clamp(gap, math.max(gap, screen.height - h - gap)),
    );

    /// Slides the window off the deity's face to the roomier side.
    Offset clearOfFace(Offset p) {
      if (!(p & Size(w, h)).overlaps(face)) return p;
      final roomLeft = face.left - gap;
      final roomRight = screen.width - face.right - gap;
      return clamp(Offset(roomRight >= roomLeft ? face.right + gap : face.left - gap - w, p.dy));
    }

    final pos = clamp(_videoPos ?? clearOfFace(Offset(screen.width - w - gap, widget.videoTop)));

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      width: w,
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0xCC000000), blurRadius: 16, offset: Offset(0, 6)),
            BoxShadow(color: Color(0x44FFB300), blurRadius: 10),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) => setState(() => _videoPos = clamp(pos + d.delta)),
                onPanEnd: (_) => setState(() => _videoPos = clearOfFace(pos)),
                child: Container(
                  height: 26,
                  padding: const EdgeInsets.only(left: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF9A6B1C), Color(0xFFF7D27A), Color(0xFF9A6B1C)]),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.drag_indicator_rounded, size: 16, color: Color(0xFF3A1A06)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _t(lang, en: 'Drag to move', hi: 'खींचकर हटाएं', mr: 'ओढून हलवा'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.mukta(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF3A1A06),
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: _t(lang, en: 'Close video', hi: 'वीडियो बंद करें', mr: 'व्हिडिओ बंद करा'),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _setVideo(false),
                          child: const SizedBox(
                            width: 32,
                            height: 26,
                            child: Icon(Icons.close_rounded, size: 17, color: Color(0xFF3A1A06)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: Colors.black,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      WebViewWidget(controller: player.web!),
                      if (!player.ready)
                        const IgnorePointer(
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Brass.gold),
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

class _LyricsCard extends StatelessWidget {
  const _LyricsCard({
    required this.aarti,
    required this.choices,
    required this.lang,
    required this.index,
    required this.keys,
    required this.video,
    required this.canVideo,
    required this.player,
    required this.onChoose,
    required this.onSelect,
    required this.onStep,
    required this.onVideo,
  });

  final AartiItem aarti;
  final List<AartiItem> choices;
  final String lang;
  final int index;
  final List<GlobalKey> keys;
  final bool video;
  final bool canVideo;
  final MandirAartiPlayer? player;
  final ValueChanged<AartiItem> onChoose;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onStep;
  final ValueChanged<bool> onVideo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE63A1206), Color(0xF2140604)],
        ),
        border: Border.all(color: Brass.gold.withValues(alpha: 0.75), width: 0.9),
        boxShadow: const [BoxShadow(color: Color(0xAA000000), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          _header(context),
          Expanded(child: _lyrics()),
          _footer(),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final title = Text(
      aarti.localizedTitle(lang),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.mukta(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFFFFE9B0)),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 2),
      child: Row(
        children: [
          const SizedBox(width: 18, height: 18, child: CustomPaint(painter: SevaIconPainter(SevaIcon.aarti))),
          const SizedBox(width: 6),
          Expanded(
            child: choices.length < 2
                ? title
                : PopupMenuButton<AartiItem>(
                    tooltip: _t(lang, en: 'Choose aarti', hi: 'आरती चुनें', mr: 'आरती निवडा'),
                    color: const Color(0xFF2A0B05),
                    onSelected: onChoose,
                    itemBuilder: (_) => [
                      for (final c in choices)
                        PopupMenuItem(
                          value: c,
                          child: Text(
                            c.localizedTitle(lang),
                            style: GoogleFonts.mukta(
                              fontSize: 14,
                              fontWeight: c.id == aarti.id ? FontWeight.w800 : FontWeight.w600,
                              color: c.id == aarti.id ? Brass.gold : const Color(0xFFFFE9B0),
                            ),
                          ),
                        ),
                    ],
                    child: Row(
                      children: [
                        Flexible(child: title),
                        const Icon(Icons.expand_more_rounded, size: 18, color: Brass.gold),
                      ],
                    ),
                  ),
          ),
          if (video || canVideo)
            _ModePill(
              icon: video ? Icons.record_voice_over_rounded : Icons.ondemand_video_rounded,
              label: video
                  ? _t(lang, en: 'Sing myself', hi: 'स्वयं गाएं', mr: 'स्वतः गा')
                  : _t(lang, en: 'Video', hi: 'वीडियो', mr: 'व्हिडिओ'),
              onTap: () => onVideo(!video),
            ),
        ],
      ),
    );
  }

  Widget _lyrics() {
    final showRoman = lang == 'en';
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
        stops: [0, 0.08, 0.88, 1],
      ).createShader(rect),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 18),
        child: Column(
          children: [
            for (var i = 0; i < aarti.lyrics.length; i++)
              GestureDetector(
                key: i < keys.length ? keys[i] : null,
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: AppMotion.entrance,
                  curve: AppMotion.easeOut,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: i == index ? const Color(0x26FFB300) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: i == index ? const Color(0x66FFD54F) : Colors.transparent, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: AppMotion.entrance,
                        curve: AppMotion.ease,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.mukta(
                          fontSize: i == index ? 16.5 : 14,
                          height: 1.35,
                          fontWeight: i == index ? FontWeight.w800 : FontWeight.w600,
                          color: i == index ? const Color(0xFFFFE08A) : const Color(0x8CFFE9B0),
                          shadows: i == index ? const [Shadow(color: Color(0xAAFF8F00), blurRadius: 10)] : const [],
                        ),
                        child: Text(aarti.lyrics[i].devanagari, textAlign: TextAlign.center),
                      ),
                      if (showRoman && aarti.lyrics[i].transliteration.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            aarti.lyrics[i].transliteration,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.mukta(
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              color: i == index ? const Color(0xCCFFE9B0) : const Color(0x66FFE9B0),
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

  Widget _footer() {
    final n = aarti.lyrics.length;
    final p = player;
    final double progress;
    final String label;
    if (video && p != null) {
      progress = p.durationMs > 0 ? (p.positionMs / p.durationMs).clamp(0.0, 1.0) : 0;
      label = p.ready
          ? '${_clock(p.positionMs)} / ${_clock(p.durationMs)}'
          : _t(lang, en: 'Loading aarti…', hi: 'आरती लोड हो रही है…', mr: 'आरती लोड होत आहे…');
    } else {
      progress = n == 0 ? 0 : (index + 1) / n;
      label = _t(lang, en: 'Verse ${index + 1}/$n', hi: 'पद ${index + 1}/$n', mr: 'कडवे ${index + 1}/$n');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
      child: Row(
        children: [
          _RoundButton(
            icon: Icons.chevron_left_rounded,
            label: _t(lang, en: 'Previous verse', hi: 'पिछला पद', mr: 'मागील कडवे'),
            onTap: () => onStep(-1),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const ColoredBox(color: Color(0x33FFE9B0)),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Color(0xFFFF8F00), Color(0xFFFFD54F)]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.mukta(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xCCFFE9B0),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (video && p != null)
            _RoundButton(
              icon: p.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: p.playing
                  ? _t(lang, en: 'Pause', hi: 'रोकें', mr: 'थांबवा')
                  : _t(lang, en: 'Play', hi: 'चलाएं', mr: 'चालू करा'),
              onTap: p.togglePlay,
            ),
          _RoundButton(
            icon: Icons.chevron_right_rounded,
            label: _t(lang, en: 'Next verse', hi: 'अगला पद', mr: 'पुढील कडवे'),
            onTap: () => onStep(1),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4A1508),
                border: Border.all(color: Brass.gold.withValues(alpha: 0.8), width: 0.8),
              ),
              child: Icon(icon, size: 19, color: const Color(0xFFFFE9B0)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 28),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFF5A1A0A),
            border: Border.all(color: Brass.gold.withValues(alpha: 0.8), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Brass.gold),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.mukta(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFFFFE9B0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

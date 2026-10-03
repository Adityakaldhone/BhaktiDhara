import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/bhakti_deity.dart';
import '../providers/bhakti_darshan_providers.dart';
import '../providers/locale_provider.dart';
import '../widgets/bhakti/category_button.dart';
import '../widgets/bhakti/darshan_shrine.dart';
import '../widgets/bhakti/ganesha_chalisa_sheet.dart';
import '../widgets/bhakti/ganesha_mantra_sheet.dart';
import '../widgets/bhakti/ganesha_stotra_sheet.dart';

/// Mandir darshan hub: a carousel of full darshan pages, one per deity.
///
/// The current page fills the screen; the previous and next pages sit on top of it as
/// small cards at the screen edges. Swiping morphs a card into the full page while the
/// current page shrinks into the opposite card slot.
class BhajanScreen extends ConsumerStatefulWidget {
  const BhajanScreen({super.key});

  @override
  ConsumerState<BhajanScreen> createState() => _BhajanScreenState();
}

class _BhajanScreenState extends ConsumerState<BhajanScreen>
    with SingleTickerProviderStateMixin {
  static const _gold = Color(0xFFE2B04F);

  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 140,
    ratio: 1,
  );

  /// Continuous carousel position: integer values are resting pages, fractions are mid-swipe.
  late final AnimationController _page = AnimationController.unbounded(
    vsync: this,
    value: ref.read(selectedDeityIndexProvider).toDouble(),
  )..addListener(_onPageTick);

  late int _nearestPage = _page.value.round();
  double _targetPage = 0;
  double _pageExtent = 1;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  bool get _canSwipe => ref.read(bhaktiDeitiesProvider).length > 1;

  void _onPageTick() {
    final nearest = _page.value.round();
    if (nearest != _nearestPage) {
      _nearestPage = nearest;
      HapticFeedback.selectionClick();
    }
  }

  void _settleTo(double target, {double velocity = 0}) {
    _targetPage = target;
    _page
        .animateWith(SpringSimulation(_spring, _page.value, target, velocity))
        .then((_) => _commit(target));
  }

  void _commit(double target) {
    _page.value = target;
    final deities = ref.read(bhaktiDeitiesProvider);
    if (deities.isEmpty) return;
    final index = target.round() % deities.length;
    if (ref.read(selectedDeityIndexProvider) != index) {
      ref.read(selectedDeityIndexProvider.notifier).state = index;
    }
    _precacheNeighbours(deities, index);
  }

  void _go(int step) {
    if (!_canSwipe) return;
    final base = _page.isAnimating ? _targetPage : _page.value.roundToDouble();
    _settleTo(base + step);
  }

  void _onDragStart(DragStartDetails _) {
    if (_canSwipe) _page.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_canSwipe) return;
    _page.value -= details.delta.dx / _pageExtent;
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_canSwipe) return;
    final pixelVelocity = -(details.primaryVelocity ?? 0);
    final current = _page.value;
    final double target;
    if (pixelVelocity > 250) {
      target = current.floorToDouble() + 1;
    } else if (pixelVelocity < -250) {
      target = current.ceilToDouble() - 1;
    } else {
      target = current.roundToDouble();
    }
    _settleTo(target, velocity: pixelVelocity / _pageExtent);
  }

  void _precacheNeighbours(List<BhaktiDeity> deities, int index) {
    for (final offset in const [0, -1, 1, -2, 2]) {
      final d = deities[(index + offset) % deities.length];
      for (final asset in _DarshanPage.assetsFor(d)) {
        precacheImage(AssetImage(asset), context);
      }
    }
  }

  void _onCategoryTap(BhaktiDeity deity, BhaktiCategory category) {
    if (deity.key == 'Lord Ganesha') {
      if (category == BhaktiCategory.stotra) {
        showGaneshaStotraSheet(context: context);
        return;
      }
      if (category == BhaktiCategory.mantra) {
        showGaneshaMantraSheet(context: context);
        return;
      }
      if (category == BhaktiCategory.chalisa) {
        showGaneshaChalisaSheet(context: context);
        return;
      }
    }
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    void resetCarouselToFirst() {
      if (_page.isAnimating) _page.stop();
      _nearestPage = 0;
      _targetPage = 0;
      _page.value = 0;
      if (ref.read(selectedDeityIndexProvider) != 0) {
        ref.read(selectedDeityIndexProvider.notifier).state = 0;
      }
    }

    ref.listen(bhaktiCarouselResetTriggerProvider, (_, _) => resetCarouselToFirst());
    ref.listen(pinnedDeityKeyProvider, (_, _) => resetCarouselToFirst());

    final localeCode = ref.watch(localeProvider).languageCode;
    final deities = ref.watch(bhaktiDeitiesProvider);
    if (deities.isEmpty) {
      return const Scaffold(backgroundColor: Color(0xFF1A0805));
    }

    final index = ref.watch(selectedDeityIndexProvider) % deities.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _precacheNeighbours(deities, index);
    });

    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A0805),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final layout = _CarouselLayout(constraints.biggest, topPadding);
            _pageExtent = layout.size.width * 0.55;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: AnimatedBuilder(
                animation: _page,
                builder: (context, _) {
                  final page = _page.value;
                  final items = [
                    for (var i = page.floor() - 2; i <= page.ceil() + 2; i++)
                      if ((i - page).abs() < 2) (index: i, frame: layout.frameFor(i - page)),
                  ]..sort((a, b) {
                      final bySize = b.frame.area.compareTo(a.frame.area);
                      if (bySize != 0) return bySize;
                      return (b.index - page).abs().compareTo((a.index - page).abs());
                    });

                  final settled = 1 - ((page - page.roundToDouble()).abs() * 2);

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      for (final item in items)
                        _buildCarouselItem(
                          key: ValueKey(item.index),
                          deity: deities[item.index % deities.length],
                          frame: item.frame,
                          offset: item.index - page,
                          layout: layout,
                          localeCode: localeCode,
                        ),
                      Positioned(
                        left: layout.leftSlot.right + 6,
                        top: layout.focus.dy - 15,
                        child: _arrowButton(Icons.chevron_left_rounded, () => _go(-1), settled),
                      ),
                      Positioned(
                        left: layout.rightSlot.left - 36,
                        top: layout.focus.dy - 15,
                        child: _arrowButton(Icons.chevron_right_rounded, () => _go(1), settled),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// One darshan page seen through a window that morphs between full screen and a card slot.
  Widget _buildCarouselItem({
    required Key key,
    required BhaktiDeity deity,
    required _ItemFrame frame,
    required double offset,
    required _CarouselLayout layout,
    required String localeCode,
  }) {
    final cardness = frame.cardness;
    final isActive = cardness < 0.5;
    final rrect = RRect.fromRectAndRadius(frame.rect, Radius.circular(frame.radius));

    final transform = Matrix4.identity()
      ..translateByDouble(frame.rect.center.dx, frame.rect.center.dy, 0, 1)
      ..scaleByDouble(frame.scale, frame.scale, 1, 1)
      ..translateByDouble(-frame.focus.dx, -frame.focus.dy, 0, 1);

    final page = Transform(
      transform: transform,
      child: RepaintBoundary(
        child: _DarshanPage(
          deity: deity,
          categories: ref.read(deityCategoriesProvider(deity.key)),
          localeCode: localeCode,
          controlsOpacity: (1 - cardness * 2).clamp(0.0, 1.0),
          onCategoryTap: _onCategoryTap,
        ),
      ),
    );

    return Stack(
      key: key,
      fit: StackFit.expand,
      children: [
        if (cardness > 0)
          Positioned.fromRect(
            rect: frame.rect,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(frame.radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.7 * cardness),
                      blurRadius: 20,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: isActive ? null : () => _go(offset.sign.toInt()),
          child: ClipRRect(
            clipper: _RRectClipper(rrect),
            child: isActive ? page : AbsorbPointer(child: page),
          ),
        ),
        if (cardness > 0)
          Positioned.fromRect(
            rect: frame.rect,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(frame.radius),
                  border: Border.all(
                    color: _gold.withValues(alpha: cardness),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _arrowButton(IconData icon, VoidCallback onTap, double opacity) {
    return IgnorePointer(
      ignoring: opacity < 0.5,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xB31E0A04),
              border: Border.all(color: _gold),
            ),
            child: Icon(icon, size: 24, color: const Color(0xFFF3C46A)),
          ),
        ),
      ),
    );
  }
}

/// Screen geometry shared by every carousel item: the full-page rect, the two card slots,
/// and where the deity sits inside a page.
class _CarouselLayout {
  final Size size;
  late final Rect fullRect = Offset.zero & size;
  late final Offset focus;
  late final Rect leftSlot;
  late final Rect rightSlot;

  /// Page scale inside a card so the mandap arch fills it.
  late final double cardScale;
  late final double cardRadius;

  _CarouselLayout(this.size, double topPadding) {
    final width = size.width;
    final buttonSize = _DarshanPage.buttonSizeFor(width);
    final stageTop = topPadding + _DarshanPage.titleTopFor(width) + _DarshanPage.titleHeight;
    final stageBottom = size.height - _DarshanPage.bottomBlockFor(buttonSize);
    final frameWidth = ((stageBottom - stageTop) / 1.5).clamp(0.0, width * 0.8);

    focus = Offset(width / 2, (stageTop + stageBottom) / 2);

    final cardWidth = width * 0.26;
    final cardHeight = cardWidth * 1.3;
    final overhang = width * 0.1;
    leftSlot = Rect.fromLTWH(-overhang, focus.dy - cardHeight / 2, cardWidth, cardHeight);
    rightSlot = Rect.fromLTWH(width - cardWidth + overhang, focus.dy - cardHeight / 2, cardWidth, cardHeight);
    cardScale = frameWidth > 0 ? cardWidth / (frameWidth * 0.7) : 0.5;
    cardRadius = cardWidth * 0.12;
  }

  /// Window for an item [offset] pages from the current one.
  _ItemFrame frameFor(double offset) {
    final distance = offset.abs();
    final slot = offset < 0 ? leftSlot : rightSlot;

    if (distance <= 1) {
      // Pages shrink faster than they travel, so the outgoing and incoming windows no longer
      // overlap at mid-swipe, where their stacking order flips.
      final t = 1 - math.pow(1 - distance, 1.4).toDouble();
      return _ItemFrame(
        rect: Rect.lerp(fullRect, slot, t)!,
        focus: Offset.lerp(fullRect.center, focus, t)!,
        scale: lerpDouble(1, cardScale, t)!,
        radius: lerpDouble(0, cardRadius, t)!,
        cardness: t,
      );
    }

    final exit = (slot.width + size.width * 0.1) * (distance - 1) * offset.sign;
    return _ItemFrame(
      rect: slot.shift(Offset(exit, 0)),
      focus: focus,
      scale: cardScale,
      radius: cardRadius,
      cardness: 1,
    );
  }
}

class _ItemFrame {
  final Rect rect;

  /// Page point that is drawn at the centre of [rect].
  final Offset focus;
  final double scale;
  final double radius;

  /// 0 when the item is the full page, 1 when it is a side card.
  final double cardness;

  const _ItemFrame({
    required this.rect,
    required this.focus,
    required this.scale,
    required this.radius,
    required this.cardness,
  });

  double get area => rect.width * rect.height;
}

class _RRectClipper extends CustomClipper<RRect> {
  final RRect rrect;

  const _RRectClipper(this.rrect);

  @override
  RRect getClip(Size size) => rrect;

  @override
  bool shouldReclip(_RRectClipper oldClipper) => oldClipper.rrect != rrect;
}

/// One complete darshan screen for a single deity, laid out at full screen size.
class _DarshanPage extends StatelessWidget {
  static const _templeBg = 'assets/bhakti/temple_bg.png';
  static const _garland = 'assets/bhakti/garland_top.png';

  static const titleHeight = 40 * 1.25;
  static double titleTopFor(double width) => width * 0.07;
  static double buttonSizeFor(double width) => ((width - 24) / 5 - 10).clamp(52.0, 74.0);
  static double bottomBlockFor(double buttonSize) => 12 + buttonSize + 8 + 22;

  final BhaktiDeity deity;
  final List<BhaktiCategory> categories;
  final String localeCode;

  /// Visibility of the category buttons; only the full-screen page shows them.
  final double controlsOpacity;
  final void Function(BhaktiDeity deity, BhaktiCategory category) onCategoryTap;

  const _DarshanPage({
    required this.deity,
    required this.categories,
    required this.localeCode,
    required this.controlsOpacity,
    required this.onCategoryTap,
  });

  // TEMP: trying a single full-scene artwork for Shiva instead of temple bg + mandap + deity.
  static const _fullScenes = {
    'Lord Shiva': (asset: 'assets/bhakti/shiva_darshan_full.jpg', hasOwnTitle: true),
    'Goddess Lakshmi': (asset: 'assets/bhakti/lakshmi_darshan_full.png', hasOwnTitle: false),
    'Lord Hanuman': (asset: 'assets/bhakti/hanuman_darshan_full.jpg', hasOwnTitle: false),
    'Lord Siddhanath': (asset: 'assets/bhakti/siddhanath_darshan_full.jpg', hasOwnTitle: false),
    'Lord Ganesha': (asset: 'assets/bhakti/ganesh_darshan_full.jpg', hasOwnTitle: false),
    'Lord Rama': (asset: 'assets/bhakti/rama_darshan_full.jpg', hasOwnTitle: false),
    'Lord Vishnu': (asset: 'assets/bhakti/vishnu_darshan_full.jpg', hasOwnTitle: false),
  };

  /// Every image a page for [deity] draws, so neighbours can be decoded before they slide in.
  static List<String> assetsFor(BhaktiDeity deity) {
    final fullScene = _fullScenes[deity.key];
    if (fullScene != null) return [fullScene.asset];
    return [_templeBg, _garland, DarshanShrine.frameAsset, deity.imageAsset];
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final fullScene = _fullScenes[deity.key];

    if (fullScene != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(fullScene.asset, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00140603), Color(0xD9140603)],
                stops: [0.7, 0.95],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (!fullScene.hasOwnTitle) ...[
                  SizedBox(height: titleTopFor(width)),
                  _buildTitle(),
                ],
                const Spacer(),
                _buildCategoryRow(width),
                const SizedBox(height: 22),
              ],
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(_templeBg, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x8C140603),
                Color(0x00140603),
                Color(0x00140603),
                Color(0xD9140603),
              ],
              stops: [0.0, 0.22, 0.62, 0.92],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: -6,
          right: -6,
          child: IgnorePointer(
            child: Image.asset(_garland, fit: BoxFit.fitWidth),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              SizedBox(height: titleTopFor(width)),
              _buildTitle(),
              Expanded(child: _buildStage()),
              const SizedBox(height: 12),
              _buildCategoryRow(width),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: SizedBox(
        height: titleHeight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            deity.darshanTitle(localeCode),
            maxLines: 1,
            style: GoogleFonts.yatraOne(
              fontSize: 40,
              height: 1.25,
              color: const Color(0xFFFFF4D6),
              shadows: const [
                Shadow(color: Color(0xBFFFBE50), blurRadius: 18),
                Shadow(color: Color(0x99000000), blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final frameWidth = (height / 1.5).clamp(0.0, width * 0.8);

        return Center(
          child: DarshanShrine(
            deity: deity,
            width: frameWidth,
            direction: 1,
          ),
        );
      },
    );
  }

  Widget _buildCategoryRow(double width) {
    final size = buttonSizeFor(width);

    return SizedBox(
      height: size + 8,
      child: IgnorePointer(
        ignoring: controlsOpacity < 0.5,
        child: Opacity(
          opacity: controlsOpacity,
          child: Row(
            mainAxisAlignment: categories.length >= 4
                ? MainAxisAlignment.spaceEvenly
                : MainAxisAlignment.center,
            children: [
              for (final category in categories)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: categories.length >= 4 ? 0 : size * 0.2,
                  ),
                  child: BhaktiCategoryButton(
                    category: category,
                    localeCode: localeCode,
                    size: size,
                    onTap: () => onCategoryTap(deity, category),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/motion.dart';
import '../../../domain/entities/greeting_image.dart';
import '../../greeting/greeting_strings.dart';
import '../../providers/greeting_providers.dart';
import '../../providers/locale_provider.dart';
import '../../providers/remote_config_provider.dart';

const kGreetingPlaceholder = Color(0xFFF3E7D5);
const kGreetingTileRadius = 22.0;

/// Whether [image] must stay blurred for this user.
bool greetingLocked(
  GreetingImage image, {
  required bool premiumAccess,
  Set<int> unlockedIds = const {},
}) {
  if (premiumAccess) return false;
  if (!image.premium) return false;
  return !unlockedIds.contains(image.id);
}

/// Shrinks its child the instant a finger lands and restores it on release,
/// so taps get feedback before they commit.
class GreetingPressable extends StatefulWidget {
  const GreetingPressable({super.key, required this.onTap, required this.child, this.pressedScale = 0.97});

  final VoidCallback onTap;
  final Widget child;
  final double pressedScale;

  @override
  State<GreetingPressable> createState() => _GreetingPressableState();
}

class _GreetingPressableState extends State<GreetingPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed && !reduceMotion ? widget.pressedScale : 1.0,
        duration: AppMotion.press,
        curve: AppMotion.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed && reduceMotion ? 0.7 : 1.0,
          duration: AppMotion.press,
          curve: AppMotion.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Fades and lifts a grid item in once, [index] steps after the first.
/// Movement is dropped under reduced motion; the fade stays.
class GreetingEntrance extends StatefulWidget {
  const GreetingEntrance({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<GreetingEntrance> createState() => _GreetingEntranceState();
}

class _GreetingEntranceState extends State<GreetingEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final delay = AppMotion.stagger * widget.index;
    final total = delay + AppMotion.entrance;
    _controller = AnimationController(vsync: this, duration: total)..forward();
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(delay.inMicroseconds / total.inMicroseconds, 1, curve: AppMotion.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faded = FadeTransition(opacity: _progress, child: widget.child);
    if (MediaQuery.disableAnimationsOf(context)) return faded;
    return AnimatedBuilder(
      animation: _progress,
      child: faded,
      builder: (_, child) => Transform.translate(offset: Offset(0, 8 * (1 - _progress.value)), child: child),
    );
  }
}

/// Small frosted-glass capsule for overlays that sit on top of photos.
class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.circle = false, this.padding = EdgeInsets.zero});

  final Widget child;
  final bool circle;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final solid = MediaQuery.highContrastOf(context);
    final edge = BorderSide(color: Colors.white.withValues(alpha: 0.22), width: 0.5);
    final ShapeBorder shape = circle ? CircleBorder(side: edge) : StadiumBorder(side: edge);
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: solid ? 0 : 14, sigmaY: solid ? 0 : 14),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: Colors.black.withValues(alpha: solid ? 0.75 : 0.32),
            shape: shape,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Grid tile: thumbnail with premium badge, lock blur and favourite heart.
class GreetingTile extends ConsumerWidget {
  const GreetingTile({super.key, required this.image, required this.onTap});

  final GreetingImage image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = GreetingStrings(ref.watch(localeProvider).languageCode);
    final locked = greetingLocked(
      image,
      premiumAccess: ref.watch(premiumAccessProvider),
      unlockedIds: ref.watch(unlockedGreetingsProvider),
    );
    final isFavorite = ref.watch(greetingFavoritesProvider).any((i) => i.id == image.id);
    final thumb = CachedNetworkImage(
      imageUrl: image.thumbUrl,
      fit: BoxFit.cover,
      memCacheWidth: 520,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, _) => const ColoredBox(color: kGreetingPlaceholder),
      errorWidget: (_, _, _) => const ColoredBox(
        color: kGreetingPlaceholder,
        child: Icon(Icons.image_not_supported_outlined, color: Color(0xFFBDAB8E)),
      ),
    );
    return GreetingPressable(
      onTap: onTap,
      pressedScale: 0.97,
      child: AspectRatio(
        aspectRatio: image.aspectRatio.clamp(0.5, 1.25),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: const RoundedSuperellipseBorder(
              borderRadius: BorderRadius.all(Radius.circular(kGreetingTileRadius)),
            ),
            color: kGreetingPlaceholder,
            shadows: [
              BoxShadow(
                color: const Color(0xFF5D3A1A).withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF5D3A1A).withValues(alpha: 0.06),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRSuperellipse(
            borderRadius: const BorderRadius.all(Radius.circular(kGreetingTileRadius)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (locked)
                  ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9), child: thumb)
                else
                  thumb,
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0x33000000)],
                      ),
                    ),
                  ),
                ),
                if (locked)
                  const Center(
                    child: _Glass(
                      circle: true,
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.lock_rounded, color: Color(0xFFFFD54F), size: 24),
                    ),
                  ),
                if (image.premium)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _Glass(
                      padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFD54F)),
                          const SizedBox(width: 3),
                          Text(
                            s.premium,
                            style: GoogleFonts.mukta(
                              fontSize: 11.5,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!locked)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _Glass(
                      circle: true,
                      child: SizedBox.square(
                        dimension: 36,
                        child: IconButton(
                          key: Key('greeting-fav-${image.id}'),
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref.read(greetingFavoritesProvider.notifier).toggle(image);
                          },
                          icon: AnimatedSwitcher(
                            duration: AppMotion.press,
                            switchInCurve: AppMotion.easeOut,
                            switchOutCurve: AppMotion.easeOut,
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: MediaQuery.disableAnimationsOf(context)
                                  ? child
                                  : ScaleTransition(
                                      scale: Tween(begin: 0.9, end: 1.0).animate(anim),
                                      child: child,
                                    ),
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              key: ValueKey(isFavorite),
                              color: isFavorite ? const Color(0xFFFF453A) : Colors.white,
                            ),
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
    );
  }
}

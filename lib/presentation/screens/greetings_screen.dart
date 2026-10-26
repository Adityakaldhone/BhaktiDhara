import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/theme.dart';
import '../../domain/entities/greeting_image.dart';
import '../../services/backend_service.dart';
import '../greeting/greeting_strings.dart';
import '../providers/greeting_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/remote_config_provider.dart';
import '../widgets/greeting/greeting_tile.dart';
import 'greeting_viewer_screen.dart';

const _gutter = 16.0;
const _gridSpacing = 12.0;
const _chipSize = 68.0;
const _chipRadius = 20.0;
const _ringGap = 3.0;

/// Category chips on top, HD greeting images of the selected category below.
class GreetingsScreen extends ConsumerStatefulWidget {
  const GreetingsScreen({super.key});

  @override
  ConsumerState<GreetingsScreen> createState() => _GreetingsScreenState();
}

class _GreetingsScreenState extends ConsumerState<GreetingsScreen> {
  @override
  void initState() {
    super.initState();
    BackendService.trackEvent('greeting_open');
  }

  @override
  Widget build(BuildContext context) {
    final s = GreetingStrings(ref.watch(localeProvider).languageCode);
    final categoriesAsync = ref.watch(greetingCategoriesProvider);
    final selected = ref.watch(selectedGreetingCategoryProvider);

    final all = categoriesAsync.valueOrNull ?? const <GreetingCategory>[];
    final withImages = all.where((c) => c.count > 0).toList();
    final visible = withImages.isEmpty ? all : withImages;
    final effective = selected == kFavoritesCategory ||
            visible.isEmpty ||
            visible.any((c) => c.slug == selected)
        ? selected
        : visible.first.slug;

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: MandirTheme.backgroundCream,
        foregroundColor: MandirTheme.secondaryMaroon,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        title: Text(
          s.title,
          style: GoogleFonts.mukta(
            fontSize: 30,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: MandirTheme.textDark,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(_gutter, 4, _gutter, 10),
              child: Text(
                s.popularCategories,
                style: GoogleFonts.mukta(
                  fontSize: 19,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: MandirTheme.textDark,
                ),
              ),
            ),
            SizedBox(
              height: _chipSize + _ringGap * 2 + 30,
              child: categoriesAsync.isLoading && all.isEmpty
                  ? const _CategoryStripSkeleton()
                  : _CategoryStrip(categories: visible, selected: effective, s: s),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: effective == kFavoritesCategory
                  ? _FavoritesGrid(key: const ValueKey(kFavoritesCategory), s: s)
                  : _CategoryGrid(key: ValueKey(effective), category: effective, s: s),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryStrip extends ConsumerWidget {
  const _CategoryStrip({required this.categories, required this.selected, required this.s});

  final List<GreetingCategory> categories;
  final String selected;
  final GreetingStrings s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void select(String slug) {
      ref.read(selectedGreetingCategoryProvider.notifier).state = slug;
      BackendService.trackEvent('greeting_category', item: slug);
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: _gutter - _ringGap),
      itemCount: categories.length + 1,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        if (i == categories.length) {
          return _CategoryChip(
            key: const Key('greeting-category-favorites'),
            label: s.favorites,
            selected: selected == kFavoritesCategory,
            onTap: () => select(kFavoritesCategory),
            child: const ColoredBox(
              color: Color(0xFFFFE9E7),
              child: Center(child: Icon(Icons.favorite_rounded, color: Color(0xFFFF453A), size: 30)),
            ),
          );
        }
        final c = categories[i];
        return _CategoryChip(
          key: Key('greeting-category-${c.slug}'),
          label: c.name,
          selected: c.slug == selected,
          onTap: () => select(c.slug),
          child: c.coverUrl == null
              ? ColoredBox(
                  color: kGreetingPlaceholder,
                  child: Center(child: Text(c.emoji.isEmpty ? '🖼️' : c.emoji, style: const TextStyle(fontSize: 28))),
                )
              : CachedNetworkImage(
                  imageUrl: c.coverUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: 220,
                  placeholder: (_, _) => const ColoredBox(color: kGreetingPlaceholder),
                  errorWidget: (_, _, _) => ColoredBox(
                    color: kGreetingPlaceholder,
                    child: Center(child: Text(c.emoji, style: const TextStyle(fontSize: 28))),
                  ),
                ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  static const _ringRadius = _chipRadius + _ringGap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GreetingPressable(
        onTap: onTap,
        child: SizedBox(
          width: _chipSize + _ringGap * 2,
          child: Column(
            children: [
              AnimatedContainer(
                duration: AppMotion.state,
                curve: AppMotion.ease,
                padding: const EdgeInsets.all(_ringGap),
                decoration: ShapeDecoration(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(_ringRadius)),
                    side: BorderSide(
                      color: selected ? MandirTheme.primarySaffron : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: ClipRSuperellipse(
                  borderRadius: const BorderRadius.all(Radius.circular(_chipRadius)),
                  child: SizedBox.square(dimension: _chipSize, child: child),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: AppMotion.state,
                curve: AppMotion.ease,
                style: GoogleFonts.mukta(
                  fontSize: 13,
                  height: 1.2,
                  letterSpacing: 0.1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? MandirTheme.primarySaffron : MandirTheme.textMuted,
                ),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryStripSkeleton extends StatelessWidget {
  const _CategoryStripSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: _gutter - _ringGap),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, _) => SizedBox(
        width: _chipSize + _ringGap * 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(_ringGap),
              child: Container(
                width: _chipSize,
                height: _chipSize,
                decoration: const ShapeDecoration(
                  color: kGreetingPlaceholder,
                  shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(_chipRadius))),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 10,
              decoration: const ShapeDecoration(color: kGreetingPlaceholder, shape: StadiumBorder()),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid({super.key, required this.category, required this.s});

  final String category;
  final GreetingStrings s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(greetingFeedProvider(category));
    final notifier = ref.read(greetingFeedProvider(category).notifier);

    if (feed.loading) return const _GridSkeleton();
    if (feed.failed) {
      return _Message(
        icon: Icons.wifi_off_rounded,
        text: s.loadFailed,
        action: s.retry,
        onAction: () {
          ref.invalidate(greetingCategoriesProvider);
          notifier.refresh();
        },
      );
    }
    return _GreetingGrid(
      images: feed.images,
      loadingMore: feed.loadingMore,
      onLoadMore: feed.hasMore ? notifier.loadMore : null,
      onRefresh: () async {
        ref.invalidate(greetingCategoriesProvider);
        await notifier.refresh();
      },
      empty: _Message(icon: Icons.photo_library_outlined, text: s.emptyCategory),
    );
  }
}

class _FavoritesGrid extends ConsumerWidget {
  const _FavoritesGrid({super.key, required this.s});

  final GreetingStrings s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GreetingGrid(
      images: ref.watch(greetingFavoritesProvider),
      empty: _Message(icon: Icons.favorite_border_rounded, text: s.emptyFavorites),
    );
  }
}

class _GreetingGrid extends ConsumerStatefulWidget {
  const _GreetingGrid({
    required this.images,
    required this.empty,
    this.loadingMore = false,
    this.onLoadMore,
    this.onRefresh,
  });

  final List<GreetingImage> images;
  final Widget empty;
  final bool loadingMore;
  final VoidCallback? onLoadMore;
  final Future<void> Function()? onRefresh;

  @override
  ConsumerState<_GreetingGrid> createState() => _GreetingGridState();
}

class _GreetingGridState extends ConsumerState<_GreetingGrid> {
  static const _staggerCount = 6;
  static const _entranceWindow = Duration(milliseconds: 300);

  final _mountedAt = DateTime.now();

  bool get _entranceOpen => DateTime.now().difference(_mountedAt) < _entranceWindow;

  @override
  Widget build(BuildContext context) {
    final _GreetingGrid(:images, :empty, :loadingMore, :onLoadMore, :onRefresh) = widget;
    final premiumAccess = ref.watch(premiumAccessProvider);
    final unlockedIds = ref.watch(unlockedGreetingsProvider);

    void open(int index) {
      final image = images[index];
      if (greetingLocked(image, premiumAccess: premiumAccess, unlockedIds: unlockedIds)) {
        BackendService.trackEvent('paywall_view', item: 'greeting_image');
        AnalyticsService.logFunnelEvent(FunnelEvent.paywallView, parameters: {'source': 'greeting_image'});
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GreetingViewerScreen(images: images, initialIndex: index)),
      );
    }

    final scroll = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (images.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: empty)
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(_gutter, 8, _gutter, _gutter),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: _gridSpacing,
              crossAxisSpacing: _gridSpacing,
              childCount: images.length,
              itemBuilder: (_, i) {
                final tile = GreetingTile(key: ValueKey(images[i].id), image: images[i], onTap: () => open(i));
                if (i >= _staggerCount || !_entranceOpen) return tile;
                return GreetingEntrance(index: i, child: tile);
              },
            ),
          ),
        if (loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(_gutter),
              child: Center(
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(MandirTheme.textMuted),
                  ),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (onLoadMore != null && n.metrics.extentAfter < 900) onLoadMore();
        return false;
      },
      child: onRefresh == null
          ? scroll
          : RefreshIndicator(
              onRefresh: onRefresh,
              color: MandirTheme.primarySaffron,
              backgroundColor: Colors.white,
              child: scroll,
            ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    const ratios = [0.62, 0.78, 0.7, 0.58, 0.8, 0.66];
    return MasonryGridView.count(
      padding: const EdgeInsets.fromLTRB(_gutter, 8, _gutter, _gutter),
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: _gridSpacing,
      crossAxisSpacing: _gridSpacing,
      itemCount: ratios.length,
      itemBuilder: (_, i) => AspectRatio(
        aspectRatio: ratios[i],
        child: const DecoratedBox(
          decoration: ShapeDecoration(
            color: kGreetingPlaceholder,
            shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(kGreetingTileRadius))),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action, this.onAction});

  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: MandirTheme.chipBackground, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: MandirTheme.goldenAccent),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(
                fontSize: 16,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: MandirTheme.textMuted,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: MandirTheme.primarySaffron,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  elevation: 0,
                ),
                child: Text(action!, style: GoogleFonts.mukta(fontSize: 16, height: 1.2, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

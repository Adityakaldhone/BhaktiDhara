import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/greeting_image.dart';
import '../../services/backend_service.dart';
import '../greeting/greeting_strings.dart';
import '../providers/greeting_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/remote_config_provider.dart';
import '../widgets/greeting/greeting_tile.dart';
import 'greeting_viewer_screen.dart';

const _bandColors = [
  Color(0xFFE65100),
  Color(0xFF2E7D32),
  Color(0xFFD81B60),
  Color(0xFF7B1FA2),
  Color(0xFF1565C0),
  Color(0xFF00897B),
  Color(0xFF6D4C41),
];

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
        elevation: 0,
        title: Text(s.title, style: GoogleFonts.mukta(fontSize: 22, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                s.popularCategories,
                style: GoogleFonts.mukta(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: MandirTheme.textDark,
                ),
              ),
            ),
            SizedBox(
              height: 116,
              child: categoriesAsync.isLoading && all.isEmpty
                  ? const _CategoryStripSkeleton()
                  : _CategoryStrip(categories: visible, selected: effective, s: s),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: effective == kFavoritesCategory
                  ? _FavoritesGrid(s: s)
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length + 1,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, i) {
        if (i == categories.length) {
          return _CategoryChip(
            key: const Key('greeting-category-favorites'),
            label: s.favorites,
            color: const Color(0xFFC62828),
            selected: selected == kFavoritesCategory,
            onTap: () => select(kFavoritesCategory),
            child: const ColoredBox(
              color: Color(0xFFFFEBEE),
              child: Center(child: Icon(Icons.favorite_rounded, color: Color(0xFFE53935), size: 34)),
            ),
          );
        }
        final c = categories[i];
        return _CategoryChip(
          key: Key('greeting-category-${c.slug}'),
          label: c.name,
          color: _bandColors[i % _bandColors.length],
          selected: c.slug == selected,
          onTap: () => select(c.slug),
          child: c.coverUrl == null
              ? ColoredBox(
                  color: kGreetingPlaceholder,
                  child: Center(child: Text(c.emoji.isEmpty ? '🖼️' : c.emoji, style: const TextStyle(fontSize: 30))),
                )
              : CachedNetworkImage(
                  imageUrl: c.coverUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: 260,
                  placeholder: (_, _) => const ColoredBox(color: kGreetingPlaceholder),
                  errorWidget: (_, _, _) => ColoredBox(
                    color: kGreetingPlaceholder,
                    child: Center(child: Text(c.emoji, style: const TextStyle(fontSize: 30))),
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
    required this.color,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.0 : 0.94,
      duration: const Duration(milliseconds: 180),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 86,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFFD4AF37) : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: selected ? 0.35 : 0.12),
                blurRadius: selected ? 10 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13.5),
            child: Column(
              children: [
                Expanded(child: SizedBox(width: double.infinity, child: child)),
                Container(
                  width: double.infinity,
                  color: color,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mukta(
                      fontSize: 13.5,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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

class _CategoryStripSkeleton extends StatelessWidget {
  const _CategoryStripSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, _) => Container(
        width: 86,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(color: kGreetingPlaceholder, borderRadius: BorderRadius.circular(16)),
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
  const _FavoritesGrid({required this.s});

  final GreetingStrings s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GreetingGrid(
      images: ref.watch(greetingFavoritesProvider),
      empty: _Message(icon: Icons.favorite_border_rounded, text: s.emptyFavorites),
    );
  }
}

class _GreetingGrid extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumAccess = ref.watch(premiumAccessProvider);
    final unlockedIds = ref.watch(unlockedGreetingsProvider);

    void open(int index) {
      final image = images[index];
      if (greetingLocked(image, premiumAccess: premiumAccess, unlockedIds: unlockedIds)) {
        BackendService.trackEvent('paywall_view', item: 'greeting_image');
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
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childCount: images.length,
              itemBuilder: (_, i) => GreetingTile(
                key: ValueKey(images[i].id),
                image: images[i],
                onTap: () => open(i),
              ),
            ),
          ),
        if (loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (onLoadMore != null && n.metrics.extentAfter < 900) onLoadMore!();
        return false;
      },
      child: onRefresh == null ? scroll : RefreshIndicator(onRefresh: onRefresh!, child: scroll),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    const ratios = [0.62, 0.78, 0.7, 0.58, 0.8, 0.66];
    return MasonryGridView.count(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: ratios.length,
      itemBuilder: (_, i) => AspectRatio(
        aspectRatio: ratios[i],
        child: DecoratedBox(
          decoration: BoxDecoration(color: kGreetingPlaceholder, borderRadius: BorderRadius.circular(16)),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFFBDAB8E)),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(fontSize: 17, color: MandirTheme.textDark, height: 1.3),
            ),
            if (action != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(backgroundColor: MandirTheme.secondaryMaroon),
                child: Text(action!, style: GoogleFonts.mukta(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

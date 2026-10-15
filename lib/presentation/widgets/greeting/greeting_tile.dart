import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/greeting_image.dart';
import '../../greeting/greeting_strings.dart';
import '../../providers/greeting_providers.dart';
import '../../providers/locale_provider.dart';
import '../../providers/remote_config_provider.dart';

const kGreetingPlaceholder = Color(0xFFF3E7D5);

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

    return AspectRatio(
      aspectRatio: image.aspectRatio.clamp(0.5, 1.25),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A5A2B).withValues(alpha: 0.16),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (locked)
                ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7), child: thumb)
              else
                thumb,
              if (locked)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, color: Color(0xFFFFD54F), size: 26),
                  ),
                ),
              if (image.premium)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFFF8F00)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '⭐ ${s.premium}',
                      style: GoogleFonts.mukta(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(onTap: onTap),
                ),
              ),
              if (!locked)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: IconButton(
                    key: Key('greeting-fav-${image.id}'),
                    onPressed: () => ref.read(greetingFavoritesProvider.notifier).toggle(image),
                    icon: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFavorite ? const Color(0xFFE53935) : Colors.white,
                      shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
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

import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/greeting_image.dart';
import '../../services/greeting_image_composer.dart';
import '../../services/rewarded_ad_service.dart';
import '../greeting/greeting_share_flow.dart';
import '../greeting/greeting_strings.dart';
import '../providers/greeting_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/remote_config_provider.dart';
import '../widgets/greeting/greeting_tile.dart';
import '../widgets/premium_blurred_gate.dart';

const _whatsAppGreen = Color(0xFF1B7F3B);
const _viewerBackground = Color(0xFF1A1410);

/// Full-screen HD image, swipeable through [images], with the optional photo
/// circle and share / save / favourite actions.
class GreetingViewerScreen extends ConsumerStatefulWidget {
  const GreetingViewerScreen({super.key, required this.images, this.initialIndex = 0});

  final List<GreetingImage> images;
  final int initialIndex;

  @override
  ConsumerState<GreetingViewerScreen> createState() => _GreetingViewerScreenState();
}

class _GreetingViewerScreenState extends ConsumerState<GreetingViewerScreen> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.images[_index];
    return Scaffold(
      backgroundColor: _viewerBackground,
      appBar: AppBar(
        backgroundColor: _viewerBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${_index + 1} / ${widget.images.length}',
          style: GoogleFonts.mukta(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.images.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _ViewerPage(image: widget.images[i]),
              ),
            ),
            _ActionBar(image: image),
          ],
        ),
      ),
    );
  }
}

class _ViewerPage extends ConsumerWidget {
  const _ViewerPage({required this.image});

  final GreetingImage image;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = greetingLocked(
      image,
      premiumAccess: ref.watch(premiumAccessProvider),
      unlockedIds: ref.watch(unlockedGreetingsProvider),
    );
    final photoEnabled = ref.watch(greetingPhotoEnabledProvider);
    final thumb = CachedNetworkImage(
      imageUrl: image.thumbUrl,
      fit: BoxFit.cover,
      placeholder: (_, _) => const ColoredBox(color: Color(0xFF2A221C)),
      errorWidget: (_, _, _) => const ColoredBox(color: Color(0xFF2A221C)),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Center(
        child: AspectRatio(
          aspectRatio: image.aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                fit: StackFit.expand,
                children: [
                  if (locked) ...[
                    ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: thumb),
                    _LockedOverlay(),
                  ] else ...[
                    CachedNetworkImage(
                      imageUrl: image.hdUrl ?? image.thumbUrl,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 150),
                      placeholder: (_, _) => Stack(
                        fit: StackFit.expand,
                        children: [
                          thumb,
                          const Center(
                            child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2.5),
                          ),
                        ],
                      ),
                      errorWidget: (_, _, _) => thumb,
                    ),
                    if (photoEnabled) _PhotoCircle(box: box.biggest),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedOverlay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final s = GreetingStrings(lang);
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFF8F00), size: 40),
            const SizedBox(height: 8),
            Text(
              s.lockedTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF7A0C08)),
            ),
            const SizedBox(height: 4),
            Text(
              s.lockedBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(fontSize: 14, color: const Color(0xFF5D4A3A), height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

/// The user's photo in a circle at the bottom-left, placed with the same
/// [GreetingPhotoLayout] as the shared file. Shows an "add photo" hint until
/// the user picks one; the hint itself is never part of the shared image.
class _PhotoCircle extends ConsumerWidget {
  const _PhotoCircle({required this.box});

  final Size box;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = GreetingStrings(ref.watch(localeProvider).languageCode);
    final stamp = ref.watch(greetingPhotoProvider);
    final bytes = stamp == null ? null : ref.watch(greetingPhotoBytesProvider(stamp)).valueOrNull;
    final circle = GreetingPhotoLayout.circle(box);
    final ring = box.width * GreetingPhotoLayout.ring;

    return Positioned.fromRect(
      rect: circle.inflate(ring),
      child: GestureDetector(
        key: const Key('greeting-photo-circle'),
        onTap: () => bytes == null ? pickGreetingPhoto(context, ref) : _showPhotoOptions(context, ref, s),
        child: bytes != null
            ? DecoratedBox(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Padding(
                  padding: EdgeInsets.all(ring),
                  child: ClipOval(
                    child: Image.memory(bytes, key: ValueKey(stamp), fit: BoxFit.cover, gaplessPlayback: true),
                  ),
                ),
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
                ),
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 30),
                        Text(
                          s.addPhoto,
                          style: GoogleFonts.mukta(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  void _showPhotoOptions(BuildContext context, WidgetRef ref, GreetingStrings s) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFFFBF2),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.photoHint, textAlign: TextAlign.center, style: GoogleFonts.mukta(fontSize: 14.5)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: Text(s.changePhoto, style: GoogleFonts.mukta(fontSize: 17, fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(sheet);
                  pickGreetingPhoto(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC62828)),
                title: Text(
                  s.removePhoto,
                  style: GoogleFonts.mukta(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFFC62828)),
                ),
                onTap: () {
                  Navigator.pop(sheet);
                  ref.read(greetingPhotoProvider.notifier).remove();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.image});

  final GreetingImage image;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final s = GreetingStrings(lang);
    final locked = greetingLocked(
      image,
      premiumAccess: ref.watch(premiumAccessProvider),
      unlockedIds: ref.watch(unlockedGreetingsProvider),
    );
    final isFavorite = ref.watch(greetingFavoritesProvider).any((i) => i.id == image.id);
    final categories = ref.watch(greetingCategoriesProvider).valueOrNull ?? const [];
    final categoryName =
        categories.where((c) => c.slug == image.category).map((c) => c.name).firstOrNull ?? s.title;

    final buttonText = GoogleFonts.mukta(fontSize: 18, fontWeight: FontWeight.w800);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: locked
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    key: const Key('greeting-watch-ad-button'),
                    onPressed: () {
                      RewardedAdService.instance.show(
                        onRewarded: () async {
                          await ref.read(unlockedGreetingsProvider.notifier).unlock(image.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  lang == 'en'
                                      ? '🎉 This greeting is unlocked! You can now share & download it.'
                                      : (lang == 'hi'
                                          ? '🎉 यह शुभकामना अनलॉक हो गई है! अब आप इसे शेयर और सेव कर सकते हैं।'
                                          : '🎉 ही शुभेच्छा अनलॉक झाली आहे! आता तुम्ही शेअर व सेव्ह करू शकता.'),
                                  style: GoogleFonts.mukta(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: const Color(0xFF2E7D32),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        onAdNotReady: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                lang == 'en'
                                    ? 'Ad not ready yet. Please try again in a moment.'
                                    : (lang == 'hi'
                                        ? 'विज्ञापन अभी तैयार नहीं है। कृपया थोड़ी देर बाद प्रयास करें।'
                                        : 'जाहिरात अजून तयार नाही. कृपया थोड्या वेळाने प्रयत्न करा.'),
                                style: GoogleFonts.mukta(),
                              ),
                              backgroundColor: const Color(0xFF8B1D18),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1D18),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFFFD54F), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFFD54F), size: 24),
                    label: Text(
                      lang == 'en'
                          ? 'Watch Ad to Unlock This Card'
                          : (lang == 'hi'
                              ? 'विज्ञापन देखें — यह कार्ड अनलॉक करें'
                              : 'जाहिरात पहा — हे कार्ड अनलॉक करा'),
                      style: GoogleFonts.mukta(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  key: const Key('greeting-unlock-button'),
                  onPressed: () => showPremiumPaywallSheet(context, ref, lang),
                  icon: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD54F), size: 18),
                  label: Text(
                    lang == 'en'
                        ? 'Or get Ad-Free VIP Subscription →'
                        : (lang == 'hi'
                            ? 'या विज्ञापन-मुक्त VIP सदस्यता लें →'
                            : 'किंवा जाहिरात-मुक्त VIP सदस्य व्हा →'),
                    style: GoogleFonts.mukta(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFFD54F),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                _RoundAction(
                  key: const Key('greeting-favorite-button'),
                  icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorite ? const Color(0xFFE53935) : Colors.white,
                  label: s.favorite,
                  onTap: () => ref.read(greetingFavoritesProvider.notifier).toggle(image),
                ),
                const SizedBox(width: 10),
                _RoundAction(
                  key: const Key('greeting-save-button'),
                  icon: Icons.download_rounded,
                  color: Colors.white,
                  label: s.save,
                  onTap: () => saveGreetingImage(context, ref, image),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Builder(
                    builder: (buttonContext) => SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        key: const Key('greeting-share-button'),
                        onPressed: () {
                          final box = buttonContext.findRenderObject() as RenderBox?;
                          final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
                          shareGreetingImage(context, ref, image, categoryName: categoryName, origin: origin);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _whatsAppGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        icon: const Icon(Icons.share_rounded),
                        label: Text(s.share, style: buttonText),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 56, height: 56, child: Icon(icon, color: color, size: 26)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../data/datasources/bhakti_deity_catalog.dart';
import '../../domain/entities/aarti_item.dart';
import '../providers/aarti_favorites_provider.dart';
import '../providers/locale_provider.dart';

/// Daily Aarti (माझी नित्य आरती) quick-play strip on the Home Dashboard: one
/// slim row of chips so the sacred collection stays in view.
class NityaAartiShelf extends ConsumerWidget {
  final void Function(AartiItem item) onOpenAarti;

  const NityaAartiShelf({
    super.key,
    required this.onOpenAarti,
  });

  static String _t(String lang, {required String en, required String hi, required String mr}) =>
      lang == 'en' ? en : (lang == 'mr' ? mr : hi);

  void _remove(BuildContext context, WidgetRef ref, AartiItem aarti, String lang) {
    HapticFeedback.mediumImpact();
    final notifier = ref.read(aartiFavoritesProvider.notifier);
    notifier.toggle(aarti.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _t(lang,
                en: 'Removed from daily aartis',
                hi: 'नित्य आरती से हटाया',
                mr: 'नित्य आरतीतून काढले'),
          ),
          action: SnackBarAction(
            label: _t(lang, en: 'Undo', hi: 'वापस', mr: 'परत'),
            onPressed: () => notifier.pin(aarti.id),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nityaAartis = ref.watch(nityaAartisListProvider);
    if (nityaAartis.isEmpty) return const SizedBox.shrink();

    final lang = ref.watch(localeProvider).languageCode;

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: nityaAartis.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Center(
              child: Text(
                _t(lang, en: '🪔 Daily', hi: '🪔 नित्य', mr: '🪔 नित्य'),
                style: GoogleFonts.mukta(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: MandirTheme.secondaryMaroon,
                ),
              ),
            );
          }
          final aarti = nityaAartis[index - 1];
          return _NityaChip(
            aarti: aarti,
            title: _t(lang, en: aarti.title, hi: aarti.titleHi, mr: aarti.titleMr),
            onTap: () => onOpenAarti(aarti),
            onLongPress: () => _remove(context, ref, aarti, lang),
          );
        },
      ),
    );
  }
}

class _NityaChip extends StatelessWidget {
  final AartiItem aarti;
  final String title;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NityaChip({
    required this.aarti,
    required this.title,
    required this.onTap,
    required this.onLongPress,
  });

  String get _imageAsset {
    for (final deity in kBhaktiDeities) {
      if (deity.matches(aarti.deity)) return deity.imageAsset;
    }
    return MandirTheme.getDeityImageAsset(aarti.deity);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Material(
      color: MandirTheme.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: const Color(0xFFE2B04F).withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: MandirTheme.backgroundCream,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    _imageAsset,
                    fit: BoxFit.cover,
                    cacheWidth: 90,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        aarti.deityEmoji.isNotEmpty ? aarti.deityEmoji : '🪔',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.mukta(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MandirTheme.textDark,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.play_circle_fill_rounded,
                size: 20,
                color: MandirTheme.primarySaffron,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

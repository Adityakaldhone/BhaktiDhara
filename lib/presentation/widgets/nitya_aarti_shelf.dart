import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/aarti_item.dart';
import '../providers/aarti_favorites_provider.dart';
import '../providers/locale_provider.dart';

/// Dedicated Daily Aarti (माझी नित्य आरती) shelf displayed on the Home Dashboard.
class NityaAartiShelf extends ConsumerWidget {
  final void Function(AartiItem item) onOpenAarti;

  const NityaAartiShelf({
    super.key,
    required this.onOpenAarti,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nityaAartis = ref.watch(nityaAartisListProvider);
    if (nityaAartis.isEmpty) return const SizedBox.shrink();

    final langCode = ref.watch(localeProvider).languageCode;

    final title = langCode == 'hi'
        ? 'मेरी नित्य आरती'
        : (langCode == 'en' ? 'My Daily Aartis' : 'माझी नित्य आरती');
    final subtitle = langCode == 'hi'
        ? 'प्रतिदिन पूजा के लिए आपकी पसंदीदा आरतियां'
        : (langCode == 'en'
            ? 'Your pinned aartis for daily morning pooja'
            : 'दररोजच्या पूजेसाठी आपल्या आवडत्या आरत्या');

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: MandirTheme.primarySaffron.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🪔', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.mukta(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: MandirTheme.textDark,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.mukta(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: MandirTheme.textMuted,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: MandirTheme.primarySaffron.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: MandirTheme.primarySaffron.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    '${nityaAartis.length}',
                    style: GoogleFonts.mukta(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: MandirTheme.primarySaffron,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: nityaAartis.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final aarti = nityaAartis[index];
                final aartiTitle = langCode == 'hi'
                    ? aarti.titleHi
                    : (langCode == 'en' ? aarti.title : aarti.titleMr);
                final deityName = langCode == 'hi'
                    ? aarti.deityHi
                    : (langCode == 'en' ? aarti.deity : aarti.deityMr);

                return _NityaAartiCard(
                  aarti: aarti,
                  title: aartiTitle,
                  deityName: deityName,
                  onTap: () => onOpenAarti(aarti),
                  onRemove: () =>
                      ref.read(aartiFavoritesProvider.notifier).toggle(aarti.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NityaAartiCard extends StatelessWidget {
  final AartiItem aarti;
  final String title;
  final String deityName;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _NityaAartiCard({
    required this.aarti,
    required this.title,
    required this.deityName,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2B04F).withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Deity Icon / Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: MandirTheme.backgroundCream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: MandirTheme.cardBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      aarti.deityEmoji.isNotEmpty ? aarti.deityEmoji : '🪔',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Titles + Play Action
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mukta(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: MandirTheme.textDark,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        deityName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mukta(
                          fontSize: 12,
                          color: MandirTheme.primarySaffron,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.play_circle_fill_rounded,
                            size: 16,
                            color: MandirTheme.primarySaffron,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            aarti.durationText,
                            style: GoogleFonts.mukta(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: MandirTheme.textMuted,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: onRemove,
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.all(2.0),
                              child: Icon(
                                Icons.favorite_rounded,
                                size: 16,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

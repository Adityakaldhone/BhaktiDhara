import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme.dart';
import '../../../data/datasources/bhajan_catalog.dart';
import '../../../domain/entities/aarti_item.dart';
import '../../providers/locale_provider.dart';
import '../../providers/review_provider.dart';
import '../../screens/altar_screen.dart';

/// The exact 13 sacred Ganesha Mantras requested by the user.
final List<AartiItem> kGaneshaMantras = [
  kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_vakratunda'),
  kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_shubh_labh'),
  kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_gayatri'),
  kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_maha_moola'),
  kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_rinharta'),
  kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_haridra'),
  kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_heramba'),
  kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_ekakshari'),
  kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_shadakshara'),
  kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_ashtakshara'),
  kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_kshipra_prasada'),
  kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganapati_mantraksharavali'),
  kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_moolamantra_padamala'),
];

/// Opens the sacred Mantra list bottom sheet for Lord Ganesha.
Future<void> showGaneshaMantraSheet({required BuildContext context}) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (ctx) => const GaneshaMantraSheet(),
  );
}

/// Bottom sheet displaying strictly the 13 sacred Mantras for Lord Ganesha.
class GaneshaMantraSheet extends ConsumerWidget {
  const GaneshaMantraSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(localeProvider).languageCode;
    final maxH = MediaQuery.sizeOf(context).height * 0.80;

    final sheetTitle = localeCode == 'mr'
        ? 'श्री गणेश मंत्र संग्रह'
        : (localeCode == 'hi'
            ? 'श्री गणेश मंत्र संग्रह'
            : 'Shri Ganesh Mantras');

    final sheetSubtitle = localeCode == 'mr'
        ? '१३ सिद्ध मंत्र संग्रह'
        : (localeCode == 'hi' ? '१३ सिद्ध मंत्र संग्रह' : '13 Sacred Mantras');

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: Color(0xFFFBF6ED),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top Drag Handle ─────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFC4A882).withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Sacred Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Ganesha Golden Ring Icon
                Container(
                  width: 50,
                  height: 50,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE2B04F), Color(0xFFB8860B)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE2B04F).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Container(
                      color: const Color(0xFF38150C),
                      child: Image.asset(
                        'assets/bhakti/ganesh.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.temple_hindu_rounded,
                          color: Color(0xFFE2B04F),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title & Count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sheetTitle,
                        style: GoogleFonts.mukta(
                          fontSize: 20.5,
                          fontWeight: FontWeight.w700,
                          color: MandirTheme.textDark,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sheetSubtitle,
                        style: GoogleFonts.mukta(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: MandirTheme.primarySaffron,
                        ),
                      ),
                    ],
                  ),
                ),

                // Close Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEADBCE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF5D2E14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE6D6C2)),

          // ── The 2 Sacred Mantras List ───────────────────────────────────
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              itemCount: kGaneshaMantras.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final mantra = kGaneshaMantras[index];
                return _buildMantraCard(
                  context: context,
                  ref: ref,
                  item: mantra,
                  index: index,
                  localeCode: localeCode,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMantraCard({
    required BuildContext context,
    required WidgetRef ref,
    required AartiItem item,
    required int index,
    required String localeCode,
  }) {
    final titlePrimary = item.localizedTitle(localeCode);
    final titleSecondary = localeCode == 'en' ? item.titleMr : item.title;

    // First verse snippet preview
    String firstVerseSnippet = '';
    if (item.lyrics.isNotEmpty) {
      final raw = item.lyrics.first.devanagari.trim();
      final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.isNotEmpty) {
        if ((lines.first.contains('वाच') || lines.first.contains('ऊचुः')) && lines.length > 1) {
          firstVerseSnippet = lines[1];
        } else {
          firstVerseSnippet = lines.first;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: MandirTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MandirTheme.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A5A2B).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            ref.read(reviewServiceProvider).trackAartiCompleted();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AartiAltarScreen(aarti: item)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Mantra Number Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1D0),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: MandirTheme.goldenAccent.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.mukta(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B1D18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // 2. Title & Verse Snippet
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titlePrimary,
                        style: GoogleFonts.mukta(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w700,
                          color: MandirTheme.textDark,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (titleSecondary.isNotEmpty && titleSecondary != titlePrimary)
                        Text(
                          titleSecondary,
                          style: GoogleFonts.mukta(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: MandirTheme.textMuted,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (firstVerseSnippet.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          firstVerseSnippet,
                          style: GoogleFonts.notoSansDevanagari(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF7A6B5D),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE8D6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 13,
                                  color: Color(0xFFD9480F),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.durationText.isNotEmpty
                                      ? item.durationText
                                      : 'व्हिडिओ उपलब्ध',
                                  style: GoogleFonts.mukta(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFD9480F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  सिद्ध जप',
                            style: GoogleFonts.mukta(
                              fontSize: 11.5,
                              color: MandirTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // 3. Play Icon / Arrow
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: MandirTheme.primarySaffron.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 22,
                      color: MandirTheme.primarySaffron,
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

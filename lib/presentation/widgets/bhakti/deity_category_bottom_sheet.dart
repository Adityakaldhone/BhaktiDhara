import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme.dart';
import '../../../data/datasources/balumama_songs_catalog.dart';
import '../../../data/datasources/datta_songs_catalog.dart';
import '../../../data/datasources/durga_songs_catalog.dart';
import '../../../data/datasources/gayatri_songs_catalog.dart';
import '../../../data/datasources/krishna_songs_catalog.dart';
import '../../../data/datasources/shiva_songs_catalog.dart';
import '../../../domain/entities/aarti_item.dart';
import '../../../domain/entities/bhakti_deity.dart';
import '../../../domain/entities/devotional_song_item.dart';
import '../../providers/locale_provider.dart';
import '../../providers/review_provider.dart';
import '../../screens/altar_screen.dart';
import '../../screens/deity_video_watch_screen.dart';

/// Single item in a deity category selection bottom sheet.
class DeitySheetItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? firstVerse;
  final String? durationText;
  final AartiItem? aartiItem;
  final DevotionalSongItem? songItem;
  final List<DevotionalSongItem>? allSongs;

  const DeitySheetItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.firstVerse,
    this.durationText,
    this.aartiItem,
    this.songItem,
    this.allSongs,
  });

  factory DeitySheetItem.fromAarti(AartiItem item, String localeCode) {
    String firstVerse = '';
    if (item.lyrics.isNotEmpty) {
      final raw = item.lyrics.first.devanagari.trim();
      final lines = raw
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.isNotEmpty) {
        if ((lines.first.contains('वाच') || lines.first.contains('ऊचुः')) &&
            lines.length > 1) {
          firstVerse = lines[1];
        } else {
          firstVerse = lines.first;
        }
      }
    }
    return DeitySheetItem(
      id: item.id,
      title: item.localizedTitle(localeCode),
      subtitle: localeCode == 'en' ? item.titleMr : (item.singer.isNotEmpty ? item.singer : item.title),
      firstVerse: firstVerse.isNotEmpty ? firstVerse : null,
      durationText: item.durationText,
      aartiItem: item,
    );
  }

  factory DeitySheetItem.fromSong(
    DevotionalSongItem item,
    List<DevotionalSongItem> allSongs,
  ) {
    return DeitySheetItem(
      id: item.id,
      title: item.song,
      subtitle: item.artist.isNotEmpty ? item.artist : item.channel,
      durationText: item.durationText,
      songItem: item,
      allSongs: allSongs,
    );
  }
}

/// Helper to build items for any deity and category.
List<DeitySheetItem> buildItemsForDeityCategory({
  required BhaktiDeity deity,
  required BhaktiCategory category,
  required List<AartiItem> aartiItems,
  required String localeCode,
}) {
  final items = <DeitySheetItem>[];
  final seenIds = <String>{};

  // 1. Check for specific datasets of today's deities
  if (deity.key == 'Lord Shiva' || deity.key == 'Shiva' || deity.key == 'Mahadev') {
    if (category == BhaktiCategory.stotra) {
      // Text stotras
      for (final a in aartiItems.where((i) => i.tags.any((t) => t.toLowerCase().contains('stotra')))) {
        if (seenIds.add(a.id)) items.add(DeitySheetItem.fromAarti(a, localeCode));
      }
      // YouTube stotras
      for (final s in kShivaSongsCatalog.where((i) => i.category == 'Stotram & Ashtakam')) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kShivaSongsCatalog));
      }
    } else if (category == BhaktiCategory.mantra) {
      for (final a in aartiItems.where((i) => i.tags.any((t) => t.toLowerCase().contains('mantra')))) {
        if (seenIds.add(a.id)) items.add(DeitySheetItem.fromAarti(a, localeCode));
      }
      for (final s in kShivaSongsCatalog.where((i) => i.category == 'Mantra & Dhun')) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kShivaSongsCatalog));
      }
    } else if (category == BhaktiCategory.aarti) {
      for (final a in aartiItems.where((i) => i.tags.any((t) => t.toLowerCase().contains('aarti')))) {
        if (seenIds.add(a.id)) items.add(DeitySheetItem.fromAarti(a, localeCode));
      }
      for (final s in kShivaSongsCatalog.where((i) => i.category == 'Aarti & Chalisa' && i.song.toLowerCase().contains('aarti'))) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kShivaSongsCatalog));
      }
    } else if (category == BhaktiCategory.chalisa) {
      for (final a in aartiItems.where((i) => i.tags.any((t) => t.toLowerCase().contains('chalisa')))) {
        if (seenIds.add(a.id)) items.add(DeitySheetItem.fromAarti(a, localeCode));
      }
      for (final s in kShivaSongsCatalog.where((i) => i.song.toLowerCase().contains('chalisa'))) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kShivaSongsCatalog));
      }
    }
  } else if (deity.key == 'Goddess Durga' || deity.key == 'Durga' || deity.key == 'Durga Mata' || deity.key == 'Maa Durga') {
    if (category == BhaktiCategory.stotra) {
      for (final s in kDurgaSongsCatalog.where((i) => i.category == 'Stotram & Kavach')) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kDurgaSongsCatalog));
      }
    } else if (category == BhaktiCategory.mantra) {
      for (final s in kDurgaSongsCatalog.where((i) => i.category == 'Mantra & Chalisa' && !i.song.toLowerCase().contains('chalisa'))) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kDurgaSongsCatalog));
      }
    } else if (category == BhaktiCategory.chalisa) {
      for (final a in aartiItems.where((i) => i.tags.any((t) => t.toLowerCase().contains('chalisa')))) {
        if (seenIds.add(a.id)) items.add(DeitySheetItem.fromAarti(a, localeCode));
      }
      for (final s in kDurgaSongsCatalog.where((i) => i.song.toLowerCase().contains('chalisa'))) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kDurgaSongsCatalog));
      }
    } else if (category == BhaktiCategory.aarti) {
      for (final a in aartiItems.where((i) => i.tags.any((t) => t.toLowerCase().contains('aarti')))) {
        if (seenIds.add(a.id)) items.add(DeitySheetItem.fromAarti(a, localeCode));
      }
      for (final s in kDurgaSongsCatalog.where((i) => i.song.toLowerCase().contains('aarti'))) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kDurgaSongsCatalog));
      }
    }
  } else if (deity.key == 'Goddess Gayatri' || deity.key == 'Gayatri' || deity.key == 'Gayatri Mata') {
    if (category == BhaktiCategory.mantra) {
      for (final a in aartiItems.where((i) => i.tags.any((t) => t.toLowerCase().contains('mantra')))) {
        if (seenIds.add(a.id)) items.add(DeitySheetItem.fromAarti(a, localeCode));
      }
      for (final s in kGayatriSongsCatalog.where((i) => i.category == 'Gayatri Mantra & Jaap')) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kGayatriSongsCatalog));
      }
    } else if (category == BhaktiCategory.stotra) {
      for (final s in kGayatriSongsCatalog.where((i) => i.category == 'Stotram & Kavacham')) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kGayatriSongsCatalog));
      }
    } else if (category == BhaktiCategory.chalisa) {
      for (final s in kGayatriSongsCatalog.where((i) => i.song.toLowerCase().contains('chalisa'))) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kGayatriSongsCatalog));
      }
    } else if (category == BhaktiCategory.aarti) {
      for (final s in kGayatriSongsCatalog.where((i) => i.category == 'Aarti & Chalisa' && i.song.toLowerCase().contains('aarti'))) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kGayatriSongsCatalog));
      }
    }
  } else if (deity.key == 'Sant Balumama' || deity.key == 'Balumama' || deity.key == 'Sadguru Balumama') {
    if (category == BhaktiCategory.aarti) {
      for (final a in aartiItems.where((i) => i.tags.any((t) => t.toLowerCase().contains('aarti')))) {
        if (seenIds.add(a.id)) items.add(DeitySheetItem.fromAarti(a, localeCode));
      }
      for (final s in kBalumamaSongsCatalog.where((i) => i.category == 'Aarti & Gajar')) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kBalumamaSongsCatalog));
      }
    } else if (category == BhaktiCategory.mantra) {
      for (final s in kBalumamaSongsCatalog.where((i) => i.category == 'Mantra & Jap')) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kBalumamaSongsCatalog));
      }
    }
  } else if (deity.key == 'Lord Datta' || deity.key == 'Datta' || deity.key == 'Shri Datta' || deity.key == 'Dattatreya' || deity.key == 'Shri Dattatreya') {
    if (category == BhaktiCategory.stotra) {
      for (final a in aartiItems.where((i) => i.tags.any((t) => t.toLowerCase().contains('stotra')))) {
        if (seenIds.add(a.id)) items.add(DeitySheetItem.fromAarti(a, localeCode));
      }
      for (final s in kDattaSongsCatalog.where((i) => i.category == 'Stotra & Kavach')) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kDattaSongsCatalog));
      }
    } else if (category == BhaktiCategory.mantra) {
      for (final a in aartiItems.where((i) => i.tags.any((t) => t.toLowerCase().contains('mantra')))) {
        if (seenIds.add(a.id)) items.add(DeitySheetItem.fromAarti(a, localeCode));
      }
      for (final s in kDattaSongsCatalog.where((i) => i.category == 'Mantra & Jap')) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kDattaSongsCatalog));
      }
    } else if (category == BhaktiCategory.chalisa) {
      for (final s in kDattaSongsCatalog.where((i) => i.category == 'Chalisa')) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kDattaSongsCatalog));
      }
    } else if (category == BhaktiCategory.aarti) {
      for (final a in aartiItems.where((i) => i.tags.any((t) => t.toLowerCase().contains('aarti')))) {
        if (seenIds.add(a.id)) items.add(DeitySheetItem.fromAarti(a, localeCode));
      }
      for (final s in kDattaSongsCatalog.where((i) => i.category == 'Aarti & Pradakshina')) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kDattaSongsCatalog));
      }
    }
  } else if (deity.key == 'Lord Krishna' || deity.key == 'Krishna' || deity.key == 'Shri Krishna') {
    if (category == BhaktiCategory.aarti) {
      for (final a in aartiItems.where((i) => i.tags.any((t) => t.toLowerCase().contains('aarti')))) {
        if (seenIds.add(a.id)) items.add(DeitySheetItem.fromAarti(a, localeCode));
      }
      for (final s in kKrishnaSongsCatalog.where((i) => i.category == 'Aarti & Kirtan')) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kKrishnaSongsCatalog));
      }
    } else if (category == BhaktiCategory.chalisa) {
      for (final a in aartiItems.where((i) => i.tags.any((t) => t.toLowerCase().contains('chalisa')))) {
        if (seenIds.add(a.id)) items.add(DeitySheetItem.fromAarti(a, localeCode));
      }
      for (final s in kKrishnaSongsCatalog.where((i) => i.song.toLowerCase().contains('chalisa'))) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kKrishnaSongsCatalog));
      }
    } else if (category == BhaktiCategory.mantra) {
      for (final a in aartiItems.where((i) => i.tags.any((t) => t.toLowerCase().contains('mantra')))) {
        if (seenIds.add(a.id)) items.add(DeitySheetItem.fromAarti(a, localeCode));
      }
      for (final s in kKrishnaSongsCatalog.where((i) => i.category == 'Radha Krishna & Dhun')) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kKrishnaSongsCatalog));
      }
    } else if (category == BhaktiCategory.stotra) {
      for (final a in aartiItems.where((i) => i.tags.any((t) => t.toLowerCase().contains('stotra') || t.toLowerCase().contains('ashtakam')))) {
        if (seenIds.add(a.id)) items.add(DeitySheetItem.fromAarti(a, localeCode));
      }
      for (final s in kKrishnaSongsCatalog.where((i) =>
          i.song.toLowerCase().contains('achyutam') ||
          i.song.toLowerCase().contains('stotra') ||
          i.song.toLowerCase().contains('ashtak'))) {
        if (seenIds.add(s.id)) items.add(DeitySheetItem.fromSong(s, kKrishnaSongsCatalog));
      }
    }
  } else {
    // General fallback for all other deities (Rama, Vitthal, Swami Samarth, etc.)
    final tagKey = category.name.toLowerCase();
    for (final a in aartiItems.where((i) => i.tags.any((t) => t.toLowerCase().contains(tagKey)))) {
      if (seenIds.add(a.id)) items.add(DeitySheetItem.fromAarti(a, localeCode));
    }
  }

  // If still empty, include all aartiItems as fallback
  if (items.isEmpty && aartiItems.isNotEmpty) {
    for (final a in aartiItems) {
      if (seenIds.add(a.id)) items.add(DeitySheetItem.fromAarti(a, localeCode));
    }
  }

  return items;
}

/// Opens the unified category selection bottom sheet for any deity.
Future<void> showDeityCategorySheet({
  required BuildContext context,
  required BhaktiDeity deity,
  required BhaktiCategory category,
  required List<DeitySheetItem> items,
  String? customTitle,
  String? customSubtitle,
}) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (ctx) => DeityCategoryBottomSheet(
      deity: deity,
      category: category,
      items: items,
      customTitle: customTitle,
      customSubtitle: customSubtitle,
    ),
  );
}

/// Bottom sheet displaying the list of sacred items for a deity's category.
class DeityCategoryBottomSheet extends ConsumerStatefulWidget {
  final BhaktiDeity deity;
  final BhaktiCategory category;
  final List<DeitySheetItem> items;
  final String? customTitle;
  final String? customSubtitle;

  const DeityCategoryBottomSheet({
    super.key,
    required this.deity,
    required this.category,
    required this.items,
    this.customTitle,
    this.customSubtitle,
  });

  @override
  ConsumerState<DeityCategoryBottomSheet> createState() =>
      _DeityCategoryBottomSheetState();
}

class _DeityCategoryBottomSheetState
    extends ConsumerState<DeityCategoryBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = ref.watch(localeProvider).languageCode;
    final maxH = MediaQuery.sizeOf(context).height * 0.82;

    // Filter items by search query if user enters text
    final filtered = widget.items.where((it) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return it.title.toLowerCase().contains(q) ||
          (it.subtitle?.toLowerCase().contains(q) ?? false) ||
          (it.firstVerse?.toLowerCase().contains(q) ?? false);
    }).toList();

    // Localized Title
    final String sheetTitle;
    if (widget.customTitle != null) {
      sheetTitle = widget.customTitle!;
    } else {
      final name = localeCode == 'mr'
          ? widget.deity.nameMr
          : (localeCode == 'hi' ? widget.deity.nameHi : widget.deity.nameEn);
      switch (widget.category) {
        case BhaktiCategory.stotra:
          sheetTitle = localeCode == 'en'
              ? '$name Stotras'
              : 'श्री $name स्तोत्र संग्रह';
          break;
        case BhaktiCategory.mantra:
          sheetTitle = localeCode == 'en'
              ? '$name Mantras'
              : 'श्री $name मंत्र संग्रह';
          break;
        case BhaktiCategory.aarti:
          sheetTitle = localeCode == 'en'
              ? '$name Aartis'
              : 'श्री $name आरती संग्रह';
          break;
        case BhaktiCategory.chalisa:
          sheetTitle = localeCode == 'en'
              ? '$name Chalisas'
              : 'श्री $name चालीसा संग्रह';
          break;
        case BhaktiCategory.song:
          sheetTitle = localeCode == 'en'
              ? '$name Songs'
              : 'श्री $name गाणी संग्रह';
          break;
        case BhaktiCategory.bhajan:
          sheetTitle = localeCode == 'en'
              ? '$name Bhajans'
              : 'श्री $name भजन संग्रह';
          break;
      }
    }

    // Localized Subtitle
    final String sheetSubtitle;
    if (widget.customSubtitle != null) {
      sheetSubtitle = widget.customSubtitle!;
    } else {
      final count = widget.items.length;
      switch (widget.category) {
        case BhaktiCategory.stotra:
          sheetSubtitle = localeCode == 'mr'
              ? '$count पावन स्तोत्रे'
              : (localeCode == 'hi' ? '$count पावन स्तोत्र' : '$count Sacred Stotras');
          break;
        case BhaktiCategory.mantra:
          sheetSubtitle = localeCode == 'mr'
              ? '$count सिद्ध मंत्र'
              : (localeCode == 'hi' ? '$count सिद्ध मंत्र' : '$count Sacred Mantras');
          break;
        case BhaktiCategory.aarti:
          sheetSubtitle = localeCode == 'mr'
              ? '$count पावन आरत्या'
              : (localeCode == 'hi' ? '$count पावन आरतियां' : '$count Sacred Aartis');
          break;
        case BhaktiCategory.chalisa:
          sheetSubtitle = localeCode == 'mr'
              ? '$count पावन चालीसा'
              : (localeCode == 'hi' ? '$count पावन चालीसा' : '$count Sacred Chalisas');
          break;
        case BhaktiCategory.song:
          sheetSubtitle = localeCode == 'mr'
              ? '$count पावन गाणी'
              : (localeCode == 'hi' ? '$count पावन भजन' : '$count Sacred Songs');
          break;
        case BhaktiCategory.bhajan:
          sheetSubtitle = localeCode == 'mr'
              ? '$count पावन भजने'
              : (localeCode == 'hi' ? '$count पावन भजन' : '$count Sacred Bhajans');
          break;
      }
    }

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
                // Deity Circular Ring Avatar
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
                        widget.deity.imageAsset,
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
                          fontSize: 20,
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

          // ── Search Bar (shown when there are > 5 items) ──────────────────
          if (widget.items.length > 5) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5D5C0)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.mukta(
                    fontSize: 14.5,
                    color: MandirTheme.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: localeCode == 'mr'
                        ? 'शोधा...'
                        : (localeCode == 'hi' ? 'खोजें...' : 'Search...'),
                    hintStyle: GoogleFonts.mukta(
                      fontSize: 14,
                      color: const Color(0xFF9E8B76),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: Color(0xFF9E8B76),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE6D6C2)),

          // ── Items List ──────────────────────────────────────────────────
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 40,
                          color: Color(0xFFBCA68E),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localeCode == 'mr'
                              ? 'कोणतेही परिणाम सापडले नाहीत'
                              : (localeCode == 'hi'
                                  ? 'कोई परिणाम नहीं मिला'
                                  : 'No results found'),
                          style: GoogleFonts.mukta(
                            fontSize: 15,
                            color: const Color(0xFF8A5A2B),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final item = filtered[index];
                      return _buildItemCard(
                        context: context,
                        ref: ref,
                        item: item,
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

  Widget _buildItemCard({
    required BuildContext context,
    required WidgetRef ref,
    required DeitySheetItem item,
    required int index,
    required String localeCode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: MandirTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ref.read(reviewServiceProvider).trackAartiCompleted();

            if (item.aartiItem != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AartiAltarScreen(aarti: item.aartiItem!),
                ),
              );
            } else if (item.songItem != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeityVideoWatchScreen(
                    initialSong: item.songItem!,
                    allSongs: item.allSongs ?? [item.songItem!],
                    deityTitle: widget.deity.nameEn,
                    blessingMessage: '',
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Index Badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFBEAD8),
                    border: Border.all(
                      color: const Color(0xFFE2B04F).withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.cinzel(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B2500),
                    ),
                  ),
                ),
                const SizedBox(width: 13),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.mukta(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: MandirTheme.textDark,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.firstVerse != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.firstVerse!,
                          style: GoogleFonts.mukta(
                            fontSize: 13,
                            color: const Color(0xFF6B4226),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle!,
                          style: GoogleFonts.mukta(
                            fontSize: 12.5,
                            color: const Color(0xFF8A5A2B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Trailing Action Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E6D3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.songItem != null
                            ? Icons.play_arrow_rounded
                            : Icons.temple_hindu_rounded,
                        size: 16,
                        color: const Color(0xFFD84315),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        item.durationText ?? (localeCode == 'en' ? 'Open' : 'उघडा'),
                        style: GoogleFonts.mukta(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8B2500),
                        ),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/motion.dart';
import '../../../domain/entities/aarti_item.dart';
import '../../../domain/entities/bhakti_deity.dart';
import '../../../domain/logic/ishta_devta.dart';
import '../../../presentation/providers/aarti_providers.dart';
import '../../../presentation/providers/akhand_diya_provider.dart';
import '../../../presentation/providers/locale_provider.dart';
import '../../../presentation/widgets/request_deity_sheet.dart';
import 'mandir_painters.dart';

String _t(String lang, {required String en, required String hi, required String mr}) => switch (lang) {
  'hi' => hi,
  'mr' => mr,
  _ => en,
};

/// Lets the devotee seat a different Ishta Devta in the Garbhagriha.
/// Resolves to the chosen deity and its main aarti, or null if dismissed.
Future<(BhaktiDeity, AartiItem)?> showMandirDeityPicker(BuildContext context) {
  return showModalBottomSheet<(BhaktiDeity, AartiItem)>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x99000000),
    builder: (_) => const _DeityPickerSheet(),
  );
}

class _DeityPickerSheet extends ConsumerStatefulWidget {
  const _DeityPickerSheet();

  @override
  ConsumerState<_DeityPickerSheet> createState() => _DeityPickerSheetState();
}

class _DeityPickerSheetState extends ConsumerState<_DeityPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(BhaktiDeity deity, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    if (deity.key.toLowerCase().contains(q)) return true;
    if (deity.nameHi.toLowerCase().contains(q)) return true;
    if (deity.nameMr.toLowerCase().contains(q)) return true;
    if (deity.nameEn.toLowerCase().contains(q)) return true;
    for (final alias in deity.aliases) {
      if (alias.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final current = ref.watch(jyotDeityProvider);
    final catalog = ref.watch(aartiCatalogProvider).valueOrNull;
    final allOptions = <(BhaktiDeity, AartiItem)>[
      for (final deity in ishtaDeities())
        (deity, safeMainAartiFor(deity, catalog ?? const [])),
    ];
    final currentIndex = allOptions.indexWhere((o) => o.$1.key == current.key);
    if (currentIndex > 0) allOptions.insert(0, allOptions.removeAt(currentIndex));

    final cleanQuery = _searchQuery.trim();
    final options = cleanQuery.isEmpty
        ? allOptions
        : allOptions.where((o) => _matchesQuery(o.$1, cleanQuery)).toList();

    final height = MediaQuery.sizeOf(context).height * 0.78;
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A1206), Color(0xFF140604)],
        ),
        border: Border(top: BorderSide(color: Brass.gold.withValues(alpha: 0.8), width: 1.2)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(color: const Color(0x66FFE9B0), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            const SizedBox(width: 34, height: 34, child: CustomPaint(painter: SevaIconPainter(SevaIcon.changeDeity))),
            const SizedBox(height: 6),
            Text(
              _t(lang, en: 'Choose your Ishta Devta', hi: 'अपने इष्ट देव चुनें', mr: 'तुमचे इष्ट दैवत निवडा'),
              style: GoogleFonts.mukta(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFFFFE08A)),
            ),
            Text(
              _t(
                lang,
                en: 'They will be seated in your Mandir',
                hi: 'वे आपके मंदिर में विराजमान होंगे',
                mr: 'ते तुमच्या मंदिरात विराजमान होतील',
              ),
              style: GoogleFonts.mukta(fontSize: 13, color: const Color(0xB3FFE9B0)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0x33FFE9B0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x66FFE9B0)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Color(0xFFFFE08A), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.mukta(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFFE9B0),
                        ),
                        cursorColor: const Color(0xFFFFE08A),
                        decoration: InputDecoration(
                          hintText: _t(
                            lang,
                            en: 'Search deity...',
                            hi: 'देवता खोजें...',
                            mr: 'दैवत शोधा...',
                          ),
                          hintStyle: GoogleFonts.mukta(fontSize: 14, color: const Color(0x99FFE9B0)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.clear_rounded, color: Color(0x99FFE9B0), size: 18),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: allOptions.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Brass.gold))
                  : options.isEmpty
                      ? _EmptySearch(
                          lang: lang,
                          query: cleanQuery,
                          onRequest: () => showRequestDeitySheet(
                            context,
                            lang: lang,
                            initialText: cleanQuery,
                            source: 'mandir_deity_picker',
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.66,
                          ),
                          itemCount: options.length,
                          itemBuilder: (context, i) {
                            final option = options[i];
                            final selected = option.$1.key == current.key;
                            return _DeityMedallion(
                              deity: option.$1,
                              lang: lang,
                              selected: selected,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.of(context).pop(selected ? null : option);
                              },
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: InkWell(
                onTap: () => showRequestDeitySheet(
                  context,
                  lang: lang,
                  initialText: cleanQuery,
                  source: 'mandir_deity_picker',
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x33FF8F00),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x88FFB300)),
                  ),
                  child: Text(
                    _t(
                      lang,
                      en: 'Can’t find your Deity? Tell us here 🙏',
                      hi: 'अपना देवता नहीं मिला? यहाँ बताएं 🙏',
                      mr: 'आपले दैवत सापडले नाही का? येथे सांगा 🙏',
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mukta(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFE08A),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.lang, required this.query, required this.onRequest});

  final String lang;
  final String query;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _t(
                lang,
                en: 'No deity found for "$query"',
                hi: '"$query" के लिए कोई देवता नहीं मिला',
                mr: '"$query" साठी कोणतेही दैवत आढळले नाही',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFFFFE08A)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8F00),
                foregroundColor: const Color(0xFF2A0E04),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: Text(
                _t(
                  lang,
                  en: 'Request "$query" 🙏',
                  hi: '"$query" जोड़ने का अनुरोध करें 🙏',
                  mr: '"$query" जोडण्याची विनंती करा 🙏',
                ),
                style: GoogleFonts.mukta(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeityMedallion extends StatelessWidget {
  const _DeityMedallion({required this.deity, required this.lang, required this.selected, required this.onTap});

  final BhaktiDeity deity;
  final String lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: deity.localizedName(lang),
      excludeSemantics: true,
      child: GestureDetector(
        key: Key('mandir-deity-${deity.key}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: AnimatedContainer(
                  duration: AppMotion.state,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        Color(0xFFFFE9A8),
                        Color(0xFF9A6B1C),
                        Color(0xFFF7D27A),
                        Color(0xFF7A5414),
                        Color(0xFFFFE9A8),
                      ],
                    ),
                    boxShadow: [
                      const BoxShadow(color: Color(0x99000000), blurRadius: 6, offset: Offset(0, 3)),
                      if (selected) const BoxShadow(color: Color(0xCCFFB300), blurRadius: 16, spreadRadius: 2),
                    ],
                  ),
                  child: ClipOval(
                    child: ColoredBox(
                      color: const Color(0xFF5A1A0A),
                      child: Image.asset(
                        deity.imageAsset,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        cacheWidth: 200,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              deity.localizedName(lang),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.mukta(
                fontSize: 12,
                height: 1.1,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? const Color(0xFFFFE08A) : const Color(0xE6FFE9B0),
              ),
            ),
            if (selected)
              Text(
                _t(lang, en: 'Seated', hi: 'विराजमान', mr: 'विराजमान'),
                style: GoogleFonts.mukta(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFFF8F00)),
              ),
          ],
        ),
      ),
    );
  }
}

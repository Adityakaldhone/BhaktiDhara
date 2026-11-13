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

class _DeityPickerSheet extends ConsumerWidget {
  const _DeityPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final current = ref.watch(jyotDeityProvider);
    final catalog = ref.watch(aartiCatalogProvider).valueOrNull;
    final options = <(BhaktiDeity, AartiItem)>[
      if (catalog != null)
        for (final deity in ishtaDeities())
          if (mainAartiFor(deity, catalog) case final aarti?) (deity, aarti),
    ];
    final currentIndex = options.indexWhere((o) => o.$1.key == current.key);
    if (currentIndex > 0) options.insert(0, options.removeAt(currentIndex));

    final height = MediaQuery.sizeOf(context).height * 0.72;
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
            Expanded(
              child: options.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Brass.gold))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
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

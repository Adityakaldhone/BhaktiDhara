import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../data/datasources/bhakti_deity_catalog.dart';
import '../../domain/entities/aarti_item.dart';
import '../../domain/entities/bhakti_deity.dart';
import '../../domain/logic/ishta_devta.dart';
import '../../services/backend_service.dart';
import '../providers/aarti_favorites_provider.dart';
import '../providers/aarti_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/nitya_onboarding_providers.dart';
import 'dashboard_screen.dart';

/// Makes [deity] the Ishta Devta and swaps the previous deity's pinned aarti
/// in मेरी नित्य आरती for [aarti].
void changeIshtaDevta(WidgetRef ref, BhaktiDeity deity, AartiItem aarti, {required String source}) {
  final previousKey = ref.read(ishtaDevtaProvider);
  final catalog = ref.read(aartiCatalogProvider).valueOrNull ?? const [];
  final previousAarti = kBhaktiDeities
      .where((d) => d.key == previousKey && d.key != deity.key)
      .map((d) => mainAartiFor(d, catalog))
      .firstOrNull;
  ref.read(ishtaDevtaProvider.notifier).select(deity.key, source: source);
  ref.read(aartiFavoritesProvider.notifier).replace(previousAarti?.id, aarti.id);
}

/// First-launch step after language: one tap on the devotee's Ishta Devta
/// pins that deity's main aarti to मेरी नित्य आरती and opens Home.
///
/// With [changing], it is opened from the More tab instead: the current
/// choice is highlighted, and a tap replaces the previous deity's pinned
/// aarti with the new one and returns.
class IshtaDevtaScreen extends ConsumerWidget {
  const IshtaDevtaScreen({super.key, this.changing = false});

  final bool changing;

  static String _t(String lang, {required String en, required String hi, required String mr}) =>
      lang == 'en' ? en : (lang == 'mr' ? mr : hi);

  void _openDashboard(NavigatorState nav) {
    nav.pushReplacement(
      MaterialPageRoute(builder: (_) => const MandirDashboardScreen()),
    );
  }

  void _skip(BuildContext context) {
    BackendService.trackEvent('ishta_skipped');
    _openDashboard(Navigator.of(context));
  }

  void _select(BuildContext context, WidgetRef ref, BhaktiDeity deity, AartiItem aarti) {
    HapticFeedback.selectionClick();
    final nav = Navigator.of(context);
    if (changing) {
      final lang = ref.read(localeProvider).languageCode;
      changeIshtaDevta(ref, deity, aarti, source: 'more');
      final messenger = ScaffoldMessenger.of(context);
      nav.pop();
      final name = deity.localizedName(lang);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _t(
                lang,
                en: '$name is now your Ishta Devta — aarti added to Daily',
                hi: '$name अब आपके इष्ट देव — आरती नित्य में जोड़ी',
                mr: '$name आता तुमचे इष्ट दैवत — आरती नित्य मध्ये जोडली',
              ),
            ),
          ),
        );
      return;
    }
    ref.read(ishtaDevtaProvider.notifier).select(deity.key);
    ref.read(aartiFavoritesProvider.notifier).pin(aarti.id);
    _openDashboard(nav);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final catalog = ref.watch(aartiCatalogProvider).valueOrNull;
    final current = changing ? ref.watch(ishtaDevtaProvider) : null;

    final options = <(BhaktiDeity, AartiItem)>[
      if (catalog != null)
        for (final deity in ishtaDeities())
          if (mainAartiFor(deity, catalog) case final aarti?) (deity, aarti),
    ];
    final currentIndex = options.indexWhere((o) => o.$1.key == current);
    if (currentIndex > 0) options.insert(0, options.removeAt(currentIndex));

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (changing)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    key: const Key('ishta-back'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: MandirTheme.textDark,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('ishta-skip'),
                    onPressed: () => _skip(context),
                    child: Text(
                      _t(lang, en: 'Skip', hi: 'छोड़ें', mr: 'वगळा'),
                      style: GoogleFonts.mukta(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: MandirTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              Text(
                changing
                    ? _t(
                        lang,
                        en: 'Change your Ishta Devta',
                        hi: 'अपने इष्ट देव बदलें',
                        mr: 'तुमचे इष्ट दैवत बदला',
                      )
                    : _t(
                        lang,
                        en: 'Who is your Ishta Devta?',
                        hi: 'आपके इष्ट देव कौन हैं?',
                        mr: 'तुमचे इष्ट दैवत कोण?',
                      ),
                textAlign: TextAlign.center,
                style: GoogleFonts.mukta(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: MandirTheme.secondaryMaroon,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                changing
                    ? _t(
                        lang,
                        en: 'Their aarti will be added to your Daily aartis',
                        hi: 'उनकी आरती मेरी नित्य आरती में जुड़ जाएगी',
                        mr: 'त्यांची आरती माझी नित्य आरतीमध्ये जोडली जाईल',
                      )
                    : _t(
                        lang,
                        en: 'Their aarti will be ready on your Home screen',
                        hi: 'उनकी आरती होम पर आपकी नित्य आरती में रहेगी',
                        mr: 'त्यांची आरती होमवर तुमच्या नित्य आरतीत असेल',
                      ),
                textAlign: TextAlign.center,
                style: GoogleFonts.mukta(fontSize: 16, color: MandirTheme.textMuted),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: options.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: MandirTheme.primarySaffron),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: options.length,
                        itemBuilder: (context, i) {
                          final (deity, aarti) = options[i];
                          return _DeityTile(
                            deity: deity,
                            lang: lang,
                            selected: deity.key == current,
                            onTap: () => _select(context, ref, deity, aarti),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeityTile extends StatelessWidget {
  const _DeityTile({
    required this.deity,
    required this.lang,
    required this.onTap,
    this.selected = false,
  });

  final BhaktiDeity deity;
  final String lang;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Material(
      key: Key('ishta-${deity.key}'),
      color: selected
          ? MandirTheme.primarySaffron.withValues(alpha: 0.10)
          : MandirTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: selected
            ? const BorderSide(color: MandirTheme.primarySaffron, width: 2)
            : const BorderSide(color: MandirTheme.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: MandirTheme.imageSurface,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ClipOval(
                    child: Image.asset(
                      deity.imageAsset,
                      fit: BoxFit.cover,
                      cacheWidth: 220,
                      errorBuilder: (_, _, _) => const Center(
                        child: Text('🙏', style: TextStyle(fontSize: 34)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                deity.localizedName(lang),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.mukta(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: MandirTheme.cardTitle,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

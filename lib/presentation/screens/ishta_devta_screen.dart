import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../data/datasources/bhakti_deity_catalog.dart';
import '../../domain/entities/aarti_item.dart';
import '../../domain/entities/bhakti_deity.dart';
import '../../domain/logic/ishta_devta.dart';
import '../../services/ad_units.dart';
import '../../services/backend_service.dart';
import '../providers/aarti_favorites_provider.dart';
import '../providers/aarti_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/nitya_onboarding_providers.dart';
import '../widgets/app_banner_ad.dart';
import '../widgets/request_deity_sheet.dart';
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
class IshtaDevtaScreen extends ConsumerStatefulWidget {
  const IshtaDevtaScreen({super.key, this.changing = false});

  final bool changing;

  @override
  ConsumerState<IshtaDevtaScreen> createState() => _IshtaDevtaScreenState();
}

class _IshtaDevtaScreenState extends ConsumerState<IshtaDevtaScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static String _t(String lang, {required String en, required String hi, required String mr}) =>
      lang == 'en' ? en : (lang == 'mr' ? mr : hi);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDashboard(NavigatorState nav) {
    nav.pushReplacement(
      MaterialPageRoute(builder: (_) => const MandirDashboardScreen()),
    );
  }

  void _skip(BuildContext context) {
    BackendService.trackEvent('ishta_skipped');
    _openDashboard(Navigator.of(context));
  }

  void _select(BuildContext context, BhaktiDeity deity, AartiItem aarti) {
    HapticFeedback.selectionClick();
    final nav = Navigator.of(context);
    if (widget.changing) {
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

  void _showRequestDeitySheet(BuildContext context, String lang, {String initialText = ''}) {
    showRequestDeitySheet(
      context,
      lang: lang,
      initialText: initialText,
      source: 'ishta_devta_screen',
      onSubmitted: () {
        // Onboarding: don't leave them stuck — default to Ganesha and continue.
        if (!widget.changing) {
          final catalog = ref.read(aartiCatalogProvider).valueOrNull;
          if (catalog != null) {
            final ganesh = ishtaOrDefault(null);
            final aarti = mainAartiFor(ganesh, catalog);
            if (aarti != null) {
              ref.read(ishtaDevtaProvider.notifier).select(ganesh.key);
              ref.read(aartiFavoritesProvider.notifier).pin(aarti.id);
            }
          }
          _openDashboard(Navigator.of(context));
        }
      },
    );
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
    final catalog = ref.watch(aartiCatalogProvider).valueOrNull;
    final current = widget.changing ? ref.watch(ishtaDevtaProvider) : null;

    final allOptions = <(BhaktiDeity, AartiItem)>[
      for (final deity in ishtaDeities())
        (deity, safeMainAartiFor(deity, catalog ?? const [])),
    ];
    final currentIndex = allOptions.indexWhere((o) => o.$1.key == current);
    if (currentIndex > 0) allOptions.insert(0, allOptions.removeAt(currentIndex));

    final cleanQuery = _searchQuery.trim();
    final options = cleanQuery.isEmpty
        ? allOptions
        : allOptions.where((o) => _matchesQuery(o.$1, cleanQuery)).toList();

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.changing)
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
                widget.changing
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
                widget.changing
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
                style: GoogleFonts.mukta(fontSize: 15, color: MandirTheme.textMuted),
              ),
              const SizedBox(height: 14),

              // ── Search Bar ──────────────────────────────────────────
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MandirTheme.cardBorder, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: MandirTheme.secondaryMaroon,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.mukta(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: MandirTheme.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: _t(
                            lang,
                            en: 'Search deity or Kuldevta...',
                            hi: 'इष्ट देव या कुलदेवता खोजें...',
                            mr: 'इष्टदेव किंवा कुलदैवत शोधा...',
                          ),
                          hintStyle: GoogleFonts.mukta(
                            fontSize: 14,
                            color: MandirTheme.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(
                          Icons.clear_rounded,
                          color: MandirTheme.textMuted,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Deity Grid or Empty State ───────────────────────────
              Expanded(
                child: allOptions.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: MandirTheme.primarySaffron),
                      )
                    : options.isEmpty
                        ? _buildSearchEmptyState(context, lang, cleanQuery)
                        : GridView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
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
                                onTap: () => _select(context, deity, aarti),
                              );
                            },
                          ),
              ),

              // ── "Can't find your deity?" Banner at Bottom ──────────
              Container(
                margin: const EdgeInsets.only(bottom: 8, top: 4),
                child: InkWell(
                  onTap: () => _showRequestDeitySheet(
                    context,
                    lang,
                    initialText: cleanQuery,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: MandirTheme.primarySaffron.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: MandirTheme.primarySaffron.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.volunteer_activism_rounded,
                          size: 18,
                          color: MandirTheme.secondaryMaroon,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _t(
                              lang,
                              en: 'Can’t find your Deity? Tell us here 🙏',
                              hi: 'अपना देवता नहीं मिला? यहाँ बताएं 🙏',
                              mr: 'आपले दैवत सापडले नाही का? येथे सांगा 🙏',
                            ),
                            style: GoogleFonts.mukta(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: MandirTheme.secondaryMaroon,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const AppBannerAd(adUnitId: AdUnits.ishtaDevtaBanner),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchEmptyState(BuildContext context, String lang, String query) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MandirTheme.primarySaffron.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.temple_hindu_rounded,
                  size: 42,
                  color: MandirTheme.secondaryMaroon,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _t(
                  lang,
                  en: 'No deity found for "$query"',
                  hi: '"$query" के लिए कोई देवता नहीं मिला',
                  mr: '"$query" साठी कोणतेही दैवत आढळले नाही',
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.mukta(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: MandirTheme.secondaryMaroon,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _t(
                  lang,
                  en: 'We will add this deity & aarti within 24 hours!',
                  hi: 'हम २४ घंटे में यह देवता और आरती ऐप में जोड़ देंगे!',
                  mr: 'आम्ही २४ तासांत हे दैवत आणि आरती ॲपमध्ये जोडू!',
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.mukta(
                  fontSize: 14,
                  color: MandirTheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showRequestDeitySheet(
                  context,
                  lang,
                  initialText: query,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MandirTheme.secondaryMaroon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: Text(
                  _t(
                    lang,
                    en: 'Request "$query" 🙏',
                    hi: '"$query" जोड़ने का अनुरोध करें 🙏',
                    mr: '"$query" जोडण्याची विनंती करा 🙏',
                  ),
                  style: GoogleFonts.mukta(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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

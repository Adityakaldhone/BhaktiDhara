import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../l10n/app_localizations.dart';
import '../../core/theme/theme.dart';
import '../../domain/entities/aarti_item.dart';
import '../providers/aarti_providers.dart';
import '../providers/locale_provider.dart';
import 'altar_screen.dart';

/// Screen 1 — BhaktiDhara Dashboard (pixel-perfect match to UI mockup)
class MandirDashboardScreen extends ConsumerStatefulWidget {
  const MandirDashboardScreen({super.key});

  @override
  ConsumerState<MandirDashboardScreen> createState() =>
      _MandirDashboardScreenState();
}

class _MandirDashboardScreenState extends ConsumerState<MandirDashboardScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  int _bottomNavIndex = 0;

  // Deity filter keys (English IDs for filtering logic)
  static const _deityKeys = [
    'All',
    'Lord Ganesha',
    'Lord Hanuman',
    'Lord Shiva',
    'Goddess Durga',
  ];

  @override
  void initState() {
    super.initState();
    // _loadBannerAd();
  }

  // void _loadBannerAd() {
  //   _bannerAd = BannerAd(
  //     adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Ad Unit ID
  //     request: const AdRequest(),
  //     size: AdSize.banner,
  //     listener: BannerAdListener(
  //       onAdLoaded: (ad) {
  //         if (mounted) setState(() => _isBannerAdLoaded = true);
  //       },
  //       onAdFailedToLoad: (ad, error) {
  //         ad.dispose();
  //         _bannerAd = null;
  //       },
  //     ),
  //   )..load();
  // }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _openAarti(AartiItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AartiAltarScreen(aarti: item)),
    );
  }

  /// Returns a short display name for the deity filter chip.
  String _chipLabel(String deityKey, AppLocalizations l10n) {
    switch (deityKey) {
      case 'All':
        return l10n.filterAll;
      case 'Lord Ganesha':
        return 'Ganesha';
      case 'Lord Hanuman':
        return 'Hanuman';
      case 'Lord Shiva':
        return 'Shiva';
      case 'Goddess Durga':
        return 'Durga';
      default:
        return deityKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(filteredCatalogProvider);
    final selectedFilter = ref.watch(selectedDeityFilterProvider) ?? 'All';
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      body: SafeArea(
        child: Column(
          children: [
            // ── Decorative Header ────────────────────────────────────────
            _buildHeader(l10n),

            // ── Search Bar ───────────────────────────────────────────────
            _buildSearchBar(l10n),

            // ── Deity Filter Chips ───────────────────────────────────────
            _buildFilterChips(selectedFilter, l10n),

            // ── Section Title Row ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.sacredCollection,
                    style: GoogleFonts.mukta(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: MandirTheme.textDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.seeAll,
                          style: TextStyle(
                            fontSize: 14,
                            color: MandirTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: MandirTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Catalog List ─────────────────────────────────────────────
            Expanded(
              child: catalogAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: MandirTheme.primarySaffron,
                  ),
                ),
                error: (err, stack) => Center(
                  child: Text(
                    l10n.loadingError,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                data: (catalog) {
                  if (catalog.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noAartiFound,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: catalog.length,
                    separatorBuilder: (context, i) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildAartiCard(catalog[index], l10n, localeCode);
                    },
                  );
                },
              ),
            ),

            // ── AdMob Banner ─────────────────────────────────────────────
            if (_isBannerAdLoaded && _bannerAd != null)
              Container(
                color: MandirTheme.backgroundCream,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),

      // ── Bottom Navigation ──────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _bottomNavIndex,
          onTap: (index) {
            setState(() => _bottomNavIndex = index);
            if (index == 2) _showLanguageBottomSheet();
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: MandirTheme.surfaceWhite,
          selectedItemColor: MandirTheme.primarySaffron,
          unselectedItemColor: MandirTheme.textMuted,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_filled),
              label: l10n.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_border),
              label: l10n.navFavorites,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.language),
              label: l10n.navLanguage,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.more_horiz),
              label: l10n.navMore,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HEADER (Om + BhaktiDhara + Aarti Sangrah + Tagline + Settings Icon)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // ── Header Background Decoration ────────────────────────────────
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/decorations/corner_mandala.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ── Main Header Content ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
            child: Column(
              children: [
                // Top row: Bells on sides, Om + Settings in center-right
                SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // Left bell — positioned at far left edge with some space
                      Positioned(
                        left: 12,
                        top: -15,
                        child: Image.asset(
                          'assets/decorations/bell.png',
                          width: 55,
                          height: 110,
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Right bell — positioned at far right edge with some space
                      Positioned(
                        right: 12,
                        top: -15,
                        child: Image.asset(
                          'assets/decorations/bell.png',
                          width: 55,
                          height: 110,
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Settings icon (positioned inward, not overlapping bell)
                      Positioned(
                        right: 76,
                        top: 4,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: MandirTheme.goldenAccent.withValues(
                              alpha: 0.15,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.settings_outlined,
                              color: MandirTheme.goldenAccent,
                              size: 20,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ),

                      // Center column: Om + Title + Subtitle + Tagline
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Om symbol (decorative image)
                            Image.asset(
                              'assets/decorations/om.png',
                              height: 44,
                              fit: BoxFit.contain,
                            ),

                            // App Title — "BhaktiDhara"
                            Text(
                              l10n.appTitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.yatraOne(
                                fontSize: 34,
                                fontWeight: FontWeight.w400,
                                color: MandirTheme.secondaryMaroon,
                                height: 1.0,
                              ),
                            ),

                            // Subtitle — "Aarti Sangrah"
                            Text(
                              l10n.appSubtitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.mukta(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: MandirTheme.textDark,
                              ),
                            ),

                            // Decorative horizontal bar
                            Image.asset(
                              'assets/decorations/horizontal_bar.png',
                              width: MediaQuery.sizeOf(context).width * 0.65,
                              height: 24,
                              fit: BoxFit.fitWidth,
                            ),

                            // Tagline
                            Text(
                              l10n.appTagline,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.mukta(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: MandirTheme.goldenAccent,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SEARCH BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSearchBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: MandirTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEBE3D5), // Subtle warm beige
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: TextField(
          textAlignVertical: TextAlignVertical.center,
          style: GoogleFonts.notoSans(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: MandirTheme.textDark,
          ),
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            hintStyle: GoogleFonts.notoSans(
              color: MandirTheme.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: MandirTheme.textMuted,
              size: 21,
            ),
            suffixIcon: const Icon(
              Icons.mic_none,
              color: MandirTheme.textMuted,
              size: 19,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DEITY FILTER CHIPS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFilterChips(String selectedFilter, AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: _deityKeys.map((deityKey) {
          final isSelected = selectedFilter == deityKey;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                ref.read(selectedDeityFilterProvider.notifier).state =
                    deityKey == 'All' ? null : deityKey;
              },
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? MandirTheme.primarySaffron
                      : MandirTheme.chipBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? null
                      : Border.all(color: MandirTheme.chipBorder, width: 1),
                ),
                child: Text(
                  _chipLabel(deityKey, l10n),
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : MandirTheme.chipText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  AARTI CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAartiCard(
    AartiItem item,
    AppLocalizations l10n,
    String localeCode,
  ) {
    final localizedTitle = item.localizedTitle(localeCode);
    final englishTitle = item.title; // Always show English as subtitle

    return Container(
      decoration: BoxDecoration(
        color: MandirTheme.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: MandirTheme.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A5A2B).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _openAarti(item),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // 1. Right-side decorative mandala
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: Opacity(
                    opacity: 0.25,
                    child: Image.asset(
                      'assets/decorations/card_right_design.png',
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // 2. Main content row
                Padding(
                  padding: const EdgeInsets.all(
                    10,
                  ), // inner padding around everything
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Artwork Container
                      Container(
                        width: 130,
                        height: 140, // Proportional to card height
                        decoration: BoxDecoration(
                          color: MandirTheme.imageSurface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              _getDeityImageAsset(item.deity),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    item.deityEmoji,
                                    style: const TextStyle(fontSize: 40),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Content Area
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hindi/Localized Title
                              Text(
                                localizedTitle,
                                style: GoogleFonts.notoSansDevanagari(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  color: MandirTheme.cardTitle,
                                  height: 1.15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              // English Title
                              Text(
                                englishTitle,
                                style: GoogleFonts.notoSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: MandirTheme.cardSubtitle,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),

                              // Content tags
                              Wrap(
                                spacing: 2,
                                runSpacing: 2,
                                children: item.tags
                                    .map((tag) => _buildContentTag(tag))
                                    .toList(),
                              ),

                              const SizedBox(height: 14),

                              // Read & Play Button and Arrow
                              Row(
                                children: [
                                  Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: MandirTheme.cardPrimaryButton,
                                      borderRadius: BorderRadius.circular(21),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.12,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.play_arrow,
                                          color: MandirTheme.cardButtonText,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          l10n.readAndPlay,
                                          style: GoogleFonts.notoSans(
                                            color: MandirTheme.cardButtonText,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  // Circular Arrow Button
                                  Container(
                                    width: 44,
                                    height: 44,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: MandirTheme.arrowBackground,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.chevron_right,
                                      color: MandirTheme.arrowIcon,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

  Widget _buildContentTag(String tag) {
    IconData iconData;
    if (tag.toLowerCase().contains('aarti') ||
        tag.toLowerCase().contains('आरती')) {
      iconData = Icons.music_note; // ♫
    } else if (tag.toLowerCase().contains('chalisa') ||
        tag.toLowerCase().contains('चालीसा')) {
      iconData = Icons.menu_book; // ▢
    } else {
      iconData = Icons.spa; // ♧
    }

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: MandirTheme.tagBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MandirTheme.tagBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(iconData, color: const Color(0xFF9A4A27), size: 14),
          const SizedBox(width: 4),
          Text(
            tag,
            style: GoogleFonts.notoSans(
              color: MandirTheme.tagText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  LANGUAGE BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════════════════
  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: MandirTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                _buildLanguageTile('English', const Locale('en')),
                _buildLanguageTile('हिंदी', const Locale('hi')),
                _buildLanguageTile('मराठी', const Locale('mr')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageTile(String label, Locale locale) {
    final isActive = ref.read(localeProvider) == locale;
    return ListTile(
      leading: Icon(
        isActive ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isActive ? MandirTheme.primarySaffron : MandirTheme.textMuted,
      ),
      title: Text(
        label,
        style: GoogleFonts.mukta(
          fontSize: 18,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: MandirTheme.textDark,
        ),
      ),
      onTap: () {
        ref.read(localeProvider.notifier).state = locale;
        Navigator.pop(context);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DEITY IMAGE ASSETS
  // ═══════════════════════════════════════════════════════════════════════════
  String _getDeityImageAsset(String deity) {
    if (deity.contains('Ganesha')) {
      return 'assets/decorations/ganesh.png';
    } else if (deity.contains('Hanuman')) {
      return 'assets/decorations/hanuman.png';
    } else if (deity.contains('Shiva')) {
      return 'assets/decorations/mahadev.png';
    } else if (deity.contains('Durga')) {
      return 'assets/decorations/durga.png';
    }
    // Fallback image if a deity doesn't match
    return 'assets/decorations/om.png';
  }
}

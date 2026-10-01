import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../core/theme/theme.dart';
import '../../domain/entities/aarti_item.dart';
import '../providers/aarti_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/premium_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/greeting/greeting_dashboard_card.dart';
import '../widgets/jaap/jaap_dashboard_card.dart';
import '../widgets/premium_blurred_gate.dart';
import 'bhajan_screen.dart';
import 'deity_aarti_list_screen.dart';
import 'horoscope_screen.dart';
import 'panchang_screen.dart';

/// Screen 1 — BhaktiDhara Dashboard (pixel-perfect match to UI mockup)
class MandirDashboardScreen extends ConsumerStatefulWidget {
  const MandirDashboardScreen({super.key});

  @override
  ConsumerState<MandirDashboardScreen> createState() =>
      _MandirDashboardScreenState();
}

class _MandirDashboardScreenState extends ConsumerState<MandirDashboardScreen> {
  BannerAd? _bannerAd;
  final bool _isBannerAdLoaded = false;
  int _bottomNavIndex = 0;

  // Search and voice recognition controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _homeScrollController = ScrollController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _homeScrollController.addListener(_onHomeScroll);
    _initSpeech();
    // _loadBannerAd();
  }

  void _onHomeScroll() {
    final show = _homeScrollController.hasClients &&
        _homeScrollController.offset > 320;
    if (show != _showScrollToTop) {
      setState(() => _showScrollToTop = show);
    }
  }

  void _scrollToTop() {
    if (_homeScrollController.hasClients) {
      _homeScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speechToText.initialize(
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      if (mounted) {
        setState(() {
          _speechEnabled = available;
        });
      }
    } catch (_) {}
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
    _homeScrollController.removeListener(_onHomeScroll);
    _searchController.dispose();
    _homeScrollController.dispose();
    _speechToText.stop();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _openAarti(AartiItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DeityAartiListScreen(deity: item.deity, initialItem: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(filteredCatalogProvider);
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      body: IndexedStack(
        index: _bottomNavIndex,
        children: [
          _buildHomeTab(catalogAsync, l10n, localeCode),
          const BhajanScreen(),
          const HoroscopeScreen(),
          const PanchangScreen(),
        ],
      ),

      // ── Scroll-to-Top Floating Action Button ───────────────────────────
      floatingActionButton: (_bottomNavIndex == 0 && _showScrollToTop)
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              mini: true,
              backgroundColor: MandirTheme.primarySaffron,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              tooltip: localeCode == 'mr'
                  ? 'वर जा'
                  : (localeCode == 'hi' ? 'ऊपर जाएं' : 'Scroll to top'),
              child: const Icon(Icons.arrow_upward_rounded, size: 22),
            )
          : null,

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
            // Re-tapping Home scrolls the collection back to the top
            if (index == 0 &&
                _bottomNavIndex == 0 &&
                _homeScrollController.hasClients) {
              _homeScrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
              );
            }
            setState(() {
              _bottomNavIndex = index;
              if (index != 0) {
                _showScrollToTop = false;
              } else if (_homeScrollController.hasClients) {
                _showScrollToTop = _homeScrollController.offset > 320;
              }
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: MandirTheme.surfaceWhite,
          selectedItemColor: MandirTheme.primarySaffron,
          unselectedItemColor: MandirTheme.textMuted,
          iconSize: 26,
          selectedFontSize: 15,
          unselectedFontSize: 13.5,
          selectedLabelStyle: GoogleFonts.mukta(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            height: 1.2,
          ),
          unselectedLabelStyle: GoogleFonts.mukta(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            height: 1.2,
          ),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_filled),
              label: l10n.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.library_music_rounded),
              label: l10n.navBhajan,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.auto_awesome),
              label: l10n.navHoroscope,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_month_rounded),
              label: l10n.navPanchang,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HOME TAB (Collapsing header + pinned search + scrolling collection)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHomeTab(
    AsyncValue<List<AartiItem>> catalogAsync,
    AppLocalizations l10n,
    String localeCode,
  ) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _homeScrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // ── Decorative Header (collapses to a compact bar) ───────
                _buildSliverHeader(l10n),

                // ── Search Bar (stays pinned under the header) ───────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedSearchBarDelegate(
                    child: _buildSearchBar(l10n, localeCode),
                  ),
                ),

                // ── Naam Jaap entry ──────────────────────────────────────
                const SliverToBoxAdapter(child: JaapDashboardCard()),
                const SliverToBoxAdapter(child: GreetingDashboardCard()),

                // ── Section Title Row ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.sacredCollection,
                            style: GoogleFonts.mukta(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: MandirTheme.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildLanguageDropdown(localeCode, l10n),
                      ],
                    ),
                  ),
                ),

                // ── Catalog List ─────────────────────────────────────────
                ...catalogAsync.when(
                  loading: () => [
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: MandirTheme.primarySaffron,
                        ),
                      ),
                    ),
                  ],
                  error: (err, stack) => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          l10n.loadingError,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ],
                  data: (catalog) => [
                    if (catalog.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyCatalog(l10n),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        sliver: SliverList.separated(
                          itemCount: catalog.length,
                          separatorBuilder: (context, i) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildAartiCard(
                              catalog[index],
                              l10n,
                              localeCode,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── AdMob Banner (Ad-Free for Premium & Free Trial) ────────────
          if (!kIsWeb &&
              _isBannerAdLoaded &&
              _bannerAd != null &&
              !ref.watch(isPremiumProvider))
            Container(
              color: MandirTheme.backgroundCream,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCatalog(AppLocalizations l10n) {
    final query = ref.watch(searchQueryProvider).trim();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: MandirTheme.goldenAccent,
            ),
            const SizedBox(height: 14),
            Text(
              query.isNotEmpty ? l10n.searchNoResults : l10n.noAartiFound,
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: MandirTheme.textDark,
              ),
            ),
            if (query.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                  setState(() {});
                },
                icon: const Icon(Icons.clear, size: 18),
                label: Text(l10n.clearSearch),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MandirTheme.primarySaffron,
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  COLLAPSING SLIVER HEADER (Full header → compact Om + title bar)
  // ═══════════════════════════════════════════════════════════════════════════
  static const double _collapsedHeaderHeight = 60;

  Widget _buildSliverHeader(AppLocalizations l10n) {
    // Om, decorative bar and padding are fixed; the three text lines scale.
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final expandedHeight = 84 + 100 * textScale;

    return SliverAppBar(
      primary: false,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: _collapsedHeaderHeight,
      collapsedHeight: _collapsedHeaderHeight,
      expandedHeight: expandedHeight,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // 1.0 = fully expanded, 0.0 = fully collapsed
          final expandRatio =
              ((constraints.maxHeight - _collapsedHeaderHeight) /
                      (expandedHeight - _collapsedHeaderHeight))
                  .clamp(0.0, 1.0);
          final collapseRatio = 1.0 - expandRatio;
          final collapsedOpacity = ((collapseRatio - 0.5) / 0.5).clamp(
            0.0,
            1.0,
          );
          final expandedOpacity = Curves.easeIn.transform(
            ((expandRatio - 0.25) / 0.75).clamp(0.0, 1.0),
          );

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Solid backdrop fades in so cards don't show through
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: MandirTheme.backgroundCream,
                    border: Border(
                      bottom: BorderSide(
                        color: MandirTheme.goldenAccent.withValues(
                          alpha: 0.45 * collapsedOpacity,
                        ),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),

              // Full header slides up and fades out while collapsing
              if (expandedOpacity > 0)
                Positioned(
                  top: constraints.maxHeight - expandedHeight,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: expandRatio < 0.5,
                    child: Opacity(
                      opacity: expandedOpacity,
                      child: _buildHeader(l10n),
                    ),
                  ),
                ),

              // Compact bar (built only once mostly collapsed)
              if (collapsedOpacity > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _collapsedHeaderHeight,
                  child: Opacity(
                    opacity: collapsedOpacity,
                    child: _buildCollapsedHeader(l10n),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCollapsedHeader(AppLocalizations l10n) {
    final localeCode = ref.watch(localeProvider).languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Image.asset('assets/decorations/om.png', height: 30, width: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.appTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.yatraOne(
                fontSize: 24,
                color: MandirTheme.secondaryMaroon,
                height: 1.0,
              ),
            ),
          ),
          _buildVipHeaderBadge(localeCode),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: MandirTheme.goldenAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.settings_outlined,
                color: MandirTheme.goldenAccent,
                size: 20,
              ),
              onPressed: () => _showSettingsSheet(context, ref, localeCode),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HEADER (Om + BhaktiDhara + Aarti Sangrah + Tagline + Settings Icon)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(AppLocalizations l10n) {
    final localeCode = ref.watch(localeProvider).languageCode;
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

                      // VIP Crown Badge in Header
                      Positioned(
                        right: 122,
                        top: 5,
                        child: _buildVipHeaderBadge(localeCode),
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
                            onPressed: () =>
                                _showSettingsSheet(context, ref, localeCode),
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
                              height: 48,
                              width: 48,
                            ),
                            const SizedBox(height: 6),
                            // App title
                            Text(
                              l10n.appTitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.yatraOne(
                                fontSize: 32,
                                color: MandirTheme.secondaryMaroon,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Subtitle
                            Text(
                              l10n.appSubtitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.mukta(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: MandirTheme.goldenAccent,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Tagline
                            Text(
                              l10n.appTagline,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.mukta(
                                fontSize: 13,
                                color: MandirTheme.textMuted,
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
  //  VIP CROWN BADGE & SETTINGS BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildVipHeaderBadge(String localeCode) {
    final isPremium = ref.watch(isPremiumProvider);
    final sub = ref.watch(subscriptionProvider);

    if (isPremium) {
      return GestureDetector(
        onTap: () => _showMembershipDetails(context, ref, localeCode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD54F), Color(0xFFD4AF37)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👑', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text(
                sub.isTrial ? 'TRIAL' : 'VIP',
                style: GoogleFonts.mukta(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF5D120B),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => showPremiumPaywallSheet(context, ref, localeCode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3DC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👑', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              localeCode == 'en' ? 'VIP' : 'प्रीमियम',
              style: GoogleFonts.mukta(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8B1D18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMembershipDetails(
    BuildContext context,
    WidgetRef ref,
    String localeCode,
  ) {
    final sub = ref.watch(subscriptionProvider);
    final expiryFormatted = sub.expiresAt != null
        ? '${sub.expiresAt!.day}/${sub.expiresAt!.month}/${sub.expiresAt!.year}'
        : 'Active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFBF2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('👑', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    localeCode == 'en'
                        ? 'BhaktiDhara VIP Member'
                        : (localeCode == 'hi'
                            ? 'भक्तिधारा वीआईपी सदस्य'
                            : 'भक्तिधारा व्हीआयपी सदस्य'),
                    style: GoogleFonts.yatraOne(
                      fontSize: 20,
                      color: const Color(0xFF5D120B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5D120B), Color(0xFF8B1D18)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD4AF37),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sub.isTrial
                              ? (localeCode == 'en'
                                  ? '7-Day Free Trial'
                                  : '७-दिवसीय मोफत ट्रायल')
                              : (localeCode == 'en'
                                  ? 'Annual VIP Plan'
                                  : 'वार्षिक व्हीआयपी योजना'),
                          style: GoogleFonts.mukta(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFD54F),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            localeCode == 'en' ? 'ACTIVE' : 'सक्रिय',
                            style: GoogleFonts.mukta(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localeCode == 'en'
                          ? 'Valid until: $expiryFormatted'
                          : 'वैधता: $expiryFormatted',
                      style: GoogleFonts.mukta(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildBenefitRow(
                '🚫',
                localeCode == 'en'
                    ? 'Completely Ad-Free Experience'
                    : 'पूर्णपणे जाहिरातमुक्त अनुभव',
              ),
              _buildBenefitRow(
                '🔮',
                localeCode == 'en'
                    ? 'Full Horoscope (All Periods Unlocked)'
                    : 'संपूर्ण साप्ताहिक व मासिक राशीभविष्य',
              ),
              _buildBenefitRow(
                '⏳',
                localeCode == 'en'
                    ? 'Deep Panchang & Shubh Muhurta Timings'
                    : 'सर्व शुभ मुहूर्त व सखोल पंचांग',
              ),
              _buildBenefitRow(
                '🖼️',
                localeCode == 'en'
                    ? 'Unlimited Watermark-Free Greeting Cards'
                    : 'वॉटरमार्कशिवाय अमर्याद शुभेच्छा पत्रे',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    showPremiumPaywallSheet(context, ref, localeCode);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B1D18),
                    side: const BorderSide(color: Color(0xFFD4AF37)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    localeCode == 'en' ? 'View All Plans' : 'सर्व योजना पहा',
                    style: GoogleFonts.mukta(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () async {
                  await ref
                      .read(subscriptionProvider.notifier)
                      .cancelSubscription();
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '🔄 Reset to Free Tier! You can now test the Paywall & Purchase flow.',
                        ),
                        backgroundColor: Color(0xFF8B1D18),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(
                  Icons.restart_alt_rounded,
                  size: 18,
                  color: Color(0xFF8B1D18),
                ),
                label: Text(
                  localeCode == 'en'
                      ? 'Reset to Free Tier (Test Flow)'
                      : 'चाचणीसाठी रीसेट करा (Free Tier)',
                  style: GoogleFonts.mukta(
                    fontSize: 13,
                    color: const Color(0xFF8B1D18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBenefitRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.mukta(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C2416),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(
    BuildContext context,
    WidgetRef ref,
    String localeCode,
  ) {
    final isPremium = ref.watch(isPremiumProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFBF2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Image.asset(
                    'assets/decorations/om.png',
                    height: 26,
                    width: 26,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    localeCode == 'en'
                        ? 'Settings & Preferences'
                        : (localeCode == 'hi'
                            ? 'सेटिंग्स व प्राथमिकताएं'
                            : 'सेटिंग्ज व प्राधान्ये'),
                    style: GoogleFonts.yatraOne(
                      fontSize: 19,
                      color: const Color(0xFF5D120B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Membership banner
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  if (isPremium) {
                    _showMembershipDetails(context, ref, localeCode);
                  } else {
                    showPremiumPaywallSheet(context, ref, localeCode);
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPremium
                          ? [
                              const Color(0xFF5D120B),
                              const Color(0xFF8B1D18),
                            ]
                          : [
                              const Color(0xFFFFF3DC),
                              const Color(0xFFFFE8B8),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isPremium ? '👑' : '⭐',
                        style: const TextStyle(fontSize: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPremium
                                  ? (localeCode == 'en'
                                      ? 'BhaktiDhara VIP Active'
                                      : 'भक्तिधारा व्हीआयपी सक्रिय')
                                  : (localeCode == 'en'
                                      ? 'Upgrade to VIP (7 Days Free)'
                                      : 'व्हीआयपी व्हा (७ दिवस मोफत)'),
                              style: GoogleFonts.mukta(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isPremium
                                    ? const Color(0xFFFFD54F)
                                    : const Color(0xFF5D120B),
                              ),
                            ),
                            Text(
                              isPremium
                                  ? (localeCode == 'en'
                                      ? 'Tap to view membership details'
                                      : 'तपशील पाहण्यासाठी टॅप करा')
                                  : (localeCode == 'en'
                                      ? 'Remove ads & unlock full panchang'
                                      : 'जाहिरातमुक्त व सखोल पंचांग अनलॉक करा'),
                              style: GoogleFonts.mukta(
                                fontSize: 12,
                                color: isPremium
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : const Color(0xFF8B1D18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isPremium
                            ? const Color(0xFFFFD54F)
                            : const Color(0xFF8B1D18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Restore Purchases
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.restore_rounded,
                    color: Color(0xFF8B1D18),
                    size: 22,
                  ),
                ),
                title: Text(
                  localeCode == 'en'
                      ? 'Restore Purchases'
                      : 'खरेदी पुनर्संचयित करा',
                  style: GoogleFonts.mukta(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C2416),
                  ),
                ),
                subtitle: Text(
                  localeCode == 'en'
                      ? 'Sync Play Store or previous subscription'
                      : 'प्ले स्टोअर सदस्यता सिंक करा',
                  style: GoogleFonts.mukta(
                    fontSize: 12,
                    color: MandirTheme.textMuted,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  Navigator.pop(ctx);
                  final restored = await ref
                      .read(subscriptionProvider.notifier)
                      .restorePurchase();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF5D120B),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        content: Text(
                          restored
                              ? (localeCode == 'en'
                                  ? '✅ Purchases restored successfully!'
                                  : '✅ सदस्यता यशस्वीरीत्या पुनर्संचयित केली!')
                              : (localeCode == 'en'
                                  ? 'No active subscription found.'
                                  : 'कोणतीही सक्रिय सदस्यता आढळली नाही.'),
                          style: GoogleFonts.mukta(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),

              // Privacy Policy Link
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.privacy_tip_outlined,
                    color: Color(0xFF8B1D18),
                    size: 22,
                  ),
                ),
                title: Text(
                  localeCode == 'en'
                      ? 'Privacy Policy'
                      : 'गोपनीयता धोरण',
                  style: GoogleFonts.mukta(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C2416),
                  ),
                ),
                subtitle: Text(
                  'Privacy-first • Zero tracking',
                  style: GoogleFonts.mukta(
                    fontSize: 12,
                    color: MandirTheme.textMuted,
                  ),
                ),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () async {
                  final uri = Uri.parse('http://46.225.142.210/privacy.html');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),

              const SizedBox(height: 12),
              Center(
                child: Text(
                  'BhaktiDhara Aarti Sangrah v1.0.4\nHetzner Mandir Cloud • Powered by Gemini AI',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mukta(
                    fontSize: 11,
                    color: MandirTheme.textMuted,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SEARCH BAR & VOICE SEARCH
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSearchBar(AppLocalizations l10n, String localeCode) {
    final query = ref.watch(searchQueryProvider);
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
          controller: _searchController,
          textAlignVertical: TextAlignVertical.center,
          style: GoogleFonts.notoSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: MandirTheme.textDark,
          ),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
            setState(() {});
          },
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
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (query.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: MandirTheme.textMuted,
                      size: 20,
                    ),
                    tooltip: l10n.clearSearch,
                    splashRadius: 18,
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                      setState(() {});
                    },
                  ),
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening
                        ? MandirTheme.primarySaffron
                        : MandirTheme.textMuted,
                    size: 21,
                  ),
                  tooltip: l10n.voiceSearch,
                  splashRadius: 18,
                  onPressed: () => _handleVoiceSearch(l10n, localeCode),
                ),
                const SizedBox(width: 4),
              ],
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

  Future<void> _handleVoiceSearch(
    AppLocalizations l10n,
    String localeCode,
  ) async {
    if (!_speechEnabled) {
      final available = await _speechToText.initialize(
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      _speechEnabled = available;
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.speechNotAvailable),
              backgroundColor: MandirTheme.secondaryMaroon,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    String targetLocaleId = 'en_IN';
    try {
      final locales = await _speechToText.locales();
      if (localeCode == 'hi') {
        final match = locales
            .where((l) => l.localeId.toLowerCase().startsWith('hi'))
            .toList();
        if (match.isNotEmpty) {
          targetLocaleId = match.first.localeId;
        }
      } else if (localeCode == 'mr') {
        final match = locales
            .where((l) => l.localeId.toLowerCase().startsWith('mr'))
            .toList();
        if (match.isNotEmpty) {
          targetLocaleId = match.first.localeId;
        } else {
          final hiMatch = locales
              .where((l) => l.localeId.toLowerCase().startsWith('hi'))
              .toList();
          if (hiMatch.isNotEmpty) {
            targetLocaleId = hiMatch.first.localeId;
          }
        }
      } else {
        final match = locales
            .where((l) => l.localeId.toLowerCase().startsWith('en'))
            .toList();
        if (match.isNotEmpty) {
          targetLocaleId = match.first.localeId;
        }
      }
    } catch (_) {}

    if (!mounted) return;
    _openVoiceSearchModal(l10n, targetLocaleId);
  }

  void _openVoiceSearchModal(AppLocalizations l10n, String targetLocaleId) {
    String recognizedQuery = '';
    bool isListeningNow = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MandirTheme.backgroundCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final cancelLabel = MaterialLocalizations.of(
              context,
            ).cancelButtonLabel;
            final searchLabel = MaterialLocalizations.of(
              context,
            ).searchFieldLabel;

            void startListening() async {
              try {
                if (mounted) setState(() => _isListening = true);
                await _speechToText.listen(
                  onResult: (result) {
                    setModalState(() {
                      recognizedQuery = result.recognizedWords;
                    });
                    if (result.finalResult &&
                        recognizedQuery.trim().isNotEmpty) {
                      _applyVoiceQuery(recognizedQuery);
                      if (modalContext.mounted &&
                          Navigator.of(modalContext).canPop()) {
                        Navigator.of(modalContext).pop();
                      }
                    }
                  },
                  listenOptions: stt.SpeechListenOptions(
                    localeId: targetLocaleId,
                    listenMode: stt.ListenMode.search,
                    cancelOnError: false,
                    partialResults: true,
                  ),
                );
              } catch (_) {}
            }

            if (!_speechToText.isListening && isListeningNow) {
              startListening();
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.brown.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.voiceSearch,
                      style: GoogleFonts.mukta(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: MandirTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isListeningNow ? l10n.listening : l10n.speakNow,
                      style: GoogleFonts.mukta(
                        fontSize: 16,
                        color: MandirTheme.primarySaffron,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () async {
                        if (_speechToText.isListening) {
                          await _speechToText.stop();
                          setModalState(() => isListeningNow = false);
                          if (recognizedQuery.trim().isNotEmpty) {
                            _applyVoiceQuery(recognizedQuery);
                            if (modalContext.mounted &&
                                Navigator.of(modalContext).canPop()) {
                              Navigator.of(modalContext).pop();
                            }
                          }
                        } else {
                          setModalState(() => isListeningNow = true);
                          startListening();
                        }
                      },
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MandirTheme.primarySaffron,
                          boxShadow: [
                            BoxShadow(
                              color: MandirTheme.primarySaffron.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isListeningNow ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: MandirTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEBE3D5)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        recognizedQuery.isNotEmpty
                            ? recognizedQuery
                            : l10n.speakNow,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.mukta(
                          fontSize: 19,
                          fontWeight: recognizedQuery.isNotEmpty
                              ? FontWeight.bold
                              : FontWeight.w400,
                          color: recognizedQuery.isNotEmpty
                              ? MandirTheme.textDark
                              : MandirTheme.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await _speechToText.stop();
                              if (modalContext.mounted &&
                                  Navigator.of(modalContext).canPop()) {
                                Navigator.of(modalContext).pop();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: MandirTheme.textMuted,
                              side: const BorderSide(color: Color(0xFFEBE3D5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              cancelLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        if (recognizedQuery.trim().isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await _speechToText.stop();
                                _applyVoiceQuery(recognizedQuery);
                                if (modalContext.mounted &&
                                    Navigator.of(modalContext).canPop()) {
                                  Navigator.of(modalContext).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MandirTheme.primarySaffron,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.search, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    searchLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() async {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      if (mounted) setState(() => _isListening = false);
    });
  }

  void _applyVoiceQuery(String query) {
    final clean = query.trim();
    if (clean.isNotEmpty) {
      _searchController.text = clean;
      ref.read(searchQueryProvider.notifier).state = clean;
      setState(() {});
    }
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
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // 2. Main content row
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Artwork Container
                      Container(
                        width: 104,
                        height: 112,
                        decoration: BoxDecoration(
                          color: MandirTheme.imageSurface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset(
                              _getDeityImageAsset(item.deity),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/decorations/om.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => Center(
                                    child: Text(
                                      item.deityEmoji,
                                      style: const TextStyle(fontSize: 40),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Content Area
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hindi/Localized Title
                              Text(
                                localizedTitle,
                                style: GoogleFonts.notoSansDevanagari(
                                  fontSize: 17,
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
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: MandirTheme.cardSubtitle,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),

                              // Content tags
                              Wrap(
                                spacing: 2,
                                runSpacing: 2,
                                children: item.tags
                                    .map((tag) => _buildContentTag(tag))
                                    .toList(),
                              ),

                              const SizedBox(height: 10),

                              // Read & Play Button and Arrow
                              Row(
                                children: [
                                  Container(
                                    height: 34,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
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
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.readAndPlay,
                                          style: GoogleFonts.notoSans(
                                            color: MandirTheme.cardButtonText,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  // Circular Arrow Button
                                  Container(
                                    width: 36,
                                    height: 36,
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
                                      size: 22,
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
  //  LANGUAGE DROPDOWN & SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLanguageDropdown(String localeCode, AppLocalizations l10n) {
    final currentLocale = ref.watch(localeProvider);
    final String labelPrefix = localeCode == 'en' ? 'Language' : 'भाषा';
    final String currentLangName = switch (localeCode) {
      'en' => 'English',
      'hi' => 'हिंदी',
      _ => 'मराठी',
    };

    return PopupMenuButton<Locale>(
      tooltip: l10n.navLanguage,
      onSelected: (Locale newLocale) {
        ref.read(localeProvider.notifier).state = newLocale;
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
      ),
      color: MandirTheme.surfaceWhite,
      elevation: 6,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        _buildLanguagePopupItem('मराठी', const Locale('mr'), currentLocale),
        _buildLanguagePopupItem('हिंदी', const Locale('hi'), currentLocale),
        _buildLanguagePopupItem('English', const Locale('en'), currentLocale),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language,
              size: 16,
              color: MandirTheme.primarySaffron,
            ),
            const SizedBox(width: 5),
            Text(
              '$labelPrefix: $currentLangName',
              style: GoogleFonts.mukta(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: MandirTheme.secondaryMaroon,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 19,
              color: MandirTheme.primarySaffron,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<Locale> _buildLanguagePopupItem(
    String label,
    Locale locale,
    Locale currentLocale,
  ) {
    final isSelected = currentLocale.languageCode == locale.languageCode;
    return PopupMenuItem<Locale>(
      value: locale,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected
                ? MandirTheme.primarySaffron
                : MandirTheme.textMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.mukta(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? MandirTheme.secondaryMaroon
                  : MandirTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DEITY IMAGE ASSETS
  // ═══════════════════════════════════════════════════════════════════════════
  String _getDeityImageAsset(String deity) {
    return MandirTheme.getDeityImageAsset(deity);
  }
}

/// Keeps the dashboard search bar pinned below the collapsed header.
class _PinnedSearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _PinnedSearchBarDelegate({required this.child});

  // 48px field + 12px vertical padding on each side.
  static const double _height = 72;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: MandirTheme.backgroundCream,
      alignment: Alignment.center,
      child: child,
    );
  }

  // Always rebuild so the clear/mic icons track search and listening state.
  @override
  bool shouldRebuild(covariant _PinnedSearchBarDelegate oldDelegate) => true;
}

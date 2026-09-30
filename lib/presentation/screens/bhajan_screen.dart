import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/theme/theme.dart';
import '../../domain/entities/aarti_item.dart';
import '../../l10n/app_localizations.dart';
import '../../services/backend_service.dart';
import '../providers/bhajan_providers.dart';
import '../providers/locale_provider.dart';
import 'altar_screen.dart';

/// Dedicated screen for Bhakti Sangrah (Bhajans, Mantras, Stotras, and Popular chants).
///
/// Features rich categories, search (text & voice),
/// 3-in-a-row grid cards, and opens [AartiAltarScreen] for lyrics synchronization and playback.
class BhajanScreen extends ConsumerStatefulWidget {
  const BhajanScreen({super.key});

  @override
  ConsumerState<BhajanScreen> createState() => _BhajanScreenState();
}

class _BhajanScreenState extends ConsumerState<BhajanScreen> {
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  final List<_BhaktiCategoryItem> _categories = const [
    _BhaktiCategoryItem(id: 'All', labelMr: 'सर्व', labelHi: 'सभी', labelEn: 'All', emoji: '🕉️'),
    _BhaktiCategoryItem(id: 'Popular', labelMr: 'लोकप्रिय', labelHi: 'लोकप्रिय', labelEn: 'Popular', emoji: '🌟'),
    _BhaktiCategoryItem(id: 'Bhajan', labelMr: 'भजन', labelHi: 'भजन', labelEn: 'Bhajan', emoji: '🪘'),
    _BhaktiCategoryItem(id: 'Mantra', labelMr: 'मंत्र', labelHi: 'मंत्र', labelEn: 'Mantra', emoji: '🔱'),
    _BhaktiCategoryItem(id: 'Stotra', labelMr: 'स्तोत्र', labelHi: 'स्तोत्र', labelEn: 'Stotra', emoji: '📜'),
  ];

  @override
  void initState() {
    super.initState();
    BackendService.trackEvent('bhajan_open');
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (err) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'notListening' && mounted) {
            setState(() => _isListening = false);
          }
        },
      );
    } catch (_) {
      _speechEnabled = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  void _openBhajan(AartiItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AartiAltarScreen(aarti: item),
      ),
    );
  }

  void _startVoiceSearch() async {
    if (!_speechEnabled) {
      _initSpeech();
      return;
    }

    final localeCode = ref.read(localeProvider).languageCode;
    final String speechLocaleId = switch (localeCode) {
      'mr' => 'mr_IN',
      'hi' => 'hi_IN',
      _ => 'en_IN',
    };

    String recognizedQuery = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: MandirTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (!_isListening) {
              _isListening = true;
              _speechToText.listen(
                onResult: (result) {
                  setModalState(() {
                    recognizedQuery = result.recognizedWords;
                  });
                  if (result.finalResult && recognizedQuery.trim().isNotEmpty) {
                    _applyVoiceQuery(recognizedQuery);
                    if (modalContext.mounted && Navigator.of(modalContext).canPop()) {
                      Navigator.of(modalContext).pop();
                    }
                  }
                },
                listenOptions: stt.SpeechListenOptions(
                  localeId: speechLocaleId,
                ),
              );
            }

            final l10n = AppLocalizations.of(context)!;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Icon(
                      Icons.mic_rounded,
                      size: 52,
                      color: MandirTheme.primarySaffron,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      recognizedQuery.isEmpty ? l10n.listening : recognizedQuery,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.mukta(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: MandirTheme.secondaryMaroon,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.speakNow,
                      style: GoogleFonts.mukta(
                        fontSize: 15,
                        color: MandirTheme.textMuted,
                      ),
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
      ref.read(bhajanSearchQueryProvider.notifier).state = clean;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = ref.watch(filteredBhajanCatalogProvider);
    final popularItems = ref.watch(popularItemsProvider);
    final bhajanItems = ref.watch(bhajanOnlyItemsProvider);
    final mantraItems = ref.watch(mantraOnlyItemsProvider);
    final stotraItems = ref.watch(stotraOnlyItemsProvider);

    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeProvider).languageCode;
    final selectedCategory = ref.watch(selectedBhajanCategoryProvider);
    final query = ref.watch(bhajanSearchQueryProvider);

    return SafeArea(
      child: Column(
        children: [
          // ── Header Bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.bhajanSangrah,
                        style: GoogleFonts.mukta(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: MandirTheme.textDark,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.bhajanSubtitle,
                        style: GoogleFonts.mukta(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: MandirTheme.textMuted,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildLanguageDropdown(localeCode, l10n),
              ],
            ),
          ),

          // ── Search Bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: MandirTheme.cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(bhajanSearchQueryProvider.notifier).state = val;
                },
                decoration: InputDecoration(
                  hintText: l10n.bhajanSearchHint,
                  hintStyle: GoogleFonts.mukta(
                    fontSize: 15,
                    color: MandirTheme.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: MandirTheme.primarySaffron,
                    size: 22,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20, color: MandirTheme.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(bhajanSearchQueryProvider.notifier).state = '';
                            setState(() {});
                          },
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.mic_none_rounded,
                          color: MandirTheme.primarySaffron,
                          size: 22,
                        ),
                        onPressed: _startVoiceSearch,
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // ── Category Filter Chips ────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, i) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = selectedCategory == cat.id;
                final label = cat.getLocalizedLabel(localeCode);

                return GestureDetector(
                  onTap: () {
                    ref.read(selectedBhajanCategoryProvider.notifier).state = cat.id;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? MandirTheme.primarySaffron : MandirTheme.chipBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? MandirTheme.primarySaffron : MandirTheme.chipBorder,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: MandirTheme.primarySaffron.withValues(alpha: 0.28),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: GoogleFonts.mukta(
                            fontSize: 14.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : MandirTheme.chipText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // ── Main Body (3 in a Row Grid Layout) ────────────────────
          Expanded(
            child: query.isNotEmpty
                ? _buildSearchResults(filteredItems, query, l10n, localeCode)
                : (selectedCategory == 'All'
                    ? _buildAllSections(
                        popular: popularItems,
                        bhajans: bhajanItems,
                        mantras: mantraItems,
                        stotras: stotraItems,
                        l10n: l10n,
                        localeCode: localeCode,
                      )
                    : _buildSingleCategoryGrid(
                        filteredItems,
                        selectedCategory,
                        l10n,
                        localeCode,
                      )),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ALL SECTIONS VIEW (Scrollable page with 4 category grids)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAllSections({
    required List<AartiItem> popular,
    required List<AartiItem> bhajans,
    required List<AartiItem> mantras,
    required List<AartiItem> stotras,
    required AppLocalizations l10n,
    required String localeCode,
  }) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // 1. POPULAR SECTION (लोकप्रिय)
        if (popular.isNotEmpty) ...[
          _buildSectionHeader(
            title: switch (localeCode) {
              'en' => 'Popular',
              _ => 'लोकप्रिय',
            },
            emoji: '🌟',
            count: popular.length,
            onSeeAll: () {
              ref.read(selectedBhajanCategoryProvider.notifier).state = 'Popular';
            },
            l10n: l10n,
          ),
          _build3ColumnGrid(popular.take(6).toList(), l10n, localeCode),
        ],

        // 2. BHAJAN SECTION (भजन)
        if (bhajans.isNotEmpty) ...[
          _buildSectionHeader(
            title: switch (localeCode) {
              'en' => 'Bhajan & Kirtan',
              _ => 'भजन व कीर्तन',
            },
            emoji: '🪘',
            count: bhajans.length,
            onSeeAll: () {
              ref.read(selectedBhajanCategoryProvider.notifier).state = 'Bhajan';
            },
            l10n: l10n,
          ),
          _build3ColumnGrid(bhajans.take(6).toList(), l10n, localeCode),
        ],

        // 3. MANTRA SECTION (मंत्र)
        if (mantras.isNotEmpty) ...[
          _buildSectionHeader(
            title: switch (localeCode) {
              'en' => 'Mantra & Chants',
              _ => 'मंत्र व जप',
            },
            emoji: '🔱',
            count: mantras.length,
            onSeeAll: () {
              ref.read(selectedBhajanCategoryProvider.notifier).state = 'Mantra';
            },
            l10n: l10n,
          ),
          _build3ColumnGrid(mantras.take(6).toList(), l10n, localeCode),
        ],

        // 4. STOTRA SECTION (स्तोत्र)
        if (stotras.isNotEmpty) ...[
          _buildSectionHeader(
            title: switch (localeCode) {
              'en' => 'Stotra & Chalisa',
              _ => 'स्तोत्र व चालीसा',
            },
            emoji: '📜',
            count: stotras.length,
            onSeeAll: () {
              ref.read(selectedBhajanCategoryProvider.notifier).state = 'Stotra';
            },
            l10n: l10n,
          ),
          _build3ColumnGrid(stotras.take(6).toList(), l10n, localeCode),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SINGLE CATEGORY GRID VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSingleCategoryGrid(
    List<AartiItem> items,
    String categoryId,
    AppLocalizations l10n,
    String localeCode,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.noBhajanFound,
            textAlign: TextAlign.center,
            style: GoogleFonts.mukta(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MandirTheme.textDark,
            ),
          ),
        ),
      );
    }

    final catItem = _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => _categories.first,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Text(catItem.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                catItem.getLocalizedLabel(localeCode),
                style: GoogleFonts.mukta(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: MandirTheme.secondaryMaroon,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: MandirTheme.primarySaffron.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${items.length}',
                  style: GoogleFonts.mukta(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: MandirTheme.primarySaffron,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  ref.read(selectedBhajanCategoryProvider.notifier).state = 'All';
                },
                icon: const Icon(Icons.arrow_back, size: 16),
                label: Text(
                  localeCode == 'en' ? 'All' : 'सर्व',
                  style: GoogleFonts.mukta(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        _build3ColumnGrid(items, l10n, localeCode),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SEARCH RESULTS VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSearchResults(
    List<AartiItem> items,
    String query,
    AppLocalizations l10n,
    String localeCode,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.library_music_outlined,
                size: 60,
                color: MandirTheme.cardBorder,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noBhajanFound,
                textAlign: TextAlign.center,
                style: GoogleFonts.mukta(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: MandirTheme.textDark,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  ref.read(bhajanSearchQueryProvider.notifier).state = '';
                  ref.read(selectedBhajanCategoryProvider.notifier).state = 'All';
                  setState(() {});
                },
                icon: const Icon(Icons.clear, size: 18),
                label: Text(l10n.clearSearch),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MandirTheme.primarySaffron,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Text(
            '${items.length} ${localeCode == 'en' ? 'results' : 'परिणाम'}',
            style: GoogleFonts.mukta(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: MandirTheme.textMuted,
            ),
          ),
        ),
        _build3ColumnGrid(items, l10n, localeCode),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SECTION HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSectionHeader({
    required String title,
    required String emoji,
    required int count,
    required VoidCallback onSeeAll,
    required AppLocalizations l10n,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 19)),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.mukta(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MandirTheme.secondaryMaroon,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
            decoration: BoxDecoration(
              color: MandirTheme.primarySaffron.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.mukta(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: MandirTheme.primarySaffron,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text(
                  l10n.seeAll,
                  style: GoogleFonts.mukta(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: MandirTheme.primarySaffron,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: MandirTheme.primarySaffron,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  3-IN-A-ROW GRID BUILDER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _build3ColumnGrid(
    List<AartiItem> items,
    AppLocalizations l10n,
    String localeCode,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildGridCard(items[index], l10n, localeCode);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  GRID CARD (Compact, 3 in 1 row)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildGridCard(
    AartiItem item,
    AppLocalizations l10n,
    String localeCode,
  ) {
    final localizedTitle = item.localizedTitle(localeCode);

    return Container(
      decoration: BoxDecoration(
        color: MandirTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MandirTheme.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A5A2B).withValues(alpha: 0.07),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openBhajan(item),
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Artwork Container with Deity Portrait
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: MandirTheme.imageSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset(
                              MandirTheme.getDeityImageAsset(item.deity),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    item.deityEmoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Floating duration / play pill
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 11,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  item.durationText,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Title and Subtitle Area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        localizedTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mukta(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: MandirTheme.textDark,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.singer.isNotEmpty ? item.singer : item.localizedDeity(localeCode),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mukta(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: MandirTheme.textMuted,
                          height: 1.1,
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

  // ═══════════════════════════════════════════════════════════════════════════
  //  LANGUAGE DROPDOWN
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: MandirTheme.secondaryMaroon,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
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
            color: isSelected ? MandirTheme.primarySaffron : MandirTheme.textMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.mukta(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? MandirTheme.secondaryMaroon : MandirTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _BhaktiCategoryItem {
  final String id;
  final String labelMr;
  final String labelHi;
  final String labelEn;
  final String emoji;

  const _BhaktiCategoryItem({
    required this.id,
    required this.labelMr,
    required this.labelHi,
    required this.labelEn,
    required this.emoji,
  });

  String getLocalizedLabel(String localeCode) {
    return switch (localeCode) {
      'en' => labelEn,
      'hi' => labelHi,
      _ => labelMr,
    };
  }
}

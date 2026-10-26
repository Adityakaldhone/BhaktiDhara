import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/theme.dart';
import '../../domain/entities/granth.dart';
import '../providers/granth_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/remote_config_provider.dart';
import '../widgets/granth_meta.dart';
import '../widgets/premium_blurred_gate.dart';
import 'granth_chapter_list_screen.dart';
import 'granth_pothi_reader_screen.dart';

/// Layout tokens for the catalog. Radii step down concentrically:
/// hero (24) > card (20) > inner tile (14) > field (12) > capsule.
abstract final class _G {
  static const double gutter = 20;
  static const double radiusHero = 24;
  static const double radiusCard = 20;
  static const double radiusTile = 14;
  static const double radiusField = 12;

  static const Color card = Color(0xFFFFFDF8);
  static const Color fill = Color(0x0F3E2723);
  static const Color hairline = Color(0x123E2723);

  static const List<BoxShadow> shadow = [
    BoxShadow(color: Color(0x0A3E2723), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F3E2723), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

/// Letter-spacing on Devanagari breaks the shirorekha, so tracking is only
/// applied to Latin script.
double _track(String langCode, double value) => langCode == 'en' ? value : 0;

class GranthCatalogScreen extends ConsumerStatefulWidget {
  const GranthCatalogScreen({super.key});

  @override
  ConsumerState<GranthCatalogScreen> createState() => _GranthCatalogScreenState();
}

class _GranthCatalogScreenState extends ConsumerState<GranthCatalogScreen> {
  String _selectedCategory = 'all'; // 'all', 'canonical', 'mahapurana', 'upapurana'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(granthBooksProvider);
    final langCode = ref.watch(localeProvider).languageCode;
    final isVip = ref.watch(premiumAccessProvider);
    final lastRead = ref.watch(granthLastReadProvider);

    final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 1.3);
    final searchHeight = 44.0 * textScale;
    final pillHeight = 36.0 * textScale;

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      body: SafeArea(
        child: RefreshIndicator(
          color: MandirTheme.primarySaffron,
          onRefresh: () async {
            ref.invalidate(granthBooksProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── Large Title + Membership ────────────────────────────────
              SliverToBoxAdapter(
                child: _buildHeader(context, ref, langCode, isVip),
              ),

              // ── Pinned translucent Search & Filter bar ──────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedBarDelegate(
                  extent: 8 + searchHeight + 10 + pillHeight + 12,
                  solid: MediaQuery.highContrastOf(context),
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.3,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildSearchBar(langCode, searchHeight),
                        const SizedBox(height: 10),
                        _buildCategoryPills(langCode, pillHeight),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Continue Reading (वाचन सुरू ठेवा) Card ───────────────────
              if (lastRead != null && _searchQuery.isEmpty)
                SliverToBoxAdapter(
                  child: _buildContinueReadingCard(context, ref, lastRead, langCode),
                ),

              // ── Books Content ───────────────────────────────────────────
              booksAsync.when(
                data: (books) {
                  if (books.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildStatusMessage(
                        icon: Icons.menu_book_rounded,
                        title: langCode == 'hi'
                            ? 'कोई ग्रंथ उपलब्ध नहीं है।'
                            : (langCode == 'en'
                                ? 'No scriptures available.'
                                : 'कोणतेही ग्रंथ उपलब्ध नाहीत.'),
                        langCode: langCode,
                      ),
                    );
                  }

                  // Apply search filter
                  final filteredBooks = books.where((b) {
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      final tMr = b.title['mr']?.toLowerCase() ?? '';
                      final tHi = b.title['hi']?.toLowerCase() ?? '';
                      final tEn = b.title['en']?.toLowerCase() ?? '';
                      final subMr = b.subtitle['mr']?.toLowerCase() ?? '';
                      final style = getGranthStyle(b.slug);
                      final deity = style.deityFor(langCode).toLowerCase();
                      final tag = style.tagFor(langCode).toLowerCase();

                      if (!tMr.contains(q) &&
                          !tHi.contains(q) &&
                          !tEn.contains(q) &&
                          !subMr.contains(q) &&
                          !deity.contains(q) &&
                          !tag.contains(q) &&
                          !b.slug.contains(q)) {
                        return false;
                      }
                    }

                    // Apply category tab
                    if (_selectedCategory == 'all') return true;
                    final style = getGranthStyle(b.slug);
                    return style.category == _selectedCategory;
                  }).toList();

                  if (filteredBooks.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: _buildStatusMessage(
                          icon: Icons.search_off_rounded,
                          title: langCode == 'hi'
                              ? '"$_searchQuery" के लिए कोई ग्रंथ नहीं मिला'
                              : (langCode == 'en'
                                  ? 'No scriptures found for "$_searchQuery"'
                                  : '"$_searchQuery" साठी कोणतेही ग्रंथ सापडले नाहीत'),
                          langCode: langCode,
                        ),
                      ),
                    );
                  }

                  // Separate into Canonical vs Puranas vs Upapuranas
                  final canonicalBooks = filteredBooks
                      .where((b) => getGranthStyle(b.slug).category == 'canonical')
                      .toList();

                  final mahapuranas = filteredBooks
                      .where((b) => getGranthStyle(b.slug).category == 'mahapurana')
                      .toList();

                  final upapuranas = filteredBooks
                      .where((b) => getGranthStyle(b.slug).category == 'upapurana')
                      .toList();

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      // ── 1. Canonical Scriptures (Gita & Dasbodh) ────────
                      if (canonicalBooks.isNotEmpty) ...[
                        if (_selectedCategory == 'all' && _searchQuery.isEmpty)
                          _buildSectionTitle(
                            title: langCode == 'hi'
                                ? 'प्रमुख पावन ग्रंथ'
                                : (langCode == 'en' ? 'Core Sacred Scriptures' : 'प्रमुख पावन ग्रंथ'),
                            subtitle: langCode == 'hi'
                                ? 'श्रीमद्भगवद्गीता एवं श्रीमद् दासबोध'
                                : (langCode == 'en'
                                    ? 'Bhagavad Gita & Shri Dasbodh'
                                    : 'श्रीमद्भगवद्गीता व श्रीमद् दासबोध'),
                            badge: 'अमृत ग्रंथ',
                            langCode: langCode,
                          )
                        else
                          const SizedBox(height: 8),
                        ...canonicalBooks.map(
                          (book) => _buildCanonicalHeroCard(context, ref, book, langCode, isVip),
                        ),
                      ],

                      // ── 2. The 18 Mahapuranas Grid ──────────────────────
                      if (mahapuranas.isNotEmpty) ...[
                        _buildSectionTitle(
                          title: langCode == 'hi'
                              ? 'अष्टादश महापुराण (१८ महापुराण)'
                              : (langCode == 'en'
                                  ? 'The 18 Sacred Mahapuranas'
                                  : 'अष्टादश महापुराणे (१८ महापुराणे)'),
                          subtitle: langCode == 'hi'
                              ? 'महर्षि वेदव्यास विरचित १८ पावन महापुराण • सचित्र मूळ ग्रंथ'
                              : (langCode == 'en'
                                  ? '18 Divine Mahapuranas composed by Maharshi Veda Vyasa'
                                  : 'महर्षि वेदव्यास विरचित १८ पावन महापुराणे • सचित्र मूळ ग्रंथ'),
                          badge: '${mahapuranas.length} महापुराणे',
                          langCode: langCode,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: _G.gutter),
                          child: _buildPuranasGrid(context, ref, mahapuranas, langCode, isVip),
                        ),
                      ],

                      // ── 3. Upapuranas & Samhita ─────────────────────────
                      if (upapuranas.isNotEmpty) ...[
                        _buildSectionTitle(
                          title: langCode == 'hi'
                              ? 'उपपुराण एवं महापुराण सार संहिता'
                              : (langCode == 'en'
                                  ? 'Upapuranas & Mahapurana Samhita'
                                  : 'उपपुराणे व महापुराण सार संहिता'),
                          subtitle: langCode == 'hi'
                              ? 'श्रीकल्कि, श्रीनृसिंह व १८ महापुराणांचा एकत्रित संग्रह'
                              : (langCode == 'en'
                                  ? 'Kalki, Narasimha & Complete Purana Compendium'
                                  : 'श्रीकल्कि, श्रीनृसिंह व १८ महापुराणांचा एकत्रित संग्रह'),
                          badge: '${upapuranas.length} ग्रंथ',
                          langCode: langCode,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: _G.gutter),
                          child: _buildPuranasGrid(context, ref, upapuranas, langCode, isVip),
                        ),
                      ],
                    ]),
                  );
                },
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: MandirTheme.primarySaffron,
                      ),
                    ),
                  ),
                ),
                error: (err, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildStatusMessage(
                    icon: Icons.cloud_off_rounded,
                    title: langCode == 'hi'
                        ? 'ग्रंथ सूची लोड नहीं हो सकी'
                        : (langCode == 'en'
                            ? 'Failed to load scriptures'
                            : 'ग्रंथ यादी लोड होऊ शकली नाही'),
                    langCode: langCode,
                    actionLabel: langCode == 'hi'
                        ? 'पुनः प्रयास करें'
                        : (langCode == 'en' ? 'Retry' : 'पुन्हा प्रयत्न करा'),
                    onAction: () => ref.invalidate(granthBooksProvider),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 48),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header: Large Title + Membership Row ───────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    String langCode,
    bool isVip,
  ) {
    final titleText = langCode == 'hi'
        ? 'पवित्र ग्रंथालय'
        : (langCode == 'en' ? 'Sacred Scriptures' : 'पवित्र ग्रंथालय');

    final subtitleText = langCode == 'hi'
        ? '१८ महापुराण, श्रीमद्भगवद्गीता एवं सनातन आत्मज्ञान'
        : (langCode == 'en'
            ? '18 Mahapuranas, Bhagavad Gita & Sacred Wisdom'
            : '१८ महापुराणे, श्रीमद्भगवद्गीता व सनातन आत्मज्ञान');

    final statusText = isVip
        ? (langCode == 'hi'
            ? 'प्रीमियम सक्रिय • सभी १८ महापुराण व अध्याय खुले हैं'
            : (langCode == 'en'
                ? 'VIP Active • All 18 Mahapuranas & scriptures unlocked'
                : 'प्रीमियम सक्रिय • सर्व १८ महापुराणे व अध्याय अनलॉक आहेत'))
        : (langCode == 'hi'
            ? 'संपूर्ण १८ महापुराण व अध्याय वाचनासाठी उपलब्ध'
            : (langCode == 'en'
                ? 'All 18 Mahapuranas & Sacred Scriptures Available'
                : 'सर्व १८ महापुराणे व ग्रंथ वाचनासाठी उपलब्ध आहेत'));

    final membershipRow = Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: _G.card,
        borderRadius: BorderRadius.circular(_G.radiusCard),
        border: Border.all(color: _G.hairline, width: 0.5),
        boxShadow: _G.shadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isVip
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFD54F), Color(0xFFC58B25)],
                    )
                  : null,
              color: isVip ? null : MandirTheme.primarySaffron.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(_G.radiusField),
            ),
            child: Icon(
              isVip ? Icons.workspace_premium_rounded : Icons.auto_stories_rounded,
              color: isVip ? Colors.white : MandirTheme.primarySaffron,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: GoogleFonts.mukta(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MandirTheme.textDark,
                height: 1.3,
              ),
            ),
          ),
          if (!isVip) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: const ShapeDecoration(
                color: MandirTheme.primarySaffron,
                shape: StadiumBorder(),
              ),
              child: Text(
                langCode == 'hi' ? 'अनलॉक' : (langCode == 'en' ? 'Unlock' : 'अनलॉक'),
                style: GoogleFonts.mukta(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(_G.gutter, 16, _G.gutter, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleText,
            style: GoogleFonts.mukta(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: MandirTheme.textDark,
              height: 1.15,
              letterSpacing: _track(langCode, -0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitleText,
            style: GoogleFonts.mukta(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: MandirTheme.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          if (isVip)
            membershipRow
          else
            _Pressable(
              onTap: () => showPremiumPaywallSheet(context, ref, langCode),
              child: membershipRow,
            ),
        ],
      ),
    );
  }

  // ── Search Field ───────────────────────────────────────────────────────────
  Widget _buildSearchBar(String langCode, double height) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _G.gutter),
      child: Container(
        height: height,
        padding: const EdgeInsets.only(left: 12, right: 4),
        decoration: BoxDecoration(
          color: _G.fill,
          borderRadius: BorderRadius.circular(_G.radiusField),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: MandirTheme.textMuted,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                textInputAction: TextInputAction.search,
                cursorColor: MandirTheme.primarySaffron,
                style: GoogleFonts.mukta(
                  fontSize: 16,
                  color: MandirTheme.textDark,
                  height: 1.2,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: langCode == 'hi'
                      ? 'ग्रंथ, पुराण किंवा अध्याय शोधा...'
                      : (langCode == 'en'
                          ? 'Search scriptures, puranas or deities...'
                          : 'ग्रंथ, पुराण किंवा अध्याय शोधा...'),
                  hintStyle: GoogleFonts.mukta(
                    fontSize: 16,
                    color: MandirTheme.textMuted.withValues(alpha: 0.8),
                    height: 1.2,
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _searchQuery.isNotEmpty ? 1 : 0,
              duration: AppMotion.press,
              curve: AppMotion.easeOut,
              child: IgnorePointer(
                ignoring: _searchQuery.isEmpty,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.cancel_rounded,
                    size: 18,
                    color: MandirTheme.textMuted,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Continue Reading (वाचन सुरू ठेवा) Card ──────────────────────────────────
  Widget _buildContinueReadingCard(
    BuildContext context,
    WidgetRef ref,
    GranthLastReadRecord record,
    String langCode,
  ) {
    final style = getGranthStyle(record.bookSlug);

    String detailText = '';
    if (record.isPothi && record.pageNumber != null) {
      detailText = langCode == 'hi'
          ? 'पृष्ठ ${record.pageNumber} वरून वाचन चालू ठेवा'
          : (langCode == 'en'
              ? 'Resume from page ${record.pageNumber}'
              : 'पृष्ठ ${record.pageNumber} वरून वाचन सुरू ठेवा');
    } else if (record.chapterNumber != null) {
      detailText = langCode == 'hi'
          ? 'अध्याय ${record.chapterNumber} ${record.chapterTitle != null ? '• ${record.chapterTitle}' : ''}'
          : (langCode == 'en'
              ? 'Chapter ${record.chapterNumber} ${record.chapterTitle != null ? '• ${record.chapterTitle}' : ''}'
              : 'अध्याय ${record.chapterNumber} ${record.chapterTitle != null ? '• ${record.chapterTitle}' : ''}');
    } else {
      detailText = langCode == 'hi'
          ? 'पावन महापुराण वाचन सुरू ठेवा'
          : (langCode == 'en' ? 'Resume sacred reading' : 'पावन महापुराण वाचन सुरू ठेवा');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(_G.gutter, 4, _G.gutter, 0),
      child: _Pressable(
        onTap: () {
          // Find book from provider
          final booksAsync = ref.read(granthBooksProvider);
          final book = booksAsync.valueOrNull?.firstWhere(
            (b) => b.slug == record.bookSlug,
            orElse: () => GranthBook(
              id: 0,
              slug: record.bookSlug,
              title: {'mr': record.bookTitle, 'hi': record.bookTitle, 'en': record.bookTitle},
              subtitle: {},
              description: {},
              totalChapters: 0,
              totalVerses: 0,
              freeChapters: 1,
              pdfUrl: record.pdfUrl,
              isActive: true,
              isUnlocked: true,
            ),
          );

          if (book == null) return;

          if (record.isPothi) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GranthPothiReaderScreen(
                  book: book,
                  initialPage: record.pageNumber ?? 1,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GranthChapterListScreen(book: book),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _G.card,
            borderRadius: BorderRadius.circular(_G.radiusCard),
            border: Border.all(color: _G.hairline, width: 0.5),
            boxShadow: _G.shadow,
          ),
          child: Row(
            children: [
              _EmblemTile(style: style, size: 56, radius: _G.radiusTile, emblemSize: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langCode == 'hi'
                          ? 'वाचन चालू ठेवा'
                          : (langCode == 'en' ? 'CONTINUE READING' : 'वाचन सुरू ठेवा'),
                      style: GoogleFonts.mukta(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: MandirTheme.primarySaffron,
                        height: 1.2,
                        letterSpacing: _track(langCode, 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.bookTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.mukta(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: MandirTheme.textDark,
                        height: 1.25,
                        letterSpacing: _track(langCode, -0.2),
                      ),
                    ),
                    Text(
                      detailText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.mukta(
                        fontSize: 14,
                        color: MandirTheme.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: MandirTheme.primarySaffron,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Category Filter Capsules ───────────────────────────────────────────────
  Widget _buildCategoryPills(String langCode, double height) {
    final categories = [
      {'key': 'all', 'label': langCode == 'hi' ? 'सर्व' : (langCode == 'en' ? 'All' : 'सर्व')},
      {
        'key': 'canonical',
        'label': langCode == 'hi' ? 'प्रमुख ग्रंथ' : (langCode == 'en' ? 'Canonical' : 'प्रमुख ग्रंथ'),
      },
      {
        'key': 'mahapurana',
        'label': langCode == 'hi' ? '१८ महापुराण' : (langCode == 'en' ? '18 Mahapuranas' : '१८ महापुराणे'),
      },
      {
        'key': 'upapurana',
        'label': langCode == 'hi' ? 'उपपुराण व संहिता' : (langCode == 'en' ? 'Upapuranas' : 'उपपुराणे व संहिता'),
      },
    ];

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: _G.gutter),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['key'];
          return _Pressable(
            scale: 0.95,
            onTap: () {
              if (isSelected) return;
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategory = cat['key']!;
              });
            },
            child: AnimatedContainer(
              duration: AppMotion.state,
              curve: AppMotion.ease,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: ShapeDecoration(
                color: isSelected ? MandirTheme.primarySaffron : _G.fill,
                shape: const StadiumBorder(),
              ),
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.state,
                curve: AppMotion.ease,
                style: GoogleFonts.mukta(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : MandirTheme.textDark,
                  height: 1.1,
                ),
                child: Text(cat['label']!),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Section Title ──────────────────────────────────────────────────────────
  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    required String badge,
    required String langCode,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_G.gutter, 28, _G.gutter, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.mukta(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: MandirTheme.textDark,
                    height: 1.2,
                    letterSpacing: _track(langCode, -0.4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.mukta(
                    fontSize: 13.5,
                    color: MandirTheme.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              badge,
              style: GoogleFonts.mukta(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: MandirTheme.goldenAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Canonical Hero Card (Bhagavad Gita & Dasbodh) ───────────────────────────
  Widget _buildCanonicalHeroCard(
    BuildContext context,
    WidgetRef ref,
    GranthBook book,
    String langCode,
    bool isVip,
  ) {
    final title = book.titleFor(langCode);
    final subtitle = book.subtitleFor(langCode);
    final description = book.descriptionFor(langCode);
    final style = getGranthStyle(book.slug);

    final isGita = book.slug == 'bhagavad-gita';
    final isDasbodh = book.slug == 'dasbodh';

    final chaptersText = isDasbodh
        ? (langCode == 'hi' ? '${book.totalChapters} दशक' : (langCode == 'en' ? '${book.totalChapters} Dashakas' : '${book.totalChapters} दशक'))
        : (langCode == 'hi' ? '${book.totalChapters} अध्याय' : (langCode == 'en' ? '${book.totalChapters} Chapters' : '${book.totalChapters} अध्याय'));
    final versesText = isDasbodh
        ? (langCode == 'hi' ? '${book.totalVerses} ओव्या' : (langCode == 'en' ? '${book.totalVerses} Ovis' : '${book.totalVerses} ओव्या'))
        : (langCode == 'hi' ? '${book.totalVerses} श्लोक' : (langCode == 'en' ? '${book.totalVerses} Verses' : '${book.totalVerses} श्लोक'));

    return Padding(
      padding: const EdgeInsets.fromLTRB(_G.gutter, 0, _G.gutter, 16),
      child: _Pressable(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GranthChapterListScreen(book: book),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: _G.card,
            borderRadius: BorderRadius.circular(_G.radiusHero),
            boxShadow: _G.shadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_G.radiusHero),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cover: emblem, tag and mantra on the scripture's own colours
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: style.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GlassTile(
                            size: 56,
                            radius: _G.radiusTile,
                            child: Text(
                              style.emblem,
                              style: TextStyle(
                                fontSize: isGita ? 30 : 26,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _GlassChip(
                            label: langCode == 'hi' ? 'मूल ग्रंथ' : (langCode == 'en' ? 'Canonical' : 'मूळ ग्रंथ'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        style.mantra,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mukta(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.mukta(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: MandirTheme.textDark,
                          height: 1.2,
                          letterSpacing: _track(langCode, -0.4),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        style.tagFor(langCode),
                        style: GoogleFonts.mukta(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: MandirTheme.primarySaffron,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle.isNotEmpty ? subtitle : description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mukta(
                          fontSize: 14.5,
                          color: MandirTheme.textMuted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '$chaptersText  ·  $versesText',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.mukta(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: MandirTheme.textMuted,
                              ),
                            ),
                          ),
                          if (isDasbodh) ...[
                            const SizedBox(width: 8),
                            _TintChip(
                              label: langCode == 'hi' ? 'सचित्र पोथी' : (langCode == 'en' ? 'Pothi' : 'सचित्र पोथी'),
                            ),
                          ],
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 7, 8, 7),
                            decoration: ShapeDecoration(
                              color: MandirTheme.primarySaffron.withValues(alpha: 0.1),
                              shape: const StadiumBorder(),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  langCode == 'hi' ? 'अध्याय सूची' : (langCode == 'en' ? 'Read' : 'अध्याय सूची'),
                                  style: GoogleFonts.mukta(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: MandirTheme.primarySaffron,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: MandirTheme.primarySaffron,
                                ),
                              ],
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

  // ── Puranas Grid (2 columns, equal-height rows) ─────────────────────────────
  Widget _buildPuranasGrid(
    BuildContext context,
    WidgetRef ref,
    List<GranthBook> puranas,
    String langCode,
    bool isVip,
  ) {
    const gap = 12.0;
    final rows = <Widget>[];
    for (var i = 0; i < puranas.length; i += 2) {
      final left = puranas[i];
      final right = i + 1 < puranas.length ? puranas[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < puranas.length ? gap : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildPuranaCard(context, ref, left, langCode, isVip)),
                const SizedBox(width: gap),
                Expanded(
                  child: right == null
                      ? const SizedBox.shrink()
                      : _buildPuranaCard(context, ref, right, langCode, isVip),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  // ── Individual Purana Card ─────────────────────────────────────────────────
  Widget _buildPuranaCard(
    BuildContext context,
    WidgetRef ref,
    GranthBook purana,
    String langCode,
    bool isVip,
  ) {
    final title = purana.titleFor(langCode);
    final subtitle = purana.subtitleFor(langCode);
    final style = getGranthStyle(purana.slug);

    final meta = [
      if (purana.totalChapters > 0) '${purana.totalChapters} अध्याय',
      if (purana.totalVerses > 0) '${purana.totalVerses} पृष्ठे',
    ].join('  ·  ');

    return _Pressable(
      onTap: () {
        // Save last read record
        ref.read(granthLastReadProvider.notifier).save(
          bookSlug: purana.slug,
          bookTitle: title,
          bookSubtitle: subtitle,
          pdfUrl: purana.pdfUrl,
          pageNumber: 1,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GranthChapterListScreen(book: purana),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: _G.card,
          borderRadius: BorderRadius.circular(_G.radiusCard),
          boxShadow: _G.shadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_G.radiusCard),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: style.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _GlassTile(
                          size: 42,
                          radius: 21,
                          child: Text(
                            style.emblem,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const Spacer(),
                        _GlassChip(
                          icon: Icons.picture_as_pdf_rounded,
                          label: langCode == 'hi' ? 'सचित्र' : (langCode == 'en' ? 'Illustrated' : 'सचित्र'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      style.deityFor(langCode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.mukta(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        style.tagFor(langCode),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mukta(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: MandirTheme.primarySaffron,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mukta(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: MandirTheme.textDark,
                          height: 1.25,
                          letterSpacing: _track(langCode, -0.2),
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.mukta(
                            fontSize: 13,
                            color: MandirTheme.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const Spacer(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.mukta(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: MandirTheme.textMuted,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: MandirTheme.primarySaffron,
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
      ),
    );
  }

  // ── Empty / Error State ────────────────────────────────────────────────────
  Widget _buildStatusMessage({
    required IconData icon,
    required String title,
    required String langCode,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: _G.fill,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: MandirTheme.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: MandirTheme.textDark,
                height: 1.35,
                letterSpacing: _track(langCode, -0.2),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              _Pressable(
                scale: 0.95,
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: const ShapeDecoration(
                    color: MandirTheme.primarySaffron,
                    shape: StadiumBorder(),
                  ),
                  child: Text(
                    actionLabel,
                    style: GoogleFonts.mukta(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Scales down on touch-down and back on release. The animation retargets
/// from the current scale, so it can be interrupted mid-flight.
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    required this.onTap,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scale;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedOpacity(
          opacity: reduceMotion && _pressed ? 0.7 : 1,
          duration: AppMotion.press,
          curve: AppMotion.easeOut,
          child: AnimatedScale(
            scale: !reduceMotion && _pressed ? widget.scale : 1,
            duration: AppMotion.press,
            curve: AppMotion.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Square or circular translucent tile that sits on a gradient cover.
class _GlassTile extends StatelessWidget {
  const _GlassTile({required this.size, required this.radius, required this.child});

  final double size;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.32), width: 1),
      ),
      child: child,
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: ShapeDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: GoogleFonts.mukta(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TintChip extends StatelessWidget {
  const _TintChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: ShapeDecoration(
        color: MandirTheme.primarySaffron.withValues(alpha: 0.1),
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: GoogleFonts.mukta(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: MandirTheme.primarySaffron,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Gradient tile carrying a scripture's emblem.
class _EmblemTile extends StatelessWidget {
  const _EmblemTile({
    required this.style,
    required this.size,
    required this.radius,
    required this.emblemSize,
  });

  final GranthStyleConfig style;
  final double size;
  final double radius;
  final double emblemSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: style.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(style.emblem, style: TextStyle(fontSize: emblemSize)),
    );
  }
}

/// Pinned bar that becomes a translucent material once content scrolls
/// beneath it, with a hairline edge only while it overlaps content.
class _PinnedBarDelegate extends SliverPersistentHeaderDelegate {
  _PinnedBarDelegate({
    required this.extent,
    required this.child,
    required this.solid,
  });

  final double extent;
  final Widget child;
  final bool solid;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final floating = (shrinkOffset > 0 || overlapsContent) && !solid;
    final overlapping = shrinkOffset > 0 || overlapsContent;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: floating ? 20 : 0,
          sigmaY: floating ? 20 : 0,
        ),
        child: AnimatedContainer(
          duration: AppMotion.state,
          curve: AppMotion.ease,
          decoration: BoxDecoration(
            color: MandirTheme.backgroundCream.withValues(alpha: floating ? 0.82 : 1),
          ),
          foregroundDecoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: overlapping ? _G.hairline : Colors.transparent,
                width: 0.5,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedBarDelegate oldDelegate) => true;
}

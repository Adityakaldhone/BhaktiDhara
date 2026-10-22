import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/granth.dart';
import '../providers/granth_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/remote_config_provider.dart';
import '../widgets/granth_meta.dart';
import '../widgets/premium_blurred_gate.dart';
import 'granth_chapter_list_screen.dart';
import 'granth_pothi_reader_screen.dart';

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
              // ── Header Bar ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildHeader(context, ref, langCode, isVip),
              ),

              // ── Search & Filter Input ───────────────────────────────────
              SliverToBoxAdapter(
                child: _buildSearchBar(langCode),
              ),

              // ── Continue Reading (वाचन सुरू ठेवा) Card ───────────────────
              if (lastRead != null && _searchQuery.isEmpty)
                SliverToBoxAdapter(
                  child: _buildContinueReadingCard(context, ref, lastRead, langCode),
                ),

              // ── Category Filter Tabs ────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildCategoryPills(langCode),
              ),

              // ── Books Content ───────────────────────────────────────────
              booksAsync.when(
                data: (books) {
                  if (books.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          langCode == 'hi'
                              ? 'कोई ग्रंथ उपलब्ध नहीं है।'
                              : (langCode == 'en'
                                  ? 'No scriptures available.'
                                  : 'कोणतेही ग्रंथ उपलब्ध नाहीत.'),
                          style: GoogleFonts.mukta(
                            fontSize: 16,
                            color: MandirTheme.textMuted,
                          ),
                        ),
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
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: MandirTheme.textMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                langCode == 'hi'
                                    ? '"$_searchQuery" के लिए कोई ग्रंथ नहीं मिला'
                                    : (langCode == 'en'
                                        ? 'No scriptures found for "$_searchQuery"'
                                        : '"$_searchQuery" साठी कोणतेही ग्रंथ सापडले नाहीत'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.mukta(
                                  fontSize: 16,
                                  color: MandirTheme.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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
                          ),
                        ...canonicalBooks.map(
                          (book) => _buildCanonicalHeroCard(context, ref, book, langCode, isVip),
                        ),
                        const SizedBox(height: 16),
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
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: _buildPuranasGrid(context, ref, mahapuranas, langCode, isVip),
                        ),
                        const SizedBox(height: 20),
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
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: _buildPuranasGrid(context, ref, upapuranas, langCode, isVip),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ]),
                  );
                },
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: MandirTheme.primarySaffron,
                    ),
                  ),
                ),
                error: (err, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: MandirTheme.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          langCode == 'hi'
                              ? 'ग्रंथ सूची लोड नहीं हो सकी'
                              : (langCode == 'en'
                                  ? 'Failed to load scriptures'
                                  : 'ग्रंथ यादी लोड होऊ शकली नाही'),
                          style: GoogleFonts.mukta(
                            fontSize: 16,
                            color: MandirTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.invalidate(granthBooksProvider),
                          child: Text(
                            langCode == 'hi' ? 'पुनः प्रयास करें' : (langCode == 'en' ? 'Retry' : 'पुन्हा प्रयत्न करा'),
                            style: GoogleFonts.mukta(
                              fontWeight: FontWeight.bold,
                              color: MandirTheme.primarySaffron,
                            ),
                          ),
                        ),
                      ],
                    ),
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

  // ── Header Bar ─────────────────────────────────────────────────────────────
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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6A1A00), // Deep Vedic Terracotta
            Color(0xFF8B2500),
            Color(0xFFD84315), // Vibrant Saffron
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD84315).withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFFFFE082),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      style: GoogleFonts.mukta(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.15,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      style: GoogleFonts.mukta(
                        fontSize: 13,
                        color: const Color(0xFFFFE082),
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // VIP / Free Chapter Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isVip
                  ? const Color(0xFFFFE082).withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isVip
                    ? const Color(0xFFFFD54F).withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isVip ? Icons.workspace_premium_rounded : Icons.menu_book_rounded,
                  color: isVip ? const Color(0xFFFFD54F) : const Color(0xFFFFE082),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isVip
                        ? (langCode == 'hi'
                            ? 'प्रीमियम सक्रिय • सभी १८ महापुराण व अध्याय खुले हैं'
                            : (langCode == 'en'
                                ? 'VIP Active • All 18 Mahapuranas & scriptures unlocked'
                                : 'प्रीमियम सक्रिय • सर्व १८ महापुराणे व अध्याय अनलॉक आहेत'))
                        : (langCode == 'hi'
                            ? 'संपूर्ण १८ महापुराण व अध्याय वाचनासाठी उपलब्ध'
                            : (langCode == 'en'
                                ? 'All 18 Mahapuranas & Sacred Scriptures Available'
                                : 'सर्व १८ महापुराणे व ग्रंथ वाचनासाठी उपलब्ध आहेत')),
                    style: GoogleFonts.mukta(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (!isVip)
                  GestureDetector(
                    onTap: () => showPremiumPaywallSheet(context, ref, langCode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        langCode == 'hi' ? 'अनलॉक' : (langCode == 'en' ? 'Unlock' : 'अनलॉक'),
                        style: GoogleFonts.mukta(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5D1D00),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar(String langCode) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MandirTheme.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
          });
        },
        style: GoogleFonts.mukta(
          fontSize: 15,
          color: MandirTheme.textDark,
        ),
        decoration: InputDecoration(
          hintText: langCode == 'hi'
              ? 'ग्रंथ, पुराण किंवा अध्याय शोधा...'
              : (langCode == 'en'
                  ? 'Search scriptures, puranas or deities...'
                  : 'ग्रंथ, पुराण किंवा अध्याय शोधा...'),
          hintStyle: GoogleFonts.mukta(
            fontSize: 14,
            color: MandirTheme.textMuted,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: MandirTheme.primarySaffron,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: MandirTheme.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF8E7),
            const Color(0xFFFFF0D0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2B04F),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD84315).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Glowing emblem badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: style.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: style.gradientColors.first.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      style.emblem,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: MandirTheme.primarySaffron.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              langCode == 'hi'
                                  ? 'वाचन चालू ठेवा'
                                  : (langCode == 'en' ? 'Continue Reading' : 'वाचन सुरू ठेवा'),
                              style: GoogleFonts.mukta(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: MandirTheme.primarySaffron,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.bookTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mukta(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: MandirTheme.textDark,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        detailText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mukta(
                          fontSize: 13,
                          color: MandirTheme.textMuted,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MandirTheme.primarySaffron,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Category Filter Pills ──────────────────────────────────────────────────
  Widget _buildCategoryPills(String langCode) {
    final categories = [
      {'key': 'all', 'label': langCode == 'hi' ? '🌟 सर्व' : (langCode == 'en' ? '🌟 All' : '🌟 सर्व')},
      {
        'key': 'canonical',
        'label': langCode == 'hi' ? '📖 प्रमुख ग्रंथ' : (langCode == 'en' ? '📖 Canonical' : '📖 प्रमुख ग्रंथ'),
      },
      {
        'key': 'mahapurana',
        'label': langCode == 'hi' ? '🔱 १८ महापुराण' : (langCode == 'en' ? '🔱 18 Mahapuranas' : '🔱 १८ महापुराणे'),
      },
      {
        'key': 'upapurana',
        'label': langCode == 'hi' ? '📜 उपपुराण व संहिता' : (langCode == 'en' ? '📜 Upapuranas' : '📜 उपपुराणे व संहिता'),
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                cat['label']!,
                style: GoogleFonts.mukta(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : MandirTheme.textDark,
                ),
              ),
              backgroundColor: MandirTheme.surfaceWhite,
              selectedColor: MandirTheme.primarySaffron,
              checkmarkColor: Colors.white,
              showCheckmark: false,
              side: BorderSide(
                color: isSelected ? MandirTheme.primarySaffron : MandirTheme.cardBorder,
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              onSelected: (_) {
                setState(() {
                  _selectedCategory = cat['key']!;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Section Title ──────────────────────────────────────────────────────────
  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    required String badge,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.mukta(
                        fontSize: 18.5,
                        fontWeight: FontWeight.bold,
                        color: MandirTheme.textDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: MandirTheme.primarySaffron.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.mukta(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: MandirTheme.primarySaffron,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.mukta(
                    fontSize: 12.5,
                    color: MandirTheme.textMuted,
                  ),
                ),
              ],
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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2B04F).withValues(alpha: 0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: style.gradientColors.first.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GranthChapterListScreen(book: book),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Emblem + Deity Title + Tag
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: style.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: style.gradientColors.first.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          style.emblem,
                          style: TextStyle(
                            fontSize: isGita ? 28 : 26,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: GoogleFonts.mukta(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: MandirTheme.textDark,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  langCode == 'hi' ? 'मूल ग्रंथ' : (langCode == 'en' ? 'Canonical' : 'मूळ ग्रंथ'),
                                  style: GoogleFonts.mukta(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            style.tagFor(langCode),
                            style: GoogleFonts.mukta(
                              fontSize: 13,
                              color: MandirTheme.primarySaffron,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Mantra / Shloka highlight bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9EE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFE082).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    style.mantra,
                    style: GoogleFonts.mukta(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF6B1B0B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Subtitle / Description
                Text(
                  subtitle.isNotEmpty ? subtitle : description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.mukta(
                    fontSize: 13,
                    color: MandirTheme.textMuted,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 14),

                // Bottom Badges & Actions
                Row(
                  children: [
                    // Chapter badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: MandirTheme.chipBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: MandirTheme.chipBorder),
                      ),
                      child: Text(
                        isDasbodh
                            ? (langCode == 'hi' ? '${book.totalChapters} दशक' : (langCode == 'en' ? '${book.totalChapters} Dashakas' : '${book.totalChapters} दशक'))
                            : (langCode == 'hi' ? '${book.totalChapters} अध्याय' : (langCode == 'en' ? '${book.totalChapters} Chapters' : '${book.totalChapters} अध्याय')),
                        style: GoogleFonts.mukta(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: MandirTheme.chipText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Verses badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: MandirTheme.chipBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: MandirTheme.chipBorder),
                      ),
                      child: Text(
                        isDasbodh
                            ? (langCode == 'hi' ? '${book.totalVerses} ओव्या' : (langCode == 'en' ? '${book.totalVerses} Ovis' : '${book.totalVerses} ओव्या'))
                            : (langCode == 'hi' ? '${book.totalVerses} श्लोक' : (langCode == 'en' ? '${book.totalVerses} Verses' : '${book.totalVerses} श्लोक')),
                        style: GoogleFonts.mukta(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: MandirTheme.chipText,
                        ),
                      ),
                    ),

                    if (isDasbodh) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD84315).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          langCode == 'hi' ? 'सचित्र पोथी' : (langCode == 'en' ? 'Pothi' : 'सचित्र पोथी'),
                          style: GoogleFonts.mukta(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD84315),
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Read CTA
                    Row(
                      children: [
                        Text(
                          langCode == 'hi' ? 'अध्याय सूची' : (langCode == 'en' ? 'Read' : 'अध्याय सूची'),
                          style: GoogleFonts.mukta(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: MandirTheme.primarySaffron,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: MandirTheme.primarySaffron,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 18 Mahapuranas Grid (2-Column Devotional Grid) ──────────────────────────
  Widget _buildPuranasGrid(
    BuildContext context,
    WidgetRef ref,
    List<GranthBook> puranas,
    String langCode,
    bool isVip,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: puranas.map((purana) {
            return SizedBox(
              width: cardWidth,
              child: _buildPuranaCard(context, ref, purana, langCode, isVip),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Individual Purana Card (Exquisite Sacred Vedic Styling) ──────────────────
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

    return Container(
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2B04F).withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Gradient Banner with Emblem & Tag
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: style.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    // Glowing circular emblem
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          style.emblem,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            style.deityFor(langCode),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.mukta(
                              fontSize: 11.5,
                              color: const Color(0xFFFFE082),
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            style.tagFor(langCode),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.mukta(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Card Body
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Purana Title
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.mukta(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: MandirTheme.textDark,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Subtitle / Narrative highlight
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.mukta(
                        fontSize: 11.5,
                        color: MandirTheme.textMuted,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Badges row: Chapters + Pages
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (purana.totalChapters > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: MandirTheme.chipBackground,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: MandirTheme.chipBorder),
                            ),
                            child: Text(
                              '${purana.totalChapters} अध्याय',
                              style: GoogleFonts.mukta(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: MandirTheme.chipText,
                              ),
                            ),
                          ),
                        if (purana.totalVerses > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: MandirTheme.chipBackground,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: MandirTheme.chipBorder),
                            ),
                            child: Text(
                              '${purana.totalVerses} पृष्ठे',
                              style: GoogleFonts.mukta(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: MandirTheme.chipText,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD84315).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.picture_as_pdf_rounded, size: 10, color: Color(0xFFD84315)),
                              const SizedBox(width: 3),
                              Text(
                                langCode == 'hi' ? 'सचित्र' : (langCode == 'en' ? 'Illustrated' : 'सचित्र'),
                                style: GoogleFonts.mukta(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFD84315),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Action: Read button
                    Row(
                      children: [
                        Text(
                          langCode == 'hi' ? 'वाचन करें' : (langCode == 'en' ? 'Read' : 'वाचन करा'),
                          style: GoogleFonts.mukta(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: MandirTheme.primarySaffron,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: MandirTheme.primarySaffron,
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
    );
  }
}

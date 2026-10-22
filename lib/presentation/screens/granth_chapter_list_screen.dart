import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/granth.dart';
import '../providers/granth_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/remote_config_provider.dart';
import '../widgets/granth_meta.dart';
import '../widgets/premium_blurred_gate.dart';
import 'granth_pothi_reader_screen.dart';
import 'granth_reader_screen.dart';

class GranthChapterListScreen extends ConsumerStatefulWidget {
  final GranthBook book;

  const GranthChapterListScreen({
    super.key,
    required this.book,
  });

  @override
  ConsumerState<GranthChapterListScreen> createState() => _GranthChapterListScreenState();
}

class _GranthChapterListScreenState extends ConsumerState<GranthChapterListScreen> {
  final TextEditingController _chapterSearchController = TextEditingController();
  String _chapterQuery = '';

  @override
  void dispose() {
    _chapterSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(granthChaptersProvider(widget.book.slug));
    final langCode = ref.watch(localeProvider).languageCode;
    final isVip = ref.watch(premiumAccessProvider);
    final bookTitle = widget.book.titleFor(langCode);
    final style = getGranthStyle(widget.book.slug);

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      appBar: AppBar(
        title: Text(
          bookTitle,
          style: GoogleFonts.mukta(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: MandirTheme.textDark,
          ),
        ),
        actions: [
          if (!isVip)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: () => showPremiumPaywallSheet(context, ref, langCode),
                icon: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFD84315),
                  size: 20,
                ),
                label: Text(
                  langCode == 'hi' ? 'प्रीमियम' : (langCode == 'en' ? 'VIP' : 'प्रीमियम'),
                  style: GoogleFonts.mukta(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD84315),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: chaptersAsync.when(
        data: (chapters) {
          // If book has no chapter entries (18 Mahapuranas & Upapuranas)
          if (chapters.isEmpty) {
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildSacredCoverBanner(context, ref, langCode, isVip, style, hasChapters: false),
                const SizedBox(height: 16),
                _buildPuranaDetailSection(context, ref, langCode, isVip, style),
              ],
            );
          }

          // Filter chapters if search query is active
          final filteredChapters = chapters.where((c) {
            if (_chapterQuery.isEmpty) return true;
            final q = _chapterQuery.toLowerCase();
            final name = c.nameFor(langCode).toLowerCase();
            final numStr = '${c.chapterNumber}';
            return name.contains(q) || numStr == q;
          }).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    children: [
                      _buildSacredCoverBanner(context, ref, langCode, isVip, style, hasChapters: true),
                      const SizedBox(height: 12),
                      _buildChapterSearchBar(langCode),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Chapter list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // Subscription CTA teaser after chapter 1 for non-VIP
                      if (!isVip && index == 1 && _chapterQuery.isEmpty) {
                        return Column(
                          children: [
                            _buildSubscriptionCta(context, ref, langCode),
                            const SizedBox(height: 12),
                            _buildChapterTile(
                              context,
                              ref,
                              filteredChapters[index],
                              isVip || filteredChapters[index].isFree,
                              langCode,
                              allChapters: chapters,
                            ),
                          ],
                        );
                      }

                      final chapter = filteredChapters[index];
                      final isUnlocked = isVip || chapter.isFree;

                      return _buildChapterTile(
                        context,
                        ref,
                        chapter,
                        isUnlocked,
                        langCode,
                        allChapters: chapters,
                      );
                    },
                    childCount: filteredChapters.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 36),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: MandirTheme.primarySaffron,
          ),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: MandirTheme.textMuted,
              ),
              const SizedBox(height: 10),
              Text(
                langCode == 'hi'
                    ? 'अध्याय लोड करने में समस्या'
                    : (langCode == 'en'
                        ? 'Failed to load chapters'
                        : 'अध्याय लोड करताना समस्या आली'),
                style: GoogleFonts.mukta(
                  fontSize: 16,
                  color: MandirTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(granthChaptersProvider(widget.book.slug)),
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
    );
  }

  // ── Sacred Cover Banner ───────────────────────────────────────────────────
  Widget _buildSacredCoverBanner(
    BuildContext context,
    WidgetRef ref,
    String langCode,
    bool isVip,
    GranthStyleConfig style, {
    required bool hasChapters,
  }) {
    final title = widget.book.titleFor(langCode);
    final subtitle = widget.book.subtitleFor(langCode);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: style.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: style.gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sacred deity disc
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFD54F),
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
                child: Center(
                  child: Text(
                    style.emblem,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        style.deityFor(langCode),
                        style: GoogleFonts.mukta(
                          fontSize: 12,
                          color: const Color(0xFFFFE082),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: GoogleFonts.mukta(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.mukta(
                          fontSize: 12.5,
                          color: const Color(0xFFFFE082),
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Mantra quote bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Text(
              style.mantra,
              style: GoogleFonts.mukta(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: const Color(0xFFFFE082),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Badges row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (widget.book.totalChapters > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.book.slug == 'dasbodh'
                        ? '${widget.book.totalChapters} दशक'
                        : '${widget.book.totalChapters} अध्याय',
                    style: GoogleFonts.mukta(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (widget.book.totalVerses > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasChapters
                        ? (widget.book.slug == 'dasbodh' ? '${widget.book.totalVerses} ओव्या' : '${widget.book.totalVerses} श्लोक')
                        : '${widget.book.totalVerses} पृष्ठे (सचित्र)',
                    style: GoogleFonts.mukta(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.5)),
                ),
                child: Text(
                  langCode == 'hi' ? 'सचित्र मूळ प्रत' : (langCode == 'en' ? 'Original Edition' : 'सचित्र मूळ प्रत'),
                  style: GoogleFonts.mukta(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD54F),
                  ),
                ),
              ),
            ],
          ),

          if (widget.book.slug == 'dasbodh') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD54F),
                  side: const BorderSide(color: Color(0xFFFFD54F), width: 1.2),
                  backgroundColor: Colors.black.withValues(alpha: 0.25),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ref.read(granthLastReadProvider.notifier).save(
                    bookSlug: widget.book.slug,
                    bookTitle: widget.book.titleFor(langCode),
                    isPothi: true,
                    pageNumber: 1,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GranthPothiReaderScreen(book: widget.book),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_stories_rounded, size: 20),
                label: Text(
                  langCode == 'hi'
                      ? 'सचित्र हस्तलिखित पोथी वाचन (६३८ पृष्ठ)'
                      : (langCode == 'en'
                          ? 'Illustrated Pothi Manuscript (638 Pages)'
                          : 'सचित्र हस्तलिखित पोथी वाचन (६३८ पृष्ठे)'),
                  style: GoogleFonts.mukta(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }


  // ── Chapter Search Bar ─────────────────────────────────────────────────────
  Widget _buildChapterSearchBar(String langCode) {
    return Container(
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MandirTheme.cardBorder),
      ),
      child: TextField(
        controller: _chapterSearchController,
        onChanged: (val) {
          setState(() {
            _chapterQuery = val.trim();
          });
        },
        style: GoogleFonts.mukta(
          fontSize: 14.5,
          color: MandirTheme.textDark,
        ),
        decoration: InputDecoration(
          hintText: langCode == 'hi' ? 'अध्याय शोधा...' : (langCode == 'en' ? 'Search chapter...' : 'अध्याय शोधा...'),
          hintStyle: GoogleFonts.mukta(
            fontSize: 13.5,
            color: MandirTheme.textMuted,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: MandirTheme.primarySaffron,
            size: 20,
          ),
          suffixIcon: _chapterQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16, color: MandirTheme.textMuted),
                  onPressed: () {
                    _chapterSearchController.clear();
                    setState(() {
                      _chapterQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
    );
  }

  // ── Purana Detail Section (For 18 Mahapuranas with Illustrated Edition) ─────
  Widget _buildPuranaDetailSection(
    BuildContext context,
    WidgetRef ref,
    String langCode,
    bool isVip,
    GranthStyleConfig style,
  ) {
    final title = widget.book.titleFor(langCode);
    final description = widget.book.descriptionFor(langCode);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2B04F).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Highlights header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MandirTheme.primarySaffron.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: MandirTheme.primarySaffron,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langCode == 'hi'
                          ? 'संपूर्ण पावन महापुराण ग्रंथ'
                          : (langCode == 'en' ? 'Complete Sacred Scripture' : 'संपूर्ण पावन महापुराण ग्रंथ'),
                      style: GoogleFonts.mukta(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: MandirTheme.textDark,
                      ),
                    ),
                    Text(
                      style.tagFor(langCode),
                      style: GoogleFonts.mukta(
                        fontSize: 13,
                        color: MandirTheme.primarySaffron,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Description
          Text(
            description,
            style: GoogleFonts.mukta(
              fontSize: 14,
              color: MandirTheme.textDark,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 16),

          // Features List (Illustrated, zoom, offline)
          _buildPuranaFeatureItem(
            Icons.menu_book_rounded,
            langCode == 'hi' ? 'सचित्र मूल हस्तलिखित रूप' : (langCode == 'en' ? 'Original Illustrated Edition' : 'सचित्र मूळ हस्तलिखित स्वरूप'),
            langCode == 'hi' ? 'उच्च गुणवत्ता स्पष्ट पृष्ठ' : (langCode == 'en' ? 'High definition crystal clear pages' : 'उच्च गुणवत्ता स्पष्ट पृष्ठे'),
          ),
          const SizedBox(height: 10),
          _buildPuranaFeatureItem(
            Icons.zoom_in_rounded,
            langCode == 'hi' ? 'झूम एवं फुलस्क्रीन वाचन' : (langCode == 'en' ? 'Pinch-to-zoom & Fullscreen' : 'झूम व फुलस्क्रीन वाचन सुविधा'),
            langCode == 'hi' ? 'प्रत्येक श्लोक व कथा सुस्पष्ट वाचा' : (langCode == 'en' ? 'Read every verse with clarity' : 'प्रत्येक श्लोक व कथा सुस्पष्ट वाचा'),
          ),
          const SizedBox(height: 10),
          _buildPuranaFeatureItem(
            Icons.bookmark_added_rounded,
            langCode == 'hi' ? 'वाचन प्रगती व बुकमार्क' : (langCode == 'en' ? 'Progress Tracking & Bookmark' : 'वाचन प्रगती व बुकमार्क'),
            langCode == 'hi' ? 'जिथून सोडले तिथून पुढे वाचा' : (langCode == 'en' ? 'Resume where you left off' : 'जिथून सोडले तिथून पुढे वाचा'),
          ),

          const SizedBox(height: 20),

          // Primary Read Action
          if (widget.book.pdfUrl != null && widget.book.pdfUrl!.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MandirTheme.primarySaffron,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
                onPressed: () async {
                  // Save last read record
                  ref.read(granthLastReadProvider.notifier).save(
                    bookSlug: widget.book.slug,
                    bookTitle: title,
                    pdfUrl: widget.book.pdfUrl,
                    pageNumber: 1,
                  );

                  final uri = Uri.parse(widget.book.pdfUrl!);
                  try {
                    final launched = await launchUrl(
                      uri,
                      mode: LaunchMode.inAppBrowserView,
                    );
                    if (!launched) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  } catch (_) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_stories_rounded, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      langCode == 'hi'
                          ? 'पावन महापुराण वाचन प्रारंभ करें'
                          : (langCode == 'en'
                              ? 'Begin Sacred Reading'
                              : 'पावन महापुराण वाचन सुरू करा'),
                      style: GoogleFonts.mukta(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPuranaFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: MandirTheme.chipBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: MandirTheme.chipBorder),
          ),
          child: Icon(icon, size: 18, color: MandirTheme.primarySaffron),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.mukta(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: MandirTheme.textDark,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.mukta(
                  fontSize: 12,
                  color: MandirTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Chapter Tile ───────────────────────────────────────────────────────────
  Widget _buildChapterTile(
    BuildContext context,
    WidgetRef ref,
    GranthChapter chapter,
    bool isUnlocked,
    String langCode, {
    required List<GranthChapter> allChapters,
  }) {
    final chapterName = chapter.nameFor(langCode);
    final summary = chapter.summaryFor(langCode);
    final isDasbodh = widget.book.slug == 'dasbodh';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? MandirTheme.cardBorder
              : Colors.amber.shade200.withValues(alpha: 0.6),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!isUnlocked) {
              showPremiumPaywallSheet(context, ref, langCode);
              return;
            }

            // Save last read
            ref.read(granthLastReadProvider.notifier).save(
              bookSlug: widget.book.slug,
              bookTitle: widget.book.titleFor(langCode),
              chapterNumber: chapter.chapterNumber,
              chapterTitle: chapterName,
              verseNumber: 1,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GranthReaderScreen(
                  book: widget.book,
                  chapter: chapter,
                  allChapters: allChapters,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chapter Number Circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? MandirTheme.primarySaffron.withValues(alpha: 0.1)
                        : Colors.amber.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUnlocked
                          ? MandirTheme.primarySaffron.withValues(alpha: 0.4)
                          : Colors.amber.shade400,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${chapter.chapterNumber}',
                      style: GoogleFonts.mukta(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? MandirTheme.primarySaffron
                            : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Chapter Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chapterName,
                              style: GoogleFonts.mukta(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: MandirTheme.textDark,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (isUnlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: chapter.isFree ? Colors.green.shade50 : Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                chapter.isFree
                                    ? (langCode == 'hi' ? 'निःशुल्क' : (langCode == 'en' ? 'Free' : 'मोफत'))
                                    : 'VIP',
                                style: GoogleFonts.mukta(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: chapter.isFree ? Colors.green.shade800 : Colors.amber.shade900,
                                ),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () => showPremiumPaywallSheet(context, ref, langCode),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B1D18), Color(0xFFE65100)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.lock_rounded, size: 12, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      langCode == 'hi' ? 'अनलॉक' : (langCode == 'en' ? 'Unlock' : 'अनलॉक'),
                                      style: GoogleFonts.mukta(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isDasbodh
                            ? '${chapter.versesCount} ओव्या'
                            : '${chapter.versesCount} श्लोक',
                        style: GoogleFonts.mukta(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: MandirTheme.primarySaffron,
                        ),
                      ),
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.mukta(
                            fontSize: 13,
                            color: MandirTheme.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ],
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

  // ── Subscription CTA Teaser ────────────────────────────────────────────────
  Widget _buildSubscriptionCta(
    BuildContext context,
    WidgetRef ref,
    String langCode,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5D1D00), Color(0xFF8B2500), Color(0xFFD84315)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD84315).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFD54F),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  langCode == 'hi'
                      ? 'संपूर्ण अध्याय अनलॉक करें'
                      : (langCode == 'en' ? 'Unlock All Chapters' : 'सर्व अध्याय अनलॉक करा'),
                  style: GoogleFonts.mukta(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                Text(
                  langCode == 'hi'
                      ? 'प्रीमियम में सभी अध्याय व १८ महापुराण उपलब्ध हैं'
                      : (langCode == 'en'
                          ? 'Get lifetime access to all sacred scriptures'
                          : 'प्रीमियममध्ये सर्व अध्याय व १८ महापुराणे उपलब्ध आहेत'),
                  style: GoogleFonts.mukta(
                    fontSize: 12,
                    color: const Color(0xFFFFE082),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD54F),
              foregroundColor: const Color(0xFF5D1D00),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => showPremiumPaywallSheet(context, ref, langCode),
            child: Text(
              langCode == 'hi' ? 'अनलॉक' : (langCode == 'en' ? 'Join' : 'अनलॉक'),
              style: GoogleFonts.mukta(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

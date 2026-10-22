import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/granth.dart';
import '../providers/granth_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/remote_config_provider.dart';
import '../widgets/premium_blurred_gate.dart';

class GranthReaderScreen extends ConsumerStatefulWidget {
  final GranthBook book;
  final GranthChapter chapter;
  final List<GranthChapter> allChapters;

  const GranthReaderScreen({
    super.key,
    required this.book,
    required this.chapter,
    required this.allChapters,
  });

  @override
  ConsumerState<GranthReaderScreen> createState() => _GranthReaderScreenState();
}

class _GranthReaderScreenState extends ConsumerState<GranthReaderScreen> {
  late int _currentChapterNumber;
  final ScrollController _scrollController = ScrollController();
  final Set<int> _expandedTransliterations = {};
  final Set<int> _expandedWordMeanings = {};

  @override
  void initState() {
    super.initState();
    _currentChapterNumber = widget.chapter.chapterNumber;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GranthChapter _getCurrentChapter() {
    return widget.allChapters.firstWhere(
      (c) => c.chapterNumber == _currentChapterNumber,
      orElse: () => widget.chapter,
    );
  }

  void _goToChapter(int chNum) {
    if (chNum < 1 || chNum > widget.allChapters.length) return;
    final isVip = ref.read(premiumAccessProvider);
    final targetCh = widget.allChapters.firstWhere(
      (c) => c.chapterNumber == chNum,
      orElse: () => widget.chapter,
    );
    if (!isVip && !targetCh.isFree) {
      showPremiumPaywallSheet(
        context,
        ref,
        ref.read(localeProvider).languageCode,
      );
      return;
    }
    setState(() {
      _currentChapterNumber = chNum;
      _expandedTransliterations.clear();
      _expandedWordMeanings.clear();
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = ref.watch(localeProvider).languageCode;
    final selectedLang = ref.watch(granthTranslationLangProvider);
    final fontSize = ref.watch(granthFontSizeProvider);

    final query = (slug: widget.book.slug, chapterNum: _currentChapterNumber);
    final detailAsync = ref.watch(granthChapterDetailProvider(query));
    final currentCh = _getCurrentChapter();
    final chTitle = currentCh.nameFor(langCode);

    // Save reading progress in post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(granthLastReadProvider.notifier).save(
          bookSlug: widget.book.slug,
          bookTitle: widget.book.titleFor(langCode),
          chapterNumber: _currentChapterNumber,
          chapterTitle: chTitle,
          verseNumber: 1,
        );
      }
    });

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.book.titleFor(langCode),
              style: GoogleFonts.mukta(
                fontSize: 13,
                color: MandirTheme.primarySaffron,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'अध्याय $_currentChapterNumber: $chTitle',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.mukta(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: MandirTheme.textDark,
              ),
            ),
          ],
        ),
        actions: [
          // 1-Tap Quick Font Zoom Cycle (A / A+ / A++)
          IconButton(
            tooltip: 'फॉन्ट आकार झूम (Font Scale)',
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: MandirTheme.primarySaffron.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: MandirTheme.primarySaffron.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                fontSize <= 16.0 ? 'A' : (fontSize <= 20.0 ? 'A+' : 'A++'),
                style: GoogleFonts.mukta(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: MandirTheme.primarySaffron,
                ),
              ),
            ),
            onPressed: () {
              final next = fontSize <= 16.0 ? 20.0 : (fontSize <= 20.0 ? 24.0 : 16.0);
              ref.read(granthFontSizeProvider.notifier).state = next;
            },
          ),

          // Granular Font Size Slider Dialog
          IconButton(
            tooltip: 'फॉन्ट आकार निवडा',
            icon: const Icon(Icons.format_size_rounded, size: 21),
            onPressed: () => _showFontSizeDialog(context),
          ),

          // Language Selector Popup
          PopupMenuButton<String>(
            tooltip: 'भाषा बदला (Translation)',
            icon: const Icon(Icons.translate_rounded, size: 21),
            initialValue: selectedLang,
            onSelected: (val) {
              ref.read(granthTranslationLangProvider.notifier).state = val;
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mr',
                child: Row(
                  children: [
                    if (selectedLang == 'mr') const Icon(Icons.check_rounded, size: 16, color: MandirTheme.primarySaffron),
                    const SizedBox(width: 8),
                    Text('मराठी भावार्थ', style: GoogleFonts.mukta(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'hi',
                child: Row(
                  children: [
                    if (selectedLang == 'hi') const Icon(Icons.check_rounded, size: 16, color: MandirTheme.primarySaffron),
                    const SizedBox(width: 8),
                    Text('हिंदी भावार्थ', style: GoogleFonts.mukta(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    if (selectedLang == 'en') const Icon(Icons.check_rounded, size: 16, color: MandirTheme.primarySaffron),
                    const SizedBox(width: 8),
                    Text('English Meaning', style: GoogleFonts.mukta(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('माहिती उपलब्ध नाही'));
          }

          final verses = detail.verses;
          final isLocked = detail.isLocked;

          return CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Chapter Banner Header ──────────────────────────────────
              SliverToBoxAdapter(
                child: _buildChapterBanner(detail, langCode),
              ),

              // ── Verses List ────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final verse = verses[index];
                      return _buildVerseCard(
                        context,
                        verse,
                        detail.chapterNumber,
                        selectedLang,
                        fontSize,
                      );
                    },
                    childCount: verses.length,
                  ),
                ),
              ),

              // ── Paywall locked gate (if chapter is locked) ──────────────
              if (isLocked)
                SliverToBoxAdapter(
                  child: _buildPaywallGate(context, ref, langCode, detail),
                ),

              // ── Chapter Navigation Bar (Prev / Next) ────────────────────
              SliverToBoxAdapter(
                child: _buildBottomNav(langCode),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 48),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: MandirTheme.primarySaffron),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 40, color: MandirTheme.textMuted),
              const SizedBox(height: 10),
              Text(
                'श्लोक लोड करता आले नाहीत',
                style: GoogleFonts.mukta(fontSize: 16, color: MandirTheme.textDark),
              ),
              TextButton(
                onPressed: () => ref.invalidate(granthChapterDetailProvider(query)),
                child: Text(
                  'पुन्हा प्रयत्न करा',
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

  // ── Chapter Banner ─────────────────────────────────────────────────────────
  Widget _buildChapterBanner(GranthChapterDetail detail, String langCode) {
    final summary = detail.chapterSummaryFor(langCode);
    final chName = detail.chapterNameFor(langCode);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MandirTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: MandirTheme.primarySaffron.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'अध्याय $_currentChapterNumber',
                  style: GoogleFonts.mukta(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: MandirTheme.primarySaffron,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  chName,
                  style: GoogleFonts.mukta(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: MandirTheme.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: MandirTheme.chipBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MandirTheme.chipBorder),
                ),
                child: Text(
                  '${detail.totalVerses} श्लोक',
                  style: GoogleFonts.mukta(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: MandirTheme.chipText,
                  ),
                ),
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              summary,
              style: GoogleFonts.mukta(
                fontSize: 13.5,
                color: MandirTheme.textMuted,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Verse Card (Opulent Vedic Styling) ─────────────────────────────────────
  Widget _buildVerseCard(
    BuildContext context,
    GranthVerse verse,
    int chapterNumber,
    String selectedLang,
    double fontSize,
  ) {
    final vNum = verse.verseNumber;
    final meaning = verse.meaningFor(selectedLang);
    final hasTranslit = verse.transliteration.isNotEmpty;
    final hasWordMeanings = verse.wordMeanings.isNotEmpty;
    final isTranslitExpanded = _expandedTransliterations.contains(vNum);
    final isWordMeaningsExpanded = _expandedWordMeanings.contains(vNum);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8), // Warm parchment tone
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2B04F).withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: MandirTheme.primarySaffron,
                width: 4.0,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Verse number + Share
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFFFE082).withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '॥ श्लोक $vNum ॥',
                      style: GoogleFonts.mukta(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: MandirTheme.primarySaffron,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        final shareText =
                            '${widget.book.titleFor('mr')} (अध्याय $chapterNumber, श्लोक $vNum)\n\n'
                            '${verse.slok}\n\n'
                            'अर्थ:\n$meaning\n\n'
                            'भक्तीधारा ॲपवरून साभार';
                        SharePlus.instance.share(
                          ShareParams(text: shareText),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.share_rounded,
                          size: 18,
                          color: MandirTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Sanskrit Shlok Text Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFBF2),
                ),
                child: Text(
                  verse.slok,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mukta(
                    fontSize: fontSize + 2.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6B1B0B),
                    height: 1.65,
                    letterSpacing: 0.4,
                  ),
                ),
              ),

              // Transliteration Toggle
              if (hasTranslit) ...[
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isTranslitExpanded) {
                        _expandedTransliterations.remove(vNum);
                      } else {
                        _expandedTransliterations.add(vNum);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: MandirTheme.cardBorder.withValues(alpha: 0.6)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.record_voice_over_rounded, size: 14, color: MandirTheme.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'उच्चार (Pronunciation)',
                          style: GoogleFonts.mukta(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: MandirTheme.textMuted,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          isTranslitExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: MandirTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isTranslitExpanded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    color: Colors.amber.shade50.withValues(alpha: 0.5),
                    child: Text(
                      verse.transliteration,
                      style: GoogleFonts.robotoMono(
                        fontSize: fontSize - 3.0,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF5D4037),
                        height: 1.45,
                      ),
                    ),
                  ),
              ],

              // Word Meanings Toggle
              if (hasWordMeanings) ...[
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isWordMeaningsExpanded) {
                        _expandedWordMeanings.remove(vNum);
                      } else {
                        _expandedWordMeanings.add(vNum);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: MandirTheme.cardBorder.withValues(alpha: 0.6)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.format_list_bulleted_rounded, size: 14, color: MandirTheme.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'पदच्छेद व शब्दार्थ (Word Meanings)',
                          style: GoogleFonts.mukta(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: MandirTheme.textMuted,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          isWordMeaningsExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: MandirTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isWordMeaningsExpanded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    color: Colors.amber.shade50.withValues(alpha: 0.35),
                    child: Text(
                      verse.wordMeanings,
                      style: GoogleFonts.mukta(
                        fontSize: fontSize - 3.0,
                        color: MandirTheme.textDark,
                        height: 1.45,
                      ),
                    ),
                  ),
              ],

              // Meaning / Bhavarth Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: MandirTheme.cardBorder.withValues(alpha: 0.8)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: MandirTheme.primarySaffron,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedLang == 'hi'
                              ? 'भावार्थ'
                              : (selectedLang == 'en' ? 'Translation' : 'भावार्थ / अर्थ'),
                          style: GoogleFonts.mukta(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: MandirTheme.primarySaffron,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      meaning.isNotEmpty ? meaning : 'अर्थ उपलब्ध होत आहे...',
                      style: GoogleFonts.mukta(
                        fontSize: fontSize,
                        color: MandirTheme.textDark,
                        height: 1.55,
                      ),
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

  // ── Paywall Locked Gate ────────────────────────────────────────────────────
  Widget _buildPaywallGate(
    BuildContext context,
    WidgetRef ref,
    String langCode,
    GranthChapterDetail detail,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A1508),
            Color(0xFF5D1D00),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD84315).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Color(0xFFFFD54F),
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            langCode == 'hi'
                ? 'यह अध्याय प्रीमियम सदस्यों के लिए है'
                : (langCode == 'en'
                    ? 'This Chapter is Locked'
                    : 'हा अध्याय प्रीमियम सदस्यांसाठी आहे'),
            textAlign: TextAlign.center,
            style: GoogleFonts.mukta(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            langCode == 'hi'
                ? 'सभी अध्याय, संपूर्ण १८ महापुराण एवं अखंड वाचनासाठी प्रीमियम अनलॉक करें।'
                : (langCode == 'en'
                    ? 'Unlock all chapters and sacred scriptures with Premium.'
                    : 'सर्व अध्याय, संपूर्ण १८ महापुराणे व अखंड वाचनासाठी प्रीमियम अनलॉक करा.'),
            textAlign: TextAlign.center,
            style: GoogleFonts.mukta(
              fontSize: 13.5,
              color: const Color(0xFFFFE082),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD54F),
              foregroundColor: const Color(0xFF5D1D00),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => showPremiumPaywallSheet(context, ref, langCode),
            child: Text(
              langCode == 'hi' ? 'प्रीमियम अनलॉक करें' : (langCode == 'en' ? 'Unlock VIP' : 'प्रीमियम अनलॉक करा'),
              style: GoogleFonts.mukta(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation Bar (Prev / Next Chapter) ────────────────────────────
  Widget _buildBottomNav(String langCode) {
    final hasPrev = _currentChapterNumber > 1;
    final hasNext = _currentChapterNumber < widget.allChapters.length;
    final isVip = ref.watch(premiumAccessProvider);
    final isNextLocked = !isVip && ((_currentChapterNumber + 1) > widget.book.freeChapters);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MandirTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: hasPrev ? () => _goToChapter(_currentChapterNumber - 1) : null,
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
            label: Text(
              langCode == 'hi' ? 'पिछला अध्याय' : (langCode == 'en' ? 'Prev' : 'मागील अध्याय'),
              style: GoogleFonts.mukta(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: MandirTheme.chipBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: MandirTheme.chipBorder),
            ),
            child: Text(
              '$_currentChapterNumber / ${widget.allChapters.length}',
              style: GoogleFonts.mukta(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: MandirTheme.chipText,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: hasNext ? () => _goToChapter(_currentChapterNumber + 1) : null,
            icon: Icon(
              isNextLocked ? Icons.lock_rounded : Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isNextLocked ? const Color(0xFFD84315) : null,
            ),
            label: Text(
              isNextLocked
                  ? (langCode == 'hi'
                      ? 'अगला (अनलॉक)'
                      : (langCode == 'en' ? 'Next (VIP)' : 'पुढील (अनलॉक)'))
                  : (langCode == 'hi' ? 'अगला अध्याय' : (langCode == 'en' ? 'Next' : 'पुढील अध्याय')),
              style: GoogleFonts.mukta(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: isNextLocked ? const Color(0xFFD84315) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Font Size Dialog ───────────────────────────────────────────────────────
  void _showFontSizeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MandirTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final size = ref.watch(granthFontSizeProvider);
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'फॉन्ट आकार (Font Size)',
                    style: GoogleFonts.mukta(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MandirTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('A-', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Slider(
                          value: size,
                          min: 14.0,
                          max: 28.0,
                          divisions: 7,
                          activeColor: MandirTheme.primarySaffron,
                          label: '${size.toInt()}',
                          onChanged: (val) {
                            ref.read(granthFontSizeProvider.notifier).state = val;
                          },
                        ),
                      ),
                      const Text('A+', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

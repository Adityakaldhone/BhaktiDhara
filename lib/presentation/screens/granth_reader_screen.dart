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

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.book.titleFor(langCode),
              style: GoogleFonts.mukta(
                fontSize: 14,
                color: MandirTheme.primarySaffron,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'अध्याय $_currentChapterNumber: $chTitle',
              style: GoogleFonts.mukta(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: MandirTheme.textDark,
              ),
            ),
          ],
        ),
        actions: [
          // Font size adjuster
          IconButton(
            tooltip: 'फॉन्ट आकार',
            icon: const Icon(Icons.format_size_rounded, size: 22),
            onPressed: () => _showFontSizeDialog(context),
          ),
          // Language selector popup
          PopupMenuButton<String>(
            tooltip: 'भाषा बदला',
            icon: const Icon(Icons.translate_rounded, size: 22),
            initialValue: selectedLang,
            onSelected: (val) {
              ref.read(granthTranslationLangProvider.notifier).state = val;
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mr',
                child: Text('मराठी अर्थ', style: GoogleFonts.mukta(fontWeight: FontWeight.bold)),
              ),
              PopupMenuItem(
                value: 'hi',
                child: Text('हिंदी अर्थ', style: GoogleFonts.mukta(fontWeight: FontWeight.bold)),
              ),
              PopupMenuItem(
                value: 'en',
                child: Text('English Meaning', style: GoogleFonts.mukta(fontWeight: FontWeight.bold)),
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
                child: SizedBox(height: 36),
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

  Widget _buildChapterBanner(GranthChapterDetail detail, String langCode) {
    final summary = detail.chapterSummaryFor(langCode);
    final chName = detail.chapterNameFor(langCode);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
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
                    fontSize: 16,
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
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: MandirTheme.cardBorder,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Verse number + Share
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: MandirTheme.chipBackground.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(
                  '॥ श्लोक $vNum ॥',
                  style: GoogleFonts.mukta(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: MandirTheme.primarySaffron,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    final shareText =
                        'श्रीमद्भगवद्गीता (अध्याय $chapterNumber, श्लोक $vNum)\n\n'
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

          // Sanskrit Shlok Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9EE),
            ),
            child: Text(
              verse.slok,
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(
                fontSize: fontSize + 2.0,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6B1B0B),
                height: 1.6,
                letterSpacing: 0.3,
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: MandirTheme.cardBorder.withValues(alpha: 0.6)),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'उच्चार (Pronunciation)',
                      style: GoogleFonts.mukta(
                        fontSize: 12,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.amber.shade50.withValues(alpha: 0.4),
                child: Text(
                  verse.transliteration,
                  style: GoogleFonts.robotoMono(
                    fontSize: fontSize - 3.0,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF5D4037),
                    height: 1.4,
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: MandirTheme.cardBorder.withValues(alpha: 0.6)),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'पदच्छेद व शब्दार्थ (Word Meanings)',
                      style: GoogleFonts.mukta(
                        fontSize: 12,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.amber.shade50.withValues(alpha: 0.3),
                child: Text(
                  verse.wordMeanings,
                  style: GoogleFonts.mukta(
                    fontSize: fontSize - 3.5,
                    color: MandirTheme.textDark,
                    height: 1.4,
                  ),
                ),
              ),
          ],

          // Meaning / Bhavarth
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: MandirTheme.cardBorder),
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
                        fontSize: 13,
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
    );
  }

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
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFD54F),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Color(0xFFFFD54F),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            langCode == 'hi'
                ? 'अध्याय $_currentChapterNumber के सम्पूर्ण श्लोक अनलॉक करें'
                : (langCode == 'en'
                    ? 'Unlock Chapter $_currentChapterNumber Full Verses'
                    : 'अध्याय $_currentChapterNumber चे सर्व श्लोक अनलॉक करा'),
            textAlign: TextAlign.center,
            style: GoogleFonts.mukta(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            langCode == 'en'
                ? '7 Days Free Trial • Then ₹51/month'
                : (langCode == 'hi'
                    ? '7 दिन मुफ्त ट्रायल • फिर ₹51/माह'
                    : '७ दिवस मोफत ट्रायल • मग ₹५१/महिना'),
            textAlign: TextAlign.center,
            style: GoogleFonts.mukta(
              fontSize: 13,
              color: const Color(0xFFFFD54F),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            langCode == 'hi'
                ? '${widget.book.titleFor(langCode)} के सभी ${widget.book.totalChapters} अध्याय एवं सविस्तार अर्थ पढ़ने के लिए भक्तिधारा प्रीमियम सदस्य बनें।'
                : (langCode == 'en'
                    ? 'Join BhaktiDhara VIP to read all ${widget.book.totalChapters} chapters of ${widget.book.titleFor(langCode)} with detailed meanings.'
                    : '${widget.book.titleFor(langCode)}चे सर्व ${widget.book.totalChapters} अध्याय आणि सविस्तर भावार्थ वाचण्यासाठी भक्तीधारा प्रीमियम सदस्य व्हा।'),
            textAlign: TextAlign.center,
            style: GoogleFonts.mukta(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => showPremiumPaywallSheet(context, ref, langCode),
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  langCode == 'en'
                      ? 'Start 7-Day Free Trial'
                      : (langCode == 'hi'
                          ? '7 दिन मुफ्त ट्रायल शुरू करें'
                          : '७ दिवस मोफत ट्रायल सुरू करा'),
                  style: GoogleFonts.mukta(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD54F),
                foregroundColor: const Color(0xFF4A1500),
                elevation: 4,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(String langCode) {
    final hasPrev = _currentChapterNumber > 1;
    final hasNext = _currentChapterNumber < widget.allChapters.length;
    final isVip = ref.watch(premiumAccessProvider);
    final isNextLocked = !isVip && ((_currentChapterNumber + 1) > widget.book.freeChapters);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MandirTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: hasPrev ? () => _goToChapter(_currentChapterNumber - 1) : null,
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
            label: Text(
              langCode == 'hi' ? 'पिछला अध्याय' : (langCode == 'en' ? 'Prev Chapter' : 'मागील अध्याय'),
              style: GoogleFonts.mukta(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '$_currentChapterNumber / ${widget.allChapters.length}',
            style: GoogleFonts.mukta(
              fontWeight: FontWeight.bold,
              color: MandirTheme.textMuted,
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
                      ? 'अगला अध्याय (अनलॉक)'
                      : (langCode == 'en' ? 'Next (Unlock)' : 'पुढील अध्याय (अनलॉक)'))
                  : (langCode == 'hi' ? 'अगला अध्याय' : (langCode == 'en' ? 'Next Chapter' : 'पुढील अध्याय')),
              style: GoogleFonts.mukta(
                fontWeight: FontWeight.bold,
                color: isNextLocked ? const Color(0xFFD84315) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                          max: 26.0,
                          divisions: 6,
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

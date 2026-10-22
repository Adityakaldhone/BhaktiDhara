import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme.dart';
import '../../data/repositories/granth_repository.dart';
import '../../domain/entities/granth.dart';
import '../providers/granth_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/remote_config_provider.dart';
import '../widgets/premium_blurred_gate.dart';

class GranthPothiReaderScreen extends ConsumerStatefulWidget {
  final GranthBook book;
  final int initialPage;

  const GranthPothiReaderScreen({
    super.key,
    required this.book,
    this.initialPage = 1,
  });

  @override
  ConsumerState<GranthPothiReaderScreen> createState() =>
      _GranthPothiReaderScreenState();
}

class _GranthPothiReaderScreenState
    extends ConsumerState<GranthPothiReaderScreen> {
  late PageController _pageController;
  late int _currentPage;
  bool _isControlsVisible = true;
  int _totalPages = 638;
  int _freePages = 638;
  String _bookmarkKey = '';

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _bookmarkKey = 'pothi_bookmark_${widget.book.slug}';
    _loadSavedBookmark();
  }

  Future<void> _loadSavedBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_bookmarkKey);
    if (saved != null && saved >= 1 && saved <= _totalPages && widget.initialPage == 1) {
      if (mounted) {
        setState(() {
          _currentPage = saved;
        });
        _pageController.jumpToPage(saved - 1);
      }
    }
  }

  Future<void> _saveBookmark(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bookmarkKey, page);
    if (!mounted) return;
    final langCode = ref.read(localeProvider).languageCode;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          langCode == 'hi'
              ? 'पृष्ठ $page बुकमार्क किया गया'
              : (langCode == 'en' ? 'Page $page bookmarked' : 'पृष्ठ $page बुकमार्क जतन केले'),
          style: GoogleFonts.mukta(fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: MandirTheme.primarySaffron,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _jumpToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
    });
    _pageController.jumpToPage(page - 1);
  }

  void _showJumpDialog(BuildContext context, String langCode) {
    final controller = TextEditingController(text: '$_currentPage');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MandirTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          langCode == 'hi'
              ? 'पृष्ठ पर जाएँ'
              : (langCode == 'en' ? 'Go to Page' : 'पृष्ठावर जा'),
          style: GoogleFonts.mukta(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              langCode == 'hi'
                  ? '१ से $_totalPages के बीच पृष्ठ संख्या दर्ज करें:'
                  : (langCode == 'en'
                      ? 'Enter page number (1 to $_totalPages):'
                      : '१ ते $_totalPages मधील पृष्ठ क्रमांक टाका:'),
              style: GoogleFonts.mukta(fontSize: 14, color: MandirTheme.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.mukta(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: MandirTheme.textDark,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: MandirTheme.backgroundCream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: MandirTheme.primarySaffron),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              langCode == 'en' ? 'Cancel' : 'रद्द करा',
              style: GoogleFonts.mukta(
                fontWeight: FontWeight.bold,
                color: MandirTheme.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MandirTheme.primarySaffron,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val >= 1 && val <= _totalPages) {
                Navigator.pop(ctx);
                _jumpToPage(val);
              }
            },
            child: Text(
              langCode == 'en' ? 'Go' : 'जा',
              style: GoogleFonts.mukta(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSectionsSheet(
    BuildContext context,
    List<GranthPothiSection> sections,
    String langCode, {
    String attributionText = '',
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MandirTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.bookmark_border_rounded,
                    color: MandirTheme.primarySaffron,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    langCode == 'hi'
                        ? 'विषय-सूची एवं प्रमुख भाग'
                        : (langCode == 'en'
                            ? 'Table of Contents & Sections'
                            : 'विषय-सूची आणि प्रमुख विभाग'),
                    style: GoogleFonts.mukta(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MandirTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...sections.map(
                (sec) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: MandirTheme.primarySaffron.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${sec.startPage}',
                        style: GoogleFonts.mukta(
                          fontWeight: FontWeight.bold,
                          color: MandirTheme.primarySaffron,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    sec.title,
                    style: GoogleFonts.mukta(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: MandirTheme.textDark,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: MandirTheme.textMuted,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _jumpToPage(sec.startPage);
                  },
                ),
              ),
              if (attributionText.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.black12, height: 1),
                const SizedBox(height: 10),
                Text(
                  attributionText,
                  style: GoogleFonts.mukta(
                    fontSize: 11,
                    color: MandirTheme.textMuted,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAttributionDialog(
    BuildContext context,
    String attributionText,
    String langCode,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MandirTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: MandirTheme.primarySaffron, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                langCode == 'hi'
                    ? 'ग्रंथ एवं परवाना जानकारी'
                    : (langCode == 'en'
                        ? 'Manuscript & License Info'
                        : 'ग्रंथ व परवाना माहिती'),
                style: GoogleFonts.mukta(
                    fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              langCode == 'hi'
                  ? 'यह पवित्र ${widget.book.titleFor(langCode)} ग्रंथ लोककल्याण एवं धार्मिक अध्ययन हेतु समस्त श्रद्धालुओं के लिए उपलब्ध है।'
                  : (langCode == 'en'
                      ? 'This sacred ${widget.book.titleFor(langCode)} manuscript is provided for spiritual study.'
                      : 'हा पवित्र ${widget.book.titleFor(langCode)} ग्रंथ लोककल्याणार्थ व आध्यात्मिक अभ्यासासाठी सर्व भाविकांना उपलब्ध आहे.'),
              style: GoogleFonts.mukta(
                  fontSize: 13.5, color: MandirTheme.textDark, height: 1.35),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MandirTheme.backgroundCream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MandirTheme.cardBorder),
              ),
              child: Text(
                attributionText.isNotEmpty
                    ? attributionText
                    : 'Digital preservation courtesy of Indic Journals / Internet Archive under CC BY-NC-ND 4.0 license.',
                style: GoogleFonts.mukta(
                    fontSize: 12, color: MandirTheme.textMuted, height: 1.3),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MandirTheme.primarySaffron,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              langCode == 'en' ? 'Close' : 'समजले',
              style: GoogleFonts.mukta(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pothiAsync = ref.watch(granthPothiInfoProvider(widget.book.slug));
    final langCode = ref.watch(localeProvider).languageCode;
    final isVip = ref.watch(premiumAccessProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1B18), // Deep warm reader backdrop
      appBar: _isControlsVisible
          ? AppBar(
              backgroundColor: const Color(0xFF1E1B18).withValues(alpha: 0.95),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.book.titleFor(langCode),
                    style: GoogleFonts.mukta(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    langCode == 'hi'
                        ? 'पृष्ठ $_currentPage / $_totalPages'
                        : (langCode == 'en'
                            ? 'Page $_currentPage of $_totalPages'
                            : 'पृष्ठ $_currentPage / $_totalPages'),
                    style: GoogleFonts.mukta(
                      fontSize: 12.5,
                      color: const Color(0xFFFFD54F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: [
                // Jump to Page
                IconButton(
                  tooltip: 'Go to Page',
                  icon: const Icon(Icons.pin_outlined, color: Colors.white),
                  onPressed: () => _showJumpDialog(context, langCode),
                ),
                // Sections / Table of Contents
                pothiAsync.when(
                  data: (pothi) => pothi != null && pothi.sections.isNotEmpty
                      ? IconButton(
                          tooltip: 'Table of Contents',
                          icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
                          onPressed: () => _showSectionsSheet(
                            context,
                            pothi.sections,
                            langCode,
                            attributionText: pothi.attributionFor(langCode),
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
                // License & Attribution Info
                pothiAsync.when(
                  data: (pothi) => pothi != null
                      ? IconButton(
                          tooltip: 'License Info',
                          icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
                          onPressed: () => _showAttributionDialog(
                            context,
                            pothi.attributionFor(langCode),
                            langCode,
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
                // Bookmark
                IconButton(
                  tooltip: 'Save Bookmark',
                  icon: const Icon(Icons.bookmark_add_outlined, color: Color(0xFFFFD54F)),
                  onPressed: () => _saveBookmark(_currentPage),
                ),
              ],
            )
          : null,
      body: pothiAsync.when(
        data: (pothi) {
          if (pothi != null) {
            _totalPages = pothi.totalPages;
            _freePages = pothi.freePages;
          }

          return Stack(
            children: [
              // ── Main PageView (Horizontal Swiping Book Reader) ────────────
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isControlsVisible = !_isControlsVisible;
                  });
                },
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _totalPages,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentPage = idx + 1;
                    });
                  },
                  itemBuilder: (context, index) {
                    final pageNum = index + 1;
                    final isLocked = !isVip && (pageNum > _freePages);

                    return _buildPageItem(pageNum, isLocked, langCode);
                  },
                ),
              ),

              // ── Bottom Scrubber / Floating Navigation Bar ────────────────
              if (_isControlsVisible)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _buildBottomScrubber(langCode, isVip),
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
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.white70,
              ),
              const SizedBox(height: 12),
              Text(
                langCode == 'en'
                    ? 'Failed to load sacred book'
                    : 'ग्रंथ लोड करताना समस्या आली',
                style: GoogleFonts.mukta(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.invalidate(granthPothiInfoProvider(widget.book.slug)),
                child: Text(
                  langCode == 'en' ? 'Retry' : 'पुन्हा प्रयत्न करा',
                  style: GoogleFonts.mukta(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD54F),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageItem(int pageNum, bool isLocked, String langCode) {
    final pageUrl =
        GranthRepository.instance.getPothiPageUrl(widget.book.slug, pageNum);

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 3.5,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Page Image
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: pageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  width: double.infinity,
                  height: 480,
                  color: Colors.white,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: MandirTheme.primarySaffron,
                          strokeWidth: 2.5,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          langCode == 'en'
                              ? 'Loading page $pageNum...'
                              : 'पृष्ठ $pageNum लोड होत आहे...',
                          style: GoogleFonts.mukta(
                            color: MandirTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: double.infinity,
                  height: 400,
                  color: Colors.white,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.broken_image_rounded,
                          size: 44,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          langCode == 'en'
                              ? 'Page $pageNum unavailable'
                              : 'पृष्ठ $pageNum उपलब्ध नाही',
                          style: GoogleFonts.mukta(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // VIP Paywall Overlay if locked
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black.withValues(alpha: 0.85),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C1E1A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFD54F),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF3D6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: Color(0xFF8B1D18),
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              langCode == 'hi'
                                  ? 'संपूर्ण ६३८ पृष्ठ अनलॉक करें'
                                  : (langCode == 'en'
                                      ? 'Unlock All 638 Pages'
                                      : 'संपूर्ण ६३८ पृष्ठे अनलॉक करा'),
                              style: GoogleFonts.mukta(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              langCode == 'hi'
                                  ? 'प्रथम २५ पृष्ठ निःशुल्क हैं। सम्पूर्ण महापुराण पढ़ने के लिए भक्तिधारा प्रीमियम सदस्य बनें।'
                                  : (langCode == 'en'
                                      ? 'First 25 pages are free. Join BhaktiDhara VIP to read all 638 pages.'
                                      : 'पहिली २५ पृष्ठे मोफत आहेत. संपूर्ण महापुराण वाचण्यासाठी भक्तीधारा प्रीमियम सदस्य व्हा.'),
                              style: GoogleFonts.mukta(
                                fontSize: 13.5,
                                color: Colors.white70,
                                height: 1.35,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF8B1D18),
                                      Color(0xFFE65100),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () => showPremiumPaywallSheet(
                                    context,
                                    ref,
                                    langCode,
                                  ),
                                  icon: const Icon(
                                    Icons.lock_open_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      langCode == 'hi'
                                          ? '7 दिन मुफ्त ट्रायल शुरू करें'
                                          : (langCode == 'en'
                                              ? 'Start 7-Day Free Trial'
                                              : '७ दिवस मोफत ट्रायल सुरू करा'),
                                      style: GoogleFonts.mukta(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomScrubber(String langCode, bool isVip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B18).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Previous Page
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white70, size: 18),
                onPressed: _currentPage > 1
                    ? () => _jumpToPage(_currentPage - 1)
                    : null,
              ),

              // Page Slider
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: MandirTheme.primarySaffron,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: const Color(0xFFFFD54F),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: _currentPage.toDouble().clamp(1.0, _totalPages.toDouble()),
                    min: 1.0,
                    max: _totalPages.toDouble(),
                    onChanged: (val) {
                      _jumpToPage(val.round());
                    },
                  ),
                ),
              ),

              // Next Page
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white70, size: 18),
                onPressed: _currentPage < _totalPages
                    ? () => _jumpToPage(_currentPage + 1)
                    : null,
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'पृष्ठ १',
                  style: GoogleFonts.mukta(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                Text(
                  '$_currentPage / $_totalPages',
                  style: GoogleFonts.mukta(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD54F),
                  ),
                ),
                Text(
                  'पृष्ठ $_totalPages',
                  style: GoogleFonts.mukta(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

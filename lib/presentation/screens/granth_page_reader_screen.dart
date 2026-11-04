import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/granth.dart';
import '../providers/granth_providers.dart';
import '../providers/locale_provider.dart';
import 'granth_pdf_reader_screen.dart';

const _backdrop = Color(0xFFEDE6DA);

/// Opens [book] at [page]: from its page images when they exist, otherwise by
/// streaming the PDF.
Future<void> openGranthBookReader(
  BuildContext context,
  GranthBook book, {
  required String langCode,
  int page = 1,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => book.hasPageImages
          ? GranthPageReaderScreen(book: book, initialPage: page)
          : GranthPdfReaderScreen(
              bookSlug: book.slug,
              title: book.titleFor(langCode),
              subtitle: book.subtitleFor(langCode),
              pdfUrl: book.pdfUrl!,
              initialPage: page,
            ),
    ),
  );
}

/// Reads a Mahapurana from its pre-rendered page images.
///
/// Each page is a ~150 KB WebP served from the CDN, so any page — including a
/// far jump or a resume — appears in well under a second. The neighbouring
/// pages are prefetched so swiping feels instant.
class GranthPageReaderScreen extends ConsumerStatefulWidget {
  const GranthPageReaderScreen({super.key, required this.book, this.initialPage = 1});

  final GranthBook book;
  final int initialPage;

  @override
  ConsumerState<GranthPageReaderScreen> createState() => _GranthPageReaderScreenState();
}

class _GranthPageReaderScreenState extends ConsumerState<GranthPageReaderScreen> {
  late final PageController _pages;
  late int _page;
  double? _scrubPage;
  Timer? _saveDebounce;

  int get _count => widget.book.pageCount;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(1, _count);
    _pages = PageController(initialPage: _page - 1);
    _saveProgress(_page);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefetchAround(_page));
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _pages.dispose();
    super.dispose();
  }

  String _t(String mr, String hi, String en) {
    final lang = ref.read(localeProvider).languageCode;
    return lang == 'en' ? en : (lang == 'hi' ? hi : mr);
  }

  void _saveProgress(int page) {
    final lang = ref.read(localeProvider).languageCode;
    ref.read(granthLastReadProvider.notifier).save(
          bookSlug: widget.book.slug,
          bookTitle: widget.book.titleFor(lang),
          bookSubtitle: widget.book.subtitleFor(lang),
          pdfUrl: widget.book.pdfUrl,
          pageNumber: page,
        );
  }

  void _prefetchAround(int page) {
    if (!mounted) return;
    for (final p in [page + 1, page + 2, page - 1]) {
      if (p < 1 || p > _count) continue;
      precacheImage(CachedNetworkImageProvider(widget.book.pageImageUrl(p)), context)
          .catchError((_) {});
    }
  }

  void _onPageChanged(int index) {
    final page = index + 1;
    setState(() => _page = page);
    _prefetchAround(page);
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), () => _saveProgress(page));
  }

  void _goTo(int page) {
    final target = page.clamp(1, _count);
    if ((target - _page).abs() <= 1) {
      _pages.animateToPage(
        target - 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      _pages.jumpToPage(target - 1);
    }
  }

  Future<void> _askPage() async {
    final input = TextEditingController();
    final page = await showDialog<int>(
      context: context,
      builder: (ctx) {
        void submit() {
          final n = int.tryParse(input.text.trim());
          if (n != null && n >= 1 && n <= _count) Navigator.pop(ctx, n);
        }

        return AlertDialog(
          backgroundColor: MandirTheme.surfaceWhite,
          title: Text(
            _t('पृष्ठावर जा', 'पृष्ठ पर जाएँ', 'Go to page'),
            style: GoogleFonts.mukta(fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: input,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => submit(),
            decoration: InputDecoration(hintText: '1 – $_count'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_t('रद्द करा', 'रद्द करें', 'Cancel'), style: GoogleFonts.mukta()),
            ),
            TextButton(
              onPressed: submit,
              child: Text(
                _t('जा', 'जाएँ', 'Go'),
                style: GoogleFonts.mukta(
                  fontWeight: FontWeight.w700,
                  color: MandirTheme.primarySaffron,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (page != null) _goTo(page);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final shownPage = _scrubPage?.round() ?? _page;

    return Scaffold(
      backgroundColor: _backdrop,
      appBar: AppBar(
        backgroundColor: MandirTheme.backgroundCream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: MandirTheme.textDark,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.book.titleFor(lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.mukta(fontSize: 18, fontWeight: FontWeight.w700, height: 1.2),
            ),
            Text(
              _t('पृष्ठ $_page / $_count', 'पृष्ठ $_page / $_count', 'Page $_page of $_count'),
              style: GoogleFonts.mukta(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MandirTheme.textMuted,
                height: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _t('पृष्ठावर जा', 'पृष्ठ पर जाएँ', 'Go to page'),
            onPressed: _askPage,
            icon: const Icon(Icons.find_in_page_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: _count,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) => _PageImage(
                url: widget.book.pageImageUrl(index + 1),
                pageNumber: index + 1,
                loadingText: _t('पृष्ठ उघडत आहे…', 'पृष्ठ खुल रहा है…', 'Opening page…'),
                errorText: _t(
                  'पृष्ठ उघडता आले नाही. इंटरनेट तपासा.',
                  'पृष्ठ नहीं खुल सका। इंटरनेट जाँचें।',
                  'Could not load this page. Check your internet.',
                ),
                retryText: _t('पुन्हा प्रयत्न करा', 'फिर प्रयास करें', 'Try again'),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: MandirTheme.backgroundCream,
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _page > 1 ? () => _goTo(_page - 1) : null,
                    icon: const Icon(Icons.chevron_left_rounded, size: 30),
                    color: MandirTheme.primarySaffron,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: MandirTheme.primarySaffron,
                        inactiveTrackColor: MandirTheme.cardBorder,
                        thumbColor: MandirTheme.primarySaffron,
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        showValueIndicator: ShowValueIndicator.onDrag,
                        valueIndicatorColor: MandirTheme.primarySaffron,
                      ),
                      child: Slider(
                        min: 1,
                        max: math.max(2, _count).toDouble(),
                        value: shownPage.clamp(1, _count).toDouble(),
                        label: '$shownPage',
                        onChanged: _count < 2 ? null : (v) => setState(() => _scrubPage = v),
                        onChangeEnd: (v) {
                          setState(() => _scrubPage = null);
                          _goTo(v.round());
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _page < _count ? () => _goTo(_page + 1) : null,
                    icon: const Icon(Icons.chevron_right_rounded, size: 30),
                    color: MandirTheme.primarySaffron,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageImage extends StatefulWidget {
  const _PageImage({
    required this.url,
    required this.pageNumber,
    required this.loadingText,
    required this.errorText,
    required this.retryText,
  });

  final String url;
  final int pageNumber;
  final String loadingText;
  final String errorText;
  final String retryText;

  @override
  State<_PageImage> createState() => _PageImageState();
}

class _PageImageState extends State<_PageImage> {
  int _attempt = 0;

  Future<void> _retry() async {
    await CachedNetworkImage.evictFromCache(widget.url);
    if (mounted) setState(() => _attempt++);
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: CachedNetworkImage(
            key: ValueKey('${widget.url}#$_attempt'),
            imageUrl: widget.url,
            fit: BoxFit.contain,
            fadeInDuration: const Duration(milliseconds: 120),
            imageBuilder: (context, image) => DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1))],
              ),
              child: Image(image: image, fit: BoxFit.contain),
            ),
            placeholder: (context, _) => AspectRatio(
              aspectRatio: 0.68,
              child: ColoredBox(
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: MandirTheme.primarySaffron,
                      strokeWidth: 2.5,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.loadingText,
                      style: GoogleFonts.mukta(fontSize: 14, color: MandirTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            errorWidget: (context, _, _) => AspectRatio(
              aspectRatio: 0.68,
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 40, color: MandirTheme.textMuted),
                      const SizedBox(height: 10),
                      Text(
                        widget.errorText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.mukta(fontSize: 15, color: MandirTheme.textDark),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _retry,
                        style: FilledButton.styleFrom(backgroundColor: MandirTheme.primarySaffron),
                        child: Text(
                          widget.retryText,
                          style: GoogleFonts.mukta(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

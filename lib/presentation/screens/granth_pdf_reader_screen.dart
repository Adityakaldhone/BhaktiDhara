import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/theme.dart';
import '../providers/granth_providers.dart';
import '../providers/locale_provider.dart';

/// In-app reader for the Mahapurana PDFs.
///
/// The PDFs are 15–75 MB, so they are streamed with HTTP range requests:
/// only the blocks needed for the visible pages are fetched (and cached on
/// disk), which shows the first page in about a second instead of waiting
/// for the whole file.
class GranthPdfReaderScreen extends ConsumerStatefulWidget {
  const GranthPdfReaderScreen({
    super.key,
    required this.bookSlug,
    required this.title,
    required this.pdfUrl,
    this.subtitle,
    this.initialPage = 1,
  });

  final String bookSlug;
  final String title;
  final String? subtitle;
  final String pdfUrl;
  final int initialPage;

  @override
  ConsumerState<GranthPdfReaderScreen> createState() => _GranthPdfReaderScreenState();
}

class _GranthPdfReaderScreenState extends ConsumerState<GranthPdfReaderScreen> {
  final _controller = PdfViewerController();
  Timer? _saveDebounce;
  int _page = 1;
  int? _pageCount;
  int _reloadKey = 0;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage < 1 ? 1 : widget.initialPage;
    _saveProgress(_page);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  String _t(String mr, String hi, String en) {
    final lang = ref.read(localeProvider).languageCode;
    return lang == 'en' ? en : (lang == 'hi' ? hi : mr);
  }

  void _saveProgress(int page) {
    ref.read(granthLastReadProvider.notifier).save(
          bookSlug: widget.bookSlug,
          bookTitle: widget.title,
          bookSubtitle: widget.subtitle,
          pdfUrl: widget.pdfUrl,
          pageNumber: page,
        );
  }

  void _onPageChanged(int? page) {
    if (page == null || page == _page) return;
    setState(() => _page = page);
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), () => _saveProgress(page));
  }

  Future<void> _jumpToPage() async {
    final total = _pageCount;
    if (total == null) return;
    final input = TextEditingController();
    final page = await showDialog<int>(
      context: context,
      builder: (ctx) {
        void submit() {
          final n = int.tryParse(input.text.trim());
          if (n != null && n >= 1 && n <= total) Navigator.pop(ctx, n);
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
            decoration: InputDecoration(hintText: '1 – $total'),
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
    if (page != null && _controller.isReady) {
      await _controller.goToPage(pageNumber: page, duration: Duration.zero);
    }
  }

  Future<void> _openExternally() async {
    final uri = Uri.parse(widget.pdfUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final pageLabel = _pageCount == null
        ? null
        : _t('पृष्ठ $_page / $_pageCount', 'पृष्ठ $_page / $_pageCount', 'Page $_page of $_pageCount');

    return Scaffold(
      backgroundColor: const Color(0xFFEDE6DA),
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
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.mukta(fontSize: 18, fontWeight: FontWeight.w700, height: 1.2),
            ),
            if (pageLabel != null)
              Text(
                pageLabel,
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
            onPressed: _pageCount == null ? null : _jumpToPage,
            icon: const Icon(Icons.find_in_page_rounded),
          ),
        ],
      ),
      body: PdfViewer.uri(
        Uri.parse(widget.pdfUrl),
        key: ValueKey(_reloadKey),
        controller: _controller,
        preferRangeAccess: true,
        initialPageNumber: _page,
        timeout: const Duration(seconds: 20),
        params: PdfViewerParams(
          backgroundColor: const Color(0xFFEDE6DA),
          margin: 6,
          pageDropShadow: const BoxShadow(color: Color(0x22000000), blurRadius: 3, offset: Offset(0, 1)),
          onViewerReady: (document, controller) {
            setState(() => _pageCount = document.pages.length);
          },
          onPageChanged: _onPageChanged,
          viewerOverlayBuilder: (context, size, handleLinkTap) => [
            PdfViewerScrollThumb(
              controller: _controller,
              orientation: ScrollbarOrientation.right,
              thumbSize: const Size(46, 28),
              thumbBuilder: (context, thumbSize, pageNumber, controller) => Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MandirTheme.primarySaffron,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                ),
                child: Text(
                  '${pageNumber ?? ''}',
                  style: GoogleFonts.mukta(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          loadingBannerBuilder: (context, bytesDownloaded, totalBytes) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: MandirTheme.primarySaffron),
                const SizedBox(height: 14),
                Text(
                  _t('ग्रंथ उघडत आहे…', 'ग्रंथ खुल रहा है…', 'Opening the scripture…'),
                  style: GoogleFonts.mukta(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MandirTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          errorBannerBuilder: (context, error, stackTrace, documentRef) => Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 44, color: MandirTheme.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    _t(
                      'ग्रंथ उघडता आला नाही. इंटरनेट तपासून पुन्हा प्रयत्न करा.',
                      'ग्रंथ नहीं खुल सका। इंटरनेट जाँचकर फिर प्रयास करें।',
                      'Could not open the scripture. Check your internet and try again.',
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mukta(fontSize: 16, color: MandirTheme.textDark, height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(() => _reloadKey++),
                    style: FilledButton.styleFrom(backgroundColor: MandirTheme.primarySaffron),
                    child: Text(
                      _t('पुन्हा प्रयत्न करा', 'फिर प्रयास करें', 'Try again'),
                      style: GoogleFonts.mukta(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: _openExternally,
                    child: Text(
                      _t('ब्राउझरमध्ये उघडा', 'ब्राउज़र में खोलें', 'Open in browser'),
                      style: GoogleFonts.mukta(color: MandirTheme.primarySaffron),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/granth.dart';
import '../providers/granth_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/remote_config_provider.dart';
import '../widgets/premium_blurred_gate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'granth_pothi_reader_screen.dart';
import 'granth_reader_screen.dart';

class GranthChapterListScreen extends ConsumerWidget {
  final GranthBook book;

  const GranthChapterListScreen({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(granthChaptersProvider(book.slug));
    final langCode = ref.watch(localeProvider).languageCode;
    final isVip = ref.watch(premiumAccessProvider);
    final bookTitle = book.titleFor(langCode);

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
          if (chapters.isEmpty) {
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildBookOverviewHeader(context, ref, langCode, isVip, hasChapters: false),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: MandirTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: MandirTheme.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD84315).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 36,
                          color: Color(0xFFD84315),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        langCode == 'hi'
                            ? 'संपूर्ण मूल महापुराण उपलब्ध है'
                            : (langCode == 'en'
                                ? 'Complete Sacred Purana Available'
                                : 'संपूर्ण मूळ महापुराण वाचनासाठी उपलब्ध आहे'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.mukta(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MandirTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        langCode == 'hi'
                            ? 'ऊपर दिए गए "सचित्र सम्पूर्ण वाचन" बटन पर टैप करके इस पावन महापुराण का सम्पूर्ण अध्ययन करें।'
                            : (langCode == 'en'
                                ? 'Tap the "Read Illustrated Scripture" button above to immerse in this holy scripture.'
                                : 'वरील "सचित्र संपूर्ण वाचन" बटणावर टॅप करून या पावन महापुराणाचे मूळ स्वरूपात वाचन करा.'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.mukta(
                          fontSize: 14,
                          color: MandirTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (book.pdfUrl != null && book.pdfUrl!.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MandirTheme.primarySaffron,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () async {
                              final uri = Uri.parse(book.pdfUrl!);
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
                            icon: const Icon(Icons.auto_stories_rounded, size: 20),
                            label: Text(
                              langCode == 'hi'
                                  ? 'पावन महापुराण वाचन प्रारंभ करें'
                                  : (langCode == 'en'
                                      ? 'Open Sacred Scripture'
                                      : 'पावन महापुराण वाचन सुरू करा'),
                              style: GoogleFonts.mukta(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }

          final itemCount = chapters.length + 1 + (!isVip ? 1 : 0);

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildBookOverviewHeader(context, ref, langCode, isVip);
              }
              if (!isVip && index == 2) {
                // Show subscription banner right after Chapter 1 (free teaser)
                return _buildSubscriptionCta(context, ref, langCode);
              }
              final chapterIndex = (!isVip && index > 2) ? index - 2 : index - 1;
              final chapter = chapters[chapterIndex];
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
                    ? 'अध्याय लोड करने में त्रुटि'
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
                onPressed: () => ref.invalidate(granthChaptersProvider(book.slug)),
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

  Widget _buildBookOverviewHeader(
    BuildContext context,
    WidgetRef ref,
    String langCode,
    bool isVip, {
    bool hasChapters = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MandirTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasChapters) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MandirTheme.primarySaffron.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    book.slug == 'dasbodh'
                        ? (langCode == 'hi'
                            ? '${book.totalChapters} दशक'
                            : (langCode == 'en' ? '${book.totalChapters} Dashakas' : '${book.totalChapters} दशक'))
                        : (langCode == 'hi'
                            ? 'संपूर्ण ${book.totalChapters} अध्याय'
                            : (langCode == 'en' ? 'All ${book.totalChapters} Chapters' : 'संपूर्ण ${book.totalChapters} अध्याय')),
                    style: GoogleFonts.mukta(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: MandirTheme.primarySaffron,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    langCode == 'hi'
                        ? 'अध्याय १ निःशुल्क'
                        : (langCode == 'en' ? 'Chapter 1 Free' : 'अध्याय १ मोफत'),
                    style: GoogleFonts.mukta(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ] else ...[
                if (book.totalChapters > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MandirTheme.primarySaffron.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      langCode == 'hi'
                          ? '${book.totalChapters} अध्याय'
                          : (langCode == 'en' ? '${book.totalChapters} Chapters' : '${book.totalChapters} अध्याय'),
                      style: GoogleFonts.mukta(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: MandirTheme.primarySaffron,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (book.totalVerses > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MandirTheme.chipBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MandirTheme.chipBorder),
                    ),
                    child: Text(
                      langCode == 'hi'
                          ? '${book.totalVerses} पृष्ठ'
                          : (langCode == 'en' ? '${book.totalVerses} Pages' : '${book.totalVerses} पृष्ठे'),
                      style: GoogleFonts.mukta(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: MandirTheme.chipText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD84315).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, size: 12, color: Color(0xFFD84315)),
                      const SizedBox(width: 4),
                      Text(
                        langCode == 'hi' ? 'सचित्र सम्पूर्ण' : (langCode == 'en' ? 'Illustrated Edition' : 'सचित्र संपूर्ण'),
                        style: GoogleFonts.mukta(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD84315),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            book.descriptionFor(langCode),
            style: GoogleFonts.mukta(
              fontSize: 13.5,
              color: MandirTheme.textMuted,
              height: 1.4,
            ),
          ),
          if (book.slug == 'dasbodh' || (book.pdfUrl != null && book.pdfUrl!.isNotEmpty)) ...[
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5D1D00), Color(0xFFD84315)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD84315).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    if (book.slug == 'dasbodh') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GranthPothiReaderScreen(book: book),
                        ),
                      );
                    } else if (book.pdfUrl != null && book.pdfUrl!.isNotEmpty) {
                      final uri = Uri.parse(book.pdfUrl!);
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
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: Color(0xFFFFD54F),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.slug == 'dasbodh'
                                    ? (langCode == 'hi'
                                        ? 'सचित्र सम्पूर्ण श्रीमद् दासबोध (४६७ पृष्ठ)'
                                        : (langCode == 'en'
                                            ? 'Illustrated Shrimad Dasbodh (467 Pages)'
                                            : 'सचित्र संपूर्ण श्रीमद् दासबोध (४६७ पृष्ठे)'))
                                    : (langCode == 'hi'
                                        ? 'सचित्र सम्पूर्ण ${book.titleFor(langCode)} (${book.totalVerses > 0 ? '${book.totalVerses} पृष्ठ' : 'PDF'})'
                                        : (langCode == 'en'
                                            ? 'Illustrated Sacred ${book.titleFor(langCode)} (${book.totalVerses > 0 ? '${book.totalVerses} Pages' : 'PDF'})'
                                            : 'सचित्र संपूर्ण ${book.titleFor(langCode)} (${book.totalVerses > 0 ? '${book.totalVerses} पृष्ठे' : 'PDF'})')),
                                style: GoogleFonts.mukta(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                book.slug == 'dasbodh'
                                    ? (langCode == 'hi'
                                        ? 'मूल हस्तलिखित ग्रंथ • २० दशक, २०० समास एवं आरती'
                                        : (langCode == 'en'
                                            ? 'Original sacred manuscript • 20 Dashakas & Aarti'
                                            : 'मूळ हस्तलिखित ग्रंथ • २० दशक, २०० समास व आरती'))
                                    : (langCode == 'hi'
                                        ? 'मूल पावन महापुराण • एचडी डिजिटल प्रत'
                                        : (langCode == 'en'
                                            ? 'Original sacred scripture • HD Digital Edition'
                                            : 'मूळ पावन महापुराण • एचडी डिजिटल प्रत')),
                                style: GoogleFonts.mukta(
                                  fontSize: 12,
                                  color: const Color(0xFFFFE082),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                langCode == 'hi' ? 'वाचन करें' : (langCode == 'en' ? 'Read' : 'वाचा'),
                                style: GoogleFonts.mukta(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5D1D00),
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Color(0xFF5D1D00),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? MandirTheme.cardBorder
              : Colors.amber.shade200.withValues(alpha: 0.6),
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GranthReaderScreen(
                  book: book,
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
                          ? MandirTheme.primarySaffron.withValues(alpha: 0.3)
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: chapter.isFree
                                    ? Colors.green.shade50
                                    : Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                chapter.isFree
                                    ? (langCode == 'hi' ? 'निःशुल्क' : (langCode == 'en' ? 'Free' : 'मोफत'))
                                    : 'VIP',
                                style: GoogleFonts.mukta(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: chapter.isFree
                                      ? Colors.green.shade800
                                      : Colors.amber.shade900,
                                ),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () => showPremiumPaywallSheet(context, ref, langCode),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B1D18), Color(0xFFE65100)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B1D18).withValues(alpha: 0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.lock_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      langCode == 'hi'
                                          ? 'अनलॉक करें'
                                          : (langCode == 'en' ? 'Unlock' : 'अनलॉक करा'),
                                      style: GoogleFonts.mukta(
                                        fontSize: 12,
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
                        langCode == 'hi'
                            ? '${chapter.versesCount} श्लोक'
                            : (langCode == 'en'
                                ? '${chapter.versesCount} Verses'
                                : '${chapter.versesCount} श्लोक'),
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

  Widget _buildSubscriptionCta(
    BuildContext context,
    WidgetRef ref,
    String langCode,
  ) {
    final bookTitle = book.titleFor(langCode);
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B1D18).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3D6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFF8B1D18),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langCode == 'en'
                          ? 'Unlock All ${book.totalChapters} Chapters of $bookTitle'
                          : (langCode == 'hi'
                              ? '$bookTitle के सभी ${book.totalChapters} अध्याय अनलॉक करें'
                              : '$bookTitleचे सर्व ${book.totalChapters} अध्याय अनलॉक करा'),
                      style: GoogleFonts.mukta(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7A0C08),
                        height: 1.2,
                      ),
                    ),
                    Text(
                      langCode == 'en'
                          ? '7 Days Free Trial • Then ₹51/month'
                          : (langCode == 'hi'
                              ? '7 दिन मुफ्त ट्रायल • फिर ₹51/माह'
                              : '७ दिवस मोफत ट्रायल • मग ₹५१/महिना'),
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B1D18), Color(0xFFE65100)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B1D18).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => showPremiumPaywallSheet(context, ref, langCode),
                icon: const Icon(
                  Icons.lock_open_rounded,
                  size: 18,
                  color: Colors.white,
                ),
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
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/granth.dart';
import '../providers/granth_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/remote_config_provider.dart';
import '../widgets/premium_blurred_gate.dart';
import 'granth_chapter_list_screen.dart';

class GranthCatalogScreen extends ConsumerWidget {
  const GranthCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(granthBooksProvider);
    final langCode = ref.watch(localeProvider).languageCode;
    final isVip = ref.watch(premiumAccessProvider);

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

              // ── Scripture Cards ─────────────────────────────────────────
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

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final book = books[index];
                          return _buildBookCard(context, ref, book, langCode, isVip);
                        },
                        childCount: books.length,
                      ),
                    ),
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
                child: SizedBox(height: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        ? 'श्रीमद्भगवद्गीता, पुराण एवं सनातन आत्मज्ञान'
        : (langCode == 'en'
            ? 'Shrimad Bhagavad Gita, Puranas & Sacred Wisdom'
            : 'श्रीमद्भगवद्गीता, पुराणे व सनातन आत्मज्ञान');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B2500), // Deep Terracotta / Saffron Maroon
            Color(0xFFD84315), // Vibrant Saffron
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD84315).withValues(alpha: 0.28),
            blurRadius: 16,
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
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFFFFE082),
                  size: 26,
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
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      style: GoogleFonts.mukta(
                        fontSize: 13.5,
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
                  : Colors.black.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isVip
                    ? const Color(0xFFFFD54F).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isVip ? Icons.workspace_premium_rounded : Icons.lock_open_rounded,
                  color: isVip ? const Color(0xFFFFD54F) : const Color(0xFFFFE082),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isVip
                        ? (langCode == 'hi'
                            ? 'प्रीमियम सक्रिय • सभी ग्रंथ और अध्याय खुले हैं'
                            : (langCode == 'en'
                                ? 'VIP Active • All scriptures & chapters unlocked'
                                : 'प्रीमियम सक्रिय • सर्व ग्रंथ आणि अध्याय अनलॉक आहेत'))
                        : (langCode == 'hi'
                            ? 'अध्याय १ सभी के लिए निःशुल्क • पूरा पढ़ने के लिए प्रीमियम'
                            : (langCode == 'en'
                                ? 'Chapter 1 Free • Unlock all chapters with VIP'
                                : 'अध्याय १ सर्वांसाठी मोफत • पूर्ण वाचनासाठी प्रीमियम')),
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

  Widget _buildBookCard(
    BuildContext context,
    WidgetRef ref,
    GranthBook book,
    String langCode,
    bool isVip,
  ) {
    final title = book.titleFor(langCode);
    final subtitle = book.subtitleFor(langCode);
    final description = book.descriptionFor(langCode);
    final isActive = book.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? const Color(0xFFE2B04F).withValues(alpha: 0.5)
              : MandirTheme.cardBorder.withValues(alpha: 0.5),
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isActive
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GranthChapterListScreen(book: book),
                    ),
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Title + Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isActive
                              ? [const Color(0xFFD84315), const Color(0xFFE65100)]
                              : [Colors.grey.shade400, Colors.grey.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFD84315).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          (book.coverImage != null && book.coverImage!.isNotEmpty && book.coverImage!.characters.length <= 2)
                              ? book.coverImage!
                              : (book.slug == 'bhagavad-gita'
                                  ? 'ॐ'
                                  : (book.slug == 'dasbodh' ? '🚩' : '📖')),
                          style: book.slug == 'bhagavad-gita'
                              ? GoogleFonts.mukta(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                )
                              : const TextStyle(
                                  fontSize: 24,
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
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: MandirTheme.textDark,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              if (!isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    langCode == 'hi'
                                        ? 'शीघ्र उपलब्ध'
                                        : (langCode == 'en' ? 'Coming Soon' : 'लवकरच'),
                                    style: GoogleFonts.mukta(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: GoogleFonts.mukta(
                                fontSize: 13,
                                color: MandirTheme.primarySaffron,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.mukta(
                    fontSize: 13.5,
                    color: MandirTheme.textMuted,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 14),

                // Bottom Metadata & Action
                Row(
                  children: [
                    // Chapter and verse badges
                    if (book.totalChapters > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: MandirTheme.chipBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: MandirTheme.chipBorder),
                        ),
                        child: Text(
                          book.slug == 'dasbodh'
                              ? (langCode == 'hi'
                                  ? '${book.totalChapters} दशक'
                                  : (langCode == 'en'
                                      ? '${book.totalChapters} Dashakas'
                                      : '${book.totalChapters} दशक'))
                              : (langCode == 'hi'
                                  ? '${book.totalChapters} अध्याय'
                                  : (langCode == 'en'
                                      ? '${book.totalChapters} Chapters'
                                      : '${book.totalChapters} अध्याय')),
                          style: GoogleFonts.mukta(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: MandirTheme.chipText,
                          ),
                        ),
                      ),
                    if (book.totalVerses > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: MandirTheme.chipBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: MandirTheme.chipBorder),
                        ),
                        child: Text(
                          book.pdfUrl != null && (book.totalVerses > 200 || book.slug.contains('purana'))
                              ? (langCode == 'hi'
                                  ? '${book.totalVerses} पृष्ठ'
                                  : (langCode == 'en'
                                      ? '${book.totalVerses} Pages'
                                      : '${book.totalVerses} पृष्ठे'))
                              : (book.slug == 'dasbodh'
                                  ? (langCode == 'hi'
                                      ? '${book.totalVerses} ओव्या'
                                      : (langCode == 'en'
                                          ? '${book.totalVerses} Ovis'
                                          : '${book.totalVerses} ओव्या'))
                                  : (langCode == 'hi'
                                      ? '${book.totalVerses} श्लोक'
                                      : (langCode == 'en'
                                          ? '${book.totalVerses} Verses'
                                          : '${book.totalVerses} श्लोक'))),
                          style: GoogleFonts.mukta(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: MandirTheme.chipText,
                          ),
                        ),
                      ),
                    ],
                    if (book.pdfUrl != null && book.pdfUrl!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              langCode == 'hi' ? 'सचित्र' : (langCode == 'en' ? 'Illustrated' : 'सचित्र'),
                              style: GoogleFonts.mukta(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD84315),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(),

                    if (isActive)
                      Row(
                        children: [
                          Text(
                            langCode == 'hi' ? 'वाचन करें' : (langCode == 'en' ? 'Read Now' : 'वाचन करा'),
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
}

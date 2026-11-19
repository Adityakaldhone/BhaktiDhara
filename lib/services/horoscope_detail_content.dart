import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/entities/horoscope.dart';
import '../presentation/widgets/premium_content_blur.dart';
import 'gemini_horoscope_service.dart';

// ── Design Kit Theme Tokens ──────────────────────────────────────────────────
class _Tokens {
  static const Color ivorySurface = Color(0xFFFBF7EE);
  static const Color guidanceRemedies = Color(0xFFEFE4D2);
  static const Color navyHero = Color(0xFF131F2D);
  static const Color goldOnNavy = Color(0xFFD8B77E);
  static const Color bronzeAccent = Color(0xFF795222);
  static const Color primaryInk = Color(0xFF262A2A);
  static const Color mutedText = Color(0xFF61564A);
  static const Color mainBorder = Color(0xFFE2D6C4);
  static const Color hairline = Color(0xFFDBCCB7);
}

// ── Multi-Language Text Helper ────────────────────────────────────────────────
class _LocalText {
  final String mr;
  final String hi;
  final String en;

  const _LocalText({required this.mr, required this.hi, required this.en});

  String of(String lang) {
    if (lang == 'hi') return hi;
    if (lang == 'en') return en;
    return mr;
  }
}

// ── Comprehensive Horoscope Detail Presentation ──────────────────────────────
class HoroscopeDetailContent extends StatelessWidget {
  const HoroscopeDetailContent({
    super.key,
    required this.page,
    this.compact = false,
    this.langCode,
  });

  final HoroscopePage page;
  final bool compact;
  final String? langCode;

  @override
  Widget build(BuildContext context) {
    final language = langCode ?? Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Navy Overview Hero Card
        _NavyHeroCard(
          page: page,
          isPremium: !compact,
          langCode: language,
        ),

        const SizedBox(height: 18),

        // 2. आजचा दिवस / चालू आठवडा (General Forecast & Moon Transit)
        _ForecastCard(
          page: page,
          langCode: language,
        ),

        const SizedBox(height: 18),

        // 3. कृतीसाठी मार्गदर्शन (Action Guidance: काय करावे व काय टाळावे)
        _ActionGuidanceCard(
          page: page,
          langCode: language,
        ),

        const SizedBox(height: 18),

        // 4. जीवनाचे पैलू (Career, Finance, Relationships, Health)
        _LifeAspectsSection(
          page: page,
          isPremium: !compact,
          langCode: language,
        ),

        const SizedBox(height: 18),

        // 5. शुभ संकेत (Color, Number, Direction)
        _LuckyElementsCard(
          page: page,
          langCode: language,
        ),

        const SizedBox(height: 18),

        // 6. वैदिक उपाय (Mantra Inset Box & Simple Remedy)
        _VedicRemediesCard(
          page: page,
          langCode: language,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 1. NAVY HERO CARD (HERO HEADLINE + ATTENTION BANNER + CELESTIAL GLYPH)
// ═════════════════════════════════════════════════════════════════════════════
class _NavyHeroCard extends StatelessWidget {
  const _NavyHeroCard({
    required this.page,
    required this.isPremium,
    required this.langCode,
  });

  final HoroscopePage page;
  final bool isPremium;
  final String langCode;

  @override
  Widget build(BuildContext context) {
    final rashiId = page.reading.rashiId.toLowerCase();

    final rashiMatch = kAllRashis.firstWhere(
      (r) => r.id.toLowerCase() == rashiId,
      orElse: () => kAllRashis.first,
    );
    final englishName = rashiMatch.nameEn;

    // Parse titles cleanly
    String primaryTitle = '';
    String secondaryTitle = '';

    final rawTitle = page.signTitle.trim();
    if (rawTitle.contains('/')) {
      primaryTitle = rawTitle.split('/').first.trim();
      final rest = rawTitle.split('/').last.trim();
      secondaryTitle = rest.contains('(')
          ? rest.split('(').first.trim()
          : rest;
    } else if (rawTitle.contains('(')) {
      primaryTitle = rawTitle.split('(').first.trim();
      secondaryTitle = rawTitle.split('(').last.replaceAll(')', '').trim();
    } else {
      primaryTitle = rawTitle;
      secondaryTitle = englishName != primaryTitle ? englishName : '';
    }

    // Dynamic attention-grabbing daily hook line
    final moodScore = page.moodScore;
    final attentionTag = switch (moodScore) {
      >= 4.0 => const _LocalText(
        mr: '🌟 आनंद गगनात मावेना! अत्यंत शुभ व फलदायी दिवस',
        hi: '🌟 अत्यंत शुभ व फलदायी दिन — नए अवसर और उन्नति के योग',
        en: '🌟 Highly Favorable & Uplifting Day — Progress & good fortune!',
      ).of(langCode),
      >= 3.5 => const _LocalText(
        mr: '⚖️ संतुलित व समाधानकारक दिवस — संयमाने कामे मार्गी लागतील',
        hi: '⚖️ संतुलित व अनुकूल दिन — समझदारी से सफलता मिलेगी',
        en: '⚖️ Steady & Balanced Day — Consistent progress through patience',
      ).of(langCode),
      _ => const _LocalText(
        mr: '🛡️ सावधगिरी व संयमाचा दिवस — विचारपूर्वक निर्णय घ्या',
        hi: '🛡️ सतर्कता व चिंतन का दिन — सोच-समझकर कदम बढ़ाएं',
        en: '🛡️ Thoughtful & Reflective Day — Exercise patience & care',
      ).of(langCode),
    };

    return Container(
      decoration: BoxDecoration(
        color: _Tokens.navyHero,
        borderRadius: BorderRadius.circular(21),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35131F2D),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            // Celestial glyph rings & zodiac symbol for all signs
            Positioned(
              top: 8,
              right: 12,
              width: 180,
              height: 180,
              child: ExcludeSemantics(
                child: Opacity(
                  opacity: 0.18,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 156,
                          height: 156,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _Tokens.goldOnNavy,
                              width: 1.5,
                            ),
                          ),
                        ),
                        Container(
                          width: 116,
                          height: 116,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _Tokens.goldOnNavy,
                              width: 1,
                            ),
                          ),
                        ),
                        Text(
                          page.symbol,
                          style: const TextStyle(
                            fontSize: 74,
                            color: _Tokens.goldOnNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Live text & info layout
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Forecast Date
                  Text(
                    page.dateAndDay,
                    style: GoogleFonts.mukta(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _Tokens.goldOnNavy.withValues(alpha: 0.95),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Large Sign Name + Secondary subtitle (guaranteed not to overflow)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          primaryTitle,
                          style: GoogleFonts.tiroDevanagariMarathi(
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        if (secondaryTitle.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Text(
                            secondaryTitle,
                            style: GoogleFonts.martel(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              color: _Tokens.goldOnNavy,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Gold accent hairline
                  Container(
                    width: 44,
                    height: 2,
                    decoration: BoxDecoration(
                      color: _Tokens.goldOnNavy,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── NEW: Attention-Grabbing Hook Line ────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _Tokens.goldOnNavy.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _Tokens.goldOnNavy.withValues(alpha: 0.45),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      attentionTag,
                      style: GoogleFonts.mukta(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _Tokens.goldOnNavy,
                        height: 1.25,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Hero Headline
                  Text(
                    page.headline,
                    style: GoogleFonts.tiroDevanagariMarathi(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _Tokens.ivorySurface,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Stars and mood score row
                  Row(
                    children: [
                      ExcludeSemantics(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            final delta = page.moodScore - index;
                            return Icon(
                              delta >= 1
                                  ? Icons.star_rounded
                                  : delta >= 0.5
                                  ? Icons.star_half_rounded
                                  : Icons.star_border_rounded,
                              size: 21,
                              color: _Tokens.goldOnNavy,
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_formatScore(page.moodScore)}/5 · ${page.mood}',
                          style: GoogleFonts.mukta(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: _Tokens.goldOnNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bottom Divider
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),

                  const SizedBox(height: 12),

                  // Range, element and ruling planet row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          page.sunSignDates,
                          style: GoogleFonts.mukta(
                            fontSize: 13,
                            color: _Tokens.ivorySurface.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${page.element} · ${page.rulingPlanet}',
                        style: GoogleFonts.mukta(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _Tokens.ivorySurface.withValues(alpha: 0.85),
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
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. आजचा दिवस / चालू आठवडा (FORECAST & MOON TRANSIT)
// ═════════════════════════════════════════════════════════════════════════════
class _ForecastCard extends StatelessWidget {
  const _ForecastCard({
    required this.page,
    required this.langCode,
  });

  final HoroscopePage page;
  final String langCode;

  @override
  Widget build(BuildContext context) {
    final generalSection = page.fullSections.firstWhere(
      (s) => s.kind == HoroscopeSectionKind.general,
      orElse: () => page.fullSections.first,
    );

    final isWeekly = page.reading.period == 'weekly';
    final cardTitle = isWeekly
        ? const _LocalText(mr: 'चालू आठवडा', hi: 'चालू सप्ताह', en: 'Weekly Forecast').of(langCode)
        : const _LocalText(mr: 'आजचा दिवस', hi: 'आज का दिन', en: "Today's Forecast").of(langCode);

    final badgeText = const _LocalText(mr: 'राशीभविष्य', hi: 'राशिफल', en: 'Horoscope').of(langCode);
    final moonTransitLabel = const _LocalText(mr: 'चंद्र गोचर', hi: 'चन्द्र गोचर', en: 'Moon Transit').of(langCode);

    final bodyText = generalSection.lines.isNotEmpty
        ? generalSection.lines.first.text
        : page.reading.summary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Tokens.ivorySurface,
        border: Border.all(color: _Tokens.mainBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.wb_sunny_outlined,
                color: _Tokens.bronzeAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cardTitle,
                  style: GoogleFonts.tiroDevanagariMarathi(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: _Tokens.primaryInk,
                  ),
                ),
              ),
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _Tokens.guidanceRemedies,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.mukta(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _Tokens.bronzeAccent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Overview Body Paragraph (enlarged font for comfortable reading)
          Text(
            bodyText,
            style: GoogleFonts.mukta(
              fontSize: 16.0,
              color: _Tokens.primaryInk,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 16),

          // Hairline divider
          Container(height: 1, color: _Tokens.hairline),

          const SizedBox(height: 14),

          // Moon Transit Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.nightlight_round,
                  color: _Tokens.bronzeAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moonTransitLabel,
                      style: GoogleFonts.mukta(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: _Tokens.primaryInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      page.transitNote,
                      style: GoogleFonts.mukta(
                        fontSize: 14.5,
                        color: _Tokens.mutedText,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 3. कृतीसाठी मार्गदर्शन (DO'S & DON'TS ACTION GUIDANCE)
// ═════════════════════════════════════════════════════════════════════════════
class _ActionGuidanceCard extends StatelessWidget {
  const _ActionGuidanceCard({
    required this.page,
    required this.langCode,
  });

  final HoroscopePage page;
  final String langCode;

  @override
  Widget build(BuildContext context) {
    final actionsSection = page.fullSections.firstWhere(
      (s) => s.kind == HoroscopeSectionKind.actions,
      orElse: () => page.fullSections.first,
    );

    final title = const _LocalText(
      mr: 'कृतीसाठी मार्गदर्शन',
      hi: 'क्या करें और क्या न करें',
      en: 'Action Guidance',
    ).of(langCode);

    final doLabel = const _LocalText(
      mr: 'काय करावे',
      hi: 'क्या करें',
      en: 'What to do',
    ).of(langCode);

    final avoidLabel = const _LocalText(
      mr: 'काय टाळावे',
      hi: 'क्या न करें',
      en: 'What to avoid',
    ).of(langCode);

    final doLine = actionsSection.lines.isNotEmpty
        ? actionsSection.lines.first
        : (
            label: doLabel,
            text: page.reading.timeSlots.morning.isNotEmpty
                ? page.reading.timeSlots.morning
                : page.reading.remedy,
            score: null,
          );

    final avoidLine = actionsSection.lines.length > 1
        ? actionsSection.lines[1]
        : (
            label: avoidLabel,
            text: page.reading.cautionDetail.isNotEmpty
                ? page.reading.cautionDetail
                : page.reading.cautionTitle,
            score: null,
          );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Tokens.guidanceRemedies,
        border: Border.all(color: _Tokens.hairline),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.explore_outlined,
                color: _Tokens.bronzeAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.tiroDevanagariMarathi(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: _Tokens.primaryInk,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // काय करावे (Do)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: _Tokens.bronzeAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doLabel,
                      style: GoogleFonts.mukta(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: _Tokens.primaryInk,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      doLine.text,
                      style: GoogleFonts.mukta(
                        fontSize: 15.0,
                        color: _Tokens.primaryInk,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // काय टाळावे (Avoid)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.remove_rounded,
                  size: 16,
                  color: Color(0xFF8B2B1B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avoidLabel,
                      style: GoogleFonts.mukta(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: _Tokens.primaryInk,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      avoidLine.text,
                      style: GoogleFonts.mukta(
                        fontSize: 15.0,
                        color: _Tokens.primaryInk,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 4. जीवनाचे पैलू (4 RULED LIFE ASPECTS WITH INDEPENDENT VERDICTS)
// ═════════════════════════════════════════════════════════════════════════════
class _LifeAspectsSection extends StatelessWidget {
  const _LifeAspectsSection({
    required this.page,
    required this.isPremium,
    required this.langCode,
  });

  final HoroscopePage page;
  final bool isPremium;
  final String langCode;

  @override
  Widget build(BuildContext context) {
    final aspectSection = page.fullSections.firstWhere(
      (s) => s.kind == HoroscopeSectionKind.lifeAspects,
      orElse: () => page.fullSections.first,
    );

    final title = const _LocalText(
      mr: 'जीवनाचे पैलू',
      hi: 'जीवन के पहलू',
      en: 'Life Aspects',
    ).of(langCode);

    final icons = [
      Icons.business_center_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.favorite_outline_rounded,
      Icons.monitor_heart_outlined,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          title,
          style: GoogleFonts.tiroDevanagariMarathi(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: _Tokens.primaryInk,
          ),
        ),

        const SizedBox(height: 12),

        // 4 Ruled Aspect Cards
        for (var i = 0; i < aspectSection.lines.length; i++) ...[
          _AspectCard(
            line: aspectSection.lines[i],
            icon: icons[i % icons.length],
            aspectIndex: i,
            isPremium: isPremium,
            langCode: langCode,
          ),
          if (i < aspectSection.lines.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _AspectCard extends StatelessWidget {
  const _AspectCard({
    required this.line,
    required this.icon,
    required this.aspectIndex,
    required this.isPremium,
    required this.langCode,
  });

  final HoroscopeLine line;
  final IconData icon;
  final int aspectIndex;
  final bool isPremium;
  final String langCode;

  @override
  Widget build(BuildContext context) {
    final score = line.score ?? 3.5;

    // Aspect localized titles
    final aspectTitle = switch (aspectIndex) {
      0 => const _LocalText(mr: 'करिअर आणि व्यवसाय', hi: 'करियर और व्यवसाय', en: 'Career & Business').of(langCode),
      1 => const _LocalText(mr: 'धन आणि आर्थिक व्यवहार', hi: 'धन और वित्त', en: 'Finance & Wealth').of(langCode),
      2 => const _LocalText(mr: 'प्रेम आणि नाती', hi: 'प्रेम और रिश्ते', en: 'Love & Relationships').of(langCode),
      _ => const _LocalText(mr: 'आरोग्य आणि दिनक्रम', hi: 'स्वास्थ्य और दिनचर्या', en: 'Health & Wellness').of(langCode),
    };

    // Independent punchy verdict for how the day is for this specific aspect
    final verdict = _getAspectVerdict(aspectIndex, score, langCode);

    final isHigh = score >= 4.0;
    final isLow = score <= 3.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Tokens.ivorySurface,
        border: Border.all(color: _Tokens.mainBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _Tokens.bronzeAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  aspectTitle,
                  style: GoogleFonts.mukta(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: _Tokens.primaryInk,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: _Tokens.guidanceRemedies,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _Tokens.mainBorder.withValues(alpha: 0.7)),
                ),
                child: Text(
                  '${_formatScore(score)}/5',
                  style: GoogleFonts.mukta(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _Tokens.bronzeAccent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Punchy Independent Aspect Verdict Banner ─────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isHigh
                  ? const Color(0xFFF7F0E4)
                  : (isLow ? const Color(0xFFFDF0ED) : const Color(0xFFF4EDE2)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isHigh
                    ? const Color(0xFFD8B77E)
                    : (isLow ? const Color(0xFFE8B4A8) : _Tokens.mainBorder),
                width: 1,
              ),
            ),
            child: Text(
              verdict,
              style: GoogleFonts.mukta(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: isLow ? const Color(0xFF8B2B1B) : _Tokens.primaryInk,
                height: 1.35,
              ),
            ),
          ),

          if (line.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            if (!isPremium)
              BlurredContentGate(
                langCode: langCode,
                borderRadius: 8,
                child: Text(
                  line.text,
                  style: GoogleFonts.mukta(
                    fontSize: 15.0,
                    color: _Tokens.primaryInk,
                    height: 1.55,
                  ),
                ),
              )
            else
              Text(
                line.text,
                style: GoogleFonts.mukta(
                  fontSize: 15.0,
                  color: _Tokens.primaryInk,
                  height: 1.55,
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _getAspectVerdict(int index, double score, String lang) {
    if (index == 0) {
      // Career & Business
      if (score >= 4.0) {
        return const _LocalText(
          mr: '🌟 आनंद गगनात मावेना! मोठे यश व प्रगतीचा सुवर्णयोग',
          hi: '🌟 शानदार दिन — कार्यक्षेत्र में बड़ी सफलता और नए अवसरों का योग',
          en: '🌟 Outstanding Success & Career Breakthrough',
        ).of(lang);
      } else if (score >= 3.5) {
        return const _LocalText(
          mr: '💼 चांगला दिवस — नियोजनपूर्वक कामे मार्गी लागतील',
          hi: '💼 अच्छा दिन — योजनाबद्ध कार्य से सफलता व सहकार्य मिलेगा',
          en: '💼 Productive Day — Steady execution and supportive teamwork',
        ).of(lang);
      } else {
        return const _LocalText(
          mr: '⚡ खडतर प्रवासाचा दिवस — "इकडे आड तिकडे विहीर" टाळा, संयम ठेवा',
          hi: '⚡ चुनौतीपूर्ण दिन — असमंजस और जल्दबाजी से बचें, धैर्य रखें',
          en: '⚡ Demanding Day — Avoid tricky dilemmas and maintain patient focus',
        ).of(lang);
      }
    } else if (index == 1) {
      // Finance & Wealth
      if (score >= 4.0) {
        return const _LocalText(
          mr: '💰 उत्तम धनलाभ — आर्थिक आवक वाढेल व गुंतवणुकीस अनुकूल',
          hi: '💰 श्रेष्ठ धन लाभ — आय में वृद्धि और निवेश के शुभ योग',
          en: '💰 Lucrative Day — Favorable for wealth gains and investments',
        ).of(lang);
      } else if (score >= 3.5) {
        return const _LocalText(
          mr: '📊 आर्थिक स्थिरता — बजेट सांभाळा, अनावश्यक खर्च टाळा',
          hi: '📊 आर्थिक स्थिरता — बजट का ध्यान रखें, संतुलित खर्च करें',
          en: '📊 Balanced Finances — Manage routine expenses and budget carefully',
        ).of(lang);
      } else {
        return const _LocalText(
          mr: '⚠️ सावधगिरीचा इशारा — उधारी, मोठे व्यवहार व अचानक खर्च टाळा',
          hi: '⚠️ सतर्कता बरतें — उधारी और जोखिम भरे सौदे टालें',
          en: '⚠️ Financial Caution — Refrain from lending or impulsive buys',
        ).of(lang);
      }
    } else if (index == 2) {
      // Love & Relationships
      if (score >= 4.0) {
        return const _LocalText(
          mr: '❤️ गोड व आनंददायी दिवस — नात्यात जिव्हाळा वाढेल, मन प्रसन्न राहील',
          hi: '❤️ मधुर व सुखद दिन — रिश्तों में गहरा प्रेम और आत्मीयता बढ़ेगी',
          en: '❤️ Blissful Harmony — Heartfelt warmth, joy and deeper bonding',
        ).of(lang);
      } else if (score >= 3.5) {
        return const _LocalText(
          mr: '🤝 सामंजस्याचा दिवस — कुटुंबासोबत वेळ घालवा, सुखद संवाद घडेल',
          hi: '🤝 सौहार्दपूर्ण दिन — परिवार के साथ गुणवत्तापूर्ण समय बिताएं',
          en: '🤝 Peaceful Connection — Share quality time and constructive thoughts',
        ).of(lang);
      } else {
        return const _LocalText(
          mr: '🕊️ संयम बाळगा — गैरसमज टाळा, वादाऐवजी प्रेमाने मतभेद मिटवा',
          hi: '🕊️ धैर्य रखें — गलतफहमी से बचें, शांत मन से संवाद बनाए रखें',
          en: '🕊️ Handle with Patience — Clear doubts gently through calm communication',
        ).of(lang);
      }
    } else {
      // Health & Wellness
      if (score >= 4.0) {
        return const _LocalText(
          mr: '🌿 पूर्ण ऊर्जा व उत्साह — मानसिक प्रसन्नता व उत्तम शारीरिक स्वास्थ्य',
          hi: '🌿 ऊर्जा और ताजगी से भरपूर — मानसिक शांति और उत्तम स्वास्थ्य',
          en: '🌿 High Energy & Vitality — Refreshed mind and robust well-being',
        ).of(lang);
      } else if (score >= 3.5) {
        return const _LocalText(
          mr: '🧘 मध्यम स्थिती — कामासोबत विश्रांती व संतुलित आहाराचा मेळ घाला',
          hi: '🧘 संतुलित स्वास्थ्य — कार्य के साथ पर्याप्त आराम और पोषण का ध्यान रखें',
          en: '🧘 Moderate Well-being — Balance work and proper rest',
        ).of(lang);
      } else {
        return const _LocalText(
          mr: '💤 विश्रांतीची गरज — ताणतणाव टाळा, आरोग्याकडे दुर्लक्ष करू नका',
          hi: '💤 आराम की आवश्यकता — तनाव से बचें और खान-पान का ध्यान रखें',
          en: '💤 Rest Needed — Ease mental stress and prioritize recovery',
        ).of(lang);
      }
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 5. शुभ संकेत (LUCKY COLOR, NUMBER, DIRECTION)
// ═════════════════════════════════════════════════════════════════════════════
class _LuckyElementsCard extends StatelessWidget {
  const _LuckyElementsCard({
    required this.page,
    required this.langCode,
  });

  final HoroscopePage page;
  final String langCode;

  @override
  Widget build(BuildContext context) {
    final luckySection = page.fullSections.firstWhere(
      (s) => s.kind == HoroscopeSectionKind.luckyElements,
      orElse: () => page.fullSections.first,
    );

    final title = const _LocalText(
      mr: 'शुभ संकेत',
      hi: 'शुभ संकेत',
      en: 'Auspicious Signs',
    ).of(langCode);

    final colorLabel = const _LocalText(
      mr: 'शुभ रंग',
      hi: 'शुभ रंग',
      en: 'Lucky Color',
    ).of(langCode);

    final numberLabel = const _LocalText(
      mr: 'शुभ अंक',
      hi: 'शुभ अंक',
      en: 'Lucky Number',
    ).of(langCode);

    final directionLabel = const _LocalText(
      mr: 'शुभ दिशा',
      hi: 'शुभ दिशा',
      en: 'Lucky Direction',
    ).of(langCode);

    String colorVal = page.reading.luckyColor;
    String numberVal = page.reading.luckyNumber;
    String directionVal = 'पूर्व';

    for (final l in luckySection.lines) {
      final labelLower = l.label.toLowerCase();
      if (l.label.contains('रंग') || labelLower.contains('color')) {
        colorVal = l.text;
      } else if (l.label.contains('अंक') || labelLower.contains('number')) {
        numberVal = l.text;
      } else if (l.label.contains('दिशा') || labelLower.contains('direction')) {
        directionVal = l.text;
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Tokens.ivorySurface,
        border: Border.all(color: _Tokens.mainBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: _Tokens.bronzeAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.tiroDevanagariMarathi(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: _Tokens.primaryInk,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 3 Columns: Color, Number, Direction
          Row(
            children: [
              // Col 1: शुभ रंग
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _resolveColor(colorVal),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      colorLabel,
                      style: GoogleFonts.mukta(
                        fontSize: 14.5,
                        color: _Tokens.mutedText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      colorVal,
                      style: GoogleFonts.mukta(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _Tokens.primaryInk,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Container(width: 1, height: 44, color: _Tokens.hairline),

              // Col 2: शुभ अंक
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '#',
                      style: GoogleFonts.tiroDevanagariMarathi(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _Tokens.bronzeAccent,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      numberLabel,
                      style: GoogleFonts.mukta(
                        fontSize: 14.5,
                        color: _Tokens.mutedText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      numberVal,
                      style: GoogleFonts.mukta(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _Tokens.primaryInk,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Container(width: 1, height: 44, color: _Tokens.hairline),

              // Col 3: शुभ दिशा
              Expanded(
                child: Column(
                  children: [
                    const Icon(
                      Icons.explore_outlined,
                      size: 18,
                      color: _Tokens.bronzeAccent,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      directionLabel,
                      style: GoogleFonts.mukta(
                        fontSize: 14.5,
                        color: _Tokens.mutedText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      directionVal,
                      style: GoogleFonts.mukta(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _Tokens.primaryInk,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _resolveColor(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('लाल') || lower.contains('red')) return const Color(0xFFD32F2F);
    if (lower.contains('पांढरा') || lower.contains('सफेद') || lower.contains('white') || lower.contains('ivory')) {
      return const Color(0xFFFBF7EE);
    }
    if (lower.contains('हिरवा') || lower.contains('हरा') || lower.contains('green')) return const Color(0xFF388E3C);
    if (lower.contains('पिवळा') || lower.contains('पीला') || lower.contains('yellow')) return const Color(0xFFFBC02D);
    if (lower.contains('निळा') || lower.contains('नीला') || lower.contains('blue') || lower.contains('indigo')) {
      return const Color(0xFF1976D2);
    }
    if (lower.contains('सोनेरी') || lower.contains('सुनहरा') || lower.contains('gold')) return const Color(0xFFD8B77E);
    if (lower.contains('केशरी') || lower.contains('नारंगी') || lower.contains('orange')) return const Color(0xFFF57C00);
    return const Color(0xFFB7894A);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 6. वैदिक उपाय (SACRED REMEDIES: MANTRA INSET BOX & SIMPLE REMEDY)
// ═════════════════════════════════════════════════════════════════════════════
class _VedicRemediesCard extends StatelessWidget {
  const _VedicRemediesCard({
    required this.page,
    required this.langCode,
  });

  final HoroscopePage page;
  final String langCode;

  @override
  Widget build(BuildContext context) {
    final spiritualSection = page.fullSections.firstWhere(
      (s) => s.kind == HoroscopeSectionKind.spiritual,
      orElse: () => page.fullSections.first,
    );

    final title = const _LocalText(
      mr: 'वैदिक उपाय',
      hi: 'वैदिक उपाय',
      en: 'Sacred Vedic Remedies',
    ).of(langCode);

    final mantraLabel = const _LocalText(
      mr: 'मंत्र',
      hi: 'मंत्र',
      en: 'Mantra',
    ).of(langCode);

    final simpleRemedyLabel = const _LocalText(
      mr: 'सोपे उपाय',
      hi: 'सरल उपाय',
      en: 'Simple Remedy',
    ).of(langCode);

    String mantraRaw = '';
    String remedyRaw = page.reading.remedy;

    for (final l in spiritualSection.lines) {
      final labelLower = l.label.toLowerCase();
      if (l.label.contains('मंत्र') || labelLower.contains('mantra')) {
        mantraRaw = l.text;
      } else if (l.label.contains('उपाय') || labelLower.contains('remedy')) {
        remedyRaw = l.text;
      }
    }

    if (mantraRaw.isEmpty) {
      mantraRaw = page.reading.deityMantra.isNotEmpty
          ? page.reading.deityMantra
          : 'ॐ नमः शिवाय';
    }

    String mantraOnly = mantraRaw;
    String countOnly = const _LocalText(mr: '११ वेळा जप', hi: '११ बार जप', en: '11 times chant').of(langCode);

    if (mantraRaw.contains('·')) {
      final parts = mantraRaw.split('·');
      mantraOnly = parts.first.trim();
      countOnly = parts.last.trim();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Tokens.guidanceRemedies,
        border: Border.all(color: _Tokens.hairline),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                color: _Tokens.bronzeAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.tiroDevanagariMarathi(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: _Tokens.primaryInk,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Inset Box: Mantra & Count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _Tokens.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mantraLabel,
                  style: GoogleFonts.mukta(
                    fontSize: 14,
                    color: _Tokens.mutedText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mantraOnly,
                  style: GoogleFonts.tiroDevanagariMarathi(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: _Tokens.primaryInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  countOnly,
                  style: GoogleFonts.mukta(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _Tokens.bronzeAccent,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // सोपे उपाय
          Text(
            simpleRemedyLabel,
            style: GoogleFonts.mukta(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _Tokens.primaryInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            remedyRaw,
            style: GoogleFonts.mukta(
              fontSize: 15.5,
              color: _Tokens.primaryInk,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatScore(double score) {
  if (score == score.roundToDouble()) {
    return score.toInt().toString();
  }
  return score.toStringAsFixed(1);
}

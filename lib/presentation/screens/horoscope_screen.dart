import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/horoscope.dart';
// import '../../services/gemini_horoscope_service.dart';
import '../providers/horoscope_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/premium_provider.dart';
import '../widgets/premium_blurred_gate.dart';
import '../widgets/premium_content_blur.dart';

/// Screen displaying Vedic Horoscopes (राशीभविष्य / राशिफल) powered by Google Gemini AI.
class HoroscopeScreen extends ConsumerStatefulWidget {
  const HoroscopeScreen({super.key});

  @override
  ConsumerState<HoroscopeScreen> createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends ConsumerState<HoroscopeScreen> {
  final ScrollController _rashiScrollController = ScrollController();

  // Note: Gemini API key is configured directly in code; dialog preserved for reference
  // void _showApiKeyDialog(BuildContext context) { ... }

  @override
  void dispose() {
    _rashiScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRashi = ref.watch(selectedRashiProvider);
    final selectedPeriod = ref.watch(selectedHoroscopePeriodProvider);
    final readingAsync = ref.watch(currentHoroscopeReadingProvider);
    final langCode = ref.watch(localeProvider).languageCode;

    final screenTitle = langCode == 'mr'
        ? 'दैनिक राशीभविष्य'
        : (langCode == 'hi' ? 'दैनिक राशिफल' : 'Daily Horoscope');

    final subtitle = langCode == 'mr'
        ? 'वैदिक ज्योतिष व ग्रहस्थितीवर आधारित'
        : (langCode == 'hi'
              ? 'वैदिक ज्योतिष व ग्रह स्थिति पर आधारित'
              : 'Based on Vedic Astrology & Planetary Transits');

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      body: Stack(
        children: [
          // Background sacred temple watermark
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/aarti_screen/bg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Header ───────────────────────────────────────────────
                _buildHeader(screenTitle, subtitle),

                // ── Period Selector (Today / Tomorrow / Weekly) ──────────────
                _buildPeriodSelector(selectedPeriod, langCode),

                const SizedBox(height: 8),

                // ── 12 Rashi Horizontal Carousel ─────────────────────────────
                _buildRashiCarousel(selectedRashi, langCode),

                const SizedBox(height: 8),

                // ── Horoscope Reading Content ────────────────────────────────
                Expanded(
                  child: readingAsync.when(
                    loading: () => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: MandirTheme.primarySaffron,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            langCode == 'mr'
                                ? 'ग्रहांची स्थिती व भविष्य जाणून घेत आहोत...'
                                : (langCode == 'hi'
                                      ? 'ग्रहों की स्थिति व राशिफल प्राप्त हो रहा है...'
                                      : 'Consulting celestial planetary transits...'),
                            style: GoogleFonts.mukta(
                              fontSize: 16,
                              color: const Color(0xFF7A0C08),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 44,
                              color: Color(0xFF8B1D18),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'राशीभविष्य लोड करता आले नाही',
                              style: GoogleFonts.mukta(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF7A0C08),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                ref
                                    .read(
                                      horoscopeRefreshTriggerProvider.notifier,
                                    )
                                    .state++;
                              },
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('पुन्हा प्रयत्न करा'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MandirTheme.primarySaffron,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (reading) {
                      final isPremium = ref.watch(isPremiumProvider);
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // Hero card + Quick Badges: always visible (free teaser)
                          _buildHeroCard(selectedRashi, reading, langCode),
                          const SizedBox(height: 12),
                          _buildQuickBadges(reading, langCode),
                          const SizedBox(height: 12),
                          // Aspect Cards (Career & Finance, Health & Energy, Family & Love):
                          // Titles are ALWAYS visible! Only the description below each title is blurred for free users.
                          _buildAspectCards(reading, langCode, isPremium),
                          const SizedBox(height: 14),
                          // Vedic Remedy Card: Title is ALWAYS visible! Only remedy text below is blurred.
                          _buildRemedyCard(reading, langCode, isPremium),
                          if (!isPremium) ...[
                            const SizedBox(height: 14),
                            _buildSubscriptionCta(langCode),
                          ],
                          const SizedBox(height: 14),
                          _buildAiFooter(reading, langCode),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ॐ',
                      style: GoogleFonts.mukta(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B1D18),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.mukta(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: MandirTheme.textDark,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.mukta(
                    fontSize: 14,
                    color: const Color(0xFF8B6040),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Premium Badge / Button
          Builder(
            builder: (ctx) {
              final isPremium = ref.watch(isPremiumProvider);
              final langCode = ref.watch(localeProvider).languageCode;
              return GestureDetector(
                onTap: () => showPremiumPaywallSheet(context, ref, langCode),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPremium
                          ? const [Color(0xFFFFF3D6), Color(0xFFFFD54F)]
                          : const [Color(0xFF8B1D18), Color(0xFFE65100)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isPremium
                                ? const Color(0xFFD4AF37)
                                : const Color(0xFF8B1D18))
                            .withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPremium
                            ? Icons.stars_rounded
                            : Icons.workspace_premium_rounded,
                        color: isPremium
                            ? const Color(0xFF8B1D18)
                            : Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPremium
                            ? (langCode == 'en' ? 'VIP' : 'प्रीमियम')
                            : (langCode == 'en' ? '₹51' : '₹५१'),
                        style: GoogleFonts.mukta(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPremium
                              ? const Color(0xFF7A0C08)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERIOD SELECTOR (Today / Tomorrow / Weekly)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPeriodSelector(String currentPeriod, String langCode) {
    final periods = [
      {
        'key': 'today',
        'label': langCode == 'mr' ? 'आज' : (langCode == 'hi' ? 'आज' : 'Today'),
      },
      {
        'key': 'tomorrow',
        'label': langCode == 'mr'
            ? 'उद्या'
            : (langCode == 'hi' ? 'कल' : 'Tomorrow'),
      },
      {
        'key': 'weekly',
        'label': langCode == 'mr'
            ? 'साप्ताहिक'
            : (langCode == 'hi' ? 'साप्ताहिक' : 'Weekly'),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFEFE8D8),
          borderRadius: BorderRadius.circular(19),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: periods.map((p) {
            final isSelected = currentPeriod == p['key'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  ref.read(selectedHoroscopePeriodProvider.notifier).state =
                      p['key']!;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? MandirTheme.primarySaffron
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: MandirTheme.primarySaffron.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    p['label']!,
                    style: GoogleFonts.mukta(
                      fontSize: 15.5,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF6D5545),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 12 RASHI CAROUSEL
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRashiCarousel(Rashi selectedRashi, String langCode) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        controller: _rashiScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: kAllRashis.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final rashi = kAllRashis[index];
          final isSelected = rashi.id == selectedRashi.id;

          return GestureDetector(
            onTap: () {
              ref.read(selectedRashiProvider.notifier).state = rashi;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 78,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFF7E6) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? MandirTheme.primarySaffron
                      : const Color(0xFFEBE0CE),
                  width: isSelected ? 1.8 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: MandirTheme.primarySaffron.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    rashi.symbol,
                    style: TextStyle(
                      fontSize: 24,
                      color: isSelected
                          ? MandirTheme.primarySaffron
                          : const Color(0xFF8B6040),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rashi.localizedName(langCode),
                    style: GoogleFonts.mukta(
                      fontSize: 14.5,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF7A0C08)
                          : const Color(0xFF5A4535),
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO CARD (Rashi details + summary + auspicious meter)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroCard(
    Rashi rashi,
    HoroscopeReading reading,
    String langCode,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAD8B0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A5A2B).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Symbol + Rashi Name + Auspicious Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFEDD0), Color(0xFFFFD59E)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD4AF37),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(rashi.symbol, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rashi.localizedName(langCode)} (${rashi.nameEn})',
                      style: GoogleFonts.mukta(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7A0C08),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${rashi.rulingPlanet} • ${rashi.element}',
                      style: GoogleFonts.mukta(
                        fontSize: 14.5,
                        color: const Color(0xFF8B6040),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Auspicious percentage chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF81C784)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${reading.auspiciousPercentage}%',
                      style: GoogleFonts.mukta(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      langCode == 'mr'
                          ? 'शुभ योग'
                          : (langCode == 'hi' ? 'शुभ' : 'Favorable'),
                      style: GoogleFonts.mukta(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E7D32),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF0E4D0), height: 1),
          const SizedBox(height: 10),

          // Date tag
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Color(0xFF8B6040),
              ),
              const SizedBox(width: 6),
              Text(
                reading.dateText,
                style: GoogleFonts.mukta(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8B6040),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Summary Text
          Text(
            reading.summary,
            style: GoogleFonts.mukta(
              fontSize: 16.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4A3525),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK BADGES (Lucky Number, Lucky Color)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildQuickBadges(HoroscopeReading reading, String langCode) {
    final numLabel = langCode == 'mr'
        ? 'भाग्यशाली अंक'
        : (langCode == 'hi' ? 'शुभ अंक' : 'Lucky Number');

    final colorLabel = langCode == 'mr'
        ? 'शुभ रंग'
        : (langCode == 'hi' ? 'शुभ रंग' : 'Lucky Color');

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEBE0CE)),
            ),
            child: Row(
              children: [
                const Text('🍀', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        numLabel,
                        style: GoogleFonts.mukta(
                          fontSize: 13,
                          color: const Color(0xFF8B6040),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        reading.luckyNumber,
                        style: GoogleFonts.mukta(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7A0C08),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEBE0CE)),
            ),
            child: Row(
              children: [
                const Text('🎨', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        colorLabel,
                        style: GoogleFonts.mukta(
                          fontSize: 13,
                          color: const Color(0xFF8B6040),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        reading.luckyColor,
                        style: GoogleFonts.mukta(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7A0C08),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ASPECT CARDS (Career, Health, Love)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAspectCards(
    HoroscopeReading reading,
    String langCode,
    bool isPremium,
  ) {
    final aspects = [
      {
        'icon': '💼',
        'title': langCode == 'mr'
            ? 'कार्य व आर्थिक स्थिती'
            : (langCode == 'hi' ? 'करियर व धन' : 'Career & Finance'),
        'desc': reading.career,
      },
      {
        'icon': '🌿',
        'title': langCode == 'mr'
            ? 'आरोग्य व मानसिक शांतता'
            : (langCode == 'hi' ? 'स्वास्थ्य व ऊर्जा' : 'Health & Energy'),
        'desc': reading.health,
      },
      {
        'icon': '💖',
        'title': langCode == 'mr'
            ? 'कौटुंबिक व प्रेम जीवन'
            : (langCode == 'hi' ? 'परिवार व संबंध' : 'Family & Love'),
        'desc': reading.love,
      },
    ];

    return Column(
      children: aspects.map((asp) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEBE0CE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(asp['icon']!, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE IS ALWAYS VISIBLE AND UNBLURRED!
                    Text(
                      asp['title']!,
                      style: GoogleFonts.mukta(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7A0C08),
                      ),
                    ),
                    const SizedBox(height: 3),
                    // ONLY THE DESCRIPTION BELOW IS BLURRED FOR FREE USERS:
                    if (isPremium)
                      Text(
                        asp['desc']!,
                        style: GoogleFonts.mukta(
                          fontSize: 15.5,
                          color: const Color(0xFF5A4535),
                          height: 1.45,
                        ),
                      )
                    else
                      BlurredContentGate(
                        langCode: langCode,
                        child: Text(
                          asp['desc']!,
                          style: GoogleFonts.mukta(
                            fontSize: 15.5,
                            color: const Color(0xFF5A4535),
                            height: 1.45,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REMEDY CARD (Vedic Upay)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRemedyCard(
    HoroscopeReading reading,
    String langCode,
    bool isPremium,
  ) {
    final remedyLabel = langCode == 'mr'
        ? 'आजचा विशेष सिद्ध उपाय'
        : (langCode == 'hi' ? 'आज का विशेष उपाय' : 'Vedic Divine Remedy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF9E6), Color(0xFFFFECC4)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A5A2B).withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🪔', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE IS ALWAYS VISIBLE AND UNBLURRED!
                Text(
                  remedyLabel,
                  style: GoogleFonts.mukta(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8B1D18),
                  ),
                ),
                const SizedBox(height: 4),
                // ONLY REMEDY CONTENT BELOW IS BLURRED FOR FREE USERS:
                if (isPremium)
                  Text(
                    reading.remedy,
                    style: GoogleFonts.mukta(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5A2010),
                      height: 1.45,
                    ),
                  )
                else
                  BlurredContentGate(
                    langCode: langCode,
                    child: Text(
                      reading.remedy,
                      style: GoogleFonts.mukta(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5A2010),
                        height: 1.45,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBSCRIPTION CTA BANNER (For Free Users)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSubscriptionCta(String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B1D18).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFF3D6),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFD4AF37),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langCode == 'en'
                          ? 'Unlock All 12 Rashi Forecasts'
                          : (langCode == 'hi'
                              ? 'सभी 12 राशियों का विस्तृत भविष्य'
                              : 'सर्व १२ राशींचे सविस्तर भविष्य अनलॉक करा'),
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
                onPressed: () =>
                    showPremiumPaywallSheet(context, ref, langCode),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // AI FOOTER & REFRESH BUTTON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAiFooter(HoroscopeReading reading, String langCode) {
    return Center(
      child: Column(
        children: [
          TextButton.icon(
            onPressed: () {
              ref.read(horoscopeRefreshTriggerProvider.notifier).state++;
            },
            icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF8B1D18)),
            label: Text(
              langCode == 'mr'
                  ? 'नवीन भविष्य मिळवा (Refresh)'
                  : (langCode == 'hi'
                        ? 'नया राशिफल प्राप्त करें (Refresh)'
                        : 'Refresh'),
              style: GoogleFonts.mukta(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8B1D18),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                reading.isAiGenerated ? Icons.auto_awesome : Icons.temple_hindu,
                size: 15,
                color: const Color(0xFF9E7B5A),
              ),
              const SizedBox(width: 6),
              Text(
                reading.isAiGenerated
                    ? 'Powered by Google Gemini & Vedic Astrology'
                    : 'Authentic Vedic Jyotish Knowledge Engine',
                style: GoogleFonts.mukta(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF9E7B5A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
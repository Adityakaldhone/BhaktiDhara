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
import '../../services/personal_numerology_service.dart';
import '../../services/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen displaying Vedic Horoscopes (राशीभविष्य / राशिफल) powered by Google Gemini AI.
class HoroscopeScreen extends ConsumerStatefulWidget {
  final String? initialRashiId;
  final String? focusSection;

  const HoroscopeScreen({
    super.key,
    this.initialRashiId,
    this.focusSection,
  });

  @override
  ConsumerState<HoroscopeScreen> createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends ConsumerState<HoroscopeScreen> {
  final ScrollController _rashiScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();
  final TextEditingController _questionInputController = TextEditingController();
  bool _isConsultingAi = false;
  VedicAiConsultation? _consultationResult;
  String? _consultedQuestion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.initialRashiId != null && widget.initialRashiId!.isNotEmpty) {
        final match = kAllRashis.firstWhere(
          (r) => r.id.toLowerCase() == widget.initialRashiId!.toLowerCase(),
          orElse: () => kAllRashis.first,
        );
        ref.read(selectedRashiProvider.notifier).state = match;
        _scrollCarouselToRashi(match);
      } else {
        await _loadSavedPreferredRashi();
      }

      if (widget.focusSection != null) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        _scrollToSection(widget.focusSection!);
      }
    });
  }

  Future<void> _loadSavedPreferredRashi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('user_preferred_rashi_id');
      if (savedId != null && savedId.isNotEmpty) {
        final match = kAllRashis.firstWhere(
          (r) => r.id.toLowerCase() == savedId.toLowerCase(),
          orElse: () => kAllRashis.first,
        );
        if (mounted) {
          ref.read(selectedRashiProvider.notifier).state = match;
          _scrollCarouselToRashi(match);
        }
      }
    } catch (_) {}
  }

  void _scrollCarouselToRashi(Rashi rashi) {
    final index = kAllRashis.indexWhere((r) => r.id == rashi.id);
    if (index >= 0 && _rashiScrollController.hasClients) {
      _rashiScrollController.animateTo(
        index * 86.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToSection(String sectionKey) {
    if (!_listScrollController.hasClients) return;
    double offset = 0;
    if (sectionKey == 'caution') {
      offset = 480;
    } else if (sectionKey == 'time_slots') {
      offset = 780;
    } else if (sectionKey == 'vedic_ai') {
      offset = 1100;
    }
    _listScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // Note: Gemini API key is configured directly in code; dialog preserved for reference
  // void _showApiKeyDialog(BuildContext context) { ... }

  @override
  void dispose() {
    _rashiScrollController.dispose();
    _listScrollController.dispose();
    _questionInputController.dispose();
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
                        controller: _listScrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // Hero card + Quick Badges: always visible (free teaser)
                          _buildHeroCard(selectedRashi, reading, langCode),
                          const SizedBox(height: 12),
                          _buildQuickBadges(reading, langCode),
                          const SizedBox(height: 12),
                          // Phase 4: नावावरून वैयक्तिक भाग्य मीटर (Personalization Hook: Name initial vibration)
                          _buildPersonalizedMeterSection(selectedRashi, reading, langCode, isPremium),
                          const SizedBox(height: 12),
                          // Phase 1: सावधगिरीचा इशारा (Caution & Avoidance Hook - "आज काय टाळावे?")
                          _buildCautionCard(reading, langCode, isPremium),
                          const SizedBox(height: 12),
                          // Phase 2: वेळेनुसार ३-टाइम-स्लॉट भविष्य (Hourly 3-Time-Slot Forecast: सकाळ Free, दुपार व संध्याकाळ Gated)
                          _buildTimeSlotsSection(reading, langCode, isPremium),
                          const SizedBox(height: 12),
                          // Phase 3: आजची मैत्री व सावध रास + इष्टदेवता बीजमंत्र (Daily Compatibility & Deity)
                          _buildCompatibilityAndDeitySection(reading, langCode, isPremium),
                          const SizedBox(height: 12),
                          // Phase 5: वेदिक AI ज्योतिष - १ वैयक्तिक प्रश्न (Ask 1 Vedic AI Question)
                          _buildVedicAiConsultCard(selectedRashi, langCode, isPremium),
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
                          // Phase 6: सकाळी ६ ची उत्कंठावर्धक पुश नोटिफिकेशन (Daily 6 AM Notification Card)
                          _buildMorningNotificationCard(selectedRashi, langCode),
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
            onTap: () async {
              ref.read(selectedRashiProvider.notifier).state = rashi;
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_preferred_rashi_id', rashi.id);
              } catch (_) {}
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
  // CAUTION & AVOIDANCE CARD (Phase 1: आज काय टाळावे? / सावधगिरीचा इशारा)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCautionCard(
    HoroscopeReading reading,
    String langCode,
    bool isPremium,
  ) {
    final alertLabel = langCode == 'mr'
        ? 'सावधगिरीचा इशारा (आज काय टाळावे?)'
        : (langCode == 'hi' ? 'सावधानी संकेत (आज क्या न करें?)' : 'Caution & Avoidance Alert');

    final title = reading.cautionTitle.isNotEmpty
        ? reading.cautionTitle
        : (langCode == 'mr'
            ? 'आज दुपारी घाईगडबडीत आर्थिक निर्णय व वादविवाद टाळावेत.'
            : (langCode == 'hi'
                ? 'आज दोपहर जल्दबाजी में धन निवेश और व्यर्थ विवाद से बचें।'
                : 'Avoid hasty financial commitments or heated arguments today.'));

    final detail = reading.cautionDetail.isNotEmpty
        ? reading.cautionDetail
        : (langCode == 'mr'
            ? 'ग्रहांच्या स्थितीनुसार आज कामाच्या ठिकाणी गैरसमज किंवा पैशांची गळती संभवते. महत्त्वाच्या कागदपत्रांची दोनदा तपासणी करा आणि रागावर नियंत्रण ठेवा.'
            : (langCode == 'hi'
                ? 'ग्रहों के प्रभाव से वाणी में उग्रता आ सकती है। वरिष्ठों व साझेदारों के साथ धैर्य रखें और नए अनुबंधों पर सोच-समझकर हस्ताक्षर करें।'
                : 'Planetary transits indicate potential impulsiveness. Keep your temper balanced and double-check important financial decisions before committing.'));

    final window = reading.cautionWindow.isNotEmpty
        ? reading.cautionWindow
        : (langCode == 'mr'
            ? 'दुपारी १२:०० - ०३:३०'
            : (langCode == 'hi' ? 'दोपहर १२:०० - ०३:३०' : '12:00 PM - 03:30 PM'));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE65100).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Alert Badge & Time Window
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0B2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('⚠️', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  alertLabel,
                  style: GoogleFonts.mukta(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB71C1C),
                    height: 1.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFFC62828)),
                    const SizedBox(width: 4),
                    Text(
                      window,
                      style: GoogleFonts.mukta(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFC62828),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // PUNCHY DANGER PREVIEW: ALWAYS UNBLURRED!
          Text(
            title,
            style: GoogleFonts.mukta(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B1D18),
              height: 1.35,
            ),
          ),

          const SizedBox(height: 6),

          // SPECIFIC ASTROLOGICAL REASON & TRAP TO AVOID: BLURRED FOR FREE USERS!
          if (isPremium)
            Text(
              detail,
              style: GoogleFonts.mukta(
                fontSize: 15,
                color: const Color(0xFF5D4037),
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            BlurredContentGate(
              langCode: langCode,
              child: Text(
                detail,
                style: GoogleFonts.mukta(
                  fontSize: 15,
                  color: const Color(0xFF5D4037),
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIME SLOTS SECTION (Phase 2: वेळेनुसार ३-काळ भविष्य)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTimeSlotsSection(
    HoroscopeReading reading,
    String langCode,
    bool isPremium,
  ) {
    final sectionTitle = langCode == 'mr'
        ? 'वेळेनुसार दैनिक काळ व भविष्य'
        : (langCode == 'hi' ? 'समयानुसार दैनिक काल व मार्गदर्शन' : 'Hourly Time-Slot Forecast');

    final sectionSubtitle = langCode == 'mr'
        ? 'सकाळ (मोफत), दुपार व संध्याकाळची ऊर्जा'
        : (langCode == 'hi' ? 'सुबह (निःशुल्क), दोपहर व शाम की ऊर्जा' : 'Morning (Free), Afternoon & Evening guidance');

    final currentHour = DateTime.now().hour;
    final isMorningActive = currentHour >= 5 && currentHour < 12;
    final isAfternoonActive = currentHour >= 12 && currentHour < 17;
    final isEveningActive = currentHour >= 17 || currentHour < 5;

    final morningDesc = reading.timeSlots.morning.isNotEmpty
        ? reading.timeSlots.morning
        : (langCode == 'mr'
            ? 'सकाळी ६ ते १२: दिवसाची सुरुवात शांत चित्ताने व इष्टदेवतेच्या आराधनेने करा. नवीन संकल्प व महत्त्वपूर्ण नियोजनासाठी सकाळची वेळ अत्यंत फलदायी आहे.'
            : (langCode == 'hi'
                ? 'सुबह ६ से १२: दिन का प्रारंभ ईष्टदेव के स्मरण एवं सकारात्मक ऊर्जा के साथ करें। नए कार्यों के चिंतन के लिए यह समय शुभ है।'
                : '06:00 AM - 12:00 PM: Start your day with positive spiritual affirmations. Early hours are auspicious for planning, prayers, and clear focus.'));

    final afternoonDesc = reading.timeSlots.afternoon.isNotEmpty
        ? reading.timeSlots.afternoon
        : (langCode == 'mr'
            ? 'दुपारी १२ ते ५: कामाच्या ठिकाणी सहकाऱ्यांशी समन्वय ठेवा. आर्थिक देवाणघेवाण व बैठकांमध्ये संयम बाळगल्यास उत्तम यश मिळेल.'
            : (langCode == 'hi'
                ? 'दोपहर १२ से ५: कार्यक्षेत्र में विवेकपूर्ण निर्णय लें। व्यापारिक सौदों और धन से जुड़े मामलों में सतर्कता बरतें।'
                : '12:00 PM - 05:00 PM: Navigate professional responsibilities with patience. Double-check contracts and exercise prudence in meetings.'));

    final eveningDesc = reading.timeSlots.evening.isNotEmpty
        ? reading.timeSlots.evening
        : (langCode == 'mr'
            ? 'संध्याकाळी ५ ते १०: कौटुंबिक सौख्य वाढेल. कामाचा अतिरिक्त ताण विसरून कुटुंबीयांसमवेत वेळ घालवा व सात्त्विक आहारावर भर द्या.'
            : (langCode == 'hi'
                ? 'शाम ५ से १०: परिजनों के साथ आनंदमय समय व्यतीत होगा। तनाव से दूर रहकर संध्या आरती एवं विश्राम पर ध्यान दें।'
                : '05:00 PM - 10:00 PM: Unwind with family and loved ones. Dedicate peaceful moments to gratitude, light dining, and rejuvenation.'));

    final slots = [
      {
        'icon': '🌅',
        'title': langCode == 'mr'
            ? 'सकाळ (प्रातःकाल ऊर्जा)'
            : (langCode == 'hi' ? 'सुबह (प्रातःकाल ऊर्जा)' : 'Morning Focus'),
        'time': langCode == 'mr'
            ? '०६:०० AM - १२:०० PM'
            : (langCode == 'hi' ? '०६:०० AM - १२:०० PM' : '06:00 AM - 12:00 PM'),
        'desc': morningDesc,
        'isActive': isMorningActive,
        'isFree': true,
      },
      {
        'icon': '☀️',
        'title': langCode == 'mr'
            ? 'दुपार (निर्णय व व्यवहार)'
            : (langCode == 'hi' ? 'दोपहर (निर्णय व व्यापार)' : 'Afternoon Strategy'),
        'time': langCode == 'mr'
            ? '१२:०० PM - ०५:०० PM'
            : (langCode == 'hi' ? '१२:०० PM - ०५:०० PM' : '12:00 PM - 05:00 PM'),
        'desc': afternoonDesc,
        'isActive': isAfternoonActive,
        'isFree': false,
      },
      {
        'icon': '🌙',
        'title': langCode == 'mr'
            ? 'संध्याकाळ (कौटुंबिक व विश्रांती)'
            : (langCode == 'hi' ? 'शाम (पारिवारिक व विश्राम)' : 'Evening Rejuvenation'),
        'time': langCode == 'mr'
            ? '०५:०० PM - १०:०० PM'
            : (langCode == 'hi' ? '०५:०० PM - १०:०० PM' : '05:00 PM - 10:00 PM'),
        'desc': eveningDesc,
        'isActive': isEveningActive,
        'isFree': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              const Text('⏳', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionTitle,
                      style: GoogleFonts.mukta(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: MandirTheme.textDark,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      sectionSubtitle,
                      style: GoogleFonts.mukta(
                        fontSize: 12.5,
                        color: const Color(0xFF8B6040),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 3 Time Slot Cards
        ...slots.map((slot) {
          final isFree = slot['isFree'] as bool;
          final isActive = slot['isActive'] as bool;
          final canView = isFree || isPremium;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? const Color(0xFFE65100)
                    : const Color(0xFFEBE0CE),
                width: isActive ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? const Color(0xFFE65100).withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: isActive ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  children: [
                    Text(
                      slot['icon'] as String,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slot['title'] as String,
                            style: GoogleFonts.mukta(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF7A0C08),
                              height: 1.1,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: Color(0xFF8B6040),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                slot['time'] as String,
                                style: GoogleFonts.mukta(
                                  fontSize: 12,
                                  color: const Color(0xFF8B6040),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status Badge (Active now / Free / Lock)
                    if (isActive) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFB74D)),
                        ),
                        child: Text(
                          langCode == 'mr'
                              ? 'चालू वेळ'
                              : (langCode == 'hi' ? 'सक्रिय' : 'Active Now'),
                          style: GoogleFonts.mukta(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE65100),
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isFree
                            ? const Color(0xFFE8F5E9)
                            : (isPremium
                                ? const Color(0xFFFFF8E1)
                                : const Color(0xFFFBE9E7)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isFree
                              ? const Color(0xFF81C784)
                              : (isPremium
                                  ? const Color(0xFFFFD54F)
                                  : const Color(0xFFFFAB91)),
                        ),
                      ),
                      child: Text(
                        isFree
                            ? (langCode == 'mr'
                                ? 'मोफत'
                                : (langCode == 'hi' ? 'मुफ्त' : 'Free'))
                            : (canView
                                ? (langCode == 'mr'
                                    ? 'प्रिमियम'
                                    : (langCode == 'hi' ? 'प्रीमियम' : 'VIP'))
                                : (langCode == 'mr'
                                    ? '🔒 लॉक'
                                    : (langCode == 'hi' ? '🔒 लॉक' : '🔒 Locked'))),
                        style: GoogleFonts.mukta(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isFree
                              ? const Color(0xFF2E7D32)
                              : (canView
                                  ? const Color(0xFFB78103)
                                  : const Color(0xFFC62828)),
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Content
                if (canView)
                  Text(
                    slot['desc'] as String,
                    style: GoogleFonts.mukta(
                      fontSize: 15,
                      color: const Color(0xFF5A4535),
                      height: 1.45,
                    ),
                  )
                else
                  BlurredContentGate(
                    langCode: langCode,
                    child: Text(
                      slot['desc'] as String,
                      style: GoogleFonts.mukta(
                        fontSize: 15,
                        color: const Color(0xFF5A4535),
                        height: 1.45,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPATIBILITY & DEITY SECTION (Phase 3: मैत्री रास व इष्टदेवता मंत्र)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCompatibilityAndDeitySection(
    HoroscopeReading reading,
    String langCode,
    bool isPremium,
  ) {
    final compatTitle = langCode == 'mr'
        ? 'आजचे अनुकूल भागीदार व मैत्री रास'
        : (langCode == 'hi' ? 'आज के अनुकूल मित्र व सतर्क राशि' : 'Daily Sign Synergy & Caution');

    final compatRashi = reading.compatibleRashi.isNotEmpty
        ? reading.compatibleRashi
        : (langCode == 'mr'
            ? 'सिंह व धनु'
            : (langCode == 'hi' ? 'सिंह व धनु' : 'Leo & Sagittarius'));

    final cautionRashi = reading.cautionRashi.isNotEmpty
        ? reading.cautionRashi
        : (langCode == 'mr'
            ? 'वृश्चिक'
            : (langCode == 'hi' ? 'वृश्चिक' : 'Scorpio'));

    final compatTip = reading.compatibilityTip.isNotEmpty
        ? reading.compatibilityTip
        : (langCode == 'mr'
            ? 'सिंह व धनु राशीच्या सहकाऱ्यांशी कामात उत्तम समन्वय व धनलाभ होईल. वृश्चिक राशीच्या व्यक्तींशी बोलताना शांतता ठेवा.'
            : (langCode == 'hi'
                ? 'सिंह व धनु राशि के व्यक्तियों के साथ कार्ययोजना में लाभ होगा। वृश्चिक राशि से व्यर्थ वाद-विवाद टालें।'
                : 'Synergy with Leo and Sagittarius brings notable progress. Maintain patient dialogue with Scorpio to prevent friction.'));

    final deityTitle = langCode == 'mr'
        ? 'आजची इष्टदेवता व ग्रह शांती बीजमंत्र'
        : (langCode == 'hi' ? 'आज के इष्टदेव व ग्रह शांति बीजमंत्र' : 'Ruling Deity & Planetary Beej Mantra');

    final rulingDeity = reading.rulingDeity.isNotEmpty
        ? reading.rulingDeity
        : (langCode == 'mr'
            ? 'श्री विघ्नहर्ता गणेश व सूर्यदेव'
            : (langCode == 'hi' ? 'भगवान श्री गणेश एवं सूर्य नारायण' : 'Lord Ganesha & Lord Surya'));

    final deityMantra = reading.deityMantra.isNotEmpty
        ? reading.deityMantra
        : (langCode == 'mr'
            ? 'ॐ गं गणपतये नमः (२१ वेळा जप)'
            : (langCode == 'hi' ? 'ॐ गं गणपतये नमः (२१ बार जप)' : 'Om Gam Ganapataye Namaha (Chant 21 times)'));

    final mantraBenefit = reading.mantraBenefit.isNotEmpty
        ? reading.mantraBenefit
        : (langCode == 'mr'
            ? 'या पवित्र मंत्राच्या जपाने आज कामातील विघ्ने दूर होऊन आत्मविश्वासात वाढ होईल आणि ग्रहदोष शांत होतील.'
            : (langCode == 'hi'
                ? 'इस पवित्र मंत्र के जप से मानसिक स्पष्टता प्राप्त होगी और कार्यों के विघ्न दूर होंगे।'
                : 'Chanting this sacred mantra dispels obstacles, calms planetary friction, and brings clarity.'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Sign Compatibility Card
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEBE0CE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🤝', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      compatTitle,
                      style: GoogleFonts.mukta(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7A0C08),
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Friendly Sign Pill
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF81C784)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('💚', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  langCode == 'mr'
                                      ? 'अनुकूल मैत्री रास'
                                      : (langCode == 'hi' ? 'मित्र राशि' : 'Lucky Sign'),
                                  style: GoogleFonts.mukta(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2E7D32),
                                    height: 1.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            compatRashi,
                            style: GoogleFonts.mukta(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B5E20),
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Caution Sign Pill
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFB74D)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('⚠️', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  langCode == 'mr'
                                      ? 'सावध राहावयाची रास'
                                      : (langCode == 'hi' ? 'सतर्क राशि' : 'Caution Sign'),
                                  style: GoogleFonts.mukta(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFE65100),
                                    height: 1.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            cautionRashi,
                            style: GoogleFonts.mukta(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFBF360C),
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (isPremium)
                Text(
                  compatTip,
                  style: GoogleFonts.mukta(
                    fontSize: 14.5,
                    color: const Color(0xFF5A4535),
                    height: 1.4,
                  ),
                )
              else
                BlurredContentGate(
                  langCode: langCode,
                  child: Text(
                    compatTip,
                    style: GoogleFonts.mukta(
                      fontSize: 14.5,
                      color: const Color(0xFF5A4535),
                      height: 1.4,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 2. Sacred Deity & Beej Mantra Card
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFDF5), Color(0xFFFFF7E6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0C475), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🪔', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deityTitle,
                      style: GoogleFonts.mukta(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B1D18),
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBE9E7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFCCBC)),
                    ),
                    child: Text(
                      rulingDeity,
                      style: GoogleFonts.mukta(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFB71C1C),
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Text(
                        deityMantra,
                        style: GoogleFonts.mukta(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8D6E63),
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (isPremium)
                Text(
                  mantraBenefit,
                  style: GoogleFonts.mukta(
                    fontSize: 14.5,
                    color: const Color(0xFF5D4037),
                    height: 1.4,
                  ),
                )
              else
                BlurredContentGate(
                  langCode: langCode,
                  child: Text(
                    mantraBenefit,
                    style: GoogleFonts.mukta(
                      fontSize: 14.5,
                      color: const Color(0xFF5D4037),
                      height: 1.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERSONALIZED LUCKY METER SECTION (Phase 4: नावावरून वैयक्तिक भाग्य मीटर)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPersonalizedMeterSection(
    Rashi selectedRashi,
    HoroscopeReading reading,
    String langCode,
    bool isPremium,
  ) {
    final userInitial = ref.watch(userInitialProvider);
    final personalReading = PersonalVedicService.calculateReading(
      initial: userInitial,
      rashi: selectedRashi,
      langCode: langCode,
    );

    final sectionTitle = langCode == 'mr'
        ? 'तुमचे वैयक्तिक भाग्य मीटर (नावावरून)'
        : (langCode == 'hi' ? 'आपका व्यक्तिगत भाग्य मीटर (नाम से)' : 'Personalized Lucky Meter (By Initial)');

    final selectPrompt = langCode == 'mr'
        ? 'तुमच्या नावाचे पहिले अक्षर निवडा:'
        : (langCode == 'hi' ? 'अपने नाम का पहला अक्षर चुनें:' : 'Select your name\'s first initial:');

    final initialsList = langCode == 'en'
        ? PersonalVedicService.popularInitialsEn
        : PersonalVedicService.popularInitialsMr;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFDF7), Color(0xFFFFF5E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0B867), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B1D18).withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECC4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('🪪', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionTitle,
                      style: GoogleFonts.mukta(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7A0C08),
                        height: 1.15,
                      ),
                    ),
                    Text(
                      personalReading.nakshatraPillar,
                      style: GoogleFonts.mukta(
                        fontSize: 12,
                        color: const Color(0xFF8B6040),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Initial Selector Bar
          Text(
            selectPrompt,
            style: GoogleFonts.mukta(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5A4535),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: initialsList.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                final init = initialsList[index];
                final isSelected = userInitial == init;
                return GestureDetector(
                  onTap: () {
                    ref.read(userInitialProvider.notifier).setInitial(init);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF8B1D18), Color(0xFFB71C1C)],
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFFE0D2C0),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF8B1D18).withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      init,
                      style: GoogleFonts.mukta(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF5A2010),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Lucky Meter / Gauge Score Card (100% VISIBLE TO EVERYONE)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEBE0CE)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFB74D)),
                          ),
                          child: Text(
                            'अक्षर: \'$userInitial\'',
                            style: GoogleFonts.mukta(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          personalReading.statusLabel,
                          style: GoogleFonts.mukta(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${personalReading.luckyScore}% अनुकूल',
                      style: GoogleFonts.mukta(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress Gauge Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: personalReading.luckyScore / 100.0,
                    minHeight: 9,
                    backgroundColor: const Color(0xFFE8F5E9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      personalReading.luckyScore >= 80
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFF57C00),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Headline: Unblurred preview
          Text(
            personalReading.headline,
            style: GoogleFonts.mukta(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B1D18),
              height: 1.25,
            ),
          ),

          const SizedBox(height: 6),

          // Detailed Dos & Don'ts: Blurred for free users
          if (isPremium) ...[
            Text(
              personalReading.dosGuidance,
              style: GoogleFonts.mukta(
                fontSize: 14.5,
                color: const Color(0xFF2E7D32),
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              personalReading.dontsGuidance,
              style: GoogleFonts.mukta(
                fontSize: 14.5,
                color: const Color(0xFFB71C1C),
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else
            BlurredContentGate(
              langCode: langCode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    personalReading.dosGuidance,
                    style: GoogleFonts.mukta(
                      fontSize: 14.5,
                      color: const Color(0xFF2E7D32),
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    personalReading.dontsGuidance,
                    style: GoogleFonts.mukta(
                      fontSize: 14.5,
                      color: const Color(0xFFB71C1C),
                      height: 1.4,
                      fontWeight: FontWeight.w600,
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

  // ── Phase 5: वेदिक AI ज्योतिष - १ वैयक्तिक प्रश्न (Ask 1 Vedic AI Question) ──
  Future<void> _handleConsultVedicAi(
    Rashi rashi,
    String question,
    String langCode,
    String initial,
  ) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isConsultingAi = true;
      _consultedQuestion = trimmed;
    });

    try {
      final service = ref.read(geminiHoroscopeServiceProvider);
      final result = await service.consultVedicAi(
        rashi: rashi,
        question: trimmed,
        langCode: langCode,
        initial: initial.isNotEmpty ? initial : null,
      );
      if (mounted) {
        setState(() {
          _consultationResult = result;
          _isConsultingAi = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isConsultingAi = false;
        });
      }
    }
  }

  Widget _buildVedicAiConsultCard(
    Rashi selectedRashi,
    String langCode,
    bool isPremium,
  ) {
    final userInitial = ref.watch(userInitialProvider);

    final title = langCode == 'mr'
        ? 'वेदिक AI ज्योतिष मार्गदर्शन'
        : (langCode == 'hi'
            ? 'वैदिक AI ज्योतिष मार्गदर्शन'
            : 'Vedic AI Astrology Consultation');

    final subtitle = langCode == 'mr'
        ? 'तुमच्या राशी व ग्रहस्थितीनुसार १ वैयक्तिक प्रश्न विचारा'
        : (langCode == 'hi'
            ? 'अपनी राशि व ग्रह स्थिति अनुसार १ व्यक्तिगत प्रश्न पूछें'
            : 'Ask 1 personal question based on your planetary transits');

    final badgeText = langCode == 'mr'
        ? '✨ थेट वेदिक AI'
        : (langCode == 'hi' ? '✨ प्रत्यक्ष वैदिक AI' : '✨ Live Vedic AI');

    final suggestionsTitle = langCode == 'mr'
        ? 'खालीलपैकी एक प्रश्न निवडा किंवा स्वतःचा विचारा:'
        : (langCode == 'hi'
            ? 'नीचे दिए प्रश्नों में से चुनें या अपना पूछें:'
            : 'Select a question or ask your own:');

    final sampleQuestions = langCode == 'mr'
        ? [
            '💼 नोकरी/व्यवसायात कधी यश मिळेल?',
            '💍 विवाहाचे शुभ योग कधी जुळून येतील?',
            '💰 कर्जमुक्ती व धनलाभाचे योग कधी आहेत?',
            '🩺 आरोग्य व मनःशांतीसाठी काय करावे?',
          ]
        : (langCode == 'hi'
            ? [
                '💼 नौकरी/व्यवसाय में सफलता कब मिलेगी?',
                '💍 विवाह के शुभ योग कब बनेंगे?',
                '💰 कर्जमुक्ति व धन लाभ कब होगा?',
                '🩺 स्वास्थ्य व मानसिक शांति के लिए क्या करें?',
              ]
            : [
                '💼 When will I succeed in career/business?',
                '💍 When will auspicious marriage prospects align?',
                '💰 When will I achieve debt relief & financial gain?',
                '🩺 What should I do for health and peace of mind?',
              ]);

    final hintText = langCode == 'mr'
        ? 'उदा. या महिन्यात नवीन काम सुरू करणे शुभ राहील का?'
        : (langCode == 'hi'
            ? 'उदा. क्या इस महीने नया कार्य शुरू करना शुभ रहेगा?'
            : 'e.g. Is it auspicious to start a new job this month?');

    final askBtnText = langCode == 'mr'
        ? 'विचारा'
        : (langCode == 'hi' ? 'पूछें' : 'Ask');

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFBF0),
            Color(0xFFFFF3DB),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF9933),
                      Color(0xFF8B1E0F),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
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
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF5A2010),
                              height: 1.2,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B1E0F),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.mukta(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFD700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.mukta(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7A4A28),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Loading state
          if (_isConsultingAi) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE8C888).withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: MandirTheme.primarySaffron,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    langCode == 'mr'
                        ? 'ग्रहांची स्थिती व वेदिक कुंडलीचे विश्लेषण सुरू आहे...'
                        : (langCode == 'hi'
                            ? 'ग्रह स्थिति व वैदिक कुंडली का विश्लेषण जारी है...'
                            : 'Analyzing planetary transits & Vedic chart...'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mukta(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5A2010),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    langCode == 'mr'
                        ? 'कृपया क्षणभर प्रतीक्षा करा...'
                        : (langCode == 'hi'
                            ? 'कृपया कुछ क्षण प्रतीक्षा करें...'
                            : 'Please wait a moment...'),
                    style: GoogleFonts.mukta(
                      fontSize: 12,
                      color: const Color(0xFF886040),
                    ),
                  ),
                ],
              ),
            ),
          ]
          // Result state
          else if (_consultationResult != null) ...[
            _buildVedicAiResultView(
              _consultationResult!,
              _consultedQuestion ?? '',
              langCode,
              isPremium,
            ),
          ]
          // Input state
          else ...[
            Text(
              suggestionsTitle,
              style: GoogleFonts.mukta(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5A2010),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sampleQuestions.map((q) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _handleConsultVedicAi(
                      selectedRashi,
                      q,
                      langCode,
                      userInitial,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        q,
                        style: GoogleFonts.mukta(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B2D12),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionInputController,
                      style: GoogleFonts.mukta(
                        fontSize: 14,
                        color: const Color(0xFF333333),
                      ),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: GoogleFonts.mukta(
                          fontSize: 12.5,
                          color: const Color(0xFF999999),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (text) => _handleConsultVedicAi(
                        selectedRashi,
                        text,
                        langCode,
                        userInitial,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MandirTheme.primarySaffron,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _handleConsultVedicAi(
                        selectedRashi,
                        _questionInputController.text,
                        langCode,
                        userInitial,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.send_rounded, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            askBtnText,
                            style: GoogleFonts.mukta(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVedicAiResultView(
    VedicAiConsultation consult,
    String question,
    String langCode,
    bool isPremium,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question quoted pill
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B1E0F).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF8B1E0F).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.help_outline_rounded,
                size: 16,
                color: Color(0xFF8B1E0F),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '“$question”',
                  style: GoogleFonts.mukta(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5A2010),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 1. Headline Summary & Planetary Transit (ALWAYS 100% VISIBLE)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    size: 16,
                    color: Color(0xFFD4AF37),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    langCode == 'mr'
                        ? 'ग्रहगोचर संकेत व सारांश'
                        : (langCode == 'hi'
                            ? 'ग्रह गोचर संकेत व सारांश'
                            : 'Planetary Transit Signal'),
                    style: GoogleFonts.mukta(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7A4A28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                consult.headline,
                style: GoogleFonts.mukta(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5A2010),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                consult.astrologicalAspect,
                style: GoogleFonts.mukta(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4A3828),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. Actionable Guidance, Sacred Remedy, Auspicious Window (GATED for non-premium)
        if (isPremium)
          _buildConsultationDetailedGuidance(consult, langCode)
        else
          BlurredContentGate(
            langCode: langCode,
            child: _buildConsultationDetailedGuidance(consult, langCode),
          ),

        const SizedBox(height: 8),

        // Reset / Ask another question button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B1E0F),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            onPressed: () {
              setState(() {
                _consultationResult = null;
                _consultedQuestion = null;
                _questionInputController.clear();
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(
              langCode == 'mr'
                  ? 'दुसरा प्रश्न विचारा'
                  : (langCode == 'hi'
                      ? 'दूसरा प्रश्न पूछें'
                      : 'Ask another question'),
              style: GoogleFonts.mukta(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsultationDetailedGuidance(
    VedicAiConsultation consult,
    String langCode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Guidance Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    size: 15,
                    color: Color(0xFF8B1E0F),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    langCode == 'mr'
                        ? 'सविस्तर वेदिक सल्ला:'
                        : (langCode == 'hi'
                            ? 'विस्तृत वैदिक सलाह:'
                            : 'Detailed Vedic Guidance:'),
                    style: GoogleFonts.mukta(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B1E0F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                consult.guidance,
                style: GoogleFonts.mukta(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Remedy Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7EA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE8C888),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.spa_rounded,
                    size: 15,
                    color: Color(0xFFB8860B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    langCode == 'mr'
                        ? 'प्रभावी वेदिक उपाय:'
                        : (langCode == 'hi'
                            ? 'सिद्ध वैदिक उपाय:'
                            : 'Sacred Vedic Remedy:'),
                    style: GoogleFonts.mukta(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B1E0F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                consult.remedy,
                style: GoogleFonts.mukta(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5A2010),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Timing Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFBCD8F5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 15,
                color: Color(0xFF1E5B8B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langCode == 'mr'
                          ? 'शुभ काळ व दिशा:'
                          : (langCode == 'hi'
                              ? 'शुभ समय व दिशा:'
                              : 'Auspicious Timing & Direction:'),
                      style: GoogleFonts.mukta(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E5B8B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      consult.favorableTiming,
                      style: GoogleFonts.mukta(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A3A54),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Phase 6: सकाळी ६ ची उत्कंठावर्धक पुश नोटिफिकेशन (Daily 6 AM Notification Card) ──
  Widget _buildMorningNotificationCard(Rashi selectedRashi, String langCode) {
    final isMorningOn = ref.watch(morningReminderEnabledProvider);

    final title = langCode == 'mr'
        ? '⏰ सकाळी ६:०० ची राशीभविष्य सूचना'
        : (langCode == 'hi'
            ? '⏰ सुबह ६:०० बजे राशिफल सूचना'
            : '⏰ Daily 6:00 AM Horoscope Alert');

    final subtitle = langCode == 'mr'
        ? 'दररोज सकाळी ६:०० वाजता ${selectedRashi.localizedName(langCode)} राशीचा सावधगिरीचा इशारा व शुभ काळ थेट मोबाइलवर मिळवा.'
        : (langCode == 'hi'
            ? 'प्रतिदिन सुबह ६:०० बजे ${selectedRashi.localizedName(langCode)} राशि की सावधानी व शुभ समय सीधे मोबाइल पर पाएं।'
            : 'Receive daily 6:00 AM alerts on planetary caution & auspicious timing for ${selectedRashi.localizedName(langCode)}.');

    final previewBtnText = langCode == 'mr'
        ? '🔔 सूचना कशी दिसेल ते पहा'
        : (langCode == 'hi' ? '🔔 नोटिफिकेशन का पूर्वावलोकन देखें' : '🔔 Test Push Preview');

    final activeStatusText = langCode == 'mr'
        ? (isMorningOn ? 'सकाळी ६:०० चा अलर्ट सुरू आहे' : 'अलर्ट बंद आहे')
        : (langCode == 'hi'
            ? (isMorningOn ? 'सुबह ६:०० बजे का अलर्ट सक्रिय है' : 'अलर्ट बंद है')
            : (isMorningOn ? '6:00 AM Morning Alert is Active' : 'Alert is Off'));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C888).withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MandirTheme.primarySaffron.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: MandirTheme.primarySaffron,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.mukta(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5A2010),
                      ),
                    ),
                    Text(
                      activeStatusText,
                      style: GoogleFonts.mukta(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isMorningOn ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isMorningOn,
                activeTrackColor: MandirTheme.primarySaffron.withValues(alpha: 0.5),
                activeThumbColor: MandirTheme.primarySaffron,
                onChanged: (val) {
                  ref.read(morningReminderEnabledProvider.notifier).toggle(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.mukta(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B4A30),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              await PushNotificationService.showMorningHoroscopePreview(
                rashiId: selectedRashi.id,
                rashiName: selectedRashi.localizedName(langCode),
                langCode: langCode,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF5A2010),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  content: Text(
                    langCode == 'mr'
                        ? 'सकाळी ६:०० वाजता अशा प्रकारे अलर्ट येईल! वर स्टेटस बार तपासा.'
                        : (langCode == 'hi'
                            ? 'सुबह ६:०० बजे इसी प्रकार सूचना आएगी! ऊपर स्टेटस बार देखें।'
                            : 'This is how your 6:00 AM notification looks! Check top status bar.'),
                    style: GoogleFonts.mukta(fontSize: 13, color: Colors.white),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9EE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.touch_app_rounded,
                    size: 16,
                    color: Color(0xFF8B1E0F),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    previewBtnText,
                    style: GoogleFonts.mukta(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B1E0F),
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
}
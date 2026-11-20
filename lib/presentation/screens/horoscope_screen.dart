import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/horoscope.dart';
import '../../services/ad_units.dart';
import '../../services/horoscope_detail_content.dart';
import '../../services/personal_numerology_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/rewarded_ad_service.dart';
import '../providers/horoscope_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/app_banner_ad.dart';
import '../widgets/language_dropdown.dart';
import '../widgets/premium_blurred_gate.dart';
import '../widgets/premium_content_blur.dart';

// ── Theme Design Tokens ──────────────────────────────────────────────────────
class _Tokens {
  static const Color paperBg = Color(0xFFF4EEE4);
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

/// Screen displaying Vedic Horoscopes (राशीभविष्य / राशिफल) matching the Bhaktidhara Horoscope Design Kit.
class HoroscopeScreen extends ConsumerStatefulWidget {
  final String? initialRashiId;
  final String? focusSection;

  const HoroscopeScreen({super.key, this.initialRashiId, this.focusSection});

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
    // Preload rewarded ad on entry
    RewardedAdService.instance.preload();

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
        index * 62.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToSection(String sectionKey) {
    if (!_listScrollController.hasClients) return;
    double offset = 0;
    if (sectionKey == 'actions' || sectionKey == 'caution') {
      offset = 420;
    } else if (sectionKey == 'aspects') {
      offset = 680;
    } else if (sectionKey == 'lucky') {
      offset = 1100;
    } else if (sectionKey == 'remedy') {
      offset = 1350;
    } else if (sectionKey == 'vedic_ai') {
      offset = 1600;
    }
    _listScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

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
    final pageAsync = ref.watch(currentHoroscopePageProvider);
    final langCode = ref.watch(localeProvider).languageCode;
    final isPremium = ref.watch(isHoroscopeUnlockedProvider);

    final screenTitle = langCode == 'mr'
        ? 'दैनिक राशीभविष्य'
        : (langCode == 'hi' ? 'दैनिक राशिफल' : 'Daily Horoscope');

    final subtitle = langCode == 'mr'
        ? 'वैदिक ज्योतिष व ग्रहस्थितीवर आधारित'
        : (langCode == 'hi'
              ? 'वैदिक ज्योतिष व ग्रह स्थिति पर आधारित'
              : 'Based on Vedic Astrology & Planetary Transits');

    return Scaffold(
      backgroundColor: _Tokens.paperBg,
      bottomNavigationBar: Navigator.canPop(context)
          ? const AppBannerAd(adUnitId: AdUnits.tabBanner)
          : null,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _listScrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── 1. Masthead (Scrolls away) ──────────────────────────────────
            SliverToBoxAdapter(
              child: _buildMasthead(screenTitle, subtitle, langCode),
            ),

            // ── 2. Pinned Folder Tabs & 12 Rashi Tray ────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _HoroscopeTrayHeaderDelegate(
                selectedPeriod: selectedPeriod,
                selectedRashi: selectedRashi,
                langCode: langCode,
                rashiScrollController: _rashiScrollController,
                onSelectPeriod: (period) {
                  ref.read(selectedHoroscopePeriodProvider.notifier).state = period;
                },
                onSelectRashi: (rashi) {
                  ref.read(selectedRashiProvider.notifier).state = rashi;
                },
              ),
            ),

            // ── 3. Main Reading & Feature Sections ───────────────────────────
            SliverToBoxAdapter(
              child: pageAsync.when(
                loading: () => Container(
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: _Tokens.bronzeAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        langCode == 'mr'
                            ? 'ग्रहांची स्थिती व राशीभविष्य जाणून घेत आहोत...'
                            : (langCode == 'hi'
                                  ? 'ग्रहों की स्थिति व राशिफल प्राप्त हो रहा है...'
                                  : 'Consulting celestial planetary transits...'),
                        style: GoogleFonts.mukta(
                          fontSize: 16.8,
                          color: _Tokens.primaryInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 44,
                        color: Color(0xFF8B1D18),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'राशीभविष्य लोड करता आले नाही',
                        style: GoogleFonts.tiroDevanagariMarathi(
                          fontSize: 18.8,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7A0C08),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(horoscopeRefreshTriggerProvider.notifier).state++;
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('पुन्हा प्रयत्न करा'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Tokens.navyHero,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (page) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Complete 6 structured panels
                      HoroscopeDetailContent(
                        page: page,
                        compact: !isPremium,
                        langCode: langCode,
                      ),

                      if (!isPremium) ...[
                        const SizedBox(height: 18),
                        _buildSubscriptionCta(langCode),
                      ],

                      const SizedBox(height: 18),

                      // Vedic AI Consultation Card
                      _buildVedicAiConsultCard(selectedRashi, langCode, isPremium),

                      const SizedBox(height: 18),

                      // 6 AM Daily Notification Card
                      _buildMorningNotificationCard(selectedRashi, langCode),

                      const SizedBox(height: 24),

                      // Refresh & Attribution Footer
                      _buildRefreshAndAttribution(langCode),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. MASTHEAD (BRONZE ॐ + BRANDING + LANGUAGE + PREMIUM + TITLE)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMasthead(String title, String subtitle, String langCode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: ॐ भक्तिधारा on left, Language + Premium on right
          Row(
            children: [
              Text(
                'ॐ',
                style: GoogleFonts.tiroDevanagariMarathi(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: _Tokens.bronzeAccent,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'भक्तिधारा',
                style: GoogleFonts.tiroDevanagariMarathi(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: _Tokens.primaryInk,
                ),
              ),
              const Spacer(),

              // Language Selector Pill
              const LanguageDropdown(),

              const SizedBox(width: 8),

              // Premium Pill Button
              InkWell(
                onTap: () => showPremiumPaywallSheet(context, ref, langCode),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _Tokens.ivorySurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _Tokens.mainBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_outline_rounded,
                        size: 15,
                        color: _Tokens.bronzeAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        langCode == 'mr'
                            ? 'प्रीमियम'
                            : (langCode == 'hi' ? 'प्रीमियम' : 'Premium'),
                        style: GoogleFonts.mukta(
                          fontSize: 13.2,
                          fontWeight: FontWeight.w700,
                          color: _Tokens.primaryInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Screen Title
          Text(
            title,
            style: GoogleFonts.tiroDevanagariMarathi(
              fontSize: 31,
              fontWeight: FontWeight.w700,
              color: _Tokens.primaryInk,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 4),

          // Subtitle
          Text(
            subtitle,
            style: GoogleFonts.mukta(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: _Tokens.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. SUBSCRIPTION & REWARDED AD CTA
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSubscriptionCta(String langCode) {
    final title = langCode == 'mr'
        ? 'संपूर्ण सविस्तर राशीभविष्य अनलॉक करा'
        : (langCode == 'hi'
              ? 'सम्पूर्ण विस्तृत राशिफल अनलॉक करें'
              : 'Unlock Full Detailed Horoscope');

    final ctaText = langCode == 'mr'
        ? 'प्रीमियम सदस्य व्हा'
        : (langCode == 'hi' ? 'प्रीमियम सदस्य बनें' : 'Upgrade to Premium');

    return Container(
      decoration: BoxDecoration(
        color: _Tokens.ivorySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Tokens.mainBorder),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _Tokens.guidanceRemedies,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: _Tokens.bronzeAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.tiroDevanagariMarathi(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w700,
                    color: _Tokens.primaryInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => showPremiumPaywallSheet(context, ref, langCode),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Tokens.navyHero,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                ctaText,
                style: GoogleFonts.mukta(
                  fontSize: 15.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Rewarded Ad 24h Unlock option
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                RewardedAdService.instance.show(
                  onRewarded: () async {
                    await ref
                        .read(horoscopeRewardedUnlockProvider.notifier)
                        .unlock24Hours();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            langCode == 'en'
                                ? '🎉 Horoscope unlocked for 24 hours!'
                                : (langCode == 'hi'
                                      ? '🎉 राशिफल 24 घंटे के लिए अनलॉक हो गया!'
                                      : '🎉 भविष्य २४ तासांसाठी अनलॉक झाले!'),
                            style: GoogleFonts.mukta(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: const Color(0xFF2E7D32),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  onAdNotReady: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          langCode == 'en'
                              ? 'Ad not ready yet. Please try again in a moment.'
                              : (langCode == 'hi'
                                    ? 'विज्ञापन अभी तैयार नहीं है। कृपया थोड़ी देर बाद प्रयास करें।'
                                    : 'जाहिरात अजून तयार नाही. कृपया थोड्या वेळाने प्रयत्न करा.'),
                          style: GoogleFonts.mukta(),
                        ),
                        backgroundColor: const Color(0xFF8B1D18),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
              },
              icon: const Icon(
                Icons.play_circle_outline_rounded,
                size: 18,
                color: _Tokens.bronzeAccent,
              ),
              label: Text(
                langCode == 'mr'
                    ? 'व्हिडिओ जाहिरात पाहून २४ तास मोफत अनलॉक करा'
                    : (langCode == 'hi'
                          ? 'वीडियो विज्ञापन देखकर २४ घंटे मुफ्त अनलॉक करें'
                          : 'Watch ad to unlock for 24 hours'),
                style: GoogleFonts.mukta(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: _Tokens.primaryInk,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _Tokens.hairline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. VEDIC AI CONSULTATION CARD
  // ═══════════════════════════════════════════════════════════════════════════
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
        ? 'राशी व जन्मकुंडलीनुसार वैयक्तिक मार्गदर्शन'
        : (langCode == 'hi'
              ? 'राशि व जन्मकुंडली अनुसार व्यक्तिगत मार्गदर्शन'
              : 'Personalized guidance based on your Vedic chart');

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
        ? 'तुमचा प्रश्न लिहा...'
        : (langCode == 'hi' ? 'अपना प्रश्न लिखें...' : 'Ask your question...');

    final askBtnText = langCode == 'mr'
        ? 'विचारा'
        : (langCode == 'hi' ? 'पूछें' : 'Ask');

    return Container(
      decoration: BoxDecoration(
        color: _Tokens.ivorySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Tokens.mainBorder),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _Tokens.navyHero,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: _Tokens.goldOnNavy,
                  size: 18,
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
                        fontSize: 17.5,
                        fontWeight: FontWeight.w700,
                        color: _Tokens.primaryInk,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.mukta(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                        color: _Tokens.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Loading state
          if (_isConsultingAi) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(_Tokens.bronzeAccent),
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
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: _Tokens.primaryInk,
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
          // Input & suggestions state
          else ...[
            Text(
              suggestionsTitle,
              style: GoogleFonts.mukta(
                fontSize: 14.2,
                fontWeight: FontWeight.w600,
                color: _Tokens.primaryInk,
              ),
            ),
            const SizedBox(height: 10),

            // Tappable Question Rows
            for (final q in sampleQuestions) ...[
              InkWell(
                onTap: () => _handleConsultVedicAi(
                  selectedRashi,
                  q,
                  langCode,
                  userInitial,
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _Tokens.mainBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          q,
                          style: GoogleFonts.mukta(
                            fontSize: 14.8,
                            fontWeight: FontWeight.w600,
                            color: _Tokens.primaryInk,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: _Tokens.mutedText,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Custom Question Input & Ask Button
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _Tokens.mainBorder),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _questionInputController,
                      style: GoogleFonts.mukta(
                        fontSize: 14.5,
                        color: _Tokens.primaryInk,
                      ),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: GoogleFonts.mukta(
                          fontSize: 14.0,
                          color: _Tokens.mutedText.withValues(alpha: 0.7),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (text) => _handleConsultVedicAi(
                        selectedRashi,
                        text,
                        langCode,
                        userInitial,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Tokens.navyHero,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _handleConsultVedicAi(
                    selectedRashi,
                    _questionInputController.text,
                    langCode,
                    userInitial,
                  ),
                  icon: const Icon(
                    Icons.auto_awesome,
                    size: 15,
                    color: _Tokens.goldOnNavy,
                  ),
                  label: Text(
                    askBtnText,
                    style: GoogleFonts.mukta(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
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
            color: _Tokens.guidanceRemedies,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _Tokens.hairline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.help_outline_rounded,
                size: 16,
                color: _Tokens.bronzeAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '“$question”',
                  style: GoogleFonts.mukta(
                    fontSize: 14.0,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: _Tokens.primaryInk,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Headline & Planetary Signal (Always 100% visible)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Tokens.mainBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    size: 16,
                    color: _Tokens.bronzeAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    langCode == 'mr'
                        ? 'ग्रहगोचर संकेत व सारांश'
                        : (langCode == 'hi'
                              ? 'ग्रह गोचर संकेत व सारांश'
                              : 'Planetary Transit Signal'),
                    style: GoogleFonts.mukta(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _Tokens.bronzeAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                consult.headline,
                style: GoogleFonts.mukta(
                  fontSize: 15.8,
                  fontWeight: FontWeight.w700,
                  color: _Tokens.primaryInk,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                consult.astrologicalAspect,
                style: GoogleFonts.mukta(
                  fontSize: 14.5,
                  color: _Tokens.mutedText,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Actionable guidance, remedy and timing
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
              foregroundColor: _Tokens.bronzeAccent,
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
                fontSize: 14.0,
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
            border: Border.all(color: _Tokens.mainBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                langCode == 'mr'
                    ? 'सविस्तर वेदिक सल्ला:'
                    : (langCode == 'hi'
                          ? 'विस्तृत वैदिक सलाह:'
                          : 'Detailed Vedic Guidance:'),
                style: GoogleFonts.mukta(
                  fontSize: 14.2,
                  fontWeight: FontWeight.w700,
                  color: _Tokens.bronzeAccent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                consult.guidance,
                style: GoogleFonts.mukta(
                  fontSize: 15.0,
                  color: _Tokens.primaryInk,
                  height: 1.5,
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
            color: _Tokens.guidanceRemedies,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Tokens.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                langCode == 'mr'
                    ? 'प्रभावी वेदिक उपाय:'
                    : (langCode == 'hi'
                          ? 'सिद्ध वैदिक उपाय:'
                          : 'Sacred Vedic Remedy:'),
                style: GoogleFonts.mukta(
                  fontSize: 14.2,
                  fontWeight: FontWeight.w700,
                  color: _Tokens.bronzeAccent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                consult.remedy,
                style: GoogleFonts.mukta(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: _Tokens.primaryInk,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Timing Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Tokens.mainBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 15,
                color: _Tokens.bronzeAccent,
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
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _Tokens.bronzeAccent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      consult.favorableTiming,
                      style: GoogleFonts.mukta(
                        fontSize: 14.2,
                        fontWeight: FontWeight.w500,
                        color: _Tokens.primaryInk,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. DAILY 6 AM NOTIFICATION CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMorningNotificationCard(Rashi selectedRashi, String langCode) {
    final isMorningOn = ref.watch(morningReminderEnabledProvider);

    final title = langCode == 'mr'
        ? '⏰ सकाळी ६:०० ची राशीभविष्य सूचना'
        : (langCode == 'hi'
              ? '⏰ सुबह ६:०० बजे राशिफल सूचना'
              : '⏰ Daily 6:00 AM Horoscope Alert');

    final subtitle = langCode == 'mr'
        ? 'दररोज सकाळी ६:०० वाजता ${selectedRashi.localizedName(langCode)} राशीचे दैनिक मार्गदर्शन, शुभ मुहूर्त व सिद्ध उपाय थेट मोबाइलवर मिळवा.'
        : (langCode == 'hi'
              ? 'प्रतिदिन सुबह ६:०० बजे ${selectedRashi.localizedName(langCode)} राशि का दैनिक मार्गदर्शन, शुभ समय व उपाय सीधे मोबाइल पर पाएं।'
              : 'Receive daily 6:00 AM alerts on daily guidance, auspicious timing & remedies for ${selectedRashi.localizedName(langCode)}.');

    final previewBtnText = langCode == 'mr'
        ? '🔔 सूचना कशी दिसेल ते पहा'
        : (langCode == 'hi'
              ? '🔔 सूचना कैसी दिखेगी देखें'
              : '🔔 Preview how notification looks');

    return Container(
      decoration: BoxDecoration(
        color: _Tokens.ivorySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Tokens.mainBorder),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: _Tokens.bronzeAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.mukta(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: _Tokens.primaryInk,
                  ),
                ),
              ),
              Switch.adaptive(
                value: isMorningOn,
                activeTrackColor: _Tokens.bronzeAccent,
                activeThumbColor: _Tokens.ivorySurface,
                onChanged: (val) async {
                  await ref
                      .read(morningReminderEnabledProvider.notifier)
                      .toggle(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.mukta(
              fontSize: 14.2,
              color: _Tokens.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await PushNotificationService.showMorningHoroscopePreview(
                  rashiId: selectedRashi.id,
                  rashiName: selectedRashi.localizedName(langCode),
                  langCode: langCode,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      langCode == 'mr'
                          ? '🔔 चाचणी सूचना पाठवली आहे! वरून नोटिफिकेशन बार तपासा.'
                          : (langCode == 'hi'
                                ? '🔔 टेस्ट नोटिफिकेशन भेजा गया है!'
                                : '🔔 Test notification sent!'),
                      style: GoogleFonts.mukta(),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_outlined,
                size: 16,
                color: _Tokens.bronzeAccent,
              ),
              label: Text(
                previewBtnText,
                style: GoogleFonts.mukta(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: _Tokens.primaryInk,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _Tokens.hairline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. REFRESH & ATTRIBUTION FOOTER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRefreshAndAttribution(String langCode) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            ref.read(horoscopeRefreshTriggerProvider.notifier).state++;
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: _Tokens.bronzeAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  langCode == 'mr'
                      ? 'नवीन भविष्य मिळवा'
                      : (langCode == 'hi'
                            ? 'नया राशिफल प्राप्त करें'
                            : 'Refresh horoscope'),
                  style: GoogleFonts.mukta(
                    fontSize: 14.8,
                    fontWeight: FontWeight.w700,
                    color: _Tokens.bronzeAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Powered by Google Gemini & Vedic Astrology',
          style: GoogleFonts.mukta(
            fontSize: 13.0,
            color: _Tokens.mutedText.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PINNED FOLDER TABS & 12 RASHI TRAY DELEGATE
// ═════════════════════════════════════════════════════════════════════════════
class _HoroscopeTrayHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HoroscopeTrayHeaderDelegate({
    required this.selectedPeriod,
    required this.selectedRashi,
    required this.langCode,
    required this.rashiScrollController,
    required this.onSelectPeriod,
    required this.onSelectRashi,
  });

  final String selectedPeriod;
  final Rashi selectedRashi;
  final String langCode;
  final ScrollController rashiScrollController;
  final ValueChanged<String> onSelectPeriod;
  final ValueChanged<Rashi> onSelectRashi;

  @override
  double get minExtent => 154.0;

  @override
  double get maxExtent => 154.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isToday = selectedPeriod == 'today';

    final todayLabel = langCode == 'mr'
        ? 'आज'
        : (langCode == 'hi' ? 'आज' : 'Today');

    final weeklyLabel = langCode == 'mr'
        ? 'साप्ताहिक'
        : (langCode == 'hi' ? 'साप्ताहिक' : 'Weekly');

    return Container(
      color: _Tokens.paperBg,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Full-Width Segmented Period Tabs ───────────────────────────────
          Container(
            height: 40,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _Tokens.guidanceRemedies,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _Tokens.mainBorder, width: 1.2),
            ),
            child: Row(
              children: [
                // Today Tab
                Expanded(
                  child: GestureDetector(
                    onTap: () => onSelectPeriod('today'),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: isToday ? _Tokens.ivorySurface : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        border: isToday
                            ? Border.all(color: _Tokens.mainBorder, width: 1)
                            : null,
                        boxShadow: isToday
                            ? const [
                                BoxShadow(
                                  color: Color(0x10000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1.5),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        todayLabel,
                        style: GoogleFonts.mukta(
                          fontSize: 15.2,
                          fontWeight:
                              isToday ? FontWeight.w800 : FontWeight.w600,
                          color: isToday
                              ? _Tokens.primaryInk
                              : _Tokens.mutedText,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Weekly Tab
                Expanded(
                  child: GestureDetector(
                    onTap: () => onSelectPeriod('weekly'),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: !isToday ? _Tokens.ivorySurface : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        border: !isToday
                            ? Border.all(color: _Tokens.mainBorder, width: 1)
                            : null,
                        boxShadow: !isToday
                            ? const [
                                BoxShadow(
                                  color: Color(0x10000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1.5),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        weeklyLabel,
                        style: GoogleFonts.mukta(
                          fontSize: 15.2,
                          fontWeight:
                              !isToday ? FontWeight.w800 : FontWeight.w600,
                          color: !isToday
                              ? _Tokens.primaryInk
                              : _Tokens.mutedText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── 12 Rashi Tray Container ────────────────────────────────────────
          Container(
            height: 98,
            decoration: BoxDecoration(
              color: _Tokens.ivorySurface,
              border: Border.all(color: _Tokens.mainBorder, width: 1.2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ListView.builder(
              controller: rashiScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: kAllRashis.length,
              itemBuilder: (context, index) {
                final rashi = kAllRashis[index];
                final isSelected = rashi.id == selectedRashi.id;

                return GestureDetector(
                  onTap: () => onSelectRashi(rashi),
                  child: Container(
                    width: 62,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isSelected ? _Tokens.navyHero : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          rashi.symbol,
                          style: TextStyle(
                            fontSize: 27,
                            color: isSelected
                                ? _Tokens.goldOnNavy
                                : _Tokens.bronzeAccent,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          rashi.localizedName(langCode),
                          style: GoogleFonts.mukta(
                            fontSize: 14.2,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : _Tokens.primaryInk,
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
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HoroscopeTrayHeaderDelegate oldDelegate) {
    return oldDelegate.selectedPeriod != selectedPeriod ||
        oldDelegate.selectedRashi != selectedRashi ||
        oldDelegate.langCode != langCode;
  }
}

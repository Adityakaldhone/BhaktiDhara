import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/panchang.dart';
import '../../domain/entities/panchang_city.dart';
// import '../../services/gemini_horoscope_service.dart';
import '../providers/locale_provider.dart';
import '../providers/panchang_provider.dart';
// import '../providers/premium_provider.dart';
// import '../widgets/premium_blurred_gate.dart';

/// Screen displaying an authentic, aesthetic Vedic Panchang (दैनिक पंचांग)
/// calibrated for the user's specific city / geographic coordinates,
/// powered by Google Gemini AI with high-precision offline astronomical calculations.
class PanchangScreen extends ConsumerStatefulWidget {
  const PanchangScreen({super.key});

  @override
  ConsumerState<PanchangScreen> createState() => _PanchangScreenState();
}

class _PanchangScreenState extends ConsumerState<PanchangScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-detect user's current city via GPS/IP in the background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(autoDetectLocationProvider);
    });
  }

  // Note: Gemini API key is configured directly in code; dialog preserved for reference
  // void _showApiKeyDialog(BuildContext context) { ... }

  void _showCitySelectionSheet(
    BuildContext context,
    PanchangCity currentCity,
    String langCode,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CitySelectionSheet(
        currentCity: currentCity,
        langCode: langCode,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final currentDate = ref.read(selectedPanchangDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MandirTheme.primarySaffron,
              onPrimary: Colors.white,
              surface: Color(0xFFFFFBF2),
              onSurface: MandirTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(selectedPanchangDateProvider.notifier).state =
          DateTime(picked.year, picked.month, picked.day);
    }
  }

  void _shiftDate(int days) {
    final current = ref.read(selectedPanchangDateProvider);
    ref.read(selectedPanchangDateProvider.notifier).state =
        current.add(Duration(days: days));
  }

  void _goToToday() {
    final now = DateTime.now();
    ref.read(selectedPanchangDateProvider.notifier).state =
        DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final panchangAsync = ref.watch(currentPanchangDataProvider);
    final selectedDate = ref.watch(selectedPanchangDateProvider);
    final selectedCity = ref.watch(selectedPanchangCityProvider);
    final langCode = ref.watch(localeProvider).languageCode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Spiritual App Bar ─────────────────────────────────────
            _buildAppBar(context),

            // ── Location / City Selector Strip ────────────────────────────
            _buildCitySelectorBar(context, selectedCity, langCode),

            // ── Date Navigation Controls ──────────────────────────────────
            _buildDateSelector(context, selectedDate, isToday, langCode),

            // ── Main Panchang Content ─────────────────────────────────────
            Expanded(
              child: panchangAsync.when(
                loading: () => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: MandirTheme.primarySaffron,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'स्थान-विशिष्ट वैदिक पंचांग गणना सुरू आहे...',
                        style: TextStyle(
                          color: MandirTheme.textDark,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 48,
                          color: MandirTheme.primarySaffron,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'पंचांग माहिती लोड करता आली नाही.',
                          style: GoogleFonts.mukta(
                            fontSize: 18,
                            color: MandirTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => ref
                              .read(panchangRefreshTriggerProvider.notifier)
                              .state++,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('पुन्हा प्रयत्न करा'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MandirTheme.primarySaffron,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (panchang) {
                  return RefreshIndicator(
                    color: MandirTheme.primarySaffron,
                    backgroundColor: const Color(0xFFFFFBF2),
                    onRefresh: () async {
                      ref.read(panchangRefreshTriggerProvider.notifier).state++;
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        // 1. Hero Calendar Card (Samvat, Tithi, Day, City)
                        _buildHeroCard(panchang, selectedCity, langCode),
                        const SizedBox(height: 16),

                        // 2. Surya & Chandra Astronomical Card
                        _buildSunMoonCard(panchang, selectedCity, langCode),
                        const SizedBox(height: 16),

                        // 3. The 5 Limbs of Panchang (पंच-अंग)
                        _buildPanchangLimbsGrid(panchang, langCode),
                        const SizedBox(height: 16),

                        // [Future Release: Premium Blurred Gate]
                        // PremiumBlurredGate(
                        //   langCode: langCode,
                        //   title: langCode == 'en'
                        //       ? 'Unlock Complete Panchang & Muhurats'
                        //       : (langCode == 'hi'
                        //           ? 'सटीक पंचांग व शुभ मुहूर्त अनलॉक करें'
                        //           : 'सविस्तर पंचांग व शुभ मुहूर्त अनलॉक करा'),
                        //   subtitle: langCode == 'en'
                        //       ? 'Accurate Abhijit Muhurat, Rahu Kaal, Yamaganda, Gulika, and Daily Vedic Mantras for your city.'
                        //       : (langCode == 'hi'
                        //           ? 'अपने शहर के लिए सटीक अभिजित मुहूर्त, राहु काल, यमघंट, गुलिक व दैनिक वैदिक मंत्र प्राप्त करें।'
                        //           : 'आपल्या शहरासाठी अचूक अभिजीत मुहूर्त, राहु काळ, यमघंट, गुलिक काळ व दैनिक वैदिक मंत्र मिळवा.'),
                        //   child: Column(
                        //     children: [
                        //       _buildShubhMuhuratCard(panchang, langCode),
                        //       const SizedBox(height: 16),
                        //       _buildAshubhKaalCard(panchang, langCode),
                        //       const SizedBox(height: 16),
                        //       _buildFestivalCard(panchang, langCode),
                        //       const SizedBox(height: 16),
                        //       _buildDailyGuidanceCard(panchang, langCode),
                        //       const SizedBox(height: 20),
                        //       Center(
                        //         child: Text(
                        //           '॥ शुभं भवतु • सर्वं श्रीकृष्णार्पणमस्तु ॥',
                        //           style: GoogleFonts.mukta(
                        //             fontSize: 14,
                        //             fontWeight: FontWeight.w600,
                        //             color: const Color(0xFF9E7B5A),
                        //             letterSpacing: 1.0,
                        //           ),
                        //         ),
                        //       ),
                        //       const SizedBox(height: 12),
                        //     ],
                        //   ),
                        // ),
                        // 4. Shubh Muhurat (शुभ मुहूर्त)
                        _buildShubhMuhuratCard(panchang, langCode),
                        const SizedBox(height: 16),

                        // 5. Ashubh Kaal (अशुभ काळ - वर्ज्य वेळ)
                        _buildAshubhKaalCard(panchang, langCode),
                        const SizedBox(height: 16),

                        // 6. Today's Festival & Vrat (सण, उत्सव व व्रत)
                        _buildFestivalCard(panchang, langCode),
                        const SizedBox(height: 16),

                        // 7. Daily Guidance & Mantra
                        _buildDailyGuidanceCard(panchang, langCode),
                        const SizedBox(height: 20),

                        // Footer Vedic Signature
                        Center(
                          child: Text(
                            '॥ शुभं भवतु • सर्वं श्रीकृष्णार्पणमस्तु ॥',
                            style: GoogleFonts.mukta(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9E7B5A),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TOP BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Om Symbol
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MandirTheme.chipBackground,
              border: Border.all(color: MandirTheme.chipBorder, width: 1.2),
            ),
            child: const Center(
              child: Text(
                'ॐ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: MandirTheme.primarySaffron,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'दैनिक पंचांग',
                  style: GoogleFonts.mukta(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: MandirTheme.textDark,
                    height: 1.1,
                  ),
                ),
                Text(
                  'वैदिक कालनिर्णय व मुहूर्त दर्शन',
                  style: GoogleFonts.mukta(
                    fontSize: 14.5,
                    color: MandirTheme.textMuted,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),

          // [Future Release: Premium Badge / Button]
          // Builder(
          //   builder: (ctx) {
          //     final isPremium = ref.watch(isPremiumProvider);
          //     final langCode = ref.watch(localeProvider).languageCode;
          //     return GestureDetector(
          //       onTap: () => showPremiumPaywallSheet(context, ref, langCode),
          //       child: Container(
          //         padding:
          //             const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          //         margin: const EdgeInsets.only(right: 4),
          //         decoration: BoxDecoration(
          //           gradient: LinearGradient(
          //             colors: isPremium
          //                 ? const [Color(0xFFFFF3D6), Color(0xFFFFD54F)]
          //                 : const [Color(0xFF8B1D18), Color(0xFFE65100)],
          //           ),
          //           borderRadius: BorderRadius.circular(16),
          //           border: Border.all(
          //             color: const Color(0xFFD4AF37),
          //             width: 1,
          //           ),
          //           boxShadow: [
          //             BoxShadow(
          //               color: (isPremium
          //                       ? const Color(0xFFD4AF37)
          //                       : const Color(0xFF8B1D18))
          //                   .withValues(alpha: 0.25),
          //               blurRadius: 4,
          //               offset: const Offset(0, 1),
          //             ),
          //           ],
          //         ),
          //         child: Row(
          //           mainAxisSize: MainAxisSize.min,
          //           children: [
          //             Icon(
          //               isPremium
          //                   ? Icons.stars_rounded
          //                   : Icons.workspace_premium_rounded,
          //               color: isPremium
          //                   ? const Color(0xFF8B1D18)
          //                   : Colors.white,
          //               size: 15,
          //             ),
          //             const SizedBox(width: 4),
          //             Text(
          //               isPremium
          //                   ? (langCode == 'en' ? 'VIP' : 'प्रीमियम')
          //                   : (langCode == 'en' ? '₹20' : '₹२०'),
          //               style: GoogleFonts.mukta(
          //                 fontSize: 12,
          //                 fontWeight: FontWeight.bold,
          //                 color: isPremium
          //                     ? const Color(0xFF7A0C08)
          //                     : Colors.white,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     );
          //   },
          // ),

          // Refresh button
          IconButton(
            tooltip: 'Refresh Panchang',
            icon: const Icon(
              Icons.refresh_rounded,
              color: MandirTheme.primarySaffron,
              size: 24,
            ),
            onPressed: () {
              ref.read(panchangRefreshTriggerProvider.notifier).state++;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('पंचांग अद्यतन केले जात आहे...'),
                  duration: Duration(seconds: 1),
                  backgroundColor: MandirTheme.secondaryMaroon,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  CITY SELECTOR BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCitySelectorBar(
    BuildContext context,
    PanchangCity currentCity,
    String langCode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: const BoxDecoration(
        color: Color(0xFFFBF4E8),
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEDCC7), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 18,
                color: MandirTheme.primarySaffron,
              ),
              const SizedBox(width: 5),
              Text(
                langCode == 'en' ? 'Location:' : 'पंचांग स्थान:',
                style: GoogleFonts.mukta(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: MandirTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: InkWell(
              onTap: () =>
                  _showCitySelectionSheet(context, currentCity, langCode),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '${currentCity.localizedName(langCode)} (${currentCity.stateOrCountry})',
                        style: GoogleFonts.mukta(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: MandirTheme.secondaryMaroon,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: MandirTheme.primarySaffron,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DATE SELECTOR BAR (◀ Yesterday | Today | Tomorrow ▶ + Calendar Picker)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDateSelector(
    BuildContext context,
    DateTime selectedDate,
    bool isToday,
    String langCode,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      color: const Color(0xFFF7EFE1),
      child: Row(
        children: [
          // Previous Day Button
          InkWell(
            onTap: () => _shiftDate(-1),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5CFB0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chevron_left,
                    size: 18,
                    color: MandirTheme.textDark,
                  ),
                  Text(
                    langCode == 'en' ? 'Prev' : 'काल',
                    style: GoogleFonts.mukta(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: MandirTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Today / Center Badge
          Expanded(
            child: InkWell(
              onTap: isToday ? () => _selectDate(context) : _goToToday,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isToday
                        ? [
                            MandirTheme.primarySaffron,
                            const Color(0xFFE65100),
                          ]
                        : [
                            const Color(0xFFFFF7E6),
                            const Color(0xFFFFECC8),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isToday
                        ? MandirTheme.primarySaffron
                        : const Color(0xFFD4AF37),
                    width: 1.2,
                  ),
                  boxShadow: isToday
                      ? [
                          BoxShadow(
                            color: MandirTheme.primarySaffron
                                .withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isToday ? Icons.today : Icons.history_rounded,
                        size: 16,
                        color:
                            isToday ? Colors.white : MandirTheme.primarySaffron,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isToday
                            ? (langCode == 'en' ? 'Today' : 'आज')
                            : DateFormat('dd MMM yyyy').format(selectedDate),
                        style: GoogleFonts.mukta(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isToday ? Colors.white : MandirTheme.textDark,
                        ),
                      ),
                      if (!isToday) ...[
                        const SizedBox(width: 4),
                        Text(
                          langCode == 'en' ? '(Go Today)' : '(आजवर जा)',
                          style: GoogleFonts.mukta(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: MandirTheme.primarySaffron,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Next Day Button
          InkWell(
            onTap: () => _shiftDate(1),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5CFB0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    langCode == 'en' ? 'Next' : 'उद्या',
                    style: GoogleFonts.mukta(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: MandirTheme.textDark,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: MandirTheme.textDark,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Calendar Picker Button
          InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                size: 19,
                color: MandirTheme.primarySaffron,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HERO CARD (Tithi, Paksha, Samvat, Date Headline)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroCard(
    PanchangData panchang,
    PanchangCity city,
    String langCode,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF9EC),
            Color(0xFFFBEFD7),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3C594), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Mandala Watermark
          Positioned(
            right: -15,
            top: -15,
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/decorations/corner_mandala.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Formatted Date & AI / City Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        panchang.formattedDate,
                        style: GoogleFonts.mukta(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                          color: MandirTheme.secondaryMaroon,
                        ),
                      ),
                    ),
                    if (panchang.isAiGenerated)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF81C784)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 13,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Gemini AI',
                              style: GoogleFonts.mukta(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Main Headline: Maas + Paksha + Tithi
                Text(
                  '${panchang.maas} ${panchang.paksha} ${panchang.tithi}',
                  style: GoogleFonts.mukta(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: MandirTheme.textDark,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),

                // End Time & City Badge
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: MandirTheme.goldenAccent,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'तिथी समाप्ती: ${panchang.tithiEndTime}',
                        style: GoogleFonts.mukta(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF755034),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBE4D2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '📍 ${city.localizedName(langCode)}',
                        style: GoogleFonts.mukta(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: MandirTheme.primarySaffron,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Divider(color: Color(0xFFE8D3B0), height: 1),
                const SizedBox(height: 10),

                // Samvat & Vedic Details Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildPillBadge(
                      'विक्रम संवत ${panchang.vikramSamvat}',
                      const Color(0xFF8D4004),
                      const Color(0xFFFBE7D0),
                    ),
                    _buildPillBadge(
                      'शक संवत ${panchang.shakaSamvat}',
                      const Color(0xFF5D4037),
                      const Color(0xFFEFEBE9),
                    ),
                    _buildPillBadge(
                      'संवत्सर: ${panchang.samvatsara}',
                      const Color(0xFF455A64),
                      const Color(0xFFECEFF1),
                    ),
                    _buildPillBadge(
                      '${panchang.ritu} • ${panchang.ayana}',
                      const Color(0xFF1B5E20),
                      const Color(0xFFE8F5E9),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.mukta(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SURYA & CHANDRA CARD (Sun & Moon Timings)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSunMoonCard(
    PanchangData panchang,
    PanchangCity city,
    String langCode,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDDBC2)),
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
              const Icon(
                Icons.wb_sunny_rounded,
                color: Color(0xFFE65100),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'सूर्य व चंद्र काल — ${city.localizedName(langCode)}',
                  style: GoogleFonts.mukta(
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                    color: MandirTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Surya Column
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8EC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE0B2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('☀️', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'सूर्य (Surya)',
                              style: GoogleFonts.mukta(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: const Color(0xFFBF360C),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildTimingRow('सूर्योदय', panchang.sunrise),
                      _buildTimingRow('सूर्यास्त', panchang.sunset),
                      _buildTimingRow('सूर्य राशी', panchang.suryaRashi),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Chandra Column
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCFD8DC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🌙', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'चंद्र (Chandra)',
                              style: GoogleFonts.mukta(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: const Color(0xFF263238),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildTimingRow('चंद्रोदय', panchang.moonrise),
                      _buildTimingRow('चंद्रास्त', panchang.moonset),
                      _buildTimingRow('चंद्र राशी', panchang.chandraRashi),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.mukta(
                fontSize: 14,
                color: MandirTheme.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.mukta(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: MandirTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  THE FIVE LIMBS OF PANCHANG (पंच-अंग)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPanchangLimbsGrid(PanchangData panchang, String langCode) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDDBC2)),
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
              const Icon(
                Icons.auto_stories_rounded,
                color: MandirTheme.primarySaffron,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'पंचांग मुख्य ५ अंगे (Five Sacred Limbs)',
                  style: GoogleFonts.mukta(
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                    color: MandirTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Tithi
          _buildLimbTile(
            number: '१',
            title: 'तिथी (Tithi)',
            value: '${panchang.paksha} ${panchang.tithi}',
            subtitle: 'समाप्ती: ${panchang.tithiEndTime}',
            icon: Icons.nightlight_outlined,
            accentColor: const Color(0xFFC2410C),
          ),
          const SizedBox(height: 8),

          // 2. Vaar
          _buildLimbTile(
            number: '२',
            title: 'वार (Day)',
            value: panchang.vaar,
            subtitle: 'स्वामी ग्रह: ${panchang.vaarGraha}',
            icon: Icons.calendar_today_rounded,
            accentColor: const Color(0xFFB45309),
          ),
          const SizedBox(height: 8),

          // 3. Nakshatra
          _buildLimbTile(
            number: '३',
            title: 'नक्षत्र (Nakshatra)',
            value: panchang.nakshatra,
            subtitle: 'समाप्ती: ${panchang.nakshatraEndTime}',
            icon: Icons.star_border_rounded,
            accentColor: const Color(0xFF4338CA),
          ),
          const SizedBox(height: 8),

          // 4. Yoga
          _buildLimbTile(
            number: '४',
            title: 'योग (Yoga)',
            value: panchang.yoga,
            subtitle: 'समाप्ती: ${panchang.yogaEndTime}',
            icon: Icons.all_inclusive_rounded,
            accentColor: const Color(0xFF047857),
          ),
          const SizedBox(height: 8),

          // 5. Karana
          _buildLimbTile(
            number: '५',
            title: 'करण (Karana)',
            value: panchang.karana,
            subtitle: 'समाप्ती: ${panchang.karanaEndTime}',
            icon: Icons.hourglass_bottom_rounded,
            accentColor: const Color(0xFF6D28D9),
          ),
        ],
      ),
    );
  }

  Widget _buildLimbTile({
    required String number,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1E4D0)),
      ),
      child: Row(
        children: [
          // Number + Icon Badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, color: accentColor, size: 20),
            ),
          ),
          const SizedBox(width: 12),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.mukta(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: MandirTheme.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.mukta(
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                    color: MandirTheme.textDark,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),

          // Subtitle (End time / deity)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EFE6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              subtitle,
              style: GoogleFonts.mukta(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF755034),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SHUBH MUHURAT (शुभ मुहूर्त)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildShubhMuhuratCard(PanchangData panchang, String langCode) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FDF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF2E7D32),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'शुभ मुहूर्त (Auspicious Timings)',
                  style: GoogleFonts.mukta(
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Highlighted Abhijit Muhurat
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF81C784)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            color: Color(0xFF2E7D32),
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'अभिजीत मुहूर्त',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.mukta(
                                fontSize: 17.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'सर्वोत्तम',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      panchang.abhijitMuhurat,
                      style: GoogleFonts.mukta(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'दिवसातील सर्वात मंगल मुहूर्त (नवीन कामांसाठी उत्तम)',
                  style: GoogleFonts.mukta(
                    fontSize: 13.5,
                    color: const Color(0xFF33691E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _buildMuhuratLine('अमृत काळ', panchang.amritKaal, 'अमृतमयी सिद्धावस्था'),
          _buildMuhuratLine(
            'ब्रह्म मुहूर्त',
            panchang.brahmaMuhurat,
            'ध्यान, साधना व पूजेसाठी उत्तम',
          ),
          _buildMuhuratLine('विजय मुहूर्त', panchang.vijayaMuhurat, 'कार्यारंभ यशदायक'),
          _buildMuhuratLine('गोधूलि मुहूर्त', panchang.godhuliMuhurat, 'संध्या दीप प्रज्वलन'),
        ],
      ),
    );
  }

  Widget _buildMuhuratLine(String label, String timing, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.mukta(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: MandirTheme.textDark,
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.mukta(
                    fontSize: 13,
                    color: MandirTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timing,
            style: GoogleFonts.mukta(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ASHUBH KAAL (अशुभ काळ - वर्ज्य वेळ)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAshubhKaalCard(PanchangData panchang, String langCode) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFC62828),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'अशुभ काळ / वर्ज्य वेळ (Inauspicious Windows)',
                  style: GoogleFonts.mukta(
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB71C1C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Prominent Rahu Kaal Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF9A9A)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'राहु काळ (Rahu Kaal)',
                        style: GoogleFonts.mukta(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFC62828),
                        ),
                      ),
                      Text(
                        'या काळात नवीन व शुभ कार्य टाळावे',
                        style: GoogleFonts.mukta(
                          fontSize: 13.5,
                          color: const Color(0xFF755034),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  panchang.rahuKaal,
                  style: GoogleFonts.mukta(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFB71C1C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _buildAshubhLine('यमगंड', panchang.yamaganda),
          _buildAshubhLine('गुलिक काळ', panchang.gulikaKaal),
          _buildAshubhLine('दुर्मुहूर्त', panchang.durmuhurat),
          _buildAshubhLine('भद्रा काळ', panchang.bhadra),
        ],
      ),
    );
  }

  Widget _buildAshubhLine(String label, String timing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.mukta(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: MandirTheme.textDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timing,
            style: GoogleFonts.mukta(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFC62828),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TODAY'S FESTIVAL & VRAT (सण, उत्सव व व्रत)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFestivalCard(PanchangData panchang, String langCode) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF3E0),
            Color(0xFFFFE0B2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: MandirTheme.primarySaffron.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.festival_rounded,
                  color: MandirTheme.primarySaffron,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'आजचे सण, उत्सव व व्रत',
                    style: GoogleFonts.mukta(
                      fontSize: 18.5,
                      fontWeight: FontWeight.bold,
                      color: MandirTheme.secondaryMaroon,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Festival Title
            Text(
              panchang.festivalName,
              style: GoogleFonts.mukta(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: MandirTheme.textDark,
                height: 1.2,
              ),
            ),
            if (panchang.vrat.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: MandirTheme.primarySaffron.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'व्रत: ${panchang.vrat}',
                  style: GoogleFonts.mukta(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: MandirTheme.primarySaffron,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),

            // Description
            Text(
              panchang.festivalDescription,
              style: GoogleFonts.mukta(
                fontSize: 16,
                color: const Color(0xFF5D4037),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DAILY GUIDANCE & MANTRA
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDailyGuidanceCard(PanchangData panchang, String langCode) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDDBC2)),
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
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: MandirTheme.goldenAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'आजचा मंत्र व मार्गदर्शन',
                  style: GoogleFonts.mukta(
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                    color: MandirTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Daily Mantra Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9EC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8D3A7)),
            ),
            child: Column(
              children: [
                Text(
                  '॥ आजचा सिद्ध मंत्र ॥',
                  style: GoogleFonts.mukta(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MandirTheme.goldenAccent,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  panchang.dailyMantra,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mukta(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: MandirTheme.secondaryMaroon,
                  ),
                ),
                const SizedBox(height: 5),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: panchang.dailyMantra));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('मंत्र कॉपी केला!'),
                        duration: Duration(seconds: 1),
                        backgroundColor: MandirTheme.primarySaffron,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.copy_rounded,
                          size: 15,
                          color: MandirTheme.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'मंत्र कॉपी करा',
                          style: GoogleFonts.mukta(
                            fontSize: 13.5,
                            color: MandirTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (panchang.specialGuidance.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                '💡 टीप: ${panchang.specialGuidance}',
                style: GoogleFonts.mukta(
                  fontSize: 15.5,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF6D5545),
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  MODAL SHEET FOR CITY SELECTION & GPS AUTO-DETECTION
// ═════════════════════════════════════════════════════════════════════════════
class _CitySelectionSheet extends ConsumerStatefulWidget {
  final PanchangCity currentCity;
  final String langCode;

  const _CitySelectionSheet({
    required this.currentCity,
    required this.langCode,
  });

  @override
  ConsumerState<_CitySelectionSheet> createState() =>
      _CitySelectionSheetState();
}

class _CitySelectionSheetState extends ConsumerState<_CitySelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLocating = false;
  String _filter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final locationService = ref.read(locationServiceProvider);
      final detected = await locationService.detectCurrentCity();
      ref.read(selectedPanchangCityProvider.notifier).state = detected;
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📍 स्थान शोधले: ${detected.localizedName(widget.langCode)} (${detected.stateOrCountry})',
            ),
            backgroundColor: MandirTheme.secondaryMaroon,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLocating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('स्थान शोधण्यात अडचण आली. कृपया सूचीमधून निवडा.'),
            backgroundColor: MandirTheme.secondaryMaroon,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCities = kPopularPanchangCities.where((c) {
      if (_filter.isEmpty) return true;
      final q = _filter.toLowerCase();
      return c.nameMr.toLowerCase().contains(q) ||
          c.nameHi.toLowerCase().contains(q) ||
          c.nameEn.toLowerCase().contains(q) ||
          c.stateOrCountry.toLowerCase().contains(q);
    }).toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.78,
      child: Material(
        color: const Color(0xFFFFFBF2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  Icons.location_city_rounded,
                  color: MandirTheme.primarySaffron,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.langCode == 'en'
                      ? 'Select City / Location'
                      : 'स्थान / शहर निवडा',
                  style: GoogleFonts.mukta(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: MandirTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Use Current Location (GPS) Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: _isLocating ? null : _useCurrentLocation,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF81C784)),
                ),
                child: Row(
                  children: [
                    _isLocating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2E7D32),
                            ),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            color: Color(0xFF2E7D32),
                            size: 20,
                          ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.langCode == 'en'
                                ? 'Use Current Location (GPS)'
                                : 'सध्याचे स्थान वापरा (GPS)',
                            style: GoogleFonts.mukta(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B5E20),
                            ),
                          ),
                          Text(
                            widget.langCode == 'en'
                                ? 'Auto-detect exact sunrise, sunset & muhurat'
                                : 'स्थानिक सूर्योदय, सूर्यास्त व मुहूर्त स्वयंचलित सेट करा',
                            style: GoogleFonts.mukta(
                              fontSize: 13.5,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Color(0xFF2E7D32),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _filter = val.trim()),
              style: const TextStyle(fontSize: 15.5),
              decoration: InputDecoration(
                hintText: widget.langCode == 'en'
                    ? 'Search city (e.g. Pune, Mumbai, Kashi)...'
                    : 'शहर शोधा (उदा. पुणे, मुंबई, काशी, अयोध्या)...',
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: MandirTheme.textMuted,
                ),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filter = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0CEB5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0CEB5)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Cities List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: filteredCities.length,
              separatorBuilder: (context, index) => const Divider(
                color: Color(0xFFF1E4D0),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final city = filteredCities[index];
                final isSelected = city.id == widget.currentCity.id;

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? MandirTheme.primarySaffron
                          : const Color(0xFFF5EBE1),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: isSelected ? Colors.white : MandirTheme.primarySaffron,
                      ),
                    ),
                  ),
                  title: Text(
                    city.localizedName(widget.langCode),
                    style: GoogleFonts.mukta(
                      fontSize: 18,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? MandirTheme.primarySaffron
                          : MandirTheme.textDark,
                    ),
                  ),
                  subtitle: Text(
                    '${city.stateOrCountry} • ${city.latitude.toStringAsFixed(2)}°N, ${city.longitude.toStringAsFixed(2)}°E',
                    style: GoogleFonts.mukta(
                      fontSize: 14,
                      color: MandirTheme.textMuted,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: MandirTheme.primarySaffron,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    ref.read(selectedPanchangCityProvider.notifier).state =
                        city;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '📍 शहर: ${city.localizedName(widget.langCode)} निवडले!',
                        ),
                        backgroundColor: MandirTheme.secondaryMaroon,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
}

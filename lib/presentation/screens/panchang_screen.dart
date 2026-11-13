import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/panchang.dart';
import '../../domain/entities/panchang_city.dart';
import '../../domain/logic/panchang_timing.dart';
import '../../services/backend_service.dart';
import '../../services/tithi_engine_names.dart';
import '../../services/tithi_engine_service.dart';
import '../panchang/panchang_strings.dart';
import '../panchang/tithi_engine_widgets.dart';
import '../providers/locale_provider.dart';
import '../providers/panchang_provider.dart';
import '../widgets/language_dropdown.dart';

/// Redesigned Daily Vedic Panchang Screen
/// Matches the reference UI mockup with:
/// - Clean typography app bar with Language dropdown pill and Refresh pill
/// - Rounded location card with pin icon
/// - Date navigation capsule (< Prev | Today | Next >) + separate Calendar button
/// - Warm celestial Today Hero card with astrolabe moon-phase dial
/// - Panchang details card with 3 sections: Five parts, Rashi, Year & season
/// - Sun & Moon 2x2 grid cards with warm peach and soft lavender accents
/// - Upcoming festivals & vrats with date badges and search pill button
class PanchangScreen extends ConsumerStatefulWidget {
  const PanchangScreen({super.key});

  @override
  ConsumerState<PanchangScreen> createState() => _PanchangScreenState();
}

class _PanchangScreenState extends ConsumerState<PanchangScreen> {
  Timer? _minuteTicker;

  @override
  void initState() {
    super.initState();
    BackendService.trackEvent('panchang_open');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(autoDetectLocationProvider);
    });
    _minuteTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _minuteTicker?.cancel();
    super.dispose();
  }

  void _showCitySelectionSheet(PanchangCity currentCity, String langCode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PanchangCitySheet(
        currentCity: currentCity,
        langCode: langCode,
      ),
    );
  }

  Future<void> _selectDate() async {
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
              primary: Color(0xFFBA471A),
              onPrimary: Colors.white,
              surface: Color(0xFFFFFBF2),
              onSurface: Color(0xFF2C1E14),
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

  void _refresh() {
    ref.read(panchangRefreshTriggerProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    final panchangAsync = ref.watch(currentPanchangDataProvider);
    final selectedDate = ref.watch(selectedPanchangDateProvider);
    final selectedCity = ref.watch(selectedPanchangCityProvider);
    final langCode = ref.watch(localeProvider).languageCode;
    final s = PanchangStrings(langCode);
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildAppBar(s),

            // City Location Selector Bar
            _buildCitySelectorBar(selectedCity, langCode, s),

            // Date Navigation Row
            _buildDateSelector(selectedDate, isToday, s),

            // Main Content Area
            Expanded(
              child: panchangAsync.when(
                loading: () => _buildLoading(s),
                error: (err, _) => _buildError(s),
                data: (panchang) => _buildContent(
                  panchang,
                  s,
                  isToday: isToday,
                  nowMinute: now.hour * 60 + now.minute,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(PanchangStrings s) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFFBA471A)),
          const SizedBox(height: 14),
          Text(
            s.loading,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: const Color(0xFF6D3214),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(PanchangStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: Color(0xFFBA471A),
            ),
            const SizedBox(height: 12),
            Text(
              s.loadError,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                color: const Color(0xFF2C1E14),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(s.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA471A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    PanchangData panchang,
    PanchangStrings s, {
    required bool isToday,
    required int nowMinute,
  }) {
    final slots = panchangSlots(panchang);
    final nowStatus = isToday ? panchangNow(slots, nowMinute) : null;
    final snapshot = ref.watch(tithiDaySnapshotProvider).valueOrNull;

    return RefreshIndicator(
      color: const Color(0xFFBA471A),
      backgroundColor: const Color(0xFFFFFBF2),
      onRefresh: () async => _refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // 1. Hero Today Card with Astrolabe Dial
          _TodayCard(
            panchang: panchang,
            slots: slots,
            now: nowStatus,
            s: s,
            snapshot: snapshot,
          ),
          const SizedBox(height: 20),

          // 2. Full Panchang Details Card (Five Parts, Rashi, Year & Season)
          _FullPanchangCard(panchang: panchang, s: s),
          const SizedBox(height: 20),

          // 3. Sun & Moon 2x2 Grid Cards
          _SunMoonCard(panchang: panchang, s: s),
          const SizedBox(height: 20),

          // 4. Upcoming Festivals & Vrats Card with Search Button
          UpcomingObservancesCard(s: s),
          const SizedBox(height: 24),

          // 5. Sacred Centered Footer
          Center(
            child: Text(
              '॥ शुभं भवतु • सर्वं श्रीकृष्णार्पणमस्तु ॥',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
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
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TOP BAR, CITY & DATE SELECTORS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAppBar(PanchangStrings s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: const Color(0xFFFAF7F0),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                s.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2C1E14),
                  letterSpacing: -0.6,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const LanguageDropdown(),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(s.refreshing),
                  duration: const Duration(seconds: 1),
                  backgroundColor: MandirTheme.secondaryMaroon,
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF7EFE4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEADBCE), width: 1.0),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                size: 20,
                color: Color(0xFF6D3214),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitySelectorBar(
    PanchangCity currentCity,
    String langCode,
    PanchangStrings s,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEDDC8), width: 1.1),
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
          onTap: () => _showCitySelectionSheet(currentCity, langCode),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFDE8D4),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 17,
                    color: Color(0xFFBA471A),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.location,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8C7565),
                        ),
                      ),
                      Text(
                        '${currentCity.localizedName(langCode)} (${currentCity.stateOrCountry})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2C1E14),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: Color(0xFF8C7565),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(
    DateTime selectedDate,
    bool isToday,
    PanchangStrings s,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          // Capsule bar containing Prev, Today, Next
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEEDDC8), width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Prev Button
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: () => _shiftDate(-1),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.chevron_left_rounded,
                              size: 17,
                              color: Color(0xFF5A3E2B),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                s.prev,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF5A3E2B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Today Button (Terracotta Pill - Selected Active Date)
                  Expanded(
                    flex: 4,
                    child: InkWell(
                      onTap: isToday ? _selectDate : _goToToday,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBA471A),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFBA471A).withValues(alpha: 0.28),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            isToday
                                ? s.today
                                : DateFormat('dd MMM').format(selectedDate),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Next Button
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: () => _shiftDate(1),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                s.next,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF5A3E2B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 17,
                              color: Color(0xFF5A3E2B),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Separate Calendar Icon Button
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEEDDC8), width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                size: 20,
                color: Color(0xFFBA471A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header Helper
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFDE8D4),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFFBA471A), size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2C1E14),
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  1. HERO TODAY CARD (WITH ASTROLABE DIAL)
// ═════════════════════════════════════════════════════════════════════════════
class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.panchang,
    required this.slots,
    required this.now,
    required this.s,
    this.snapshot,
  });

  final PanchangData panchang;
  final List<PanchangSlot> slots;
  final PanchangNow? now;
  final PanchangStrings s;
  final TithiDaySnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('panchang-today-card'),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7ED), Color(0xFFFDF0DC)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF3DEC8), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        panchang.formattedDate,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8C6546),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${panchang.maas} ${panchang.paksha}\n${panchang.tithi}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2C1E14),
                          height: 1.18,
                        ),
                      ),
                      if (panchang.festivalName.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('🪔', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                panchang.festivalName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFBA471A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Astrolabe Dial Graphic on the right
                const SizedBox(
                  width: 84,
                  height: 84,
                  child: CustomPaint(
                    painter: _AstrolabeDialPainter(color: Color(0xFFB88C64)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bottom Row: Tithi right now
            Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.nightlight_outlined,
                      size: 15,
                      color: Color(0xFF8C6546),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      s.lang == 'mr'
                          ? 'चालू तिथी'
                          : (s.lang == 'hi'
                              ? 'वर्तमान तिथि'
                              : 'Tithi right now'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8C6546),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    snapshot?.currentTithi != null
                        ? TithiEngineNames(s.lang).tithiLabel(snapshot!.currentTithi!)
                        : '${panchang.paksha} ${panchang.tithi}',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFBA471A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Footnote
            Text(
              s.lang == 'mr'
                  ? 'खगोलीय गणना: अयनांश: लाहिरी • निर्देशांक: ${panchang.cityName}'
                  : (s.lang == 'hi'
                      ? 'खगोलीय गणना: अयनांश: लाहिड़ी • निर्देशांक: ${panchang.cityName}'
                      : 'Astronomical calculation: Ayanamsha: Lahiri, Coordinates: ${panchang.cityName}'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFA08875),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Astrolabe Dial Painter
// ─────────────────────────────────────────────────────────────────────────────
class _AstrolabeDialPainter extends CustomPainter {
  final Color color;
  const _AstrolabeDialPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final tickPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final circlePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer ticks
    for (int i = 0; i < 36; i++) {
      final angle = (i * 10) * (math.pi / 180);
      final isMajor = i % 3 == 0;
      final startR = radius - (isMajor ? 8.0 : 4.0);
      final endR = radius - 1.0;
      final p1 = Offset(
        center.dx + startR * math.cos(angle),
        center.dy + startR * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + endR * math.cos(angle),
        center.dy + endR * math.sin(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Outer ring
    canvas.drawCircle(center, radius - 8.0, circlePaint);
    // Inner ring
    canvas.drawCircle(center, radius - 14.0, circlePaint);

    // Inner glowing crescent moon
    final moonCenter = center;
    final moonRadius = radius * 0.42;
    final moonPath = Path()
      ..moveTo(moonCenter.dx, moonCenter.dy - moonRadius)
      ..cubicTo(
        moonCenter.dx - moonRadius * 1.1,
        moonCenter.dy - moonRadius * 0.8,
        moonCenter.dx - moonRadius * 1.1,
        moonCenter.dy + moonRadius * 0.8,
        moonCenter.dx,
        moonCenter.dy + moonRadius,
      )
      ..cubicTo(
        moonCenter.dx - moonRadius * 0.4,
        moonCenter.dy + moonRadius * 0.6,
        moonCenter.dx - moonRadius * 0.4,
        moonCenter.dy - moonRadius * 0.6,
        moonCenter.dx,
        moonCenter.dy - moonRadius,
      );

    final moonFill = Paint()
      ..color = color.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    final moonStroke = Paint()
      ..color = color.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(moonPath, moonFill);
    canvas.drawPath(moonPath, moonStroke);

    // Subtle star dots inside
    final dotPaint = Paint()..color = color.withValues(alpha: 0.6);
    canvas.drawCircle(
      Offset(center.dx + moonRadius * 0.4, center.dy - moonRadius * 0.3),
      1.2,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + moonRadius * 0.5, center.dy + moonRadius * 0.2),
      1.0,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AstrolabeDialPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ═════════════════════════════════════════════════════════════════════════════
//  2. FULL PANCHANG DETAILS CARD
// ═════════════════════════════════════════════════════════════════════════════
class _FullPanchangCard extends StatelessWidget {
  const _FullPanchangCard({
    required this.panchang,
    required this.s,
  });

  final PanchangData panchang;
  final PanchangStrings s;

  @override
  Widget build(BuildContext context) {
    final p = panchang;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.menu_book_rounded,
          title: s.detailsTitle,
        ),
        const SizedBox(height: 12),
        Container(
          key: const Key('panchang-full-details'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0E4D4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Part 1: The five parts of Panchang
              _subHeader(s.limbsSection),
              const SizedBox(height: 8),
              _row(s.tithi, s.tithiMeaning, '${p.paksha} ${p.tithi}', p.tithiEndTime),
              _divider(),
              _row(s.vaar, s.vaarMeaning(p.vaarGraha), p.vaar, null),
              _divider(),
              _row(s.nakshatra, s.nakshatraMeaning, p.nakshatra, p.nakshatraEndTime),
              _divider(),
              _row(s.yoga, s.yogaMeaning, p.yoga, p.yogaEndTime),
              _divider(),
              _row(s.karana, s.karanaMeaning, p.karana, p.karanaEndTime),

              const SizedBox(height: 18),

              // Part 2: Rashi (signs)
              _subHeader(s.rashiSection),
              const SizedBox(height: 8),
              _row(s.suryaRashi, null, p.suryaRashi, null),
              _divider(),
              _row(s.chandraRashi, null, p.chandraRashi, null),

              const SizedBox(height: 18),

              // Part 3: Year & season
              _subHeader(s.yearSection),
              const SizedBox(height: 8),
              _row(s.maas, null, p.maas, null),
              _divider(),
              _row(s.paksha, null, p.paksha, null),
              _divider(),
              _row(s.vikramSamvat, null, p.vikramSamvat, null),
              _divider(),
              _row(s.shakaSamvat, null, p.shakaSamvat, null),
              _divider(),
              _row(s.samvatsara, null, p.samvatsara, null),
              _divider(),
              _row(s.ritu, null, p.ritu, null),
              _divider(),
              _row(s.ayana, null, p.ayana, null),
            ],
          ),
        ),
      ],
    );
  }

  Widget _subHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF8D3F1B),
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Divider(
        height: 1,
        thickness: 0.8,
        color: Color(0xFFF7ECE1),
      ),
    );
  }

  Widget _row(String label, String? meaning, String value, String? ends) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C1E14),
                    height: 1.2,
                  ),
                ),
                if (meaning != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    meaning,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8C7565),
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2C1E14),
                    height: 1.2,
                  ),
                ),
                if (ends != null && ends.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    ends,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFBA471A),
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  3. SUN & MOON (2X2 GRID CARDS)
// ═════════════════════════════════════════════════════════════════════════════
class _SunMoonCard extends StatelessWidget {
  const _SunMoonCard({
    required this.panchang,
    required this.s,
  });

  final PanchangData panchang;
  final PanchangStrings s;

  @override
  Widget build(BuildContext context) {
    Widget miniCard({
      required IconData icon,
      required String label,
      required String value,
      required Color cardBg,
      required Color borderColor,
      required Color iconBoxBg,
      required Color iconColor,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.1),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBoxBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8C7565),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2C1E14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.wb_sunny_rounded,
          title: s.sunMoonTitle,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            miniCard(
              icon: Icons.wb_sunny_outlined,
              label: s.sunrise,
              value: panchang.sunrise,
              cardBg: const Color(0xFFFEF3E4),
              borderColor: const Color(0xFFF8E2C8),
              iconBoxBg: const Color(0xFFFDE5D0),
              iconColor: const Color(0xFFBA471A),
            ),
            const SizedBox(width: 10),
            miniCard(
              icon: Icons.wb_twilight_rounded,
              label: s.sunset,
              value: panchang.sunset,
              cardBg: const Color(0xFFFEF3E4),
              borderColor: const Color(0xFFF8E2C8),
              iconBoxBg: const Color(0xFFFDE5D0),
              iconColor: const Color(0xFFBA471A),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            miniCard(
              icon: Icons.nightlight_round,
              label: s.moonrise,
              value: panchang.moonrise,
              cardBg: const Color(0xFFF9EEF2),
              borderColor: const Color(0xFFEBDDE6),
              iconBoxBg: const Color(0xFFF7DDE6),
              iconColor: const Color(0xFF884D68),
            ),
            const SizedBox(width: 10),
            miniCard(
              icon: Icons.dark_mode_outlined,
              label: s.moonset,
              value: panchang.moonset,
              cardBg: const Color(0xFFF9EEF2),
              borderColor: const Color(0xFFEBDDE6),
              iconBoxBg: const Color(0xFFF7DDE6),
              iconColor: const Color(0xFF884D68),
            ),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  CITY SELECTION SHEET
// ═════════════════════════════════════════════════════════════════════════════
class PanchangCitySheet extends ConsumerStatefulWidget {
  final PanchangCity currentCity;
  final String langCode;

  const PanchangCitySheet({
    super.key,
    required this.currentCity,
    required this.langCode,
  });

  @override
  ConsumerState<PanchangCitySheet> createState() =>
      _PanchangCitySheetState();
}

class _PanchangCitySheetState extends ConsumerState<PanchangCitySheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLocating = false;
  String _filter = '';

  PanchangStrings get s => PanchangStrings(widget.langCode);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final locStatus = await Geolocator.checkPermission();
      if (locStatus == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLocating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.langCode == 'mr'
                    ? 'स्थान परवानगी बंद आहे. कृपया सेटिंग्जमध्ये जाऊन परवानगी द्या.'
                    : (widget.langCode == 'hi'
                        ? 'स्थान अनुमति बंद है। कृपया सेटिंग्स में जाकर अनुमति दें।'
                        : 'Location permission is disabled. Please enable it in Settings.'),
              ),
              action: SnackBarAction(
                label: widget.langCode == 'mr'
                    ? 'सेटिंग्ज'
                    : (widget.langCode == 'hi' ? 'सेटिंग्स' : 'Settings'),
                onPressed: () => Geolocator.openAppSettings(),
              ),
              backgroundColor: MandirTheme.secondaryMaroon,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final locationService = ref.read(locationServiceProvider);
      final detected = await locationService.detectCurrentCity(
        requestPermission: true,
        forceGps: true,
      );
      ref.read(selectedPanchangCityProvider.notifier).state = detected;
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.locationFound(
                '${detected.localizedName(widget.langCode)} (${detected.stateOrCountry})',
              ),
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
          SnackBar(
            content: Text(s.locationFailed),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_city_rounded,
                    color: Color(0xFFBA471A),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.selectCity,
                      style: GoogleFonts.mukta(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: MandirTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
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
                              s.useGps,
                              style: GoogleFonts.mukta(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B5E20),
                              ),
                            ),
                            Text(
                              s.useGpsHint,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _filter = val.trim()),
                style: const TextStyle(fontSize: 15.5),
                decoration: InputDecoration(
                  hintText: s.searchCity,
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
                            ? const Color(0xFFBA471A)
                            : const Color(0xFFF5EBE1),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFBA471A),
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
                            ? const Color(0xFFBA471A)
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
                            color: Color(0xFFBA471A),
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
                            s.citySelected(city.localizedName(widget.langCode)),
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/panchang.dart';
import '../../domain/entities/panchang_city.dart';
import '../../domain/logic/panchang_timing.dart';
import '../../services/backend_service.dart';
import '../panchang/panchang_strings.dart';
import '../providers/locale_provider.dart';
import '../providers/panchang_provider.dart';

const _goodColor = Color(0xFF2E7D32);
const _goodDark = Color(0xFF1B5E20);
const _goodBg = Color(0xFFF1F8F1);
const _badColor = Color(0xFFC62828);
const _badDark = Color(0xFFB71C1C);
const _badBg = Color(0xFFFFF4F4);
const _cardBorder = Color(0xFFEDDBC2);
const _brownText = Color(0xFF755034);

/// Daily Vedic Panchang for the user's city, arranged so the most useful
/// answers (what is happening now, when is a good time, what to avoid) come
/// first and the technical Panchang details stay one tap away.
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
      builder: (ctx) => _CitySelectionSheet(
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
      backgroundColor: MandirTheme.backgroundCream,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(s),
            _buildCitySelectorBar(selectedCity, langCode, s),
            _buildDateSelector(selectedDate, isToday, s),
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
          const CircularProgressIndicator(color: MandirTheme.primarySaffron),
          const SizedBox(height: 14),
          Text(
            s.loading,
            textAlign: TextAlign.center,
            style: GoogleFonts.mukta(fontSize: 17, color: MandirTheme.textDark),
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
              color: MandirTheme.primarySaffron,
            ),
            const SizedBox(height: 12),
            Text(
              s.loadError,
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(fontSize: 18, color: MandirTheme.textDark),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(s.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: MandirTheme.primarySaffron,
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
    final hasFestival = panchang.festivalName.isNotEmpty ||
        panchang.festivalDescription.isNotEmpty ||
        panchang.dailyMantra.isNotEmpty;

    return RefreshIndicator(
      color: MandirTheme.primarySaffron,
      backgroundColor: const Color(0xFFFFFBF2),
      onRefresh: () async => _refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _TodayCard(panchang: panchang, slots: slots, now: nowStatus, s: s),
          const SizedBox(height: 16),
          _ScheduleCard(
            slots: slots,
            s: s,
            nowMinute: isToday ? nowMinute : null,
          ),
          if (hasFestival) ...[
            const SizedBox(height: 16),
            _FestivalCard(panchang: panchang, s: s),
          ],
          const SizedBox(height: 16),
          _SunMoonCard(panchang: panchang, s: s),
          const SizedBox(height: 16),
          _FullPanchangCard(panchang: panchang, s: s),
          const SizedBox(height: 20),
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
          if (panchang.isAiGenerated) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                s.aiSource,
                style: GoogleFonts.mukta(
                  fontSize: 13,
                  color: MandirTheme.textMuted,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TOP BAR, CITY & DATE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAppBar(PanchangStrings s) {
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
                  s.title,
                  style: GoogleFonts.mukta(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: MandirTheme.textDark,
                    height: 1.1,
                  ),
                ),
                Text(
                  s.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.mukta(
                    fontSize: 14.5,
                    color: MandirTheme.textMuted,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh Panchang',
            icon: const Icon(
              Icons.refresh_rounded,
              color: MandirTheme.primarySaffron,
              size: 24,
            ),
            onPressed: () {
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(s.refreshing),
                  duration: const Duration(seconds: 1),
                  backgroundColor: MandirTheme.secondaryMaroon,
                ),
              );
            },
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: const BoxDecoration(
        color: Color(0xFFFBF4E8),
        border: Border(bottom: BorderSide(color: Color(0xFFEEDCC7))),
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
                s.location,
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
              onTap: () => _showCitySelectionSheet(currentCity, langCode),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: const Color(0xFFD4AF37), width: 1.2),
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

  Widget _buildDateSelector(
    DateTime selectedDate,
    bool isToday,
    PanchangStrings s,
  ) {
    Widget sideButton({
      required String label,
      required IconData icon,
      required bool iconFirst,
      required VoidCallback onTap,
    }) {
      final iconWidget = Icon(icon, size: 18, color: MandirTheme.textDark);
      return InkWell(
        onTap: onTap,
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
              if (iconFirst) iconWidget,
              Text(
                label,
                style: GoogleFonts.mukta(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: MandirTheme.textDark,
                ),
              ),
              if (!iconFirst) iconWidget,
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      color: const Color(0xFFF7EFE1),
      child: Row(
        children: [
          sideButton(
            label: s.prev,
            icon: Icons.chevron_left,
            iconFirst: true,
            onTap: () => _shiftDate(-1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: isToday ? _selectDate : _goToToday,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isToday
                        ? const [MandirTheme.primarySaffron, Color(0xFFE65100)]
                        : const [Color(0xFFFFF7E6), Color(0xFFFFECC8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isToday
                        ? MandirTheme.primarySaffron
                        : const Color(0xFFD4AF37),
                    width: 1.2,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
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
                            ? s.today
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
                          s.goToday,
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
          sideButton(
            label: s.next,
            icon: Icons.chevron_right,
            iconFirst: false,
            onTap: () => _shiftDate(1),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _selectDate,
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
}

// ═════════════════════════════════════════════════════════════════════════════
//  SHARED PIECES
// ═════════════════════════════════════════════════════════════════════════════
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.icon, this.text, {this.color = MandirTheme.primarySaffron});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.mukta(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: MandirTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.color, this.filled = true});

  final String text;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: GoogleFonts.mukta(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }
}

/// Start time on top, end time below, so long ranges never squeeze the name.
class _TimeRange extends StatelessWidget {
  const _TimeRange(this.slot, {required this.color});

  final PanchangSlot slot;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final parts = slot.rangeParts;
    final style = GoogleFonts.mukta(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.2,
    );
    if (parts == null) {
      return Text(slot.raw, style: style, textAlign: TextAlign.end);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(parts.$1, style: style),
        Text(
          '– ${parts.$2}',
          style: style.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  1. TODAY AT A GLANCE
// ═════════════════════════════════════════════════════════════════════════════
class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.panchang,
    required this.slots,
    required this.now,
    required this.s,
  });

  final PanchangData panchang;
  final List<PanchangSlot> slots;
  final PanchangNow? now;
  final PanchangStrings s;

  PanchangSlot? _slot(PanchangSlotKind kind) {
    for (final slot in slots) {
      if (slot.kind == kind) return slot;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final best = _slot(PanchangSlotKind.abhijit);
    final avoid = _slot(PanchangSlotKind.rahu);

    return Container(
      key: const Key('panchang-today-card'),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF9EC), Color(0xFFFBEFD7)],
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
          Positioned(
            right: -15,
            top: -15,
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/decorations/corner_mandala.png',
                width: 140,
                height: 140,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  panchang.formattedDate,
                  style: GoogleFonts.mukta(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: MandirTheme.secondaryMaroon,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${panchang.maas} ${panchang.paksha} ${panchang.tithi}',
                  style: GoogleFonts.mukta(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: MandirTheme.textDark,
                    height: 1.15,
                  ),
                ),
                if (panchang.festivalName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🪔', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          panchang.festivalName,
                          style: GoogleFonts.mukta(
                            fontSize: 17.5,
                            fontWeight: FontWeight.bold,
                            color: MandirTheme.primarySaffron,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (now != null) ...[
                  const SizedBox(height: 14),
                  _NowBanner(now: now!, s: s),
                ],
                if (best != null || avoid != null) ...[
                  const SizedBox(height: 14),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (best != null)
                          Expanded(
                            child: _KeyTimeTile(
                              label: s.bestTime,
                              slot: best,
                              s: s,
                            ),
                          ),
                        if (best != null && avoid != null)
                          const SizedBox(width: 10),
                        if (avoid != null)
                          Expanded(
                            child: _KeyTimeTile(
                              label: s.avoidTime,
                              slot: avoid,
                              s: s,
                            ),
                          ),
                      ],
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

class _NowBanner extends StatelessWidget {
  const _NowBanner({required this.now, required this.s});

  final PanchangNow now;
  final PanchangStrings s;

  @override
  Widget build(BuildContext context) {
    final name = s.slotName(now.slot.kind);
    final parts = now.slot.rangeParts;
    final start = parts?.$1 ?? now.slot.raw;
    final end = parts?.$2 ?? now.slot.raw;

    final (IconData icon, Color color, Color bg, String title, String sub) =
        switch (now.kind) {
      PanchangNowKind.avoid => (
          Icons.do_not_disturb_on_rounded,
          _badColor,
          const Color(0xFFFFEBEE),
          s.nowAvoid(name),
          s.nowAvoidSub(end),
        ),
      PanchangNowKind.good => (
          Icons.check_circle_rounded,
          _goodColor,
          const Color(0xFFE8F5E9),
          s.nowGood(name),
          s.until(end),
        ),
      PanchangNowKind.nextGood => (
          Icons.schedule_rounded,
          const Color(0xFF8D5A00),
          const Color(0xFFFFF3D6),
          s.nextGood(name),
          s.from(start),
        ),
    };

    return Container(
      key: const Key('panchang-now-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.3),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.mukta(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.2,
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.mukta(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _brownText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyTimeTile extends StatelessWidget {
  const _KeyTimeTile({required this.label, required this.slot, required this.s});

  final String label;
  final PanchangSlot slot;
  final PanchangStrings s;

  @override
  Widget build(BuildContext context) {
    final good = slot.isGood;
    final color = good ? _goodDark : _badDark;
    final parts = slot.rangeParts;
    final timeStyle = GoogleFonts.mukta(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.2,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: good ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: good ? const Color(0xFF81C784) : const Color(0xFFEF9A9A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                good ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.mukta(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s.slotName(slot.kind),
            style: GoogleFonts.mukta(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: _brownText,
            ),
          ),
          const Spacer(),
          if (parts == null)
            Text(slot.raw, style: timeStyle)
          else ...[
            Text(parts.$1, style: timeStyle),
            Text('– ${parts.$2}', style: timeStyle),
          ],
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  2. GOOD & BAD TIMES, IN ORDER OF THE DAY
// ═════════════════════════════════════════════════════════════════════════════
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.slots,
    required this.s,
    required this.nowMinute,
  });

  final List<PanchangSlot> slots;
  final PanchangStrings s;

  /// Only set when the selected date is today.
  final int? nowMinute;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(Icons.schedule_rounded, s.scheduleTitle),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: _goodColor, size: 16),
              const SizedBox(width: 4),
              Text(
                s.good,
                style: GoogleFonts.mukta(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: _goodColor,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.cancel_rounded, color: _badColor, size: 16),
              const SizedBox(width: 4),
              Text(
                s.avoid,
                style: GoogleFonts.mukta(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: _badColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final slot in slots) _slotRow(slot),
        ],
      ),
    );
  }

  Widget _slotRow(PanchangSlot slot) {
    final good = slot.isGood;
    final color = good ? _goodColor : _badColor;
    final minute = nowMinute;
    final window = slot.window;
    final isNow = minute != null && window != null && window.contains(minute);
    final isOver = minute != null && window != null && window.isOverAt(minute);

    return Opacity(
      opacity: isOver ? 0.5 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: good ? _goodBg : _badBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isNow ? color : color.withValues(alpha: 0.18),
            width: isNow ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              good ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: color,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        s.slotName(slot.kind),
                        style: GoogleFonts.mukta(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: MandirTheme.textDark,
                          height: 1.2,
                        ),
                      ),
                      if (isNow)
                        _Tag(s.now, color: color)
                      else if (isOver)
                        _Tag(s.over, color: MandirTheme.textMuted, filled: false)
                      else if (slot.isBest)
                        _Tag(good ? s.best : s.most, color: color),
                    ],
                  ),
                  Text(
                    s.slotMeaning(slot.kind),
                    style: GoogleFonts.mukta(
                      fontSize: 14,
                      color: MandirTheme.textMuted,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _TimeRange(slot, color: good ? _goodDark : _badDark),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  3. FESTIVAL, VRAT & MANTRA
// ═════════════════════════════════════════════════════════════════════════════
class _FestivalCard extends StatelessWidget {
  const _FestivalCard({required this.panchang, required this.s});

  final PanchangData panchang;
  final PanchangStrings s;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF6E8), Color(0xFFFFE9C7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(Icons.festival_rounded, s.festivalTitle),
          if (panchang.festivalName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              panchang.festivalName,
              style: GoogleFonts.mukta(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: MandirTheme.textDark,
                height: 1.2,
              ),
            ),
          ],
          if (panchang.vrat.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: MandirTheme.primarySaffron.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${s.vrat}: ${panchang.vrat}',
                style: GoogleFonts.mukta(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: MandirTheme.primarySaffron,
                ),
              ),
            ),
          ],
          if (panchang.festivalDescription.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              panchang.festivalDescription,
              style: GoogleFonts.mukta(
                fontSize: 16.5,
                color: const Color(0xFF5D4037),
                height: 1.45,
              ),
            ),
          ],
          if (panchang.dailyMantra.isNotEmpty) ...[
            const SizedBox(height: 12),
            _mantraBox(context),
          ],
          if (panchang.specialGuidance.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '💡 ${s.tip}: ${panchang.specialGuidance}',
              style: GoogleFonts.mukta(
                fontSize: 16,
                color: const Color(0xFF6D5545),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mantraBox(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8D3A7)),
      ),
      child: Column(
        children: [
          Text(
            s.mantra,
            style: GoogleFonts.mukta(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: MandirTheme.goldenAccent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            panchang.dailyMantra,
            textAlign: TextAlign.center,
            style: GoogleFonts.mukta(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: MandirTheme.secondaryMaroon,
            ),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: panchang.dailyMantra));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(s.mantraCopied),
                  duration: const Duration(seconds: 1),
                  backgroundColor: MandirTheme.primarySaffron,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text(s.copyMantra, style: GoogleFonts.mukta(fontSize: 14.5)),
            style: TextButton.styleFrom(foregroundColor: MandirTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  4. SUN & MOON
// ═════════════════════════════════════════════════════════════════════════════
class _SunMoonCard extends StatelessWidget {
  const _SunMoonCard({required this.panchang, required this.s});

  final PanchangData panchang;
  final PanchangStrings s;

  @override
  Widget build(BuildContext context) {
    Widget tile(String emoji, String label, String value, Color bg) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.mukta(
                        fontSize: 14.5,
                        color: MandirTheme.textMuted,
                        height: 1.1,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: GoogleFonts.mukta(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          color: MandirTheme.textDark,
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

    const sunBg = Color(0xFFFFF4E0);
    const moonBg = Color(0xFFF0F4F8);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            Icons.wb_sunny_rounded,
            s.sunMoonTitle,
            color: const Color(0xFFE65100),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              tile('🌅', s.sunrise, panchang.sunrise, sunBg),
              const SizedBox(width: 10),
              tile('🌇', s.sunset, panchang.sunset, sunBg),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              tile('🌙', s.moonrise, panchang.moonrise, moonBg),
              const SizedBox(width: 10),
              tile('🌘', s.moonset, panchang.moonset, moonBg),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  5. FULL PANCHANG (one tap away)
// ═════════════════════════════════════════════════════════════════════════════
class _FullPanchangCard extends StatelessWidget {
  const _FullPanchangCard({required this.panchang, required this.s});

  final PanchangData panchang;
  final PanchangStrings s;

  @override
  Widget build(BuildContext context) {
    final p = panchang;
    return Material(
      color: MandirTheme.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const Key('panchang-full-details'),
          tilePadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: MandirTheme.primarySaffron,
          collapsedIconColor: MandirTheme.primarySaffron,
          leading: const Icon(
            Icons.auto_stories_rounded,
            color: MandirTheme.primarySaffron,
            size: 26,
          ),
          title: Text(
            s.detailsTitle,
            style: GoogleFonts.mukta(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: MandirTheme.textDark,
            ),
          ),
          subtitle: Text(
            s.detailsHint,
            style: GoogleFonts.mukta(
              fontSize: 14,
              color: MandirTheme.textMuted,
            ),
          ),
          children: [
            _section(s.limbsSection),
            _row(s.tithi, s.tithiMeaning, '${p.paksha} ${p.tithi}', p.tithiEndTime),
            _row(s.vaar, s.vaarMeaning(p.vaarGraha), p.vaar, null),
            _row(s.nakshatra, s.nakshatraMeaning, p.nakshatra, p.nakshatraEndTime),
            _row(s.yoga, s.yogaMeaning, p.yoga, p.yogaEndTime),
            _row(s.karana, s.karanaMeaning, p.karana, p.karanaEndTime),
            _section(s.rashiSection),
            _row(s.suryaRashi, null, p.suryaRashi, null),
            _row(s.chandraRashi, null, p.chandraRashi, null),
            _section(s.yearSection),
            _row(s.maas, null, p.maas, null),
            _row(s.paksha, null, p.paksha, null),
            _row(s.vikramSamvat, null, p.vikramSamvat, null),
            _row(s.shakaSamvat, null, p.shakaSamvat, null),
            _row(s.samvatsara, null, p.samvatsara, null),
            _row(s.ritu, null, p.ritu, null),
            _row(s.ayana, null, p.ayana, null),
          ],
        ),
      ),
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Row(
        children: [
          Text(
            text,
            style: GoogleFonts.mukta(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: MandirTheme.primarySaffron,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: Color(0xFFEBD9BD))),
        ],
      ),
    );
  }

  Widget _row(String label, String? meaning, String value, String? ends) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
                  style: GoogleFonts.mukta(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MandirTheme.textDark,
                    height: 1.2,
                  ),
                ),
                if (meaning != null)
                  Text(
                    meaning,
                    style: GoogleFonts.mukta(
                      fontSize: 13.5,
                      color: MandirTheme.textMuted,
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.mukta(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: MandirTheme.textDark,
                    height: 1.2,
                  ),
                ),
                if (ends != null && ends.isNotEmpty)
                  Text(
                    ends,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.mukta(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _brownText,
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  CITY SELECTION SHEET
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

  PanchangStrings get s => PanchangStrings(widget.langCode);

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
                    color: MandirTheme.primarySaffron,
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
                                color: _goodColor,
                              ),
                            )
                          : const Icon(
                              Icons.my_location_rounded,
                              color: _goodColor,
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
                                color: _goodDark,
                              ),
                            ),
                            Text(
                              s.useGpsHint,
                              style: GoogleFonts.mukta(
                                fontSize: 13.5,
                                color: _goodColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: _goodColor,
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
                            ? MandirTheme.primarySaffron
                            : const Color(0xFFF5EBE1),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: isSelected
                              ? Colors.white
                              : MandirTheme.primarySaffron,
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

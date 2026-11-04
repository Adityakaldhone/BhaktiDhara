import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/birth_profile.dart';
import '../../domain/entities/panchang_city.dart';
import '../../services/kundali/kundali_service.dart';
import '../kundali/kundali_strings.dart';
import '../providers/kundali_providers.dart';
import '../providers/locale_provider.dart';
import 'kundali_result_screen.dart';
import 'kundali_screen.dart';

class KundaliFormScreen extends ConsumerStatefulWidget {
  const KundaliFormScreen({super.key, this.initial, this.popOnSave = false});

  /// Profile being edited, or `null` to create a new one.
  final BirthProfile? initial;

  /// Pop with the saved [BirthProfile] instead of opening its chart.
  final bool popOnSave;

  @override
  ConsumerState<KundaliFormScreen> createState() => _KundaliFormScreenState();
}

class _KundaliFormScreenState extends ConsumerState<KundaliFormScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  DateTime? _date;
  TimeOfDay? _time;
  BirthPlace? _place;

  @override
  void initState() {
    super.initState();
    final b = widget.initial?.birthLocal;
    if (b != null) {
      _date = DateTime(b.year, b.month, b.day);
      _time = TimeOfDay(hour: b.hour, minute: b.minute);
    }
    _place = widget.initial?.place;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Widget _pickerTheme(BuildContext context, Widget? child) => Theme(
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1850),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialEntryMode: DatePickerEntryMode.calendar,
      builder: _pickerTheme,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 6, minute: 0),
      builder: _pickerTheme,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickPlace(String langCode) async {
    final picked = await showModalBottomSheet<BirthPlace>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MandirTheme.backgroundCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PlaceSearchSheet(langCode: langCode),
    );
    if (picked != null) setState(() => _place = picked);
  }

  Future<void> _submit(KundaliStrings s) async {
    final name = _name.text.trim();
    if (name.isEmpty || _date == null || _time == null || _place == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(s.fillAll, style: GoogleFonts.mukta()),
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }
    final birth = DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    final profile = widget.initial?.copyWith(name: name, birthLocal: birth, place: _place) ??
        BirthProfile(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          birthLocal: birth,
          place: _place!,
        );
    await ref.read(kundaliProfilesProvider.notifier).upsert(profile);
    if (!mounted) return;
    if (widget.popOnSave) {
      Navigator.pop(context, profile);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => KundaliResultScreen(profile: profile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langCode = ref.watch(localeProvider).languageCode;
    final s = KundaliStrings(langCode);
    final timeValue = _time == null
        ? null
        : s.time(DateTime(2000, 1, 1, _time!.hour, _time!.minute));

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            KundaliHeader(title: s.birthDetails, subtitle: s.subtitle),
            const SizedBox(height: 20),
            _Label(s.name),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.mukta(fontSize: 17, color: MandirTheme.textDark),
              decoration: InputDecoration(
                hintText: s.nameHint,
                hintStyle: GoogleFonts.mukta(color: MandirTheme.textMuted),
                filled: true,
                fillColor: MandirTheme.cardBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: _border(MandirTheme.cardBorder),
                enabledBorder: _border(MandirTheme.cardBorder),
                focusedBorder: _border(MandirTheme.primarySaffron),
              ),
            ),
            const SizedBox(height: 16),
            _Label(s.birthDate),
            _PickerField(
              icon: Icons.calendar_month_rounded,
              value: _date == null ? null : s.date(_date!),
              placeholder: s.select,
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            _Label(s.birthTime),
            _PickerField(
              icon: Icons.schedule_rounded,
              value: timeValue,
              placeholder: s.select,
              onTap: _pickTime,
            ),
            const SizedBox(height: 6),
            Text(
              s.timeTip,
              style: GoogleFonts.mukta(fontSize: 13, color: MandirTheme.textMuted, height: 1.3),
            ),
            const SizedBox(height: 16),
            _Label(s.birthPlace),
            _PickerField(
              icon: Icons.location_on_rounded,
              value: _place?.label,
              placeholder: s.searchPlace,
              onTap: () => _pickPlace(langCode),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: () => _submit(s),
                style: FilledButton.styleFrom(
                  backgroundColor: MandirTheme.primarySaffron,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  s.showKundali,
                  style: GoogleFonts.mukta(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(
          text,
          style: GoogleFonts.mukta(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: MandirTheme.cardSubtitle,
          ),
        ),
      );
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final IconData icon;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KundaliFlatCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: MandirTheme.primarySaffron, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value ?? placeholder,
              style: GoogleFonts.mukta(
                fontSize: 17,
                fontWeight: value == null ? FontWeight.w500 : FontWeight.w600,
                color: value == null ? MandirTheme.textMuted : MandirTheme.textDark,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: MandirTheme.arrowIcon),
        ],
      ),
    );
  }
}

class _PlaceSearchSheet extends StatefulWidget {
  const _PlaceSearchSheet({required this.langCode});

  final String langCode;

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<BirthPlace> _results = const [];
  bool _loading = false;
  String _query = '';

  late final List<BirthPlace> _popular = [
    for (final c in kPopularPanchangCities)
      if (c.timezoneOffsetHours == 5.5)
        BirthPlace(
          name: c.localizedName(widget.langCode).split(' (').first,
          region: c.stateOrCountry,
          latitude: c.latitude,
          longitude: c.longitude,
          timezone: 'Asia/Kolkata',
        ),
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    setState(() => _query = text.trim());
    if (_query.length < 2) {
      setState(() {
        _results = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final q = _query;
      final found = await KundaliService.searchPlaces(q, widget.langCode);
      if (!mounted || q != _query) return;
      setState(() {
        _results = found;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = KundaliStrings(widget.langCode);
    final searching = _query.length >= 2;
    final items = searching ? _results : _popular;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MandirTheme.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                style: GoogleFonts.mukta(fontSize: 17),
                decoration: InputDecoration(
                  hintText: s.searchPlace,
                  hintStyle: GoogleFonts.mukta(color: MandirTheme.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: MandirTheme.textMuted),
                  filled: true,
                  fillColor: MandirTheme.cardBackground,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: MandirTheme.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: MandirTheme.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: MandirTheme.primarySaffron),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 4),
              child: Row(
                children: [
                  Text(
                    searching ? s.searchResults : s.popularPlaces,
                    style: GoogleFonts.mukta(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: MandirTheme.textMuted,
                    ),
                  ),
                  const Spacer(),
                  if (_loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: MandirTheme.primarySaffron,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: searching && !_loading && items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        s.noPlaceFound,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.mukta(fontSize: 15, color: MandirTheme.textMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: MandirTheme.cardBorder),
                      itemBuilder: (_, i) {
                        final place = items[i];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: MandirTheme.primarySaffron,
                          ),
                          title: Text(
                            place.name,
                            style: GoogleFonts.mukta(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w600,
                              color: MandirTheme.textDark,
                            ),
                          ),
                          subtitle: place.region.isEmpty
                              ? null
                              : Text(
                                  place.region,
                                  style: GoogleFonts.mukta(
                                    fontSize: 13.5,
                                    color: MandirTheme.textMuted,
                                  ),
                                ),
                          onTap: () => Navigator.pop(context, place),
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

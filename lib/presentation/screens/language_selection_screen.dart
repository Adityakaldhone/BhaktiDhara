import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../providers/locale_provider.dart';
import 'dashboard_screen.dart';

/// First-launch language picker. English is preselected; the choice is saved
/// on Continue so this screen is never shown again.
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageOption {
  final String code;
  final String badge;
  final String nativeName;
  final String englishName;

  const _LanguageOption(this.code, this.badge, this.nativeName, this.englishName);
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  static const _languages = [
    _LanguageOption('en', 'EN', 'English', 'English'),
    _LanguageOption('hi', 'HI', 'हिंदी', 'Hindi'),
    _LanguageOption('mr', 'MR', 'मराठी', 'Marathi'),
  ];

  static const _strings = {
    'en': (
      title: 'Select Language',
      subtitle: 'भाषा निवडा  •  भाषा चुनें',
      search: 'Search Languages',
      all: 'All Languages',
      cta: 'Continue',
    ),
    'hi': (
      title: 'भाषा चुनें',
      subtitle: 'Select Language  •  भाषा निवडा',
      search: 'भाषा खोजें',
      all: 'सभी भाषाएँ',
      cta: 'आगे बढ़ें',
    ),
    'mr': (
      title: 'भाषा निवडा',
      subtitle: 'Select Language  •  भाषा चुनें',
      search: 'भाषा शोधा',
      all: 'सर्व भाषा',
      cta: 'पुढे चला',
    ),
  };

  static const _gradient = LinearGradient(
    colors: [MandirTheme.goldenAccent, MandirTheme.primarySaffron],
  );
  static const _accent = MandirTheme.primarySaffron;
  static const _selectedText = MandirTheme.secondaryMaroon;
  static const _textDark = MandirTheme.textDark;
  static const _textMuted = MandirTheme.textMuted;
  static const _border = MandirTheme.cardBorder;

  final _searchController = TextEditingController();
  String _selectedCode = 'en';
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_LanguageOption> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _languages;
    return _languages
        .where((l) =>
            l.nativeName.toLowerCase().contains(q) ||
            l.englishName.toLowerCase().contains(q))
        .toList();
  }

  void _continue() {
    selectAppLanguage(ref, Locale(_selectedCode));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MandirDashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languages = _filtered;
    final s = _strings[_selectedCode]!;

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                s.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.mukta(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: MandirTheme.secondaryMaroon,
                ),
              ),
              Text(
                s.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.mukta(fontSize: 16, color: _textMuted),
              ),
              const SizedBox(height: 24),
              _buildSearchField(s.search),
              const SizedBox(height: 28),
              Text(
                s.all,
                style: GoogleFonts.mukta(fontSize: 16, color: _textMuted),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: languages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, i) => _buildTile(languages[i]),
                ),
              ),
              _buildContinueButton(s.cta),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(String hint) {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _query = v),
      style: GoogleFonts.mukta(fontSize: 16, color: _textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.mukta(fontSize: 16, color: _textMuted),
        prefixIcon: const Icon(Icons.search, color: _accent),
        filled: true,
        fillColor: MandirTheme.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent),
        ),
      ),
    );
  }

  Widget _buildTile(_LanguageOption lang) {
    final selected = lang.code == _selectedCode;

    return GestureDetector(
      onTap: () => setState(() => _selectedCode = lang.code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected
              ? const LinearGradient(
                  colors: [MandirTheme.chipBackground, MandirTheme.cardBackground],
                )
              : null,
          color: selected ? null : MandirTheme.surfaceWhite,
          border: Border.all(
            color: selected ? _accent : _border,
            width: selected ? 1.6 : 1,
          ),
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
            SizedBox(
              width: 40,
              child: Text(
                lang.badge,
                style: GoogleFonts.mukta(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: selected ? _accent : MandirTheme.goldenAccent,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.nativeName,
                    style: GoogleFonts.mukta(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: selected ? _selectedText : _textDark,
                    ),
                  ),
                  Text(
                    lang.englishName,
                    style: GoogleFonts.mukta(fontSize: 15, color: _textMuted),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: _accent, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(String label) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 56,
        decoration: BoxDecoration(
          gradient: _gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _continue,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.mukta(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

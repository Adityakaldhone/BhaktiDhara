import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../data/datasources/jaap_mantra_catalog.dart';
import '../jaap/jaap_colors.dart';
import '../jaap/jaap_strings.dart';
import '../providers/jaap_providers.dart';
import '../providers/locale_provider.dart';
import '../widgets/jaap/jaap_sheets.dart';
import 'jaap_counter_screen.dart';

/// First-time setup: pick a mantra, pick a daily goal, begin. Two choices,
/// both pre-selected, so "Next → Begin" is enough.
class JaapWelcomeScreen extends ConsumerStatefulWidget {
  const JaapWelcomeScreen({super.key});

  @override
  ConsumerState<JaapWelcomeScreen> createState() => _JaapWelcomeScreenState();
}

class _JaapWelcomeScreenState extends ConsumerState<JaapWelcomeScreen> {
  int _step = 0;
  String _mantraId = JaapMantraCatalog.defaultMantraId;
  int _goal = 1;

  Future<void> _finish() async {
    await ref.read(jaapProvider.notifier).completeOnboarding(
          mantraId: _mantraId,
          dailyGoalMalas: _goal,
        );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const JaapCounterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final s = JaapStrings(lang);

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step = 0);
      },
      child: Scaffold(
        backgroundColor: JaapColors.sandalStart,
        appBar: AppBar(
          backgroundColor: JaapColors.sandalStart,
          leading: IconButton(
            iconSize: 30,
            tooltip: s.back,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (_step == 1) {
                setState(() => _step = 0);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(s.title),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  children: [
                    Text(
                      s.welcomeTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.yatraOne(
                        fontSize: 28,
                        color: MandirTheme.secondaryMaroon,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _step == 0 ? s.welcomeSubtitle : s.dailyGoalQuestion,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.mukta(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: MandirTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _step == 0 ? _buildMantraStep(lang) : _buildGoalStep(s, lang),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _step == 0
                        ? () => setState(() => _step = 1)
                        : _finish,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      _step == 0 ? s.next : s.start,
                      style: GoogleFonts.mukta(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMantraStep(String lang) {
    return ListView.separated(
      key: const ValueKey('mantra-step'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: JaapMantraCatalog.all.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final mantra = JaapMantraCatalog.all[i];
        return JaapMantraTile(
          mantra: mantra,
          langCode: lang,
          selected: mantra.id == _mantraId,
          onTap: () => setState(() => _mantraId = mantra.id),
        );
      },
    );
  }

  Widget _buildGoalStep(JaapStrings s, String lang) {
    final mantra = JaapMantraCatalog.byId(_mantraId);
    return SingleChildScrollView(
      key: const ValueKey('goal-step'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Text(
            mantra.devanagari,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 22,
              height: 1.5,
              fontWeight: FontWeight.w700,
              color: JaapColors.mantraMaroon,
            ),
          ),
          const SizedBox(height: 24),
          JaapGoalSelector(
            selected: _goal,
            langCode: lang,
            onSelected: (g) => setState(() => _goal = g),
          ),
          const SizedBox(height: 20),
          Text(
            s.goalHint,
            textAlign: TextAlign.center,
            style: GoogleFonts.mukta(
              fontSize: 17,
              color: MandirTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

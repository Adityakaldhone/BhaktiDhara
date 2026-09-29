import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/theme/theme.dart';
import '../../domain/entities/aarti_item.dart';
import '../../l10n/app_localizations.dart';
import '../../services/backend_service.dart';
import '../providers/bhajan_providers.dart';
import '../providers/locale_provider.dart';
import 'altar_screen.dart';

/// Dedicated screen for Hindu Bhajans and Kirtans.
///
/// Features rich deity categories, search (text & voice),
/// and opens [AltarScreen] for lyrics synchronization and playback.
class BhajanScreen extends ConsumerStatefulWidget {
  const BhajanScreen({super.key});

  @override
  ConsumerState<BhajanScreen> createState() => _BhajanScreenState();
}

class _BhajanScreenState extends ConsumerState<BhajanScreen> {
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  final List<_BhajanCategoryItem> _categories = const [
    _BhajanCategoryItem(id: 'All', labelMr: 'सर्व', labelHi: 'सभी', labelEn: 'All', emoji: '🕉️'),
    _BhajanCategoryItem(id: 'Lord Krishna', labelMr: 'श्री कृष्ण', labelHi: 'श्री कृष्ण', labelEn: 'Krishna', emoji: '🦚'),
    _BhajanCategoryItem(id: 'Lord Rama', labelMr: 'श्री राम', labelHi: 'श्री राम', labelEn: 'Ram', emoji: '🏹'),
    _BhajanCategoryItem(id: 'Lord Shiva', labelMr: 'महादेव', labelHi: 'शिव जी', labelEn: 'Shiva', emoji: '🔱'),
    _BhajanCategoryItem(id: 'Lord Vitthal', labelMr: 'विठ्ठल', labelHi: 'विट्ठल', labelEn: 'Vitthal', emoji: '🙏'),
    _BhajanCategoryItem(id: 'Goddess Durga', labelMr: 'माताजी', labelHi: 'दुर्गा माँ', labelEn: 'Durga', emoji: '🌺'),
    _BhajanCategoryItem(id: 'Lord Ganesha', labelMr: 'गणपती', labelHi: 'गणेश जी', labelEn: 'Ganesha', emoji: '🐘'),
    _BhajanCategoryItem(id: 'Kirtan', labelMr: 'कीर्तन व धुन', labelHi: 'कीर्तन व धुन', labelEn: 'Kirtan', emoji: '🪘'),
  ];

  @override
  void initState() {
    super.initState();
    BackendService.trackEvent('bhajan_open');
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (err) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'notListening' && mounted) {
            setState(() => _isListening = false);
          }
        },
      );
    } catch (_) {
      _speechEnabled = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  void _openBhajan(AartiItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AartiAltarScreen(aarti: item),
      ),
    );
  }

  void _startVoiceSearch() async {
    if (!_speechEnabled) {
      _initSpeech();
      return;
    }

    final localeCode = ref.read(localeProvider).languageCode;
    final String speechLocaleId = switch (localeCode) {
      'mr' => 'mr_IN',
      'hi' => 'hi_IN',
      _ => 'en_IN',
    };

    String recognizedQuery = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: MandirTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (!_isListening) {
              _isListening = true;
              _speechToText.listen(
                onResult: (result) {
                  setModalState(() {
                    recognizedQuery = result.recognizedWords;
                  });
                  if (result.finalResult && recognizedQuery.trim().isNotEmpty) {
                    _applyVoiceQuery(recognizedQuery);
                    if (modalContext.mounted && Navigator.of(modalContext).canPop()) {
                      Navigator.of(modalContext).pop();
                    }
                  }
                },
                listenOptions: stt.SpeechListenOptions(
                  localeId: speechLocaleId,
                ),
              );
            }

            final l10n = AppLocalizations.of(context)!;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Icon(
                      Icons.mic_rounded,
                      size: 52,
                      color: MandirTheme.primarySaffron,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      recognizedQuery.isEmpty ? l10n.listening : recognizedQuery,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.mukta(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: MandirTheme.secondaryMaroon,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.speakNow,
                      style: GoogleFonts.mukta(
                        fontSize: 15,
                        color: MandirTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() async {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      if (mounted) setState(() => _isListening = false);
    });
  }

  void _applyVoiceQuery(String query) {
    final clean = query.trim();
    if (clean.isNotEmpty) {
      _searchController.text = clean;
      ref.read(bhajanSearchQueryProvider.notifier).state = clean;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bhajans = ref.watch(filteredBhajanCatalogProvider);
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeProvider).languageCode;
    final selectedCategory = ref.watch(selectedBhajanCategoryProvider);
    final query = ref.watch(bhajanSearchQueryProvider);

    return SafeArea(
      child: Column(
        children: [
          // ── Header Bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.bhajanSangrah,
                        style: GoogleFonts.mukta(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: MandirTheme.textDark,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.bhajanSubtitle,
                        style: GoogleFonts.mukta(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: MandirTheme.textMuted,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildLanguageDropdown(localeCode, l10n),
              ],
            ),
          ),

          // ── Search Bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: MandirTheme.cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(bhajanSearchQueryProvider.notifier).state = val;
                },
                decoration: InputDecoration(
                  hintText: l10n.bhajanSearchHint,
                  hintStyle: GoogleFonts.mukta(
                    fontSize: 15,
                    color: MandirTheme.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: MandirTheme.primarySaffron,
                    size: 22,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20, color: MandirTheme.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(bhajanSearchQueryProvider.notifier).state = '';
                            setState(() {});
                          },
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.mic_none_rounded,
                          color: MandirTheme.primarySaffron,
                          size: 22,
                        ),
                        onPressed: _startVoiceSearch,
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // ── Category Filter Chips ────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, i) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = selectedCategory == cat.id;
                final label = cat.getLocalizedLabel(localeCode);

                return GestureDetector(
                  onTap: () {
                    ref.read(selectedBhajanCategoryProvider.notifier).state = cat.id;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? MandirTheme.primarySaffron : MandirTheme.chipBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? MandirTheme.primarySaffron : MandirTheme.chipBorder,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: MandirTheme.primarySaffron.withValues(alpha: 0.28),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: GoogleFonts.mukta(
                            fontSize: 14.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : MandirTheme.chipText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // ── Bhajan List ──────────────────────────────────────────
          Expanded(
            child: bhajans.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.library_music_outlined,
                            size: 60,
                            color: MandirTheme.cardBorder,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noBhajanFound,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.mukta(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: MandirTheme.textDark,
                            ),
                          ),
                          if (query.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                ref.read(bhajanSearchQueryProvider.notifier).state = '';
                                ref.read(selectedBhajanCategoryProvider.notifier).state = 'All';
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear, size: 18),
                              label: Text(l10n.clearSearch),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MandirTheme.primarySaffron,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: bhajans.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildBhajanCard(bhajans[index], l10n, localeCode);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BHAJAN CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBhajanCard(
    AartiItem item,
    AppLocalizations l10n,
    String localeCode,
  ) {
    final localizedTitle = item.localizedTitle(localeCode);
    final englishTitle = item.title;

    return Container(
      decoration: BoxDecoration(
        color: MandirTheme.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: MandirTheme.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A5A2B).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _openBhajan(item),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Right decorative mandala
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: Opacity(
                    opacity: 0.22,
                    child: Image.asset(
                      'assets/decorations/card_right_design.png',
                      width: 170,
                      height: 170,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Card content
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Artwork Container
                      Container(
                        width: 125,
                        height: 135,
                        decoration: BoxDecoration(
                          color: MandirTheme.imageSurface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              MandirTheme.getDeityImageAsset(item.deity),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    item.deityEmoji,
                                    style: const TextStyle(fontSize: 40),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Details Area
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Devanagari Title
                              Text(
                                localizedTitle,
                                style: GoogleFonts.notoSansDevanagari(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: MandirTheme.cardTitle,
                                  height: 1.15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              // English Subtitle
                              Text(
                                englishTitle,
                                style: GoogleFonts.notoSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: MandirTheme.cardSubtitle,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 5),

                              // Singer
                              Row(
                                children: [
                                  const Icon(
                                    Icons.mic_rounded,
                                    size: 14,
                                    color: MandirTheme.primarySaffron,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.singer,
                                      style: GoogleFonts.mukta(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: MandirTheme.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // Tags
                              Wrap(
                                spacing: 4,
                                runSpacing: 3,
                                children: [
                                  for (final tag in item.tags.take(3))
                                    _buildTag(tag),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Read & Play Button and Arrow
                              Row(
                                children: [
                                  Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: MandirTheme.cardPrimaryButton,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.play_arrow,
                                          color: MandirTheme.cardButtonText,
                                          size: 19,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.readAndPlay,
                                          style: GoogleFonts.notoSans(
                                            color: MandirTheme.cardButtonText,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: MandirTheme.arrowBackground,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.chevron_right,
                                      color: MandirTheme.arrowIcon,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: MandirTheme.tagBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MandirTheme.tagBorder),
      ),
      child: Text(
        tag,
        style: GoogleFonts.mukta(
          color: MandirTheme.tagText,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  LANGUAGE DROPDOWN
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLanguageDropdown(String localeCode, AppLocalizations l10n) {
    final currentLocale = ref.watch(localeProvider);
    final String labelPrefix = localeCode == 'en' ? 'Language' : 'भाषा';
    final String currentLangName = switch (localeCode) {
      'en' => 'English',
      'hi' => 'हिंदी',
      _ => 'मराठी',
    };

    return PopupMenuButton<Locale>(
      tooltip: l10n.navLanguage,
      onSelected: (Locale newLocale) {
        ref.read(localeProvider.notifier).state = newLocale;
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
      ),
      color: MandirTheme.surfaceWhite,
      elevation: 6,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        _buildLanguagePopupItem('मराठी', const Locale('mr'), currentLocale),
        _buildLanguagePopupItem('हिंदी', const Locale('hi'), currentLocale),
        _buildLanguagePopupItem('English', const Locale('en'), currentLocale),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language,
              size: 16,
              color: MandirTheme.primarySaffron,
            ),
            const SizedBox(width: 5),
            Text(
              '$labelPrefix: $currentLangName',
              style: GoogleFonts.mukta(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: MandirTheme.secondaryMaroon,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: MandirTheme.primarySaffron,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<Locale> _buildLanguagePopupItem(
    String label,
    Locale locale,
    Locale currentLocale,
  ) {
    final isSelected = currentLocale.languageCode == locale.languageCode;
    return PopupMenuItem<Locale>(
      value: locale,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? MandirTheme.primarySaffron : MandirTheme.textMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.mukta(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? MandirTheme.secondaryMaroon : MandirTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _BhajanCategoryItem {
  final String id;
  final String labelMr;
  final String labelHi;
  final String labelEn;
  final String emoji;

  const _BhajanCategoryItem({
    required this.id,
    required this.labelMr,
    required this.labelHi,
    required this.labelEn,
    required this.emoji,
  });

  String getLocalizedLabel(String localeCode) {
    return switch (localeCode) {
      'en' => labelEn,
      'hi' => labelHi,
      _ => labelMr,
    };
  }
}

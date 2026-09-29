import '../../core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/aarti_item.dart';
import '../providers/aarti_providers.dart';
import '../providers/locale_provider.dart';
import 'altar_screen.dart';

/// Configuration metadata for deity header presentation.
class _DeityHeaderInfo {
  final String title;
  final String subtitle;
  final String shloka;
  final String imagePath;

  const _DeityHeaderInfo({
    required this.title,
    required this.subtitle,
    required this.shloka,
    required this.imagePath,
  });
}

/// Mediator Screen — Displays aarti collection for a selected deity
/// matching the sacred temple design from reference image.
class DeityAartiListScreen extends ConsumerStatefulWidget {
  final String deity;
  final AartiItem? initialItem;

  const DeityAartiListScreen({
    super.key,
    required this.deity,
    this.initialItem,
  });

  @override
  ConsumerState<DeityAartiListScreen> createState() =>
      _DeityAartiListScreenState();
}

class _DeityAartiListScreenState extends ConsumerState<DeityAartiListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  _DeityHeaderInfo _getHeaderInfo(String deity, String localeCode) {
    switch (deity) {
      case 'Lord Shiva':
        return const _DeityHeaderInfo(
          title: 'भगवान शिव',
          subtitle: 'आरती संग्रह',
          shloka: '''कर्पूरगौरं करुणावतारं
संसारसारं भुजगेन्द्रहारम् ।
सदावसन्तं हृदयारविन्दे
भवं भवानीसहितं नमामि ॥''',
          imagePath: 'assets/decorations/mahadev.png',
        );
      case 'Lord Hanuman':
        return const _DeityHeaderInfo(
          title: 'श्री हनुमान',
          subtitle: 'आरती संग्रह',
          shloka: '''मनोजवं मारुततुल्यवेगं
जितेन्द्रियं बुद्धिमतां वरिष्ठम् ।
वातात्मजं वानरयूथमुख्यं
श्रीरामदूतं शरणं प्रपद्ये ॥''',
          imagePath: 'assets/decorations/hanuman.png',
        );
      case 'Goddess Durga':
        return const _DeityHeaderInfo(
          title: 'माँ दुर्गा',
          subtitle: 'आरती संग्रह',
          shloka: '''सर्वमङ्गलमाङ्गल्ये
शिवे सर्वार्थसाधिके ।
शरण्ये त्र्यम्बके गौरि
नारायणि नमोऽस्तु ते ॥''',
          imagePath: 'assets/decorations/durga.png',
        );
      case 'Goddess Lakshmi':
        return const _DeityHeaderInfo(
          title: 'माँ लक्ष्मी',
          subtitle: 'आरती संग्रह',
          shloka: '''नमस्तेऽस्तु महामाये
श्रीपीठे सुरपूजिते ।
शङ्खचक्रगदाहस्ते
महालक्ष्मि नमोऽस्तु ते ॥''',
          imagePath: 'assets/decorations/lakshmi.png',
        );
      case 'Goddess Santoshi Mata':
        return const _DeityHeaderInfo(
          title: 'संतोषी माता',
          subtitle: 'आरती संग्रह',
          shloka: 'जय देवी श्री देवी संतोषी माते । वंदन भावें माझें तव पदकमलातें ॥',
          imagePath: 'assets/decorations/santoshi_mata.png',
        );
      case 'Lord Vitthal':
        return const _DeityHeaderInfo(
          title: 'श्री विठ्ठल',
          subtitle: 'आरती संग्रह',
          shloka: 'युगे अठ्ठावीस विटेवरी उभा । वामांगी रखुमाई दिसे दिव्य शोभा ॥',
          imagePath: 'assets/decorations/vitthal.png',
        );
      case 'Lord Krishna':
        return const _DeityHeaderInfo(
          title: 'श्री कृष्ण',
          subtitle: 'आरती संग्रह',
          shloka: '''वसुदेवसुतं देवं
कंसचाणूरमर्दनम् ।
देवकीपरमानन्दं
कृष्णं वन्दे जगद्गुरुम् ॥''',
          imagePath: 'assets/decorations/krishna.png',
        );
      case 'Lord Rama':
        return const _DeityHeaderInfo(
          title: 'श्री राम',
          subtitle: 'आरती संग्रह',
          shloka: 'श्रीरामचन्द्र कृपालु भजु मन हरण भवभय दारुणम् ।',
          imagePath: 'assets/decorations/rama.png',
        );
      case 'Lord Datta':
        return const _DeityHeaderInfo(
          title: 'श्री दत्त',
          subtitle: 'आरती संग्रह',
          shloka: 'दिगंबर दिगंबर श्रीपाद वल्लभ दिगंबर ॥',
          imagePath: 'assets/decorations/datta.png',
        );
      case 'Sai Baba':
        return const _DeityHeaderInfo(
          title: 'साई बाबा',
          subtitle: 'आरती संग्रह',
          shloka: 'श्रद्धा सबुरी धरा मनमाहीं । साईनाथ चरणीं सुख पाहीं ॥',
          imagePath: 'assets/decorations/saibaba.png',
        );
      case 'Lord Satyanarayan':
        return const _DeityHeaderInfo(
          title: 'सत्यनारायण',
          subtitle: 'आरती संग्रह',
          shloka: 'जय जय दीनदयाळ सत्यनारायण देवा ।',
          imagePath: 'assets/decorations/vishnu.png',
        );
      case 'Gajanan Maharaj':
        return const _DeityHeaderInfo(
          title: 'गजानन महाराज',
          subtitle: 'आरती संग्रह',
          shloka: 'गण गण गणात बोते गजानन महाराज ॥',
          imagePath: 'assets/decorations/gajanan_maharaj.png',
        );
      case 'Lord Shani':
        return const _DeityHeaderInfo(
          title: 'शनि देव',
          subtitle: 'आरती संग्रह',
          shloka: 'नीलांजन समाभासं रविपुत्रं यमाग्रजम् ।',
          imagePath: 'assets/decorations/shani.png',
        );
      case 'Lord Vishnu':
        return const _DeityHeaderInfo(
          title: 'श्री विष्णु',
          subtitle: 'आरती संग्रह',
          shloka: 'शान्ताकारं भुजगशयनं पद्मनाभं सुरेशम् ।',
          imagePath: 'assets/decorations/vishnu.png',
        );
      case 'Lord Khandoba':
        return const _DeityHeaderInfo(
          title: 'श्री खंडोबा',
          subtitle: 'आरती संग्रह',
          shloka: 'येळकोट येळकोट जय मल्हारी । खंडेराया तव भंडारी ॥',
          imagePath: 'assets/decorations/khandoba.png',
        );
      case 'Lord Venkatesh':
        return const _DeityHeaderInfo(
          title: 'श्री व्यंकटेश',
          subtitle: 'आरती संग्रह',
          shloka: 'शेषाचल अवतार तारक तू देवा । व्यंकटेशा श्रीनिवासा ॥',
          imagePath: 'assets/decorations/venkatesh.png',
        );
      case 'Goddess Tulsi':
        return const _DeityHeaderInfo(
          title: 'तुळस',
          subtitle: 'आरती संग्रह',
          shloka: 'जय देवी जय देवी जय तुळसी । निजपत्राहुनि लघुतर त्रिभुवन हे तुळसी ॥',
          imagePath: 'assets/decorations/tulsi.png',
        );
      case 'Sant':
        return const _DeityHeaderInfo(
          title: 'संत परंपरा',
          subtitle: 'आरती संग्रह',
          shloka: 'ज्ञानदेव तुकाराम एकनाथ रामदास ॥',
          imagePath: 'assets/decorations/sant.png',
        );
      case 'Lord Ganesha':
        return const _DeityHeaderInfo(
          title: 'श्री गणेश',
          subtitle: 'आरती संग्रह',
          shloka: 'वक्रतुण्ड महाकाय सूर्यकोटि समप्रभ । निर्विघ्नं कुरु मे देव सर्वकार्येषु सर्वदा ॥',
          imagePath: 'assets/decorations/ganesh.png',
        );
      default:
        return _DeityHeaderInfo(
          title: deity,
          subtitle: 'आरती संग्रह',
          shloka: 'ॐ',
          imagePath: MandirTheme.getDeityImageAsset(deity),
        );
    }
  }

  void _openAltar(AartiItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AartiAltarScreen(aarti: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(aartiCatalogProvider);
    final localeCode = ref.watch(localeProvider).languageCode;
    final headerInfo = _getHeaderInfo(widget.deity, localeCode);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F4E8),
      body: Stack(
        children: [
          // ── 1. Sacred Temple Background ────────────────────────────────
          Positioned.fill(
            child: Image.asset('assets/aarti_screen/bg.png', fit: BoxFit.cover),
          ),

          // ── 2. Scrollable Body Content ─────────────────────────────────
          SafeArea(
            bottom: false,
            child: catalogAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B1D18)),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'त्रुटी आढळली',
                  style: GoogleFonts.mukta(
                    fontSize: 16,
                    color: const Color(0xFF8B1D18),
                  ),
                ),
              ),
              data: (allAartis) {
                // Filter items for this deity
                final deityAartis = allAartis.where((item) {
                  return item.deity == widget.deity;
                }).toList();

                // Apply local search filtering
                final filteredList = deityAartis.where((item) {
                  if (_searchQuery.trim().isEmpty) return true;
                  return matchAartiSearch(item, _searchQuery);
                }).toList();

                return Column(
                  children: [
                    // Top Navigation Bar (Back Button + Om)
                    _buildTopBar(),

                    // Deity Header (Ganesha + Shree Ganesh + Shloka Card)
                    _buildDeityHeader(headerInfo),

                    const SizedBox(height: 10),

                    // Search Bar
                    _buildSearchBar(),
                    const SizedBox(height: 10),

                    // Aarti Cards Scrollable List
                    Expanded(
                      child: filteredList.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                4,
                                16,
                                110,
                              ),
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                return _buildAartiCard(
                                  filteredList[index],
                                  localeCode,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── 3. Fixed Bottom Lotus & Gold Bar Overlay ──────────────────
          // The user specifically requested these two flowers and divider
          // to be displayed fixed above the bottom of the card list.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: SizedBox(
                height: 85,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Center Decorative Horizontal Bar
                    Positioned(
                      bottom: 8,
                      left: 60,
                      right: 60,
                      child: Image.asset(
                        'assets/decorations/horizontal_bar_trimmed.png',
                        height: 14,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Left Pink Lotus Flower
                    Positioned(
                      left: -2,
                      bottom: -4,
                      child: Image.asset(
                        'assets/aarti_list/left_lotus.png',
                        height: 82,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Right Pink Lotus Flower
                    Positioned(
                      right: -2,
                      bottom: -4,
                      child: Image.asset(
                        'assets/aarti_list/right_lotus.png',
                        height: 82,
                        fit: BoxFit.contain,
                      ),
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
  // TOP BAR (Enlarged Back Button + assets/aarti_screen/om.png)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: SizedBox(
        height: 75,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Om Image (assets/aarti_screen/om.png)
            Image.asset(
              'assets/aarti_screen/om.png',
              width: 150,
              height: 60,
              fit: BoxFit.contain,
            ),

            // Left Back Button (enlarged for easy tapping)
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Image.asset(
                  'assets/aarti_screen/back_button.png',
                  width: 75,
                  height: 75,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEITY HEADER (Sitting Ganesh + Title + Aarti Sangrah + Shloka Card)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDeityHeader(_DeityHeaderInfo info) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Deity Portrait
          Expanded(
            flex: 5,
            child: Center(
              child: Image.asset(
                info.imagePath,
                height: 155,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Image.asset(
                  'assets/aarti_screen/om.png',
                  height: 155,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Right: Title, Subtitle, and Shloka Box
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title (e.g. श्री गणेश)
                Text(
                  info.title,
                  style: GoogleFonts.mukta(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7A0C08),
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 2),

                // Subtitle (— आरती संग्रह —)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '— ',
                      style: TextStyle(
                        color: Color(0xFF9E7B5A),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      info.subtitle,
                      style: GoogleFonts.mukta(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8B2B1B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Text(
                      ' —',
                      style: TextStyle(
                        color: Color(0xFF9E7B5A),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Ornate Shloka Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF2).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8A5A2B).withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    info.shloka,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mukta(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5A2010),
                      height: 1.35,
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
  // SEARCH BAR (Uses search_bar_bg.png, shifted search icon, removed filter icon)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/aarti_list/search_bar_bg.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 54, right: 30),
        child: Row(
          children: [
            // Search Icon shifted to right so it doesn't overlap the left gold flourish
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF8B1D18),
              size: 24,
            ),

            const SizedBox(width: 10),

            // Search Text Field
            Expanded(
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.mukta(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5A2010),
                ),
                decoration: InputDecoration(
                  hintText: 'आरती शोधा...',
                  hintStyle: GoogleFonts.mukta(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9E7B5A),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),

            // Clear Icon (only shown when search query is typed, filter icon removed)
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Icon(
                  Icons.clear_rounded,
                  color: Color(0xFF8B1D18),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AARTI CARD (Shifted right and reduced mandala size to avoid corner overlap)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAartiCard(AartiItem item, String localeCode) {
    final displayTitle = (localeCode == 'hi' && item.titleHi.isNotEmpty)
        ? item.titleHi
        : (item.titleMr.isNotEmpty ? item.titleMr : item.title);

    final displayAbout = (localeCode == 'hi' && item.aboutHi.isNotEmpty)
        ? item.aboutHi
        : (item.aboutMr.isNotEmpty
              ? item.aboutMr
              : item.localizedAbout(localeCode));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 88,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/aarti_list/aarti_list_card_bg.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openAltar(item),
          child: Padding(
            // Shifted right to 26px to clear left gold corner flourish
            padding: const EdgeInsets.fromLTRB(26, 8, 16, 8),
            child: Row(
              children: [
                // Mandala Thumbnail: reduced to 50x50 and shifted right
                // ClipRRect(
                //   borderRadius: BorderRadius.circular(10),
                //   child: SizedBox(
                //     width: 50,
                //     height: 50,
                //     child: Image.asset(
                //       'assets/aarti_list/mandala_thumb.png',
                //       fit: BoxFit.cover,
                //     ),
                //   ),
                // ),
                const SizedBox(width: 14),

                // Title and Subtitle
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        style: GoogleFonts.mukta(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B1D18),
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        displayAbout,
                        style: GoogleFonts.mukta(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF7A5835),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8B1D18),
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPTY SEARCH STATE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Color(0xFFB8860B),
            ),
            const SizedBox(height: 10),
            Text(
              'कोणतीही आरती आढळली नाही',
              style: GoogleFonts.mukta(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7A0C08),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'कृपया वेगळा शब्द किंवा नाव शोधून पहा.',
              style: GoogleFonts.mukta(
                fontSize: 13,
                color: const Color(0xFF7A5835),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

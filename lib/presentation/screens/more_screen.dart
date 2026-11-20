import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/app_remote_config.dart';
import '../../domain/entities/bhakti_deity.dart';
import '../../domain/logic/ishta_devta.dart';
import '../../l10n/app_localizations.dart';
import '../../services/backend_service.dart';
import '../providers/aarti_providers.dart';
import '../providers/nitya_onboarding_providers.dart';
import '../providers/remote_config_provider.dart';
import '../widgets/nitya_pin_sheet.dart';
import 'calendar/calendar_screen.dart';
import 'deity_aarti_list_screen.dart';
import 'grahan_screen.dart';
import 'granth_catalog_screen.dart';
import 'ishta_devta_screen.dart';
import 'kundali_screen.dart';
import 'milan_screen.dart';

/// Redesigned More Tab — Sacred Devotee Hub
/// Features:
/// - Ishta Devta Hero styled with the App's Bhagwa Saffron, Maroon & Gold Mandir Theme
/// - Clean Bento cards for Daily Practice and Vedic Astrology
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  void _openDeityView(BuildContext context, WidgetRef ref, BhaktiDeity deity) {
    final catalog = ref.read(aartiCatalogProvider).valueOrNull ?? const [];
    final hasAarti = catalog.any((i) => deity.matches(i.deity));
    if (hasAarti) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeityAartiListScreen(deity: deity.key),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const IshtaDevtaScreen(changing: true),
        ),
      );
    }
  }

  void _openIshtaPicker(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const IshtaDevtaScreen(changing: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final showGranth = ref.watch(featureEnabledProvider(AppRemoteConfig.granth));
    final lang = Localizations.localeOf(context).languageCode;
    final ishtaKey = ref.watch(ishtaDevtaProvider);
    final deity = ishtaOrDefault(ishtaKey);
    final version = ref.watch(appVersionProvider).valueOrNull;

    // In English, display classical Narasimha Devta if Narsingh is selected,
    // otherwise the deity's localized name.
    final deityDisplayName = (lang == 'en' && deity.key == 'Narsingh Devta')
        ? 'Narasimha\nDevta'
        : deity.localizedName(lang);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Screen Title
            Text(
              l10n.navMore,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E1E1E),
                letterSpacing: -0.6,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 18),

            // Top Hero Card: Ishta Devta in App's Saffron/Maroon/Gold theme
            _IshtaDevtaHeroCard(
              key: const Key('more-ishta-devta'),
              deity: deity,
              displayName: deityDisplayName,
              lang: lang,
              onCardTap: () => _openIshtaPicker(context),
              onViewTap: () => _openDeityView(context, ref, deity),
            ),

            const SizedBox(height: 24),

            // Section: Daily Practice
            Text(
              switch (lang) {
                'mr' => 'नित्य साधना',
                'hi' => 'दैनिक साधना',
                _ => 'Daily practice',
              },
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E1E1E),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),

            // Aarti Reminders Tile
            _AartiRemindersCard(
              key: const Key('more-aarti-reminders'),
              lang: lang,
              onTap: () => showAartiReminderSettingsSheet(context),
            ),

            const SizedBox(height: 12),

            // Side-by-Side: Panchang Calendar & Granth
            Row(
              children: [
                Expanded(
                  child: _BentoActionCard(
                    key: const Key('more-panchang'),
                    iconBoxBg: const Color(0xFFE2EDE7),
                    iconColor: const Color(0xFF2F5C48),
                    icon: Icons.calendar_month_outlined,
                    title: switch (lang) {
                      'mr' => 'पंचांग कॅलेंडर',
                      'hi' => 'पंचांग कैलेंडर',
                      _ => 'Panchang Calendar',
                    },
                    subtitle: switch (lang) {
                      'mr' => 'तिथी, सण व नक्षत्र',
                      'hi' => 'तिथि, त्योहार व नक्षत्र',
                      _ => 'Tithi, festivals & nakshatra',
                    },
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                    ),
                  ),
                ),
                if (showGranth) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BentoActionCard(
                      key: const Key('more-granth'),
                      iconBoxBg: const Color(0xFFF2EBDC),
                      iconColor: const Color(0xFF614E2D),
                      icon: Icons.menu_book_rounded,
                      title: l10n.navGranth,
                      subtitle: switch (lang) {
                        'mr' => 'गीता, पुराणे व पवित्र ग्रंथ',
                        'hi' => 'गीता, पुराण व पवित्र ग्रंथ',
                        _ => 'Gita, Puranas & scriptures',
                      },
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GranthCatalogScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // Section: Vedic Astrology
            Text(
              switch (lang) {
                'mr' => 'वैदिक ज्योतिष',
                'hi' => 'वैदिक ज्योतिष',
                _ => 'Vedic astrology',
              },
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E1E1E),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),

            // Grouped Astrology Card Container
            Material(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFEFECE5), width: 1.2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _AstrologyListTile(
                    key: const Key('more-kundali'),
                    iconWidget: const CustomPaint(
                      size: Size(22, 22),
                      painter: _KundaliIconPainter(color: Color(0xFF3D566C)),
                    ),
                    iconBoxBg: const Color(0xFFE8EDF2),
                    title: switch (lang) {
                      'mr' => 'कुंडली',
                      'hi' => 'कुंडली चार्ट',
                      _ => 'Kundali Chart',
                    },
                    subtitle: switch (lang) {
                      'mr' => 'वैदिक जन्मपत्रिका',
                      'hi' => 'वैदिक जन्म पत्रिका',
                      _ => 'Vedic birth chart',
                    },
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const KundaliScreen()),
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 72,
                    endIndent: 16,
                    color: Color(0xFFF2EFE9),
                  ),
                  _AstrologyListTile(
                    key: const Key('more-milan'),
                    iconWidget: const CustomPaint(
                      size: Size(22, 22),
                      painter: _MilanIconPainter(color: Color(0xFF85646D)),
                    ),
                    iconBoxBg: const Color(0xFFF9E8EC),
                    title: switch (lang) {
                      'mr' => 'कुंडली मिलन',
                      'hi' => 'कुंडली मिलान',
                      _ => 'Kundali Milan',
                    },
                    subtitle: switch (lang) {
                      'mr' => '३६ गुण मिलन व मंगळ दोष',
                      'hi' => '३६ गुण मिलान व मांगलिक दोष',
                      _ => '36-guna matching & Manglik check',
                    },
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MilanScreen()),
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 72,
                    endIndent: 16,
                    color: Color(0xFFF2EFE9),
                  ),
                  _AstrologyListTile(
                    key: const Key('more-grahan'),
                    iconWidget: const CustomPaint(
                      size: Size(22, 22),
                      painter: _GrahanIconPainter(color: Color(0xFF605275)),
                    ),
                    iconBoxBg: const Color(0xFFECE7F4),
                    title: switch (lang) {
                      'mr' => 'ग्रहण',
                      'hi' => 'ग्रहण',
                      _ => 'Grahan (Eclipses)',
                    },
                    subtitle: switch (lang) {
                      'mr' => 'सूर्य व चंद्र ग्रहण, सुतक व आठवण',
                      'hi' => 'सूर्य व चंद्र ग्रहण, सूतक व रिमाइंडर',
                      _ => 'Solar & lunar eclipses, sutak & reminders',
                    },
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GrahanScreen()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            _FeedbackCard(lang: lang),

            if (version != null && version.isNotEmpty) ...[
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'v$version',
                  key: const Key('more-app-version'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9E9D98),
                  ),
                ),
              ),
            ],
          ],
          ),
        ),
      ),
    );
  }
}

/// Feedback / suggestion / deity-request note above the version footer.
class _FeedbackCard extends StatefulWidget {
  const _FeedbackCard({required this.lang});

  final String lang;

  static const int maxChars = 1000;

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _title => switch (widget.lang) {
        'hi' => 'अपनी समस्या बताएं / सुझाव दें',
        'en' => 'Share feedback or a request',
        _ => 'आपल्या समस्या सांगा / सूचना द्या',
      };

  String get _hint => switch (widget.lang) {
        'hi' =>
          'समस्या, सुझाव, या कोई आराध्य देव जोड़ने का अनुरोध लिखें…',
        'en' =>
          'Tell us a problem, suggestion, or request to add a deity…',
        _ =>
          'समस्या, सूचना किंवा आराध्या दैवत जोडण्यासाठी विनंती लिहा…',
      };

  String get _submitLabel => switch (widget.lang) {
        'hi' => 'भेजें',
        'en' => 'Submit',
        _ => 'पाठवा',
      };

  String get _success => switch (widget.lang) {
        'hi' => 'धन्यवाद! आपका संदेश मिल गया।',
        'en' => 'Thank you! Your message was sent.',
        _ => 'धन्यवाद! तुमचा संदेश मिळाला.',
      };

  String get _failed => switch (widget.lang) {
        'hi' => 'भेज नहीं सके। फिर कोशिश करें।',
        'en' => 'Could not send. Please try again.',
        _ => 'पाठवता आले नाही. पुन्हा प्रयत्न करा.',
      };

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;
    if (text.length > _FeedbackCard.maxChars) return;

    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await BackendService.submitFeedback(message: text, lang: widget.lang);
      if (!mounted) return;
      _controller.clear();
      setState(() {});
      messenger.showSnackBar(
        SnackBar(
          content: Text(_success),
          behavior: SnackBarBehavior.floating,
          backgroundColor: MandirTheme.secondaryMaroon,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(_failed),
          behavior: SnackBarBehavior.floating,
          backgroundColor: MandirTheme.secondaryMaroon,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final length = _controller.text.characters.length;
    final canSubmit =
        !_submitting && length > 0 && length <= _FeedbackCard.maxChars;

    return Material(
      key: const Key('more-feedback'),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFEFECE5), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              switch (widget.lang) {
                'hi' =>
                  'समस्या बताएं, सुझाव दें, या आराध्य देव जोड़ने का अनुरोध करें।',
                'en' =>
                  'Share a problem, suggestion, or request to add a deity.',
                _ =>
                  'समस्या सांगा, सूचना द्या, किंवा आराध्या दैवत जोडण्यासाठी विनंती करा.',
              },
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7D7A75),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('more-feedback-input'),
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              maxLength: _FeedbackCard.maxChars,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E1E1E),
                height: 1.35,
              ),
              decoration: InputDecoration(
                hintText: _hint,
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFFB5B3AC),
                ),
                filled: true,
                fillColor: const Color(0xFFFBF9F4),
                counterStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: length > _FeedbackCard.maxChars
                      ? const Color(0xFFB3261E)
                      : const Color(0xFF9E9D98),
                ),
                contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE8E4DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE8E4DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: MandirTheme.goldenAccent,
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                key: const Key('more-feedback-submit'),
                onPressed: canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MandirTheme.secondaryMaroon,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE8E4DB),
                  disabledForegroundColor: const Color(0xFF9E9D98),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _submitLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ishta Devta Hero Card — Saffron & Maroon Mandir Theme
// ─────────────────────────────────────────────────────────────────────────────
class _IshtaDevtaHeroCard extends StatelessWidget {
  const _IshtaDevtaHeroCard({
    super.key,
    required this.deity,
    required this.displayName,
    required this.lang,
    required this.onCardTap,
    required this.onViewTap,
  });

  final BhaktiDeity deity;
  final String displayName;
  final String lang;
  final VoidCallback onCardTap;
  final VoidCallback onViewTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 204,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // Rich saffron/maroon glow
          BoxShadow(
            color: const Color(0xFF8B2500).withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 9),
            spreadRadius: -2,
          ),
          // Subtle upper rim light
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
        // Sacred App Theme: Deep Bhagwa Saffron -> Royal Mandir Maroon -> Divine Burgundy
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9E2C08), // Sacred Bhagwa Saffron
            Color(0xFF751818), // Royal Temple Maroon
            Color(0xFF4C0E16), // Deep Burgundy
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCardTap,
          child: Stack(
            children: [
              // 1. Divine Golden Halo / Aura radiating behind the Deity
              Positioned(
                right: -15,
                top: -10,
                bottom: -10,
                width: 215,
                child: Center(
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFD54F).withValues(alpha: 0.32),
                          const Color(0xFFFF9800).withValues(alpha: 0.16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Deity transparent cutout on the right
              Positioned(
                right: 2,
                top: 0,
                bottom: 0,
                width: 185,
                child: Image.asset(
                  deity.imageAsset,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),

              // 3. Left content: Overline, Deity Name, and Pill Button
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 160, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            switch (lang) {
                              'mr' => 'इष्ट दैवत',
                              'hi' => 'इष्ट देव',
                              _ => 'ISHTA DEVTA',
                            },
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                              color: const Color(0xFFFFD574),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onViewTap,
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                                width: 1.1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  switch (lang) {
                                    'mr' => 'दर्शन करा',
                                    'hi' => 'दर्शन करें',
                                    _ => 'View deity',
                                  },
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.arrow_outward_rounded,
                                  size: 15,
                                  color: Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aarti Reminders Card
// ─────────────────────────────────────────────────────────────────────────────
class _AartiRemindersCard extends StatelessWidget {
  const _AartiRemindersCard({
    super.key,
    required this.lang,
    required this.onTap,
  });

  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFEFECE5), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE7D7),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const CustomPaint(
                  size: Size(24, 24),
                  painter: _DiyaIconPainter(color: Color(0xFF853B20)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      switch (lang) {
                        'mr' => 'आरती आठवण',
                        'hi' => 'आरती रिमाइंडर',
                        _ => 'Aarti Reminders',
                      },
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _ReminderPill(
                          label: switch (lang) {
                            'mr' => 'काकड 6:00 AM',
                            'hi' => 'काकड़ 6:00 AM',
                            _ => 'Kakad 6:00 AM',
                          },
                        ),
                        _ReminderPill(
                          label: switch (lang) {
                            'mr' => 'संध्या 6:30 PM',
                            'hi' => 'संध्या 6:30 PM',
                            _ => 'Sandhya 6:30 PM',
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB5B3AC),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderPill extends StatelessWidget {
  const _ReminderPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF4EA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF5F493B),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bento Action Card (Panchang / Granth)
// ─────────────────────────────────────────────────────────────────────────────
class _BentoActionCard extends StatelessWidget {
  const _BentoActionCard({
    super.key,
    required this.iconBoxBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color iconBoxBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFEFECE5), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBoxBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: Color(0xFF9E9D98),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7D7A75),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Astrology List Tile
// ─────────────────────────────────────────────────────────────────────────────
class _AstrologyListTile extends StatelessWidget {
  const _AstrologyListTile({
    super.key,
    required this.iconWidget,
    required this.iconBoxBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget iconWidget;
  final Color iconBoxBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBoxBg,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: iconWidget,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF7D7A75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFB5B3AC),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Icon Painters
// ─────────────────────────────────────────────────────────────────────────────

class _DiyaIconPainter extends CustomPainter {
  final Color color;
  const _DiyaIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Diya bowl
    final bowl = Path()
      ..moveTo(w * 0.12, h * 0.62)
      ..cubicTo(w * 0.20, h * 0.88, w * 0.80, h * 0.88, w * 0.88, h * 0.62)
      ..lineTo(w * 0.12, h * 0.62);
    canvas.drawPath(bowl, strokePaint);

    // Diya flame
    final flame = Path()
      ..moveTo(w * 0.50, h * 0.16)
      ..cubicTo(w * 0.64, h * 0.32, w * 0.62, h * 0.52, w * 0.50, h * 0.55)
      ..cubicTo(w * 0.38, h * 0.52, w * 0.36, h * 0.32, w * 0.50, h * 0.16);
    canvas.drawPath(flame, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _DiyaIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _KundaliIconPainter extends CustomPainter {
  final Color color;
  const _KundaliIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rect = Rect.fromLTWH(
      size.width * 0.12,
      size.height * 0.12,
      size.width * 0.76,
      size.height * 0.76,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2.5)),
      paint,
    );

    // Diagonals
    canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
    canvas.drawLine(rect.topRight, rect.bottomLeft, paint);

    // Inner diamond connecting midpoints
    final diamond = Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.right, rect.center.dy)
      ..lineTo(rect.center.dx, rect.bottom)
      ..lineTo(rect.left, rect.center.dy)
      ..close();
    canvas.drawPath(diamond, paint);
  }

  @override
  bool shouldRepaint(covariant _KundaliIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MilanIconPainter extends CustomPainter {
  final Color color;
  const _MilanIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Two interlocking diamond loops
    final leftDiamond = Path()
      ..moveTo(w * 0.30, h * 0.28)
      ..lineTo(w * 0.46, h * 0.50)
      ..lineTo(w * 0.30, h * 0.72)
      ..lineTo(w * 0.14, h * 0.50)
      ..close();

    final rightDiamond = Path()
      ..moveTo(w * 0.70, h * 0.28)
      ..lineTo(w * 0.86, h * 0.50)
      ..lineTo(w * 0.70, h * 0.72)
      ..lineTo(w * 0.54, h * 0.50)
      ..close();

    canvas.drawPath(leftDiamond, paint);
    canvas.drawPath(rightDiamond, paint);
  }

  @override
  bool shouldRepaint(covariant _MilanIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _GrahanIconPainter extends CustomPainter {
  final Color color;
  const _GrahanIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Crescent moon
    final moon = Path()
      ..moveTo(w * 0.54, h * 0.20)
      ..cubicTo(w * 0.24, h * 0.20, w * 0.18, h * 0.80, w * 0.54, h * 0.80)
      ..cubicTo(w * 0.34, h * 0.70, w * 0.32, h * 0.30, w * 0.54, h * 0.20);
    canvas.drawPath(moon, strokePaint);

    // Eclipse sparkles / stars
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.70, h * 0.34), 1.5, fillPaint);
    canvas.drawCircle(Offset(w * 0.78, h * 0.50), 1.8, fillPaint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.68), 1.4, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _GrahanIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

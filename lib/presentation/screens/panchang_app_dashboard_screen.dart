import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/theme.dart';
import '../providers/locale_provider.dart';
import '../providers/review_provider.dart';
import 'calendar/calendar_screen.dart';
import 'grahan_screen.dart';
import 'horoscope_screen.dart';
import 'kundali_screen.dart';
import 'milan_screen.dart';
import 'panchang_screen.dart';

/// Dedicated root dashboard for the standalone "Sampurna Panchang & Rashifal" app.
class PanchangAppDashboardScreen extends ConsumerStatefulWidget {
  const PanchangAppDashboardScreen({super.key});

  @override
  ConsumerState<PanchangAppDashboardScreen> createState() =>
      _PanchangAppDashboardScreenState();
}

class _PanchangAppDashboardScreenState
    extends ConsumerState<PanchangAppDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PanchangScreen(),
    HoroscopeScreen(),
    CalendarScreen(),
    KundaliScreen(),
    _PanchangMoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final langCode = ref.watch(localeProvider).languageCode;

    final panchangLabel = langCode == 'hi'
        ? 'पंचांग'
        : (langCode == 'mr' ? 'पंचांग' : 'Panchang');
    final rashifalLabel = langCode == 'hi'
        ? 'राशिफल'
        : (langCode == 'mr' ? 'राशीभविष्य' : 'Horoscope');
    final calendarLabel = langCode == 'hi'
        ? 'कैलेंडर'
        : (langCode == 'mr' ? 'दिनदर्शिका' : 'Calendar');
    final kundaliLabel = langCode == 'hi'
        ? 'कुंडली'
        : (langCode == 'mr' ? 'कुंडली' : 'Kundali');
    final moreLabel = langCode == 'hi'
        ? 'अधिक'
        : (langCode == 'mr' ? 'अधिक' : 'More');

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: MandirTheme.surfaceWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = idx);
            },
            backgroundColor: MandirTheme.surfaceWhite,
            indicatorColor: MandirTheme.primarySaffron.withValues(alpha: 0.15),
            elevation: 0,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.wb_sunny_outlined, size: 22),
                selectedIcon: const Icon(Icons.wb_sunny_rounded,
                    color: MandirTheme.primarySaffron, size: 24),
                label: panchangLabel,
              ),
              NavigationDestination(
                icon: const Icon(Icons.stars_outlined, size: 22),
                selectedIcon: const Icon(Icons.stars_rounded,
                    color: MandirTheme.primarySaffron, size: 24),
                label: rashifalLabel,
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined, size: 22),
                selectedIcon: const Icon(Icons.calendar_month_rounded,
                    color: MandirTheme.primarySaffron, size: 24),
                label: calendarLabel,
              ),
              NavigationDestination(
                icon: const Icon(Icons.auto_awesome_outlined, size: 22),
                selectedIcon: const Icon(Icons.auto_awesome_rounded,
                    color: MandirTheme.primarySaffron, size: 24),
                label: kundaliLabel,
              ),
              NavigationDestination(
                icon: const Icon(Icons.more_horiz_rounded, size: 22),
                selectedIcon: const Icon(Icons.more_horiz_rounded,
                    color: MandirTheme.primarySaffron, size: 24),
                label: moreLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extra Vedic Astrology tools and preferences for the standalone app.
class _PanchangMoreScreen extends ConsumerWidget {
  const _PanchangMoreScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = ref.watch(localeProvider).languageCode;

    final title = langCode == 'hi'
        ? 'वैदिक साधन एवं सेटिंग्स'
        : (langCode == 'mr'
            ? 'वैदिक साधने व सेटिंग्ज'
            : 'Vedic Tools & Settings');

    final grahanTitle = langCode == 'hi'
        ? 'सूर्य व चंद्र ग्रहण'
        : (langCode == 'mr' ? 'सूर्य व चंद्र ग्रहण' : 'Solar & Lunar Eclipses');
    final grahanSubtitle = langCode == 'hi'
        ? 'सूतक काल, ग्रहण समय एवं नियम'
        : (langCode == 'mr'
            ? 'सूतक काळ, ग्रहण वेळ व नियम'
            : 'Sutak timing & eclipse guide');

    final milanTitle = langCode == 'hi'
        ? 'कुंडली मिलान (गुणमिलन)'
        : (langCode == 'mr' ? 'विवाह गुणमिलन' : 'Horoscope Matching (Milan)');
    final milanSubtitle = langCode == 'hi'
        ? '३६ गुण मिलान, नाड़ी, भकूट एवं दोष विचार'
        : (langCode == 'mr'
            ? '३६ गुण जुळणी, नाडी, भकूट व दोष'
            : '36 Guna marriage compatibility');

    final languageTitle = langCode == 'hi'
        ? 'भाषा बदलें'
        : (langCode == 'mr' ? 'भाषा बदला' : 'Change Language');

    final shareTitle = langCode == 'hi'
        ? 'ऐप शेयर करें'
        : (langCode == 'mr' ? 'अ‍ॅप शेअर करा' : 'Share App');

    final rateTitle = langCode == 'hi'
        ? 'ऐप को रेटिंग दें'
        : (langCode == 'mr' ? 'अ‍ॅपला रेटिंग द्या' : 'Rate this App');
    final rateSubtitle = langCode == 'hi'
        ? 'Google Play Store पर 5 स्टार रेटिंग देकर सहयोग करें'
        : (langCode == 'mr'
            ? 'गुगल प्ले स्टोअरवर ५ स्टार रेटिंग देऊन सहकार्य करा'
            : 'Support us with a 5-star rating on Play Store');

    final appName = langCode == 'hi'
        ? 'संपूर्ण पंचांग एवं राशिफल'
        : (langCode == 'mr'
            ? 'संपूर्ण पंचांग आणि राशीभविष्य'
            : 'Sampurna Panchang & Rashifal');

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: MandirTheme.surfaceWhite,
        elevation: 0,
        title: Text(
          title,
          style: GoogleFonts.mukta(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: MandirTheme.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // App Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8A2E00), MandirTheme.primarySaffron],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: MandirTheme.primarySaffron.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Center(
                    child: Text('🕉️', style: TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appName,
                        style: GoogleFonts.mukta(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        '100% Authentic Vedic Astrology',
                        style: GoogleFonts.mukta(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tools Section Header
          Text(
            langCode == 'hi'
                ? 'अतिरिक्त ज्योतिष साधन'
                : (langCode == 'mr'
                    ? 'अतिरिक्त ज्योतिष साधने'
                    : 'Additional Astro Tools'),
            style: GoogleFonts.mukta(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MandirTheme.primarySaffron,
            ),
          ),
          const SizedBox(height: 8),

          // Grahan Card
          _SettingsTile(
            icon: Icons.shield_moon_rounded,
            iconBgColor: const Color(0xFF673AB7),
            title: grahanTitle,
            subtitle: grahanSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GrahanScreen()),
              );
            },
          ),
          const SizedBox(height: 10),

          // Guna Milan Card
          _SettingsTile(
            icon: Icons.favorite_rounded,
            iconBgColor: const Color(0xFFE91E63),
            title: milanTitle,
            subtitle: milanSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MilanScreen()),
              );
            },
          ),
          const SizedBox(height: 20),

          // Preferences Header
          Text(
            langCode == 'hi'
                ? 'प्राथमिकताएं'
                : (langCode == 'mr' ? 'प्राधान्ये' : 'Preferences'),
            style: GoogleFonts.mukta(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MandirTheme.primarySaffron,
            ),
          ),
          const SizedBox(height: 8),

          // Language Tile
          _SettingsTile(
            icon: Icons.translate_rounded,
            iconBgColor: const Color(0xFF00897B),
            title: languageTitle,
            subtitle: langCode == 'mr'
                ? 'मराठी'
                : (langCode == 'hi' ? 'हिंदी' : 'English'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: MandirTheme.textMuted),
            onTap: () {
              _showLanguageDialog(context, ref);
            },
          ),
          const SizedBox(height: 10),

          // Share App
          _SettingsTile(
            icon: Icons.share_rounded,
            iconBgColor: const Color(0xFF1E88E5),
            title: shareTitle,
            subtitle: 'Share Sampurna Panchang & Rashifal with family & friends',
            onTap: () {
              SharePlus.instance.share(
                ShareParams(
                  text: 'पहा आजचे संपूर्ण पंचांग, राशीभविष्य, शुभ मुहूर्त व कुंडली एकाच ठिकाणी: https://play.google.com/store/apps/details?id=com.kaldhone.panchang',
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Rate App (In-App Review / Play Store)
          _SettingsTile(
            icon: Icons.star_rate_rounded,
            iconBgColor: const Color(0xFFFF9800),
            title: rateTitle,
            subtitle: rateSubtitle,
            trailing: const Icon(Icons.open_in_new_rounded,
                size: 16, color: MandirTheme.textMuted),
            onTap: () {
              ref
                  .read(reviewServiceProvider)
                  .requestInAppReview(fallbackToStore: true);
            },
          ),

          const SizedBox(height: 28),
          Center(
            child: Text(
              '॥ ॐ श्री गणेशाय नमः • ॐ नमः शिवाय ॥',
              style: GoogleFonts.mukta(
                fontSize: 14,
                color: MandirTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MandirTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Select Language / भाषा निवडा',
          style: GoogleFonts.mukta(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('मराठी (Marathi)'),
              onTap: () {
                selectAppLanguage(ref, const Locale('mr'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('हिंदी (Hindi)'),
              onTap: () {
                selectAppLanguage(ref, const Locale('hi'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('English'),
              onTap: () {
                selectAppLanguage(ref, const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MandirTheme.cardBorder),
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
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconBgColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.mukta(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: MandirTheme.textDark,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.mukta(
                          fontSize: 12,
                          color: MandirTheme.textMuted,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ??
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: MandirTheme.textMuted,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

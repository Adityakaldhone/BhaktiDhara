import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/app_remote_config.dart';
import '../../l10n/app_localizations.dart';
import '../providers/remote_config_provider.dart';
import 'calendar/calendar_screen.dart';
import 'granth_catalog_screen.dart';
import 'grahan_screen.dart';
import 'kundali_screen.dart';
import 'milan_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final showGranth = ref.watch(featureEnabledProvider(AppRemoteConfig.granth));
    final lang = Localizations.localeOf(context).languageCode;
    final calTitle = lang == 'mr'
        ? 'पंचांग कॅलेंडर'
        : lang == 'hi'
            ? 'पंचांग कैलेंडर'
            : 'Panchang Calendar';
    final calSub = lang == 'mr'
        ? 'तिथी, सण, नक्षत्र व शुभ मुहूर्त'
        : lang == 'hi'
            ? 'तिथि, त्योहार, नक्षत्र व शुभ मुहूर्त'
            : 'Tithi, Festivals & Nakshatra';
    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              l10n.navMore,
              style: GoogleFonts.mukta(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: MandirTheme.textDark,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 16),
            _MoreCard(
              icon: Icons.calendar_month_rounded,
              title: calTitle,
              subtitle: calSub,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              ),
            ),
            const SizedBox(height: 12),
            if (showGranth) ...[
              _MoreCard(
                icon: Icons.menu_book_rounded,
                title: l10n.navGranth,
                subtitle: l10n.moreGranthSubtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GranthCatalogScreen()),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _MoreCard(
              icon: Icons.brightness_7_rounded,
              title: l10n.moreKundaliTitle,
              subtitle: l10n.moreKundaliSubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KundaliScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _MoreCard(
              icon: Icons.favorite_rounded,
              title: l10n.moreMilanTitle,
              subtitle: l10n.moreMilanSubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MilanScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _MoreCard(
              icon: Icons.brightness_3_rounded,
              title: l10n.moreGrahanTitle,
              subtitle: l10n.moreGrahanSubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GrahanScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreCard extends StatelessWidget {
  const _MoreCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Material(
      color: MandirTheme.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: MandirTheme.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: MandirTheme.primarySaffron.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: MandirTheme.primarySaffron, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.mukta(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: MandirTheme.cardTitle,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.mukta(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: MandirTheme.cardSubtitle,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: MandirTheme.arrowIcon,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

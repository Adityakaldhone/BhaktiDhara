import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/birth_profile.dart';
import '../kundali/kundali_strings.dart';
import '../providers/kundali_providers.dart';
import '../providers/locale_provider.dart';
import 'kundali_form_screen.dart';
import 'kundali_result_screen.dart';

class KundaliScreen extends ConsumerWidget {
  const KundaliScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = KundaliStrings(ref.watch(localeProvider).languageCode);
    final profiles = ref.watch(kundaliProfilesProvider);

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            KundaliHeader(title: s.title, subtitle: s.subtitle),
            const SizedBox(height: 16),
            KundaliFlatCard(
              color: MandirTheme.primarySaffron,
              borderColor: MandirTheme.primarySaffron,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KundaliFormScreen()),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.newKundali,
                      style: GoogleFonts.mukta(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 26),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              s.savedKundalis,
              style: GoogleFonts.mukta(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: MandirTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            if (profiles == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: MandirTheme.primarySaffron),
                ),
              )
            else if (profiles.isEmpty)
              Text(
                s.emptySaved,
                style: GoogleFonts.mukta(
                  fontSize: 15,
                  color: MandirTheme.textMuted,
                  height: 1.4,
                ),
              )
            else
              for (final p in profiles) ...[
                _ProfileCard(profile: p, s: s),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.profile, required this.s});

  final BirthProfile profile;
  final KundaliStrings s;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MandirTheme.surfaceWhite,
        content: Text(s.deleteConfirm(profile.name), style: GoogleFonts.mukta(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel, style: GoogleFonts.mukta(color: MandirTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.delete,
              style: GoogleFonts.mukta(
                color: MandirTheme.primarySaffron,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(kundaliProfilesProvider.notifier).remove(profile.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KundaliFlatCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => KundaliResultScreen(profile: profile)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: MandirTheme.primarySaffron.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              profile.name.characters.first.toUpperCase(),
              style: GoogleFonts.mukta(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: MandirTheme.primarySaffron,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: GoogleFonts.mukta(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: MandirTheme.cardTitle,
                    height: 1.2,
                  ),
                ),
                Text(
                  '${s.date(profile.birthLocal)} • ${s.time(profile.birthLocal)}',
                  style: GoogleFonts.mukta(fontSize: 13.5, color: MandirTheme.cardSubtitle),
                ),
                Text(
                  profile.place.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.mukta(fontSize: 13.5, color: MandirTheme.textMuted),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: MandirTheme.textMuted),
            color: MandirTheme.surfaceWhite,
            onSelected: (v) {
              if (v == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => KundaliFormScreen(initial: profile)),
                );
              } else {
                _confirmDelete(context, ref);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(s.edit, style: GoogleFonts.mukta())),
              PopupMenuItem(value: 'delete', child: Text(s.delete, style: GoogleFonts.mukta())),
            ],
          ),
        ],
      ),
    );
  }
}

/// Back button + large title used by the Kundali screens.
class KundaliHeader extends StatelessWidget {
  const KundaliHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (Navigator.canPop(context))
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: MandirTheme.textDark,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        Text(
          title,
          style: GoogleFonts.mukta(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: MandirTheme.textDark,
            height: 1.15,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: GoogleFonts.mukta(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: MandirTheme.textMuted,
              height: 1.35,
            ),
          ),
      ],
    );
  }
}

/// Flat (zero-elevation) bordered card used across the Kundali screens.
class KundaliFlatCard extends StatelessWidget {
  const KundaliFlatCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color = MandirTheme.cardBackground,
    this.borderColor = MandirTheme.cardBorder,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

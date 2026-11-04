import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/birth_profile.dart';
import '../../services/kundali/guna_milan.dart';
import '../../services/kundali/kundali_service.dart';
import '../kundali/milan_strings.dart';
import '../providers/kundali_providers.dart';
import '../providers/locale_provider.dart';
import 'kundali_form_screen.dart';
import 'kundali_screen.dart';

const _green = Color(0xFF2E7D32);
const _red = Color(0xFFC62828);
const _amber = Color(0xFFEF6C00);

class MilanScreen extends ConsumerStatefulWidget {
  const MilanScreen({super.key});

  @override
  ConsumerState<MilanScreen> createState() => _MilanScreenState();
}

class _MilanScreenState extends ConsumerState<MilanScreen> {
  String? _boyId;
  String? _girlId;

  Future<void> _choose({required bool groom, required MilanStrings s}) async {
    final profiles = ref.read(kundaliProfilesProvider) ?? const [];
    final picked = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MandirTheme.backgroundCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProfilePickerSheet(
        s: s,
        title: groom ? s.groom : s.bride,
        profiles: profiles,
        selectedId: groom ? _boyId : _girlId,
      ),
    );
    if (!mounted || picked == null) return;

    final profile = picked is BirthProfile
        ? picked
        : await Navigator.push<BirthProfile>(
            context,
            MaterialPageRoute(builder: (_) => const KundaliFormScreen(popOnSave: true)),
          );
    if (profile == null) return;
    setState(() => groom ? _boyId = profile.id : _girlId = profile.id);
  }

  @override
  Widget build(BuildContext context) {
    final s = MilanStrings(ref.watch(localeProvider).languageCode);
    final profiles = ref.watch(kundaliProfilesProvider) ?? const <BirthProfile>[];
    BirthProfile? find(String? id) => profiles.where((p) => p.id == id).firstOrNull;
    final boy = find(_boyId);
    final girl = find(_girlId);
    final samePerson = boy != null && boy.id == girl?.id;
    final result = boy == null || girl == null || samePerson
        ? null
        : GunaMilan.match(
            boy: KundaliService.calculate(boy),
            girl: KundaliService.calculate(girl),
          );

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            KundaliHeader(title: s.title, subtitle: s.subtitle),
            const SizedBox(height: 16),
            _PersonSlot(
              label: s.groom,
              icon: Icons.man_rounded,
              profile: boy,
              s: s,
              onTap: () => _choose(groom: true, s: s),
            ),
            Align(
              child: TextButton.icon(
                onPressed: boy == null && girl == null
                    ? null
                    : () => setState(() {
                          final t = _boyId;
                          _boyId = _girlId;
                          _girlId = t;
                        }),
                icon: const Icon(Icons.swap_vert_rounded, size: 20),
                label: Text(s.swap, style: GoogleFonts.mukta(fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(foregroundColor: MandirTheme.primarySaffron),
              ),
            ),
            _PersonSlot(
              label: s.bride,
              icon: Icons.woman_rounded,
              profile: girl,
              s: s,
              onTap: () => _choose(groom: false, s: s),
            ),
            const SizedBox(height: 20),
            if (result == null)
              Text(
                samePerson ? s.samePerson : s.pickBoth,
                textAlign: TextAlign.center,
                style: GoogleFonts.mukta(
                  fontSize: 15,
                  color: samePerson ? _red : MandirTheme.textMuted,
                  height: 1.4,
                ),
              )
            else ...[
              _ScoreCard(result: result, s: s),
              const SizedBox(height: 22),
              _SectionTitle(s.kootaDetails),
              _KootaCard(result: result, s: s),
              const SizedBox(height: 22),
              _SectionTitle(s.doshas),
              _DoshaCard(result: result, s: s),
              const SizedBox(height: 22),
              _SectionTitle(s.manglik),
              _ManglikCard(result: result, boy: boy!, girl: girl!, s: s),
              const SizedBox(height: 16),
              Text(
                s.disclaimer,
                textAlign: TextAlign.center,
                style: GoogleFonts.mukta(fontSize: 13, color: MandirTheme.textMuted, height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 2),
        child: Text(
          text,
          style: GoogleFonts.mukta(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: MandirTheme.textDark,
          ),
        ),
      );
}

class _PersonSlot extends StatelessWidget {
  const _PersonSlot({
    required this.label,
    required this.icon,
    required this.profile,
    required this.s,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final BirthProfile? profile;
  final MilanStrings s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return KundaliFlatCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: MandirTheme.primarySaffron.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: MandirTheme.primarySaffron, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.mukta(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: MandirTheme.textMuted,
                    height: 1.2,
                  ),
                ),
                Text(
                  p?.name ?? s.choose,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.mukta(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w700,
                    color: p == null ? MandirTheme.primarySaffron : MandirTheme.cardTitle,
                    height: 1.25,
                  ),
                ),
                if (p != null)
                  Text(
                    '${s.fmt.date(p.birthLocal)} • ${s.fmt.time(p.birthLocal)}',
                    style: GoogleFonts.mukta(fontSize: 13, color: MandirTheme.cardSubtitle),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: MandirTheme.arrowIcon, size: 26),
        ],
      ),
    );
  }
}

Color _verdictColor(MilanVerdict v) => switch (v) {
      MilanVerdict.notRecommended => _red,
      MilanVerdict.average => _amber,
      MilanVerdict.good || MilanVerdict.excellent => _green,
    };

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.result, required this.s});

  final MilanResult result;
  final MilanStrings s;

  @override
  Widget build(BuildContext context) {
    final color = _verdictColor(result.verdict);
    return KundaliFlatCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: result.total / 36,
                  strokeWidth: 9,
                  strokeCap: StrokeCap.round,
                  color: color,
                  backgroundColor: MandirTheme.cardBorder,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.score(result.total),
                        style: GoogleFonts.mukta(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: MandirTheme.textDark,
                          height: 1,
                        ),
                      ),
                      Text(
                        '/ ${s.fmt.num(36)}',
                        style: GoogleFonts.mukta(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MandirTheme.textMuted,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.verdict(result.verdict),
                  style: GoogleFonts.mukta(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.2,
                  ),
                ),
                Text(
                  s.outOf36(result.total),
                  style: GoogleFonts.mukta(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: MandirTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.verdictNote(result.verdict),
                  style: GoogleFonts.mukta(
                    fontSize: 13.5,
                    color: MandirTheme.cardSubtitle,
                    height: 1.35,
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

class _KootaCard extends StatelessWidget {
  const _KootaCard({required this.result, required this.s});

  final MilanResult result;
  final MilanStrings s;

  @override
  Widget build(BuildContext context) {
    return KundaliFlatCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final k in result.kootas) ...[
            if (k.koota != Koota.varna)
              const Divider(height: 1, color: MandirTheme.cardBorder),
            _KootaRow(k: k, s: s),
          ],
          const Divider(height: 1, color: MandirTheme.cardBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.gunas,
                    style: GoogleFonts.mukta(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: MandirTheme.textDark,
                    ),
                  ),
                ),
                Text(
                  '${s.score(result.total)} / ${s.fmt.num(36)}',
                  style: GoogleFonts.mukta(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _verdictColor(result.verdict),
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

class _KootaRow extends StatelessWidget {
  const _KootaRow({required this.k, required this.s});

  final KootaResult k;
  final MilanStrings s;

  @override
  Widget build(BuildContext context) {
    final color = k.score == k.max
        ? _green
        : k.score == 0
            ? _red
            : _amber;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: s.kootaName(k.koota),
                        style: GoogleFonts.mukta(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: MandirTheme.cardTitle,
                        ),
                      ),
                      TextSpan(
                        text: '  ${s.kootaMeaning(k.koota)}',
                        style: GoogleFonts.mukta(fontSize: 13, color: MandirTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.groom}: ${s.kootaValue(k.koota, k.boy)}   •   '
                  '${s.bride}: ${s.kootaValue(k.koota, k.girl)}',
                  style: GoogleFonts.mukta(
                    fontSize: 13.5,
                    color: MandirTheme.cardSubtitle,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${s.score(k.score)}/${s.fmt.num(k.max)}',
                  style: GoogleFonts.mukta(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: k.score / k.max,
                    minHeight: 5,
                    color: color,
                    backgroundColor: MandirTheme.cardBorder,
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

class _DoshaCard extends StatelessWidget {
  const _DoshaCard({required this.result, required this.s});

  final MilanResult result;
  final MilanStrings s;

  @override
  Widget build(BuildContext context) {
    final entries = [
      if (result.nadiDosha)
        (s.nadiDosha, s.nadiDoshaNote, result.nadiCancelled, s.nadiCancelledNote),
      if (result.bhakootDosha)
        (s.bhakootDosha, s.bhakootDoshaNote, result.bhakootCancelled, s.bhakootCancelledNote),
    ];
    return KundaliFlatCard(
      child: entries.isEmpty
          ? _StatusLine(icon: Icons.check_circle_rounded, color: _green, text: s.noMajorDosha)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, e) in entries.indexed) ...[
                  if (i > 0) const Divider(height: 24, color: MandirTheme.cardBorder),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.$1,
                          style: GoogleFonts.mukta(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: MandirTheme.cardTitle,
                          ),
                        ),
                      ),
                      _Pill(
                        text: e.$3 ? s.cancelled : s.present,
                        color: e.$3 ? _green : _red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.$2,
                    style: GoogleFonts.mukta(
                      fontSize: 13.5,
                      color: MandirTheme.cardSubtitle,
                      height: 1.35,
                    ),
                  ),
                  if (e.$3) ...[
                    const SizedBox(height: 6),
                    _StatusLine(icon: Icons.verified_rounded, color: _green, text: e.$4),
                  ],
                ],
              ],
            ),
    );
  }
}

class _ManglikCard extends StatelessWidget {
  const _ManglikCard({
    required this.result,
    required this.boy,
    required this.girl,
    required this.s,
  });

  final MilanResult result;
  final BirthProfile boy;
  final BirthProfile girl;
  final MilanStrings s;

  @override
  Widget build(BuildContext context) {
    Widget person(String role, BirthProfile p, ManglikStatus m) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$role • ${p.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.mukta(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MandirTheme.cardTitle,
                    ),
                  ),
                  Text(
                    s.marsHouses(m),
                    style: GoogleFonts.mukta(
                      fontSize: 13,
                      color: MandirTheme.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Pill(
              text: s.manglikStatus(m),
              color: m.fromLagna
                  ? _red
                  : m.fromMoon
                      ? _amber
                      : _green,
            ),
          ],
        );

    return KundaliFlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          person(s.groom, boy, result.boyManglik),
          const Divider(height: 22, color: MandirTheme.cardBorder),
          person(s.bride, girl, result.girlManglik),
          const SizedBox(height: 14),
          _StatusLine(
            icon: result.manglikMatch ? Icons.check_circle_rounded : Icons.info_rounded,
            color: result.manglikMatch ? _green : _amber,
            text: s.manglikVerdict(result),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.mukta(fontSize: 13, fontWeight: FontWeight.w700, color: color),
        ),
      );
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.mukta(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MandirTheme.textDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      );
}

class _ProfilePickerSheet extends StatelessWidget {
  const _ProfilePickerSheet({
    required this.s,
    required this.title,
    required this.profiles,
    required this.selectedId,
  });

  final MilanStrings s;
  final String title;
  final List<BirthProfile> profiles;
  final String? selectedId;

  /// Returned instead of a profile when the user wants to create one.
  static const createNew = 'new';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MandirTheme.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
            child: Text(
              '$title — ${s.choose}',
              style: GoogleFonts.mukta(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: MandirTheme.textDark,
              ),
            ),
          ),
          Expanded(
            child: profiles.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      s.noSaved,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.mukta(fontSize: 15, color: MandirTheme.textMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    itemCount: profiles.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: MandirTheme.cardBorder),
                    itemBuilder: (_, i) {
                      final p = profiles[i];
                      final selected = p.id == selectedId;
                      return ListTile(
                        onTap: () => Navigator.pop(context, p),
                        leading: CircleAvatar(
                          backgroundColor: MandirTheme.primarySaffron.withValues(alpha: 0.1),
                          child: Text(
                            p.name.characters.first.toUpperCase(),
                            style: GoogleFonts.mukta(
                              fontWeight: FontWeight.w700,
                              color: MandirTheme.primarySaffron,
                            ),
                          ),
                        ),
                        title: Text(
                          p.name,
                          style: GoogleFonts.mukta(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: MandirTheme.textDark,
                          ),
                        ),
                        subtitle: Text(
                          '${s.fmt.date(p.birthLocal)} • ${p.place.name}',
                          style: GoogleFonts.mukta(fontSize: 13.5, color: MandirTheme.textMuted),
                        ),
                        trailing: selected
                            ? const Icon(Icons.check_circle_rounded,
                                color: MandirTheme.primarySaffron)
                            : null,
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            child: SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, createNew),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: Text(
                  s.fmt.newKundali,
                  style: GoogleFonts.mukta(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: MandirTheme.primarySaffron,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

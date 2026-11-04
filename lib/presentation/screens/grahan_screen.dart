import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/panchang_city.dart';
import '../../services/grahan/grahan_engine.dart';
import '../../services/push_notification_service.dart';
import '../grahan/grahan_strings.dart';
import '../providers/grahan_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/panchang_provider.dart';
import 'kundali_screen.dart' show KundaliFlatCard, KundaliHeader;
import 'panchang_screen.dart' show PanchangCitySheet;

class GrahanScreen extends ConsumerWidget {
  const GrahanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = ref.watch(localeProvider).languageCode;
    final s = GrahanStrings(langCode);
    final city = ref.watch(selectedPanchangCityProvider);
    final eventsAsync = ref.watch(upcomingGrahanProvider);

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            KundaliHeader(title: s.title, subtitle: s.subtitle),
            const SizedBox(height: 14),
            _CityRow(city: city, langCode: langCode, s: s),
            const SizedBox(height: 20),
            Text(
              s.upcoming,
              style: GoogleFonts.mukta(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: MandirTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            ...eventsAsync.when(
              loading: () => [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: MandirTheme.primarySaffron),
                      const SizedBox(height: 12),
                      Text(s.loading, style: GoogleFonts.mukta(color: MandirTheme.textMuted)),
                    ],
                  ),
                ),
              ],
              error: (_, _) => [
                Text(s.loadError, style: GoogleFonts.mukta(color: MandirTheme.textMuted)),
              ],
              data: (events) {
                final now = DateTime.now().toUtc();
                final upcoming = events
                    .where((e) => (e.mokshaUtc ?? e.greatestUtc).isAfter(now))
                    .toList();
                return [
                  for (var i = 0; i < upcoming.length; i++) ...[
                    _GrahanCard(
                      event: upcoming[i],
                      city: city,
                      s: s,
                      isFirst: i == 0,
                    ),
                    const SizedBox(height: 12),
                  ],
                ];
              },
            ),
            const SizedBox(height: 12),
            _GuidanceCard(s: s),
            const SizedBox(height: 12),
            Text(
              s.accuracyNote,
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(fontSize: 12.5, color: MandirTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({required this.city, required this.langCode, required this.s});

  final PanchangCity city;
  final String langCode;
  final GrahanStrings s;

  @override
  Widget build(BuildContext context) {
    return KundaliFlatCard(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PanchangCitySheet(currentCity: city, langCode: langCode),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: MandirTheme.primarySaffron, size: 22),
          const SizedBox(width: 8),
          Text(s.location, style: GoogleFonts.mukta(fontSize: 15, color: MandirTheme.textMuted)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              city.localizedName(langCode),
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.mukta(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MandirTheme.textDark,
              ),
            ),
          ),
          Text(
            s.change,
            style: GoogleFonts.mukta(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: MandirTheme.primarySaffron,
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: MandirTheme.primarySaffron),
        ],
      ),
    );
  }
}

class _GrahanCard extends ConsumerWidget {
  const _GrahanCard({
    required this.event,
    required this.city,
    required this.s,
    required this.isFirst,
  });

  final GrahanEvent event;
  final PanchangCity city;
  final GrahanStrings s;
  final bool isFirst;

  DateTime _local(DateTime utc) =>
      utc.add(Duration(minutes: (city.timezoneOffsetHours * 60).round()));

  int get _notificationBase => 70000000 + (event.id.hashCode.abs() % 100000000) * 2;

  Future<void> _toggleReminder(BuildContext context, WidgetRef ref, bool enable) async {
    final messenger = ScaffoldMessenger.of(context);
    void say(String text) => messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(text, style: GoogleFonts.mukta()),
        behavior: SnackBarBehavior.floating,
      ));

    if (!enable) {
      await PushNotificationService.cancelReminder(_notificationBase);
      await PushNotificationService.cancelReminder(_notificationBase + 1);
      await ref.read(grahanRemindersProvider.notifier).set(event.id, enabled: false);
      say(s.reminderRemoved);
      return;
    }

    final granted = await PushNotificationService.checkPermissionGranted() ||
        await PushNotificationService.requestNotificationPermission();
    if (!granted) {
      say(s.permissionNeeded);
      return;
    }

    final sparsh = _local(event.sparshUtc!);
    final body = s.notifyBody(
      s.timeOn(sparsh, sparsh),
      s.timeOn(_local(event.mokshaUtc!), sparsh),
    );
    const payload = {'route': 'grahan'};
    final sutak = event.sutakUtc;
    if (sutak != null) {
      await PushNotificationService.scheduleReminder(
        id: _notificationBase,
        atUtc: sutak,
        title: s.notifySutakTitle(event),
        body: body,
        payload: payload,
      );
    }
    await PushNotificationService.scheduleReminder(
      id: _notificationBase + 1,
      atUtc: event.sparshUtc!.subtract(const Duration(minutes: 10)),
      title: s.notifySparshTitle(event),
      body: body,
      payload: payload,
    );
    await ref.read(grahanRemindersProvider.notifier).set(event.id, enabled: true);
    say(s.reminderSet);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = event;
    final isSolar = e.kind == GrahanKind.surya;
    final nowUtc = DateTime.now().toUtc();
    final ongoing = e.sparshUtc != null &&
        e.mokshaUtc != null &&
        !nowUtc.isBefore(e.sparshUtc!) &&
        nowUtc.isBefore(e.mokshaUtc!);
    final reference = _local(e.madhyaUtc ?? e.greatestUtc);
    final reminderOn = ref.watch(grahanRemindersProvider).contains(e.id);
    final canRemind = e.visible &&
        e.isObserved &&
        e.sparshUtc != null &&
        e.sparshUtc!.isAfter(nowUtc) &&
        PushNotificationService.canScheduleReminders;

    final localType = isSolar && e.visible && (e.localMagnitude ?? 0) < 1 && e.type != GrahanType.partial
        ? s.partialHere
        : s.type(e.type);

    final rows = <(String, String)>[];
    if (e.visible) {
      String at(DateTime? utc) => s.timeOn(_local(utc!), reference);
      rows
        ..add((s.sparsh, at(e.sparshUtc)))
        ..add((s.madhya, at(e.madhyaUtc)))
        ..add((s.moksha, at(e.mokshaUtc)));
      if (e.totalStartUtc != null) {
        rows.add((s.totality, '${at(e.totalStartUtc)} – ${at(e.totalEndUtc)}'));
      }
      final partlyVisible = e.visibleFromUtc != e.sparshUtc || e.visibleToUtc != e.mokshaUtc;
      if (partlyVisible && e.visibleFromUtc != null) {
        rows.add((s.visibleWindow, '${at(e.visibleFromUtc)} – ${at(e.visibleToUtc)}'));
      }
      rows.add((s.duration, s.durationText(e.mokshaUtc!.difference(e.sparshUtc!))));
      if (isSolar && e.localMagnitude != null) {
        rows.add((s.coverage, s.percent(e.localMagnitude!.clamp(0.0, 1.0))));
      }
      if (e.sutakUtc != null) {
        rows
          ..add((s.sutak, at(e.sutakUtc)))
          ..add((s.sutakRelaxed, at(e.relaxedSutakUtc)));
      }
    }

    return KundaliFlatCard(
      color: e.visible && e.isObserved ? MandirTheme.cardBackground : MandirTheme.surfaceWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isSolar ? MandirTheme.primarySaffron : const Color(0xFF3949AB))
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSolar ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  color: isSolar ? MandirTheme.primarySaffron : const Color(0xFF3949AB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.kind(e.kind)} • $localType',
                      style: GoogleFonts.mukta(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: MandirTheme.cardTitle,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      s.fullDate(reference),
                      style: GoogleFonts.mukta(fontSize: 14, color: MandirTheme.cardSubtitle),
                    ),
                  ],
                ),
              ),
              if (ongoing || isFirst) _Badge(text: ongoing ? s.ongoing : s.next),
            ],
          ),
          const SizedBox(height: 10),
          _VisibilityPill(visible: e.visible, s: s),
          if (e.visible && !e.isObserved) ...[
            const SizedBox(height: 8),
            _Note(s.penumbralNote),
          ],
          if (!e.visible) ...[
            const SizedBox(height: 8),
            _Note(s.notVisibleNote),
          ],
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        r.$1,
                        style: GoogleFonts.mukta(fontSize: 14.5, color: MandirTheme.textMuted),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Text(
                        r.$2,
                        textAlign: TextAlign.end,
                        style: GoogleFonts.mukta(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: r.$1 == s.sutak ? MandirTheme.primarySaffron : MandirTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (canRemind) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _toggleReminder(context, ref, !reminderOn),
                icon: Icon(
                  reminderOn ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                ),
                label: Text(
                  reminderOn ? s.reminderOn : s.remind,
                  style: GoogleFonts.mukta(fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: reminderOn ? Colors.white : MandirTheme.primarySaffron,
                  backgroundColor: reminderOn ? MandirTheme.primarySaffron : Colors.transparent,
                  side: const BorderSide(color: MandirTheme.primarySaffron),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: const ShapeDecoration(
          color: MandirTheme.primarySaffron,
          shape: StadiumBorder(),
        ),
        child: Text(
          text,
          style: GoogleFonts.mukta(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      );
}

class _VisibilityPill extends StatelessWidget {
  const _VisibilityPill({required this.visible, required this.s});

  final bool visible;
  final GrahanStrings s;

  @override
  Widget build(BuildContext context) {
    final color = visible ? const Color(0xFF2E7D32) : MandirTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            visible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            visible ? s.visible : s.notVisible,
            style: GoogleFonts.mukta(fontSize: 13.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.mukta(fontSize: 13.5, color: MandirTheme.textMuted, height: 1.35),
      );
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({required this.s});

  final GrahanStrings s;

  @override
  Widget build(BuildContext context) {
    return KundaliFlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.guidanceTitle,
            style: GoogleFonts.mukta(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: MandirTheme.cardTitle,
            ),
          ),
          const SizedBox(height: 6),
          for (final line in s.guidance)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: GoogleFonts.mukta(fontSize: 15, color: MandirTheme.primarySaffron)),
                  Expanded(
                    child: Text(
                      line,
                      style: GoogleFonts.mukta(fontSize: 14.5, color: MandirTheme.textDark, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.safety,
                    style: GoogleFonts.mukta(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB71C1C),
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
}

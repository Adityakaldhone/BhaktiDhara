import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/theme/theme.dart';
import '../../domain/entities/aarti_item.dart';
import '../../services/aarti_reminder_service.dart';
import '../../services/backend_service.dart';
import '../providers/aarti_favorites_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/nitya_onboarding_providers.dart';

String _t(String lang, {required String en, required String hi, required String mr}) =>
    lang == 'en' ? en : (lang == 'mr' ? mr : hi);

/// After an aarti: "make this my Nitya Aarti" + daily reminder, offered once.
class NityaPinSheet {
  NityaPinSheet._();

  static const _shownKey = 'nitya_pin_sheet_shown';

  /// Offered once per install: always to devotees who picked an Ishta Devta
  /// (their aarti is already pinned, so this is mainly the reminder offer),
  /// otherwise only to devotees who have not pinned anything yet.
  static bool shouldOffer({
    required bool alreadyShown,
    required bool fromOnboarding,
    required bool hasPins,
    bool hasIshta = false,
  }) =>
      !alreadyShown && (fromOnboarding || hasIshta || !hasPins);

  static Future<bool> wasShown() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_shownKey) ?? false;
    } catch (_) {
      return true;
    }
  }

  static bool _openThisSession = false;

  /// Returns whether the sheet was shown.
  static Future<bool> maybeShow(
    BuildContext context,
    WidgetRef ref,
    AartiItem aarti, {
    required bool fromOnboarding,
    required String trigger,
  }) async {
    if (_openThisSession) return false;
    final offer = shouldOffer(
      alreadyShown: await wasShown(),
      fromOnboarding: fromOnboarding,
      hasPins: ref.read(aartiFavoritesProvider).isNotEmpty,
      hasIshta: ref.read(ishtaDevtaProvider) != null,
    );
    if (!offer || !context.mounted) return false;
    _openThisSession = true;
    try {
      await (await SharedPreferences.getInstance()).setBool(_shownKey, true);
    } catch (_) {}
    BackendService.trackEvent(
      'nitya_sheet_view',
      item: aarti.id,
      props: {'trigger': trigger, 'onboarding': fromOnboarding},
    );
    if (!context.mounted) return false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NityaPinSheetBody(aarti: aarti, fromOnboarding: fromOnboarding),
    );
    return true;
  }
}

class _NityaPinSheetBody extends ConsumerStatefulWidget {
  const _NityaPinSheetBody({required this.aarti, required this.fromOnboarding});

  final AartiItem aarti;
  final bool fromOnboarding;

  @override
  ConsumerState<_NityaPinSheetBody> createState() => _NityaPinSheetBodyState();
}

class _NityaPinSheetBodyState extends ConsumerState<_NityaPinSheetBody> {
  bool _pin = true;
  bool _evening = true;
  bool _kakad = false;
  bool _saving = false;

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    final lang = ref.read(localeProvider).languageCode;
    final source = widget.fromOnboarding ? 'onboarding_sheet' : 'aarti_sheet';

    if (_pin) {
      await ref.read(aartiFavoritesProvider.notifier).pin(widget.aarti.id);
      BackendService.trackEvent('nitya_pinned', item: widget.aarti.id, props: {'source': source});
      AnalyticsService.logFunnelEvent(
        FunnelEvent.nityaPinned,
        parameters: {'item_id': widget.aarti.id, 'source': source},
      );
    }
    final current = ref.read(aartiRemindersProvider);
    final next = current.copyWith(
      evening: current.evening || _evening,
      kakad: current.kakad || _kakad,
    );
    if (next.evening != current.evening || next.kakad != current.kakad) {
      await ref.read(aartiRemindersProvider.notifier).update(
            next,
            lang: lang,
            source: source,
            aartiId: widget.aarti.id,
          );
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _dismiss() {
    BackendService.trackEvent('nitya_sheet_dismissed', item: widget.aarti.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final title = widget.aarti.localizedTitle(lang);

    return _SheetFrame(
      children: [
        Text(
          _t(lang,
              en: '🙏 Make it your daily aarti',
              hi: '🙏 इसे अपनी नित्य आरती बनाएं',
              mr: '🙏 हिला तुमची नित्य आरती बनवा'),
          textAlign: TextAlign.center,
          style: GoogleFonts.mukta(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: MandirTheme.secondaryMaroon,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.mukta(fontSize: 16, color: MandirTheme.textMuted),
        ),
        const SizedBox(height: 16),
        _ToggleRow(
          key: const Key('nitya-pin-toggle'),
          icon: '🪔',
          title: _t(lang,
              en: 'Pin to My Daily Aartis',
              hi: 'मेरी नित्य आरती में जोड़ें',
              mr: 'माझी नित्य आरती मध्ये जोडा'),
          subtitle: _t(lang,
              en: 'One tap from the home screen',
              hi: 'होम स्क्रीन पर एक टैप में',
              mr: 'होम स्क्रीनवर एका टॅपमध्ये'),
          value: _pin,
          onChanged: (v) => setState(() => _pin = v),
        ),
        _ToggleRow(
          key: const Key('nitya-evening-toggle'),
          icon: '🔔',
          title: _t(lang,
              en: 'Remind me daily at 6:30 PM',
              hi: 'रोज़ शाम 6:30 बजे याद दिलाएं',
              mr: 'रोज संध्याकाळी 6:30 वाजता आठवण करा'),
          subtitle: _t(lang,
              en: 'We’ll remind you for Sandhya aarti',
              hi: 'संध्या आरती याद दिलाएंगे',
              mr: 'संध्याकाळच्या आरतीची आठवण करून देऊ'),
          value: _evening,
          onChanged: (v) => setState(() => _evening = v),
        ),
        _ToggleRow(
          key: const Key('nitya-kakad-toggle'),
          icon: '🌅',
          title: _t(lang,
              en: 'Kakad aarti at 6 AM',
              hi: 'सुबह 6 बजे काकड़ आरती',
              mr: 'पहाटे 6 वाजता काकड आरती'),
          subtitle: _t(lang, en: 'Optional', hi: 'वैकल्पिक', mr: 'ऐच्छिक'),
          value: _kakad,
          onChanged: (v) => setState(() => _kakad = v),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            key: const Key('nitya-confirm'),
            onPressed: _saving ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: MandirTheme.primarySaffron,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _t(lang, en: 'Yes, save', hi: 'हाँ, सेव करें', mr: 'होय, सेव्ह करा'),
              style: GoogleFonts.mukta(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        TextButton(
          key: const Key('nitya-dismiss'),
          onPressed: _saving ? null : _dismiss,
          child: Text(
            _t(lang, en: 'Not now', hi: 'अभी नहीं', mr: 'आत्ता नको'),
            style: GoogleFonts.mukta(fontSize: 16, color: MandirTheme.textMuted),
          ),
        ),
      ],
    );
  }
}

/// Reminder switches that apply immediately; opened from the More tab.
Future<void> showAartiReminderSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ReminderSettingsBody(),
  );
}

class _ReminderSettingsBody extends ConsumerWidget {
  const _ReminderSettingsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final settings = ref.watch(aartiRemindersProvider);

    Future<void> apply(AartiReminderSettings next) async {
      final firstPin = ref.read(aartiFavoritesProvider).firstOrNull;
      final deliverable = await ref.read(aartiRemindersProvider.notifier).update(
            next,
            lang: lang,
            source: 'more_tab',
            aartiId: firstPin,
          );
      if (!deliverable && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              _t(lang,
                  en: 'Turn on notifications for BhaktiDhara in phone Settings.',
                  hi: 'फ़ोन सेटिंग्स में भक्तिधारा के नोटिफिकेशन चालू करें।',
                  mr: 'फोन सेटिंग्जमध्ये भक्तिधाराच्या सूचना सुरू करा.'),
              style: GoogleFonts.mukta(fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    }

    return _SheetFrame(
      children: [
        Text(
          _t(lang, en: 'Aarti reminders', hi: 'आरती रिमाइंडर', mr: 'आरती आठवण'),
          textAlign: TextAlign.center,
          style: GoogleFonts.mukta(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: MandirTheme.secondaryMaroon,
          ),
        ),
        const SizedBox(height: 12),
        _ToggleRow(
          key: const Key('reminder-evening-toggle'),
          icon: '🪔',
          title: _t(lang,
              en: 'Sandhya aarti · 6:30 PM',
              hi: 'संध्या आरती · शाम 6:30',
              mr: 'संध्याकाळची आरती · 6:30'),
          subtitle: _t(lang, en: 'Every evening', hi: 'रोज़ शाम', mr: 'रोज संध्याकाळी'),
          value: settings.evening,
          onChanged: (v) => apply(settings.copyWith(evening: v)),
        ),
        _ToggleRow(
          key: const Key('reminder-kakad-toggle'),
          icon: '🌅',
          title: _t(lang,
              en: 'Kakad aarti · 6:00 AM',
              hi: 'काकड़ आरती · सुबह 6:00',
              mr: 'काकड आरती · पहाटे 6:00'),
          subtitle: _t(lang, en: 'Every morning', hi: 'रोज़ सुबह', mr: 'रोज सकाळी'),
          value: settings.kakad,
          onChanged: (v) => apply(settings.copyWith(kakad: v)),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: MandirTheme.backgroundCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: MandirTheme.goldenAccent.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: MandirTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MandirTheme.cardBorder),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: MandirTheme.primarySaffron,
        activeTrackColor: MandirTheme.primarySaffron.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        secondary: Text(icon, style: const TextStyle(fontSize: 24)),
        title: Text(
          title,
          style: GoogleFonts.mukta(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: MandirTheme.textDark,
            height: 1.2,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.mukta(fontSize: 13, color: MandirTheme.textMuted),
        ),
      ),
    );
  }
}

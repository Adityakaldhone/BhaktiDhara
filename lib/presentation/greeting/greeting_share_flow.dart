import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme.dart';
import '../../domain/logic/greeting_card_logic.dart';
import '../../services/backend_service.dart';
import '../../services/card_renderer.dart';
import '../../services/card_share_service.dart';
import '../providers/greeting_card_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/remote_config_provider.dart';
import '../providers/review_provider.dart';
import '../widgets/premium_blurred_gate.dart';
import 'greeting_strings.dart';

bool _sharing = false;

/// Checks if free tier user can share today (limit: 1 card/day).
Future<bool> _isDailyShareAllowed() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = 'greeting_share_count_${now.year}_${now.month}_${now.day}';
    final count = prefs.getInt(todayKey) ?? 0;
    return count < 1;
  } catch (_) {
    return true; // Fail-open so users aren't stuck on prefs read errors
  }
}

/// Increment today's share count for free tier users.
Future<void> _recordDailyShare() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = 'greeting_share_count_${now.year}_${now.month}_${now.day}';
    final count = prefs.getInt(todayKey) ?? 0;
    await prefs.setInt(todayKey, count + 1);
  } catch (_) {}
}

/// Render + share today's card.
///
/// - Free tier users whose 7-day trial expired have a 1 card/day limit.
/// - Active trial and paid premium members enjoy unlimited shares!
Future<void> shareGreetingCard(
  BuildContext context,
  WidgetRef ref, {
  Rect? origin,
}) async {
  if (_sharing) return;
  _sharing = true;
  final lang = ref.read(localeProvider).languageCode;
  final s = GreetingStrings(lang);
  final messenger = ScaffoldMessenger.maybeOf(context);

  try {
    // Check daily limit for non-premium free users
    final isPremium = ref.read(premiumAccessProvider);
    if (!isPremium) {
      final allowed = await _isDailyShareAllowed();
      if (!allowed) {
        if (context.mounted) {
          _showDailyLimitBottomSheet(context, ref, lang, s);
        }
        return;
      }
    }

    final prefsNotifier = ref.read(greetingCardPrefsProvider.notifier);
    await prefsNotifier.ready;
    if (!ref.read(greetingCardPrefsProvider).askedForName) {
      if (!context.mounted) return;
      final name = await askSenderName(context, s);
      if (name == null) {
        prefsNotifier.markAskedForName();
      } else {
        prefsNotifier.setSenderName(name);
      }
    }

    final card = ref.read(greetingCardProvider);

    messenger?.showSnackBar(SnackBar(
      content: Text(s.preparing),
      duration: const Duration(seconds: 2),
    ));
    final png = await CardRenderer.renderPng(card);
    messenger?.hideCurrentSnackBar();

    await CardShareService.share(
      png: png,
      caption: s.caption(card.title),
      origin: origin,
    );

    // Record share count for free users
    if (!isPremium) {
      await _recordDailyShare();
    }

    BackendService.trackEvent('status_card_share', props: {
      'template': card.template.name,
      'deity': card.deityId,
      'lang': lang,
      'photo': card.photoStamp != null,
      'emoji': card.emojis != null,
      'is_premium': isPremium,
    });

    // Track card share for review eligibility
    ref.read(reviewServiceProvider).trackCardShared();
  } catch (_) {
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(s.shareFailed)));
  } finally {
    _sharing = false;
  }
}

/// Displays an upsell sheet when a free user reaches the 1 card/day limit.
void _showDailyLimitBottomSheet(
  BuildContext context,
  WidgetRef ref,
  String lang,
  GreetingStrings s,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBF2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            // Royal Badge Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B1D18), Color(0xFFD84315)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B1D18).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFFFD54F),
                size: 32,
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              s.dailyLimitTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF7A0C08),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),

            // Body
            Text(
              s.dailyLimitBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(
                fontSize: 15,
                color: MandirTheme.textDark,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Benefits preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEEDCC7)),
              ),
              child: Column(
                children: [
                  _benefitRow(
                    '🚀',
                    lang == 'en'
                        ? 'Unlimited Cards Daily'
                        : (lang == 'hi'
                            ? 'प्रतिदिन असीमित कार्ड्स'
                            : 'दररोज अमर्याद कार्ड्स'),
                  ),
                  const Divider(height: 10, color: Color(0xFFF3E7D5)),
                  _benefitRow(
                    '✨',
                    lang == 'en'
                        ? 'Watermark-Free HD Sharing'
                        : (lang == 'hi'
                            ? 'बिना वॉटरमार्क सुंदर कार्ड'
                            : 'वॉटरमार्क नसलेले HD ग्रीटिंग्ज'),
                  ),
                  const Divider(height: 10, color: Color(0xFFF3E7D5)),
                  _benefitRow(
                    '🎨',
                    lang == 'en'
                        ? 'All 7+ Royal Templates'
                        : (lang == 'hi'
                            ? 'सभी 7+ राजसी व खास डिज़ाइन'
                            : 'सर्व ७+ राजेशाही व विशेष डिझाइन्स'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Upgrade Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1D18),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 3,
                ),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  showPremiumPaywallSheet(context, ref, lang);
                },
                icon: const Icon(Icons.stars_rounded, color: Color(0xFFFFD54F)),
                label: Text(
                  s.viewPremiumPlans,
                  style: GoogleFonts.mukta(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Dismiss Button
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: Text(
                s.tryAgainTomorrow,
                style: GoogleFonts.mukta(
                  fontSize: 14.5,
                  color: MandirTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _benefitRow(String emoji, String text) {
  return Row(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 17)),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: GoogleFonts.mukta(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: MandirTheme.textDark,
          ),
        ),
      ),
    ],
  );
}

/// Returns the entered name, or null when the user skips.
Future<String?> askSenderName(BuildContext context, GreetingStrings s) {
  return showDialog<String>(
    context: context,
    builder: (context) => _NameDialog(s: s),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.s});

  final GreetingStrings s;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _controller = TextEditingController();
  bool _invalid = false;

  @override
  void initState() {
    super.initState();
    BackendService.getDevoteeName().then((saved) {
      if (!mounted || saved == null || _controller.text.isNotEmpty) return;
      final clean = GreetingCardLogic.sanitizeName(saved);
      if (clean != null) _controller.text = clean;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = GreetingCardLogic.sanitizeName(_controller.text);
    if (name == null) {
      setState(() => _invalid = _controller.text.trim().isNotEmpty);
      if (_controller.text.trim().isEmpty) Navigator.pop(context);
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return AlertDialog(
      title: Text(
        s.askNameTitle,
        style: GoogleFonts.mukta(fontSize: 21, fontWeight: FontWeight.w800, color: MandirTheme.secondaryMaroon),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.askNameBody, style: GoogleFonts.mukta(fontSize: 16, color: MandirTheme.textDark)),
          const SizedBox(height: 12),
          TextField(
            key: const Key('greeting-name-field'),
            controller: _controller,
            autofocus: true,
            maxLength: GreetingCardLogic.maxNameLength,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            style: GoogleFonts.mukta(fontSize: 19, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: s.nameHint,
              errorText: _invalid ? s.nameInvalid : null,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.skipName, style: GoogleFonts.mukta(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
          child: Text(s.addName, style: GoogleFonts.mukta(fontSize: 17, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

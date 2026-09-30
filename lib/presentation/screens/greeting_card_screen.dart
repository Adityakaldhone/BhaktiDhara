import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/theme.dart';
import '../../data/datasources/greeting_content.dart';
import '../../data/repositories/greeting_card_prefs_repository.dart';
import '../../domain/entities/greeting_card.dart';
import '../../domain/logic/greeting_card_logic.dart';
import '../../services/backend_service.dart';
import '../../domain/entities/subscription_plan.dart';
import '../greeting/greeting_share_flow.dart';
import '../greeting/greeting_strings.dart';
import '../providers/greeting_card_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/premium_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/greeting/card_canvas.dart';
import '../widgets/premium_blurred_gate.dart';

const _whatsAppGreen = Color(0xFF1B7F3B);

const _quickEmojis = [
  '🙏', '🪔', '🌺', '🌸', '🌼', '💐', '🕉️', '🔱', '🚩', '🐚', '🔔', '🛕', //
  '✨', '🌞', '🌅', '🌹', '🍃', '❤️', '🧡', '💛', '🙌', '😊', '🥰', '🎉',
];

final _emojiOnly = TextInputFormatter.withFunction((oldValue, newValue) {
  final clean = GreetingCardLogic.sanitizeEmojis(newValue.text) ?? '';
  if (clean == newValue.text) return newValue;
  return TextEditingValue(text: clean, selection: TextSelection.collapsed(offset: clean.length));
});

/// Today's card with one big send button. No ads here — the card carries
/// the app's name to other families.
class GreetingCardScreen extends ConsumerStatefulWidget {
  const GreetingCardScreen({super.key});

  @override
  ConsumerState<GreetingCardScreen> createState() => _GreetingCardScreenState();
}

class _GreetingCardScreenState extends ConsumerState<GreetingCardScreen> {
  @override
  void initState() {
    super.initState();
    BackendService.trackEvent('status_card_preview');
  }

  @override
  Widget build(BuildContext context) {
    final langCode = ref.watch(localeProvider).languageCode;
    final s = GreetingStrings(langCode);
    final card = ref.watch(greetingCardProvider);
    final subStatus = ref.watch(subscriptionProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: MandirTheme.backgroundCream,
        foregroundColor: MandirTheme.secondaryMaroon,
        elevation: 0,
        title: Text(
          s.previewTitle,
          style: GoogleFonts.mukta(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        actions: [
          _buildMembershipAction(context, subStatus, isPremium, langCode),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Membership / Free Trial / Trial-Ended Status Banner
            _SubscriptionStatusBanner(
              status: subStatus,
              isPremium: isPremium,
              langCode: langCode,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Center(child: CardPreview(data: card, radius: 16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  SizedBox(
                    height: 60,
                    child: OutlinedButton.icon(
                      key: const Key('greeting-edit-button'),
                      onPressed: () => showGreetingEditSheet(context),
                      icon: const Icon(Icons.edit_rounded),
                      label: Text(s.change, style: GoogleFonts.mukta(fontSize: 18, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MandirTheme.secondaryMaroon,
                        side: const BorderSide(color: MandirTheme.secondaryMaroon, width: 1.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Builder(
                      builder: (buttonContext) => SizedBox(
                        height: 60,
                        child: FilledButton.icon(
                          key: const Key('greeting-send-button'),
                          onPressed: () {
                            final box = buttonContext.findRenderObject() as RenderBox?;
                            final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
                            shareGreetingCard(context, ref, origin: origin);
                          },
                          icon: const Icon(Icons.send_rounded),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              s.sendWhatsApp,
                              style: GoogleFonts.mukta(fontSize: 19, fontWeight: FontWeight.w800),
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _whatsAppGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipAction(
    BuildContext context,
    SubscriptionStatus status,
    bool isPremium,
    String lang,
  ) {
    if (isPremium && !status.isTrial) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => showPremiumPaywallSheet(context, ref, lang),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8F00).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium_rounded, size: 16, color: Color(0xFF7A0C08)),
                  const SizedBox(width: 4),
                  Text(
                    lang == 'en' ? 'Premium' : (lang == 'hi' ? 'प्रीमियम' : 'प्रीमियम'),
                    style: GoogleFonts.mukta(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7A0C08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (status.isTrial && isPremium && !status.trialExpired) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => showPremiumPaywallSheet(context, ref, lang),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B1D18), Color(0xFFD84315)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B1D18).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.celebration_rounded, size: 15, color: Color(0xFFFFD54F)),
                  const SizedBox(width: 4),
                  Text(
                    lang == 'en'
                        ? 'Trial (${status.trialDaysRemaining}d)'
                        : (lang == 'hi'
                            ? 'ट्रायल (${status.trialDaysRemaining} दिन)'
                            : 'ट्रायल (${status.trialDaysRemaining}d)'),
                    style: GoogleFonts.mukta(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showPremiumPaywallSheet(context, ref, lang),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B1D18), Color(0xFFE65100)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B1D18).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium_rounded, size: 15, color: Color(0xFFFFD54F)),
                const SizedBox(width: 4),
                Text(
                  lang == 'en' ? 'Plans' : (lang == 'hi' ? 'प्लान्स' : 'प्लॅन्स'),
                  style: GoogleFonts.mukta(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Status banner showing Free Trial / Trial Ended / Paid Premium status.
class _SubscriptionStatusBanner extends ConsumerWidget {
  final SubscriptionStatus status;
  final bool isPremium;
  final String langCode;

  const _SubscriptionStatusBanner({
    required this.status,
    required this.isPremium,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isPremium && !status.isTrial) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD4AF37)),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD4AF37), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                langCode == 'en'
                    ? '👑 BhaktiDhara Premium • Watermark-Free Unlimited Cards'
                    : (langCode == 'hi'
                        ? '👑 भक्तिधारा प्रीमियम • वॉटरमार्क-मुक्त असीमित कार्ड'
                        : '👑 भक्तीधारा प्रीमियम • वॉटरमार्क मुक्त अमर्याद कार्ड्स'),
                style: GoogleFonts.mukta(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7A0C08),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (status.isTrial && isPremium && !status.trialExpired) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF8E7), Color(0xFFFFECC4)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
        ),
        child: Row(
          children: [
            const Icon(Icons.celebration_rounded, color: Color(0xFFE65100), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      langCode == 'en'
                          ? '🎉 7-Day Free Trial (${status.trialDaysRemaining} days left)'
                          : (langCode == 'hi'
                              ? '🎉 7 दिन मुफ्त ट्रायल (${status.trialDaysRemaining} दिन शेष)'
                              : '🎉 ७ दिवस मोफत ट्रायल (${status.trialDaysRemaining} दिवस शिल्लक)'),
                      style: GoogleFonts.mukta(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7A0C08),
                      ),
                    ),
                  ),
                  Text(
                    langCode == 'en'
                        ? 'Enjoying watermark-free unlimited cards!'
                        : (langCode == 'hi'
                            ? 'वॉटरमार्क-मुक्त असीमित कार्ड चालू हैं!'
                            : 'वॉटरमार्कशिवाय अमर्याद कार्ड्स मोफत सुरू!'),
                    style: GoogleFonts.mukta(
                      fontSize: 12,
                      color: const Color(0xFF6D4C41),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => showPremiumPaywallSheet(context, ref, langCode),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                langCode == 'en' ? 'Plans' : (langCode == 'hi' ? 'प्लान्स' : 'प्लॅन्स'),
                style: GoogleFonts.mukta(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8B1D18),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Trial expired or free tier
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3F0), Color(0xFFFFE5E0)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD32F2F).withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFFC62828), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  langCode == 'en'
                      ? 'Free Plan (1 card/day • with watermark)'
                      : (langCode == 'hi'
                          ? 'मुफ्त प्लान (1 कार्ड/दिन • वॉटरमार्क सहित)'
                          : 'मोफत आवृत्ती (१ कार्ड/दिवस • वॉटरमार्कसह)'),
                  style: GoogleFonts.mukta(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB71C1C),
                  ),
                ),
                Text(
                  langCode == 'en'
                      ? 'Remove watermark & unlock all templates'
                      : (langCode == 'hi'
                          ? 'वॉटरमार्क हटाने व सभी डिज़ाइन हेतु:'
                          : 'वॉटरमार्क काढण्यासाठी व सर्व डिझाइन्ससाठी:'),
                  style: GoogleFonts.mukta(
                    fontSize: 12,
                    color: MandirTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B1D18),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => showPremiumPaywallSheet(context, ref, langCode),
            child: Text(
              langCode == 'en' ? '₹51/mo' : (langCode == 'hi' ? '₹51/मा.' : '₹५१/मा.'),
              style: GoogleFonts.mukta(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The real card canvas, scaled to fit — identical to the shared image.
class CardPreview extends ConsumerWidget {
  const CardPreview({super.key, required this.data, this.radius = 12});

  final GreetingCardData data;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref
            .watch(cardImagesProvider((deityId: data.deityId, photoStamp: data.photoStamp)))
            .valueOrNull ??
        const CardImages();
    final isPremium = ref.watch(isPremiumProvider);
    final langCode = ref.watch(localeProvider).languageCode;

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A5A2B).withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                child: GreetingCardCanvas(data: data, images: images),
              ),
              // If free user (not premium), display subtle watermark badge with tap to remove
              if (!isPremium)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => showPremiumPaywallSheet(context, ref, langCode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline, size: 11, color: Color(0xFFFFD54F)),
                          const SizedBox(width: 4),
                          Text(
                            langCode == 'en'
                                ? 'Watermark (Tap to remove)'
                                : (langCode == 'hi'
                                    ? 'वॉटरमार्क (हटाने हेतु टैप करें)'
                                    : 'वॉटरमार्क (काढण्यासाठी टॅप करा)'),
                            style: GoogleFonts.mukta(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
    );
  }
}

Future<void> showGreetingEditSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MandirTheme.backgroundCream,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _GreetingEditSheet(),
  );
}

class _GreetingEditSheet extends ConsumerStatefulWidget {
  const _GreetingEditSheet();

  @override
  ConsumerState<_GreetingEditSheet> createState() => _GreetingEditSheetState();
}

class _GreetingEditSheetState extends ConsumerState<_GreetingEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _emojis;
  bool _invalid = false;
  bool _pickingPhoto = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: ref.read(greetingCardPrefsProvider).senderName ?? '');
    _emojis = TextEditingController(text: ref.read(greetingCardPrefsProvider).emojis ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _emojis.dispose();
    super.dispose();
  }

  void _done() {
    final raw = _name.text.trim();
    if (raw.isNotEmpty && GreetingCardLogic.sanitizeName(raw) == null) {
      setState(() => _invalid = true);
      return;
    }
    ref.read(greetingCardPrefsProvider.notifier).setSenderName(raw);
    Navigator.pop(context);
  }

  void _setEmojis(String value) {
    final clean = GreetingCardLogic.sanitizeEmojis(value) ?? '';
    if (_emojis.text != clean) {
      _emojis.value = TextEditingValue(text: clean, selection: TextSelection.collapsed(offset: clean.length));
    }
    ref.read(greetingCardPrefsProvider.notifier).setEmojis(clean);
  }

  Widget _emojiSection(GreetingStrings s, TextStyle label) {
    final full = _emojis.text.characters.length >= GreetingCardLogic.maxEmojis;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(s.emojiTitle, style: label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final emoji in _quickEmojis)
              InkWell(
                key: Key('greeting-emoji-$emoji'),
                borderRadius: BorderRadius.circular(10),
                onTap: full ? null : () => _setEmojis(_emojis.text + emoji),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('greeting-edit-emoji'),
          controller: _emojis,
          inputFormatters: [_emojiOnly],
          onChanged: _setEmojis,
          style: const TextStyle(fontSize: 26),
          decoration: InputDecoration(
            hintText: '🙏🪔🌺',
            helperText: s.emojiHint,
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            suffixIcon: _emojis.text.isEmpty
                ? null
                : IconButton(
                    key: const Key('greeting-emoji-clear'),
                    tooltip: s.clear,
                    icon: const Icon(Icons.backspace_outlined),
                    onPressed: () {
                      final chars = _emojis.text.characters;
                      _setEmojis(chars.take(chars.length - 1).toString());
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickPhoto(GreetingStrings s) async {
    if (_pickingPhoto) return;
    setState(() => _pickingPhoto = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    var saved = false;
    try {
      // The system photo picker needs no permission; requestFullMetadata
      // false keeps iOS from asking for photo-library access.
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        requestFullMetadata: false,
      );
      if (file == null) return;
      saved = await ref.read(greetingCardPrefsProvider.notifier).setPhoto(await file.readAsBytes());
      if (saved) BackendService.trackEvent('status_card_photo_added');
    } catch (_) {
      saved = false;
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
    if (!saved) messenger?.showSnackBar(SnackBar(content: Text(s.photoFailed)));
  }

  Widget _photoSection(GreetingStrings s, GreetingCardPrefs prefs, TextStyle label) {
    final card = ref.watch(greetingCardProvider);
    final photo = card.photoStamp == null
        ? null
        : ref.watch(cardImagesProvider((deityId: card.deityId, photoStamp: card.photoStamp))).valueOrNull?.photo;
    final buttonText = GoogleFonts.mukta(fontSize: 17, fontWeight: FontWeight.w700);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(s.yourPhoto, style: label),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFF3D6),
                border: Border.all(color: const Color(0xFFE8C98A), width: 1.2),
              ),
              child: ClipOval(
                child: photo == null
                    ? const Icon(Icons.person_rounded, size: 40, color: Color(0xFFC9A36A))
                    : RawImage(image: photo, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: FilledButton.tonalIcon(
                key: const Key('greeting-photo-pick'),
                onPressed: _pickingPhoto ? null : () => _pickPhoto(s),
                icon: _pickingPhoto
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.photo_library_rounded),
                label: Text(prefs.photoStamp == null ? s.addPhoto : s.changePhoto, style: buttonText),
              ),
            ),
            if (prefs.photoStamp != null) ...[
              const SizedBox(width: 4),
              TextButton(
                key: const Key('greeting-photo-remove'),
                onPressed: () => ref.read(greetingCardPrefsProvider.notifier).removePhoto(),
                child: Text(s.removePhoto, style: buttonText),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(s.photoHint, style: GoogleFonts.mukta(fontSize: 14, color: MandirTheme.textDark)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final s = GreetingStrings(lang);
    final prefs = ref.watch(greetingCardPrefsProvider);
    final notifier = ref.read(greetingCardPrefsProvider.notifier);
    final todayDeity = GreetingContent.deity(
      GreetingCardLogic.weekdayDeity(GreetingCardLogic.cardDay(ref.read(greetingClockProvider)()), lang),
    );
    final label = GoogleFonts.mukta(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: MandirTheme.secondaryMaroon,
    );

    String greetingText(GreetingChoice g) => switch (g) {
          GreetingChoice.morning => GreetingContent.morningGreeting[lang] ?? GreetingContent.morningGreeting['mr']!,
          GreetingChoice.jaykar => GreetingContent.deity(prefs.deityId ?? todayDeity.id).localizedJaykar(lang),
          GreetingChoice.alt => GreetingContent.altGreeting[lang] ?? GreetingContent.altGreeting['mr']!,
        };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(
                  s.editTitle,
                  style: GoogleFonts.mukta(fontSize: 22, fontWeight: FontWeight.w800, color: MandirTheme.secondaryMaroon),
                ),
              ),
              const SizedBox(height: 10),
              _buildMembershipSheetBanner(context, ref, lang),
              const SizedBox(height: 12),
              Text(s.chooseDesign, style: label),
              const SizedBox(height: 8),
              SizedBox(
                height: 170,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StyleChoice(
                      key: const Key('greeting-style-auto'),
                      style: GreetingCardLogic.autoStyle(
                        GreetingCardLogic.cardDay(ref.read(greetingClockProvider)()),
                      ),
                      name: s.dailyNew,
                      selected: prefs.style == null,
                      onTap: () => notifier.setStyle(null),
                    ),
                    for (final style in CardStyle.values)
                      _StyleChoice(
                        key: Key('greeting-style-${style.name}'),
                        style: style,
                        name: s.styleName(style),
                        selected: prefs.style == style,
                        onTap: () => notifier.setStyle(style),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(s.chooseDeity, style: label),
              const SizedBox(height: 8),
              SizedBox(
                height: 104,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _DeityChoice(
                      asset: todayDeity.asset,
                      name: s.autoDeity,
                      selected: prefs.deityId == null,
                      onTap: () => notifier.setDeity(null),
                    ),
                    for (final d in GreetingContent.deities)
                      _DeityChoice(
                        asset: d.asset,
                        name: d.localizedName(lang),
                        selected: prefs.deityId == d.id,
                        onTap: () => notifier.setDeity(d.id),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(s.chooseGreeting, style: label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final g in GreetingChoice.values)
                    ChoiceChip(
                      label: Text(greetingText(g), style: GoogleFonts.mukta(fontSize: 17, fontWeight: FontWeight.w700)),
                      selected: prefs.greeting == g,
                      onSelected: (_) => notifier.setGreeting(g),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                ],
              ),
              if (ref.watch(statusCardPhotoEnabledProvider).valueOrNull ?? false)
                _photoSection(s, prefs, label),
              _emojiSection(s, label),
              const SizedBox(height: 16),
              Text(s.yourName, style: label),
              const SizedBox(height: 8),
              TextField(
                key: const Key('greeting-edit-name'),
                controller: _name,
                maxLength: GreetingCardLogic.maxNameLength,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _done(),
                style: GoogleFonts.mukta(fontSize: 19, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: s.nameHint,
                  helperText: s.askNameBody,
                  errorText: _invalid ? s.nameInvalid : null,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  key: const Key('greeting-edit-done'),
                  onPressed: _done,
                  style: FilledButton.styleFrom(
                    backgroundColor: MandirTheme.secondaryMaroon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: Text(s.done, style: GoogleFonts.mukta(fontSize: 19, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembershipSheetBanner(
    BuildContext context,
    WidgetRef ref,
    String lang,
  ) {
    final subStatus = ref.watch(subscriptionProvider);
    final isPremium = ref.watch(isPremiumProvider);

    if (isPremium && !subStatus.isTrial) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD4AF37)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFD4AF37),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lang == 'en'
                    ? '👑 BhaktiDhara Premium Active • No Watermark'
                    : (lang == 'hi'
                        ? '👑 भक्तिधारा प्रीमियम सक्रिय • बिना वॉटरमार्क'
                        : '👑 भक्तीधारा प्रीमियम सक्रिय • वॉटरमार्क मुक्त'),
                style: GoogleFonts.mukta(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7A0C08),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (subStatus.isTrial && isPremium && !subStatus.trialExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD4AF37)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.celebration_rounded,
              color: Color(0xFFE65100),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  lang == 'en'
                      ? '🎉 7-Day Free Trial (${subStatus.trialDaysRemaining}d left) • All styles unlocked'
                      : (lang == 'hi'
                          ? '🎉 7 दिन मुफ्त ट्रायल (${subStatus.trialDaysRemaining} दिन शेष)'
                          : '🎉 ७ दिवस मोफत ट्रायल (${subStatus.trialDaysRemaining}d शिल्लक) • सर्व डिझाइन्स मोफत'),
                  style: GoogleFonts.mukta(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7A0C08),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => showPremiumPaywallSheet(context, ref, lang),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
              child: Text(
                lang == 'en' ? 'Plans' : (lang == 'hi' ? 'प्लान्स' : 'प्लॅन्स'),
                style: GoogleFonts.mukta(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8B1D18),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD32F2F).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: Color(0xFFC62828), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lang == 'en'
                  ? 'Free Plan (1 card/day • with watermark)'
                  : (lang == 'hi'
                      ? 'मुफ्त प्लान (1 कार्ड/दिन • वॉटरमार्क सहित)'
                      : 'मोफत आवृत्ती (१ कार्ड/दिवस • वॉटरमार्कसह)'),
              style: GoogleFonts.mukta(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFB71C1C),
              ),
            ),
          ),
          TextButton(
            onPressed: () => showPremiumPaywallSheet(context, ref, lang),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
            child: Text(
              lang == 'en' ? '₹51/mo' : (lang == 'hi' ? '₹51/मा.' : '₹५१/मा.'),
              style: GoogleFonts.mukta(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8B1D18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A live mini card in [style] with the user's current deity, greeting and name.
class _StyleChoice extends ConsumerWidget {
  const _StyleChoice({
    super.key,
    required this.style,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final CardStyle style;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  bool get isExclusive =>
      style == CardStyle.rajwada ||
      style == CardStyle.om ||
      style == CardStyle.kamal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(greetingCardProvider).withStyle(style);
    final isPremium = ref.watch(isPremiumProvider);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 78,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? MandirTheme.primarySaffron
                            : const Color(0xFFE8C98A),
                        width: selected ? 3.5 : 1.2,
                      ),
                    ),
                    child: SizedBox(
                      width: 70,
                      height: 124,
                      child: CardPreview(data: preview, radius: 8),
                    ),
                  ),
                  if (isExclusive && !isPremium)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B1D18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFD54F),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 11,
                          color: Color(0xFFFFD54F),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.mukta(
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: MandirTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeityChoice extends StatelessWidget {
  const _DeityChoice({required this.asset, required this.name, required this.selected, required this.onTap});

  final String asset;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFF3D6),
                  border: Border.all(
                    color: selected ? MandirTheme.primarySaffron : const Color(0xFFE8C98A),
                    width: selected ? 3.5 : 1.2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(asset, fit: BoxFit.cover, cacheWidth: 160, errorBuilder: (_, _, _) => const SizedBox()),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.mukta(
                  fontSize: 13.5,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: MandirTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

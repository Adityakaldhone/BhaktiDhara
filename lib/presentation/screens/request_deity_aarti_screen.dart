import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';
import '../providers/locale_provider.dart';
import '../widgets/request_deity_section.dart';

/// Simple, high-contrast full screen where devotees (especially 40+) can send
/// a Deity or Aarti request in two straightforward steps.
class RequestDeityAartiScreen extends ConsumerWidget {
  const RequestDeityAartiScreen({
    super.key,
    this.initialText = '',
    this.initialKind = DeityRequestKind.deity,
    this.source = 'dedicated_section',
  });

  final String initialText;
  final DeityRequestKind initialKind;
  final String source;

  static String _t(String lang, {required String en, required String hi, required String mr}) =>
      switch (lang) {
        'hi' => hi,
        'mr' => mr,
        _ => en,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    return Scaffold(
      backgroundColor: MandirTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: MandirTheme.surfaceWhite,
        elevation: 0,
        title: Text(
          _t(
            lang,
            en: 'Add Deity or Aarti',
            hi: 'देवता या आरती जोड़ें',
            mr: 'देव किंवा आरती जोडा',
          ),
          style: GoogleFonts.mukta(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: MandirTheme.secondaryMaroon,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DeityAartiRequestSection(
                lang: lang,
                source: source,
                initialText: initialText,
                initialKind: initialKind,
                allowPhotoUpload: true,
                autofocusName: initialText.isEmpty,
                inputKey: const Key('dedicated-request-name-input'),
                submitKey: const Key('dedicated-request-submit'),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: MandirTheme.cardBorder, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        lang,
                        en: 'Easy 3 Steps:',
                        hi: 'बस ३ आसान काम:',
                        mr: 'फक्त ३ सोप्या पायऱ्या:',
                      ),
                      style: GoogleFonts.mukta(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: MandirTheme.secondaryMaroon,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SimpleStep(
                      number: '1',
                      text: _t(
                        lang,
                        en: 'Type your God or Aarti name above.',
                        hi: 'ऊपर अपने भगवान या आरती का नाम लिखें।',
                        mr: 'वर तुमच्या देवाचे किंवा आरतीचे नाव लिहा.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SimpleStep(
                      number: '2',
                      text: _t(
                        lang,
                        en: 'Press the orange Send button.',
                        hi: 'नीचे "रिक्वेस्ट भेजें" बटन दबाएं।',
                        mr: 'खाली "विनंती पाठवा" बटण दाबा.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SimpleStep(
                      number: '3',
                      text: _t(
                        lang,
                        en: 'We will add it within 24 hours! 🙏',
                        hi: '२४ घंटे के अंदर आपको ऐप में मिल जाएगा! 🙏',
                        mr: '२४ तासांत तुम्हाला ॲपमध्ये मिळून जाईल! 🙏',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleStep extends StatelessWidget {
  const _SimpleStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: MandirTheme.secondaryMaroon,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: GoogleFonts.mukta(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.mukta(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: MandirTheme.textDark,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

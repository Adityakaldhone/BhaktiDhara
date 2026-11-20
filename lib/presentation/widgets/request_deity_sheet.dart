import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/theme/theme.dart';
import '../../services/backend_service.dart';

String _t(String lang, {required String en, required String hi, required String mr}) =>
    switch (lang) {
      'hi' => hi,
      'mr' => mr,
      _ => en,
    };

/// Bottom sheet for requesting a missing deity (name required; image + YouTube optional).
Future<void> showRequestDeitySheet(
  BuildContext context, {
  required String lang,
  String initialText = '',
  String source = 'unknown',
  VoidCallback? onSubmitted,
}) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _RequestDeitySheet(
      lang: lang,
      initialText: initialText,
      source: source,
      onSubmitted: onSubmitted,
    ),
  );
}

class _RequestDeitySheet extends StatefulWidget {
  const _RequestDeitySheet({
    required this.lang,
    required this.initialText,
    required this.source,
    this.onSubmitted,
  });

  final String lang;
  final String initialText;
  final String source;
  final VoidCallback? onSubmitted;

  @override
  State<_RequestDeitySheet> createState() => _RequestDeitySheetState();
}

class _RequestDeitySheetState extends State<_RequestDeitySheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _youtubeController;
  XFile? _image;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialText);
    _youtubeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file != null && mounted) setState(() => _image = file);
    } catch (_) {}
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _submitting) return;
    setState(() => _submitting = true);

    final youtube = _youtubeController.text.trim();
    final lang = widget.lang;
    final source = widget.source;

    try {
      await BackendService.submitDeityRequest(
        deityName: name,
        lang: lang,
        source: source,
        youtubeUrl: youtube,
        imagePath: _image?.path,
      );
    } catch (_) {
      // Still track locally if upload fails.
      BackendService.trackEvent(
        'deity_requested',
        item: name,
        props: {
          'deity_name': name,
          'source': source,
          'lang': lang,
          if (youtube.isNotEmpty) 'youtube_url': youtube,
          if (_image != null) 'has_image': true,
        },
      );
    }

    AnalyticsService.logCustomEvent(
      'deity_requested',
      parameters: {
        'deity_name': name,
        'source': source,
        'lang': lang,
      },
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    HapticFeedback.mediumImpact();
    widget.onSubmitted?.call();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: MandirTheme.secondaryMaroon,
          content: Text(
            _t(
              lang,
              en: '🙏 Request for "$name" received! We will add it within 24 hours.',
              hi: '🙏 "$name" का अनुरोध मिला! हम २४ घंटे में जोड़ देंगे।',
              mr: '🙏 "$name" ची विनंती मिळाली! आम्ही २४ तासांत जोडू.',
            ),
            style: GoogleFonts.mukta(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
  }

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.mukta(fontSize: 15, color: MandirTheme.textMuted),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: MandirTheme.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: MandirTheme.primarySaffron, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: MandirTheme.backgroundCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MandirTheme.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MandirTheme.primarySaffron.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.temple_hindu_rounded,
                      color: MandirTheme.secondaryMaroon,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t(
                            lang,
                            en: 'Can’t find your Deity / Kuldevta?',
                            hi: 'अपने इष्टदेव या कुलदेवता का नाम बताएं',
                            mr: 'आपले इष्टदेव किंवा कुलदैवत सांगा',
                          ),
                          style: GoogleFonts.mukta(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: MandirTheme.secondaryMaroon,
                          ),
                        ),
                        Text(
                          _t(
                            lang,
                            en: 'We will add your deity within 24 hours 🙏',
                            hi: 'हम २४ घंटे में यह देवता और आरती जोड़ देंगे 🙏',
                            mr: 'आम्ही २४ तासांत हे दैवत आणि आरती जोडू 🙏',
                          ),
                          style: GoogleFonts.mukta(fontSize: 13, color: MandirTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                autofocus: true,
                style: GoogleFonts.mukta(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: MandirTheme.textDark,
                ),
                decoration: _fieldDecoration(
                  hint: _t(
                    lang,
                    en: 'e.g. Tuljabhavani, Jyotiba, Banke Bihari...',
                    hi: 'उदा. माँ तुलजा भवानी, बांके बिहारी, जोतिबा...',
                    mr: 'उदा. तुळजाभवानी, जोतिबा, बांके बिहारी...',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _youtubeController,
                keyboardType: TextInputType.url,
                style: GoogleFonts.mukta(fontSize: 15, color: MandirTheme.textDark),
                decoration: _fieldDecoration(
                  hint: _t(
                    lang,
                    en: 'YouTube link (optional)',
                    hi: 'YouTube लिंक (वैकल्पिक)',
                    mr: 'YouTube लिंक (पर्यायी)',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _submitting ? null : _pickImage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: MandirTheme.secondaryMaroon,
                  side: BorderSide(color: MandirTheme.primarySaffron.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(
                  _image == null ? Icons.add_photo_alternate_outlined : Icons.check_circle_rounded,
                  size: 20,
                ),
                label: Text(
                  _image == null
                      ? _t(
                          lang,
                          en: 'Upload deity image (optional)',
                          hi: 'देवता की छवि अपलोड करें (वैकल्पिक)',
                          mr: 'दैवताचे चित्र अपलोड करा (पर्यायी)',
                        )
                      : _t(
                          lang,
                          en: 'Image selected — tap to change',
                          hi: 'छवि चुनी गई — बदलने के लिए टैप करें',
                          mr: 'चित्र निवडले — बदलण्यासाठी टॅप करा',
                        ),
                  style: GoogleFonts.mukta(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              if (_image != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_image!.path),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MandirTheme.primarySaffron,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(
                        _t(
                          lang,
                          en: 'Submit Request 🙏',
                          hi: 'अनुरोध भेजें 🙏',
                          mr: 'विनंती पाठवा 🙏',
                        ),
                        style: GoogleFonts.mukta(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

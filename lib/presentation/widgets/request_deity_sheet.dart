import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/theme.dart';
import 'request_deity_section.dart';

String _t(String lang, {required String en, required String hi, required String mr}) =>
    switch (lang) {
      'hi' => hi,
      'mr' => mr,
      _ => en,
    };

/// Bottom sheet for requesting a missing deity or aarti (name required; image + YouTube optional).
Future<void> showRequestDeitySheet(
  BuildContext context, {
  required String lang,
  String initialText = '',
  String source = 'unknown',
  DeityRequestKind initialKind = DeityRequestKind.deity,
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
      initialKind: initialKind,
      onSubmitted: onSubmitted,
    ),
  );
}

class _RequestDeitySheet extends StatefulWidget {
  const _RequestDeitySheet({
    required this.lang,
    required this.initialText,
    required this.source,
    required this.initialKind,
    this.onSubmitted,
  });

  final String lang;
  final String initialText;
  final String source;
  final DeityRequestKind initialKind;
  final VoidCallback? onSubmitted;

  @override
  State<_RequestDeitySheet> createState() => _RequestDeitySheetState();
}

class _RequestDeitySheetState extends State<_RequestDeitySheet> {
  late final TextEditingController _nameController;
  final TextEditingController _youtubeController = TextEditingController();
  XFile? _image;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialText);
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

    final lang = widget.lang;
    final source = widget.source;
    final kind = widget.initialKind;
    final rootNavContext = Navigator.of(context, rootNavigator: true).context;

    await submitDeityOrAartiRequest(
      name: name,
      kind: kind,
      lang: lang,
      source: source,
      youtubeUrl: _youtubeController.text,
      imagePath: _image?.path,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    HapticFeedback.mediumImpact();
    widget.onSubmitted?.call();

    if (rootNavContext.mounted) {
      await showRequestSentConfirmationDialog(
        rootNavContext,
        lang: lang,
        itemName: name,
        kind: kind,
      );
    }
  }

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.mukta(fontSize: 15.5, color: MandirTheme.textMuted),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: MandirTheme.goldenAccent, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: MandirTheme.goldenAccent, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: MandirTheme.primarySaffron, width: 2.2),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: MandirTheme.secondaryMaroon,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.temple_hindu_rounded,
                      color: Color(0xFFFFE082),
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
                            en: 'Add Your Deity or Aarti',
                            hi: 'नया देवता या आरती जोड़ें',
                            mr: 'नवीन देव किंवा आरती जोडा',
                          ),
                          style: GoogleFonts.mukta(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: MandirTheme.secondaryMaroon,
                          ),
                        ),
                        Text(
                          _t(
                            lang,
                            en: 'We will add it within 24 hours 🙏',
                            hi: 'हम २४ घंटे में जोड़ देंगे 🙏',
                            mr: 'आम्ही २४ तासांत जोडून देऊ 🙏',
                          ),
                          style: GoogleFonts.mukta(
                            fontSize: 14.5,
                            color: MandirTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _t(
                  lang,
                  en: 'Write God or Aarti Name:',
                  hi: 'भगवान या आरती का नाम लिखें:',
                  mr: 'देवाचे किंवा आरतीचे नाव लिहा:',
                ),
                style: GoogleFonts.mukta(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: MandirTheme.secondaryMaroon,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                autofocus: true,
                style: GoogleFonts.mukta(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: MandirTheme.textDark,
                ),
                decoration: _fieldDecoration(
                  hint: _t(
                    lang,
                    en: 'e.g. Tuljabhavani, Jyotiba...',
                    hi: 'जैसे: माँ तुळजाभवानी, जोतिबा...',
                    mr: 'उदा. तुळजाभवानी, जोतिबा...',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _t(
                  lang,
                  en: 'YouTube Video Link (Optional):',
                  hi: 'YouTube वीडियो लिंक (ज़रूरी नहीं):',
                  mr: 'YouTube व्हिडिओ लिंक (ऐच्छिक):',
                ),
                style: GoogleFonts.mukta(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: MandirTheme.secondaryMaroon,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _youtubeController,
                keyboardType: TextInputType.url,
                style: GoogleFonts.mukta(fontSize: 16, color: MandirTheme.textDark),
                decoration: _fieldDecoration(
                  hint: _t(
                    lang,
                    en: 'Paste YouTube link here (if you have one)',
                    hi: 'अगर YouTube लिंक हो तो यहाँ डालें...',
                    mr: 'YouTube लिंक असल्यास येथे पेस्ट करा...',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _submitting ? null : _pickImage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: MandirTheme.secondaryMaroon,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: MandirTheme.cardBorder, width: 1.3),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(
                  _image == null ? Icons.photo_camera_outlined : Icons.check_circle_rounded,
                  size: 22,
                ),
                label: Text(
                  _image == null
                      ? _t(
                          lang,
                          en: 'Attach Photo (Optional)',
                          hi: 'फोटो लगाएं (ज़रूरी नहीं)',
                          mr: 'फोटो जोडा (ऐच्छिक)',
                        )
                      : _t(
                          lang,
                          en: 'Photo Added — Tap to Change',
                          hi: 'फोटो लग गई — बदलने के लिए दबाएं',
                          mr: 'फोटो जोडला — बदलण्यासाठी दाबा',
                        ),
                  style: GoogleFonts.mukta(fontSize: 15, fontWeight: FontWeight.w700),
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
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MandirTheme.primarySaffron,
                    foregroundColor: Colors.white,
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
                            en: 'Send Request 🙏',
                            hi: 'अनुरोध भेजें 🙏',
                            mr: 'विनंती पाठवा 🙏',
                          ),
                          style: GoogleFonts.mukta(fontSize: 17, fontWeight: FontWeight.w700),
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

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/theme/theme.dart';
import '../../services/backend_service.dart';

const String _kSubmittedRequestsPrefsKey = 'submitted_deity_requests_v1';

enum DeityRequestKind { deity, aarti }

String _tr(String lang, {required String en, required String hi, required String mr}) =>
    switch (lang) {
      'hi' => hi,
      'mr' => mr,
      _ => en,
    };

/// Persisted summary of a devotee's submitted deity or aarti request.
class SubmittedDeityRequest {
  const SubmittedDeityRequest({
    required this.name,
    required this.kind,
    required this.submittedAtMs,
  });

  final String name;
  final DeityRequestKind kind;
  final int submittedAtMs;

  Map<String, dynamic> toJson() => {
        'name': name,
        'kind': kind.name,
        'ts': submittedAtMs,
      };

  static SubmittedDeityRequest? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final name = (raw['name'] ?? '').toString().trim();
    if (name.isEmpty) return null;
    final kindStr = (raw['kind'] ?? 'deity').toString();
    final ts = raw['ts'] is int ? raw['ts'] as int : 0;
    return SubmittedDeityRequest(
      name: name,
      kind: kindStr == 'aarti' ? DeityRequestKind.aarti : DeityRequestKind.deity,
      submittedAtMs: ts,
    );
  }
}

/// Loads locally recorded requests so devotees can see what they have already sent.
Future<List<SubmittedDeityRequest>> loadSubmittedRequests() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSubmittedRequestsPrefsKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .map(SubmittedDeityRequest.fromJson)
        .whereType<SubmittedDeityRequest>()
        .toList();
  } catch (_) {
    return const [];
  }
}

/// Sends a Deity or Aarti request to the backend, records analytics, and saves
/// a local confirmation entry in [SharedPreferences].
Future<List<SubmittedDeityRequest>> submitDeityOrAartiRequest({
  required String name,
  required DeityRequestKind kind,
  required String lang,
  required String source,
  String youtubeUrl = '',
  String? imagePath,
}) async {
  final cleanName = name.trim();
  final cleanYoutube = youtubeUrl.trim();
  final backendName = kind == DeityRequestKind.aarti ? '$cleanName (Aarti)' : cleanName;

  try {
    await BackendService.submitDeityRequest(
      deityName: backendName,
      lang: lang,
      source: source,
      youtubeUrl: cleanYoutube,
      imagePath: imagePath,
    );
  } catch (_) {
    BackendService.trackEvent(
      'deity_requested',
      item: backendName,
      props: {
        'deity_name': backendName,
        'kind': kind.name,
        'source': source,
        'lang': lang,
        if (cleanYoutube.isNotEmpty) 'youtube_url': cleanYoutube,
        if (imagePath != null && imagePath.isNotEmpty) 'has_image': true,
      },
    );
  }

  if (kind == DeityRequestKind.aarti) {
    BackendService.trackEvent(
      'aarti_requested',
      item: cleanName,
      props: {
        'query': cleanName,
        'source': source,
        'locale': lang,
      },
    );
  }

  AnalyticsService.logCustomEvent(
    kind == DeityRequestKind.aarti ? 'aarti_requested' : 'deity_requested',
    parameters: {
      'deity_name': cleanName,
      'kind': kind.name,
      'source': source,
      'lang': lang,
    },
  );

  final entry = SubmittedDeityRequest(
    name: cleanName,
    kind: kind,
    submittedAtMs: DateTime.now().millisecondsSinceEpoch,
  );
  final existing = await loadSubmittedRequests();
  final next = [
    entry,
    ...existing.where((e) => e.name.toLowerCase() != cleanName.toLowerCase()),
  ].take(6).toList();

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kSubmittedRequestsPrefsKey,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  } catch (_) {}

  return next;
}

/// Immediately shows a clear, large-type confirmation popup after submitting a
/// Deity or Aarti request.
Future<void> showRequestSentConfirmationDialog(
  BuildContext context, {
  required String lang,
  required String itemName,
  DeityRequestKind kind = DeityRequestKind.deity,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: MandirTheme.backgroundCream,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2E7D32),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              _tr(
                lang,
                en: 'Request Sent! 🙏',
                hi: 'आपकी विनती भेज दी गई है! 🙏',
                mr: 'तुमची विनंती पाठवली आहे! 🙏',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: MandirTheme.secondaryMaroon,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: MandirTheme.cardBorder, width: 1.3),
              ),
              child: Text(
                _tr(
                  lang,
                  en: 'We received "$itemName".\nIt will be added in 24 hours 🙏',
                  hi: '"$itemName" की रिक्वेस्ट हमें मिल गई है।\n२४ घंटे के अंदर ऐप में जोड़ कर मिल जाएगी। 🙏',
                  mr: '"$itemName" ची विनंती आम्हाला मिळाली आहे.\n२४ तासांत ॲपमध्ये जोडून मिळेल. 🙏',
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.mukta(
                  fontSize: 16.5,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: MandirTheme.textDark,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('request-sent-dialog-ok'),
                onPressed: () => Navigator.of(dialogCtx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MandirTheme.secondaryMaroon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _tr(lang, en: 'OK, Got it 🙏', hi: 'ठीक है 🙏', mr: 'ठीक आहे 🙏'),
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

/// Calm, large-type, single-input section designed specifically so devotees
/// aged 40+ can request any Deity or Aarti in two simple steps without confusion.
class DeityAartiRequestSection extends StatefulWidget {
  const DeityAartiRequestSection({
    super.key,
    required this.lang,
    required this.source,
    this.initialText = '',
    this.initialKind = DeityRequestKind.deity,
    this.allowPhotoUpload = false,
    this.autofocusName = false,
    this.inputKey,
    this.submitKey,
    this.onSubmitted,
  });

  final String lang;
  final String source;
  final String initialText;
  final DeityRequestKind initialKind;
  final bool allowPhotoUpload;
  final bool autofocusName;
  final Key? inputKey;
  final Key? submitKey;
  final VoidCallback? onSubmitted;

  @override
  State<DeityAartiRequestSection> createState() => _DeityAartiRequestSectionState();
}

class _DeityAartiRequestSectionState extends State<DeityAartiRequestSection> {
  late final TextEditingController _nameController;
  final TextEditingController _youtubeController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  XFile? _image;
  bool _submitting = false;
  bool _showEmptyError = false;
  SubmittedDeityRequest? _justSent;
  List<SubmittedDeityRequest> _history = const [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialText);
    _loadHistory();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _youtubeController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final items = await loadSubmittedRequests();
    if (!mounted) return;
    setState(() => _history = items);
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
    if (name.isEmpty) {
      setState(() => _showEmptyError = true);
      _nameFocusNode.requestFocus();
      return;
    }
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _showEmptyError = false;
    });

    final updatedHistory = await submitDeityOrAartiRequest(
      name: name,
      kind: widget.initialKind,
      lang: widget.lang,
      source: widget.source,
      youtubeUrl: _youtubeController.text,
      imagePath: _image?.path,
    );

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    _nameController.clear();
    _youtubeController.clear();
    setState(() {
      _submitting = false;
      _image = null;
      _history = updatedHistory;
      _justSent = SubmittedDeityRequest(
        name: name,
        kind: widget.initialKind,
        submittedAtMs: DateTime.now().millisecondsSinceEpoch,
      );
    });

    widget.onSubmitted?.call();

    await showRequestSentConfirmationDialog(
      context,
      lang: widget.lang,
      itemName: name,
      kind: widget.initialKind,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: MandirTheme.goldenAccent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: MandirTheme.secondaryMaroon,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.temple_hindu_rounded,
                  color: Color(0xFFFFE082),
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _tr(
                    lang,
                    en: 'Add Your Deity or Aarti',
                    hi: 'नया देवता या आरती जोड़ें',
                    mr: 'नवीन देव किंवा आरती जोडा',
                  ),
                  style: GoogleFonts.mukta(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: MandirTheme.secondaryMaroon,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _tr(
              lang,
              en: 'If your God or Aarti is not listed, write the name below. We will add it within 24 hours.',
              hi: 'अगर आपके भगवान या आरती नहीं मिल रहे, तो नीचे नाम लिखकर भेजें। हम २४ घंटे में जोड़ देंगे।',
              mr: 'तुमचा देव किंवा आरती सापडत नसेल, तर खाली नाव लिहून पाठवा. २४ तासांत जोडून मिळेल.',
            ),
            style: GoogleFonts.mukta(
              fontSize: 15,
              color: MandirTheme.textDark,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _tr(
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
            key: widget.inputKey,
            controller: _nameController,
            focusNode: _nameFocusNode,
            autofocus: widget.autofocusName,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_showEmptyError) setState(() => _showEmptyError = false);
            },
            onSubmitted: (_) => _submit(),
            style: GoogleFonts.mukta(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: MandirTheme.textDark,
            ),
            decoration: InputDecoration(
              hintText: _tr(
                lang,
                en: 'e.g. Tuljabhavani, Kalbhairav Aarti...',
                hi: 'जैसे: माँ तुळजाभवानी, जोतिबा आरती...',
                mr: 'उदा. तुळजाभवानी, काळभैरव आरती...',
              ),
              hintStyle: GoogleFonts.mukta(
                fontSize: 15.5,
                color: MandirTheme.textMuted,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _showEmptyError ? Colors.red.shade700 : MandirTheme.goldenAccent,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _showEmptyError ? Colors.red.shade700 : MandirTheme.goldenAccent,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: MandirTheme.primarySaffron, width: 2.2),
              ),
            ),
          ),
          if (_showEmptyError) ...[
            const SizedBox(height: 6),
            Text(
              _tr(
                lang,
                en: 'Please type a name above first 🙏',
                hi: 'कृपया पहले ऊपर नाम लिखें 🙏',
                mr: 'कृपया आधी वर नाव लिहा 🙏',
              ),
              style: GoogleFonts.mukta(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Colors.red.shade800,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            _tr(
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
            textInputAction: TextInputAction.done,
            style: GoogleFonts.mukta(
              fontSize: 16,
              color: MandirTheme.textDark,
            ),
            decoration: InputDecoration(
              hintText: _tr(
                lang,
                en: 'Paste YouTube link here (if you have one)',
                hi: 'अगर YouTube लिंक हो तो यहाँ डालें...',
                mr: 'YouTube लिंक असल्यास येथे पेस्ट करा...',
              ),
              hintStyle: GoogleFonts.mukta(
                fontSize: 14.5,
                color: MandirTheme.textMuted,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: MandirTheme.cardBorder, width: 1.4),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: MandirTheme.cardBorder, width: 1.4),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: MandirTheme.primarySaffron, width: 2),
              ),
            ),
          ),
          if (widget.allowPhotoUpload) ...[
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
                    ? _tr(
                        lang,
                        en: 'Attach Deity Photo (Optional)',
                        hi: 'भगवान की फोटो लगाएं (ज़रूरी नहीं)',
                        mr: 'देवाचा फोटो जोडा (ऐच्छिक)',
                      )
                    : _tr(
                        lang,
                        en: 'Photo Added — Tap to Change',
                        hi: 'फोटो लग गई — बदलने के लिए दबाएं',
                        mr: 'फोटो जोडला — बदलण्यासाठी दाबा',
                      ),
                style: GoogleFonts.mukta(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            if (_image != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_image!.path),
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              key: widget.submitKey,
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: MandirTheme.primarySaffron,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              icon: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(
                _tr(
                  lang,
                  en: 'Send Request (Added in 24h) 🙏',
                  hi: 'रिक्वेस्ट भेजें (२४ घंटे में जुड़ेगी) 🙏',
                  mr: 'विनंती पाठवा (२४ तासांत मिळेल) 🙏',
                ),
                style: GoogleFonts.mukta(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (_justSent != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF81C784), width: 1.2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _tr(
                        lang,
                        en: 'Request for "${_justSent!.name}" sent! Added within 24 hours. 🙏',
                        hi: '"${_justSent!.name}" की विनती भेज दी गई है! २४ घंटे के अंदर मिल जाएगी। 🙏',
                        mr: '"${_justSent!.name}" ची विनंती पाठवली आहे! २४ तासांत जोडली जाईल. 🙏',
                      ),
                      style: GoogleFonts.mukta(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B5E20),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              _tr(
                lang,
                en: 'Your Sent Requests:',
                hi: 'आपकी भेजी गई रिक्वेस्ट:',
                mr: 'तुम्ही पाठवलेल्या विनंत्या:',
              ),
              style: GoogleFonts.mukta(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MandirTheme.secondaryMaroon,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final req in _history.take(5))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: MandirTheme.goldenAccent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 6),
                        Text(
                          req.name,
                          style: GoogleFonts.mukta(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: MandirTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

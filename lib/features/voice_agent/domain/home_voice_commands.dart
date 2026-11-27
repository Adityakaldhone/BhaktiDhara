import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/aarti_providers.dart';
import 'mandir_voice_commands.dart';

/// Master release toggle for Bhakti AI voice assistant UI & wake-word listener.
/// Flip to `true` when ready to ship Bhakti AI.
const bool kEnableBhaktiAi = true;

/// Only the screen that was visible when listening began can handle a command.
/// [pendingAction] keeps the mic open for a follow-up (Mandir clarify turns).
typedef HomeVoiceReply = ({String text, VoidCallback? apply, String? pendingAction});

HomeVoiceReply voiceReply(
  String text, {
  VoidCallback? apply,
  String? pendingAction,
}) => (text: text, apply: apply, pendingAction: pendingAction);

typedef HomeVoiceHandler =
    HomeVoiceReply? Function(
      String transcript,
      String language, {
      HomeCommand? prediction,
    });

class HomeVoiceBinding {
  HomeVoiceHandler? homeHandler;
  HomeVoiceHandler? Function()? activeHandler;
  MandirVoiceHandler? mandirHandler;
  MandirVoiceHandler? Function()? activeMandirHandler;
}

final homeVoiceBindingProvider = Provider((ref) => HomeVoiceBinding());

sealed class HomeCommand {
  const HomeCommand();

  static HomeCommand? fromPrediction(dynamic data) {
    if (data is! Map) return null;
    switch (data['type']) {
      case 'read_home_region':
        return const ReadHomeRegion();
      case 'read_home_search':
        return const ReadHomeSearch();
      case 'search_home':
        final query = data['query'];
        return query is String && query.length <= 250
            ? SearchHome(query.trim())
            : null;
      case 'filter_home':
        if (data['region'] == 'all') return const FilterHome(null);
        for (final region in AartiRegion.values) {
          if (region.name == data['region']) return FilterHome(region);
        }
        return null;
      case 'open_home_result':
        final n = data['position'];
        final section = data['section'];
        if (n is int &&
            n > 0 &&
            n <= 10000 &&
            const {'all', 'books', 'aartis'}.contains(section)) {
          return OpenHomeResult(n, section as String);
        }
    }
    return null;
  }

  /// Limit the extra model request to utterances referring to Home controls.
  static bool mightReferToHome(String text) => RegExp(
    r'search|खाली|कोरी|shabd|का चुनाव|look up|look for|find|type in|typed|box|filter|region|state|selected|highlighted|gujarat|uttarakhand|rajasthan|result|list|first|second|third|fourth|fifth|entry|entries|listed|खोज|शोध|ढूंढ|ढूँढ|लिख|प्रदेश|राज्य|गुजरात|राजस्थान|उत्तराखंड|छाँट|निवड|पहिल|पहल|दूसर|दुसर|तीसर|तिसर|निकाल|क्रमांक|नंबर|dhund|shodh|pehl|pahil|dusr|doosr|tisr|number|ऊपर से|वरून|चौथ|पाँचव|पाचव|chauth|paanchv|नोंद|सूची|यादी',
    caseSensitive: false,
  ).hasMatch(text);

  static HomeCommand? parse(String transcript) {
    final text = transcript
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[.!?।]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceFirst(RegExp(r'^please '), '')
        .replaceFirst(RegExp(r' please$'), '');
    if (_all.hasMatch(text) ||
        text == 'फक्त एक राज्य नको सगळे प्रदेश दिसू देत') {
      return const FilterHome(null);
    }
    if (_cancelHome.hasMatch(text)) return const CancelHomeCommand();
    if (RegExp(
      r"(?:^| )(?:don't|don’t|never|not|mat|मत|नको|नहीं)(?: |$)| and then | और फिर | आणि मग ",
    ).hasMatch(text)) {
      return null;
    }
    if (_selectedRegion.hasMatch(text)) return const ReadHomeRegion();
    if (_searchText.hasMatch(text)) return const ReadHomeSearch();
    if (_clear.hasMatch(text)) return const SearchHome('');
    for (final region in AartiRegion.values) {
      final name = '(?:${region.name}|${region.nameHi})';
      if (RegExp(
        '^(?:(?:show|select|choose|filter by|switch to) (?:only )?$name(?: (?:aartis?|region|filter))?|$name(?: वाली| की| च्या|च्या| मधल्या| ki| chya| wale)?(?: आरती| aartis?)? (?:दिखाओ|दाखव|दाखवा|चुनो|निवडा|dikhao|dakhav))\$',
      ).hasMatch(text)) {
        return FilterHome(region);
      }
    }
    final ordinal = _result.firstMatch(text);
    if (ordinal != null) {
      final word = ordinal[1]!;
      final converted = word.replaceAllMapped(
        RegExp('[०-९]'),
        (m) => '${m[0]!.codeUnitAt(0) - 0x966}',
      );
      final position = int.tryParse(converted) ?? _ordinalWords[word];
      if (position == null) return null;
      final noun = ordinal[2];
      final section =
          const {'book', 'scripture', 'ग्रंथ', 'पोथी', 'किताब'}.contains(noun)
          ? 'books'
          : const {'aarti', 'आरती'}.contains(noun)
          ? 'aartis'
          : 'all';
      return OpenHomeResult(position, section);
    }
    // Let help questions about the search controls reach the app guide.
    if (RegExp(
          r'^(?:search|look up) (?:bar|box|field|text|mic|result|mein|madhle|madhla|madhe|मध्ये|में)(?: |$)',
        ).hasMatch(text) ||
        RegExp(
          r'(?:kaise|kase|kasa|kya|kyun|mhanje|कसे|कसा|काय|कैसे)(?: |$)',
        ).hasMatch(text)) {
      return null;
    }
    for (final pattern in _search) {
      final match = pattern.firstMatch(text);
      if (match != null) return SearchHome(match[1]!.trim());
    }
    return null;
  }

  // Consume explicit cancellations here so they cannot fall through to media navigation.
  static final _cancelHome = RegExp(
    r"(?:^| )(?:don't|don’t|do not|never) (?:open|bring up|show|read|select|switch)|"
    r"(?:मत (?:खोल|दिखा|चुन)|उघडू (?:नको|नका)|mat (?:khol|dikha)|ughadu nako)|"
    r"(?:leave|keep) .*(?:closed|alone|untouched|as it is)|रहने दो|रहने दे|राहू दे|rehne do|rahu de",
  );

  static final _selectedRegion = RegExp(
    r'^(?:which (?:state|region)(?: filter)? is (?:currently )?(?:selected|active)|what region am i viewing|कौन सा राज्य चुना है|कोणता प्रदेश निवडला आहे|kaunsa state selected hai)$',
  );
  static final _searchText = RegExp(
    r"^(?:what (?:am i searching for|is in (?:the|my) search (?:box|bar))|what.s my search query|खोज में क्या लिखा है|शोधपेटीत काय लिहिलं आहे|search box mein kya likha hai)$",
  );
  static final _clear = RegExp(
    r'^(?:clear (?:the |my )?(?:home )?search(?: box| bar)?|reset (?:the )?search|remove what i typed in the search bar|मैंने जो खोज में लिखा था वो मिटा दो|खोजने के लिए लिखा हुआ नाम हटा दो|शोधपेटीतलं नाव पुसून टाक|(?:खोज|शोध|search) (?:साफ करो|साफ करा|clear kar|clear karo|madhla text kadhun tak))$',
  );
  static final _all = RegExp(
    r'^(?:show (?:all regions|all states)(?: again)?|bring back the entries from all regions|change the region back to all|undo the region filter so i can see every state again|(?:clear|reset|remove) (?:the )?(?:region|state) filter|state filter hatao(?: sab states chahiye)?|सभी राज्य दिखाओ|सर्व प्रदेश दाखव|सगळे प्रदेश दाखवा)$',
  );
  static const _ordinalWords = {
    'first': 1,
    'second': 2,
    'third': 3,
    'fourth': 4,
    'fifth': 5,
    'पहला': 1,
    'पहली': 1,
    'पहिला': 1,
    'पहिली': 1,
    'दूसरा': 2,
    'दूसरी': 2,
    'दुसरा': 2,
    'दुसरी': 2,
    'तीसरा': 3,
    'तिसरा': 3,
    'pehla': 1,
    'dusra': 2,
    'dusri': 2,
    'tisra': 3,
  };
  static final _result = RegExp(
    '^(?:(?:open|read|show) (?:the )?|ती )?('
    '${_ordinalWords.keys.join("|")}|[0-9०-९]+)(?:st|nd|rd|th)? '
    r'(result|one|aarti|book|scripture|आरती|ग्रंथ|पोथी|किताब|निकाल|वाला|वाली|वाला रिजल्ट|result wala)(?: दिखाओ| खोलो| उघड| दाखव| kholo| dakhav)?$',
  );
  static final _search = [
    RegExp(r'^type (.+?) into the (?:home )?search (?:box|bar)$'),
    RegExp(r'^(?:search(?: for)?|look up|look for) (.+)$'),
    RegExp(r'^(.+?) (?:शोधा|शोध|ढूँढो|खोजो|search karo|search kar)$'),
  ];
}

class SearchHome extends HomeCommand {
  const SearchHome(this.query);
  final String query;
}

class FilterHome extends HomeCommand {
  const FilterHome(this.region);
  final AartiRegion? region;
}

class OpenHomeResult extends HomeCommand {
  const OpenHomeResult(this.position, this.section);
  final int position;
  final String section;
}

class ReadHomeRegion extends HomeCommand {
  const ReadHomeRegion();
}

class ReadHomeSearch extends HomeCommand {
  const ReadHomeSearch();
}

class HomeExplanation extends HomeCommand {
  const HomeExplanation(this.text);
  final String text;
}

class CancelHomeCommand extends HomeCommand {
  const CancelHomeCommand();
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/data/datasources/catalog.dart';
import 'package:nitya_aarti/presentation/providers/aarti_providers.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';

void main() {
  test('Search in English', () {
    final hanuman = kDevotionalCatalog.firstWhere((i) => i.id == 'hanuman_chalisa');
    expect(matchAartiSearch(hanuman, 'hanuman'), isTrue);
    expect(matchAartiSearch(hanuman, 'chalisa'), isTrue);
    expect(matchAartiSearch(hanuman, 'hariharan'), isTrue);
    expect(matchAartiSearch(hanuman, 'bajrangbali'), isTrue);
  });

  test('Search in Hindi (Devanagari)', () {
    final ganesh = kDevotionalCatalog.firstWhere((i) => i.id == 'ganesh_aarti');
    expect(matchAartiSearch(ganesh, 'गणेश'), isTrue);
    expect(matchAartiSearch(ganesh, 'सुखकर्ता'), isTrue);
    expect(matchAartiSearch(ganesh, 'आरती'), isTrue);
  });

  test('Search in Marathi', () {
    final ganesh = kDevotionalCatalog.firstWhere((i) => i.id == 'ganesh_aarti');
    expect(matchAartiSearch(ganesh, 'गणपती'), isTrue);
    expect(matchAartiSearch(ganesh, 'बाप्पा'), isTrue);

    final shiv = kDevotionalCatalog.firstWhere((i) => i.id == 'shiv_aarti');
    expect(matchAartiSearch(shiv, 'महादेव'), isTrue);
  });

  test('Search by lyric stanza transliteration and devanagari', () {
    final hanuman = kDevotionalCatalog.firstWhere((i) => i.id == 'hanuman_chalisa');
    expect(matchAartiSearch(hanuman, 'Saroj Raj'), isTrue);
    expect(matchAartiSearch(hanuman, 'पवन कुमार'), isTrue);
  });

  test('Device locale detection defaults gracefully', () {
    final locale = getInitialDeviceLocale();
    expect(['mr', 'hi', 'en'], contains(locale.languageCode));
  });
}

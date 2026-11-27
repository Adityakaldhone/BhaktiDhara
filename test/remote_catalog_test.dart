import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/data/datasources/catalog.dart';
import 'package:nitya_aarti/domain/entities/aarti_item.dart';
import 'package:nitya_aarti/domain/entities/bhakti_deity.dart';
import 'package:nitya_aarti/domain/entities/lyric_stanza.dart';
import 'package:nitya_aarti/domain/entities/remote_devotional_catalog.dart';

void main() {
  group('LyricStanza / AartiItem / BhaktiDeity JSON', () {
    test('parses aarti with lyrics', () {
      final aarti = AartiItem.fromJson({
        'id': 'hanuman_aarti_remote_1',
        'title': 'New Hanuman Aarti',
        'titleHi': 'नई हनुमान आरती',
        'deity': 'Lord Hanuman',
        'youtubeVideoId': 'abc123XYZ_',
        'durationText': '3:10',
        'tags': ['Aarti'],
        'lyrics': [
          {
            'startTimeMs': 0,
            'devanagari': 'जय हनुमान',
            'transliteration': 'Jai Hanuman',
          },
          {
            'startTimeMs': 20000,
            'devanagari': 'दूसरा कडवा',
            'transliteration': 'Doosra',
          },
        ],
      });

      expect(aarti.isValidRemote, isTrue);
      expect(aarti.lyrics, hasLength(2));
      expect(aarti.lyrics.first, isA<LyricStanza>());
      expect(aarti.toJson()['id'], 'hanuman_aarti_remote_1');
    });

    test('rejects incomplete aarti as invalid remote', () {
      final aarti = AartiItem.fromJson({
        'id': 'broken',
        'title': 'No video',
        'deity': 'Lord Hanuman',
        'lyrics': [
          {'startTimeMs': 0, 'devanagari': 'जय'},
        ],
      });
      expect(aarti.isValidRemote, isFalse);
    });

    test('parses deity with imageUrl', () {
      final deity = BhaktiDeity.fromJson({
        'key': 'Goddess Example',
        'nameEn': 'Example Mata',
        'nameHi': 'उदाहरण माता',
        'aliases': ['Example'],
        'imageUrl': 'https://cdn.example/mata.webp',
      });
      expect(deity.isValidRemote, isTrue);
      expect(deity.imageUrl, contains('cdn.example'));
      expect(deity.imageAsset, 'assets/bhakti/durga.webp');
    });
  });

  group('merge catalogs', () {
    test('local ids win; remote appends new aartis including Hanuman', () {
      const local = [
        AartiItem(
          id: 'hanuman_chalisa',
          title: 'Local Chalisa',
          deity: 'Lord Hanuman',
          singer: 'Local',
          youtubeVideoId: 'localVid',
          durationText: '9:00',
          lyrics: [
            LyricStanza(startTimeMs: 0, devanagari: 'जय', transliteration: 'Jai'),
          ],
          accentColorHex: '#E65100',
          deityEmoji: '🙏',
        ),
      ];
      final remote = [
        AartiItem.fromJson({
          'id': 'hanuman_chalisa',
          'title': 'Remote overwrite attempt',
          'deity': 'Lord Hanuman',
          'youtubeVideoId': 'remoteVid',
          'lyrics': [
            {'startTimeMs': 0, 'devanagari': 'रिमोट', 'transliteration': 'Remote'},
          ],
        }),
        AartiItem.fromJson({
          'id': 'hanuman_aarti_new_xyz',
          'title': 'New Hanuman Aarti',
          'deity': 'Lord Hanuman',
          'youtubeVideoId': 'newVid123',
          'lyrics': [
            {'startTimeMs': 0, 'devanagari': 'नई', 'transliteration': 'Nayi'},
          ],
        }),
      ];

      final merged = mergeAartiCatalogs(
        local,
        remote,
        aartiSort: const {'hanuman_aarti_new_xyz': 0},
      );
      expect(merged, hasLength(2));
      // Admin sort pin puts the remote aarti first.
      expect(merged.first.id, 'hanuman_aarti_new_xyz');
      expect(merged.last.title, 'Local Chalisa');
    });

    test('local deity keys win; remote adds new deities', () {
      const local = [
        BhaktiDeity(
          key: 'Lord Hanuman',
          nameEn: 'Hanuman',
          nameHi: 'हनुमान',
          nameMr: 'हनुमान',
          imageAsset: 'assets/bhakti/hanuman.webp',
        ),
      ];
      final remote = [
        BhaktiDeity.fromJson({
          'key': 'Lord Hanuman',
          'nameEn': 'Should Not Replace',
          'imageUrl': 'https://evil.example/h.webp',
        }),
        BhaktiDeity.fromJson({
          'key': 'Goddess New',
          'nameEn': 'New Mata',
          'nameHi': 'नई माता',
        }),
      ];

      final merged = mergeDeityCatalogs(local, remote);
      expect(merged, hasLength(2));
      expect(merged.first.nameEn, 'Hanuman');
      expect(merged.first.imageUrl, isEmpty);
      expect(merged.last.key, 'Goddess New');
    });

    test('RemoteDevotionalCatalog.fromJson drops invalid rows', () {
      final catalog = RemoteDevotionalCatalog.fromJson({
        'version': 'abc',
        'aartis': [
          {
            'id': 'ok',
            'title': 'Ok',
            'deity': 'Lord Hanuman',
            'youtubeVideoId': 'vid',
            'lyrics': [
              {'startTimeMs': 0, 'devanagari': 'जय'},
            ],
          },
          {'id': 'bad', 'title': 'No lyrics', 'deity': 'Lord Hanuman', 'youtubeVideoId': 'x'},
        ],
        'deities': [
          {'key': 'Goddess New', 'nameEn': 'New'},
          {'key': '', 'nameEn': 'Missing key'},
        ],
      });
      expect(catalog.version, 'abc');
      expect(catalog.aartis, hasLength(1));
      expect(catalog.deities, hasLength(1));
    });

    test('Lord Vishnu pins Om Jai Jagdish Hare at index 0 by default', () {
      final merged = mergeAartiCatalogs(kDevotionalCatalog, const []);
      final vishnu = merged.where((i) => i.deity == 'Lord Vishnu').toList();
      expect(vishnu, isNotEmpty);
      expect(vishnu.first.id, 'vishnu_om_jai_jagdish_hare');
    });
  });
}

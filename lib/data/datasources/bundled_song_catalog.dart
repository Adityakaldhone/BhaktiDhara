import '../../domain/entities/devotional_song_item.dart';
import 'balumama_songs_catalog.dart';
import 'chandra_songs_catalog.dart';
import 'datta_songs_catalog.dart';
import 'durga_songs_catalog.dart';
import 'ganesha_songs_catalog.dart';
import 'gayatri_songs_catalog.dart';
import 'gondavalekar_maharaj_songs_catalog.dart';
import 'hanuman_songs_catalog.dart';
import 'khandoba_songs_catalog.dart';
import 'khatushyam_songs_catalog.dart';
import 'krishna_songs_catalog.dart';
import 'lakshmi_songs_catalog.dart';
import 'mahakal_songs_catalog.dart';
import 'narmada_songs_catalog.dart';
import 'radha_songs_catalog.dart';
import 'rama_songs_catalog.dart';
import 'renuka_songs_catalog.dart';
import 'shiva_songs_catalog.dart';
import 'siddhanath_songs_catalog.dart';
import 'swami_samarth_songs_catalog.dart';
import 'venkatesh_songs_catalog.dart';
import 'vishnu_songs_catalog.dart';
import 'vitthal_songs_catalog.dart';

const bundledSongCollections = <String, List<DevotionalSongItem>>{
  'Sant Balumama': kBalumamaSongsCatalog,
  'Chandra Dev': kChandraSongsCatalog,
  'Lord Datta': kDattaSongsCatalog,
  'Goddess Durga': kDurgaSongsCatalog,
  'Lord Ganesha': kGaneshaSongsCatalog,
  'Goddess Gayatri': kGayatriSongsCatalog,
  'Gondavalekar Maharaj': kGondavalekarMaharajSongsCatalog,
  'Lord Hanuman': kHanumanSongsCatalog,
  'Lord Khandoba': kKhandobaSongsCatalog,
  'Khatu Shyam': kKhatuShyamSongsCatalog,
  'Lord Krishna': kKrishnaSongsCatalog,
  'Goddess Lakshmi': kLakshmiSongsCatalog,
  'Mahakal': kMahakalSongsCatalog,
  'Goddess Narmada': kNarmadaSongsCatalog,
  'Radha': kRadhaSongsCatalog,
  'Lord Rama': kRamaSongsCatalog,
  'Goddess Renuka Mata': kRenukaSongsCatalog,
  'Lord Shiva': kShivaSongsCatalog,
  'Lord Siddhanath': kSiddhanathSongsCatalog,
  'Swami Samarth': kSwamiSamarthSongsCatalog,
  'Lord Venkatesh': kVenkateshSongsCatalog,
  'Lord Vishnu': kVishnuSongsCatalog,
  'Lord Vitthal': kVitthalSongsCatalog,
};

typedef CatalogVideo = ({String deity, DevotionalSongItem song});

String normalizeVoiceTitle(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^\w\u0900-\u097f]+'), ' ')
    .replaceAll(RegExp(r'\b(?:a+r+ti|aarati)\b'), 'aarti')
    .trim();

Iterable<String> spokenSongTitles(DevotionalSongItem song) sync* {
  final short = song.song.replaceFirst(RegExp(r'\s*\([^()]+\)\s*$'), '');
  yield normalizeVoiceTitle(song.song);
  yield normalizeVoiceTitle(short);
  if (song.artist.isNotEmpty) {
    yield normalizeVoiceTitle('$short by ${song.artist}');
  }
}

final catalogVideosById = {
  for (final group in bundledSongCollections.entries)
    for (final song in group.value) song.id: (deity: group.key, song: song),
};

final catalogVideosByTitle = () {
  final index = <String, CatalogVideo>{};
  for (final video in catalogVideosById.values) {
    for (final title in spokenSongTitles(video.song)) {
      if (title.isNotEmpty) index.putIfAbsent(title, () => video);
    }
  }
  return index;
}();

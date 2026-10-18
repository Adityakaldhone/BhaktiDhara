import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/granth_repository.dart';
import '../../domain/entities/granth.dart';

final granthBooksProvider = FutureProvider.autoDispose<List<GranthBook>>((ref) async {
  return GranthRepository.instance.getBooks();
});

final granthChaptersProvider =
    FutureProvider.family.autoDispose<List<GranthChapter>, String>((ref, slug) async {
  return GranthRepository.instance.getChapters(slug);
});

typedef GranthChapterQuery = ({String slug, int chapterNum});

final granthChapterDetailProvider =
    FutureProvider.family.autoDispose<GranthChapterDetail?, GranthChapterQuery>(
        (ref, query) async {
  return GranthRepository.instance.getChapterDetail(query.slug, query.chapterNum);
});

/// Preferred reading font size for scripture verses
final granthFontSizeProvider = StateProvider<double>((ref) => 18.0);

/// Preferred scripture translation language ('mr', 'hi', 'en')
final granthTranslationLangProvider = StateProvider<String>((ref) => 'mr');

final granthPothiInfoProvider =
    FutureProvider.family.autoDispose<GranthPothiInfo?, String>((ref, slug) async {
  return GranthRepository.instance.getPothiInfo(slug);
});

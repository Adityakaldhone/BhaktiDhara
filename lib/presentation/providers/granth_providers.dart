import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// Represents the user's last read position across Granths (Gita, Dasbodh, Puranas)
class GranthLastReadRecord {
  final String bookSlug;
  final String bookTitle;
  final String? bookSubtitle;
  final int? chapterNumber;
  final String? chapterTitle;
  final int? verseNumber;
  final int? pageNumber;
  final String? pdfUrl;
  final bool isPothi;
  final int timestamp;

  const GranthLastReadRecord({
    required this.bookSlug,
    required this.bookTitle,
    this.bookSubtitle,
    this.chapterNumber,
    this.chapterTitle,
    this.verseNumber,
    this.pageNumber,
    this.pdfUrl,
    this.isPothi = false,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'bookSlug': bookSlug,
        'bookTitle': bookTitle,
        'bookSubtitle': bookSubtitle,
        'chapterNumber': chapterNumber,
        'chapterTitle': chapterTitle,
        'verseNumber': verseNumber,
        'pageNumber': pageNumber,
        'pdfUrl': pdfUrl,
        'isPothi': isPothi,
        'timestamp': timestamp,
      };

  factory GranthLastReadRecord.fromJson(Map<String, dynamic> json) =>
      GranthLastReadRecord(
        bookSlug: json['bookSlug']?.toString() ?? '',
        bookTitle: json['bookTitle']?.toString() ?? '',
        bookSubtitle: json['bookSubtitle']?.toString(),
        chapterNumber: json['chapterNumber'] as int?,
        chapterTitle: json['chapterTitle']?.toString(),
        verseNumber: json['verseNumber'] as int?,
        pageNumber: json['pageNumber'] as int?,
        pdfUrl: json['pdfUrl']?.toString(),
        isPothi: json['isPothi'] == true,
        timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      );
}

class GranthLastReadNotifier extends StateNotifier<GranthLastReadRecord?> {
  GranthLastReadNotifier() : super(null) {
    _load();
  }

  static const _prefKey = 'granth_last_read_v1';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefKey);
      if (str != null && str.isNotEmpty) {
        final decoded = json.decode(str) as Map<String, dynamic>;
        state = GranthLastReadRecord.fromJson(decoded);
      }
    } catch (_) {}
  }

  Future<void> save({
    required String bookSlug,
    required String bookTitle,
    String? bookSubtitle,
    int? chapterNumber,
    String? chapterTitle,
    int? verseNumber,
    int? pageNumber,
    String? pdfUrl,
    bool isPothi = false,
  }) async {
    final record = GranthLastReadRecord(
      bookSlug: bookSlug,
      bookTitle: bookTitle,
      bookSubtitle: bookSubtitle,
      chapterNumber: chapterNumber,
      chapterTitle: chapterTitle,
      verseNumber: verseNumber,
      pageNumber: pageNumber,
      pdfUrl: pdfUrl,
      isPothi: isPothi,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    state = record;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, json.encode(record.toJson()));
    } catch (_) {}
  }
}

final granthLastReadProvider =
    StateNotifierProvider<GranthLastReadNotifier, GranthLastReadRecord?>((ref) {
  return GranthLastReadNotifier();
});


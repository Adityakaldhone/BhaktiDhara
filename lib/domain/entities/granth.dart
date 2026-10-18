class GranthBook {
  final int id;
  final String slug;
  final Map<String, String> title;
  final Map<String, String> subtitle;
  final Map<String, String> description;
  final int totalChapters;
  final int totalVerses;
  final int freeChapters;
  final String? coverImage;
  final String? pdfUrl;
  final bool isActive;
  final bool isUnlocked;

  const GranthBook({
    required this.id,
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.totalChapters,
    required this.totalVerses,
    required this.freeChapters,
    this.coverImage,
    this.pdfUrl,
    required this.isActive,
    required this.isUnlocked,
  });

  String titleFor(String lang) =>
      title[lang] ?? title['mr'] ?? title['hi'] ?? title['en'] ?? '';

  String subtitleFor(String lang) =>
      subtitle[lang] ?? subtitle['mr'] ?? subtitle['hi'] ?? subtitle['en'] ?? '';

  String descriptionFor(String lang) =>
      description[lang] ?? description['mr'] ?? description['hi'] ?? description['en'] ?? '';

  factory GranthBook.fromJson(Map<String, dynamic> json) {
    Map<String, String> parseMap(dynamic v) {
      if (v is Map) {
        return v.map((k, val) => MapEntry(k.toString(), val?.toString() ?? ''));
      }
      return {};
    }

    return GranthBook(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      slug: json['slug']?.toString() ?? '',
      title: parseMap(json['title']),
      subtitle: parseMap(json['subtitle']),
      description: parseMap(json['description']),
      totalChapters: json['totalChapters'] is int ? json['totalChapters'] : 0,
      totalVerses: json['totalVerses'] is int ? json['totalVerses'] : 0,
      freeChapters: json['freeChapters'] is int ? json['freeChapters'] : 1,
      coverImage: json['coverImage']?.toString(),
      pdfUrl: json['pdfUrl']?.toString(),
      isActive: json['isActive'] == true,
      isUnlocked: json['isUnlocked'] == true,
    );
  }
}

class GranthChapter {
  final int id;
  final int chapterNumber;
  final Map<String, String> name;
  final Map<String, String> summary;
  final int versesCount;
  final bool isFree;
  final bool isUnlocked;

  const GranthChapter({
    required this.id,
    required this.chapterNumber,
    required this.name,
    required this.summary,
    required this.versesCount,
    required this.isFree,
    required this.isUnlocked,
  });

  String nameFor(String lang) =>
      name[lang] ?? name['mr'] ?? name['hi'] ?? name['sanskrit'] ?? name['en'] ?? '';

  String summaryFor(String lang) =>
      summary[lang] ?? summary['mr'] ?? summary['hi'] ?? summary['en'] ?? '';

  factory GranthChapter.fromJson(Map<String, dynamic> json) {
    Map<String, String> parseMap(dynamic v) {
      if (v is Map) {
        return v.map((k, val) => MapEntry(k.toString(), val?.toString() ?? ''));
      }
      return {};
    }

    return GranthChapter(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      chapterNumber: json['chapterNumber'] is int ? json['chapterNumber'] : 0,
      name: parseMap(json['name']),
      summary: parseMap(json['summary']),
      versesCount: json['versesCount'] is int ? json['versesCount'] : 0,
      isFree: json['isFree'] == true,
      isUnlocked: json['isUnlocked'] == true,
    );
  }
}

class GranthVerse {
  final int verseNumber;
  final String slok;
  final String transliteration;
  final String wordMeanings;
  final Map<String, String> meaning;

  const GranthVerse({
    required this.verseNumber,
    required this.slok,
    required this.transliteration,
    required this.wordMeanings,
    required this.meaning,
  });

  String meaningFor(String lang) =>
      meaning[lang] ?? meaning['mr'] ?? meaning['hi'] ?? meaning['en'] ?? '';

  factory GranthVerse.fromJson(Map<String, dynamic> json) {
    Map<String, String> parseMap(dynamic v) {
      if (v is Map) {
        return v.map((k, val) => MapEntry(k.toString(), val?.toString() ?? ''));
      }
      return {};
    }

    return GranthVerse(
      verseNumber: json['verseNumber'] is int ? json['verseNumber'] : 0,
      slok: json['slok']?.toString() ?? '',
      transliteration: json['transliteration']?.toString() ?? '',
      wordMeanings: json['wordMeanings']?.toString() ?? '',
      meaning: parseMap(json['meaning']),
    );
  }
}

class GranthChapterDetail {
  final String bookSlug;
  final Map<String, String> bookTitle;
  final int chapterNumber;
  final Map<String, String> chapterName;
  final Map<String, String> chapterSummary;
  final int totalVerses;
  final bool isFree;
  final bool isLocked;
  final bool isPremiumUser;
  final List<GranthVerse> verses;

  const GranthChapterDetail({
    required this.bookSlug,
    required this.bookTitle,
    required this.chapterNumber,
    required this.chapterName,
    required this.chapterSummary,
    required this.totalVerses,
    required this.isFree,
    required this.isLocked,
    required this.isPremiumUser,
    required this.verses,
  });

  String bookTitleFor(String lang) =>
      bookTitle[lang] ?? bookTitle['mr'] ?? bookTitle['hi'] ?? bookTitle['en'] ?? '';

  String chapterNameFor(String lang) =>
      chapterName[lang] ?? chapterName['mr'] ?? chapterName['hi'] ?? chapterName['sanskrit'] ?? '';

  String chapterSummaryFor(String lang) =>
      chapterSummary[lang] ?? chapterSummary['mr'] ?? chapterSummary['hi'] ?? chapterSummary['en'] ?? '';

  factory GranthChapterDetail.fromJson(Map<String, dynamic> json) {
    Map<String, String> parseMap(dynamic v) {
      if (v is Map) {
        return v.map((k, val) => MapEntry(k.toString(), val?.toString() ?? ''));
      }
      return {};
    }

    final rawVerses = json['verses'] as List? ?? [];
    return GranthChapterDetail(
      bookSlug: json['bookSlug']?.toString() ?? '',
      bookTitle: parseMap(json['bookTitle']),
      chapterNumber: json['chapterNumber'] is int ? json['chapterNumber'] : 0,
      chapterName: parseMap(json['chapterName']),
      chapterSummary: parseMap(json['chapterSummary']),
      totalVerses: json['totalVerses'] is int ? json['totalVerses'] : 0,
      isFree: json['isFree'] == true,
      isLocked: json['isLocked'] == true,
      isPremiumUser: json['isPremiumUser'] == true,
      verses: rawVerses
          .whereType<Map<String, dynamic>>()
          .map((v) => GranthVerse.fromJson(v))
          .toList(),
    );
  }
}

class GranthPothiSection {
  final String title;
  final int startPage;

  const GranthPothiSection({required this.title, required this.startPage});

  factory GranthPothiSection.fromJson(Map<String, dynamic> json) {
    return GranthPothiSection(
      title: json['title']?.toString() ?? '',
      startPage: json['startPage'] is int
          ? json['startPage']
          : int.tryParse('${json['startPage']}') ?? 1,
    );
  }
}

class GranthPothiInfo {
  final String bookSlug;
  final bool isPremiumUser;
  final Map<String, String> title;
  final Map<String, String> subtitle;
  final Map<String, String> description;
  final Map<String, String> attribution;
  final int totalPages;
  final int freePages;
  final List<GranthPothiSection> sections;

  const GranthPothiInfo({
    required this.bookSlug,
    required this.isPremiumUser,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.attribution,
    required this.totalPages,
    required this.freePages,
    required this.sections,
  });

  String titleFor(String lang) =>
      title[lang] ?? title['mr'] ?? title['hi'] ?? title['en'] ?? '';

  String subtitleFor(String lang) =>
      subtitle[lang] ?? subtitle['mr'] ?? subtitle['hi'] ?? subtitle['en'] ?? '';

  String descriptionFor(String lang) =>
      description[lang] ??
      description['mr'] ??
      description['hi'] ??
      description['en'] ??
      '';

  String attributionFor(String lang) =>
      attribution[lang] ??
      attribution['mr'] ??
      attribution['hi'] ??
      attribution['en'] ??
      '';

  factory GranthPothiInfo.fromJson(Map<String, dynamic> json) {
    Map<String, String> parseMap(dynamic v) {
      if (v is Map) {
        return v.map((k, val) => MapEntry(k.toString(), val?.toString() ?? ''));
      }
      return {};
    }

    final rawSections = json['sections'] as List? ?? [];
    return GranthPothiInfo(
      bookSlug: json['bookSlug']?.toString() ?? '',
      isPremiumUser: json['isPremiumUser'] == true,
      title: parseMap(json['title']),
      subtitle: parseMap(json['subtitle']),
      description: parseMap(json['description']),
      attribution: parseMap(json['attribution']),
      totalPages: json['totalPages'] is int ? json['totalPages'] : 0,
      freePages: json['freePages'] is int ? json['freePages'] : 638,
      sections: rawSections
          .whereType<Map<String, dynamic>>()
          .map((s) => GranthPothiSection.fromJson(s))
          .toList(),
    );
  }
}

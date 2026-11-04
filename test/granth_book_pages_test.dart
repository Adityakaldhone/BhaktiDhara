import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/domain/entities/granth.dart';

void main() {
  test('books with page images build zero-padded page URLs', () {
    final book = GranthBook.fromJson({
      'id': 1,
      'slug': 'vamana-purana',
      'title': {'en': 'Vamana'},
      'pdfUrl': 'https://cdn.example/puranas/vaman-puran.pdf',
      'pageCount': 196,
      'pagesBaseUrl': 'https://cdn.example/puranas/pages/vamana-purana',
      'isActive': true,
    });
    expect(book.hasPageImages, isTrue);
    expect(book.pageImageUrl(7), 'https://cdn.example/puranas/pages/vamana-purana/0007.webp');
    expect(book.pageImageUrl(196), endsWith('/0196.webp'));
  });

  test('books without page images fall back to the PDF', () {
    final book = GranthBook.fromJson({
      'id': 2,
      'slug': 'shiva-purana',
      'pdfUrl': 'https://cdn.example/puranas/shiv-puran.pdf',
      'pageCount': null,
      'pagesBaseUrl': null,
    });
    expect(book.hasPageImages, isFalse);
    expect(book.pageCount, 0);
  });
}

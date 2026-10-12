import 'package:akademihub_mob/core/config/app_config.dart';
import 'package:akademihub_mob/features/ujian/data/services/cbt_media_prefetch_service.dart';
import 'package:akademihub_mob/features/ujian/domain/entities/ujian_question_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CbtMediaPrefetchService', () {
    late CbtMediaPrefetchService service;
    late List<String> downloadedUrls;

    setUp(() {
      downloadedUrls = [];
      service = CbtMediaPrefetchService(
        customDownloader: (url) async {
          downloadedUrls.add(url);
        },
      );
    });

    test('extracts media URLs from mediaPath and embedded HTML/Markdown images', () {
      final origin = AppConfig.extractOrigin(AppConfig.apiBaseUrl)!;
      final questions = [
        const UjianQuestionEntity(
          id: 1,
          question:
              'Perhatikan gambar berikut <img src="/uploads/soal/q1.png"> apa yang terjadi?',
          type: 1,
          mediaPath: '/uploads/soal/header1.jpg',
          options: [
            UjianOptionEntity(
              id: 11,
              text: 'Opsi A ![](https://example.com/optA.png)',
            ),
            UjianOptionEntity(id: 12, text: 'Opsi B'),
          ],
        ),
        const UjianQuestionEntity(
          id: 2,
          question: 'Soal teks murni tanpa gambar',
          type: 2,
        ),
      ];

      final urls = service.extractImageUrls(questions);
      expect(urls, contains('$origin/uploads/soal/header1.jpg'));
      expect(urls, contains('$origin/uploads/soal/q1.png'));
      expect(urls, contains('https://example.com/optA.png'));
      expect(urls.length, 3);
    });

    test('prefetches all extracted images using custom downloader', () async {
      final questions = [
        const UjianQuestionEntity(
          id: 1,
          question: 'Soal 1',
          type: 1,
          mediaPath: 'https://example.com/pic1.jpg',
        ),
        const UjianQuestionEntity(
          id: 2,
          question: 'Soal 2',
          type: 1,
          mediaPath: 'https://example.com/pic2.jpg',
        ),
      ];

      final count = await service.prefetchImages(questions);
      expect(count, 2);
      expect(downloadedUrls, contains('https://example.com/pic1.jpg'));
      expect(downloadedUrls, contains('https://example.com/pic2.jpg'));
    });
  });
}

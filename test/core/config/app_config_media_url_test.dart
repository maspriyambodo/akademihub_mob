import 'package:akademihub_mob/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig.resolveMediaUrl', () {
    test('returns null for null or empty string', () {
      expect(AppConfig.resolveMediaUrl(null), isNull);
      expect(AppConfig.resolveMediaUrl(''), isNull);
      expect(AppConfig.resolveMediaUrl('   '), isNull);
    });

    test('preserves full http/https URLs', () {
      expect(
        AppConfig.resolveMediaUrl('https://cdn.school.org/images/q1.png'),
        'https://cdn.school.org/images/q1.png',
      );
      expect(
        AppConfig.resolveMediaUrl('http://insecure.site/soal/diagram.jpg'),
        'http://insecure.site/soal/diagram.jpg',
      );
    });

    test('prepends api base origin for relative paths', () {
      final origin = AppConfig.extractOrigin(AppConfig.apiBaseUrl)!;
      expect(
        AppConfig.resolveMediaUrl('/uploads/soal/question_1.png'),
        '$origin/uploads/soal/question_1.png',
      );
      expect(
        AppConfig.resolveMediaUrl('storage/soal/diagram.jpg'),
        '$origin/storage/soal/diagram.jpg',
      );
    });
  });
}

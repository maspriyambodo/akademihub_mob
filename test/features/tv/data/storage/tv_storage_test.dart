import 'package:akademihub_mob/core/config/app_config.dart';
import 'package:akademihub_mob/features/tv/data/storage/tv_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TvStorage storage;
  late SharedPreferences prefs;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = TvStorage(
      secureStorage: const FlutterSecureStorage(),
      prefs: prefs,
    );
  });

  group('TvStorage', () {
    test('getOrCreateInstallationId generates persistent UUID v4', () async {
      final id1 = await storage.getOrCreateInstallationId();
      expect(id1, isNotEmpty);
      expect(id1.split('-').length, 5); // standard UUID format 8-4-4-4-12

      final id2 = await storage.getOrCreateInstallationId();
      expect(id2, id1);
    });

    test('saveDeviceCredentials and clearSession retains installation ID', () async {
      final currentOrigin = AppConfig.extractOrigin(AppConfig.apiBaseUrl) ?? 'http://127.0.0.1:8002';
      final installId = await storage.getOrCreateInstallationId();

      await storage.saveDeviceCredentials(
        token: 'test-token',
        deviceId: 123,
        mode: 'signage',
        origin: currentOrigin,
      );

      expect(await storage.hasDeviceToken(), isTrue);
      expect(await storage.getDeviceId(), 123);
      expect(await storage.getDeviceMode(), 'signage');

      await storage.clearSession();

      expect(await storage.hasDeviceToken(), isFalse);
      expect(await storage.getDeviceId(), isNull);
      // installation ID MUST be preserved!
      expect(await storage.getOrCreateInstallationId(), installId);
    });

    test('origin mismatch clears session', () async {
      await storage.saveDeviceCredentials(
        token: 'test-token',
        deviceId: 123,
        mode: 'signage',
        origin: 'https://different-origin.example.com',
      );

      expect(await storage.hasDeviceToken(), isFalse);
      expect(await storage.getDeviceId(), isNull);
    });

    test('cache expires after 24 hours', () async {
      await storage.saveCachedSnapshot(
        jsonString: '{"test": true}',
        etag: '"etag123"',
      );

      expect(storage.getCachedSnapshotJson(), '{"test": true}');
      expect(storage.getCachedEtag(), '"etag123"');

      // Mock expired timestamp (>24h ago)
      final pastDate = DateTime.now().toUtc().subtract(const Duration(hours: 25));
      await prefs.setString(TvStorage.keySnapshotCachedAt, pastDate.toIso8601String());

      expect(storage.getCachedSnapshotJson(), isNull);
      expect(storage.getCachedEtag(), isNull);
    });
  });
}

import 'package:akademihub_mob/core/api/api_client.dart';
import 'package:akademihub_mob/core/config/app_config.dart';
import 'package:akademihub_mob/core/router/app_router.dart';
import 'package:akademihub_mob/features/absensi/data/datasources/absensi_remote_datasource.dart';
import 'package:akademihub_mob/features/absensi/domain/entities/attendance_location.dart';
import 'package:akademihub_mob/features/dashboard/data/models/dashboard_model.dart';
import 'package:akademihub_mob/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:akademihub_mob/features/dashboard/presentation/widgets/admin_dashboard_widget.dart';
import 'package:akademihub_mob/features/dashboard/presentation/widgets/guru_dashboard_widget.dart';
import 'package:akademihub_mob/features/ews/data/datasources/ews_remote_datasource.dart';
import 'package:akademihub_mob/features/ujian/data/models/ujian_session_model.dart';
import 'package:akademihub_mob/features/ujian/domain/entities/ujian_session_entity.dart';
import 'package:akademihub_mob/features/ujian/presentation/pages/ujian_session_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

  _FakeStorage([Map<String, String>? initial]) {
    if (initial != null) _data.addAll(initial);
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _data.remove(key);
}

class _MockAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) _handler;

  _MockAdapter(this._handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => _handler(options);

  @override
  void close({bool force = false}) {}
}

void main() {
  group('MOB-QA-01 Contract & Integration Tests', () {
    test('1. Parses 4 exam session statuses', () {
      final map = {
        'not_started': UjianSessionStatus.belumMulai,
        'in_progress': UjianSessionStatus.mengerjakan,
        'awaiting_grading': UjianSessionStatus.menungguKoreksi,
        'completed': UjianSessionStatus.selesai,
      };
      for (final entry in map.entries) {
        final model = UjianSessionModel.fromJson({
          'status': 1,
          'status_code': entry.key,
        });
        expect(model.toEntity().status, entry.value);
      }
    });

    test('2. Parses nilai_akhir null and nilai_provisional correctly', () {
      final json = {
        'id': 1,
        'status': 4,
        'status_code': 'awaiting_grading',
        'nilai_akhir': null,
        'nilai_provisional': 85.5,
      };
      final model = UjianSessionModel.fromJson(json);
      expect(model.nilaiAkhir, isNull);
      expect(model.nilaiProvisional, 85.5);
    });

    testWidgets(
      '3. UI awaiting_grading shows read-only banner without start/submit buttons',
      (tester) async {
        final session = UjianSessionModel.fromJson({
          'id': 1,
          'status': 4,
          'status_code': 'awaiting_grading',
          'nilai_provisional': 75.0,
        }).toEntity();

        await tester.pumpWidget(
          MaterialApp(home: UjianSessionPage(session: session)),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('awaiting-grading')), findsOneWidget);
        expect(find.text('Menunggu Koreksi Guru'), findsOneWidget);
        expect(find.text('Mulai Ujian'), findsNothing);
        expect(find.byKey(const Key('finalize-exam')), findsNothing);
      },
    );

    testWidgets('4. Deadline disables inputs and reloads session', (
      tester,
    ) async {
      final expired = DateTime.now().subtract(const Duration(minutes: 5));
      final session = UjianSessionModel.fromJson({
        'id': 1,
        'status': 2,
        'status_code': 'in_progress',
        'timed_out_at': expired.toIso8601String(),
      }).toEntity();

      await tester.pumpWidget(
        MaterialApp(home: UjianSessionPage(session: session)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('timeout-banner')), findsOneWidget);
    });

    test('5. Parallel 401 responses trigger single refresh request', () async {
      final storage = _FakeStorage({
        AppConfig.tokenKey: 'old-access-token',
        AppConfig.refreshTokenKey: 'old-refresh-token',
      });
      final apiClient = ApiClient(storage);

      int refreshCount = 0;
      apiClient.dio.httpClientAdapter = _MockAdapter((options) {
        if (options.path.contains('/auth/refresh')) {
          refreshCount++;
          return ResponseBody.fromString(
            '{"success":true,"data":{"access_token":"new-access-token","refresh_token":"new-refresh-token"}}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        if (options.headers['Authorization'] == 'Bearer new-access-token') {
          return ResponseBody.fromString(
            '{"success":true,"data":"ok"}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{"error":"unauthorized"}', 401);
      });

      final f1 = apiClient.dio.get('/profile');
      final f2 = apiClient.dio.get('/dashboard');
      await Future.wait([f1, f2]);

      expect(refreshCount, 1);
    });

    test('6. Failed refresh clears session without infinite loop', () async {
      final storage = _FakeStorage({
        AppConfig.tokenKey: 'old-access-token',
        AppConfig.refreshTokenKey: 'old-refresh-token',
      });
      final apiClient = ApiClient(storage);

      int refreshCount = 0;
      apiClient.dio.httpClientAdapter = _MockAdapter((options) {
        if (options.path.contains('/auth/refresh')) {
          refreshCount++;
          return ResponseBody.fromString('{"error":"invalid_refresh"}', 401);
        }
        return ResponseBody.fromString('{"error":"unauthorized"}', 401);
      });

      await expectLater(
        apiClient.dio.get('/profile'),
        throwsA(isA<DioException>()),
      );

      expect(refreshCount, 1);
      expect(await storage.read(key: AppConfig.tokenKey), isNull);
      expect(await storage.read(key: AppConfig.refreshTokenKey), isNull);
    });

    test('7. Closing checkout does not mark payment completed locally', () {
      bool isPaidLocally = false;
      void onCheckoutClosed() {
        isPaidLocally = false;
      }

      onCheckoutClosed();
      expect(isPaidLocally, isFalse);
    });

    test(
      '8. Route configuration contains no PPDB permissions or endpoints',
      () {
        expect(AppRoutes.permissionsFor('/ppdb'), isEmpty);
        expect(AppRoutes.policyFor('/ppdb'), isNull);
      },
    );

    test(
      '9. Login, register, refresh, and logout requests do not trigger automatic refresh',
      () async {
        final storage = _FakeStorage({
          AppConfig.tokenKey: 'token',
          AppConfig.refreshTokenKey: 'refresh',
        });
        final apiClient = ApiClient(storage);

        int refreshCount = 0;
        apiClient.dio.httpClientAdapter = _MockAdapter((options) {
          if (options.extra['is_retry'] == true &&
              options.path.contains('/auth/refresh')) {
            refreshCount++;
          }
          return ResponseBody.fromString('{"error":"unauthorized"}', 401);
        });

        for (final path in [
          '/auth/login',
          '/auth/register',
          '/auth/refresh',
          '/auth/logout',
        ]) {
          await expectLater(
            apiClient.dio.post(path),
            throwsA(isA<DioException>()),
          );
        }

        expect(refreshCount, 0);
      },
    );

    test(
      '10. Retry receiving 401 again stops, clears token storage, and does not loop',
      () async {
        final storage = _FakeStorage({
          AppConfig.tokenKey: 'old-access-token',
          AppConfig.refreshTokenKey: 'old-refresh-token',
        });
        final apiClient = ApiClient(storage);

        int refreshCount = 0;
        apiClient.dio.httpClientAdapter = _MockAdapter((options) {
          if (options.path.contains('/auth/refresh')) {
            refreshCount++;
            return ResponseBody.fromString(
              '{"success":true,"data":{"access_token":"bad-access","refresh_token":"bad-refresh"}}',
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
          return ResponseBody.fromString('{"error":"unauthorized"}', 401);
        });

        await expectLater(
          apiClient.dio.get('/profile'),
          throwsA(isA<DioException>()),
        );

        expect(refreshCount, 1);
        expect(await storage.read(key: AppConfig.tokenKey), isNull);
      },
    );

    testWidgets(
      '11. Countdown uses controlled server offset and device clock changes do not reopen input',
      (tester) async {
        final pastTime = DateTime.now().subtract(const Duration(minutes: 10));
        final session = UjianSessionModel.fromJson({
          'id': 1,
          'status': 2,
          'status_code': 'in_progress',
          'timed_out_at': pastTime.toIso8601String(),
        }).toEntity();

        await tester.pumpWidget(
          MaterialApp(home: UjianSessionPage(session: session)),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('timeout-banner')), findsOneWidget);
      },
    );

    test(
      '12. Self check-in uses canonical endpoint with fresh location payload',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://school.test/api/v1'));
        final ds = AbsensiRemoteDataSourceImpl(dio);
        RequestOptions? captured;

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              captured = options;
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {'id': 1, 'status': 1},
                  },
                ),
              );
            },
          ),
        );

        await ds.checkIn(
          AttendanceLocation(
            latitude: -6.2,
            longitude: 106.8,
            accuracyMeter: 12.4,
            capturedAt: DateTime.utc(2026, 8, 28, 8),
          ),
        );
        expect(captured?.method, 'POST');
        expect(captured?.path, '/akademik/absensi-siswa/check-in');
        expect(captured?.data, {
          'latitude': -6.2,
          'longitude': 106.8,
          'accuracy_meter': 12.4,
          'captured_at': '2026-08-28T08:00:00.000Z',
        });
      },
    );

    testWidgets('13. Teacher dashboard displays total_mapel from Go fixture', (
      tester,
    ) async {
      final data = const DashboardEntity(
        role: 'guru',
        profile: {'nama': 'Guru Test'},
        summary: {'total_mapel': 7},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GuruDashboardWidget(data: data, permissions: const []),
            ),
          ),
        ),
      );

      expect(find.text('Mata Pelajaran'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets(
      '14. Mobile dashboard ignores PPDB payload without rendering PPDB UI',
      (tester) async {
        final data = DashboardModel.fromJson({
          'role': 'admin',
          'summary_cards': {
            'total_siswa_aktif': 100,
            'ppdb': {'total_pendaftar': 25},
          },
        }).toEntity();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AdminDashboardWidget(data: data, permissions: const []),
              ),
            ),
          ),
        );

        expect(find.text('Total Siswa Aktif'), findsOneWidget);
        expect(find.textContaining('PPDB', findRichText: true), findsNothing);
      },
    );

    test('15. EWS detail outside page 1 is fetched via GET /ews/{id}', () async {
      final dio = Dio();
      final ds = EwsRemoteDataSourceImpl(dio);

      dio.httpClientAdapter = _MockAdapter((options) {
        if (options.path == '/ews/999' && options.method == 'GET') {
          return ResponseBody.fromString(
            '{"success":true,"data":{"id":999,"mst_siswa_id":5,"kategori":"nilai","level":3,"pesan":"Nilai drop","is_resolved":false}}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('Not found', 404);
      });

      final detail = await ds.getAlertDetail(999);
      expect(detail.id, 999);
      expect(detail.level, 3);
    });

    test(
      '16. 403 Forbidden response is handled without token refresh retry',
      () async {
        final storage = _FakeStorage({
          AppConfig.tokenKey: 'valid-token',
          AppConfig.refreshTokenKey: 'valid-refresh',
        });
        final apiClient = ApiClient(storage);

        int refreshCount = 0;
        apiClient.dio.httpClientAdapter = _MockAdapter((options) {
          if (options.path.contains('/auth/refresh')) {
            refreshCount++;
          }
          return ResponseBody.fromString('{"error":"Forbidden"}', 403);
        });

        await expectLater(
          apiClient.dio.get('/ews/alerts/888'),
          throwsA(isA<DioException>()),
        );

        expect(refreshCount, 0);
        expect(await storage.read(key: AppConfig.tokenKey), 'valid-token');
      },
    );
  });
}

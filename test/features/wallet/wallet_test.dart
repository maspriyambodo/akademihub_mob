import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akademihub_mob/core/router/app_router.dart';
import 'package:akademihub_mob/features/auth/data/models/user_model.dart';
import 'package:akademihub_mob/features/wallet/data/wallet_repository.dart';
import 'package:akademihub_mob/features/wallet/presentation/wallet_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('integer money validates zero, overflow and decimal input', () {
    expect(walletAmount('9000000000000'), 9000000000000);
    expect(walletAmount('0', zero: true), 0);
    for (final value in ['0', '-1', '1.2', '1,000', '9000000000001', '']) {
      expect(() => walletAmount(value), throwsFormatException);
    }
  });

  test('QR only extracts public token; rejects arbitrary payloads', () {
    final token = List.filled(48, 'a').join();
    expect(walletToken(token), token);
    expect(walletToken('https://school.example/wallet/pay/$token'), token);
    for (final value in [
      'javascript:alert(1)',
      'http://school.example/$token',
      'https://school.example/$token?pay=1',
      'https://school.example/other/$token',
      'https://school.example/wallet/pay/$token/',
      'random',
    ]) {
      expect(() => walletToken(value), throwsFormatException);
    }
  });

  test('roles preserve identity without inventing permissions', () {
    for (final role in [
      'staff',
      'staff_keuangan',
      'staff_perpustakaan',
      'admin_ppdb',
    ]) {
      final model = UserModel(id: 1, name: 'Test', email: 'a@b.c', role: role);
      expect(model.normalizedRole, 'staff');
      expect(model.permissions, isEmpty);
    }
    expect(
      const UserModel(
        id: 1,
        name: 'Test',
        email: 'a@b.c',
        role: 'pedagang',
      ).normalizedRole,
      'pedagang',
    );
    expect(
      const UserModel(
        id: 1,
        name: 'Test',
        email: 'a@b.c',
        role: 'other',
      ).normalizedRole,
      'unknown',
    );
    for (final role in ['siswa', 'wali', 'pedagang']) {
      expect(
        AppRoutes.canAccess('/wallet', authenticated: true, role: role),
        isTrue,
      );
    }
    for (final role in ['unknown', 'staff', 'admin', 'guru']) {
      expect(
        AppRoutes.canAccess('/wallet', authenticated: true, role: role),
        isFalse,
      );
    }
    expect(
      AppRoutes.canAccess(
        '/wallet',
        authenticated: true,
        permissions: ['wallet.cash-topup'],
      ),
      isTrue,
    );
    expect(
      AppRoutes.canAccess('/wallet', authenticated: false, role: 'pedagang'),
      isFalse,
    );
  });

  test('pagination supports merchant arrays and Laravel nested pages', () {
    expect(
      WalletPageData.parse([
        {'id': 1},
      ]).lastPage,
      1,
    );
    final page = WalletPageData.parse({
      'data': [
        {'id': 8},
      ],
      'current_page': 2,
      'last_page': 3,
    });
    expect(page.rows.single['id'], 8);
    expect(page.page, 2);
    expect(page.lastPage, 3);
  });

  test(
    'feature off releases unposted intent; conflict retains recovery key',
    () async {
      final dio = Dio();
      var message = 'WALLET_DISABLED';
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) {
            h.reject(
              DioException(
                requestOptions: r,
                response: Response(
                  requestOptions: r,
                  statusCode: message == 'WALLET_DISABLED' ? 503 : 409,
                  data: {'message': message},
                ),
              ),
            );
          },
        ),
      );
      final repo = WalletRepository(
        dio,
        const FlutterSecureStorage(),
        'disabled',
      );
      var op = await repo.prepare('payments', {'amount': 1});
      await expectLater(repo.submit(op), throwsA(isA<DioException>()));
      expect(await repo.pending(), isNull);
      message = 'IDEMPOTENCY_CONFLICT';
      op = await repo.prepare('payments', {'amount': 1});
      await expectLater(repo.submit(op), throwsA(isA<DioException>()));
      expect(await repo.pending(), isNotNull);
    },
  );

  test(
    'timeout retains same key across repository recreation, no PIN persisted',
    () async {
      final dio = Dio();
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            if (requests.length == 1) {
              handler.reject(
                DioException(
                  requestOptions: request,
                  type: DioExceptionType.receiveTimeout,
                ),
              );
            } else {
              handler.resolve(
                Response(
                  requestOptions: request,
                  data: {
                    'success': true,
                    'data': {'id': 'receipt', 'kind': 'payment'},
                  },
                ),
              );
            }
          },
        ),
      );
      const storage = FlutterSecureStorage();
      final repo = WalletRepository(dio, storage, 'school_user');
      final op = await repo.prepare('payments', {
        'qr_token': 'a' * 48,
        'amount': 500,
      });
      await expectLater(
        repo.submit(op, secrets: {'pin': '123456'}),
        throwsA(isA<DioException>()),
      );
      final restored = WalletRepository(dio, storage, 'school_user');
      final pending = (await restored.pending())!;
      expect(jsonEncode(pending), isNot(contains('123456')));
      await expectLater(
        restored.prepare('payments', {'amount': 500}),
        throwsFormatException,
      );
      await restored.submit(pending, secrets: {'pin': '123456'});
      expect(
        requests.first.data['idempotency_key'],
        requests.last.data['idempotency_key'],
      );
      expect(requests.last.data['amount'], isA<int>());
      expect(await restored.pending(), isNull);
      expect(
        await WalletRepository(dio, storage, 'other_user').pending(),
        isNull,
      );
    },
  );

  test(
    'account endpoint uses supplied student ID and envelope unwraps',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) {
            expect(r.path, '/wallet/accounts/17');
            h.resolve(
              Response(
                requestOptions: r,
                data: {
                  'success': true,
                  'data': {
                    'id': 900,
                    'owner_id': 17,
                    'student': {'id': 17},
                  },
                },
              ),
            );
          },
        ),
      );
      final result = await WalletRepository(
        dio,
        const FlutterSecureStorage(),
        'x',
      ).request('accounts/17');
      expect(result['id'], 900);
      expect(result['student']['id'], 17);
    },
  );

  testWidgets('PIN masked, invalid amount blocked, compact form scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: WalletForm(
          title: 'Bayar',
          fields: [
            WalletField('amount', 'Nominal', amount: true),
            WalletField('pin', 'PIN', secret: true, pin: true),
          ],
        ),
      ),
    );
    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields.length, 2);
    expect(
      tester
          .widgetList<EditableText>(find.byType(EditableText))
          .last
          .obscureText,
      isTrue,
    );
    await tester.enterText(find.byType(TextFormField).first, '1.5');
    await tester.enterText(find.byType(TextFormField).last, '123');
    await tester.tap(find.text('Lanjutkan'));
    await tester.pump();
    expect(find.text('PIN harus 6 digit.'), findsOneWidget);
    expect(find.text('Masukkan rupiah bulat tanpa pemisah.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef WalletRecord = Map<String, dynamic>;

const walletPermissions = [
  'wallet.view-all',
  'wallet.cash-topup',
  'wallet.manage-merchants',
  'wallet.process-payout',
  'wallet.reset-pin',
  'wallet.handle-cases',
];

bool walletAccess(String? role, Iterable<String> permissions) =>
    {'siswa', 'wali', 'pedagang'}.contains(role) ||
    walletPermissions.any(permissions.contains);

int walletAmount(String text, {bool zero = false}) {
  if (!RegExp(r'^\d+$').hasMatch(text)) {
    throw const FormatException('Masukkan rupiah bulat tanpa pemisah.');
  }
  final value = int.tryParse(text);
  if (value == null || value < (zero ? 0 : 1) || value > 9000000000000) {
    throw const FormatException('Nominal di luar batas yang diizinkan.');
  }
  return value;
}

String walletToken(String text) {
  var token = text.trim();
  final uri = Uri.tryParse(token);
  if (uri != null && uri.hasScheme) {
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !RegExp(r'^/wallet/pay/[a-f0-9]{48}$').hasMatch(uri.path)) {
      throw const FormatException('QR tidak valid.');
    }
    // Only the token is sent to our API. Scanned URLs are never opened.
    token = uri.pathSegments.last;
  }
  if (!RegExp(r'^[a-f0-9]{48}$').hasMatch(token)) {
    throw const FormatException('Kode QR pedagang tidak valid.');
  }
  return token;
}

class WalletPageData {
  final List<WalletRecord> rows;
  final int page;
  final int lastPage;
  const WalletPageData(this.rows, this.page, this.lastPage);
  factory WalletPageData.parse(dynamic data) {
    final rows = data is List ? data : data['data'];
    if (rows is! List) throw const FormatException('Daftar saldo tidak valid.');
    return WalletPageData(
      rows.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      data is Map ? (data['current_page'] as num).toInt() : 1,
      data is Map ? (data['last_page'] as num).toInt() : 1,
    );
  }
}

class WalletRepository {
  final Dio dio;
  final FlutterSecureStorage storage;
  final String scope;
  WalletRepository(this.dio, this.storage, this.scope);

  Future<dynamic> request(
    String path, {
    String method = 'GET',
    WalletRecord? data,
    WalletRecord? query,
  }) async {
    final response = await dio.request<dynamic>(
      '/wallet/$path',
      data: data,
      queryParameters: query,
      options: Options(method: method),
    );
    final body = response.data;
    if (body is! Map || body['success'] != true || body['data'] == null) {
      throw const FormatException('Respons saldo tidak valid.');
    }
    return body['data'];
  }

  Future<WalletPageData> list(
    String path, {
    int page = 1,
    WalletRecord? query,
  }) async => WalletPageData.parse(
    await request(path, query: {...?query, 'page': page}),
  );

  String get _pendingKey => 'wallet_pending_$scope';
  Future<WalletRecord?> pending() async {
    final raw = await storage.read(key: _pendingKey);
    return raw == null ? null : Map<String, dynamic>.from(jsonDecode(raw));
  }

  // Persist before sending; never persist a PIN or password.
  Future<WalletRecord> prepare(String path, WalletRecord payload) async {
    if (await pending() != null) {
      throw const FormatException(
        'Selesaikan transaksi tertunda terlebih dahulu.',
      );
    }
    final bytes = List.generate(24, (_) => Random.secure().nextInt(256));
    final operation = <String, dynamic>{
      'path': path,
      'data': {...payload, 'idempotency_key': base64Url.encode(bytes)},
    };
    await storage.write(key: _pendingKey, value: jsonEncode(operation));
    return operation;
  }

  Future<WalletRecord> submit(
    WalletRecord operation, {
    WalletRecord secrets = const {},
  }) async {
    try {
      final result = Map<String, dynamic>.from(
        await request(
          operation['path'] as String,
          method: 'POST',
          data: {...Map<String, dynamic>.from(operation['data']), ...secrets},
        ),
      );
      if (operation['path'] == 'topups') {
        await storage.write(
          key: 'wallet_topup_$scope',
          value: result['id'] as String,
        );
      }
      await storage.delete(key: _pendingKey);
      return result;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data;
      final message = body is Map ? body['message'] : null;
      if (message != 'IDEMPOTENCY_CONFLICT' &&
          ((code != null && {400, 403, 404, 409, 422, 429}.contains(code)) ||
              message == 'WALLET_DISABLED')) {
        await storage.delete(key: _pendingKey);
      }
      rethrow;
    }
  }

  Future<String?> lastTopup() => storage.read(key: 'wallet_topup_$scope');
}

String walletError(Object error) {
  if (error is FormatException) return error.message;
  if (error is DioException) {
    if (error.response?.statusCode == 401) {
      return 'Sesi berakhir. Masuk kembali sebelum mencoba ulang.';
    }
    final body = error.response?.data;
    final message = body is Map ? '${body['message'] ?? ''}' : '';
    return switch (message) {
      'WALLET_DISABLED' =>
        'Saldo kantin belum aktif. Riwayat tetap dapat dilihat.',
      'STALE_LIMIT_VERSION' =>
        'Batas diubah wali lain. Muat ulang sebelum menyimpan.',
      'INSUFFICIENT_BALANCE' => 'Saldo tersedia tidak cukup.',
      'DAILY_LIMIT_EXCEEDED' => 'Nominal melebihi sisa batas harian.',
      'ACCOUNT_FROZEN' => 'Belanja dibekukan. Hubungi petugas sekolah.',
      'INVALID_PIN' => 'PIN salah.',
      'PIN_LOCKED' => 'PIN terkunci selama 15 menit.',
      'ONLINE_TOPUP_NOT_CONFIGURED' => 'Top up online belum tersedia.',
      _ =>
        message.isNotEmpty
            ? message
            : 'Koneksi terputus. Status belum diketahui; gunakan Coba ulang, jangan membuat transaksi baru.',
    };
  }
  return 'Operasi gagal. Muat ulang atau coba kembali.';
}

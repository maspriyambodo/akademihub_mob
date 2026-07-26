/// Helper parsing bersama untuk model PPDB.
///
/// Backend mencampur beberapa bentuk serialisasi:
/// - kolom `decimal` Laravel terserialisasi sebagai String ("150000.00"),
/// - endpoint `show`/`active` gelombang mengembalikan model Eloquent mentah
///   (tanggal ISO `2026-01-01T00:00:00.000000Z`) sementara jalur index
///   memakai Resource (tanggal `Y-m-d`),
/// - boolean bisa datang sebagai `true/false` maupun `1/0`.
library;

double? parseDoubleOrNull(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? parseIntOrNull(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

bool parseBool(dynamic v, {bool fallback = false}) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return fallback;
}

/// Ambil bagian tanggal `Y-m-d` dari string tanggal apa pun
/// (`2026-01-05` maupun `2026-01-05T00:00:00.000000Z`).
String parseTanggal(dynamic v) {
  if (v is! String || v.isEmpty) return '';
  return v.length >= 10 ? v.substring(0, 10) : v;
}

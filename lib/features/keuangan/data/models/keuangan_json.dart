/// Helper parsing JSON untuk modul keuangan.
///
/// Semua nilai numerik dari backend bisa datang sebagai `num` ATAU `String`
/// (kolom `decimal:2` di Eloquent diserialisasi sebagai string, mis.
/// `"350000.00"`), jadi semua helper di sini toleran terhadap keduanya.
library;

double? keuToDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

/// Sama seperti [keuToDouble] tetapi dengan nilai default (untuk field yang
/// pasti ada di response tapi tetap ingin aman).
double keuToDoubleOr(dynamic value, [double fallback = 0]) =>
    keuToDouble(value) ?? fallback;

int? keuToInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) return parsed;
    return double.tryParse(value.trim())?.toInt();
  }
  return null;
}

int keuToIntOr(dynamic value, [int fallback = 0]) =>
    keuToInt(value) ?? fallback;

String? keuToText(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

DateTime? keuToDate(dynamic value) {
  final text = keuToText(value);
  if (text == null || text.trim().isEmpty) return null;
  return DateTime.tryParse(text.trim());
}

/// Backend kadang mengirim daftar bulan sebagai LIST (`[1,2,3]`) dan kadang
/// sebagai MAP (`{"3":4,"4":5}`) — ini terjadi pada `bulan_belum_lunas` yang
/// dibuat lewat `array_diff()` di PHP sehingga key-nya tidak berurutan dan
/// `json_encode` menghasilkan objek. Tangani keduanya.
List<int> keuToIntList(dynamic raw) {
  final result = <int>[];
  if (raw is List) {
    for (final item in raw) {
      final v = keuToInt(item);
      if (v != null) result.add(v);
    }
  } else if (raw is Map) {
    for (final item in raw.values) {
      final v = keuToInt(item);
      if (v != null) result.add(v);
    }
  }
  result.sort();
  return result;
}

/// Ambil `Map<String, dynamic>` dari sebuah key, aman terhadap tipe lain.
Map<String, dynamic>? keuToMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
  return null;
}

/// Ambil daftar `Map<String, dynamic>` dari sebuah key.
List<Map<String, dynamic>> keuToMapList(dynamic raw) {
  if (raw is! List) return const [];
  final result = <Map<String, dynamic>>[];
  for (final item in raw) {
    final map = keuToMap(item);
    if (map != null) result.add(map);
  }
  return result;
}

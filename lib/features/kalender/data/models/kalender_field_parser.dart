/// Helper parsing field yang dipakai bersama oleh model-model kalender.
///
/// Kolom tanggal di backend memakai cast Eloquent `date`, sehingga JSON-nya
/// bisa berupa:
/// - `"2026-07-14T00:00:00.000000Z"` (Carbon default, mayoritas kasus)
/// - `"2026-07-14"` (bila Resource memanggil `toDateString()`, mis. tahun ajaran)
///
/// Kita SELALU mengambil 10 karakter pertama, bukan `DateTime.parse().toLocal()`,
/// supaya tanggal tidak bergeser satu hari di timezone dengan offset negatif.
String? normalisasiTanggal(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.length < 10) return null;
  final potong = s.substring(0, 10);
  // Validasi ringan: harus berbentuk YYYY-MM-DD
  if (potong.length != 10 || potong[4] != '-' || potong[7] != '-') return null;
  if (DateTime.tryParse(potong) == null) return null;
  return potong;
}

/// Kolom `time` Postgres dikembalikan sebagai `"07:30:00"`.
/// Dipangkas menjadi `"07:30"`. Mengembalikan null bila kosong / tidak valid.
String? normalisasiWaktu(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.length < 5) return null;
  final potong = s.substring(0, 5);
  if (potong[2] != ':') return null;
  return potong;
}

int intAtau(dynamic raw, int fallback) {
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw) ?? fallback;
  return fallback;
}

int? intOpsional(dynamic raw) {
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}

bool boolAtau(dynamic raw, bool fallback) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final s = raw.toLowerCase();
    if (s == 'true' || s == '1' || s == 't') return true;
    if (s == 'false' || s == '0' || s == 'f') return false;
  }
  return fallback;
}

String? stringOpsional(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  return s.isEmpty ? null : s;
}

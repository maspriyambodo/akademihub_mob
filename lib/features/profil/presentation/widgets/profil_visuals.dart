import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_theme.dart';

// ── Role ─────────────────────────────────────────────────────────────────────

/// `sys_roles.code` berbentuk UPPERCASE (`SISWA`, `GURU`, `WALI_SISWA`,
/// `ADMIN`) sementara `UserEntity.role` bisa lowercase. Normalisasi ke salah
/// satu dari: `wali` | `siswa` | `guru` | `admin` | `lainnya`.
///
/// Cek `wali` HARUS lebih dulu karena `WALI_SISWA` mengandung `siswa`.
String normalisasiRole(String? role) {
  final r = (role ?? '').toLowerCase();
  if (r.contains('wali')) return 'wali';
  if (r.contains('guru')) return 'guru';
  if (r.contains('siswa')) return 'siswa';
  if (r.contains('admin')) return 'admin';
  return r.isEmpty ? 'lainnya' : r;
}

Color warnaRole(String? role) {
  switch (normalisasiRole(role)) {
    case 'siswa':
      return AppColors.siswaColor;
    case 'guru':
      return AppColors.guruColor;
    case 'wali':
      return AppColors.waliColor;
    default:
      return AppColors.primary;
  }
}

String labelRole(String? role) {
  switch (normalisasiRole(role)) {
    case 'siswa':
      return 'Siswa';
    case 'guru':
      return 'Guru';
    case 'wali':
      return 'Wali Murid';
    case 'admin':
      return 'Administrator';
    default:
      return 'Pengguna';
  }
}

IconData ikonRole(String? role) {
  switch (normalisasiRole(role)) {
    case 'siswa':
      return Icons.school_outlined;
    case 'guru':
      return Icons.co_present_outlined;
    case 'wali':
      return Icons.family_restroom_outlined;
    case 'admin':
      return Icons.admin_panel_settings_outlined;
    default:
      return Icons.person_outline;
  }
}

// ── Teks ─────────────────────────────────────────────────────────────────────

/// Inisial dari nama, maksimal 2 huruf. "Budi Santoso" → "BS".
String inisialNama(String nama) {
  final parts = nama
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final p = parts.first;
    return (p.length == 1 ? p : p.substring(0, 2)).toUpperCase();
  }
  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}

/// Ambil nilai bertipe teks dari map profil dengan beberapa kemungkinan key.
/// Mengembalikan null bila tidak ada / kosong.
String? nilaiProfil(Map<String, dynamic>? profile, List<String> keys) {
  if (profile == null) return null;
  for (final key in keys) {
    final value = profile[key];
    if (value == null) continue;
    if (value is String) {
      if (value.trim().isEmpty) continue;
      return value.trim();
    }
    if (value is num || value is bool) return value.toString();
  }
  return null;
}

/// `jenis_kelamin` disimpan sebagai smallint referensi
/// (`sys_references`: 1 = Laki-Laki, 2 = Perempuan). Nilai string 'L'/'P'
/// ikut ditangani untuk berjaga-jaga.
String? formatJenisKelamin(dynamic value) {
  if (value == null) return null;
  if (value is num) {
    if (value == 1) return 'Laki-Laki';
    if (value == 2) return 'Perempuan';
    return null;
  }
  final s = value.toString().trim().toUpperCase();
  if (s.isEmpty) return null;
  if (s == '1' || s == 'L' || s == 'LAKI-LAKI' || s == 'LAKI LAKI') {
    return 'Laki-Laki';
  }
  if (s == '2' || s == 'P' || s == 'PEREMPUAN') return 'Perempuan';
  return null;
}

const List<String> _namaBulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// "2010-03-12" → "12 Maret 2010". Format manual agar tidak bergantung pada
/// inisialisasi locale `intl`.
String? formatTanggal(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final date = DateTime.tryParse(raw.trim());
  if (date == null) return raw.trim();
  return '${date.day} ${_namaBulan[date.month - 1]} ${date.year}';
}

// ── Waktu relatif ────────────────────────────────────────────────────────────

bool _localeTerdaftar = false;

/// Daftarkan pesan locale Indonesia untuk `timeago`. Aman dipanggil berkali-kali
/// dan hanya dipakai oleh fitur profil.
void ensureTimeagoIdLocale() {
  if (_localeTerdaftar) return;
  timeago.setLocaleMessages('id', timeago.IdMessages());
  _localeTerdaftar = true;
}

/// Contoh hasil: "5 menit yang lalu".
String waktuRelatif(DateTime? date) {
  if (date == null) return 'Belum pernah aktif';
  ensureTimeagoIdLocale();
  return timeago.format(date, locale: 'id');
}

/// Format absolut tanpa locale `intl`: "26/07/2026 14:05".
String waktuLengkap(DateTime? date) {
  if (date == null) return '-';
  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  final hh = date.hour.toString().padLeft(2, '0');
  final mi = date.minute.toString().padLeft(2, '0');
  return '$dd/$mm/${date.year} $hh:$mi';
}

// ── Perangkat ────────────────────────────────────────────────────────────────

String labelPerangkat(String? deviceType) {
  final t = (deviceType ?? '').toLowerCase();
  if (t.contains('android')) return 'Android';
  if (t.contains('ios') || t.contains('iphone') || t.contains('ipad')) {
    return 'iOS';
  }
  if (t.contains('web')) return 'Web';
  if (t.isEmpty) return 'Perangkat';
  return deviceType!;
}

IconData ikonPerangkat(String? deviceType) {
  final t = (deviceType ?? '').toLowerCase();
  if (t.contains('android')) return Icons.android;
  if (t.contains('ios') || t.contains('iphone') || t.contains('ipad')) {
    return Icons.phone_iphone;
  }
  if (t.contains('web')) return Icons.language;
  return Icons.devices_other;
}

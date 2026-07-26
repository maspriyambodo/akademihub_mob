import '../../domain/entities/jadwal_pelajaran_entity.dart';

/// Model untuk `JadwalPelajaranResource` (backend Laravel).
///
/// Bentuk JSON:
/// ```json
/// {
///   "id": 1,
///   "kelas": { "id": 3, "nama_kelas": "X IPA 1", "tingkat": "X" },
///   "guru_mapel": {
///     "id": 12,
///     "guru": { "id": 5, "nama": "Budi", "nip": "1987..." },
///     "mapel": { "id": 2, "nama": "Matematika" }
///   },
///   "hari": "MON",
///   "jam_mulai": "07:00",
///   "jam_selesai": "08:30",
///   "ruangan": "R-101"
/// }
/// ```
/// Catatan: key `kelas` dan `guru_mapel` memakai `whenLoaded`, jadi bisa
/// tidak ada sama sekali (endpoint /kelas/{id} tidak meng-eager-load `kelas`).
/// Nested `guru`/`mapel` bisa bernilai null.
class JadwalPelajaranModel {
  final int id;
  final int? kelasId;
  final String? kelasNama;
  final String? kelasTingkat;
  final int? guruMapelId;
  final int? guruId;
  final String? guruNama;
  final String? guruNip;
  final int? mapelId;
  final String? mapelNama;
  final String hari;
  final String? jamMulai;
  final String? jamSelesai;
  final String? ruangan;

  const JadwalPelajaranModel({
    required this.id,
    this.kelasId,
    this.kelasNama,
    this.kelasTingkat,
    this.guruMapelId,
    this.guruId,
    this.guruNama,
    this.guruNip,
    this.mapelId,
    this.mapelNama,
    required this.hari,
    this.jamMulai,
    this.jamSelesai,
    this.ruangan,
  });

  factory JadwalPelajaranModel.fromJson(Map<String, dynamic> json) {
    final kelas = _asMap(json['kelas']);
    final guruMapel = _asMap(json['guru_mapel']);
    final guru = guruMapel != null ? _asMap(guruMapel['guru']) : null;
    final mapel = guruMapel != null ? _asMap(guruMapel['mapel']) : null;

    return JadwalPelajaranModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kelasId: (kelas?['id'] as num?)?.toInt(),
      kelasNama: kelas?['nama_kelas'] as String?,
      kelasTingkat: kelas?['tingkat']?.toString(),
      guruMapelId: (guruMapel?['id'] as num?)?.toInt(),
      guruId: (guru?['id'] as num?)?.toInt(),
      guruNama: guru?['nama'] as String?,
      guruNip: guru?['nip'] as String?,
      mapelId: (mapel?['id'] as num?)?.toInt(),
      mapelNama: mapel?['nama'] as String?,
      hari: (json['hari'] as String? ?? '').toUpperCase(),
      jamMulai: _asJam(json['jam_mulai']),
      jamSelesai: _asJam(json['jam_selesai']),
      ruangan: json['ruangan'] as String?,
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) =>
      value is Map<String, dynamic> ? value : null;

  /// Backend mengirim "HH:mm", tapi tetap toleran bila berupa "HH:mm:ss"
  /// atau ISO datetime penuh.
  static String? _asJam(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    if (value.contains('T')) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        final h = parsed.hour.toString().padLeft(2, '0');
        final m = parsed.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
    }
    final parts = value.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return value;
  }

  JadwalPelajaranEntity toEntity() => JadwalPelajaranEntity(
    id: id,
    kelasId: kelasId,
    kelasNama: kelasNama,
    kelasTingkat: kelasTingkat,
    guruMapelId: guruMapelId,
    guruId: guruId,
    guruNama: guruNama,
    guruNip: guruNip,
    mapelId: mapelId,
    mapelNama: mapelNama,
    hari: hari,
    jamMulai: jamMulai,
    jamSelesai: jamSelesai,
    ruangan: ruangan,
  );
}

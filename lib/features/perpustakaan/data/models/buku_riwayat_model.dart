import '../../domain/entities/buku_riwayat_entity.dart';

/// Parsing manual respons `GET /perpustakaan/buku/{id}/peminjaman`.
///
/// Bentuknya dibangun manual di `BukuService::getPeminjamanByBuku()`:
/// ```json
/// { "buku": { "id": 1, "judul": "...", "stok": 3 },
///   "peminjaman_aktif": [
///     { "id": 9, "siswa": {"id": 2, "nama": "...", "nis": "..."},
///       "tanggal_pinjam": "2026-07-20T00:00:00.000000Z" } ] }
/// ```
/// Bila buku tidak ditemukan backend mengirim `data: []` (array kosong).
class BukuRiwayatModel {
  final int bukuId;
  final String? judul;
  final int stok;
  final List<PeminjamanAktifModel> peminjamanAktif;

  const BukuRiwayatModel({
    required this.bukuId,
    this.judul,
    this.stok = 0,
    this.peminjamanAktif = const [],
  });

  factory BukuRiwayatModel.fromJson(Map<String, dynamic> json) {
    final buku = json['buku'] is Map
        ? Map<String, dynamic>.from(json['buku'] as Map)
        : null;

    final rawList = json['peminjaman_aktif'];
    final aktif = <PeminjamanAktifModel>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map) {
          aktif.add(
            PeminjamanAktifModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return BukuRiwayatModel(
      bukuId: (buku?['id'] as num?)?.toInt() ?? 0,
      judul: buku?['judul'] as String?,
      stok: (buku?['stok'] as num?)?.toInt() ?? 0,
      peminjamanAktif: aktif,
    );
  }

  BukuRiwayatEntity toEntity() => BukuRiwayatEntity(
    bukuId: bukuId,
    judul: judul,
    stok: stok,
    peminjamanAktif: peminjamanAktif.map((e) => e.toEntity()).toList(),
  );
}

class PeminjamanAktifModel {
  final int id;
  final int? siswaId;
  final String? siswaNama;
  final String? siswaNis;
  final String? tanggalPinjam;

  const PeminjamanAktifModel({
    required this.id,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    this.tanggalPinjam,
  });

  factory PeminjamanAktifModel.fromJson(Map<String, dynamic> json) {
    final siswa = json['siswa'] is Map
        ? Map<String, dynamic>.from(json['siswa'] as Map)
        : null;

    return PeminjamanAktifModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      siswaId: (siswa?['id'] as num?)?.toInt(),
      siswaNama: siswa?['nama'] as String?,
      siswaNis: siswa?['nis'] as String?,
      tanggalPinjam: json['tanggal_pinjam']?.toString(),
    );
  }

  PeminjamanAktifEntity toEntity() => PeminjamanAktifEntity(
    id: id,
    siswaId: siswaId,
    siswaNama: siswaNama,
    siswaNis: siswaNis,
    tanggalPinjam: tanggalPinjam,
  );
}

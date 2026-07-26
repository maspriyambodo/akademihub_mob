import '../../domain/entities/peminjaman_buku_entity.dart';

/// Parsing manual `PeminjamanBukuResource` backend (tanpa code generation).
///
/// Relasi `siswa` dan `buku` memakai `whenLoaded`, jadi keduanya bisa TIDAK ADA
/// tergantung endpoint:
/// - `/peminjaman` & `/peminjaman/overdue` → `with(['siswa','buku'])` (dua-duanya ada)
/// - `/peminjaman/siswa/{id}`              → `with('buku')` saja (tanpa `siswa`)
/// - `POST /peminjaman` & `.../pengembalian` → model baru tanpa eager load
///   (kedua relasi absen)
class PeminjamanBukuModel {
  final int id;
  final int? siswaId;
  final String? siswaNama;
  final String? siswaNis;
  final int? bukuId;
  final String? bukuJudul;
  final String? bukuIsbn;
  final String? tanggalPinjam;
  final String? tanggalJatuhTempo;
  final String? tanggalKembali;
  final String? status;
  final String? keterangan;

  const PeminjamanBukuModel({
    required this.id,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    this.bukuId,
    this.bukuJudul,
    this.bukuIsbn,
    this.tanggalPinjam,
    this.tanggalJatuhTempo,
    this.tanggalKembali,
    this.status,
    this.keterangan,
  });

  factory PeminjamanBukuModel.fromJson(Map<String, dynamic> json) {
    final siswa = json['siswa'] is Map
        ? Map<String, dynamic>.from(json['siswa'] as Map)
        : null;
    final buku = json['buku'] is Map
        ? Map<String, dynamic>.from(json['buku'] as Map)
        : null;

    return PeminjamanBukuModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      siswaId:
          (siswa?['id'] as num?)?.toInt() ??
          (json['mst_siswa_id'] as num?)?.toInt(),
      siswaNama: siswa?['nama'] as String?,
      siswaNis: siswa?['nis'] as String?,
      bukuId:
          (buku?['id'] as num?)?.toInt() ??
          (json['mst_buku_id'] as num?)?.toInt(),
      bukuJudul: buku?['judul'] as String?,
      bukuIsbn: buku?['isbn'] as String?,
      tanggalPinjam: json['tanggal_pinjam']?.toString(),
      tanggalJatuhTempo: json['tanggal_jatuh_tempo']?.toString(),
      tanggalKembali: json['tanggal_kembali']?.toString(),
      // `status` dikirim sebagai LABEL (`refLabel('status_pinjam', ...)`),
      // tapi bisa juga berupa angka mentah bila referensi tidak ditemukan.
      status: json['status']?.toString(),
      keterangan: json['keterangan'] as String?,
    );
  }

  PeminjamanBukuEntity toEntity() => PeminjamanBukuEntity(
    id: id,
    siswaId: siswaId,
    siswaNama: siswaNama,
    siswaNis: siswaNis,
    bukuId: bukuId,
    bukuJudul: bukuJudul,
    bukuIsbn: bukuIsbn,
    tanggalPinjam: tanggalPinjam,
    tanggalJatuhTempo: tanggalJatuhTempo,
    tanggalKembali: tanggalKembali,
    status: status,
    keterangan: keterangan,
  );
}

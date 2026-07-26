import 'package:equatable/equatable.dart';

/// Entity untuk satu baris log akses materi (tabel `trx_log_akses_materi`).
///
/// Sumber field: `LogAksesMateriResource` backend —
/// `id`, `materi_id`, `siswa_id`, `kelas_id`, `waktu_akses`, `durasi_detik`,
/// `durasi_label`, `status`, `progress_persen`, `ip_address`, `user_agent`,
/// `metadata`, `materi{id,judul}`, `siswa{id,nis,nama}`, `created_at`.
class LogAksesMateriEntity extends Equatable {
  final int id;
  final int? materiId;
  final int? siswaId;
  final int? kelasId;

  /// ISO8601
  final String? waktuAkses;

  final int durasiDetik;

  /// Label siap tampil dari backend, mis. "2 menit 30 detik".
  final String? durasiLabel;

  /// 1 = started, 2 = in_progress, 3 = completed
  final int? status;
  final int? progressPersen;

  final String? materiJudul;
  final String? siswaNama;
  final String? siswaNis;

  const LogAksesMateriEntity({
    required this.id,
    this.materiId,
    this.siswaId,
    this.kelasId,
    this.waktuAkses,
    this.durasiDetik = 0,
    this.durasiLabel,
    this.status,
    this.progressPersen,
    this.materiJudul,
    this.siswaNama,
    this.siswaNis,
  });

  DateTime? get waktuAksesDate =>
      waktuAkses == null ? null : DateTime.tryParse(waktuAkses!);

  String get statusLabel => switch (status) {
    2 => 'Sedang dibaca',
    3 => 'Selesai',
    _ => 'Dibuka',
  };

  @override
  List<Object?> get props => [id];
}

/// Ringkasan statistik pembaca untuk satu materi (dihitung client-side dari
/// `GET /akademik/log-akses-materi/materi/{materiId}`).
class MateriStatistikEntity extends Equatable {
  /// Jumlah baris log (setiap kali materi dibuka).
  final int totalAkses;

  /// Jumlah siswa unik yang pernah membuka materi.
  final int pembacaUnik;

  /// Total akumulasi durasi baca (detik).
  final int totalDurasiDetik;

  /// Waktu akses terakhir.
  final DateTime? aksesTerakhir;

  /// Beberapa log terbaru untuk ditampilkan sebagai daftar pembaca.
  final List<LogAksesMateriEntity> terbaru;

  const MateriStatistikEntity({
    this.totalAkses = 0,
    this.pembacaUnik = 0,
    this.totalDurasiDetik = 0,
    this.aksesTerakhir,
    this.terbaru = const [],
  });

  factory MateriStatistikEntity.fromLogs(List<LogAksesMateriEntity> logs) {
    if (logs.isEmpty) return const MateriStatistikEntity();

    final siswaIds = <int>{};
    var totalDurasi = 0;
    DateTime? terakhir;

    for (final log in logs) {
      final sid = log.siswaId;
      if (sid != null) siswaIds.add(sid);
      totalDurasi += log.durasiDetik;
      final waktu = log.waktuAksesDate;
      if (waktu != null && (terakhir == null || waktu.isAfter(terakhir))) {
        terakhir = waktu;
      }
    }

    final urut = [...logs]
      ..sort((a, b) {
        final da = a.waktuAksesDate;
        final db = b.waktuAksesDate;
        if (da == null && db == null) return b.id.compareTo(a.id);
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

    return MateriStatistikEntity(
      totalAkses: logs.length,
      pembacaUnik: siswaIds.isEmpty ? logs.length : siswaIds.length,
      totalDurasiDetik: totalDurasi,
      aksesTerakhir: terakhir,
      terbaru: urut.take(10).toList(),
    );
  }

  /// Rata-rata durasi baca per akses (detik).
  int get rataDurasiDetik =>
      totalAkses == 0 ? 0 : (totalDurasiDetik / totalAkses).round();

  bool get kosong => totalAkses == 0;

  @override
  List<Object?> get props => [
    totalAkses,
    pembacaUnik,
    totalDurasiDetik,
    aksesTerakhir,
  ];
}

/// Baris hasil `GET /akademik/log-akses-materi/popular`.
///
/// Endpoint ini mengembalikan hasil agregat mentah (bukan Resource):
/// `materi_id`, `total_akses`, `total_durasi`, dan relasi `materi`.
class MateriPopulerEntity extends Equatable {
  final int materiId;
  final String? judul;
  final int totalAkses;
  final int totalDurasiDetik;

  const MateriPopulerEntity({
    required this.materiId,
    this.judul,
    this.totalAkses = 0,
    this.totalDurasiDetik = 0,
  });

  String get judulLabel =>
      (judul != null && judul!.isNotEmpty) ? judul! : 'Materi #$materiId';

  @override
  List<Object?> get props => [materiId];
}

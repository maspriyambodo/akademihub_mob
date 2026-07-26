import 'package:equatable/equatable.dart';

/// Hasil seleksi otomatis satu pendaftar.
///
/// Sumber: tabel `ppdb_hasil_seleksi` via `PpdbHasilSeleksiResource`
/// (endpoint `/ppdb/seleksi/gelombang/{gelombangId}/hasil`).
/// `status_seleksi` mengikuti enum backend `PpdbStatusSeleksi`:
/// `menunggu` | `lolos` | `cadangan` | `tidak_lolos`.
class PpdbHasilSeleksiEntity extends Equatable {
  final int id;
  final int? pendaftarId;
  final int? gelombangId;
  final double? totalSkor;
  final int? peringkat;
  final int? peringkatJurusan;
  final String statusSeleksi;
  final String? statusSeleksiLabel;
  final bool isFinalized;
  final String? catatanSeleksi;
  final String? namaJurusan;

  const PpdbHasilSeleksiEntity({
    required this.id,
    this.pendaftarId,
    this.gelombangId,
    this.totalSkor,
    this.peringkat,
    this.peringkatJurusan,
    this.statusSeleksi = 'menunggu',
    this.statusSeleksiLabel,
    this.isFinalized = false,
    this.catatanSeleksi,
    this.namaJurusan,
  });

  @override
  List<Object?> get props => [id];
}

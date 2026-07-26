import 'package:equatable/equatable.dart';

import 'organisasi_anggota_entity.dart';
import 'organisasi_entity.dart';

/// Detail satu organisasi: profil + seluruh anggotanya.
///
/// Bersumber dari `GET /organisasi/{id}` yang meng-eager-load
/// `pembina`, `anggota.jabatan`, dan `anggota.siswa` sekaligus — sehingga
/// struktur kepengurusan bisa dibangun TANPA endpoint
/// `/organisasi/jabatan` (role mobile tidak punya izin
/// `organisasi.jabatan.view`).
class OrganisasiDetailEntity extends Equatable {
  final OrganisasiEntity organisasi;
  final List<OrganisasiAnggotaEntity> anggota;

  const OrganisasiDetailEntity({
    required this.organisasi,
    this.anggota = const [],
  });

  int get totalAnggota => anggota.length;

  int get totalAnggotaAktif => anggota.where((a) => a.isAktif).length;

  @override
  List<Object?> get props => [organisasi, anggota];
}

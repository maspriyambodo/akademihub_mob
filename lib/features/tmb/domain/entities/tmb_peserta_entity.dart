import 'package:equatable/equatable.dart';

import 'tmb_hasil_entity.dart';
import 'tmb_tes_entity.dart';

/// Keikutsertaan siswa pada satu tes (`trx_tes_minat_bakat_peserta`).
class TmbPesertaEntity extends Equatable {
  final int id;
  final int tesId;
  final int siswaId;

  /// 0=terdaftar, 1=sedang mengerjakan, 2=selesai, 3=timeout.
  final int status;

  final String? waktuMulai;
  final String? waktuSelesai;
  final int? progressPersen;
  final String? siswaNama;
  final String? siswaNis;
  final String? kelasNama;
  final TmbTesEntity? tes;
  final List<TmbHasilEntity> hasil;

  const TmbPesertaEntity({
    required this.id,
    required this.tesId,
    required this.siswaId,
    this.status = 0,
    this.waktuMulai,
    this.waktuSelesai,
    this.progressPersen,
    this.siswaNama,
    this.siswaNis,
    this.kelasNama,
    this.tes,
    this.hasil = const [],
  });

  static const statusTerdaftar = 0;
  static const statusBerjalan = 1;
  static const statusSelesai = 2;
  static const statusTimeout = 3;

  bool get isTerdaftar => status == statusTerdaftar;
  bool get isBerjalan => status == statusBerjalan;
  bool get isSelesai => status == statusSelesai;
  bool get isTimeout => status == statusTimeout;

  String get labelStatus {
    switch (status) {
      case statusBerjalan:
        return 'Sedang Berjalan';
      case statusSelesai:
        return 'Selesai';
      case statusTimeout:
        return 'Waktu Habis';
      default:
        return 'Terdaftar';
    }
  }

  DateTime? get waktuMulaiDate =>
      waktuMulai == null ? null : DateTime.tryParse(waktuMulai!)?.toLocal();

  DateTime? get waktuSelesaiDate =>
      waktuSelesai == null ? null : DateTime.tryParse(waktuSelesai!)?.toLocal();

  TmbPesertaEntity copyWith({
    int? status,
    String? waktuMulai,
    String? waktuSelesai,
    int? progressPersen,
    TmbTesEntity? tes,
    List<TmbHasilEntity>? hasil,
  }) {
    return TmbPesertaEntity(
      id: id,
      tesId: tesId,
      siswaId: siswaId,
      status: status ?? this.status,
      waktuMulai: waktuMulai ?? this.waktuMulai,
      waktuSelesai: waktuSelesai ?? this.waktuSelesai,
      progressPersen: progressPersen ?? this.progressPersen,
      siswaNama: siswaNama,
      siswaNis: siswaNis,
      kelasNama: kelasNama,
      tes: tes ?? this.tes,
      hasil: hasil ?? this.hasil,
    );
  }

  @override
  List<Object?> get props => [id, tesId, siswaId, status, progressPersen, hasil];
}

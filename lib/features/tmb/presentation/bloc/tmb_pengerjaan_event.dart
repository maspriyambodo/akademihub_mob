part of 'tmb_pengerjaan_bloc.dart';

abstract class TmbPengerjaanEvent extends Equatable {
  const TmbPengerjaanEvent();

  @override
  List<Object?> get props => [];
}

class TmbPengerjaanStarted extends TmbPengerjaanEvent {
  final TmbPesertaEntity peserta;
  final TmbTesEntity tes;

  /// True bila user tidak punya `tes-minat-bakat-pertanyaan.view` (siswa) —
  /// pertanyaan diambil dari `GET /tes-minat-bakat/{id}`.
  final bool viaTesDetail;

  /// True bila peserta baru saja memulai (status awal 0) — kegagalan memuat
  /// jawaban tersimpan tidak perlu ditampilkan.
  final bool pesertaBaruMulai;

  const TmbPengerjaanStarted({
    required this.peserta,
    required this.tes,
    required this.viaTesDetail,
    this.pesertaBaruMulai = false,
  });

  @override
  List<Object?> get props => [peserta.id, tes.id, viaTesDetail];
}

class TmbPengerjaanIndexChanged extends TmbPengerjaanEvent {
  final int index;
  const TmbPengerjaanIndexChanged(this.index);

  @override
  List<Object?> get props => [index];
}

class TmbPengerjaanOpsiDipilih extends TmbPengerjaanEvent {
  final int pertanyaanId;
  final int opsiId;
  const TmbPengerjaanOpsiDipilih({
    required this.pertanyaanId,
    required this.opsiId,
  });

  @override
  List<Object?> get props => [pertanyaanId, opsiId];
}

class TmbPengerjaanTeksDikirim extends TmbPengerjaanEvent {
  final int pertanyaanId;
  final String teks;
  const TmbPengerjaanTeksDikirim({
    required this.pertanyaanId,
    required this.teks,
  });

  @override
  List<Object?> get props => [pertanyaanId, teks];
}

class TmbPengerjaanSelesaikanRequested extends TmbPengerjaanEvent {
  const TmbPengerjaanSelesaikanRequested();
}

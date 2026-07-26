part of 'tmb_pengerjaan_bloc.dart';

abstract class TmbPengerjaanState extends Equatable {
  const TmbPengerjaanState();

  @override
  List<Object?> get props => [];
}

class TmbPengerjaanInitial extends TmbPengerjaanState {}

class TmbPengerjaanLoading extends TmbPengerjaanState {}

class TmbPengerjaanError extends TmbPengerjaanState {
  final String message;
  const TmbPengerjaanError(this.message);

  @override
  List<Object?> get props => [message];
}

class TmbPengerjaanLoaded extends TmbPengerjaanState {
  final TmbPesertaEntity peserta;
  final TmbTesEntity tes;
  final List<TmbPertanyaanEntity> pertanyaan;

  /// Jawaban tersimpan per `pertanyaan_id`.
  final Map<int, TmbJawabanEntity> jawaban;

  /// Indeks pertanyaan yang sedang tampil.
  final int index;

  /// `pertanyaan_id` yang jawabannya sedang dikirim ke server.
  final Set<int> sedangMengirim;

  final bool sedangMenyelesaikan;
  final String? catatan;

  const TmbPengerjaanLoaded({
    required this.peserta,
    required this.tes,
    required this.pertanyaan,
    required this.jawaban,
    required this.index,
    this.sedangMengirim = const {},
    this.sedangMenyelesaikan = false,
    this.catatan,
  });

  int get jumlahTerjawab => jawaban.length;
  int get jumlahPertanyaan => pertanyaan.length;
  int get jumlahBelumTerjawab => jumlahPertanyaan - jumlahTerjawab;
  bool get semuaTerjawab => jumlahBelumTerjawab <= 0;

  double get progress =>
      jumlahPertanyaan == 0 ? 0 : jumlahTerjawab / jumlahPertanyaan;

  TmbJawabanEntity? jawabanUntuk(int pertanyaanId) => jawaban[pertanyaanId];

  bool sudahDijawab(int pertanyaanId) => jawaban.containsKey(pertanyaanId);

  @override
  List<Object?> get props => [
    peserta,
    pertanyaan,
    jawaban,
    index,
    sedangMengirim,
    sedangMenyelesaikan,
    catatan,
  ];
}

/// Transien — untuk snackbar kegagalan kirim/selesaikan; bloc langsung
/// meng-emit ulang [TmbPengerjaanLoaded] setelahnya.
class TmbPengerjaanActionFailure extends TmbPengerjaanState {
  final String message;
  const TmbPengerjaanActionFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Tes selesai — [peserta] segar dari backend, sudah memuat `hasil.aspek`.
class TmbPengerjaanSelesai extends TmbPengerjaanState {
  final TmbPesertaEntity peserta;
  const TmbPengerjaanSelesai(this.peserta);

  @override
  List<Object?> get props => [peserta];
}

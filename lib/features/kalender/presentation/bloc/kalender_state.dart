part of 'kalender_bloc.dart';

/// Sekelompok agenda yang jatuh pada satu tanggal.
class KalenderGrupTanggal extends Equatable {
  /// "YYYY-MM-DD"
  final String tanggal;
  final List<KalenderAgendaItem> items;

  const KalenderGrupTanggal({required this.tanggal, required this.items});

  DateTime? get tanggalDate => DateTime.tryParse(tanggal);

  @override
  List<Object?> get props => [tanggal, items];
}

abstract class KalenderState extends Equatable {
  const KalenderState();

  @override
  List<Object?> get props => [];
}

class KalenderInitial extends KalenderState {}

class KalenderLoading extends KalenderState {}

class KalenderLoaded extends KalenderState {
  /// Konteks akademik untuk header (bisa kosong bila tidak diizinkan).
  final KalenderKonteksEntity konteks;

  /// Master tipe untuk chip filter & legenda.
  final List<KalenderTipeEntity> tipeList;

  /// Agenda yang berlangsung hari ini (lintas bulan, tidak ikut difilter bulan).
  final List<KalenderAgendaItem> agendaHariIni;

  /// Agenda bulan terpilih, dikelompokkan per tanggal, urut menaik.
  final List<KalenderGrupTanggal> grupBulanIni;

  final int bulan;
  final int tahun;

  /// Jumlah agenda pada bulan terpilih (termasuk agenda hari ini).
  final int totalBulanIni;

  /// Filter tipe aktif; null = semua.
  final int? filterTipeId;

  /// False bila endpoint `kalender-harian` tidak dapat diakses / gagal —
  /// linimasa tetap tampil dari `kalender-akademik` saja.
  final bool harianTersedia;

  const KalenderLoaded({
    required this.konteks,
    required this.tipeList,
    required this.agendaHariIni,
    required this.grupBulanIni,
    required this.bulan,
    required this.tahun,
    required this.totalBulanIni,
    this.filterTipeId,
    this.harianTersedia = true,
  });

  bool get kosong => agendaHariIni.isEmpty && grupBulanIni.isEmpty;

  @override
  List<Object?> get props => [
    konteks,
    tipeList,
    agendaHariIni,
    grupBulanIni,
    bulan,
    tahun,
    totalBulanIni,
    filterTipeId,
    harianTersedia,
  ];
}

class KalenderError extends KalenderState {
  final String message;

  const KalenderError(this.message);

  @override
  List<Object?> get props => [message];
}

/// User tidak punya permission `kalender-akademik.view`.
/// Dipisahkan dari [KalenderError] supaya UI bisa menampilkan pesan
/// "tidak punya akses" (tanpa tombol Coba Lagi) alih-alih pesan galat teknis.
class KalenderForbidden extends KalenderState {
  final String message;

  const KalenderForbidden(this.message);

  @override
  List<Object?> get props => [message];
}

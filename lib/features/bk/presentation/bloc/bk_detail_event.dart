part of 'bk_detail_bloc.dart';

abstract class BkDetailEvent extends Equatable {
  const BkDetailEvent();

  @override
  List<Object?> get props => [];
}

class BkDetailLoadRequested extends BkDetailEvent {
  final int kasusId;
  final bool canViewSesi;
  final bool canViewHasil;
  final bool canViewTindakan;
  final bool canManageSesi;
  final bool canManageHasil;
  final bool canManageTindakan;

  const BkDetailLoadRequested({
    required this.kasusId,
    required this.canViewSesi,
    required this.canViewHasil,
    required this.canViewTindakan,
    required this.canManageSesi,
    required this.canManageHasil,
    required this.canManageTindakan,
  });

  @override
  List<Object?> get props => [
    kasusId,
    canViewSesi,
    canViewHasil,
    canViewTindakan,
    canManageSesi,
    canManageHasil,
    canManageTindakan,
  ];
}

class BkDetailRefreshRequested extends BkDetailEvent {
  const BkDetailRefreshRequested();
}

class BkSesiCreateRequested extends BkDetailEvent {
  final String tanggal; // yyyy-MM-dd
  final int metode; // 1=Tatap Muka, 2=Online, 3=Telepon (ref `metode_bk`)
  final String catatan;

  const BkSesiCreateRequested({
    required this.tanggal,
    required this.metode,
    required this.catatan,
  });

  @override
  List<Object?> get props => [tanggal, metode, catatan];
}

class BkHasilCreateRequested extends BkDetailEvent {
  final String hasil;
  final String rekomendasi;

  const BkHasilCreateRequested({
    required this.hasil,
    required this.rekomendasi,
  });

  @override
  List<Object?> get props => [hasil, rekomendasi];
}

class BkTindakanCreateRequested extends BkDetailEvent {
  final String deskripsi;

  const BkTindakanCreateRequested({required this.deskripsi});

  @override
  List<Object?> get props => [deskripsi];
}

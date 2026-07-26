part of 'bk_detail_bloc.dart';

abstract class BkDetailState extends Equatable {
  const BkDetailState();

  @override
  List<Object?> get props => [];
}

class BkDetailInitial extends BkDetailState {}

class BkDetailLoading extends BkDetailState {}

class BkDetailLoaded extends BkDetailState {
  final List<BkSesiEntity> sesi;
  final List<BkHasilEntity> hasil;
  final List<BkTindakanEntity> tindakan;

  /// Pesan error per seksi (null = seksi berhasil dimuat / tidak dimuat).
  final String? errorSesi;
  final String? errorHasil;
  final String? errorTindakan;

  final bool canViewSesi;
  final bool canViewHasil;
  final bool canViewTindakan;
  final bool canManageSesi;
  final bool canManageHasil;
  final bool canManageTindakan;

  final int revisi;

  const BkDetailLoaded({
    required this.sesi,
    required this.hasil,
    required this.tindakan,
    required this.errorSesi,
    required this.errorHasil,
    required this.errorTindakan,
    required this.canViewSesi,
    required this.canViewHasil,
    required this.canViewTindakan,
    required this.canManageSesi,
    required this.canManageHasil,
    required this.canManageTindakan,
    required this.revisi,
  });

  @override
  List<Object?> get props => [
    sesi,
    hasil,
    tindakan,
    errorSesi,
    errorHasil,
    errorTindakan,
    canViewSesi,
    canViewHasil,
    canViewTindakan,
    canManageSesi,
    canManageHasil,
    canManageTindakan,
    revisi,
  ];
}

class BkDetailError extends BkDetailState {
  final String message;
  const BkDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State transien untuk SnackBar setelah aksi tulis berhasil.
class BkDetailActionSuccess extends BkDetailState {
  final String message;
  const BkDetailActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// State transien untuk SnackBar setelah aksi tulis gagal.
class BkDetailActionFailure extends BkDetailState {
  final String message;
  const BkDetailActionFailure(this.message);

  @override
  List<Object?> get props => [message];
}

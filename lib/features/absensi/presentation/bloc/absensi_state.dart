part of 'absensi_bloc.dart';

abstract class AbsensiState extends Equatable {
  const AbsensiState();
  @override
  List<Object?> get props => [];
}

class AbsensiInitial extends AbsensiState {}

class AbsensiLoading extends AbsensiState {}

class AbsensiLoaded extends AbsensiState {
  final AbsensiSummaryEntity summary;
  final List<AbsensiSiswaEntity> siswaItems;
  final List<AbsensiGuruEntity> guruItems;
  final int bulan;
  final int tahun;
  final String role;

  const AbsensiLoaded({
    required this.summary,
    required this.siswaItems,
    required this.guruItems,
    required this.bulan,
    required this.tahun,
    required this.role,
  });

  bool get isGuruMode => role == 'guru';

  @override
  List<Object?> get props => [
    summary,
    siswaItems,
    guruItems,
    bulan,
    tahun,
    role,
  ];
}

class AbsensiError extends AbsensiState {
  final String message;
  const AbsensiError(this.message);

  @override
  List<Object?> get props => [message];
}

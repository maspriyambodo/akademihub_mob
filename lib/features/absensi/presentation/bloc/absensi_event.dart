part of 'absensi_bloc.dart';

abstract class AbsensiEvent extends Equatable {
  const AbsensiEvent();
  @override
  List<Object?> get props => [];
}

class AbsensiLoadRequested extends AbsensiEvent {
  final String role;
  final int? profileId;
  final int bulan;
  final int tahun;

  const AbsensiLoadRequested({
    required this.role,
    this.profileId,
    required this.bulan,
    required this.tahun,
  });

  @override
  List<Object?> get props => [role, profileId, bulan, tahun];
}

class AbsensiMonthChanged extends AbsensiEvent {
  final int bulan;
  final int tahun;

  const AbsensiMonthChanged({required this.bulan, required this.tahun});

  @override
  List<Object?> get props => [bulan, tahun];
}

class AbsensiRefreshRequested extends AbsensiEvent {
  const AbsensiRefreshRequested();
}

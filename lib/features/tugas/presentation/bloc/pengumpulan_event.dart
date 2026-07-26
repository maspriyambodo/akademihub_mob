part of 'pengumpulan_bloc.dart';

abstract class PengumpulanEvent extends Equatable {
  const PengumpulanEvent();
  @override
  List<Object?> get props => [];
}

class PengumpulanLoadRequested extends PengumpulanEvent {
  final int tugasId;
  const PengumpulanLoadRequested(this.tugasId);

  @override
  List<Object?> get props => [tugasId];
}

class PengumpulanRefreshRequested extends PengumpulanEvent {
  const PengumpulanRefreshRequested();
}

class PengumpulanNilaiRequested extends PengumpulanEvent {
  final int pengumpulanId;
  final double nilai;
  final String? catatanGuru;

  const PengumpulanNilaiRequested({
    required this.pengumpulanId,
    required this.nilai,
    this.catatanGuru,
  });

  @override
  List<Object?> get props => [pengumpulanId, nilai, catatanGuru];
}

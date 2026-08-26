part of 'pengumpulan_bloc.dart';

abstract class PengumpulanEvent extends Equatable {
  const PengumpulanEvent();
  @override
  List<Object?> get props => [];
}

class PengumpulanLoadRequested extends PengumpulanEvent {
  final int tugasId;
  final bool canNilai;

  const PengumpulanLoadRequested(this.tugasId, {this.canNilai = false});

  @override
  List<Object?> get props => [tugasId, canNilai];
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

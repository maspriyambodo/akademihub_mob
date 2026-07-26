part of 'ujian_nilai_bloc.dart';

abstract class UjianNilaiEvent extends Equatable {
  const UjianNilaiEvent();
  @override
  List<Object?> get props => [];
}

class UjianNilaiLoadRequested extends UjianNilaiEvent {
  final int ujianId;
  const UjianNilaiLoadRequested(this.ujianId);

  @override
  List<Object?> get props => [ujianId];
}

class UjianNilaiRefreshRequested extends UjianNilaiEvent {
  const UjianNilaiRefreshRequested();
}

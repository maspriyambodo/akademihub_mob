part of 'ujian_nilai_bloc.dart';

abstract class UjianNilaiState extends Equatable {
  const UjianNilaiState();
  @override
  List<Object?> get props => [];
}

class UjianNilaiInitial extends UjianNilaiState {}

class UjianNilaiLoading extends UjianNilaiState {}

class UjianNilaiLoaded extends UjianNilaiState {
  final UjianNilaiDetailEntity detail;
  const UjianNilaiLoaded(this.detail);

  @override
  List<Object?> get props => [detail];
}

class UjianNilaiError extends UjianNilaiState {
  final String message;
  const UjianNilaiError(this.message);

  @override
  List<Object?> get props => [message];
}

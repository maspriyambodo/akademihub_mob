part of 'bk_form_bloc.dart';

abstract class BkFormEvent extends Equatable {
  const BkFormEvent();

  @override
  List<Object?> get props => [];
}

class BkFormStarted extends BkFormEvent {
  const BkFormStarted();
}

class BkFormSiswaSearchRequested extends BkFormEvent {
  final String query;
  const BkFormSiswaSearchRequested(this.query);

  @override
  List<Object?> get props => [query];
}

class BkFormSubmitted extends BkFormEvent {
  final int siswaId;
  final int guruId;
  final int jenisId;
  final String tanggal; // yyyy-MM-dd
  final String keterangan;

  const BkFormSubmitted({
    required this.siswaId,
    required this.guruId,
    required this.jenisId,
    required this.tanggal,
    required this.keterangan,
  });

  @override
  List<Object?> get props => [siswaId, guruId, jenisId, tanggal, keterangan];
}

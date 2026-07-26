part of 'bk_form_bloc.dart';

abstract class BkFormState extends Equatable {
  const BkFormState();

  @override
  List<Object?> get props => [];
}

class BkFormInitial extends BkFormState {}

class BkFormLoading extends BkFormState {}

/// Master jenis gagal dimuat — form tidak bisa dipakai.
class BkFormError extends BkFormState {
  final String message;
  const BkFormError(this.message);

  @override
  List<Object?> get props => [message];
}

class BkFormReady extends BkFormState {
  final List<BkJenisEntity> jenisList;
  final List<BkSiswaRingkasEntity> hasilCariSiswa;
  final bool sedangCariSiswa;
  final bool mengirim;
  final int revisi;

  const BkFormReady({
    required this.jenisList,
    required this.hasilCariSiswa,
    required this.sedangCariSiswa,
    required this.mengirim,
    required this.revisi,
  });

  @override
  List<Object?> get props => [
    jenisList,
    hasilCariSiswa,
    sedangCariSiswa,
    mengirim,
    revisi,
  ];
}

/// State transien: kasus berhasil dibuat (page akan pop + refresh daftar).
class BkFormSubmitSuccess extends BkFormState {
  final String message;
  const BkFormSubmitSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// State transien: aksi gagal (SnackBar).
class BkFormActionFailure extends BkFormState {
  final String message;
  const BkFormActionFailure(this.message);

  @override
  List<Object?> get props => [message];
}

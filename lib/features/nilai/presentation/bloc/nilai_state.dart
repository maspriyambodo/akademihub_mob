part of 'nilai_bloc.dart';

/// Opsi pemilih ujian untuk role guru (diturunkan dari data nilai yang dimuat,
/// karena tidak ada endpoint daftar ujian pada fitur ini).
class NilaiUjianOption extends Equatable {
  final int id;
  final String label;
  final String? mapel;
  final String? kelas;

  const NilaiUjianOption({
    required this.id,
    required this.label,
    this.mapel,
    this.kelas,
  });

  String get subtitle {
    final parts = <String>[
      if (mapel != null && mapel!.isNotEmpty) mapel!,
      if (kelas != null && kelas!.isNotEmpty) kelas!,
    ];
    return parts.join(' · ');
  }

  @override
  List<Object?> get props => [id, label, mapel, kelas];
}

abstract class NilaiState extends Equatable {
  const NilaiState();
  @override
  List<Object?> get props => [];
}

class NilaiInitial extends NilaiState {}

class NilaiLoading extends NilaiState {}

class NilaiLoaded extends NilaiState {
  final String role;

  /// Daftar nilai yang sudah difilter & diurutkan.
  final List<NilaiEntity> items;

  final NilaiSummaryEntity summary;

  /// Semua label semester yang tersedia pada data.
  final List<String> semesterOptions;
  final String? selectedSemester;

  /// Opsi ujian (dipakai role guru).
  final List<NilaiUjianOption> ujianOptions;
  final int? selectedUjianId;

  final String searchQuery;

  const NilaiLoaded({
    required this.role,
    required this.items,
    required this.summary,
    this.semesterOptions = const [],
    this.selectedSemester,
    this.ujianOptions = const [],
    this.selectedUjianId,
    this.searchQuery = '',
  });

  /// Siswa & wali melihat ringkasan + pengelompokan per mata pelajaran.
  bool get isRingkasanMode => role == 'siswa' || role == 'wali';

  /// Guru & admin melihat daftar dengan pencarian nama siswa.
  bool get showSearch => role == 'guru' || role == 'admin';

  bool get isGuruMode => role == 'guru';

  bool get isUjianMode => selectedUjianId != null;

  NilaiUjianOption? get selectedUjian {
    for (final o in ujianOptions) {
      if (o.id == selectedUjianId) return o;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    role,
    items,
    summary,
    semesterOptions,
    selectedSemester,
    ujianOptions,
    selectedUjianId,
    searchQuery,
  ];
}

class NilaiError extends NilaiState {
  final String message;
  const NilaiError(this.message);

  @override
  List<Object?> get props => [message];
}

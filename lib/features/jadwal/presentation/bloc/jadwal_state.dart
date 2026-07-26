part of 'jadwal_bloc.dart';

abstract class JadwalState extends Equatable {
  const JadwalState();
  @override
  List<Object?> get props => [];
}

class JadwalInitial extends JadwalState {}

class JadwalLoading extends JadwalState {}

class JadwalLoaded extends JadwalState {
  /// Role yang sedang aktif ('siswa' | 'guru' | 'wali' | 'admin').
  final String role;

  /// Kode hari terpilih ('MON'..'SUN').
  final String selectedHari;

  /// Kode hari yang tersedia sebagai tab (Senin–Sabtu + Minggu bila ada data).
  final List<String> availableHari;

  /// Jadwal pada hari terpilih, sudah terurut berdasarkan jam mulai.
  final List<JadwalPelajaranEntity> items;

  /// Total jadwal dalam satu minggu (semua hari).
  final int totalMinggu;

  /// Waktu saat state dibentuk — dipakai untuk menandai jadwal berlangsung.
  final DateTime now;

  const JadwalLoaded({
    required this.role,
    required this.selectedHari,
    required this.availableHari,
    required this.items,
    required this.totalMinggu,
    required this.now,
  });

  /// Apakah hari terpilih sama dengan hari ini.
  bool get isHariIni => selectedHari == hariCodeFromWeekday(now.weekday);

  /// Tampilkan nama kelas pada kartu bila bukan jadwal kelas sendiri.
  bool get showKelas => role == 'guru' || role == 'admin';

  @override
  List<Object?> get props => [
    role,
    selectedHari,
    availableHari,
    items,
    totalMinggu,
    now,
  ];
}

class JadwalError extends JadwalState {
  final String message;
  const JadwalError(this.message);

  @override
  List<Object?> get props => [message];
}

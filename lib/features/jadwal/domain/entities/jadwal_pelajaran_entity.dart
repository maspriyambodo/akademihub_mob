import 'package:equatable/equatable.dart';

/// Daftar kode hari operasional standar (Senin–Sabtu).
/// Backend menyimpan kolom `hari` sebagai string kode:
/// 'MON','TUE','WED','THU','FRI','SAT','SUN'
/// (lihat CHECK constraint pada tabel `trx_jadwal_pelajaran`).
const List<String> kHariKerjaCodes = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

/// Semua kode hari yang valid menurut backend.
const List<String> kHariCodes = [
  'MON',
  'TUE',
  'WED',
  'THU',
  'FRI',
  'SAT',
  'SUN',
];

const Map<String, String> _hariLabels = {
  'MON': 'Senin',
  'TUE': 'Selasa',
  'WED': 'Rabu',
  'THU': 'Kamis',
  'FRI': 'Jumat',
  'SAT': 'Sabtu',
  'SUN': 'Minggu',
};

const Map<String, String> _hariLabelsShort = {
  'MON': 'Sen',
  'TUE': 'Sel',
  'WED': 'Rab',
  'THU': 'Kam',
  'FRI': 'Jum',
  'SAT': 'Sab',
  'SUN': 'Min',
};

/// Ubah `DateTime.weekday` (1 = Senin ... 7 = Minggu) menjadi kode hari backend.
String hariCodeFromWeekday(int weekday) {
  const byWeekday = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  if (weekday < 1 || weekday > 7) return 'MON';
  return byWeekday[weekday - 1];
}

/// Nama hari lengkap dalam Bahasa Indonesia, mis. 'MON' -> 'Senin'.
String hariLabel(String code) => _hariLabels[code.toUpperCase()] ?? code;

/// Nama hari singkat, mis. 'MON' -> 'Sen'.
String hariLabelShort(String code) =>
    _hariLabelsShort[code.toUpperCase()] ?? code;

/// Konversi "HH:mm" (atau "HH:mm:ss") menjadi menit sejak tengah malam.
/// Mengembalikan null bila format tidak dikenali.
int? minutesFromJam(String? jam) {
  if (jam == null || jam.isEmpty) return null;
  final parts = jam.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

class JadwalPelajaranEntity extends Equatable {
  final int id;

  // ── Kelas (hanya terisi pada endpoint index; endpoint per-kelas tidak
  //    meng-eager-load relasi kelas sehingga key `kelas` tidak dikirim) ──
  final int? kelasId;
  final String? kelasNama;
  final String? kelasTingkat;

  // ── Guru mapel ────────────────────────────────────────────────────────
  final int? guruMapelId;
  final int? guruId;
  final String? guruNama;
  final String? guruNip;
  final int? mapelId;
  final String? mapelNama;

  /// Kode hari: 'MON'..'SUN'
  final String hari;

  /// Format "HH:mm" dari backend (`jam_mulai`)
  final String? jamMulai;

  /// Format "HH:mm" dari backend (`jam_selesai`)
  final String? jamSelesai;

  final String? ruangan;

  const JadwalPelajaranEntity({
    required this.id,
    this.kelasId,
    this.kelasNama,
    this.kelasTingkat,
    this.guruMapelId,
    this.guruId,
    this.guruNama,
    this.guruNip,
    this.mapelId,
    this.mapelNama,
    required this.hari,
    this.jamMulai,
    this.jamSelesai,
    this.ruangan,
  });

  /// Nama hari lengkap, mis. "Senin".
  String get hariNama => hariLabel(hari);

  /// Menit sejak tengah malam untuk jam mulai (null bila tidak valid).
  int? get mulaiMenit => minutesFromJam(jamMulai);

  /// Menit sejak tengah malam untuk jam selesai (null bila tidak valid).
  int? get selesaiMenit => minutesFromJam(jamSelesai);

  /// Label rentang jam, mis. "07:00 - 08:30".
  String get rentangJam {
    final mulai = jamMulai ?? '--:--';
    final selesai = jamSelesai ?? '--:--';
    return '$mulai - $selesai';
  }

  /// Durasi pelajaran dalam menit (null bila jam tidak lengkap).
  int? get durasiMenit {
    final m = mulaiMenit;
    final s = selesaiMenit;
    if (m == null || s == null) return null;
    final d = s - m;
    return d > 0 ? d : null;
  }

  /// Apakah jadwal ini sedang berlangsung pada [now].
  /// Hanya bernilai true bila hari pada [now] sama dengan hari jadwal.
  bool isBerlangsung(DateTime now) {
    if (hari.toUpperCase() != hariCodeFromWeekday(now.weekday)) return false;
    final m = mulaiMenit;
    final s = selesaiMenit;
    if (m == null || s == null) return false;
    final nowMenit = now.hour * 60 + now.minute;
    return nowMenit >= m && nowMenit < s;
  }

  /// Apakah jadwal ini sudah lewat pada [now] (hari sama, jam selesai terlampaui).
  bool isSelesai(DateTime now) {
    if (hari.toUpperCase() != hariCodeFromWeekday(now.weekday)) return false;
    final s = selesaiMenit;
    if (s == null) return false;
    return (now.hour * 60 + now.minute) >= s;
  }

  @override
  List<Object?> get props => [id];
}

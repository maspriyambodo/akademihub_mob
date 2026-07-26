import 'package:equatable/equatable.dart';

/// Tes minat bakat (`trx_tes_minat_bakat`).
class TmbTesEntity extends Equatable {
  final int id;
  final String namaTes;
  final String? deskripsi;

  /// 1=RIASEC, 2=multiple intelligence, 3=learning style, 4=custom.
  final int tipeTes;

  /// 0=draft, 1=published, 2=closed.
  final int status;

  final String? waktuMulai;
  final String? waktuSelesai;
  final int? durasiMenit;
  final int? targetPeserta;
  final String? semesterNama;

  const TmbTesEntity({
    required this.id,
    required this.namaTes,
    this.deskripsi,
    this.tipeTes = 1,
    this.status = 0,
    this.waktuMulai,
    this.waktuSelesai,
    this.durasiMenit,
    this.targetPeserta,
    this.semesterNama,
  });

  static const statusDraft = 0;
  static const statusDibuka = 1;
  static const statusDitutup = 2;

  bool get isDibuka => status == statusDibuka;
  bool get isDitutup => status == statusDitutup;

  String get labelTipe {
    switch (tipeTes) {
      case 1:
        return 'RIASEC';
      case 2:
        return 'Kecerdasan Majemuk';
      case 3:
        return 'Gaya Belajar';
      default:
        return 'Kustom';
    }
  }

  String get labelStatus {
    switch (status) {
      case statusDibuka:
        return 'Dibuka';
      case statusDitutup:
        return 'Ditutup';
      default:
        return 'Draf';
    }
  }

  DateTime? get waktuMulaiDate =>
      waktuMulai == null ? null : DateTime.tryParse(waktuMulai!)?.toLocal();

  DateTime? get waktuSelesaiDate =>
      waktuSelesai == null ? null : DateTime.tryParse(waktuSelesai!)?.toLocal();

  /// Jadwal tes sudah lewat (bila `waktu_selesai` diisi).
  bool get sudahLewatJadwal {
    final selesai = waktuSelesaiDate;
    return selesai != null && DateTime.now().isAfter(selesai);
  }

  /// Jadwal tes belum dimulai (bila `waktu_mulai` diisi).
  bool get belumMasukJadwal {
    final mulai = waktuMulaiDate;
    return mulai != null && DateTime.now().isBefore(mulai);
  }

  /// Kelayakan dikerjakan dari sisi UI (backend sendiri tidak memvalidasi
  /// status tes saat `mulai`, jadi ini murni penjagaan klien).
  bool get bisaDikerjakan => isDibuka && !sudahLewatJadwal && !belumMasukJadwal;

  @override
  List<Object?> get props => [id, status, namaTes];
}

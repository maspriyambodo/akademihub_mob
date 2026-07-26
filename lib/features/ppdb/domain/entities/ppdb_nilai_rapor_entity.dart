import 'package:equatable/equatable.dart';

/// Satu baris nilai rapor pendaftar (tabel `ppdb_pendaftar_nilai_rapor`, 3NF).
///
/// Endpoint `/ppdb/nilai-rapor/pendaftaran/{id}` mengembalikan model mentah:
/// `{ id, ppdb_pendaftar_id, kode_mapel, nilai }` — `nilai` bertipe
/// `decimal:2` sehingga terserialisasi sebagai string ("85.50").
class PpdbNilaiRaporEntity extends Equatable {
  final int id;
  final String kodeMapel;
  final double? nilai;

  const PpdbNilaiRaporEntity({
    required this.id,
    this.kodeMapel = '',
    this.nilai,
  });

  /// Label mapel untuk kode standar yang dipakai backend
  /// (`mtk`, `ipa`, `bindo`, `bing`); selain itu tampilkan kodenya.
  String get labelMapel {
    switch (kodeMapel.toLowerCase()) {
      case 'mtk':
        return 'Matematika';
      case 'ipa':
        return 'IPA';
      case 'ips':
        return 'IPS';
      case 'bindo':
        return 'B. Indonesia';
      case 'bing':
        return 'B. Inggris';
      default:
        return kodeMapel.toUpperCase();
    }
  }

  @override
  List<Object?> get props => [id];
}

/// Ringkasan statistik nilai rapor satu pendaftar
/// (bagian `statistik` pada response nilai rapor).
class PpdbNilaiStatistikEntity extends Equatable {
  final int jumlahMapel;
  final double? rataRata;
  final double? nilaiTertinggi;
  final double? nilaiTerendah;

  const PpdbNilaiStatistikEntity({
    this.jumlahMapel = 0,
    this.rataRata,
    this.nilaiTertinggi,
    this.nilaiTerendah,
  });

  static const kosong = PpdbNilaiStatistikEntity();

  @override
  List<Object?> get props =>
      [jumlahMapel, rataRata, nilaiTertinggi, nilaiTerendah];
}

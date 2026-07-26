import 'package:equatable/equatable.dart';

/// Hasil per aspek untuk satu peserta (`trx_tes_minat_bakat_hasil`).
///
/// Diisi backend saat `POST /tes-minat-bakat-peserta/{id}/selesaikan`:
/// `skor_total`, `skor_persen`, dan `interpretasi` (Dominan/Cukup/Rendah).
/// `kategori_hasil`, `peringkat`, dan `rekomendasi` hanya terisi bila diinput
/// manual/seeder — tampilkan bila ada.
class TmbHasilEntity extends Equatable {
  final int id;
  final int? pesertaId;
  final int? aspekId;
  final int skorTotal;
  final int? skorPersen;
  final int? peringkat;
  final String? kategoriHasil;
  final String? interpretasi;
  final String? rekomendasi;
  final String? aspekKode;
  final String? aspekNama;
  final String? aspekDeskripsi;

  const TmbHasilEntity({
    required this.id,
    this.pesertaId,
    this.aspekId,
    this.skorTotal = 0,
    this.skorPersen,
    this.peringkat,
    this.kategoriHasil,
    this.interpretasi,
    this.rekomendasi,
    this.aspekKode,
    this.aspekNama,
    this.aspekDeskripsi,
  });

  /// Label kategori yang ditampilkan (dua kolom backend yang mungkin terisi).
  String? get kategoriTampil {
    final k = kategoriHasil?.trim();
    if (k != null && k.isNotEmpty) return k;
    final i = interpretasi?.trim();
    if (i != null && i.isNotEmpty) return i;
    return null;
  }

  String get namaTampil {
    final nama = aspekNama?.trim();
    if (nama != null && nama.isNotEmpty) return nama;
    final kode = aspekKode?.trim();
    if (kode != null && kode.isNotEmpty) return kode;
    return 'Aspek ${aspekId ?? '-'}';
  }

  @override
  List<Object?> get props => [id, aspekId, skorTotal, skorPersen];
}

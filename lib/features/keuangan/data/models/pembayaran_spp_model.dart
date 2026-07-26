import '../../domain/entities/pembayaran_spp_entity.dart';
import 'keuangan_json.dart';

/// Mapping dari `PembayaranSppResource` (Laravel).
///
/// Bentuk JSON (nama field diverifikasi langsung dari
/// `app/Http/Resources/Api/V1/PembayaranSppResource.php`):
/// ```json
/// {
///   "id": 12,
///   "siswa": { "id": 3, "nama": "Budi", "nis": "2026001" },
///   "tarif_spp": {
///     "id": 1,
///     "nominal": "350000.00",
///     "kelas": { "id": 5, "nama_kelas": "X IPA 1" }
///   },
///   "bulan": 1,
///   "nama_bulan": "Januari",
///   "tahun": 2026,
///   "tanggal_bayar": "2026-01-08",
///   "jumlah_bayar": "350000.00",
///   "status": "Lunas",
///   "metode_pembayaran": "Transfer",
///   "keterangan": "Lunas via Midtrans",
///   "petugas": { "id": 7, "name": "Petugas TU" },
///   "created_at": "2026-01-08T08:30:00+07:00",
///   "updated_at": "..."
/// }
/// ```
/// `siswa`, `tarif_spp`, `tarif_spp.kelas`, dan `petugas` memakai
/// `whenLoaded`/`when` → key-nya bisa HILANG sama sekali (bukan null).
/// Khusus endpoint by-siswa, backend hanya meng-eager-load `tarifSpp.kelas`
/// sehingga `siswa` dan `petugas` tidak ikut terkirim.
class PembayaranSppModel {
  final int id;
  final int? siswaId;
  final String? siswaNama;
  final String? siswaNis;
  final int? tarifSppId;
  final double? tarifNominal;
  final int? kelasId;
  final String? kelasNama;
  final int? bulan;
  final String? namaBulan;
  final int? tahun;
  final DateTime? tanggalBayar;
  final double? jumlahBayar;
  final String? status;
  final String? metodePembayaran;
  final String? keterangan;
  final int? petugasId;
  final String? petugasNama;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PembayaranSppModel({
    required this.id,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    this.tarifSppId,
    this.tarifNominal,
    this.kelasId,
    this.kelasNama,
    this.bulan,
    this.namaBulan,
    this.tahun,
    this.tanggalBayar,
    this.jumlahBayar,
    this.status,
    this.metodePembayaran,
    this.keterangan,
    this.petugasId,
    this.petugasNama,
    this.createdAt,
    this.updatedAt,
  });

  factory PembayaranSppModel.fromJson(Map<String, dynamic> json) {
    final siswa = keuToMap(json['siswa']);
    final tarif = keuToMap(json['tarif_spp']);
    final kelas = keuToMap(tarif?['kelas']);
    final petugas = keuToMap(json['petugas']);

    return PembayaranSppModel(
      id: keuToIntOr(json['id']),
      // `mst_siswa_id` tidak dikirim Resource; satu-satunya sumber adalah
      // relasi `siswa` yang di-eager-load.
      siswaId: keuToInt(siswa?['id']),
      siswaNama: keuToText(siswa?['nama']),
      siswaNis: keuToText(siswa?['nis']),
      tarifSppId: keuToInt(tarif?['id']),
      tarifNominal: keuToDouble(tarif?['nominal']),
      kelasId: keuToInt(kelas?['id']),
      kelasNama: keuToText(kelas?['nama_kelas']),
      bulan: keuToInt(json['bulan']),
      namaBulan: keuToText(json['nama_bulan']),
      tahun: keuToInt(json['tahun']),
      tanggalBayar: keuToDate(json['tanggal_bayar']),
      jumlahBayar: keuToDouble(json['jumlah_bayar']),
      status: keuToText(json['status']),
      metodePembayaran: keuToText(json['metode_pembayaran']),
      keterangan: keuToText(json['keterangan']),
      petugasId: keuToInt(petugas?['id']),
      petugasNama: keuToText(petugas?['name']),
      createdAt: keuToDate(json['created_at']),
      updatedAt: keuToDate(json['updated_at']),
    );
  }

  PembayaranSppEntity toEntity() => PembayaranSppEntity(
    id: id,
    siswaId: siswaId,
    siswaNama: siswaNama,
    siswaNis: siswaNis,
    tarifSppId: tarifSppId,
    tarifNominal: tarifNominal,
    kelasId: kelasId,
    kelasNama: kelasNama,
    bulan: bulan,
    namaBulan: namaBulan,
    tahun: tahun,
    tanggalBayar: tanggalBayar,
    jumlahBayar: jumlahBayar,
    status: status,
    metodePembayaran: metodePembayaran,
    keterangan: keterangan,
    petugasId: petugasId,
    petugasNama: petugasNama,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

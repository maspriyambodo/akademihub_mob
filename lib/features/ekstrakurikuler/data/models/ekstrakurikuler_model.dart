import '../../domain/entities/ekstrakurikuler_entity.dart';

/// Model ekstrakurikuler — parsing manual dari serialisasi model Eloquent
/// `MstEkstrakurikuler` (backend tidak memakai API Resource untuk modul ini).
class EkstrakurikulerModel {
  final int id;
  final String? kode;
  final String nama;
  final String? deskripsi;
  final int? pembinaGuruId;
  final String? pembinaNama;
  final String? pembinaNip;
  final String? hari;
  final String? jamMulai;
  final String? jamSelesai;
  final String? lokasi;
  final String status;

  const EkstrakurikulerModel({
    required this.id,
    this.kode,
    required this.nama,
    this.deskripsi,
    this.pembinaGuruId,
    this.pembinaNama,
    this.pembinaNip,
    this.hari,
    this.jamMulai,
    this.jamSelesai,
    this.lokasi,
    this.status = 'aktif',
  });

  factory EkstrakurikulerModel.fromJson(Map<String, dynamic> json) {
    final pembina = json['pembina'] as Map<String, dynamic>?;

    return EkstrakurikulerModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kode: json['kode'] as String?,
      nama: json['nama'] as String? ?? '(Tanpa nama)',
      deskripsi: json['deskripsi'] as String?,
      pembinaGuruId:
          (json['pembina_guru_id'] as num?)?.toInt() ??
          (pembina?['id'] as num?)?.toInt(),
      pembinaNama: pembina?['nama'] as String?,
      pembinaNip: pembina?['nip'] as String?,
      hari: json['hari'] as String?,
      jamMulai: normalisasiJam(json['jam_mulai']),
      jamSelesai: normalisasiJam(json['jam_selesai']),
      lokasi: json['lokasi'] as String?,
      status: json['status'] as String? ?? 'aktif',
    );
  }

  /// Kolom `jam_mulai`/`jam_selesai` bertipe `time` dan di-cast
  /// `datetime:H:i`, sehingga umumnya dikirim sebagai `"15:00"`. Tetap
  /// ditangani bentuk lain (`"15:00:00"`, ISO8601 penuh) supaya aman.
  static String? normalisasiJam(dynamic raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    if (text.isEmpty) return null;

    var jamBagian = text;
    if (text.contains('T')) {
      jamBagian = text.split('T').last;
    } else if (text.contains(' ')) {
      jamBagian = text.split(' ').last;
    }

    final potongan = jamBagian.split(':');
    if (potongan.length < 2) return null;

    final jam = potongan[0].padLeft(2, '0');
    final menit = potongan[1].substring(0, potongan[1].length >= 2 ? 2 : 1);
    if (int.tryParse(jam) == null || int.tryParse(menit) == null) return null;

    return '$jam:${menit.padLeft(2, '0')}';
  }

  EkstrakurikulerEntity toEntity() => EkstrakurikulerEntity(
    id: id,
    kode: kode,
    nama: nama,
    deskripsi: deskripsi,
    pembinaGuruId: pembinaGuruId,
    pembinaNama: pembinaNama,
    pembinaNip: pembinaNip,
    hari: hari,
    jamMulai: jamMulai,
    jamSelesai: jamSelesai,
    lokasi: lokasi,
    status: status,
  );
}

import 'package:equatable/equatable.dart';

/// Info sekolah (tenant) yang ditampilkan di kartu "Sekolah".
///
/// Sumber data bisa dua-duanya:
/// - endpoint `GET /sekolah/{id}` / `GET /sekolah/uuid/{uuid}` (butuh
///   permission `sekolah.view`) — data lengkap;
/// - tenant yang tersimpan di perangkat (hasil pemilihan sekolah saat login) —
///   hanya nama & logo, `id` bernilai null.
class SekolahEntity extends Equatable {
  final int? id;
  final String? uuid;
  final String? npsn;
  final String namaSekolah;
  final String? alamat;
  final String? logoUrl;
  final String? subscriptionPlan;
  final bool isActive;

  const SekolahEntity({
    this.id,
    this.uuid,
    this.npsn,
    required this.namaSekolah,
    this.alamat,
    this.logoUrl,
    this.subscriptionPlan,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, uuid, namaSekolah];
}

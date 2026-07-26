import '../../domain/entities/forum_entity.dart';

/// Model post forum — parsing manual dari `ForumResource` backend.
///
/// Field yang benar-benar dikirim `App\Http\Resources\Api\V1\ForumResource`:
/// `id`, `sekolah_id`, `kelas_id`, `mapel_id`, `created_by`, `judul`, `konten`,
/// `tipe`, `status`, `is_anonymous`, `view_count`, `reply_count`,
/// `last_reply_at`, `metadata`, `kelas{id,nama_kelas}`, `mapel{id,nama_mapel}`,
/// `createdBy{id,name}`, `created_at`, `updated_at`.
class ForumModel {
  final int id;
  final int? sekolahId;
  final int? kelasId;
  final int? mapelId;
  final int? createdBy;
  final String judul;
  final String konten;
  final int? tipe;
  final int? status;
  final bool isAnonymous;
  final int viewCount;
  final int replyCount;
  final String? lastReplyAt;
  final String? kelasNama;
  final String? mapelNama;
  final String? penulisNama;
  final String? createdAt;
  final String? updatedAt;

  const ForumModel({
    required this.id,
    this.sekolahId,
    this.kelasId,
    this.mapelId,
    this.createdBy,
    required this.judul,
    required this.konten,
    this.tipe,
    this.status,
    this.isAnonymous = false,
    this.viewCount = 0,
    this.replyCount = 0,
    this.lastReplyAt,
    this.kelasNama,
    this.mapelNama,
    this.penulisNama,
    this.createdAt,
    this.updatedAt,
  });

  factory ForumModel.fromJson(Map<String, dynamic> json) {
    final kelas = json['kelas'];
    final mapel = json['mapel'];
    // Resource memakai key camelCase `createdBy` untuk relasi penulis.
    // `created_by` di level atas adalah id (scalar), bukan objek.
    final penulis = json['createdBy'];

    return ForumModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      sekolahId: (json['sekolah_id'] as num?)?.toInt(),
      kelasId:
          (json['kelas_id'] as num?)?.toInt() ??
          (kelas is Map ? (kelas['id'] as num?)?.toInt() : null),
      mapelId:
          (json['mapel_id'] as num?)?.toInt() ??
          (mapel is Map ? (mapel['id'] as num?)?.toInt() : null),
      createdBy:
          (json['created_by'] as num?)?.toInt() ??
          (penulis is Map ? (penulis['id'] as num?)?.toInt() : null),
      judul: json['judul'] as String? ?? '(Tanpa judul)',
      konten: json['konten'] as String? ?? '',
      tipe: (json['tipe'] as num?)?.toInt(),
      status: (json['status'] as num?)?.toInt(),
      isAnonymous: _asBool(json['is_anonymous']),
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
      lastReplyAt: json['last_reply_at'] as String?,
      kelasNama: kelas is Map ? kelas['nama_kelas'] as String? : null,
      mapelNama: mapel is Map ? mapel['nama_mapel'] as String? : null,
      penulisNama: penulis is Map ? penulis['name'] as String? : null,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  /// Backend PostgreSQL bisa mengirim boolean sebagai `true`, `1`, atau `"1"`.
  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == '1';
    }
    return false;
  }

  ForumEntity toEntity() => ForumEntity(
    id: id,
    sekolahId: sekolahId,
    kelasId: kelasId,
    mapelId: mapelId,
    createdBy: createdBy,
    judul: judul,
    konten: konten,
    tipe: tipe,
    status: status,
    isAnonymous: isAnonymous,
    viewCount: viewCount,
    replyCount: replyCount,
    lastReplyAt: lastReplyAt,
    kelasNama: kelasNama,
    mapelNama: mapelNama,
    penulisNama: penulisNama,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

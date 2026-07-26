import 'package:equatable/equatable.dart';

/// Entity untuk satu post forum diskusi (tabel `trx_forum`).
///
/// CATATAN PENTING: backend TIDAK punya konsep balasan/threading.
/// Tabel `trx_forum` tidak memiliki `parent_id`, tidak ada tabel balasan,
/// dan tidak ada relasi `replies` pada model `TrxForum`. Kolom `reply_count`
/// dan `last_reply_at` hanya counter denormalisasi yang tidak pernah diisi
/// oleh endpoint mana pun. Jadi forum ini adalah daftar post datar.
class ForumEntity extends Equatable {
  final int id;

  /// `sekolah_id` — dibutuhkan saat membuat post baru (wajib di FormRequest).
  final int? sekolahId;

  /// `kelas_id` — null berarti forum lingkup sekolah.
  final int? kelasId;

  /// `mapel_id` — null berarti forum umum (tanpa mapel).
  final int? mapelId;

  /// `created_by` — id `sys_users` penulis post.
  final int? createdBy;

  final String judul;
  final String konten;

  /// 1 = diskusi, 2 = pertanyaan, 3 = pengumuman
  final int? tipe;

  /// 0 = ditutup, 1 = terbuka, 2 = disematkan
  final int? status;

  final bool isAnonymous;
  final int viewCount;

  /// Selalu 0 di praktiknya — tidak ada endpoint yang menaikkannya.
  final int replyCount;

  /// ISO8601 atau null.
  final String? lastReplyAt;

  // ── Relasi (hanya terisi bila di-eager load backend) ───────────────────────
  final String? kelasNama;
  final String? mapelNama;

  /// Nama penulis dari relasi `createdBy` (hanya ada di endpoint index & show,
  /// TIDAK ada di endpoint `/forum/user/{userId}`).
  final String? penulisNama;

  final String? createdAt;
  final String? updatedAt;

  const ForumEntity({
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

  DateTime? get createdAtDate =>
      createdAt == null ? null : DateTime.tryParse(createdAt!)?.toLocal();

  DateTime? get updatedAtDate =>
      updatedAt == null ? null : DateTime.tryParse(updatedAt!)?.toLocal();

  /// True bila post pernah diubah setelah dibuat (selisih > 1 detik).
  bool get pernahDiubah {
    final c = createdAtDate;
    final u = updatedAtDate;
    if (c == null || u == null) return false;
    return u.difference(c).inSeconds > 1;
  }

  /// Nama yang ditampilkan; post anonim menyembunyikan identitas penulis.
  String get penulisLabel {
    if (isAnonymous) return 'Anonim';
    final nama = penulisNama;
    if (nama != null && nama.trim().isNotEmpty) return nama;
    return 'Pengguna';
  }

  /// Inisial untuk avatar bulat, maksimal 2 huruf.
  String get penulisInisial {
    final parts = penulisLabel
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  /// Cuplikan isi untuk kartu daftar (baris baru diratakan jadi spasi).
  String get cuplikan {
    final rata = konten.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (rata.length <= 140) return rata;
    return '${rata.substring(0, 140)}…';
  }

  /// Label konteks: "Matematika · X IPA 1" / "Umum".
  String get konteksLabel {
    final bagian = <String>[
      if (mapelNama != null && mapelNama!.isNotEmpty) mapelNama!,
      if (kelasNama != null && kelasNama!.isNotEmpty) kelasNama!,
    ];
    if (bagian.isEmpty) return 'Umum';
    return bagian.join(' · ');
  }

  bool get isDisematkan => status == 2;
  bool get isDitutup => status == 0;

  /// Post ini milik user dengan id [userId]?
  bool milikUser(int? userId) =>
      userId != null && createdBy != null && createdBy == userId;

  @override
  List<Object?> get props => [id];
}

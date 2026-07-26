import 'package:equatable/equatable.dart';

/// Jenis lampiran utama pada sebuah materi — dipakai untuk ikon & label kartu.
enum MateriTipe {
  dokumen('Dokumen'),
  video('Video'),
  teks('Teks');

  final String label;
  const MateriTipe(this.label);
}

/// Entity untuk satu materi pembelajaran (tabel `mst_materi`).
///
/// Sumber field: `MateriResource` backend —
/// `id`, `mst_guru_mapel_id`, `judul`, `deskripsi`, `file_materi`,
/// `link_video`, `status`, `status_label`, `guru_mapel{guru,mapel}`,
/// `created_at`, `updated_at`.
class MateriEntity extends Equatable {
  final int id;

  /// `mst_guru_mapel_id`
  final int? guruMapelId;

  final String judul;
  final String? deskripsi;

  /// `file_materi` — kolom varchar(255). Bisa berupa URL penuh ATAU path
  /// relatif di storage (backend tidak menormalisasi nilainya).
  final String? fileMateri;

  /// `link_video` — kolom varchar(255), biasanya tautan YouTube/Drive.
  final String? linkVideo;

  /// 1 = Aktif, 0 = Draft
  final int? status;
  final String? statusLabel;

  // ── Relasi guru_mapel ──────────────────────────────────────────────────────
  final int? guruId;
  final String? guruNama;
  final int? mapelId;
  final String? mapelKode;
  final String? mapelNama;

  /// ISO8601, mis. "2026-07-20T09:15:00+07:00"
  final String? createdAt;
  final String? updatedAt;

  const MateriEntity({
    required this.id,
    this.guruMapelId,
    required this.judul,
    this.deskripsi,
    this.fileMateri,
    this.linkVideo,
    this.status,
    this.statusLabel,
    this.guruId,
    this.guruNama,
    this.mapelId,
    this.mapelKode,
    this.mapelNama,
    this.createdAt,
    this.updatedAt,
  });

  DateTime? get createdAtDate =>
      createdAt == null ? null : DateTime.tryParse(createdAt!);

  DateTime? get updatedAtDate =>
      updatedAt == null ? null : DateTime.tryParse(updatedAt!);

  bool get isAktif => status == 1;

  bool get punyaFile => fileMateri != null && fileMateri!.trim().isNotEmpty;

  bool get punyaVideo => linkVideo != null && linkVideo!.trim().isNotEmpty;

  bool get punyaLampiran => punyaFile || punyaVideo;

  MateriTipe get tipe {
    if (punyaVideo) return MateriTipe.video;
    if (punyaFile) return MateriTipe.dokumen;
    return MateriTipe.teks;
  }

  /// Nama mata pelajaran untuk header pengelompokan.
  String get mapelLabel {
    if (mapelNama != null && mapelNama!.isNotEmpty) return mapelNama!;
    if (mapelKode != null && mapelKode!.isNotEmpty) return mapelKode!;
    return 'Tanpa Mata Pelajaran';
  }

  String get guruLabel =>
      (guruNama != null && guruNama!.isNotEmpty) ? guruNama! : 'Guru pengampu';

  /// Ekstensi berkas huruf kecil tanpa titik (mis. "pdf"), null bila tak jelas.
  String? get ekstensiFile {
    if (!punyaFile) return null;
    final bersih = fileMateri!.trim().split('?').first.split('#').first;
    final nama = bersih.split('/').last;
    final titik = nama.lastIndexOf('.');
    if (titik <= 0 || titik == nama.length - 1) return null;
    final ext = nama.substring(titik + 1).toLowerCase();
    return ext.length > 5 ? null : ext;
  }

  /// Teks yang dipakai untuk pencarian client-side.
  String get haystack => [
    judul,
    deskripsi ?? '',
    mapelNama ?? '',
    mapelKode ?? '',
    guruNama ?? '',
  ].join(' ').toLowerCase();

  @override
  List<Object?> get props => [id];
}

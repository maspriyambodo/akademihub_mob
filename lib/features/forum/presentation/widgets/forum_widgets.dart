import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/forum_entity.dart';
import 'forum_visuals.dart';

/// Aksi pada menu kartu / app bar detail.
enum ForumAksi { ubah, hapus }

/// Kartu satu topik di daftar forum.
class ForumCard extends StatelessWidget {
  final ForumEntity post;
  final bool bolehUbah;
  final bool bolehHapus;
  final bool milikSaya;
  final VoidCallback onTap;
  final ValueChanged<ForumAksi> onAksi;

  const ForumCard({
    super.key,
    required this.post,
    required this.bolehUbah,
    required this.bolehHapus,
    required this.milikSaya,
    required this.onTap,
    required this.onAksi,
  });

  @override
  Widget build(BuildContext context) {
    final tipe = forumTipeOf(post.tipe);
    final adaMenu = bolehUbah || bolehHapus;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Baris atas: badge tipe/status + menu aksi ──────────────────
              Row(
                children: [
                  ForumBadge(
                    label: tipe.label,
                    color: tipe.color,
                    icon: tipe.icon,
                  ),
                  if (post.isDisematkan) ...[
                    const SizedBox(width: 6),
                    const ForumBadge(
                      label: 'Disematkan',
                      color: AppColors.warning,
                      icon: Icons.push_pin_outlined,
                    ),
                  ],
                  if (post.isDitutup) ...[
                    const SizedBox(width: 6),
                    const ForumBadge(
                      label: 'Ditutup',
                      color: AppColors.textSecondary,
                      icon: Icons.lock_outline,
                    ),
                  ],
                  const Spacer(),
                  if (adaMenu)
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: PopupMenuButton<ForumAksi>(
                        padding: EdgeInsets.zero,
                        tooltip: 'Aksi topik',
                        icon: const Icon(
                          Icons.more_vert,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onSelected: onAksi,
                        itemBuilder: (_) => [
                          if (bolehUbah)
                            const PopupMenuItem(
                              value: ForumAksi.ubah,
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.edit_outlined, size: 18),
                                title: Text('Ubah'),
                              ),
                            ),
                          if (bolehHapus)
                            const PopupMenuItem(
                              value: ForumAksi.hapus,
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                title: Text(
                                  'Hapus',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 8),

              // ── Judul ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  post.judul,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // ── Cuplikan isi ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  post.cuplikan,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Baris bawah: penulis + waktu relatif ──────────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: tipe.color.withAlpha(35),
                    child: Text(
                      post.penulisInisial,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: tipe.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      post.penulisLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (milikSaya) ...[
                    const SizedBox(width: 4),
                    const Text(
                      '(Anda)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  const Text(
                    '·',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      waktuRelatif(post.createdAtDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // reply_count hanya ditampilkan bila > 0. Backend TIDAK punya
                  // fitur balasan, jadi praktis selalu 0 — ditampilkan sekadar
                  // menghormati data yang mungkin diisi dari sisi lain.
                  if (post.replyCount > 0) ...[
                    const Icon(
                      Icons.mode_comment_outlined,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${post.replyCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  const Icon(
                    Icons.visibility_outlined,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${post.viewCount}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),

              // ── Konteks mapel/kelas ───────────────────────────────────────
              if (post.mapelNama != null || post.kelasNama != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.label_outline,
                      size: 12,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        post.konteksLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog konfirmasi hapus. Mengembalikan true bila user menekan "Hapus".
Future<bool> konfirmasiHapusForum(BuildContext context, String judul) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hapus Topik?'),
      content: Text(
        'Topik "$judul" akan dihapus. Tindakan ini tidak dapat dibatalkan '
        'dari aplikasi.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  return hasil ?? false;
}

/// Tampilan error dengan tombol coba lagi (privat per fitur).
class ForumErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ForumErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tampilan kosong (privat per fitur).
class ForumEmptyView extends StatelessWidget {
  final String message;

  const ForumEmptyView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

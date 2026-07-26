import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/forum_entity.dart';
import '../bloc/forum_bloc.dart';
import '../bloc/forum_detail_bloc.dart';
import '../widgets/forum_visuals.dart';
import '../widgets/forum_widgets.dart';
import 'forum_form_page.dart';

/// Halaman detail satu topik forum.
///
/// CATATAN: backend tidak punya konsep balasan (tidak ada `parent_id`,
/// tabel balasan, maupun endpoint balasan), jadi halaman ini menampilkan
/// isi post saja — tidak ada daftar balasan maupun form tulis balasan.
///
/// Halaman ini dibuka dengan `Navigator.push` dan menerima `ForumBloc`
/// milik halaman daftar lewat `BlocProvider.value` supaya aksi ubah/hapus
/// tetap satu sumber kebenaran.
class ForumDetailPage extends StatelessWidget {
  final int forumId;

  /// Data dari daftar untuk render instan sebelum detail selesai dimuat.
  final ForumEntity? postAwal;

  const ForumDetailPage({super.key, required this.forumId, this.postAwal});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ForumDetailBloc>()..add(ForumDetailLoadRequested(forumId)),
      child: _ForumDetailView(forumId: forumId, postAwal: postAwal),
    );
  }
}

class _ForumDetailView extends StatelessWidget {
  final int forumId;
  final ForumEntity? postAwal;

  const _ForumDetailView({required this.forumId, this.postAwal});

  ForumLoaded? _listState(BuildContext context) {
    final state = context.read<ForumBloc>().state;
    return state is ForumLoaded ? state : null;
  }

  Future<void> _ubah(BuildContext context, ForumEntity post) async {
    final forumBloc = context.read<ForumBloc>();
    final detailBloc = context.read<ForumDetailBloc>();

    final hasil = await Navigator.of(context).push<ForumFormResult>(
      MaterialPageRoute(builder: (_) => ForumFormPage(awal: post)),
    );
    if (hasil == null) return;

    forumBloc.add(
      ForumUpdateRequested(
        id: post.id,
        judul: hasil.judul,
        konten: hasil.konten,
        tipe: hasil.tipe,
        isAnonymous: hasil.isAnonymous,
      ),
    );
    detailBloc.add(const ForumDetailRefreshRequested());
  }

  Future<void> _hapus(BuildContext context, ForumEntity post) async {
    final forumBloc = context.read<ForumBloc>();
    final navigator = Navigator.of(context);

    final setuju = await konfirmasiHapusForum(context, post.judul);
    if (!setuju) return;

    forumBloc.add(ForumDeleteRequested(post.id));
    // Daftar akan menampilkan SnackBar hasil aksi; kembali ke daftar.
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Topik'),
        centerTitle: true,
        actions: [
          BlocBuilder<ForumDetailBloc, ForumDetailState>(
            builder: (context, state) {
              final post = state is ForumDetailLoaded ? state.post : postAwal;
              if (post == null) return const SizedBox.shrink();

              final listState = _listState(context);
              final bolehUbah = listState?.bolehUbah(post) ?? false;
              final bolehHapus = listState?.bolehHapus(post) ?? false;
              if (!bolehUbah && !bolehHapus) return const SizedBox.shrink();

              return PopupMenuButton<ForumAksi>(
                tooltip: 'Aksi topik',
                onSelected: (aksi) {
                  if (aksi == ForumAksi.ubah) {
                    _ubah(context, post);
                  } else {
                    _hapus(context, post);
                  }
                },
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
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ForumDetailBloc, ForumDetailState>(
        builder: (context, state) {
          if (state is ForumDetailError) {
            // Bila data dari daftar tersedia, tetap tampilkan itu daripada
            // memaksa layar error kosong.
            if (postAwal == null) {
              return ForumErrorView(
                message: state.message,
                onRetry: () => context.read<ForumDetailBloc>().add(
                  ForumDetailLoadRequested(forumId),
                ),
              );
            }
            return _Isi(post: postAwal!);
          }

          final post = state is ForumDetailLoaded ? state.post : postAwal;
          if (post == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _Isi(post: post);
        },
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  final ForumEntity post;

  const _Isi({required this.post});

  @override
  Widget build(BuildContext context) {
    final tipe = forumTipeOf(post.tipe);
    final listState = context.select<ForumBloc, ForumLoaded?>(
      (bloc) => bloc.state is ForumLoaded ? bloc.state as ForumLoaded : null,
    );
    final milikSaya = post.milikUser(listState?.userId);

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ForumDetailBloc>().add(
          const ForumDetailRefreshRequested(),
        );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Badge ────────────────────────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ForumBadge(label: tipe.label, color: tipe.color, icon: tipe.icon),
              ForumBadge(
                label: forumStatusLabel(post.status),
                color: forumStatusColor(post.status),
                icon: post.isDitutup
                    ? Icons.lock_outline
                    : (post.isDisematkan
                          ? Icons.push_pin_outlined
                          : Icons.lock_open_outlined),
              ),
              if (post.mapelNama != null || post.kelasNama != null)
                ForumBadge(
                  label: post.konteksLabel,
                  color: AppColors.textSecondary,
                  icon: Icons.label_outline,
                ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Judul ────────────────────────────────────────────────────────
          Text(
            post.judul,
            style: const TextStyle(
              fontSize: 19,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // ── Penulis + waktu ──────────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: tipe.color.withAlpha(35),
                child: Text(
                  post.penulisInisial,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: tipe.color,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.penulisLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (milikSaya) ...[
                          const SizedBox(width: 6),
                          const ForumBadge(
                            label: 'Anda',
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${waktuRelatif(post.createdAtDate)} · '
                      '${waktuLengkap(post.createdAtDate)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (post.pernahDiubah)
                      Text(
                        'Diubah ${waktuRelatif(post.updatedAtDate)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textHint,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // ── Isi lengkap ──────────────────────────────────────────────────
          SelectableText(
            post.konten.isEmpty ? '(Tidak ada isi)' : post.konten,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // ── Statistik ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${post.viewCount} dilihat',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (post.replyCount > 0) ...[
                  const SizedBox(width: 18),
                  const Icon(
                    Icons.mode_comment_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${post.replyCount} balasan',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Penjelasan jujur ke pengguna: fitur balasan memang belum ada
          // di backend, bukan sekadar belum dipasang di aplikasi.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.info),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Balasan pada topik belum tersedia. Untuk menanggapi, '
                    'buat topik baru yang merujuk topik ini.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

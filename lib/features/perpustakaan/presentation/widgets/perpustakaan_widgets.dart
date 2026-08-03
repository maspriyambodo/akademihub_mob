import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/buku_entity.dart';
import '../../domain/entities/peminjaman_buku_entity.dart';
import 'perpustakaan_format.dart';

// ── Error / Empty ────────────────────────────────────────────────────────────

class PerpustakaanErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const PerpustakaanErrorView({
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

class PerpustakaanEmptyView extends StatelessWidget {
  final String message;
  final IconData icon;

  const PerpustakaanEmptyView({
    super.key,
    required this.message,
    this.icon = Icons.menu_book_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint),
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

/// Badge kecil berwarna (dipakai untuk status & ketersediaan).
class PerpustakaanBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const PerpustakaanBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Batas lebar supaya label panjang meng-ellipsis, bukan meluber
      // keluar dari kartu di layar sempit.
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kartu buku (tab Katalog) ─────────────────────────────────────────────────

class BukuCard extends StatelessWidget {
  final BukuEntity buku;
  final VoidCallback onTap;

  const BukuCard({super.key, required this.buku, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final warna = warnaKetersediaan(buku.stok);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buku.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      buku.penulis?.isNotEmpty == true
                          ? buku.penulis!
                          : 'Pengarang tidak diketahui',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (buku.penerbit != null || buku.tahun != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (buku.penerbit?.isNotEmpty == true) buku.penerbit!,
                          if (buku.tahun != null) '${buku.tahun}',
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    PerpustakaanBadge(
                      label: teksKetersediaan(buku.stok),
                      color: warna,
                      icon: buku.tersedia
                          ? Icons.check_circle_outline
                          : Icons.remove_circle_outline,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Kartu peminjaman (tab Peminjaman) ────────────────────────────────────────

class PeminjamanCard extends StatelessWidget {
  final PeminjamanBukuEntity item;

  /// Hasil gabungan perhitungan lokal + endpoint `/overdue`.
  final bool terlambat;

  /// Tampilkan nama siswa (untuk admin/guru/wali).
  final bool tampilkanSiswa;

  /// Tampilkan tombol "Proses Kembali" (permission `peminjaman.pengembalian`).
  final bool canPengembalian;

  final VoidCallback? onPengembalian;

  const PeminjamanCard({
    super.key,
    required this.item,
    required this.terlambat,
    this.tampilkanSiswa = false,
    this.canPengembalian = false,
    this.onPengembalian,
  });

  @override
  Widget build(BuildContext context) {
    final warna = warnaStatus(item, terlambat: terlambat);
    final tenggat = teksTenggat(item, terlambat: terlambat);
    final bisaDikembalikan =
        canPengembalian && !item.sudahDikembalikan && !item.hilang;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: terlambat
            ? const BorderSide(color: AppColors.error, width: 1.4)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.bukuJudul?.isNotEmpty == true
                        ? item.bukuJudul!
                        : 'Buku #${item.bukuId ?? '-'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PerpustakaanBadge(label: item.statusLabel, color: warna),
              ],
            ),
            if (tampilkanSiswa && item.siswaNama != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.siswaNis != null
                          ? '${item.siswaNama} • ${item.siswaNis}'
                          : item.siswaNama!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _KolomTanggal(
                    label: 'Dipinjam',
                    nilai: formatTanggal(item.tanggalPinjam),
                  ),
                ),
                Expanded(
                  child: _KolomTanggal(
                    label: 'Jatuh Tempo',
                    nilai: formatTanggal(item.tanggalJatuhTempo),
                    warna: terlambat ? AppColors.error : null,
                  ),
                ),
                Expanded(
                  child: _KolomTanggal(
                    label: 'Kembali',
                    nilai: formatTanggal(item.tanggalKembali, kosong: 'Belum'),
                    warna: item.dikembalikanTerlambat
                        ? AppColors.warning
                        : null,
                  ),
                ),
              ],
            ),
            if (tenggat != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: warna.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      terlambat
                          ? Icons.warning_amber_rounded
                          : Icons.schedule_outlined,
                      size: 15,
                      color: warna,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tenggat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: warna,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (item.sudahDikembalikan && item.dikembalikanTerlambat) ...[
              const SizedBox(height: 8),
              const Text(
                'Dikembalikan melewati jatuh tempo',
                style: TextStyle(fontSize: 11, color: AppColors.warning),
              ),
            ],
            if (bisaDikembalikan) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onPengembalian,
                  icon: const Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 18,
                  ),
                  label: const Text('Proses Pengembalian'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 40),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KolomTanggal extends StatelessWidget {
  final String label;
  final String nilai;
  final Color? warna;

  const _KolomTanggal({required this.label, required this.nilai, this.warna});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: AppColors.textHint),
        ),
        const SizedBox(height: 2),
        // Tanggal harus muat pada kolom sempit (3 kolom di layar 320dp).
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            nilai,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: warna ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/organisasi_anggota_entity.dart';
import '../../domain/entities/organisasi_entity.dart';

/// Badge kecil berlabel + warna (dipakai untuk status organisasi & anggota).
class OrganisasiStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const OrganisasiStatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Warna badge status anggota: 1=aktif (hijau), 2=alumni (biru info),
/// lainnya nonaktif (abu).
Color warnaStatusAnggota(int status) => switch (status) {
  1 => AppColors.success,
  2 => AppColors.info,
  _ => AppColors.textSecondary,
};

/// Avatar bulat berisi inisial nama; warna latar deterministik dari nama.
class InisialAvatar extends StatelessWidget {
  final String nama;
  final String inisial;
  final double radius;

  const InisialAvatar({
    super.key,
    required this.nama,
    required this.inisial,
    this.radius = 20,
  });

  static const List<Color> _palet = [
    Color(0xFF1565C0),
    Color(0xFF00897B),
    Color(0xFF6A1B9A),
    Color(0xFFEF6C00),
    Color(0xFF2E7D32),
    Color(0xFFC62828),
    Color(0xFF283593),
    Color(0xFF00838F),
  ];

  @override
  Widget build(BuildContext context) {
    final warna = _palet[nama.hashCode.abs() % _palet.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: warna.withAlpha(31),
      child: Text(
        inisial,
        style: TextStyle(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w700,
          color: warna,
        ),
      ),
    );
  }
}

/// Kartu satu organisasi pada daftar utama.
class OrganisasiCard extends StatelessWidget {
  final OrganisasiEntity organisasi;
  final VoidCallback onTap;

  const OrganisasiCard({
    super.key,
    required this.organisasi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            organisasi.nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OrganisasiStatusBadge(
                          label: organisasi.statusLabel,
                          color: organisasi.isAktif
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (organisasi.hasPembina)
                      _InfoBaris(
                        icon: Icons.person_outline,
                        teks: 'Pembina: ${organisasi.pembinaNama}',
                      ),
                    _InfoBaris(
                      icon: Icons.calendar_today_outlined,
                      teks: organisasi.periodeLabel == null
                          ? 'Periode belum diatur'
                          : 'Periode ${organisasi.periodeLabel}',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBaris extends StatelessWidget {
  final IconData icon;
  final String teks;

  const _InfoBaris({required this.icon, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              teks,
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
    );
  }
}

/// Baris satu anggota di dalam kartu jabatan.
class AnggotaTile extends StatelessWidget {
  final OrganisasiAnggotaEntity anggota;

  const AnggotaTile({super.key, required this.anggota});

  @override
  Widget build(BuildContext context) {
    final masa = anggota.masaKeanggotaanLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          InisialAvatar(nama: anggota.siswaNama, inisial: anggota.inisial),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anggota.siswaNama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (anggota.siswaNis != null &&
                    anggota.siswaNis!.trim().isNotEmpty)
                  Text(
                    'NIS ${anggota.siswaNis}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (masa != null)
                  Text(
                    masa,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OrganisasiStatusBadge(
            label: anggota.statusLabel,
            color: warnaStatusAnggota(anggota.status),
          ),
        ],
      ),
    );
  }
}

/// Kartu satu jabatan pada struktur kepengurusan beserta daftar anggotanya.
class JabatanStrukturCard extends StatelessWidget {
  final String namaJabatan;
  final List<OrganisasiAnggotaEntity> anggota;

  const JabatanStrukturCard({
    super.key,
    required this.namaJabatan,
    required this.anggota,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(16),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_outlined,
                  size: 17,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    namaJabatan,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  '${anggota.length} orang',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < anggota.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 66,
                endIndent: 14,
                color: AppColors.divider,
              ),
            AnggotaTile(anggota: anggota[i]),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

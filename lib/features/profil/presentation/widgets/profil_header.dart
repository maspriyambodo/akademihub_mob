import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import 'profil_visuals.dart';

/// Header profil: avatar (foto bila ada, selain itu inisial), nama, email,
/// dan chip role berwarna sesuai peran.
class ProfilHeader extends StatelessWidget {
  final UserEntity user;

  const ProfilHeader({super.key, required this.user});

  /// `UserResource` saat ini belum mengirim foto profil. Kalau nanti field
  /// tersebut ditambahkan (salah satu key di bawah, berupa URL absolut),
  /// avatar otomatis memakainya.
  String? get _fotoUrl {
    final raw = nilaiProfil(user.profile, const [
      'foto_url',
      'foto',
      'foto_path',
      'photo_url',
      'avatar',
      'avatar_url',
    ]);
    if (raw == null) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return null; // path relatif → tidak bisa dipastikan base URL-nya
  }

  @override
  Widget build(BuildContext context) {
    final warna = warnaRole(user.role);
    final foto = _fotoUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            clipBehavior: Clip.antiAlias,
            child: foto != null
                ? CachedNetworkImage(
                    imageUrl: foto,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        _Inisial(nama: user.name, warna: warna),
                    errorWidget: (context, url, error) =>
                        _Inisial(nama: user.name, warna: warna),
                  )
                : _Inisial(nama: user.name, warna: warna),
          ),
          const SizedBox(height: 14),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(220)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _RoleChip(role: user.role),
              if (!user.isActive)
                const _StatusChip(
                  label: 'Nonaktif',
                  warna: AppColors.error,
                  ikon: Icons.block,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Inisial extends StatelessWidget {
  final String nama;
  final Color warna;

  const _Inisial({required this.nama, required this.warna});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: warna.withAlpha(45),
      alignment: Alignment.center,
      child: Text(
        inisialNama(nama),
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: warna,
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String? role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final warna = warnaRole(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikonRole(role), size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            labelRole(role),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color warna;
  final IconData ikon;

  const _StatusChip({
    required this.label,
    required this.warna,
    required this.ikon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

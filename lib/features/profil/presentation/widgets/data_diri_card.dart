import 'package:flutter/material.dart';

import '../../../auth/domain/entities/user_entity.dart';
import 'profil_info_card.dart';
import 'profil_visuals.dart';

/// Kartu "Data Diri". Isinya menyesuaikan role dan HANYA menampilkan field
/// yang benar-benar ada di `profile` hasil `GET /auth/me` — tidak pernah ada
/// baris kosong.
///
/// Bentuk `profile` per role (lihat `UserResource@toArray`):
/// - SISWA      : { id, nis, nama, jenis_kelamin, kelas: { id, nama_kelas } }
/// - GURU       : { id, mst_guru_id, nip, nama, jenis_kelamin, no_hp }
/// - WALI_SISWA : { nama, no_hp }
///
/// Field lain (tempat/tanggal lahir, alamat, no HP siswa, mapel guru) belum
/// dikirim backend, tetapi tetap dibaca di sini supaya otomatis tampil bila
/// suatu saat `UserResource` diperluas.
class DataDiriCard extends StatelessWidget {
  final UserEntity user;

  const DataDiriCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final rows = _bangunBaris();

    return ProfilInfoCard(
      judul: 'Data Diri',
      ikon: Icons.badge_outlined,
      warnaIkon: warnaRole(user.role),
      children: rows.isEmpty
          ? const [
              ProfilCardMessage(
                ikon: Icons.info_outline,
                pesan: 'Data diri belum tersedia untuk akun ini',
              ),
            ]
          : rows,
    );
  }

  List<Widget> _bangunBaris() {
    final profile = user.profile;
    final role = normalisasiRole(user.role);
    final rows = <Widget>[];

    void tambah(IconData ikon, String label, String? nilai) {
      if (nilai == null || nilai.trim().isEmpty) return;
      rows.add(ProfilInfoRow(ikon: ikon, label: label, nilai: nilai.trim()));
    }

    final jk = formatJenisKelamin(profile?['jenis_kelamin']);
    final noHp = nilaiProfil(profile, const ['no_hp', 'telp_hp', 'telepon']);
    final namaProfil = nilaiProfil(profile, const ['nama']);

    switch (role) {
      case 'siswa':
        {
          tambah(Icons.tag, 'NIS', nilaiProfil(profile, const ['nis']));
          tambah(
            Icons.badge_outlined,
            'NISN',
            nilaiProfil(profile, const ['nisn']),
          );
          tambah(Icons.class_outlined, 'Kelas', _namaKelas(profile));
          tambah(Icons.wc_outlined, 'Jenis Kelamin', jk);
          tambah(
            Icons.cake_outlined,
            'Tempat, Tgl Lahir',
            _tempatTanggalLahir(profile),
          );
          tambah(
            Icons.home_outlined,
            'Alamat',
            nilaiProfil(profile, const ['alamat']),
          );
          tambah(Icons.phone_outlined, 'No. HP', noHp);
        }
        break;

      case 'guru':
        tambah(Icons.tag, 'NIP', nilaiProfil(profile, const ['nip']));
        tambah(Icons.wc_outlined, 'Jenis Kelamin', jk);
        tambah(Icons.menu_book_outlined, 'Mapel Diampu', _mapelDiampu(profile));
        tambah(Icons.phone_outlined, 'No. HP', noHp);
        break;

      case 'wali':
        tambah(Icons.person_outline, 'Nama', namaProfil);
        tambah(Icons.phone_outlined, 'No. HP', noHp);
        break;

      default:
        // Admin & role lain: profil biasanya null, tampilkan seadanya.
        tambah(Icons.person_outline, 'Nama', namaProfil);
        tambah(Icons.wc_outlined, 'Jenis Kelamin', jk);
        tambah(Icons.phone_outlined, 'No. HP', noHp);
    }

    return rows;
  }

  /// Kelas ada di `profile['kelas']['nama_kelas']`; sebagian endpoint lain
  /// mengirimnya sebagai string biasa.
  String? _namaKelas(Map<String, dynamic>? profile) {
    final kelas = profile?['kelas'];
    if (kelas is Map) {
      final nama = kelas['nama_kelas'] ?? kelas['nama'];
      if (nama is String && nama.trim().isNotEmpty) return nama.trim();
      return null;
    }
    if (kelas is String && kelas.trim().isNotEmpty) return kelas.trim();
    return null;
  }

  String? _tempatTanggalLahir(Map<String, dynamic>? profile) {
    final tempat = nilaiProfil(profile, const ['tempat_lahir']);
    final rawTanggal = nilaiProfil(profile, const ['tanggal_lahir']);
    final tanggal = formatTanggal(rawTanggal);
    if (tempat == null && tanggal == null) return null;
    if (tempat == null) return tanggal;
    if (tanggal == null) return tempat;
    return '$tempat, $tanggal';
  }

  /// Mapel bisa berbentuk string, list string, atau list objek
  /// (`{ nama_mapel | nama }`) tergantung relasi yang di-load backend.
  String? _mapelDiampu(Map<String, dynamic>? profile) {
    if (profile == null) return null;

    for (final key in const ['mapel', 'mata_pelajaran', 'mapel_diampu']) {
      final raw = profile[key];
      if (raw == null) continue;

      if (raw is String && raw.trim().isNotEmpty) return raw.trim();

      if (raw is Map) {
        final nama = raw['nama_mapel'] ?? raw['nama'];
        if (nama is String && nama.trim().isNotEmpty) return nama.trim();
        continue;
      }

      if (raw is List) {
        final items = <String>[];
        for (final e in raw) {
          if (e is String && e.trim().isNotEmpty) {
            items.add(e.trim());
          } else if (e is Map) {
            final nama = e['nama_mapel'] ?? e['nama'];
            if (nama is String && nama.trim().isNotEmpty) items.add(nama.trim());
          }
        }
        if (items.isNotEmpty) return items.join(', ');
      }
    }
    return null;
  }
}

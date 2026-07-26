part of 'organisasi_detail_bloc.dart';

/// Filter status anggota pada halaman struktur.
enum StatusAnggotaFilter { semua, aktif, alumni }

/// Satu kelompok jabatan pada struktur kepengurusan, berisi para anggotanya.
/// Dibangun dari relasi `anggota.jabatan` (anggota tanpa jabatan dikelompokkan
/// sebagai "Anggota" di urutan paling bawah).
class JabatanStrukturGroup extends Equatable {
  final int? jabatanId;
  final String nama;

  /// Kolom `urutan` jabatan — kecil = posisi lebih tinggi.
  final int urutan;
  final List<OrganisasiAnggotaEntity> anggota;

  const JabatanStrukturGroup({
    required this.jabatanId,
    required this.nama,
    required this.urutan,
    required this.anggota,
  });

  @override
  List<Object?> get props => [jabatanId, nama, urutan, anggota];
}

abstract class OrganisasiDetailState extends Equatable {
  const OrganisasiDetailState();

  @override
  List<Object?> get props => [];
}

class OrganisasiDetailInitial extends OrganisasiDetailState {}

class OrganisasiDetailLoading extends OrganisasiDetailState {}

class OrganisasiDetailLoaded extends OrganisasiDetailState {
  final OrganisasiDetailEntity detail;
  final String search;
  final StatusAnggotaFilter filterStatus;

  const OrganisasiDetailLoaded({
    required this.detail,
    this.search = '',
    this.filterStatus = StatusAnggotaFilter.semua,
  });

  /// Urutan fallback untuk jabatan tanpa kolom `urutan`.
  static const int _urutanTanpaNilai = 999998;

  /// Urutan kelompok "Anggota" (tanpa jabatan) — selalu paling bawah.
  static const int _urutanTanpaJabatan = 999999;

  /// Anggota setelah filter status + pencarian nama/NIS/jabatan.
  List<OrganisasiAnggotaEntity> get anggotaTersaring {
    final kueri = search.trim().toLowerCase();
    return detail.anggota.where((a) {
      switch (filterStatus) {
        case StatusAnggotaFilter.aktif:
          if (!a.isAktif) return false;
        case StatusAnggotaFilter.alumni:
          if (!a.isAlumni) return false;
        case StatusAnggotaFilter.semua:
          break;
      }
      if (kueri.isEmpty) return true;
      return a.siswaNama.toLowerCase().contains(kueri) ||
          (a.siswaNis ?? '').toLowerCase().contains(kueri) ||
          (a.jabatanNama ?? '').toLowerCase().contains(kueri);
    }).toList();
  }

  /// Struktur kepengurusan: anggota dikelompokkan per jabatan lalu diurutkan
  /// hierarkis (kolom `urutan` jabatan naik, anggota per kelompok
  /// alfabetis).
  List<JabatanStrukturGroup> get struktur {
    final perJabatan = <int?, List<OrganisasiAnggotaEntity>>{};
    for (final a in anggotaTersaring) {
      perJabatan.putIfAbsent(a.jabatanId, () => []).add(a);
    }

    final kelompok = <JabatanStrukturGroup>[];
    perJabatan.forEach((jabatanId, para) {
      para.sort(
        (x, y) =>
            x.siswaNama.toLowerCase().compareTo(y.siswaNama.toLowerCase()),
      );
      final pertama = para.first;
      kelompok.add(
        JabatanStrukturGroup(
          jabatanId: jabatanId,
          nama: jabatanId == null
              ? 'Anggota'
              : (pertama.jabatanNama ?? 'Jabatan #$jabatanId'),
          urutan: jabatanId == null
              ? _urutanTanpaJabatan
              : (pertama.jabatanUrutan ?? _urutanTanpaNilai),
          anggota: para,
        ),
      );
    });

    kelompok.sort((a, b) {
      final banding = a.urutan.compareTo(b.urutan);
      if (banding != 0) return banding;
      return a.nama.toLowerCase().compareTo(b.nama.toLowerCase());
    });
    return kelompok;
  }

  bool get adaFilterAktif =>
      search.trim().isNotEmpty || filterStatus != StatusAnggotaFilter.semua;

  OrganisasiDetailLoaded copyWith({
    OrganisasiDetailEntity? detail,
    String? search,
    StatusAnggotaFilter? filterStatus,
  }) {
    return OrganisasiDetailLoaded(
      detail: detail ?? this.detail,
      search: search ?? this.search,
      filterStatus: filterStatus ?? this.filterStatus,
    );
  }

  @override
  List<Object?> get props => [detail, search, filterStatus];
}

class OrganisasiDetailError extends OrganisasiDetailState {
  final String message;
  const OrganisasiDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

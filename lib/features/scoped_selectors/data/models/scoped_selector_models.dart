class GuruMapelOptionModel {
  final int id;
  final int guruId;
  final int mapelId;
  final String mapelNama;

  const GuruMapelOptionModel({
    required this.id,
    required this.guruId,
    required this.mapelId,
    required this.mapelNama,
  });

  factory GuruMapelOptionModel.fromJson(Map<String, dynamic> json) {
    final mapel = json['mapel'];
    return GuruMapelOptionModel(
      id: (json['id'] as num).toInt(),
      guruId: (json['mst_guru_id'] as num?)?.toInt() ?? 0,
      mapelId: (json['mst_mapel_id'] as num?)?.toInt() ?? 0,
      mapelNama: mapel is Map ? mapel['nama']?.toString() ?? '' : '',
    );
  }
}

class KelasSelectorModel {
  final int id;
  final String nama;

  const KelasSelectorModel({required this.id, required this.nama});

  factory KelasSelectorModel.fromJson(Map<String, dynamic> json) =>
      KelasSelectorModel(
        id: (json['id'] as num).toInt(),
        nama: json['nama_kelas']?.toString() ?? '',
      );
}

class SiswaSelectorModel {
  final int id;
  final String nama;
  final String? nis;

  const SiswaSelectorModel({required this.id, required this.nama, this.nis});

  factory SiswaSelectorModel.fromJson(Map<String, dynamic> json) =>
      SiswaSelectorModel(
        id: (json['id'] as num).toInt(),
        nama: json['nama']?.toString() ?? '',
        nis: json['nis']?.toString(),
      );
}

class UjianSelectorModel {
  final int id;
  final String nama;

  const UjianSelectorModel({required this.id, required this.nama});

  factory UjianSelectorModel.fromJson(Map<String, dynamic> json) =>
      UjianSelectorModel(
        id: (json['id'] as num).toInt(),
        nama: json['nama']?.toString() ?? '',
      );
}

class SemesterSelectorModel {
  final int id;
  final String nama;
  final int? tahunAjaranId;

  const SemesterSelectorModel({
    required this.id,
    required this.nama,
    this.tahunAjaranId,
  });

  factory SemesterSelectorModel.fromJson(Map<String, dynamic> json) =>
      SemesterSelectorModel(
        id: (json['id'] as num).toInt(),
        nama: json['nama']?.toString() ?? '',
        tahunAjaranId: (json['tahun_ajaran_id'] as num?)?.toInt(),
      );
}

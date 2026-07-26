import '../../domain/entities/buku_entity.dart';

/// Parsing manual `BukuResource` backend (tanpa code generation).
class BukuModel {
  final int id;
  final String? isbn;
  final String judul;
  final String? penulis;
  final String? penerbit;
  final int? tahun;
  final int stok;

  const BukuModel({
    required this.id,
    this.isbn,
    required this.judul,
    this.penulis,
    this.penerbit,
    this.tahun,
    this.stok = 0,
  });

  factory BukuModel.fromJson(Map<String, dynamic> json) {
    return BukuModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      isbn: json['isbn'] as String?,
      judul: json['judul'] as String? ?? '(Tanpa judul)',
      penulis: json['penulis'] as String?,
      penerbit: json['penerbit'] as String?,
      tahun: (json['tahun'] as num?)?.toInt(),
      stok: (json['stok'] as num?)?.toInt() ?? 0,
    );
  }

  BukuEntity toEntity() => BukuEntity(
    id: id,
    isbn: isbn,
    judul: judul,
    penulis: penulis,
    penerbit: penerbit,
    tahun: tahun,
    stok: stok,
  );
}

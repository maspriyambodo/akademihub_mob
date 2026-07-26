import 'package:equatable/equatable.dart';

/// Sesi konseling (`trx_bk_sesi`).
///
/// `metode` sudah berupa label dari `sys_references` grup `metode_bk`
/// (Tatap Muka / Online / Telepon) atau angka mentah bila referensi hilang.
class BkSesiEntity extends Equatable {
  final int id;
  final int? kasusId;
  final String? tanggal; // yyyy-MM-dd
  final String? metode;
  final String? catatan;
  final String? createdAt;

  const BkSesiEntity({
    required this.id,
    this.kasusId,
    this.tanggal,
    this.metode,
    this.catatan,
    this.createdAt,
  });

  String get metodeLabel {
    final m = (metode ?? '').trim();
    switch (m) {
      case '1':
        return 'Tatap Muka';
      case '2':
        return 'Online';
      case '3':
        return 'Telepon';
    }
    return m.isEmpty ? '-' : m;
  }

  @override
  List<Object?> get props => [id];
}

import 'package:equatable/equatable.dart';

/// Tindak lanjut kasus BK (`trx_bk_tindakan`).
class BkTindakanEntity extends Equatable {
  final int id;
  final int? kasusId;
  final String? deskripsi;
  final String? createdAt;

  const BkTindakanEntity({
    required this.id,
    this.kasusId,
    this.deskripsi,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}

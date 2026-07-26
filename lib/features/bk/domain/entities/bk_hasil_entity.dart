import 'package:equatable/equatable.dart';

/// Hasil konseling (`trx_bk_hasil`).
class BkHasilEntity extends Equatable {
  final int id;
  final int? kasusId;
  final String? hasil;
  final String? rekomendasi;
  final String? createdAt;

  const BkHasilEntity({
    required this.id,
    this.kasusId,
    this.hasil,
    this.rekomendasi,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}

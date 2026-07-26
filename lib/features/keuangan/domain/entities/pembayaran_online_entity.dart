import 'package:equatable/equatable.dart';

/// Hasil inisiasi pembayaran online via Midtrans SNAP.
///
/// Backend: `PembayaranSppService::initiatePembayaranOnline()`.
/// Endpoint: `POST /keuangan/pembayaran-spp/bayar-online`
/// Body: `mst_siswa_id`, `mst_tarif_spp_id`, `bulan`, `tahun`.
///
/// Response 201 dengan `data`:
/// ```json
/// {
///   "pembayaran_id": 12,
///   "checkout_url": "https://app.sandbox.midtrans.com/snap/v2/vtweb/xxx",
///   "midtrans_order_id": "SPP-3-202601-1769..."
/// }
/// ```
/// Backend mengembalikan URL redirect (bukan hanya snap token), jadi aplikasi
/// cukup membukanya lewat `url_launcher` — tidak perlu Snap SDK native.
/// Status akhir pembayaran masuk lewat webhook `POST v1/webhooks/midtrans`,
/// sehingga aplikasi hanya perlu refresh data setelah user kembali.
class PembayaranOnlineEntity extends Equatable {
  final int? pembayaranId;
  final String? checkoutUrl;
  final String? midtransOrderId;

  const PembayaranOnlineEntity({
    this.pembayaranId,
    this.checkoutUrl,
    this.midtransOrderId,
  });

  bool get punyaUrl => checkoutUrl != null && checkoutUrl!.trim().isNotEmpty;

  @override
  List<Object?> get props => [pembayaranId, checkoutUrl, midtransOrderId];
}

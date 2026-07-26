import '../../domain/entities/pembayaran_online_entity.dart';
import 'keuangan_json.dart';

/// Mapping dari `PembayaranSppService::initiatePembayaranOnline()`.
/// Endpoint: `POST /keuangan/pembayaran-spp/bayar-online` (HTTP 201).
///
/// `data`: `{ "pembayaran_id": 12, "checkout_url": "...", "midtrans_order_id": "..." }`
class PembayaranOnlineModel {
  final int? pembayaranId;
  final String? checkoutUrl;
  final String? midtransOrderId;

  const PembayaranOnlineModel({
    this.pembayaranId,
    this.checkoutUrl,
    this.midtransOrderId,
  });

  factory PembayaranOnlineModel.fromJson(Map<String, dynamic> json) {
    return PembayaranOnlineModel(
      pembayaranId: keuToInt(json['pembayaran_id']),
      // `checkout_url` adalah `redirect_url` dari Midtrans SNAP
      // (lihat MidtransSnapService::createTransaction). Beberapa versi
      // backend juga menyertakan `redirect_url`/`snap_token` — antisipasi.
      checkoutUrl:
          keuToText(json['checkout_url']) ?? keuToText(json['redirect_url']),
      midtransOrderId:
          keuToText(json['midtrans_order_id']) ?? keuToText(json['order_id']),
    );
  }

  PembayaranOnlineEntity toEntity() => PembayaranOnlineEntity(
    pembayaranId: pembayaranId,
    checkoutUrl: checkoutUrl,
    midtransOrderId: midtransOrderId,
  );
}

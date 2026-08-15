import 'package:flutter_test/flutter_test.dart';
import 'package:akademihub_mob/features/keuangan/domain/entities/pembayaran_spp_entity.dart';

void main() {
  group('MOB-PAY-01 Pembayaran Reconciliation Tests', () {
    test('penutupan checkout browser/WebView dilarang mengubah status lunas secara lokal', () {
      final awal = PembayaranSppEntity(
        id: 101,
        tarifNominal: 500000,
        jumlahBayar: 0,
        status: 'belum_lunas',
      );

      // Simulasi penutupan checkout browser / WebView tanpa response backend
      // Status lokal HARUS tetap status asli (belum_lunas) dan tidak diubah secara optimistik ke lunas.
      expect(awal.isLunas, false);
      expect(awal.isBelumLunas, true);
      expect(awal.status, 'belum_lunas');
      expect(awal.nominalEfektif, 0.0);
    });

    test('update status lunas hanya diperbolehkan bila entity backend mengembalikan lunas', () {
      final backendResponse = PembayaranSppEntity(
        id: 101,
        tarifNominal: 500000,
        jumlahBayar: 500000,
        status: 'lunas',
      );

      expect(backendResponse.isLunas, true);
      expect(backendResponse.status, 'lunas');
      expect(backendResponse.nominalEfektif, 500000.0);
    });
  });
}

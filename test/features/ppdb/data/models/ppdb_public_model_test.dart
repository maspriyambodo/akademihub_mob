import 'package:akademihub_mob/features/ppdb/data/models/ppdb_public_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses public PPDB status with nested gelombang', () {
    final model = PpdbStatusPublikModel.fromJson({
      'no_pendaftaran': 'PPDB-2026-001',
      'nama_lengkap': 'Budi Santoso',
      'status_pendaftaran': 'terverifikasi',
      'gelombang': {'nama_gelombang': 'Gelombang 1'},
      'tanggal_daftar': '2026-01-15T10:30:00.000000Z',
    });

    expect(model.noPendaftaran, 'PPDB-2026-001');
    expect(model.namaGelombang, 'Gelombang 1');
    expect(model.status, 'terverifikasi');
    expect(model.tanggalDaftar, isNotNull);
  });

  test('parses successful public registration response', () {
    final model = PpdbPendaftaranPublikModel.fromJson({
      'no_pendaftaran': 'PPDB-2026-002',
      'nama_lengkap': 'Siti Aminah',
      'status_pendaftaran': 'draft',
    });

    expect(model.toEntity().noPendaftaran, 'PPDB-2026-002');
    expect(model.status, 'draft');
  });
}

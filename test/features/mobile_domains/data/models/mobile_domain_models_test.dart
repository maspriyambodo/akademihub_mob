import 'package:akademihub_mob/features/bk/data/models/bk_kasus_model.dart';
import 'package:akademihub_mob/features/ekstrakurikuler/data/models/ekstrakurikuler_model.dart';
import 'package:akademihub_mob/features/ekstrakurikuler/data/models/pendaftaran_ekskul_model.dart';
import 'package:akademihub_mob/features/ews/data/models/ews_alert_model.dart';
import 'package:akademihub_mob/features/siswa_insight/data/models/siswa_insight_model.dart';
import 'package:akademihub_mob/features/tmb/data/models/tmb_peserta_model.dart';
import 'package:akademihub_mob/features/tmb/data/models/tmb_pertanyaan_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses EWS payload including numeric resolver ID', () {
    final alert = EwsAlertModel.fromJson({
      'id': 12,
      'mst_siswa_id': 42,
      'kategori': 'nilai',
      'level': 2,
      'pesan': 'Nilai di bawah standar',
      'data_pendukung': {'rata_rata': 58.75},
      'is_resolved': 1,
      'resolved_by': 7,
      'resolved_at': '2026-08-12T08:00:00+07:00',
    });

    expect(alert.siswaId, 42);
    expect(alert.isResolved, isTrue);
    expect(alert.resolvedBy, '7');
  });

  test('parses BK resource aliases backed by actual columns', () {
    final kasus = BkKasusModel.fromJson({
      'id': 10,
      'siswa': {'id': 5, 'nama': 'Budi', 'nis': '20240001'},
      'guru': {'id': 2, 'nama': 'Ibu Sari'},
      'jenis': {'id': 1, 'kode': 'BK-001', 'nama': 'Bolos'},
      'judul_kasus': 'Kehadiran',
      'tanggal_mulai': '2026-03-15',
      'deskripsi_masalah': 'Bolos lima hari',
      'status': 'dibuka',
    });

    expect(kasus.siswaId, 5);
    expect(kasus.tanggal, '2026-03-15');
    expect(kasus.keterangan, 'Bolos lima hari');
  });

  test('parses TMB participant, questions, options, and embedded results', () {
    final peserta = TmbPesertaModel.fromJson({
      'id': 10,
      'tes_id': 3,
      'siswa_id': 25,
      'status': 2,
      'progress_persen': 100,
      'tes': {'id': 3, 'nama_tes': 'Tes Minat', 'tipe_tes': 1, 'status': 1},
      'hasil': [
        {
          'id': 8,
          'peserta_id': 10,
          'aspek_id': 1,
          'skor_total': 22,
          'skor_persen': 73,
          'interpretasi': 'Dominan',
          'aspek': {'kode_aspek': 'SAIN', 'nama_aspek': 'Sains'},
        },
      ],
    });
    final pertanyaan = TmbPertanyaanModel.fromJson({
      'id': 21,
      'tes_id': 3,
      'aspek_id': 1,
      'pertanyaan': 'Saya menyukai eksperimen',
      'tipe_pertanyaan': 2,
      'nomor_urut': 1,
      'opsi': [
        {'id': 84, 'pertanyaan_id': 21, 'opsi': 'Sesuai', 'nilai': 4},
      ],
    });

    expect(peserta.tes?.namaTes, 'Tes Minat');
    expect(peserta.hasil.single.aspekNama, 'Sains');
    expect(pertanyaan.opsi.single.nilai, 4);
  });

  test('parses Insight 360 aggregate response', () {
    final insight = SiswaInsightModel.fromJson({
      'siswa': {'id': 42, 'nama': 'Budi', 'kelas': 'X IPA 1'},
      'risk_profile': {
        'risk_score': 42,
        'risk_category': 'medium',
        'dimensions': {},
      },
      'kehadiran_summary': {'pct_hadir': 90.9, 'status': 'baik'},
      'ews_summary': {'total_aktif': 1, 'status': 'perlu_perhatian'},
      'activity_heatmap': {'2026-08-12': 3},
      'computed_at': '2026-08-12T09:00:00+07:00',
    }).toEntity();

    expect(insight.namaSiswa, 'Budi');
    expect(insight.riskProfile?['risk_score'], 42);
    expect(insight.activityHeatmap['2026-08-12'], 3);
  });

  test('parses extracurricular catalog and registration resources', () {
    final ekskul = EkstrakurikulerModel.fromJson({
      'id': 4,
      'kode': 'SCI',
      'nama': 'Klub Sains',
      'hari': 'Rabu',
      'jam_mulai': '2026-08-12T15:00:00.000000Z',
      'jam_selesai': '17:00:00',
      'status': 'aktif',
      'pembina': {'id': 2, 'nama': 'Ibu Sari'},
    });
    final pendaftaran = PendaftaranEkskulModel.fromJson({
      'id': 9,
      'ekstrakurikuler_id': 4,
      'siswa_id': 25,
      'tanggal_daftar': '2026-08-12',
      'status': 'aktif',
      'ekstrakurikuler': {'id': 4, 'nama': 'Klub Sains'},
      'siswa': {'id': 25, 'nama': 'Budi', 'nis': '20240001'},
    });

    expect(ekskul.jamMulai, '15:00');
    expect(ekskul.jamSelesai, '17:00');
    expect(pendaftaran.ekstrakurikulerNama, 'Klub Sains');
  });
}

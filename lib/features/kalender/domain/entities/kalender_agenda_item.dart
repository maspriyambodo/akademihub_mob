import 'package:equatable/equatable.dart';

import 'kalender_event_entity.dart';
import 'kalender_harian_entity.dart';
import 'kalender_tipe_entity.dart';

/// Asal data sebuah baris linimasa.
enum KalenderSumber {
  /// Berasal dari `trx_kalender_akademik` (event utama).
  akademik,

  /// Berasal dari `trx_kalender_harian` (catatan/override per hari).
  harian,
}

/// Satu baris pada linimasa agenda — hasil penggabungan event kalender akademik
/// dan agenda harian ke dalam SATU daftar.
///
/// Lihat `KalenderBloc._bangunAgenda()` untuk aturan penggabungannya.
class KalenderAgendaItem extends Equatable {
  /// Kunci unik lintas sumber, mis. `akademik-12` / `harian-345`.
  final String id;

  final KalenderSumber sumber;

  final String judul;
  final String? deskripsi;

  /// "YYYY-MM-DD"
  final String tanggalMulai;

  /// "YYYY-MM-DD"; null bila hanya satu hari.
  final String? tanggalSelesai;

  /// "HH:mm"
  final String? waktuMulai;
  final String? waktuSelesai;

  final KalenderTipeEntity? tipe;
  final String? lokasi;

  /// 0 = dibatalkan, 1 = aktif, 2 = selesai.
  final int status;

  /// 1 = tinggi, 2 = normal, 3 = rendah. Selalu 2 untuk sumber harian.
  final int prioritas;

  final bool isAllDay;

  /// Hanya terisi untuk sumber harian.
  final String? catatan;

  /// Id event kalender akademik terkait (induk untuk sumber harian).
  final int? eventId;

  const KalenderAgendaItem({
    required this.id,
    required this.sumber,
    required this.judul,
    this.deskripsi,
    required this.tanggalMulai,
    this.tanggalSelesai,
    this.waktuMulai,
    this.waktuSelesai,
    this.tipe,
    this.lokasi,
    this.status = 1,
    this.prioritas = 2,
    this.isAllDay = false,
    this.catatan,
    this.eventId,
  });

  factory KalenderAgendaItem.dariEvent(KalenderEventEntity e) =>
      KalenderAgendaItem(
        id: 'akademik-${e.id}',
        sumber: KalenderSumber.akademik,
        judul: e.judul,
        deskripsi: e.deskripsi,
        tanggalMulai: e.tanggalMulai,
        tanggalSelesai: e.tanggalSelesai,
        waktuMulai: e.waktuMulai,
        waktuSelesai: e.waktuSelesai,
        tipe: e.tipe,
        lokasi: e.lokasi,
        status: e.status,
        prioritas: e.prioritas,
        isAllDay: e.isAllDay,
        eventId: e.id,
      );

  factory KalenderAgendaItem.dariHarian(
    KalenderHarianEntity h, {
    KalenderTipeEntity? tipe,
    KalenderEventEntity? induk,
  }) => KalenderAgendaItem(
    id: 'harian-${h.id}',
    sumber: KalenderSumber.harian,
    judul: h.eventJudul ?? induk?.judul ?? 'Agenda harian',
    deskripsi: h.eventDeskripsi ?? induk?.deskripsi,
    tanggalMulai: h.tanggal,
    waktuMulai: induk?.waktuMulai,
    waktuSelesai: induk?.waktuSelesai,
    tipe: tipe ?? induk?.tipe,
    lokasi: h.eventLokasi ?? induk?.lokasi,
    status: h.status,
    catatan: h.catatan,
    eventId: h.kalenderId,
  );

  DateTime? get mulaiDate => DateTime.tryParse(tanggalMulai);

  DateTime? get selesaiDate =>
      tanggalSelesai == null ? null : DateTime.tryParse(tanggalSelesai!);

  DateTime? get akhirEfektifDate => selesaiDate ?? mulaiDate;

  bool get isRentang {
    final m = mulaiDate;
    final s = selesaiDate;
    return m != null && s != null && s.isAfter(m);
  }

  bool get isDibatalkan => status == 0;
  bool get isSelesai => status == 2;
  bool get isPrioritasTinggi => prioritas == 1;

  /// Apakah [hari] berada di dalam rentang agenda ini (inklusif).
  bool mencakup(DateTime hari) {
    final m = mulaiDate;
    if (m == null) return false;
    final a = akhirEfektifDate ?? m;
    final target = DateTime(hari.year, hari.month, hari.day);
    final awal = DateTime(m.year, m.month, m.day);
    final akhir = DateTime(a.year, a.month, a.day);
    return !target.isBefore(awal) && !target.isAfter(akhir);
  }

  /// Sedang berlangsung hari ini (rentang mencakup hari ini dan belum
  /// dibatalkan).
  bool sedangBerlangsung(DateTime hariIni) =>
      !isDibatalkan && mencakup(hariIni);

  /// Jumlah hari dalam rentang (minimal 1).
  int get jumlahHari {
    final m = mulaiDate;
    final a = akhirEfektifDate;
    if (m == null || a == null) return 1;
    final selisih = DateTime(
      a.year,
      a.month,
      a.day,
    ).difference(DateTime(m.year, m.month, m.day)).inDays;
    return selisih < 0 ? 1 : selisih + 1;
  }

  @override
  List<Object?> get props => [id];
}

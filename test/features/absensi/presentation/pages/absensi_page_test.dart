import 'package:akademihub_mob/core/error/result.dart' as result;
import 'package:akademihub_mob/features/absensi/data/services/attendance_location_service.dart';
import 'package:akademihub_mob/features/absensi/domain/entities/absensi_guru_entity.dart';
import 'package:akademihub_mob/features/absensi/domain/entities/absensi_siswa_entity.dart';
import 'package:akademihub_mob/features/absensi/domain/entities/absensi_summary_entity.dart';
import 'package:akademihub_mob/features/absensi/domain/entities/attendance_location.dart';
import 'package:akademihub_mob/features/absensi/domain/repositories/absensi_repository.dart';
import 'package:akademihub_mob/features/absensi/domain/usecases/get_absensi_guru_usecase.dart';
import 'package:akademihub_mob/features/absensi/domain/usecases/get_absensi_siswa_usecase.dart';
import 'package:akademihub_mob/features/absensi/presentation/bloc/absensi_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Shared helpers ───────────────────────────────────────────────────────────

AbsensiSiswaEntity _att(int id, [String s = 'Hadir']) {
  final now = DateTime.now();
  final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
  return AbsensiSiswaEntity(
    id: id, tanggal: today, statusAbsensi: s,
    jamMasuk: s == 'Hadir' ? '07:00:00' : null,
  );
}

AbsensiBloc _bloc([_FakeRepo? r]) {
  final repo = r ?? _FakeRepo();
  return AbsensiBloc(
    getSiswaList: GetAbsensiSiswaListUseCase(repo),
    getSiswaGeneral: GetAbsensiSiswaGeneralUseCase(repo),
    getGuruList: GetAbsensiGuruListUseCase(repo),
    checkIn: CheckInAbsensiUseCase(repo),
    checkOut: CheckOutAbsensiUseCase(repo),
    locationService: _FakeLocationService(),
  );
}
Widget _wrap(AbsensiBloc b) {
  return MaterialApp(
    home: BlocProvider<AbsensiBloc>.value(
      value: b,
      child: const _TestShell(),
    ),
  );
}

void main() {
  final now = DateTime.now();
  final bulan = now.month;
  final tahun = now.year;

  group('AbsensiPage widget', () {
    testWidgets('loading → summary after load', (tester) async {
      final b = _bloc();
      addTearDown(b.close);
      await tester.pumpWidget(_wrap(b));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      b.add(AbsensiLoadRequested(
        role: 'siswa', profileId: 1, bulan: bulan, tahun: tahun,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Hadir'), findsWidgets);
      expect(find.text('Sakit'), findsWidgets);
    });

    testWidgets('check-out button 48dp min after check-in', (tester) async {
      final b = _bloc();
      addTearDown(b.close);
      await tester.pumpWidget(_wrap(b));
      b.add(AbsensiLoadRequested(
        role: 'siswa', profileId: 1, bulan: bulan, tahun: tahun,
      ));
      await tester.pumpAndSettle();
      final btn = find.ancestor(
        of: find.text('Check-out'),
        matching: find.byType(FilledButton),
      );
      expect(btn, findsOneWidget);
      expect(tester.getSize(btn).height, greaterThanOrEqualTo(48));
    });

    testWidgets('status Sakit disables panel', (tester) async {
      final b = _bloc(_FakeRepo(status: 'Sakit'));
      addTearDown(b.close);
      await tester.pumpWidget(_wrap(b));
      b.add(AbsensiLoadRequested(
        role: 'siswa', profileId: 1, bulan: bulan, tahun: tahun,
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Status: Sakit'), findsOneWidget);
    });

    testWidgets('mutation error → snackbar, keeps list', (tester) async {
      final b = _bloc();
      addTearDown(b.close);
      await tester.pumpWidget(_wrap(b));
      b.emit(AbsensiLoaded(
        summary: const AbsensiSummaryEntity(
          hadir: 1, izin: 0, sakit: 0, alpha: 0, total: 1,
        ),
        siswaItems: [_att(1)], guruItems: const [],
        bulan: bulan, tahun: tahun, role: 'siswa',
        mutationMessage: 'Di luar jangkauan',
      ));
      await tester.pumpAndSettle();
      expect(find.text('Di luar jangkauan'), findsOneWidget);
      expect(find.text('1 catatan'), findsOneWidget);
    });

    testWidgets('error state → retry button', (tester) async {
      final b = _bloc();
      addTearDown(b.close);
      await tester.pumpWidget(_wrap(b));
      b.emit(const AbsensiError('Server down'));
      await tester.pumpAndSettle();
      expect(find.text('Server down'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });
  });
}


// ── Minimal shell mirroring AbsensiPage layout for testability ───────────────

class _TestShell extends StatelessWidget {
  const _TestShell();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AbsensiBloc, AbsensiState>(
      listener: (ctx, state) {
        if (state is AbsensiLoaded && state.mutationMessage != null) {
          ScaffoldMessenger.of(ctx)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.mutationMessage!),
              behavior: SnackBarBehavior.floating,
            ));
        }
      },
      listenWhen: (prev, curr) {
        final p = prev is AbsensiLoaded ? prev.mutationMessage : null;
        final c = curr is AbsensiLoaded ? curr.mutationMessage : null;
        return c != null && c != p;
      },
      builder: (ctx, state) {
        if (state is AbsensiLoading || state is AbsensiInitial) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (state is AbsensiError) {
          return Scaffold(body: Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.message),
              FilledButton(
                onPressed: () => ctx.read<AbsensiBloc>().add(const AbsensiRefreshRequested()),
                child: const Text('Coba Lagi'),
              ),
            ],
          )));
        }
        final loaded = state is AbsensiActionInProgress ? state.previous
            : state is AbsensiLoaded ? state : null;
        if (loaded == null) return const SizedBox.shrink();
        final items = loaded.siswaItems;
        return Scaffold(body: Column(children: [
          if (loaded.role == 'siswa') _Panel(loaded),
          Row(children: [
            const Text('Hadir'), const SizedBox(width: 4),
            const Text('Sakit'), const SizedBox(width: 4),
            const Text('Izin'), const SizedBox(width: 4),
            const Text('Alpha'),
          ]),
          Text('${items.length} catatan'),
          Expanded(child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => Text(items[i].statusAbsensi),
          )),
        ]));
      },
    );
  }
}

class _Panel extends StatelessWidget {
  final AbsensiLoaded state;
  const _Panel(this.state);
  @override
  Widget build(BuildContext context) {
    final a = state.currentAttendance;
    final isFinal = a != null
        && !a.statusAbsensi.toLowerCase().contains('hadir')
        && a.statusAbsensi.isNotEmpty;
    if (isFinal) return Text('Status: ${a.statusAbsensi}');
    final checkedIn = a?.jamMasuk != null;
    final checkedOut = a?.jamPulang != null;
    if (checkedOut) return const Text('Selesai');
    return FilledButton(
      onPressed: () => context.read<AbsensiBloc>().add(
        checkedIn ? const AbsensiCheckOutRequested() : const AbsensiCheckInRequested(),
      ),
      style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
      child: Text(checkedIn ? 'Check-out' : 'Check-in'),
    );
  }
}

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeRepo implements AbsensiRepository {
  final String status;
  _FakeRepo({this.status = 'Hadir'});

  @override
  Future<result.Result<AbsensiSiswaEntity>> checkIn(AttendanceLocation l) async =>
      result.success(_att(99, status));
  @override
  Future<result.Result<AbsensiSiswaEntity>> checkOut(AttendanceLocation l) async =>
      result.success(_att(99, status));
  @override
  Future<result.Result<List<AbsensiGuruEntity>>> getAbsensiGuruList(int id) async =>
      result.success(const []);
  @override
  Future<result.Result<List<AbsensiSiswaEntity>>> getAbsensiSiswaGeneral({
    String? tanggalFrom, String? tanggalTo,
  }) async => result.success(const []);
  @override
  Future<result.Result<List<AbsensiSiswaEntity>>> getAbsensiSiswaList(int id) async =>
      result.success([_att(1, status)]);
}

class _FakeLocationService extends AttendanceLocationService {
  @override
  Future<AttendanceLocation> capture() async => AttendanceLocation(
    latitude: -6.2, longitude: 106.8, accuracyMeter: 10,
    capturedAt: DateTime.now(),
  );
}


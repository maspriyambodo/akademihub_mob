import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/tugas_entity.dart';
import '../../domain/entities/tugas_siswa_entity.dart';
import '../bloc/pengumpulan_bloc.dart';
import '../widgets/tugas_widgets.dart';

/// Daftar pengumpulan siswa untuk SATU tugas (view guru) + aksi beri nilai.
class PengumpulanTugasPage extends StatelessWidget {
  final TugasEntity tugas;

  const PengumpulanTugasPage({super.key, required this.tugas});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<PengumpulanBloc>()..add(PengumpulanLoadRequested(tugas.id)),
      child: _PengumpulanView(tugas: tugas),
    );
  }
}

class _PengumpulanView extends StatelessWidget {
  final TugasEntity tugas;

  const _PengumpulanView({required this.tugas});

  Future<void> _bukaDialogNilai(
    BuildContext context,
    TugasSiswaEntity item,
  ) async {
    final bloc = context.read<PengumpulanBloc>();
    final hasil = await showDialog<_HasilNilai>(
      context: context,
      builder: (_) => _NilaiDialog(item: item),
    );
    if (hasil == null) return;

    bloc.add(
      PengumpulanNilaiRequested(
        pengumpulanId: item.id,
        nilai: hasil.nilai,
        catatanGuru: hasil.catatan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumpulan'),
        centerTitle: true,
      ),
      body: BlocConsumer<PengumpulanBloc, PengumpulanState>(
        listenWhen: (_, current) =>
            current is PengumpulanActionSuccess ||
            current is PengumpulanActionFailure,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state is PengumpulanActionSuccess) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is PengumpulanActionFailure) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        buildWhen: (_, current) =>
            current is! PengumpulanActionSuccess &&
            current is! PengumpulanActionFailure,
        builder: (context, state) {
          if (state is PengumpulanInitial || state is PengumpulanLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PengumpulanError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<PengumpulanBloc>().add(
                const PengumpulanRefreshRequested(),
              ),
            );
          }
          if (state is PengumpulanLoaded) {
            return Column(
              children: [
                _HeaderTugas(tugas: tugas, state: state),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<PengumpulanBloc>().add(
                        const PengumpulanRefreshRequested(),
                      );
                    },
                    child: state.items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                child: const _EmptyView(
                                  message:
                                      'Belum ada siswa yang mengumpulkan tugas ini',
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(top: 6, bottom: 20),
                            itemCount: state.items.length,
                            itemBuilder: (context, index) {
                              final item = state.items[index];
                              return PengumpulanCard(
                                item: item,
                                onNilai: () =>
                                    _bukaDialogNilai(context, item),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Header ringkasan tugas ───────────────────────────────────────────────────

class _HeaderTugas extends StatelessWidget {
  final TugasEntity tugas;
  final PengumpulanLoaded state;

  const _HeaderTugas({required this.tugas, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tugas.judul,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              tugas.mapelLabel,
              if (tugas.kelasNama != null) 'Kelas ${tugas.kelasNama}',
              'Tenggat ${formatTanggalWaktu(tugas.tenggatWaktuDate)}',
            ].join(' · '),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatBox(
                label: 'Terkumpul',
                value: state.items.length,
                color: AppColors.info,
              ),
              const SizedBox(width: 8),
              _StatBox(
                label: 'Dinilai',
                value: state.totalDinilai,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              _StatBox(
                label: 'Belum dinilai',
                value: state.totalBelumDinilai,
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog beri nilai ────────────────────────────────────────────────────────

class _HasilNilai {
  final double nilai;
  final String? catatan;
  const _HasilNilai({required this.nilai, this.catatan});
}

class _NilaiDialog extends StatefulWidget {
  final TugasSiswaEntity item;
  const _NilaiDialog({required this.item});

  @override
  State<_NilaiDialog> createState() => _NilaiDialogState();
}

class _NilaiDialogState extends State<_NilaiDialog> {
  late final TextEditingController _nilaiCtrl;
  late final TextEditingController _catatanCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nilaiCtrl = TextEditingController(
      text: widget.item.sudahDinilai ? widget.item.nilaiLabel : '',
    );
    _catatanCtrl = TextEditingController(text: widget.item.catatanGuru ?? '');
  }

  @override
  void dispose() {
    _nilaiCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final nilai = double.parse(_nilaiCtrl.text.trim().replaceAll(',', '.'));
    final catatan = _catatanCtrl.text.trim();
    Navigator.of(context).pop(
      _HasilNilai(nilai: nilai, catatan: catatan.isEmpty ? null : catatan),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Nilai — ${widget.item.siswaNama ?? 'Siswa'}',
        style: const TextStyle(fontSize: 16),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nilaiCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nilai (0 - 100)',
                hintText: 'Contoh: 85',
              ),
              validator: (value) {
                final v = (value ?? '').trim().replaceAll(',', '.');
                if (v.isEmpty) return 'Nilai wajib diisi';
                final n = double.tryParse(v);
                if (n == null) return 'Nilai harus berupa angka';
                if (n < 0 || n > 100) return 'Nilai antara 0 sampai 100';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _catatanCtrl,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        TextButton(onPressed: _simpan, child: const Text('Simpan')),
      ],
    );
  }
}

// ── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty View ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

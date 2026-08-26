import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/datasources/perpustakaan_remote_datasource.dart';

class PerpustakaanPage extends StatefulWidget {
  const PerpustakaanPage({super.key});
  @override
  State<PerpustakaanPage> createState() => _PerpustakaanPageState();
}

class _PerpustakaanPageState extends State<PerpustakaanPage> {
  late final _source = PerpustakaanRemoteDataSource(sl<ApiClient>().dio);
  Future<_LibraryData>? _data;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data ??= _load();
  }

  Future<_LibraryData> _load() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return const _LibraryData();
    final user = auth.user;
    final id = user.profile?['id'];
    final siswaId = id is int ? id : int.tryParse('$id');
    final books = user.hasPermission('buku.view')
        ? await _source.availableBooks()
        : const <Map<String, dynamic>>[];
    final loans =
        user.hasPermission('peminjaman.view') && user.isSiswa && siswaId != null
        ? await _source.loansForStudent(siswaId)
        : const <Map<String, dynamic>>[];
    return _LibraryData(books, loans);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perpustakaan')),
    body: FutureBuilder<_LibraryData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Gagal memuat perpustakaan'));
        }
        final data = snapshot.data ?? const _LibraryData();
        return RefreshIndicator(
          onRefresh: () async => setState(() => _data = _load()),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (data.books.isNotEmpty) ...[
                Text(
                  'Buku tersedia',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ...data.books.map(
                  (x) => ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text('${x['judul'] ?? '-'}'),
                    subtitle: Text('${x['penulis'] ?? '-'}'),
                    trailing: Text('Stok ${x['stok'] ?? 0}'),
                  ),
                ),
              ],
              if (data.loans.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Riwayat pinjaman saya',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ...data.loans.map(_loanTile),
              ],
              if (data.books.isEmpty && data.loans.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 64),
                  child: Center(child: Text('Tidak ada data perpustakaan')),
                ),
            ],
          ),
        );
      },
    ),
  );

  Widget _loanTile(Map<String, dynamic> loan) {
    final due = DateTime.tryParse('${loan['tanggal_jatuh_tempo'] ?? ''}');
    final overdue =
        loan['tanggal_kembali'] == null &&
        due != null &&
        due.isBefore(DateTime.now());
    final book = loan['buku'];
    return ListTile(
      leading: Icon(overdue ? Icons.warning_amber_rounded : Icons.history),
      title: Text('${book is Map ? book['judul'] : 'Buku'}'),
      subtitle: Text('Jatuh tempo ${loan['tanggal_jatuh_tempo'] ?? '-'}'),
      trailing: Text(overdue ? 'Terlambat' : '${loan['status'] ?? '-'}'),
    );
  }
}

class _LibraryData {
  final List<Map<String, dynamic>> books;
  final List<Map<String, dynamic>> loans;
  const _LibraryData([this.books = const [], this.loans = const []]);
}

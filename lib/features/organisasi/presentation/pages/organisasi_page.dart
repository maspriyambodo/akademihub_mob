import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/organisasi_remote_datasource.dart';

class OrganisasiPage extends StatefulWidget {
  const OrganisasiPage({super.key});

  @override
  State<OrganisasiPage> createState() => _OrganisasiPageState();
}

class _OrganisasiPageState extends State<OrganisasiPage> {
  late final _source = sl<OrganisasiRemoteDataSource>();
  late Future<List<Map<String, dynamic>>> _future = _source.list();

  void _reload() => setState(() => _future = _source.list());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Organisasi')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: _reload,
              child: const Text('Muat ulang'),
            ),
          );
        }
        final items = snapshot.data ?? const [];
        final authState = context.read<AuthBloc>().state;
        final canViewAnggota =
            authState is AuthAuthenticated &&
            authState.user.hasPermission('organisasi.anggota.view');
        if (items.isEmpty) {
          return const Center(child: Text('Belum ada organisasi'));
        }
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, index) {
              final item = items[index];
              return ListTile(
                title: Text('${item['nama'] ?? '-'}'),
                subtitle: Text(
                  '${item['kode'] ?? ''}${item['status'] == null ? '' : ' • ${item['status']}'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _OrganisasiDetailPage(
                      id: (item['id'] as num).toInt(),
                      source: _source,
                      canViewAnggota: canViewAnggota,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class _OrganisasiDetailPage extends StatelessWidget {
  final int id;
  final OrganisasiRemoteDataSource source;
  final bool canViewAnggota;

  const _OrganisasiDetailPage({
    required this.id,
    required this.source,
    required this.canViewAnggota,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detail Organisasi')),
    body: FutureBuilder<List<dynamic>>(
      future: Future.wait([
        source.detail(id),
        if (canViewAnggota) source.anggota(id),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Organisasi tidak dapat dimuat'));
        }
        final organisasi = snapshot.data![0] as Map<String, dynamic>?;
        final anggota = canViewAnggota
            ? snapshot.data![1] as List<Map<String, dynamic>>
            : const <Map<String, dynamic>>[];
        if (organisasi == null) {
          return const Center(child: Text('Organisasi tidak ditemukan'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${organisasi['nama'] ?? '-'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if ('${organisasi['kode'] ?? ''}'.isNotEmpty)
              Text('${organisasi['kode']}'),
            if ('${organisasi['deskripsi'] ?? ''}'.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('${organisasi['deskripsi']}'),
              ),
            if (canViewAnggota) ...[
              const SizedBox(height: 24),
              Text('Anggota', style: Theme.of(context).textTheme.titleLarge),
              if (anggota.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Belum ada anggota'),
                ),
              ...anggota.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(
                    '${(item['siswa'] as Map?)?['nama'] ?? item['nama_siswa'] ?? '-'}',
                  ),
                  subtitle: Text(
                    '${(item['jabatan'] as Map?)?['nama'] ?? '-'}',
                  ),
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
}

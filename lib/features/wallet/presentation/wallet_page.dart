import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_client.dart';
import '../../../core/di/injection.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../wali/guardian_child_selector.dart';
import '../data/wallet_repository.dart';
import 'wallet_cubit.dart';

String rupiah(dynamic amount) => NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
).format(amount is num ? amount : int.tryParse('$amount') ?? 0);

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final UserEntity user;
  late final WalletRepository repo;
  late final WalletCubit cubit;
  String section = 'accounts';
  WalletRecord filters = {};
  bool busy = false;
  WalletRecord? pending;
  String? topupId;

  @override
  void initState() {
    super.initState();
    user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    repo = WalletRepository(
      sl<ApiClient>().dio,
      sl<FlutterSecureStorage>(),
      '${user.tenant?.uuid}_${user.id}',
    );
    cubit = WalletCubit(repo);
    section = user.isMerchant
        ? 'merchants'
        : user.isSiswa || user.isWali || user.hasPermission('wallet.view-all')
        ? 'accounts'
        : user.hasPermission('wallet.manage-merchants')
        ? 'merchants'
        : user.hasPermission('wallet.process-payout')
        ? 'payouts'
        : user.hasPermission('wallet.handle-cases')
        ? 'cases'
        : 'accounts';
    refresh();
  }

  Future<void> refresh() async {
    if (section != 'accounts' ||
        user.isSiswa ||
        user.isWali ||
        user.hasPermission('wallet.view-all')) {
      await cubit.load(section, query: filters);
    }
    final op = await repo.pending();
    final id = await repo.lastTopup();
    if (mounted) {
      setState(() {
        pending = op;
        topupId = id;
      });
    }
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(walletError(e))));
      }
    } finally {
      final op = await repo.pending();
      if (mounted) {
        setState(() {
          busy = false;
          pending = op;
        });
      }
    }
  }

  Future<WalletRecord?> form(
    String title,
    List<WalletField> fields, {
    String? description,
  }) => Navigator.of(context).push<WalletRecord>(
    MaterialPageRoute(
      builder: (_) =>
          WalletForm(title: title, fields: fields, description: description),
    ),
  );

  Future<bool> confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(message)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Konfirmasi'),
            ),
          ],
        ),
      ) ??
      false;

  Future<WalletRecord?> mutate(
    String path,
    WalletRecord data, {
    WalletRecord secrets = const {},
  }) async {
    final op = await repo.prepare(path, data);
    return repo.submit(op, secrets: secrets);
  }

  Future<void> receipt(WalletRecord row, {int? student}) async {
    final data = await repo.request(
      'transactions/${row['id']}',
      query: {'student_id': ?student},
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WalletReceipt(record: Map<String, dynamic>.from(data)),
      ),
    );
  }

  Future<void> retry() async {
    final op = pending!;
    WalletRecord secrets = {};
    if (op['path'] == 'payments') {
      final input = await form(
        'Ulangi pembayaran yang sama',
        [const WalletField('pin', 'PIN transaksi', secret: true, pin: true)],
        description:
            'Nominal ${rupiah(op['data']['amount'])}. Kunci transaksi tetap sama.',
      );
      if (input == null) return;
      secrets = input;
    } else if (op['path'] == 'merchants' && op['data']['email'] != null) {
      final input = await form('Ulangi pembuatan pedagang', [
        const WalletField(
          'password',
          'Kata sandi awal yang sama',
          secret: true,
          min: 12,
          max: 128,
        ),
      ]);
      if (input == null) return;
      secrets = input;
    }
    final result = await repo.submit(op, secrets: secrets);
    if (result['kind'] != null) {
      await receipt(
        result,
        student: user.isWali ? result['student_id'] as int? : null,
      );
    }
    await refresh();
  }

  Future<void> resetById() async {
    final data = await form(
      'Reset PIN siswa',
      [
        const WalletField('student_id', 'ID siswa terverifikasi', amount: true),
        const WalletField(
          'password',
          'Kata sandi akun Anda',
          secret: true,
          max: 128,
        ),
        const WalletField('reason', 'Alasan reset'),
      ],
      description:
          'Gunakan identitas siswa yang telah diverifikasi sekolah. Siswa mengatur PIN baru sendiri.',
    );
    if (data == null) return;
    final id = data.remove('student_id');
    if (!await confirm('Reset PIN siswa $id?', 'PIN lama akan dicabut.')) {
      return;
    }
    await repo.request('accounts/$id/pin-reset', method: 'POST', data: data);
  }

  List<(String, String)> get sections => [
    if (user.isSiswa || user.isWali || user.hasPermission('wallet.view-all'))
      ('accounts', 'Saldo siswa'),
    if (user.isMerchant || user.hasPermission('wallet.manage-merchants'))
      ('merchants', 'Pedagang'),
    if (user.isSiswa ||
        user.isMerchant ||
        user.hasPermission('wallet.view-all'))
      ('transactions', 'Transaksi'),
    if (user.isMerchant || user.hasPermission('wallet.process-payout'))
      ('payouts', 'Pencairan'),
    if (user.hasPermission('wallet.handle-cases')) ('cases', 'Kasus gateway'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(user.isMerchant ? 'Kantin saya' : 'Saldo kantin'),
      actions: [
        IconButton(
          tooltip: 'Muat ulang',
          onPressed: busy ? null : () => run(refresh),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: BlocBuilder<WalletCubit, WalletState>(
          bloc: cubit,
          builder: (context, state) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final item in sections)
                    ChoiceChip(
                      label: Text(item.$2),
                      selected: section == item.$1,
                      onSelected: busy || state.busy
                          ? null
                          : (_) {
                              setState(() {
                                section = item.$1;
                                filters = {};
                              });
                              refresh();
                            },
                    ),
                ],
              ),
              if (busy || state.busy) const LinearProgressIndicator(),
              if (user.hasPermission('wallet.reset-pin') &&
                  !user.hasPermission('wallet.view-all'))
                OutlinedButton(
                  onPressed: busy ? null : () => run(resetById),
                  child: const Text('Reset PIN berdasarkan ID'),
                ),
              if (user.hasPermission('wallet.cash-topup') &&
                  !user.hasPermission('wallet.view-all'))
                const Text(
                  'Isi tunai memerlukan akses identitas siswa (wallet.view-all). Hubungi pengelola izin; akses tidak diperluas otomatis.',
                ),
              if (pending != null)
                ListTile(
                  title: const Text('Transaksi belum terkonfirmasi'),
                  subtitle: Text(
                    '${pending!['path']}\nJangan membuat transaksi pengganti.',
                  ),
                  trailing: TextButton(
                    onPressed: busy ? null : () => run(retry),
                    child: const Text('Coba ulang'),
                  ),
                ),
              if (user.isWali && topupId != null)
                TextButton(
                  onPressed: busy
                      ? null
                      : () => run(() => topupStatus(topupId!)),
                  child: const Text('Status top up terakhir'),
                ),
              if (section == 'transactions')
                TextButton.icon(
                  onPressed: busy ? null : () => run(filterTransactions),
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter transaksi'),
                ),
              if (section == 'merchants' &&
                  user.hasPermission('wallet.manage-merchants'))
                FilledButton(
                  onPressed: busy ? null : () => run(createMerchant),
                  child: const Text('Tambah pedagang'),
                ),
              if (section == 'payouts' && user.isMerchant)
                FilledButton(
                  onPressed: busy ? null : () => run(requestPayout),
                  child: const Text('Ajukan pencairan'),
                ),
              if (state.error != null)
                Text(
                  state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (state.page != null && state.page!.rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Belum ada data. Muat ulang untuk memeriksa pembaruan.',
                  ),
                ),
              if (state.page != null) ...[
                if (user.isWali &&
                    section == 'accounts' &&
                    state.page!.rows.isNotEmpty)
                  GuardianChildSelector(
                    key: ValueKey(state.page!.page),
                    children: state.page!.rows
                        .map(
                          (a) => GuardianChild(
                            id: a['student']['id'] as int,
                            name: a['student']['name'] as String,
                          ),
                        )
                        .toList(),
                    selectedId: state.page!.rows.first['student']['id'] as int,
                    onChanged: (child) => run(() => account(child.id)),
                  ),
                for (final row in state.page!.rows) rowWidget(row),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  children: [
                    TextButton(
                      onPressed: busy || state.busy || state.page!.page <= 1
                          ? null
                          : () => cubit.load(
                              section,
                              page: state.page!.page - 1,
                              query: filters,
                            ),
                      child: const Text('Sebelumnya'),
                    ),
                    Text('${state.page!.page} / ${state.page!.lastPage}'),
                    TextButton(
                      onPressed:
                          busy ||
                              state.busy ||
                              state.page!.page >= state.page!.lastPage
                          ? null
                          : () => cubit.load(
                              section,
                              page: state.page!.page + 1,
                              query: filters,
                            ),
                      child: const Text('Berikutnya'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget rowWidget(WalletRecord row) {
    if (section == 'accounts') {
      return ListTile(
        title: Text('${row['student']['name']}'),
        subtitle: Text(
          'Kelas ${row['student']['class_id'] ?? "-"}\nTersedia ${rupiah(row['available'])}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: busy
            ? null
            : () => run(() => account(row['student']['id'] as int)),
      );
    }
    if (section == 'merchants') {
      return ListTile(
        title: Text('${row['name']}'),
        subtitle: Text(
          '${row['active'] == true ? "Aktif" : "Nonaktif"}\nTersedia ${rupiah(row['account']['available'])}',
        ),
        onTap: busy ? null : () => run(() => merchant(row)),
      );
    }
    if (section == 'transactions') {
      return ListTile(
        title: Text('${row['kind']}  ${rupiah(row['amount'])}'),
        subtitle: Text('${row['created_at']}\n${row['id']}'),
        onTap: busy ? null : () => run(() => transaction(row)),
      );
    }
    return ListTile(
      title: Text(
        section == 'payouts'
            ? '${rupiah(row['amount'])} / ${row['status']}'
            : 'Siswa ${row['student_id']} / ${row['status']}',
      ),
      subtitle: Text('${row['id']}\n${row['created_at']}'),
      onTap: busy
          ? null
          : () => run(() => section == 'payouts' ? payout(row) : reversal(row)),
    );
  }

  Future<void> account(int id) async {
    final a = Map<String, dynamic>.from(await repo.request('accounts/$id'));
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WalletAccount(
          account: a,
          user: user,
          repo: repo,
          onAction: (action) async {
            switch (action) {
              case 'pay':
                await pay(a);
              case 'pin':
                final data = await form('Atur PIN transaksi', [
                  const WalletField(
                    'password',
                    'Kata sandi akun',
                    secret: true,
                    max: 128,
                  ),
                  const WalletField(
                    'pin',
                    'PIN baru 6 digit',
                    secret: true,
                    pin: true,
                  ),
                ]);
                if (data != null) {
                  await repo.request('pin', method: 'POST', data: data);
                }
              case 'reset':
                final data = await form(
                  'Reset PIN siswa',
                  [
                    const WalletField(
                      'password',
                      'Kata sandi akun Anda',
                      secret: true,
                      max: 128,
                    ),
                    const WalletField('reason', 'Alasan reset'),
                  ],
                  description: 'Siswa mengatur PIN baru sendiri setelah reset.',
                );
                if (data != null) {
                  await repo.request(
                    'accounts/$id/pin-reset',
                    method: 'POST',
                    data: data,
                  );
                }
              case 'limit':
                await limit(a);
              case 'cash':
                final data = await form(
                  'Isi saldo tunai',
                  [
                    const WalletField('amount', 'Nominal rupiah', amount: true),
                    const WalletField('receipt', 'Referensi bukti penerimaan'),
                  ],
                  description:
                      '${a['student']['name']} / kelas ${a['student']['class_id']}\nTanpa biaya tambahan.',
                );
                if (data != null &&
                    await confirm(
                      'Konfirmasi tunai',
                      '${a['student']['name']}\n${rupiah(data['amount'])}\nDana sudah diterima?',
                    )) {
                  final tx = await mutate('topups/cash', {
                    ...data,
                    'student_id': id,
                  });
                  if (tx != null) await receipt(tx);
                }
              case 'topup':
                await topup(a);
            }
          },
        ),
      ),
    );
    await refresh();
  }

  Future<void> limit(WalletRecord account) async {
    final id = account['student']['id'];
    final current = Map<String, dynamic>.from(
      await repo.request('accounts/$id'),
    );
    final data = await form(
      'Batas belanja harian',
      [
        WalletField(
          'daily_limit',
          'Rupiah (kosong = tanpa batas)',
          amount: true,
          optional: true,
          zero: true,
          initial: '${current['daily_limit'] ?? ''}',
        ),
      ],
      description:
          'Rp0 memblokir belanja. Perubahan tidak menghapus pemakaian hari ini.',
    );
    if (data == null ||
        !await confirm(
          'Simpan batas?',
          data['daily_limit'] == null
              ? 'Hapus batas tambahan.'
              : 'Batas ${rupiah(data['daily_limit'])} per hari.',
        )) {
      return;
    }
    await repo.request(
      'accounts/$id/daily-limit',
      method: 'PUT',
      data: {...data, 'version': current['limit_version']},
    );
  }

  Future<void> pay(WalletRecord account) async {
    if (account['frozen'] == true || account['pin_set'] != true) {
      throw const FormatException('Belanja dibekukan atau PIN belum diatur.');
    }
    final scanned = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const WalletScanner()));
    if (scanned == null) return;
    final token = walletToken(scanned);
    final m = await repo.request('qr/$token');
    if (m['active'] != true || m['school_id'] != user.tenant?.id) {
      throw const FormatException('Pedagang tidak aktif atau berbeda sekolah.');
    }
    final data = await form(
      'Bayar ${m['name']}',
      [
        const WalletField('amount', 'Nominal rupiah', amount: true),
        const WalletField('pin', 'PIN transaksi', secret: true, pin: true),
      ],
      description:
          '${m['school_name']}\nMaksimum saat ini ${rupiah(account['max_payment'])}. Server memeriksa ulang saldo dan jatah.',
    );
    if (data == null ||
        !await confirm(
          'Konfirmasi pembayaran',
          '${m['name']}\n${m['school_name']}\n${rupiah(data['amount'])}',
        )) {
      return;
    }
    final tx = await mutate(
      'payments',
      {'qr_token': token, 'amount': data['amount']},
      secrets: {'pin': data['pin']},
    );
    if (tx != null) await receipt(tx);
  }

  Future<void> topup(WalletRecord a) async {
    final methods = await repo.request('topups/methods');
    if (methods['enabled'] != true) {
      throw const FormatException(
        'Top up online belum tersedia. Hubungi petugas untuk isi tunai.',
      );
    }
    final data = await form('Isi saldo ${a['student']['name']}', [
      const WalletField('amount', 'Nominal saldo', amount: true),
      WalletField(
        'method',
        'Metode pembayaran',
        choices: [for (final m in methods['methods']) '${m['method']}'],
      ),
    ]);
    if (data == null) return;
    final payload = {...data, 'student_id': a['student']['id']};
    final quote = await repo.request(
      'topups/quote',
      method: 'POST',
      data: payload,
    );
    if (!await confirm(
      'Konfirmasi biaya',
      'Saldo ${rupiah(quote['principal'])}\nBiaya ${rupiah(quote['fee'])}\nTotal ${rupiah(quote['total'])}\nMetode ${quote['method']}',
    )) {
      return;
    }
    final t = await mutate('topups', {
      ...payload,
      'fee': quote['fee'],
      'total': quote['total'],
      'schedule_version': quote['schedule_version'],
    });
    if (t != null) await topupStatus(t['id'] as String);
  }

  Future<void> topupStatus(String id) async {
    final t = Map<String, dynamic>.from(await repo.request('topups/$id'));
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WalletTopup(repo: repo, initial: t),
      ),
    );
  }

  Future<void> filterTransactions() async {
    final data = await form('Filter transaksi', [
      const WalletField(
        'status',
        'Status transaksi',
        optional: true,
        choices: ['', 'posted', 'refunded'],
      ),
      if (user.hasPermission('wallet.view-all'))
        const WalletField(
          'student_id',
          'ID siswa',
          amount: true,
          optional: true,
        ),
      if (!user.isMerchant)
        const WalletField(
          'merchant_id',
          'ID pedagang',
          amount: true,
          optional: true,
        ),
      const WalletField(
        'kind',
        'Jenis',
        optional: true,
        choices: [
          '',
          'payment',
          'refund',
          'cash_topup',
          'gateway_topup',
          'payout',
        ],
      ),
      const WalletField(
        'from',
        'Dari (YYYY-MM-DD)',
        optional: true,
        date: true,
      ),
      const WalletField(
        'until',
        'Sampai eksklusif (YYYY-MM-DD)',
        optional: true,
        date: true,
      ),
    ]);
    if (data == null) return;
    filters = Map.fromEntries(
      data.entries.where((e) => e.value != null && e.value != ''),
    );
    await refresh();
  }

  Future<void> transaction(WalletRecord row) async {
    await receipt(row);
    if (!user.isMerchant || row['kind'] != 'payment') return;
    final tx = await repo.request('transactions/${row['id']}');
    if (tx['status'] == 'refunded') return;
    if (!await confirm(
      'Refund penuh?',
      '${rupiah(row['amount'])}\nPilih Batal jika hanya ingin melihat bukti.',
    )) {
      return;
    }
    final data = await form('Alasan refund', [
      const WalletField('reason', 'Alasan'),
    ]);
    if (data == null) return;
    final result = await mutate('transactions/${row['id']}/refund', data);
    if (result != null) await receipt(result);
    await refresh();
  }

  Future<void> createMerchant() async {
    final data = await form('Akun pedagang baru', [
      const WalletField('name', 'Nama pedagang', max: 100),
      const WalletField('email', 'Email', email: true, max: 100),
      const WalletField(
        'password',
        'Kata sandi awal',
        secret: true,
        min: 12,
        max: 128,
      ),
    ]);
    if (data == null) return;
    final password = data.remove('password');
    await mutate('merchants', data, secrets: {'password': password});
    await refresh();
  }

  Future<void> merchant(WalletRecord m) async {
    if (user.isMerchant) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => WalletQr(merchant: m)));
      return;
    }
    final data = await form('Kelola ${m['name']}', [
      WalletField(
        'active',
        'Status',
        choices: const ['Aktif', 'Nonaktif'],
        initial: m['active'] == true ? 'Aktif' : 'Nonaktif',
      ),
      const WalletField(
        'rotate',
        'QR',
        choices: ['Pertahankan', 'Cabut dan ganti'],
      ),
    ]);
    if (data == null ||
        !await confirm(
          'Simpan perubahan?',
          'QR lama tidak berlaku setelah diganti.',
        )) {
      return;
    }
    await repo.request(
      'merchants/${m['id']}',
      method: 'PATCH',
      data: {
        'active': data['active'] == 'Aktif',
        'rotate_qr': data['rotate'] == 'Cabut dan ganti',
      },
    );
    await refresh();
  }

  Future<void> requestPayout() async {
    final accounts = await repo.list('accounts');
    final available = accounts.rows.first['available'];
    final data = await form(
      'Ajukan pencairan',
      [
        WalletField(
          'amount',
          'Nominal bebas atau seluruh saldo',
          amount: true,
          initial: '$available',
        ),
        const WalletField('method', 'Metode', choices: ['cash', 'bank']),
        const WalletField(
          'destination',
          'Rekening bank atau nama penerima tunai',
        ),
      ],
      description:
          'Tersedia ${rupiah(available)}. Tanpa biaya pencairan. Dana dicadangkan sampai pengajuan selesai.',
    );
    if (data == null ||
        !await confirm(
          'Cadangkan dana?',
          '${rupiah(data['amount'])}\n${data['destination']}',
        )) {
      return;
    }
    await mutate('payouts', data);
    await refresh();
  }

  Future<void> payout(WalletRecord p) async {
    final staff = user.hasPermission('wallet.process-payout');
    final choices = [
      if (p['status'] == 'requested') ...[
        if (staff) ...['processing', 'reject'],
        'cancel',
      ],
      if (staff && p['status'] == 'processing') ...['paid', 'cancel'],
    ];
    if (choices.isEmpty) {
      await confirm(
        'Pencairan ${p['status']}',
        '${rupiah(p['amount'])}\n${p['destination']}\nBukti: ${p['proof'] ?? "-"}\n${p['paid_at'] ?? ""}',
      );
      return;
    }
    final selected = await form(
      'Pencairan ${rupiah(p['amount'])}',
      [WalletField('action', 'Tindakan', choices: choices)],
      description:
          '${p['status']}\n${p['method']} / ${p['destination']}\nPembayaran dilakukan sekolah di luar aplikasi.',
    );
    if (selected == null) return;
    final action = selected['action'];
    WalletRecord data = {};
    if (action != 'processing') {
      final input = await form('Konfirmasi $action', [
        WalletField(
          action == 'paid' ? 'proof' : 'reason',
          action == 'paid' ? 'Referensi bukti pembayaran' : 'Alasan',
        ),
      ]);
      if (input == null) return;
      data = input;
    }
    if (!await confirm(
      'Konfirmasi $action',
      action == 'cancel' && p['status'] == 'processing'
          ? 'Pastikan TIDAK ADA pembayaran eksternal. Jangan batalkan jika hasil transfer belum diketahui.'
          : '${rupiah(p['amount'])}\n${p['destination']}\nPastikan tindakan sesuai bukti.',
    )) {
      return;
    }
    if (action == 'cancel' && p['status'] == 'processing') {
      data['no_external_payment'] = true;
    }
    await mutate('payouts/${p['id']}/$action', data);
    await refresh();
  }

  Future<void> reversal(WalletRecord c) async {
    if (c['status'] != 'open') {
      await confirm('Kasus ditutup', '${c['id']}');
      return;
    }
    final data = await form(
      'Selesaikan kasus',
      [
        const WalletField(
          'resolution',
          'Penyelesaian',
          choices: ['cash_recovered', 'school_loss'],
        ),
        const WalletField('proof', 'Bukti penyelesaian'),
      ],
      description:
          'Siswa ${c['student_id']}\nReversal ${rupiah(c['reversed_total'])}\nDiselesaikan ${rupiah(c['resolved_total'])}',
    );
    if (data == null ||
        !await confirm(
          'Tutup kasus?',
          'Penyelesaian dicatat pada jurnal sekolah. ${data['resolution']}',
        )) {
      return;
    }
    await mutate('cases/${c['id']}/resolve', data);
    await refresh();
  }
}

class WalletField {
  final String keyName, label;
  final bool secret, pin, amount, zero, optional, date, email;
  final int min, max;
  final String? initial;
  final List<String>? choices;
  const WalletField(
    this.keyName,
    this.label, {
    this.secret = false,
    this.pin = false,
    this.amount = false,
    this.zero = false,
    this.optional = false,
    this.date = false,
    this.email = false,
    this.min = 1,
    this.max = 500,
    this.initial,
    this.choices,
  });
}

class WalletForm extends StatefulWidget {
  final String title;
  final String? description;
  final List<WalletField> fields;
  const WalletForm({
    super.key,
    required this.title,
    required this.fields,
    this.description,
  });
  @override
  State<WalletForm> createState() => _WalletFormState();
}

class _WalletFormState extends State<WalletForm> {
  final key = GlobalKey<FormState>();
  late final controllers = {
    for (final f in widget.fields)
      f.keyName: TextEditingController(
        text: f.initial ?? f.choices?.first ?? '',
      ),
  };
  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? validate(WalletField f, String? raw) {
    final v = raw ?? '';
    if (f.optional && v.isEmpty) return null;
    if (f.pin && !RegExp(r'^\d{6}$').hasMatch(v)) return 'PIN harus 6 digit.';
    if (v.trim().length < f.min || v.length > f.max) {
      return 'Isi ${f.min}-${f.max} karakter.';
    }
    if (f.email && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
      return 'Email tidak valid.';
    }
    if (f.date &&
        (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v) ||
            DateTime.tryParse(v)?.toIso8601String().substring(0, 10) != v)) {
      return 'Tanggal tidak valid.';
    }
    if (f.amount) {
      try {
        walletAmount(v, zero: f.zero);
      } catch (e) {
        return walletError(e);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: key,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (widget.description != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(widget.description!),
                ),
              for (final f in widget.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: f.choices != null
                      ? DropdownButtonFormField<String>(
                          initialValue: controllers[f.keyName]!.text,
                          decoration: InputDecoration(labelText: f.label),
                          isExpanded: true,
                          items: [
                            for (final choice in f.choices!)
                              DropdownMenuItem(
                                value: choice,
                                child: Text(choice.isEmpty ? 'Semua' : choice),
                              ),
                          ],
                          onChanged: (value) =>
                              controllers[f.keyName]!.text = value ?? '',
                        )
                      : TextFormField(
                          controller: controllers[f.keyName],
                          obscureText: f.secret,
                          autocorrect: !f.secret,
                          enableSuggestions: !f.secret,
                          keyboardType: f.amount || f.pin
                              ? TextInputType.number
                              : f.email
                              ? TextInputType.emailAddress
                              : TextInputType.text,
                          decoration: InputDecoration(labelText: f.label),
                          validator: (v) => validate(f, v),
                        ),
                ),
              FilledButton(
                onPressed: () {
                  if (!key.currentState!.validate()) return;
                  Navigator.pop(context, <String, dynamic>{
                    for (final f in widget.fields)
                      f.keyName:
                          f.optional && controllers[f.keyName]!.text.isEmpty
                          ? null
                          : f.amount
                          ? walletAmount(
                              controllers[f.keyName]!.text,
                              zero: f.zero,
                            )
                          : controllers[f.keyName]!.text,
                  });
                },
                child: const Text('Lanjutkan'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class WalletReceipt extends StatelessWidget {
  final WalletRecord record;
  const WalletReceipt({super.key, required this.record});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bukti transaksi server')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          rupiah(record['amount']),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        for (final key in [
          'id',
          'created_at',
          'kind',
          'status',
          'student_id',
          'merchant_id',
          'actor_id',
          'original_id',
        ])
          if (record[key] != null) SelectableText('$key: ${record[key]}'),
        if (record['details'] is Map)
          for (final e in (record['details'] as Map).entries)
            SelectableText('${e.key}: ${e.value}'),
        if (record['refund'] != null)
          SelectableText(
            'Refund: ${record['refund']['id']}\n${record['refund']['created_at']}',
          ),
        const SizedBox(height: 24),
        const Text(
          'Pedagang memverifikasi penerimaan melalui riwayat akunnya, bukan screenshot.',
        ),
      ],
    ),
  );
}

class WalletAccount extends StatefulWidget {
  final WalletRecord account;
  final UserEntity user;
  final WalletRepository repo;
  final Future<void> Function(String) onAction;
  const WalletAccount({
    super.key,
    required this.account,
    required this.user,
    required this.repo,
    required this.onAction,
  });
  @override
  State<WalletAccount> createState() => _WalletAccountState();
}

class _WalletAccountState extends State<WalletAccount> {
  late WalletRecord a = widget.account;
  bool busy = false;
  String? error;
  String section = 'transactions';
  WalletPageData? page;
  int get id => a['student']['id'] as int;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({int number = 1}) async {
    try {
      final account = Map<String, dynamic>.from(
        await widget.repo.request('accounts/$id'),
      );
      final result = await widget.repo.list(
        section == 'audit' ? 'accounts/$id/audit' : 'transactions',
        page: number,
        query: section == 'audit' ? null : {'student_id': id},
      );
      if (mounted) {
        setState(() {
          a = account;
          page = result;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = walletError(e));
    }
  }

  Future<void> action(String action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onAction(action);
    } catch (e) {
      if (mounted) setState(() => error = walletError(e));
    }
    // Keep action errors visible; refresh summary separately.
    try {
      final updated = Map<String, dynamic>.from(
        await widget.repo.request('accounts/$id'),
      );
      if (mounted) setState(() => a = updated);
    } catch (_) {}
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Scaffold(
      appBar: AppBar(
        title: Text('${a['student']['name']}'),
        actions: [
          IconButton(
            onPressed: busy ? null : load,
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Tersedia ${rupiah(a['available'])}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Total ${rupiah(a['balance'])} / Dicadangkan ${rupiah(a['reserved'])}',
              ),
              if (a['frozen'] == true)
                const Text('Belanja dibekukan. Hubungi petugas.'),
              const Divider(),
              Text(
                'Batas harian: ${a['daily_limit'] == null ? "Tanpa batas tambahan" : rupiah(a['daily_limit'])}',
              ),
              Text('Belanja hari ini: ${rupiah(a['spent_today'])}'),
              Text(
                'Sisa jatah: ${a['remaining_today'] == null ? "Tanpa batas tambahan" : rupiah(a['remaining_today'])}',
              ),
              Text('Maksimum pembayaran: ${rupiah(a['max_payment'])}'),
              Text('${a['timezone']} / Reset ${a['resets_at']}'),
              if (busy) const LinearProgressIndicator(),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              Wrap(
                spacing: 8,
                children: [
                  for (final item in <(String, String)>[
                    if (user.isSiswa &&
                        a['pin_set'] == true &&
                        a['frozen'] != true)
                      ('pay', 'Scan dan bayar'),
                    if (user.isSiswa && a['pin_set'] != true)
                      ('pin', 'Atur PIN'),
                    if (user.isWali) ...[
                      ('topup', 'Isi saldo'),
                      ('limit', 'Atur batas'),
                    ],
                    if (user.isWali || user.hasPermission('wallet.reset-pin'))
                      ('reset', 'Reset PIN'),
                    if (user.hasPermission('wallet.cash-topup'))
                      ('cash', 'Isi tunai'),
                  ])
                    OutlinedButton(
                      onPressed: busy ? null : () => action(item.$1),
                      child: Text(item.$2),
                    ),
                ],
              ),
              const Divider(),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in ['transactions', 'audit'])
                    ChoiceChip(
                      label: Text(
                        s == 'audit' ? 'Audit batas / PIN' : 'Riwayat',
                      ),
                      selected: section == s,
                      onSelected: busy
                          ? null
                          : (_) {
                              setState(() {
                                section = s;
                                page = null;
                              });
                              load();
                            },
                    ),
                ],
              ),
              if (page?.rows.isEmpty == true) const Text('Belum ada riwayat.'),
              for (final row in page?.rows ?? <WalletRecord>[])
                ListTile(
                  title: Text(
                    section == 'audit'
                        ? '${row['action']}'
                        : '${row['kind']} ${rupiah(row['amount'])}',
                  ),
                  subtitle: Text(
                    '${row['created_at']}\n${section == 'audit' ? "Aktor ${row['actor_id']} / ${row['details']}" : row['id']}',
                  ),
                  onTap: section == 'audit'
                      ? null
                      : () async {
                          try {
                            final record = Map<String, dynamic>.from(
                              await widget.repo.request(
                                'transactions/${row['id']}',
                                query: {'student_id': id},
                              ),
                            );
                            if (context.mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => WalletReceipt(record: record),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) setState(() => error = walletError(e));
                          }
                        },
                ),
              if (page != null)
                Wrap(
                  children: [
                    TextButton(
                      onPressed: page!.page > 1
                          ? () => load(number: page!.page - 1)
                          : null,
                      child: const Text('Sebelumnya'),
                    ),
                    TextButton(
                      onPressed: page!.page < page!.lastPage
                          ? () => load(number: page!.page + 1)
                          : null,
                      child: const Text('Berikutnya'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class WalletScanner extends StatefulWidget {
  const WalletScanner({super.key});
  @override
  State<WalletScanner> createState() => _WalletScannerState();
}

class _WalletScannerState extends State<WalletScanner> {
  final controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  final text = TextEditingController();
  bool finished = false;
  String? error;
  void accept(String raw) {
    if (finished) return;
    try {
      final token = walletToken(raw);
      finished = true;
      Navigator.pop(context, token);
    } catch (e) {
      setState(() => error = walletError(e));
    }
  }

  @override
  void dispose() {
    controller.dispose();
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan QR pedagang')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SizedBox(
          height: 280,
          child: MobileScanner(
            controller: controller,
            onDetect: (capture) {
              for (final code in capture.barcodes) {
                if (code.rawValue != null) {
                  accept(code.rawValue!);
                  break;
                }
              }
            },
            errorBuilder: (_, _) => const Center(
              child: Text(
                'Kamera tidak tersedia atau izin ditolak. Aktifkan izin kamera di pengaturan, atau masukkan kode.',
              ),
            ),
          ),
        ),
        TextField(
          controller: text,
          decoration: const InputDecoration(
            labelText: 'Kode atau URL QR pedagang',
          ),
        ),
        if (error != null) Text(error!),
        FilledButton(
          onPressed: () => accept(text.text),
          child: const Text('Periksa pedagang'),
        ),
        const Text(
          'Pemindaian tidak mendebit saldo. Periksa identitas sebelum konfirmasi.',
        ),
      ],
    ),
  );
}

class WalletTopup extends StatefulWidget {
  final WalletRepository repo;
  final WalletRecord initial;
  const WalletTopup({super.key, required this.repo, required this.initial});
  @override
  State<WalletTopup> createState() => _WalletTopupState();
}

class _WalletTopupState extends State<WalletTopup> with WidgetsBindingObserver {
  late WalletRecord record = widget.initial;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) update(false);
  }

  Future<void> update(bool checkout) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = Map<String, dynamic>.from(
        await widget.repo.request(
          'topups/${record['id']}${checkout ? '/checkout' : ''}',
          method: checkout ? 'POST' : 'GET',
        ),
      );
      if (!mounted) return;
      setState(() => record = data);
      if (checkout && data['status'] != 'paid') {
        final uri = Uri.tryParse('${data['checkout_url'] ?? ''}');
        if (uri == null ||
            uri.scheme != 'https' ||
            uri.host.isEmpty ||
            uri.userInfo.isNotEmpty) {
          throw const FormatException(
            'Checkout belum tersedia. Status sedang direkonsiliasi; jangan membuat top up pengganti.',
          );
        }
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw const FormatException(
            'Tidak dapat membuka checkout. Coba lagi.',
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = walletError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Status top up')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SelectableText('${record['id']}'),
        Text('Status server: ${record['status']}'),
        Text(
          'Saldo ${rupiah(record['principal'])}\nBiaya ${rupiah(record['fee'])}\nTotal ${rupiah(record['total'])}',
        ),
        Text(
          record['status'] == 'paid'
              ? 'Saldo telah diposting server.'
              : 'Saldo belum dikonfirmasi masuk. Kembali dari checkout bukan bukti pembayaran.',
        ),
        if (busy) const LinearProgressIndicator(),
        if (error != null) Text(error!),
        if (['created', 'pending'].contains(record['status']))
          FilledButton(
            onPressed: busy ? null : () => update(true),
            child: const Text('Buka checkout'),
          ),
        OutlinedButton(
          onPressed: busy ? null : () => update(false),
          child: const Text('Periksa status'),
        ),
      ],
    ),
  );
}

class WalletQr extends StatefulWidget {
  final WalletRecord merchant;
  const WalletQr({super.key, required this.merchant});
  @override
  State<WalletQr> createState() => _WalletQrState();
}

class _WalletQrState extends State<WalletQr> {
  final boundary = GlobalKey();
  bool busy = false;
  String? message;
  Future<void> export(bool share) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final render =
          boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final bytes = data!.buffer.asUint8List();
      final name = 'kantin-${widget.merchant['id']}.png';
      if (share) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$name');
        await file.writeAsBytes(bytes, flush: true);
        if (!mounted) return;
        final box = context.findRenderObject() as RenderBox;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
          ),
        );
      } else {
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan QR siap cetak',
          fileName: name,
          bytes: bytes,
          type: FileType.custom,
          allowedExtensions: ['png'],
        );
        if (path != null && !Platform.isAndroid && !Platform.isIOS) {
          await File(path).writeAsBytes(bytes);
        }
        if (mounted) {
          setState(
            () => message = path == null
                ? 'Penyimpanan dibatalkan.'
                : 'QR disimpan.',
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => message = walletError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.merchant;
    final a = m['account'];
    return Scaffold(
      appBar: AppBar(title: const Text('QR kantin saya')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Total ${rupiah(a['balance'])}\nTersedia ${rupiah(a['available'])}\nDicadangkan ${rupiah(a['reserved'])}',
              ),
              if (m['active'] != true)
                const Text(
                  'Pedagang nonaktif. QR tidak dapat digunakan untuk pembayaran.',
                ),
              RepaintBoundary(
                key: boundary,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        '${m['name']}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                        ),
                      ),
                      QrImageView(
                        data: '${m['qr_url']}',
                        size: 240,
                        backgroundColor: Colors.white,
                      ),
                      const Text(
                        'Saldo kantin sekolah',
                        style: TextStyle(color: Colors.black),
                      ),
                      Text(
                        '${m['qr_token']}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (message != null) Text(message!),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton(
                    onPressed: busy ? null : () => export(false),
                    child: const Text('Unduh PNG'),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : () => export(true),
                    child: const Text('Bagikan QR'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

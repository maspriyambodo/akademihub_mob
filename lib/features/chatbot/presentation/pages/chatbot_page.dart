import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../bloc/chatbot_bloc.dart';

/// Permission backend (grup `Route::prefix('v1/chatbot')` di routes/api.php).
const String _permKirim = 'chatbot.message';
const String _permSesi = 'chatbot.session';

class ChatbotPage extends StatelessWidget {
  const ChatbotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ChatbotBloc>(),
      child: const _ChatbotView(),
    );
  }
}

class _ChatbotView extends StatefulWidget {
  const _ChatbotView();

  @override
  State<_ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<_ChatbotView> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();
  int _galatVersiTerakhir = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final user = authState.user;
        context.read<ChatbotBloc>().add(
          ChatbotStarted(
            bolehKirim: user.hasPermission(_permKirim),
            bolehHapus: user.hasPermission(_permSesi),
          ),
        );
      } else {
        context.read<ChatbotBloc>().add(
          const ChatbotStarted(bolehKirim: false, bolehHapus: false),
        );
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  void _kirim() {
    final teks = _input.text.trim();
    if (teks.isEmpty) return;
    context.read<ChatbotBloc>().add(ChatbotPesanDikirim(teks));
    _input.clear();
  }

  void _scrollKeBawah() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _konfirmasiSesiBaru() async {
    final bloc = context.read<ChatbotBloc>();
    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mulai Percakapan Baru?'),
        content: const Text(
          'Riwayat percakapan saat ini akan dihapus, baik di aplikasi maupun '
          'di server. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Hapus & Mulai Baru',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (yakin == true) {
      bloc.add(const ChatbotSesiBaruDiminta());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten AI'),
        centerTitle: true,
        actions: [
          BlocBuilder<ChatbotBloc, ChatbotState>(
            builder: (context, state) {
              if (state is! ChatbotLoaded || !state.bolehHapusSesi) {
                return const SizedBox.shrink();
              }
              if (state.menghapusSesi) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }
              return IconButton(
                tooltip: 'Mulai Percakapan Baru',
                icon: const Icon(Icons.restart_alt),
                onPressed: state.sedangMengetik ? null : _konfirmasiSesiBaru,
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ChatbotBloc, ChatbotState>(
        listenWhen: (prev, curr) {
          if (curr is! ChatbotLoaded) return false;
          if (prev is! ChatbotLoaded) return true;
          return prev.messages.length != curr.messages.length ||
              prev.sedangMengetik != curr.sedangMengetik ||
              prev.galatVersi != curr.galatVersi;
        },
        listener: (context, state) {
          if (state is! ChatbotLoaded) return;
          _scrollKeBawah();
          final galat = state.galat;
          if (galat != null && state.galatVersi != _galatVersiTerakhir) {
            _galatVersiTerakhir = state.galatVersi;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(galat),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
        },
        builder: (context, state) {
          if (state is ChatbotNoAccess) {
            return _NoAccessView(message: state.message);
          }
          if (state is! ChatbotLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final jumlahItem =
              state.messages.length + (state.sedangMengetik ? 1 : 0);

          final horizontalPad = Responsive.pagePadding(context).horizontal / 2;

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Responsive.lebarKontenMaks(context),
                    ),
                    child: ListView.builder(
                      controller: _scroll,
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        14,
                        horizontalPad,
                        8,
                      ),
                      itemCount: jumlahItem,
                      itemBuilder: (context, i) {
                        if (i >= state.messages.length) {
                          return const _TypingBubble();
                        }
                        final pesan = state.messages[i];
                        return _ChatBubble(
                          pesan: pesan,
                          onKirimUlang: pesan.gagal && !state.sedangMengetik
                              ? () => context.read<ChatbotBloc>().add(
                                  ChatbotKirimUlangDiminta(pesan.id),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ),
              ),
              _InputBar(
                controller: _input,
                bolehKirim: !state.sedangMengetik && !state.menghapusSesi,
                sedangMengetik: state.sedangMengetik,
                onKirim: _kirim,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Bubble pesan ──────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final ChatMessageEntity pesan;
  final VoidCallback? onKirimUlang;

  const _ChatBubble({required this.pesan, this.onKirimUlang});

  String get _jam =>
      '${pesan.waktu.hour.toString().padLeft(2, '0')}:'
      '${pesan.waktu.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final dariPengguna = pesan.dariPengguna;
    // Bubble sedikit lebih lebar di layar sempit agar ruang teks tidak
    // terlalu sempit, tetap dibatasi lebar konten maksimum di tablet.
    final rasioLebar = Responsive.isCompact(context) ? 0.85 : 0.78;
    final lebarMaks = math.min(
      MediaQuery.of(context).size.width * rasioLebar,
      Responsive.lebarKontenMaks(context) * 0.78,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: dariPengguna
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: dariPengguna
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!dariPengguna) ...[
                const _AvatarBot(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: lebarMaks),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: dariPengguna
                          ? (pesan.gagal
                                ? AppColors.primary.withAlpha(150)
                                : AppColors.primary)
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(dariPengguna ? 16 : 4),
                        bottomRight: Radius.circular(dariPengguna ? 4 : 16),
                      ),
                      border: dariPengguna
                          ? null
                          : Border.all(color: AppColors.divider),
                    ),
                    // Balasan dirender sebagai teks biasa (tanpa markdown).
                    child: Text(
                      pesan.teks,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: dariPengguna
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: EdgeInsets.only(
              left: dariPengguna ? 0 : 40,
              right: dariPengguna ? 2 : 0,
            ),
            child: pesan.gagal
                ? _LabelGagal(onKirimUlang: onKirimUlang)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (pesan.status == ChatStatus.mengirim) ...[
                        const Icon(
                          Icons.schedule,
                          size: 11,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        pesan.status == ChatStatus.mengirim
                            ? 'Mengirim…'
                            : _jam,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LabelGagal extends StatelessWidget {
  final VoidCallback? onKirimUlang;

  const _LabelGagal({this.onKirimUlang});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onKirimUlang,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 13, color: AppColors.error),
            const SizedBox(width: 4),
            const Text(
              'Gagal terkirim',
              style: TextStyle(fontSize: 11, color: AppColors.error),
            ),
            if (onKirimUlang != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.refresh, size: 13, color: AppColors.primary),
              const SizedBox(width: 2),
              const Text(
                'Kirim ulang',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AvatarBot extends StatelessWidget {
  const _AvatarBot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(24),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.smart_toy_outlined,
        size: 18,
        color: AppColors.primary,
      ),
    );
  }
}

// ── Indikator "sedang mengetik" ───────────────────────────────────────────────

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _AvatarBot(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.divider),
            ),
            child: const _TitikMengetik(),
          ),
        ],
      ),
    );
  }
}

class _TitikMengetik extends StatefulWidget {
  const _TitikMengetik();

  @override
  State<_TitikMengetik> createState() => _TitikMengetikState();
}

class _TitikMengetikState extends State<_TitikMengetik>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final fase = (_ctrl.value * 2 * math.pi) - (i * 0.9);
            final nilai = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(fase));
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
              child: Opacity(
                opacity: nilai,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Bar input pesan ───────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool bolehKirim;
  final bool sedangMengetik;
  final VoidCallback onKirim;

  const _InputBar({
    required this.controller,
    required this.bolehKirim,
    required this.sedangMengetik,
    required this.onKirim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  // Backend memvalidasi `message` maksimal 1000 karakter.
                  maxLength: 1000,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Tulis pesan…',
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 46,
                height: 46,
                child: Material(
                  color: bolehKirim ? AppColors.primary : AppColors.divider,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: bolehKirim ? onKirim : null,
                    child: sedangMengetik
                        ? const Padding(
                            padding: EdgeInsets.all(13),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            size: 21,
                            color: bolehKirim
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tanpa akses ───────────────────────────────────────────────────────────────

class _NoAccessView extends StatelessWidget {
  final String message;

  const _NoAccessView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(28),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 42,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Akses Ditolak',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

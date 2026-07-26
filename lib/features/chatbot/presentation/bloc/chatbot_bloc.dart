import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/usecases/hapus_sesi_usecase.dart';
import '../../domain/usecases/kirim_pesan_usecase.dart';

part 'chatbot_event.dart';
part 'chatbot_state.dart';

/// Bloc percakapan chatbot.
///
/// Riwayat percakapan HANYA disimpan di state ini selama sesi aplikasi —
/// backend tidak menyediakan endpoint GET riwayat (server menyimpan konteks
/// di tabel `chatbot_sessions` hanya untuk kebutuhan prompt LLM).
/// Kegagalan satu pesan tidak menghapus riwayat: pesan ditandai gagal dan
/// bisa dikirim ulang.
class ChatbotBloc extends Bloc<ChatbotEvent, ChatbotState> {
  final KirimPesanChatbotUseCase kirimPesan;
  final HapusSesiChatbotUseCase hapusSesi;

  /// Penghasil id lokal untuk pesan (tidak ada id dari server).
  int _idBerikut = 0;

  ChatbotBloc({required this.kirimPesan, required this.hapusSesi})
    : super(ChatbotInitial()) {
    on<ChatbotStarted>(_onStarted);
    on<ChatbotPesanDikirim>(_onPesanDikirim);
    on<ChatbotKirimUlangDiminta>(_onKirimUlang);
    on<ChatbotSesiBaruDiminta>(_onSesiBaru);
  }

  /// Pesan pembuka statis dari bot saat percakapan kosong.
  ChatMessageEntity _sapaan() => ChatMessageEntity(
    id: _idBerikut++,
    peran: ChatPeran.bot,
    teks:
        'Halo! Saya Asisten AI AkademiHub. Ada yang bisa saya bantu seputar '
        'informasi sekolah, nilai, kehadiran, atau pembayaran SPP?',
    waktu: DateTime.now(),
  );

  void _onStarted(ChatbotStarted event, Emitter<ChatbotState> emit) {
    if (!event.bolehKirim) {
      emit(
        const ChatbotNoAccess(
          'Akun Anda tidak memiliki izin "chatbot.message" untuk menggunakan '
          'Asisten AI. Silakan hubungi administrator sekolah.',
        ),
      );
      return;
    }
    emit(
      ChatbotLoaded(messages: [_sapaan()], bolehHapusSesi: event.bolehHapus),
    );
  }

  Future<void> _onPesanDikirim(
    ChatbotPesanDikirim event,
    Emitter<ChatbotState> emit,
  ) async {
    final s = state;
    if (s is! ChatbotLoaded || s.sedangMengetik || s.menghapusSesi) return;

    final teks = event.teks.trim();
    if (teks.isEmpty) return;

    final pesan = ChatMessageEntity(
      id: _idBerikut++,
      peran: ChatPeran.pengguna,
      teks: teks,
      waktu: DateTime.now(),
      status: ChatStatus.mengirim,
    );

    emit(s.copyWith(messages: [...s.messages, pesan], sedangMengetik: true));
    await _prosesKirim(pesan, emit);
  }

  Future<void> _onKirimUlang(
    ChatbotKirimUlangDiminta event,
    Emitter<ChatbotState> emit,
  ) async {
    final s = state;
    if (s is! ChatbotLoaded || s.sedangMengetik || s.menghapusSesi) return;

    final idx = s.messages.indexWhere(
      (m) => m.id == event.idPesan && m.gagal,
    );
    if (idx == -1) return;

    final pesan = s.messages[idx].copyWith(status: ChatStatus.mengirim);
    emit(
      s.copyWith(
        messages: _ubahStatus(s.messages, pesan.id, ChatStatus.mengirim),
        sedangMengetik: true,
      ),
    );
    await _prosesKirim(pesan, emit);
  }

  Future<void> _prosesKirim(
    ChatMessageEntity pesan,
    Emitter<ChatbotState> emit,
  ) async {
    final result = await kirimPesan(pesan.teks);

    final s = state;
    if (s is! ChatbotLoaded) return;

    if (result.isSuccess) {
      final balasan = ChatMessageEntity(
        id: _idBerikut++,
        peran: ChatPeran.bot,
        teks: result.requireData,
        waktu: DateTime.now(),
      );
      emit(
        s.copyWith(
          messages: [
            ..._ubahStatus(s.messages, pesan.id, ChatStatus.terkirim),
            balasan,
          ],
          sedangMengetik: false,
        ),
      );
    } else {
      // Riwayat dipertahankan; pesan hanya ditandai gagal + opsi kirim ulang.
      emit(
        s.copyWith(
          messages: _ubahStatus(s.messages, pesan.id, ChatStatus.gagal),
          sedangMengetik: false,
          galat: result.requireFailure.message,
          galatVersi: s.galatVersi + 1,
        ),
      );
    }
  }

  Future<void> _onSesiBaru(
    ChatbotSesiBaruDiminta event,
    Emitter<ChatbotState> emit,
  ) async {
    final s = state;
    if (s is! ChatbotLoaded || s.sedangMengetik || s.menghapusSesi) return;

    emit(s.copyWith(menghapusSesi: true));
    final result = await hapusSesi();

    final kini = state;
    if (kini is! ChatbotLoaded) return;

    if (result.isSuccess) {
      // Sesi server terhapus → mulai percakapan baru dengan sapaan pembuka.
      emit(
        ChatbotLoaded(
          messages: [_sapaan()],
          bolehHapusSesi: kini.bolehHapusSesi,
          galatVersi: kini.galatVersi,
        ),
      );
    } else {
      emit(
        kini.copyWith(
          menghapusSesi: false,
          galat: result.requireFailure.message,
          galatVersi: kini.galatVersi + 1,
        ),
      );
    }
  }

  List<ChatMessageEntity> _ubahStatus(
    List<ChatMessageEntity> daftar,
    int id,
    ChatStatus status,
  ) => [
    for (final m in daftar)
      if (m.id == id) m.copyWith(status: status) else m,
  ];
}

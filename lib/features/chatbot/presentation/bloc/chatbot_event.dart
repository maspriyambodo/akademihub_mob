part of 'chatbot_bloc.dart';

abstract class ChatbotEvent extends Equatable {
  const ChatbotEvent();
  @override
  List<Object?> get props => [];
}

/// Dipicu saat halaman dibuka; membawa hasil cek permission dari AuthBloc.
class ChatbotStarted extends ChatbotEvent {
  final bool bolehKirim;
  final bool bolehHapus;

  const ChatbotStarted({required this.bolehKirim, required this.bolehHapus});

  @override
  List<Object?> get props => [bolehKirim, bolehHapus];
}

/// User mengirim pesan baru.
class ChatbotPesanDikirim extends ChatbotEvent {
  final String teks;

  const ChatbotPesanDikirim(this.teks);

  @override
  List<Object?> get props => [teks];
}

/// User meminta kirim ulang pesan yang gagal.
class ChatbotKirimUlangDiminta extends ChatbotEvent {
  final int idPesan;

  const ChatbotKirimUlangDiminta(this.idPesan);

  @override
  List<Object?> get props => [idPesan];
}

/// User meminta mulai percakapan baru (hapus sesi server + riwayat lokal).
class ChatbotSesiBaruDiminta extends ChatbotEvent {
  const ChatbotSesiBaruDiminta();
}

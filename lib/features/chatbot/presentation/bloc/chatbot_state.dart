part of 'chatbot_bloc.dart';

abstract class ChatbotState extends Equatable {
  const ChatbotState();
  @override
  List<Object?> get props => [];
}

class ChatbotInitial extends ChatbotState {}

/// User tidak punya permission `chatbot.message`.
class ChatbotNoAccess extends ChatbotState {
  final String message;

  const ChatbotNoAccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Percakapan aktif. Kegagalan pengiriman tidak mengganti state ini —
/// galat disalurkan lewat [galat]/[galatVersi] agar riwayat tetap utuh.
class ChatbotLoaded extends ChatbotState {
  final List<ChatMessageEntity> messages;

  /// Sedang menunggu balasan bot (indikator "mengetik").
  final bool sedangMengetik;

  /// Sedang memproses DELETE /chatbot/session.
  final bool menghapusSesi;

  /// Punya permission `chatbot.session` (tombol percakapan baru).
  final bool bolehHapusSesi;

  /// Pesan galat terakhir (ditampilkan sebagai SnackBar, bukan layar error).
  final String? galat;

  /// Versi galat — bertambah setiap galat baru supaya listener bisa
  /// membedakan galat berulang dengan pesan yang sama.
  final int galatVersi;

  const ChatbotLoaded({
    required this.messages,
    this.sedangMengetik = false,
    this.menghapusSesi = false,
    this.bolehHapusSesi = false,
    this.galat,
    this.galatVersi = 0,
  });

  ChatbotLoaded copyWith({
    List<ChatMessageEntity>? messages,
    bool? sedangMengetik,
    bool? menghapusSesi,
    bool? bolehHapusSesi,
    String? galat,
    int? galatVersi,
  }) => ChatbotLoaded(
    messages: messages ?? this.messages,
    sedangMengetik: sedangMengetik ?? this.sedangMengetik,
    menghapusSesi: menghapusSesi ?? this.menghapusSesi,
    bolehHapusSesi: bolehHapusSesi ?? this.bolehHapusSesi,
    galat: galat ?? this.galat,
    galatVersi: galatVersi ?? this.galatVersi,
  );

  @override
  List<Object?> get props => [
    messages,
    sedangMengetik,
    menghapusSesi,
    bolehHapusSesi,
    galat,
    galatVersi,
  ];
}

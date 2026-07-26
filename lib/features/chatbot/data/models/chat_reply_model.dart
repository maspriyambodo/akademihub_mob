/// Balasan chatbot dari `POST /chatbot/message`.
///
/// Envelope backend: `{ "success": true, "message": "OK",
/// "data": { "reply": "..." } }` — `reply` berisi teks balasan AI (lihat
/// `ChatbotController::message` + `ApiResponseTrait::successResponse`).
/// `reply` secara tipe bisa null (`ChatbotService::handleWeb` mengembalikan
/// `?string`), jadi parsing dibuat null-safe dengan teks fallback.
class ChatReplyModel {
  final String reply;

  const ChatReplyModel({required this.reply});

  factory ChatReplyModel.fromJson(Map<String, dynamic> json) {
    final reply = json['reply'] as String?;
    return ChatReplyModel(
      reply: (reply == null || reply.trim().isEmpty)
          ? 'Maaf, saya tidak dapat memproses pesan Anda saat ini.'
          : reply,
    );
  }

  /// Domain memakai `String` langsung sebagai balasan.
  String toEntity() => reply;
}

import 'package:dio/dio.dart';
import '../models/chat_reply_model.dart';

abstract class ChatbotRemoteDataSource {
  Future<ChatReplyModel> sendMessage(String pesan);
  Future<void> clearSession();
}

class ChatbotRemoteDataSourceImpl implements ChatbotRemoteDataSource {
  final Dio _dio;

  const ChatbotRemoteDataSourceImpl(this._dio);

  /// Panggilan LLM di backend bisa lama: `OpenAiService` memakai
  /// `Http::timeout(config('openai.timeout', 60))` = 60 detik, sementara
  /// default `receiveTimeout` ApiClient juga 60 detik. Override per-request
  /// supaya request tidak terpotong tepat saat backend masih menunggu OpenAI.
  static const Duration _timeoutBalasan = Duration(seconds: 120);

  /// Catatan route: di `routes/api.php` grup chatbot berada di
  /// `Route::prefix('v1/chatbot')` terpisah dari grup utama, tetapi karena
  /// base URL Dio sudah memuat `/api/v1`, path relatifnya tetap
  /// `/chatbot/message`.
  @override
  Future<ChatReplyModel> sendMessage(String pesan) async {
    final response = await _dio.post(
      '/chatbot/message',
      data: {'message': pesan},
      options: Options(receiveTimeout: _timeoutBalasan),
    );
    final body = response.data;
    final raw = body is Map ? body['data'] : null;
    final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    return ChatReplyModel.fromJson(map);
  }

  @override
  Future<void> clearSession() async {
    await _dio.delete('/chatbot/session');
  }
}

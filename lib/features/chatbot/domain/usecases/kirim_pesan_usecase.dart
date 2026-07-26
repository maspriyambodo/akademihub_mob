import '../../../../core/error/result.dart';
import '../repositories/chatbot_repository.dart';

class KirimPesanChatbotUseCase {
  final ChatbotRepository _repository;

  const KirimPesanChatbotUseCase(this._repository);

  Future<Result<String>> call(String pesan) => _repository.kirimPesan(pesan);
}

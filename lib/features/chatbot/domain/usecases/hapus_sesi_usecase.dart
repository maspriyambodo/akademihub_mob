import '../../../../core/error/result.dart';
import '../repositories/chatbot_repository.dart';

class HapusSesiChatbotUseCase {
  final ChatbotRepository _repository;

  const HapusSesiChatbotUseCase(this._repository);

  Future<Result<void>> call() => _repository.hapusSesi();
}

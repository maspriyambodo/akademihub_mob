import '../../../../core/error/result.dart';

abstract class ChatbotRepository {
  /// Kirim satu pesan ke chatbot dan terima teks balasan AI (sekali balas,
  /// tanpa streaming).
  Future<Result<String>> kirimPesan(String pesan);

  /// Hapus sesi/riwayat percakapan user yang sedang login di server.
  Future<Result<void>> hapusSesi();
}

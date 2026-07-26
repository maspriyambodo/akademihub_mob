import 'package:equatable/equatable.dart';

/// Peran pengirim pesan dalam percakapan chatbot.
enum ChatPeran { pengguna, bot }

/// Status pengiriman pesan (relevan untuk pesan pengguna).
enum ChatStatus { mengirim, terkirim, gagal }

/// Satu gelembung pesan dalam percakapan.
///
/// Backend TIDAK menyediakan endpoint GET riwayat, jadi id dibuat lokal
/// (increment) dan riwayat hanya hidup selama sesi aplikasi di state bloc.
class ChatMessageEntity extends Equatable {
  final int id;
  final ChatPeran peran;
  final String teks;
  final DateTime waktu;
  final ChatStatus status;

  const ChatMessageEntity({
    required this.id,
    required this.peran,
    required this.teks,
    required this.waktu,
    this.status = ChatStatus.terkirim,
  });

  bool get dariPengguna => peran == ChatPeran.pengguna;
  bool get gagal => status == ChatStatus.gagal;

  ChatMessageEntity copyWith({ChatStatus? status}) => ChatMessageEntity(
    id: id,
    peran: peran,
    teks: teks,
    waktu: waktu,
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [id, peran, teks, waktu, status];
}

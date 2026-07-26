part of 'keuangan_detail_bloc.dart';

abstract class KeuanganDetailState extends Equatable {
  const KeuanganDetailState();
  @override
  List<Object?> get props => [];
}

class KeuanganDetailInitial extends KeuanganDetailState {}

class KeuanganDetailLoading extends KeuanganDetailState {}

class KeuanganDetailLoaded extends KeuanganDetailState {
  final PembayaranSppEntity pembayaran;

  /// Hasil `hitung-denda` — hanya diambil untuk tagihan yang belum lunas.
  final DendaEntity? denda;

  final KeuanganAksiStatus aksiStatus;

  /// URL checkout Midtrans hasil `bayar-online`.
  final String? aksiUrl;

  final String? aksiMessage;

  const KeuanganDetailLoaded({
    required this.pembayaran,
    this.denda,
    this.aksiStatus = KeuanganAksiStatus.idle,
    this.aksiUrl,
    this.aksiMessage,
  });

  KeuanganDetailLoaded copyWith({
    PembayaranSppEntity? pembayaran,
    DendaEntity? denda,
    KeuanganAksiStatus? aksiStatus,
    String? aksiUrl,
    String? aksiMessage,
    bool clearAksiUrl = false,
    bool clearAksiMessage = false,
  }) {
    return KeuanganDetailLoaded(
      pembayaran: pembayaran ?? this.pembayaran,
      denda: denda ?? this.denda,
      aksiStatus: aksiStatus ?? this.aksiStatus,
      aksiUrl: clearAksiUrl ? null : (aksiUrl ?? this.aksiUrl),
      aksiMessage: clearAksiMessage
          ? null
          : (aksiMessage ?? this.aksiMessage),
    );
  }

  @override
  List<Object?> get props => [
    pembayaran,
    pembayaran.status,
    denda,
    aksiStatus,
    aksiUrl,
    aksiMessage,
  ];
}

class KeuanganDetailError extends KeuanganDetailState {
  final String message;
  const KeuanganDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

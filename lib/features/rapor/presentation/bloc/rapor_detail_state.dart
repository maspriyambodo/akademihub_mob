part of 'rapor_detail_bloc.dart';

enum RaporExportStatus { idle, loading, success, failure }

abstract class RaporDetailState extends Equatable {
  const RaporDetailState();
  @override
  List<Object?> get props => [];
}

class RaporDetailInitial extends RaporDetailState {}

class RaporDetailLoading extends RaporDetailState {}

class RaporDetailLoaded extends RaporDetailState {
  final RaporDetailEntity detail;
  final RaporExportStatus exportStatus;

  /// Path file lokal hasil unduhan (bila sukses).
  final String? exportPath;

  /// Pesan kegagalan unduhan (bila gagal).
  final String? exportMessage;

  const RaporDetailLoaded({
    required this.detail,
    this.exportStatus = RaporExportStatus.idle,
    this.exportPath,
    this.exportMessage,
  });

  RaporDetailLoaded copyWith({
    RaporDetailEntity? detail,
    RaporExportStatus? exportStatus,
    String? exportPath,
    String? exportMessage,
    bool clearExportPath = false,
    bool clearExportMessage = false,
  }) {
    return RaporDetailLoaded(
      detail: detail ?? this.detail,
      exportStatus: exportStatus ?? this.exportStatus,
      exportPath: clearExportPath ? null : (exportPath ?? this.exportPath),
      exportMessage: clearExportMessage
          ? null
          : (exportMessage ?? this.exportMessage),
    );
  }

  @override
  List<Object?> get props => [detail, exportStatus, exportPath, exportMessage];
}

class RaporDetailError extends RaporDetailState {
  final String message;
  const RaporDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

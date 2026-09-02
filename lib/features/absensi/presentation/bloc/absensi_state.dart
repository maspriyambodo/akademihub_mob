part of 'absensi_bloc.dart';

abstract class AbsensiState extends Equatable {
  const AbsensiState();
  @override
  List<Object?> get props => [];
}

class AbsensiInitial extends AbsensiState {}

class AbsensiLoading extends AbsensiState {}

class AbsensiActionInProgress extends AbsensiState {
  final AbsensiLoaded previous;
  const AbsensiActionInProgress(this.previous);

  @override
  List<Object?> get props => [previous];
}

class AbsensiLoaded extends AbsensiState {
  final AbsensiSummaryEntity summary;
  final List<AbsensiSiswaEntity> siswaItems;
  final List<AbsensiGuruEntity> guruItems;
  final int bulan;
  final int tahun;
  final String role;
  final AbsensiSiswaEntity? currentAttendance;
  final String? mutationMessage;
  final String? mutationErrorCode;
  final Map<String, dynamic> mutationErrorDetails;
  final AttendanceSettingsTarget? settingsTarget;
  final bool showContactOfficer;

  const AbsensiLoaded({
    required this.summary,
    required this.siswaItems,
    required this.guruItems,
    required this.bulan,
    required this.tahun,
    required this.role,
    this.currentAttendance,
    this.mutationMessage,
    this.mutationErrorCode,
    this.mutationErrorDetails = const {},
    this.settingsTarget,
    this.showContactOfficer = false,
  });

  bool get isGuruMode => role == 'guru';

  AbsensiLoaded copyWith({
    AbsensiSummaryEntity? summary,
    List<AbsensiSiswaEntity>? siswaItems,
    List<AbsensiGuruEntity>? guruItems,
    int? bulan,
    int? tahun,
    String? role,
    AbsensiSiswaEntity? currentAttendance,
    bool clearCurrentAttendance = false,
    String? mutationMessage,
    bool clearMutationMessage = false,
    String? mutationErrorCode,
    bool clearMutationErrorCode = false,
    Map<String, dynamic>? mutationErrorDetails,
    AttendanceSettingsTarget? settingsTarget,
    bool clearSettingsTarget = false,
    bool? showContactOfficer,
  }) {
    return AbsensiLoaded(
      summary: summary ?? this.summary,
      siswaItems: siswaItems ?? this.siswaItems,
      guruItems: guruItems ?? this.guruItems,
      bulan: bulan ?? this.bulan,
      tahun: tahun ?? this.tahun,
      role: role ?? this.role,
      currentAttendance: clearCurrentAttendance
          ? null
          : (currentAttendance ?? this.currentAttendance),
      mutationMessage: clearMutationMessage
          ? null
          : (mutationMessage ?? this.mutationMessage),
      mutationErrorCode: clearMutationErrorCode
          ? null
          : (mutationErrorCode ?? this.mutationErrorCode),
      mutationErrorDetails: mutationErrorDetails ?? this.mutationErrorDetails,
      settingsTarget: clearSettingsTarget
          ? null
          : (settingsTarget ?? this.settingsTarget),
      showContactOfficer: showContactOfficer ?? this.showContactOfficer,
    );
  }

  @override
  List<Object?> get props => [
    summary,
    siswaItems,
    guruItems,
    bulan,
    tahun,
    role,
    currentAttendance,
    mutationMessage,
    mutationErrorCode,
    mutationErrorDetails,
    settingsTarget,
    showContactOfficer,
  ];
}

class AbsensiError extends AbsensiState {
  final String message;
  final AttendanceSettingsTarget? settingsTarget;
  final bool showContactOfficer;
  const AbsensiError(
    this.message, {
    this.settingsTarget,
    this.showContactOfficer = false,
  });

  @override
  List<Object?> get props => [message, settingsTarget, showContactOfficer];
}

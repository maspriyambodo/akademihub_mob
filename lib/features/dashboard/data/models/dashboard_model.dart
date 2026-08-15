import '../../domain/entities/dashboard_entity.dart';

class DashboardModel {
  final String role;

  // Siswa / Guru / Wali shared
  final Map<String, dynamic>? profile;

  // Siswa
  final List<Map<String, dynamic>>? attendanceSummary;
  final List<Map<String, dynamic>>? unpaidSpp;
  final List<Map<String, dynamic>>? recentGrades;
  final List<Map<String, dynamic>>? upcomingTasks;

  // Guru
  final Map<String, dynamic>? summary;
  final List<Map<String, dynamic>>? recentBkCases;

  // Wali
  final List<Map<String, dynamic>>? children;

  // Admin
  final Map<String, dynamic>? summaryCards;
  final Map<String, dynamic>? financial;
  final Map<String, dynamic>? academicAttendance;
  final Map<String, dynamic>? counseling;

  const DashboardModel({
    required this.role,
    this.profile,
    this.attendanceSummary,
    this.unpaidSpp,
    this.recentGrades,
    this.upcomingTasks,
    this.summary,
    this.recentBkCases,
    this.children,
    this.summaryCards,
    this.financial,
    this.academicAttendance,
    this.counseling,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>>? asList(dynamic val) {
      if (val is List) {
        return val.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return null;
    }

    Map<String, dynamic>? asMap(dynamic val) {
      if (val is Map) return Map<String, dynamic>.from(val);
      return null;
    }

    return DashboardModel(
      role: _normalizeRole(json['role'] as String?),
      profile: asMap(json['profile']),
      attendanceSummary: asList(json['attendance_summary']),
      unpaidSpp: asList(json['unpaid_spp']),
      recentGrades: asList(json['recent_grades']),
      upcomingTasks: asList(json['upcoming_tasks']),
      summary: asMap(json['summary']),
      recentBkCases: asList(json['recent_bk_cases']),
      children: asList(json['children']),
      summaryCards: asMap(json['summary_cards']),
      financial: asMap(json['financial']),
      academicAttendance: asMap(json['academic_attendance']),
      counseling: asMap(json['counseling']),
    );
  }

  DashboardEntity toEntity() => DashboardEntity(
    role: role,
    profile: profile,
    attendanceSummary: attendanceSummary,
    unpaidSpp: unpaidSpp,
    recentGrades: recentGrades,
    upcomingTasks: upcomingTasks,
    summary: summary,
    recentBkCases: recentBkCases,
    children: children,
    summaryCards: summaryCards,
    financial: financial,
    academicAttendance: academicAttendance,
    counseling: counseling,
  );
}

String _normalizeRole(String? role) {
  switch (role?.toUpperCase()) {
    case 'SISWA':
      return 'siswa';
    case 'GURU':
      return 'guru';
    case 'WALI':
    case 'WALI_SISWA':
      return 'wali';
    default:
      return 'admin';
  }
}

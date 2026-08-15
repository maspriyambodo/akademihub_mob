import 'package:equatable/equatable.dart';

class DashboardEntity extends Equatable {
  final String role;
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

  const DashboardEntity({
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

  @override
  List<Object?> get props => [role, profile];
}

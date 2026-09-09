import 'package:equatable/equatable.dart';

class TvDeviceSummary extends Equatable {
  final int id;
  final String name;
  final String mode;

  const TvDeviceSummary({
    required this.id,
    required this.name,
    required this.mode,
  });

  @override
  List<Object?> get props => [id, name, mode];
}

class TvSchoolSummary extends Equatable {
  final String name;
  final String? logoUrl;
  final String timezone;

  const TvSchoolSummary({
    required this.name,
    this.logoUrl,
    required this.timezone,
  });

  @override
  List<Object?> get props => [name, logoUrl, timezone];
}

class TvDisplaySettings extends Equatable {
  final int slideDurationSeconds;
  final bool showAttendance;

  const TvDisplaySettings({
    required this.slideDurationSeconds,
    required this.showAttendance,
  });

  @override
  List<Object?> get props => [slideDurationSeconds, showAttendance];
}

class TvScheduleItem extends Equatable {
  final int id;
  final String subject;
  final String teacher;
  final String className;
  final String startsAt;
  final String endsAt;
  final String? room;

  const TvScheduleItem({
    required this.id,
    required this.subject,
    required this.teacher,
    required this.className,
    required this.startsAt,
    required this.endsAt,
    this.room,
  });

  @override
  List<Object?> get props => [id, subject, teacher, className, startsAt, endsAt, room];
}

class TvAnnouncementItem extends Equatable {
  final int id;
  final String title;
  final String body;
  final String? imageUrl;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String priority;

  const TvAnnouncementItem({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.startsAt,
    this.endsAt,
    required this.priority,
  });

  @override
  List<Object?> get props => [id, title, body, imageUrl, startsAt, endsAt, priority];
}

class TvCalendarItem extends Equatable {
  final int id;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool allDay;

  const TvCalendarItem({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.allDay,
  });

  @override
  List<Object?> get props => [id, title, startsAt, endsAt, allDay];
}

class TvAttendanceSummary extends Equatable {
  final int present;
  final int late;
  final int absent;
  final int total;

  const TvAttendanceSummary({
    required this.present,
    required this.late,
    required this.absent,
    required this.total,
  });

  @override
  List<Object?> get props => [present, late, absent, total];
}

class TvSnapshot extends Equatable {
  final DateTime generatedAt;
  final int refreshAfter;
  final TvDeviceSummary device;
  final TvSchoolSummary school;
  final TvDisplaySettings settings;
  final List<TvScheduleItem> schedule;
  final List<TvAnnouncementItem> announcements;
  final List<TvCalendarItem> calendar;
  final TvAttendanceSummary? attendance;

  const TvSnapshot({
    required this.generatedAt,
    required this.refreshAfter,
    required this.device,
    required this.school,
    required this.settings,
    required this.schedule,
    required this.announcements,
    required this.calendar,
    this.attendance,
  });

  @override
  List<Object?> get props => [
        generatedAt,
        refreshAfter,
        device,
        school,
        settings,
        schedule,
        announcements,
        calendar,
        attendance,
      ];
}

sealed class TvSnapshotFetch extends Equatable {
  const TvSnapshotFetch();
}

class TvSnapshotModified extends TvSnapshotFetch {
  final TvSnapshot snapshot;
  final String? etag;

  const TvSnapshotModified(this.snapshot, {this.etag});

  @override
  List<Object?> get props => [snapshot, etag];
}

class TvSnapshotNotModified extends TvSnapshotFetch {
  const TvSnapshotNotModified();

  @override
  List<Object?> get props => [];
}

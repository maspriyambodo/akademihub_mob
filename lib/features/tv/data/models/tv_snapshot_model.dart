import '../../domain/entities/tv_snapshot.dart';

class TvDeviceSummaryModel extends TvDeviceSummary {
  const TvDeviceSummaryModel({required super.id, required super.name, required super.mode});

  factory TvDeviceSummaryModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt();
    final name = json['name'] as String?;
    final mode = json['mode'] as String?;
    if (id == null || name == null || mode == null) {
      throw const FormatException('Invalid TvDeviceSummary json');
    }
    return TvDeviceSummaryModel(id: id, name: name, mode: mode);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'mode': mode};
}

class TvSchoolSummaryModel extends TvSchoolSummary {
  const TvSchoolSummaryModel({required super.name, super.logoUrl, required super.timezone});

  factory TvSchoolSummaryModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    final timezone = json['timezone'] as String? ?? 'Asia/Jakarta';
    final logoUrl = json['logo_url'] as String?;
    if (name == null || name.isEmpty) throw const FormatException('Invalid TvSchoolSummary');
    return TvSchoolSummaryModel(name: name, logoUrl: logoUrl, timezone: timezone);
  }

  Map<String, dynamic> toJson() => {'name': name, 'logo_url': logoUrl, 'timezone': timezone};
}

class TvDisplaySettingsModel extends TvDisplaySettings {
  const TvDisplaySettingsModel({required super.slideDurationSeconds, required super.showAttendance});

  factory TvDisplaySettingsModel.fromJson(Map<String, dynamic> json) {
    final dur = (json['slide_duration_seconds'] as num?)?.toInt() ?? 12;
    final att = (json['show_attendance'] as bool?) ?? true;
    return TvDisplaySettingsModel(slideDurationSeconds: dur.clamp(5, 60), showAttendance: att);
  }

  Map<String, dynamic> toJson() => {
        'slide_duration_seconds': slideDurationSeconds,
        'show_attendance': showAttendance,
      };
}

class TvScheduleItemModel extends TvScheduleItem {
  const TvScheduleItemModel({
    required super.id,
    required super.subject,
    required super.teacher,
    required super.className,
    required super.startsAt,
    required super.endsAt,
    super.room,
  });

  factory TvScheduleItemModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt();
    final subject = json['subject'] as String?;
    final teacher = json['teacher'] as String?;
    final className = (json['class'] ?? json['class_name']) as String?;
    final startsAt = json['starts_at'] as String?;
    final endsAt = json['ends_at'] as String?;
    final room = json['room'] as String?;
    if (id == null || subject == null || teacher == null || className == null || startsAt == null || endsAt == null) {
      throw const FormatException('Invalid TvScheduleItem json');
    }
    return TvScheduleItemModel(
      id: id,
      subject: subject,
      teacher: teacher,
      className: className,
      startsAt: startsAt,
      endsAt: endsAt,
      room: room,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'teacher': teacher,
        'class': className,
        'starts_at': startsAt,
        'ends_at': endsAt,
        'room': room,
      };
}

class TvAnnouncementItemModel extends TvAnnouncementItem {
  const TvAnnouncementItemModel({
    required super.id,
    required super.title,
    required super.body,
    super.imageUrl,
    super.startsAt,
    super.endsAt,
    required super.priority,
  });

  factory TvAnnouncementItemModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt();
    final title = json['title'] as String?;
    final body = json['body'] as String?;
    final imageUrl = json['image_url'] as String?;
    final startsAtStr = json['starts_at'] as String?;
    final endsAtStr = json['ends_at'] as String?;
    final priority = json['priority'] as String? ?? 'normal';
    if (id == null || title == null || body == null) {
      throw const FormatException('Invalid TvAnnouncementItem json');
    }
    return TvAnnouncementItemModel(
      id: id,
      title: title,
      body: body,
      imageUrl: imageUrl,
      startsAt: startsAtStr != null ? DateTime.parse(startsAtStr).toUtc() : null,
      endsAt: endsAtStr != null ? DateTime.parse(endsAtStr).toUtc() : null,
      priority: priority,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'image_url': imageUrl,
        'starts_at': startsAt?.toIso8601String(),
        'ends_at': endsAt?.toIso8601String(),
        'priority': priority,
      };
}


class TvCalendarItemModel extends TvCalendarItem {
  const TvCalendarItemModel({
    required super.id,
    required super.title,
    required super.startsAt,
    required super.endsAt,
    required super.allDay,
  });

  factory TvCalendarItemModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt();
    final title = json['title'] as String?;
    final startsAtStr = json['starts_at'] as String?;
    final endsAtStr = json['ends_at'] as String?;
    final allDay = (json['all_day'] as bool?) ?? true;
    if (id == null || title == null || startsAtStr == null || endsAtStr == null) {
      throw const FormatException('Invalid TvCalendarItem json');
    }
    return TvCalendarItemModel(
      id: id,
      title: title,
      startsAt: DateTime.parse(startsAtStr).toUtc(),
      endsAt: DateTime.parse(endsAtStr).toUtc(),
      allDay: allDay,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt.toIso8601String(),
        'all_day': allDay,
      };
}

class TvAttendanceSummaryModel extends TvAttendanceSummary {
  const TvAttendanceSummaryModel({
    required super.present,
    required super.late,
    required super.absent,
    required super.total,
  });

  factory TvAttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    final present = (json['present'] as num?)?.toInt() ?? 0;
    final late = (json['late'] as num?)?.toInt() ?? 0;
    final absent = (json['absent'] as num?)?.toInt() ?? 0;
    final total = (json['total'] as num?)?.toInt() ?? (present + late + absent);
    return TvAttendanceSummaryModel(present: present, late: late, absent: absent, total: total);
  }

  Map<String, dynamic> toJson() => {
        'present': present,
        'late': late,
        'absent': absent,
        'total': total,
      };
}

class TvSnapshotModel extends TvSnapshot {
  const TvSnapshotModel({
    required super.generatedAt,
    required super.refreshAfter,
    required super.device,
    required super.school,
    required super.settings,
    required super.schedule,
    required super.announcements,
    required super.calendar,
    super.attendance,
  });

  factory TvSnapshotModel.fromJson(Map<String, dynamic> json) {
    final genAtStr = json['generated_at'] as String?;
    final refreshAfter = (json['refresh_after_seconds'] as num?)?.toInt() ?? 300;
    final deviceMap = json['device'] as Map<String, dynamic>?;
    final schoolMap = json['school'] as Map<String, dynamic>?;
    final settingsMap = json['settings'] as Map<String, dynamic>?;

    if (genAtStr == null || deviceMap == null || schoolMap == null || settingsMap == null) {
      throw const FormatException('Missing required snapshot fields');
    }

    final scheduleList = (json['schedule'] as List<dynamic>?)
            ?.map((e) => TvScheduleItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final announcementsList = (json['announcements'] as List<dynamic>?)
            ?.map((e) => TvAnnouncementItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final calendarList = (json['calendar'] as List<dynamic>?)
            ?.map((e) => TvCalendarItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final attendanceMap = json['attendance'] as Map<String, dynamic>?;

    return TvSnapshotModel(
      generatedAt: DateTime.parse(genAtStr).toUtc(),
      refreshAfter: refreshAfter.clamp(30, 3600),
      device: TvDeviceSummaryModel.fromJson(deviceMap),
      school: TvSchoolSummaryModel.fromJson(schoolMap),
      settings: TvDisplaySettingsModel.fromJson(settingsMap),
      schedule: scheduleList,
      announcements: announcementsList,
      calendar: calendarList,
      attendance: attendanceMap != null ? TvAttendanceSummaryModel.fromJson(attendanceMap) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'generated_at': generatedAt.toIso8601String(),
        'refresh_after_seconds': refreshAfter,
        'device': {
          'id': device.id,
          'name': device.name,
          'mode': device.mode,
        },
        'school': {
          'name': school.name,
          'logo_url': school.logoUrl,
          'timezone': school.timezone,
        },
        'settings': {
          'slide_duration_seconds': settings.slideDurationSeconds,
          'show_attendance': settings.showAttendance,
        },
        'schedule': schedule
            .map((e) => {
                  'id': e.id,
                  'subject': e.subject,
                  'teacher': e.teacher,
                  'class': e.className,
                  'starts_at': e.startsAt,
                  'ends_at': e.endsAt,
                  'room': e.room,
                })
            .toList(),
        'announcements': announcements
            .map((e) => {
                  'id': e.id,
                  'title': e.title,
                  'body': e.body,
                  'image_url': e.imageUrl,
                  'starts_at': e.startsAt?.toIso8601String(),
                  'ends_at': e.endsAt?.toIso8601String(),
                  'priority': e.priority,
                })
            .toList(),
        'calendar': calendar
            .map((e) => {
                  'id': e.id,
                  'title': e.title,
                  'starts_at': e.startsAt.toIso8601String(),
                  'ends_at': e.endsAt.toIso8601String(),
                  'all_day': e.allDay,
                })
            .toList(),
        'attendance': attendance != null
            ? {
                'present': attendance!.present,
                'late': attendance!.late,
                'absent': attendance!.absent,
                'total': attendance!.total,
              }
            : null,
      };
}


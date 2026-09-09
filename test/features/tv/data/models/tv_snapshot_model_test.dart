import 'package:akademihub_mob/features/tv/data/models/tv_snapshot_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TvSnapshotModel', () {
    final validJson = {
      'generated_at': '2026-09-05T14:20:00Z',
      'refresh_after_seconds': 300,
      'device': {
        'id': 42,
        'name': 'TV Lobby Utama',
        'mode': 'signage',
      },
      'school': {
        'name': 'SMA Negeri 1 Jakarta',
        'logo_url': 'https://example.com/logo.png',
        'timezone': 'Asia/Jakarta',
      },
      'settings': {
        'slide_duration_seconds': 12,
        'show_attendance': true,
      },
      'schedule': [
        {
          'id': 1,
          'subject': 'Matematika',
          'teacher': 'Budi Santoso, S.Pd.',
          'class': 'XII MIPA 1',
          'starts_at': '07:30',
          'ends_at': '09:00',
          'room': 'R.301',
        }
      ],
      'announcements': [
        {
          'id': 10,
          'title': 'Upacara Hari Senin',
          'body': 'Seluruh siswa wajib memakai seragam lengkap.',
          'image_url': null,
          'starts_at': '2026-09-01T00:00:00Z',
          'ends_at': '2026-09-10T23:59:59Z',
          'priority': 'normal',
        }
      ],
      'calendar': [
        {
          'id': 5,
          'title': 'Penilaian Tengah Semester',
          'starts_at': '2026-09-15T00:00:00Z',
          'ends_at': '2026-09-20T23:59:59Z',
          'all_day': true,
        }
      ],
      'attendance': {
        'present': 820,
        'late': 15,
        'absent': 8,
        'total': 843,
      },
    };

    test('fromJson parses complete valid JSON correctly', () {
      final model = TvSnapshotModel.fromJson(validJson);

      expect(model.generatedAt, DateTime.utc(2026, 9, 5, 14, 20, 0));
      expect(model.refreshAfter, 300);
      expect(model.device.name, 'TV Lobby Utama');
      expect(model.school.name, 'SMA Negeri 1 Jakarta');
      expect(model.settings.slideDurationSeconds, 12);
      expect(model.schedule.length, 1);
      expect(model.schedule.first.subject, 'Matematika');
      expect(model.schedule.first.className, 'XII MIPA 1');
      expect(model.announcements.length, 1);
      expect(model.calendar.length, 1);
      expect(model.attendance?.present, 820);
    });

    test('fromJson clamps slide duration between 5 and 60 seconds', () {
      final customJson = Map<String, dynamic>.from(validJson);
      customJson['settings'] = {
        'slide_duration_seconds': 2,
        'show_attendance': false,
      };

      final model = TvSnapshotModel.fromJson(customJson);
      expect(model.settings.slideDurationSeconds, 5);
      expect(model.settings.showAttendance, isFalse);
    });

    test('toJson and fromJson preserves data round-trip', () {
      final model = TvSnapshotModel.fromJson(validJson);
      final jsonMap = model.toJson();
      final reconstructed = TvSnapshotModel.fromJson(jsonMap);

      expect(reconstructed.generatedAt, model.generatedAt);
      expect(reconstructed.device.id, model.device.id);
      expect(reconstructed.school.name, model.school.name);
      expect(reconstructed.schedule.first.subject, model.schedule.first.subject);
      expect(reconstructed.announcements.first.title, model.announcements.first.title);
    });

    test('fromJson throws FormatException when required fields are missing', () {
      expect(
        () => TvSnapshotModel.fromJson({'generated_at': '2026-09-05T14:20:00Z'}),
        throwsFormatException,
      );
    });
  });
}

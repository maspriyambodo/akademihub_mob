import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../domain/entities/attendance_location.dart';

enum AttendanceSettingsTarget { app, location }

class AttendanceLocationException implements Exception {
  final String message;
  final AttendanceSettingsTarget? settingsTarget;

  const AttendanceLocationException(this.message, {this.settingsTarget});
}

Future<bool> openAttendanceSettings(AttendanceSettingsTarget target) =>
    target == AttendanceSettingsTarget.app
    ? Geolocator.openAppSettings()
    : Geolocator.openLocationSettings();

class AttendanceLocationService {
  Future<AttendanceLocation> capture() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const AttendanceLocationException(
        'Layanan lokasi sedang mati. Aktifkan GPS, lalu coba lagi.',
        settingsTarget: AttendanceSettingsTarget.location,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const AttendanceLocationException(
        'Izin lokasi ditolak. Izinkan lokasi saat diminta, lalu coba lagi.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const AttendanceLocationException(
        'Izin lokasi ditolak permanen. Aktifkan izin lokasi melalui Pengaturan aplikasi.',
        settingsTarget: AttendanceSettingsTarget.app,
      );
    }

    late final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      throw const AttendanceLocationException(
        'Pencarian lokasi terlalu lama. Coba lagi di area terbuka.',
      );
    }
    if (position.accuracy < 0 || position.accuracy > 100) {
      throw const AttendanceLocationException(
        'Akurasi lokasi lebih dari 100 meter. Coba lagi di area terbuka.',
      );
    }
    return AttendanceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeter: position.accuracy,
      capturedAt: position.timestamp,
    );
  }
}

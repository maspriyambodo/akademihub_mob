import 'package:geolocator/geolocator.dart';

import '../../domain/entities/attendance_location.dart';

class AttendanceLocationService {
  Future<AttendanceLocation> capture() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Aktifkan layanan lokasi untuk melakukan absensi.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw StateError('Izin lokasi diperlukan untuk melakukan absensi.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Izin lokasi ditolak permanen. Aktifkan melalui pengaturan aplikasi.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return AttendanceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeter: position.accuracy,
      capturedAt: position.timestamp,
    );
  }
}

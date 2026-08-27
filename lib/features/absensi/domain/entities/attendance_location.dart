class AttendanceLocation {
  final double latitude;
  final double longitude;
  final double accuracyMeter;
  final DateTime capturedAt;

  const AttendanceLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeter,
    required this.capturedAt,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy_meter': accuracyMeter,
    'captured_at': capturedAt.toUtc().toIso8601String(),
  };
}

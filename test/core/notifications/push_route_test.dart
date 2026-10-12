void main() {
  String? resolveRoute(Map<String, dynamic> data) {
    final explicitRoute = data['route']?.toString();
    if (explicitRoute != null && explicitRoute.isNotEmpty) {
      return explicitRoute;
    }
    final type = data['type']?.toString();
    return switch (type) {
      'absensi' || 'absensi_kritis' => '/absensi',
      'spp' || 'spp_tunggakan' || 'keuangan' => '/keuangan',
      'ews_alert' || 'ews' => '/ews',
      'tugas' || 'tugas_baru' => '/tugas',
      'nilai' || 'nilai_anomali' => '/nilai',
      'jadwal' => '/jadwal',
      'ujian' => '/ujian',
      'wallet' || 'saldo' => '/wallet',
      _ => null,
    };
  }

  assert(resolveRoute({'route': '/custom/path'}) == '/custom/path');
  assert(resolveRoute({'type': 'absensi_kritis'}) == '/absensi');
  assert(resolveRoute({'type': 'spp_tunggakan'}) == '/keuangan');
  assert(resolveRoute({'type': 'ews_alert'}) == '/ews');
  assert(resolveRoute({'type': 'tugas_baru'}) == '/tugas');
  assert(resolveRoute({'type': 'unknown'}) == null);
}

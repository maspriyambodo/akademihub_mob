import 'package:akademihub_mob/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UserEntity user(Map<String, dynamic> profile) => UserEntity(
    id: 10,
    name: 'Siswa',
    email: 'siswa@example.test',
    role: 'siswa',
    profile: profile,
  );

  test('profileId membaca variasi ID profil siswa', () {
    expect(user({'mst_siswa_id': 62}).profileId, 62);
    expect(user({'siswa_id': '62'}).profileId, 62);
    expect(
      user({
        'siswa': {'id': 62},
      }).profileId,
      62,
    );
    expect(user({'id': 62}).profileId, 62);
  });
}

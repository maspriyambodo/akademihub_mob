import 'package:akademihub_mob/features/auth/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses permission objects returned by the API', () {
    final user = UserModel.fromJson({
      'id': 99,
      'name': 'Abi Yusuf',
      'email': 'abiyusuf@sekolah.com',
      'role': 'SUPER_ADMIN',
      'is_active': true,
      'permissions': [
        {'id': 1, 'code': 'users.view', 'name': 'Lihat User'},
        {'id': 2, 'code': 'users.create', 'name': 'Buat User'},
      ],
    });

    expect(user.permissions, ['users.view', 'users.create']);
    expect(user.isAdmin, isTrue);
  });

  test('still parses permission code strings', () {
    final user = UserModel.fromJson({
      'id': 1,
      'name': 'Guru',
      'email': 'guru@sekolah.com',
      'role': 'GURU',
      'is_active': true,
      'permissions': ['materi.view'],
    });

    expect(user.permissions, ['materi.view']);
    expect(user.isGuru, isTrue);
    expect(user.normalizedRole, 'guru');
  });

  test('normalizes API roles for role-specific mobile screens', () {
    final siswa = UserModel.fromJson({
      'id': 2,
      'name': 'Siswa',
      'email': 'siswa@sekolah.com',
      'role': 'SISWA',
      'is_active': true,
    });
    final wali = UserModel.fromJson({
      'id': 3,
      'name': 'Wali',
      'email': 'wali@sekolah.com',
      'role': 'WALI_SISWA',
      'is_active': true,
    });

    expect(siswa.normalizedRole, 'siswa');
    expect(wali.normalizedRole, 'wali');
  });
}

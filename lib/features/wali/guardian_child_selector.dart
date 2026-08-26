import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class GuardianChild {
  final int id;
  final String name;
  final int? kelasId;

  const GuardianChild({required this.id, required this.name, this.kelasId});

  factory GuardianChild.fromJson(Map<String, dynamic> json) {
    final kelas = json['kelas'];
    return GuardianChild(
      id: _id(json['id'])!,
      name: json['nama'] as String? ?? 'Siswa',
      kelasId: kelas is Map ? _id(kelas['id']) : _id(json['mst_kelas_id']),
    );
  }

  static int? _id(Object? value) => switch (value) {
    int value => value,
    num value => value.toInt(),
    String value => int.tryParse(value),
    _ => null,
  };
}

/// Authoritative child relation. Cache intentionally lives only in memory.
class GuardianChildService {
  final Dio _dio;
  final _cache = <int, Future<List<GuardianChild>>>{};

  GuardianChildService(this._dio);

  Future<List<GuardianChild>> getChildren(int waliId) => _cache.putIfAbsent(
    waliId,
    () async {
      final response = await _dio.get('/wali/$waliId/siswa');
      final body = response.data;
      final data = body is Map ? body['data'] ?? body : body;
      final rows = data is List ? data : const [];
      return rows
          .whereType<Map>()
          .map((row) => GuardianChild.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    },
  );
}

class GuardianChildSelector extends StatelessWidget {
  final List<GuardianChild> children;
  final int selectedId;
  final ValueChanged<GuardianChild> onChanged;

  const GuardianChildSelector({
    super.key,
    required this.children,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: DropdownButtonFormField<int>(
      initialValue: selectedId,
      decoration: const InputDecoration(labelText: 'Anak'),
      items: children
          .map(
            (child) =>
                DropdownMenuItem(value: child.id, child: Text(child.name)),
          )
          .toList(growable: false),
      onChanged: (id) {
        if (id == null) return;
        onChanged(children.firstWhere((child) => child.id == id));
      },
    ),
  );
}

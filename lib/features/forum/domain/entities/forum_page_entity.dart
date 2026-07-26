import 'package:equatable/equatable.dart';

import 'forum_entity.dart';

/// Satu halaman hasil `GET /akademik/forum`.
///
/// Backend memakai `cursorPaginate`, jadi paginasi memakai cursor (bukan nomor
/// halaman). Meta yang dikirim: `next_cursor`, `prev_cursor`, `has_more`,
/// dan `total`.
class ForumPageEntity extends Equatable {
  final List<ForumEntity> items;

  /// Cursor untuk permintaan halaman berikutnya (`?cursor=...`).
  final String? nextCursor;

  /// Masih ada halaman berikutnya?
  final bool hasMore;

  /// Total seluruh baris (bisa null bila backend tidak menghitungnya).
  final int? total;

  const ForumPageEntity({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
    this.total,
  });

  static const ForumPageEntity kosong = ForumPageEntity(items: []);

  @override
  List<Object?> get props => [items, nextCursor, hasMore, total];
}

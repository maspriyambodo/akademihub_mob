import '../../domain/entities/forum_page_entity.dart';
import 'forum_model.dart';

/// Satu halaman hasil index forum beserta meta paginasinya.
class ForumPageModel {
  final List<ForumModel> items;
  final String? nextCursor;
  final bool hasMore;
  final int? total;

  const ForumPageModel({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
    this.total,
  });

  ForumPageEntity toEntity() => ForumPageEntity(
    items: items.map((m) => m.toEntity()).toList(),
    nextCursor: nextCursor,
    hasMore: hasMore,
    total: total,
  );
}

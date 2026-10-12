import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/ujian_question_entity.dart';

typedef CbtImageDownloader = Future<void> Function(String url);

/// Service for prefetching question images and options media before/during CBT exams.
/// Ensures all exam images are cached to local disk storage for schools with minim sinyal (offline tolerance).
///
/// ponytail: uses DefaultCacheManager disk store. Upgrade to encrypted custom cache store if question media requires DRM/scrambling.
class CbtMediaPrefetchService {
  final BaseCacheManager _cacheManager;
  final CbtImageDownloader? _customDownloader;

  static final _imgTagRegex =
      RegExp(r'<img[^>]+src=["\x27]([^"\x27]+)["\x27]', caseSensitive: false);
  static final _mdImgRegex =
      RegExp(r'!\[.*?\]\((https?://[^\s\)]+|/[^\s\)]+)\)', caseSensitive: false);

  CbtMediaPrefetchService({
    BaseCacheManager? cacheManager,
    CbtImageDownloader? customDownloader,
  })  : _cacheManager = cacheManager ?? DefaultCacheManager(),
        _customDownloader = customDownloader;

  /// Scans all questions and options for media URLs.
  List<String> extractImageUrls(List<UjianQuestionEntity> questions) {
    final urls = <String>{};

    for (final q in questions) {
      if (q.mediaPath != null) {
        final resolved = AppConfig.resolveMediaUrl(q.mediaPath);
        if (resolved != null && resolved.isNotEmpty) {
          urls.add(resolved);
        }
      }

      _extractFromText(q.question, urls);

      for (final opt in q.options) {
        _extractFromText(opt.text, urls);
      }
    }

    return urls.toList();
  }

  void _extractFromText(String text, Set<String> urls) {
    if (text.isEmpty) return;

    for (final match in _imgTagRegex.allMatches(text)) {
      final src = match.group(1);
      final resolved = AppConfig.resolveMediaUrl(src);
      if (resolved != null && resolved.isNotEmpty) {
        urls.add(resolved);
      }
    }

    for (final match in _mdImgRegex.allMatches(text)) {
      final src = match.group(1);
      final resolved = AppConfig.resolveMediaUrl(src);
      if (resolved != null && resolved.isNotEmpty) {
        urls.add(resolved);
      }
    }
  }

  /// Downloads all extracted image URLs to local disk cache.
  /// Returns count of successfully cached images.
  Future<int> prefetchImages(List<UjianQuestionEntity> questions) async {
    final urls = extractImageUrls(questions);
    if (urls.isEmpty) return 0;

    int successCount = 0;
    await Future.wait(
      urls.map((url) async {
        try {
          if (_customDownloader != null) {
            await _customDownloader(url);
          } else {
            await _cacheManager.getSingleFile(url);
          }
          successCount++;
        } catch (e) {
          debugPrint('CBT prefetch image failed for $url: $e');
        }
      }),
    );

    return successCount;
  }
}

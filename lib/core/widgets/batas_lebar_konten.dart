import 'package:flutter/material.dart';

import '../utils/responsive.dart';

/// Membatasi lebar konten di layar lebar agar teks/kartu tidak melebar
/// tak terbaca. Di layar sempit child dikembalikan apa adanya.
///
/// Pola yang disarankan:
/// ```dart
/// Center(
///   child: BatasLebarKonten(
///     child: ListView(...),
///   ),
/// )
/// ```
/// atau cukup `BatasLebarKonten` saja (sudah memusatkan saat expanded).
class BatasLebarKonten extends StatelessWidget {
  final Widget child;

  /// Override batas lebar. Default: [Responsive.lebarKontenMaks].
  final double? maxWidth;

  const BatasLebarKonten({super.key, required this.child, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final batas = maxWidth ?? Responsive.lebarKontenMaks(context);
    if (!batas.isFinite) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: batas),
        child: child,
      ),
    );
  }
}

/// Membungkus body halaman dengan padding adaptif + batas lebar konten.
///
/// Cocok untuk [ListView], [CustomScrollView], atau konten statis.
class AdaptivePageBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool constrainWidth;

  const AdaptivePageBody({
    super.key,
    required this.child,
    this.padding,
    this.constrainWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final pad = padding ?? Responsive.pagePadding(context);
    Widget content = Padding(padding: pad, child: child);
    if (constrainWidth) {
      content = BatasLebarKonten(child: content);
    }
    return content;
  }
}

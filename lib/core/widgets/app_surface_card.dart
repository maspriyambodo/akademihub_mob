import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Surface card berbasis token Ruang Belajar Nusantara.
///
/// Menggunakan surface `paperBright`, radius 20, dan level-1 shadow.
/// Jika [accentColor] diberikan, strip vertikal 4dp ditampilkan di sisi kiri.
class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Color? accentColor;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.semanticLabel,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadius.lg);

    Widget content = Padding(padding: padding, child: child);

    if (accentColor != null) {
      content = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accentColor),
            Expanded(child: content),
          ],
        ),
      );
    }

    Widget cardBody = Material(
      color: Colors.transparent,
      child: onTap != null
          ? InkWell(onTap: onTap, borderRadius: borderRadius, child: content)
          : content,
    );

    Widget card = Container(
      decoration: BoxDecoration(
        color: AppColors.paperBright,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.line.withValues(alpha: 0.55)),
        boxShadow: AppElevation.level1,
      ),
      clipBehavior: Clip.antiAlias,
      child: cardBody,
    );

    if (semanticLabel != null || onTap != null) {
      return Semantics(
        label: semanticLabel,
        button: onTap != null,
        container: true,
        child: card,
      );
    }

    return card;
  }
}

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

    // ponytail: Subtle border radius on vertical accent bar; full shape border when custom card border styling requested.
    if (accentColor != null) {
      content = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(2),
                ),
              ),
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    Widget cardBody = Material(
      color: Colors.transparent,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: borderRadius,
              splashColor: AppColors.primaryLight.withValues(alpha: 0.25),
              highlightColor: Colors.transparent,
              child: content,
            )
          : content,
    );

    Widget card = Container(
      decoration: BoxDecoration(
        color: AppColors.paperBright,
        borderRadius: borderRadius,
        border: Border.all(
          color: AppColors.line.withValues(alpha: 0.6),
          width: 1.0,
        ),
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

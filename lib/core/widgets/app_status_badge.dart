import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Status badge berbasis token Ruang Belajar Nusantara.
///
/// Radius pill, padding (10, 5), icon 14, label 11/700, container/on-container sesuai tone.
class AppStatusBadge extends StatelessWidget {
  final String label;
  final AppStatusTone tone;
  final IconData? icon;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.semantic(tone);

    return Semantics(
      label: '$label, status',
      container: true,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.container,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: colors.onContainer),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Text(
              label,
              style: TextStyle(
                color: colors.onContainer,
                fontSize: 11,
                height: 14 / 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_surface_card.dart';

/// Metric tile untuk ringkasan angka, persentase, dan statistik akademik.
///
/// Menggunakan tabular figures, semantics terpadu, dan layout fleksibel (tidak fixed-height).
class AppMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final AppStatusTone tone;
  final String? supportingText;

  const AppMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
    this.supportingText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.semantic(tone);
    final textTheme = Theme.of(context).textTheme;
    final valueStyle =
        (Theme.of(context).extension<AppDataTypography>()?.value ??
                textTheme.headlineMedium ??
                const TextStyle())
            .copyWith(
              color: AppColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            );

    final semanticText = StringBuffer('$label, $value');
    if (supportingText != null && supportingText!.isNotEmpty) {
      semanticText.write(', $supportingText');
    }

    return Semantics(
      label: semanticText.toString(),
      container: true,
      excludeSemantics: true,
      child: AppSurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.container,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, size: 18, color: colors.onContainer),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: valueStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (supportingText != null && supportingText!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                supportingText!,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

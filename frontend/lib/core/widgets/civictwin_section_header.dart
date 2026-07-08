import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// **CivicTwinSectionHeader**
///
/// A premium layout header component.
/// Provides typography hierarchy, secondary actions, and visual separator alignments.
class CivicTwinSectionHeader extends StatelessWidget {
  const CivicTwinSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppDesignSystem.heading3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (action != null) action!,
          ],
        ),
        if (subtitle != null) ...[
          AppDesignSystem.height4,
          Text(
            subtitle!,
            style: AppDesignSystem.bodySmall.copyWith(
              color: AppDesignSystem.textMuted,
            ),
          ),
        ],
        AppDesignSystem.height12,
        const Divider(
          color: AppDesignSystem.brandBorderTranslucent,
          height: 1.0,
          thickness: 1.0,
        ),
      ],
    );
  }
}

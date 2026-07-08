import 'package:flutter/material.dart';
import '../theme/design_system.dart';

enum CivicTwinStatusType { success, error, warning, info, muted }

/// **CivicTwinStatusChip**
///
/// A reusable chip wrapper.
/// Styles its borders and background using the design system's semantic color palette
/// to signify status metrics (e.g. HIGH/MEDIUM/LOW priorities or Open/Closed statuses).
class CivicTwinStatusChip extends StatelessWidget {
  const CivicTwinStatusChip({
    super.key,
    required this.label,
    this.type = CivicTwinStatusType.muted,
  });

  final String label;
  final CivicTwinStatusType type;

  @override
  Widget build(BuildContext context) {
    Color baseColor;

    switch (type) {
      case CivicTwinStatusType.success:
        baseColor = AppDesignSystem.semanticSuccess;
        break;
      case CivicTwinStatusType.error:
        baseColor = AppDesignSystem.semanticError;
        break;
      case CivicTwinStatusType.warning:
        baseColor = AppDesignSystem.semanticWarning;
        break;
      case CivicTwinStatusType.info:
        baseColor = AppDesignSystem.semanticInfo;
        break;
      case CivicTwinStatusType.muted:
        baseColor = AppDesignSystem.textMuted;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.08),
        borderRadius: AppDesignSystem.borderRadii4,
        border: Border.all(
          color: baseColor.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.space8,
        vertical: AppDesignSystem.space4,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppDesignSystem.label.copyWith(
          color: baseColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

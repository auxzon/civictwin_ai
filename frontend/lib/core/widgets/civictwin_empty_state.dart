import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// **CivicTwinEmptyState**
///
/// A visual placeholder panel displayed when data collections (e.g. historical plans)
/// are empty. Provides clean design elements, descriptions, and icon mappings.
class CivicTwinEmptyState extends StatelessWidget {
  const CivicTwinEmptyState({
    super.key,
    required this.message,
    this.description,
    this.icon = Icons.info_outline,
  });

  final String message;
  final String? description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppDesignSystem.brandBorderTranslucent,
                border: Border.all(
                  color: AppDesignSystem.brandBorderTranslucent,
                ),
              ),
              child: Icon(
                icon,
                size: AppDesignSystem.iconSizeLarge,
                color: AppDesignSystem.textMuted,
              ),
            ),
            AppDesignSystem.height16,
            Text(
              message,
              style: AppDesignSystem.title.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              AppDesignSystem.height8,
              Text(
                description!,
                style: AppDesignSystem.bodySmall.copyWith(
                  color: AppDesignSystem.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

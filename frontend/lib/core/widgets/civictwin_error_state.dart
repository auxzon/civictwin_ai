import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import 'civictwin_button.dart';

/// **CivicTwinErrorState**
///
/// Displayed when network operations, API pipeline calls, or database retrievals fail.
/// Features high-contrast error descriptions and an action button to retry.
class CivicTwinErrorState extends StatelessWidget {
  const CivicTwinErrorState({
    super.key,
    required this.errorText,
    this.onRetry,
  });

  final String errorText;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.space32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppDesignSystem.semanticError.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppDesignSystem.semanticError.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: AppDesignSystem.iconSizeLarge,
                  color: AppDesignSystem.semanticError,
                ),
              ),
              AppDesignSystem.height16,
              Text(
                'System Error',
                style: AppDesignSystem.heading3.copyWith(
                  color: AppDesignSystem.textPrimary,
                ),
              ),
              AppDesignSystem.height8,
              Text(
                errorText,
                style: AppDesignSystem.body.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (onRetry != null) ...[
                AppDesignSystem.height24,
                CivicTwinButton(
                  onPressed: onRetry,
                  label: 'Retry Operation',
                  variant: CivicTwinButtonVariant.secondary,
                  icon: Icons.refresh,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// **CivicTwinSpinner**
///
/// A premium circular progress loader styled to match the dark neon theme of CivicTwin AI.
/// Provides visual consistency across loading overlays and spinners.
class CivicTwinSpinner extends StatelessWidget {
  const CivicTwinSpinner({
    super.key,
    this.size = 32.0,
    this.strokeWidth = 3.0,
  });

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: const AlwaysStoppedAnimation<Color>(
            AppDesignSystem.brandNeonCyan,
          ),
          backgroundColor: AppDesignSystem.brandNeonCyanDim,
        ),
      ),
    );
  }
}

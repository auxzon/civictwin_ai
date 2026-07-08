import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// **CivicTwinGlassPanel**
///
/// A premium glassmorphic container widget featuring customized backdrop filter blur,
/// translucent borders, background opacity controls, and custom drop shadows.
/// Reinforced to serve as the visual shell for all floating overlay panels.
class CivicTwinGlassPanel extends StatelessWidget {
  const CivicTwinGlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor,
    this.blurSigmaX,
    this.blurSigmaY,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final double? blurSigmaX;
  final double? blurSigmaY;

  @override
  Widget build(BuildContext context) {
    final activeBorderRadius = borderRadius ?? AppDesignSystem.borderRadii12;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: activeBorderRadius,
        boxShadow: AppDesignSystem.shadowSubtle,
      ),
      child: ClipRRect(
        borderRadius: activeBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigmaX ?? AppDesignSystem.glassBlurSigma,
            sigmaY: blurSigmaY ?? AppDesignSystem.glassBlurSigma,
          ),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppDesignSystem.space16),
            decoration: BoxDecoration(
              color: backgroundColor ?? AppDesignSystem.brandObsidianOverlay,
              borderRadius: activeBorderRadius,
              border: Border.all(
                color: borderColor ?? AppDesignSystem.brandBorderTranslucent,
                width: AppDesignSystem.glassBorderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

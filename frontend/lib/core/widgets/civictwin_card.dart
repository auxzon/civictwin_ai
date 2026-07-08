import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// **CivicTwinCard**
///
/// A premium card wrapper widget designed for data-dense layouts.
/// Provides metallic surface coloration, customizable hover animation states,
/// standard margins, and padding.
class CivicTwinCard extends StatefulWidget {
  const CivicTwinCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  State<CivicTwinCard> createState() => _CivicTwinCardState();
}

class _CivicTwinCardState extends State<CivicTwinCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hasAction = widget.onTap != null;

    final Widget cardContent = Container(
      padding: widget.padding ?? const EdgeInsets.all(AppDesignSystem.space16),
      child: widget.child,
    );

    return MouseRegion(
      onEnter: (_) => hasAction ? setState(() => _isHovered = true) : null,
      onExit: (_) => hasAction ? setState(() => _isHovered = false) : null,
      cursor: hasAction ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF141619)
                : AppDesignSystem.brandMetallicSurface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12), // Modern rounded corners
            border: Border.all(
              color: _isHovered
                  ? AppDesignSystem.brandNeonCyan.withValues(alpha: 0.6)
                  : AppDesignSystem.brandBorderTranslucent,
              width: 1.2,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppDesignSystem.brandNeonCyan.withValues(alpha: 0.08),
                      blurRadius: 15,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: cardContent,
        ),
      ),
    );
  }
}

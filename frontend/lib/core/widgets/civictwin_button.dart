import 'package:flutter/material.dart';
import '../theme/design_system.dart';

enum CivicTwinButtonVariant { primary, secondary }

/// **CivicTwinButton**
///
/// A premium reusable button component designed to match Linear, Stripe, and Apple visual design.
/// - **Primary Variant:** Dark metallic body with a glowing neon cyan border that gets brighter on hover.
/// - **Secondary Variant:** Outlined glassmorphic style with white text and clean hover transitions.
/// Supports a custom loading spinner state and customizable prefix/suffix icons.
class CivicTwinButton extends StatefulWidget {
  const CivicTwinButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.variant = CivicTwinButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  final VoidCallback? onPressed;
  final String label;
  final CivicTwinButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  @override
  State<CivicTwinButton> createState() => _CivicTwinButtonState();
}

class _CivicTwinButtonState extends State<CivicTwinButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final isPrimary = widget.variant == CivicTwinButtonVariant.primary;

    Color bg;
    Border border;
    List<BoxShadow>? shadows;
    Color fg;

    if (isDisabled) {
      bg = isPrimary
          ? const Color(0xFF0D0F12).withValues(alpha: 0.5)
          : Colors.transparent;
      border = Border.all(
        color: Colors.white.withValues(alpha: 0.1),
        width: 1.2,
      );
      fg = AppDesignSystem.textMuted;
      shadows = null;
    } else {
      if (isPrimary) {
        bg = _isHovered ? const Color(0xFF0F1216) : const Color(0xFF0D0F12);
        border = Border.all(
          color: AppDesignSystem.brandNeonCyan.withValues(alpha: _isHovered ? 0.8 : 0.3),
          width: 1.2,
        );
        fg = Colors.white;
        shadows = _isHovered
            ? [
                BoxShadow(
                  color: AppDesignSystem.brandNeonCyan.withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: 1,
                )
              ]
            : null;
      } else {
        bg = _isHovered
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.transparent;
        border = Border.all(
          color: _isHovered
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.2),
          width: 1.2,
        );
        fg = Colors.white;
        shadows = null;
      }
    }

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: const AlwaysStoppedAnimation<Color>(AppDesignSystem.brandNeonCyan),
              backgroundColor: AppDesignSystem.brandNeonCyanDim,
            ),
          ),
          const SizedBox(width: 12),
        ] else if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: 16,
            color: isPrimary ? AppDesignSystem.brandNeonCyan : Colors.white.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontFamilyFallback: const ['Geist', 'Inter', 'system-ui', 'sans-serif'],
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fg,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );

    return MouseRegion(
      cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => isDisabled ? null : setState(() => _isHovered = true),
      onExit: (_) => isDisabled ? null : setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: widget.width,
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: bg,
            border: border,
            borderRadius: BorderRadius.circular(8),
            boxShadow: shadows,
          ),
          child: content,
        ),
      ),
    );
  }
}

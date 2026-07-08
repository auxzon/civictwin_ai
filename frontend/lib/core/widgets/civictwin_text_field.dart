import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// **CivicTwinTextField**
///
/// A premium reusable text field widget styled to fit the dark glassmorphic dashboard theme.
/// Features a dark semitransparent canvas surface, dynamic focus/hover borders, custom icons,
/// and high-contrast typography scaling.
class CivicTwinTextField extends StatefulWidget {
  const CivicTwinTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  State<CivicTwinTextField> createState() => _CivicTwinTextFieldState();
}

class _CivicTwinTextFieldState extends State<CivicTwinTextField> {
  final _focusNode = FocusNode();
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _focusNode.hasFocus;

    Color borderColor = AppDesignSystem.brandBorderTranslucent;
    if (hasFocus) {
      borderColor = AppDesignSystem.brandNeonCyan;
    } else if (_isHovered) {
      borderColor = AppDesignSystem.brandNeonCyan.withValues(alpha: 0.5);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.text,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppDesignSystem.durationFast,
        curve: AppDesignSystem.curveStandard,
        decoration: BoxDecoration(
          color: AppDesignSystem.brandMetallicSurface.withValues(alpha: 0.3),
          borderRadius: AppDesignSystem.borderRadii8,
          border: Border.all(
            color: borderColor,
            width: AppDesignSystem.glassBorderWidth,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.space12),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          style: AppDesignSystem.bodyLarge.copyWith(
            color: AppDesignSystem.textPrimary,
          ),
          decoration: InputDecoration(
            labelText: widget.labelText,
            labelStyle: AppDesignSystem.body.copyWith(
              color: hasFocus
                  ? AppDesignSystem.brandNeonCyan
                  : AppDesignSystem.textMuted,
            ),
            border: InputBorder.none,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              vertical: AppDesignSystem.space12,
            ),
          ),
          validator: widget.validator,
        ),
      ),
    );
  }
}

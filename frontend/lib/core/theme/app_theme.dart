import 'package:flutter/material.dart';

import 'design_system.dart';

/// Application-wide [ThemeData] fully integrated with the CivicTwin AI design
/// system. Ensures that any fallback Material widget inherits the premium dark
/// obsidian aesthetic rather than generic Flutter defaults.
abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Plus Jakarta Sans',
    scaffoldBackgroundColor: AppDesignSystem.brandObsidianBg,
    colorScheme: const ColorScheme.dark(
      primary: AppDesignSystem.brandNeonCyan,
      onPrimary: AppDesignSystem.textOnNeon,
      secondary: AppDesignSystem.brandDeepCyan,
      surface: AppDesignSystem.brandMetallicSurface,
      onSurface: AppDesignSystem.textPrimary,
      error: AppDesignSystem.semanticError,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppDesignSystem.brandObsidianBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(
        color: AppDesignSystem.textSecondary,
        size: 20,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppDesignSystem.brandBorderTranslucent,
      thickness: 1,
      space: 1,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppDesignSystem.brandMetallicSurface,
        borderRadius: AppDesignSystem.borderRadii8,
        border: Border.all(
          color: AppDesignSystem.brandBorderTranslucent,
        ),
      ),
      textStyle: AppDesignSystem.bodySmall.copyWith(
        color: AppDesignSystem.textSecondary,
      ),
      waitDuration: AppDesignSystem.durationMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppDesignSystem.brandMetallicSurface,
      contentTextStyle: AppDesignSystem.body.copyWith(
        color: AppDesignSystem.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppDesignSystem.borderRadii8,
        side: const BorderSide(
          color: AppDesignSystem.brandBorderTranslucent,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppDesignSystem.brandNeonCyan;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppDesignSystem.textOnNeon),
      side: const BorderSide(
        color: AppDesignSystem.textMuted,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppDesignSystem.borderRadii4,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(
        AppDesignSystem.brandBorderTranslucent,
      ),
      radius: const Radius.circular(AppDesignSystem.radius4),
      thickness: WidgetStateProperty.all(4),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppDesignSystem.brandNeonCyan,
      selectionColor: AppDesignSystem.brandNeonCyanDim,
      selectionHandleColor: AppDesignSystem.brandNeonCyan,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
    ),
  );
}

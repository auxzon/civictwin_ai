import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Application-wide [ThemeData]. Deliberately minimal: only the tokens
/// fixed by DECISIONS.md are applied here. Screen-level visual polish is
/// out of scope until explicitly requested.
abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.mapBackground,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.neonAccent,
      surface: AppColors.mapBackground,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.mapBackground,
      elevation: 0,
    ),
  );
}

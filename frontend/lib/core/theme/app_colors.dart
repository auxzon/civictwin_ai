import 'package:flutter/material.dart';

/// Colors and design tokens fixed by EDD V2 Document 05
/// ("Visual Specifications Core Directives") and DECISIONS.md.
///
/// These values are not stylistic choices — they are the frozen
/// architecture spec. Do not adjust without an approved change to
/// DECISIONS.md.
abstract final class AppColors {
  /// Grayscale map canvas background.
  static const Color mapBackground = Color(0xFF111111);

  /// Primary arterial road color on the map skin.
  static const Color mapArterialRoad = Color(0xFF263238);

  /// Environmental element suppression (water, parks, transit).
  static const Color mapEnvironmentSuppressed = Color(0xFF000000);

  /// Glassmorphic panel backing: Colors.black.withOpacity(0.65).
  static const Color glassPanelBackground = Color(0xA6000000);

  /// Glassmorphic panel border color: #00E5FF at 0.2 opacity.
  static const Color glassPanelBorder = Color(0x3300E5FF);

  /// Accent color used for neon ward-boundary highlighting.
  static const Color neonAccent = Color(0xFF00E5FF);
}

/// Glassmorphic panel dimension constants (Document 05).
abstract final class GlassPanelSpec {
  static const double blurSigma = 10.0;
  static const double borderWidth = 1.5;
}

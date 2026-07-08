import 'package:flutter/material.dart';

/// # CivicTwin AI Design Philosophy
///
/// 1. **Premium & Enterprise-Grade:** Designed to feel like a high-end spatial AI
///    dashboard tailored for governments and municipal planners. Uses a unified dark
///    aesthetic with glassmorphic accents instead of generic consumer layouts.
/// 2. **Data & Spatial-First:** The map is the canvas. UI elements float as
///    non-intrusive overlays to prioritize spatial content. High information density is
///    balanced with meticulous hierarchy.
/// 3. **Calm & Minimal:** An obsidian-based palette reduces visual fatigue during
///    extended operational monitoring. Neon highlights are reserved for critical data points,
///    actions, and active systems.
/// 4. **Professional & Consistent:** Absolutely no ad-hoc inline values. All dimensions,
///    colors, text styles, and motion parameters are derived directly from this design system.
abstract final class AppDesignSystem {
  // ===========================================================================
  // Colors
  // ===========================================================================
  static const Color brandObsidianBg = Color(0xFF0B0C10);
  static const Color brandMetallicSurface = Color(0xFF1F2833);
  static const Color brandNeonCyan = Color(0xFF00E5FF);
  static const Color brandNeonCyanDim = Color(0x3300E5FF);
  static const Color brandDeepCyan = Color(0xFF00A8CC);
  static const Color brandObsidianOverlay = Color(0xA6000000); // 65% opacity black
  static const Color brandBorderTranslucent = Color(0x26FFFFFF); // 15% opacity white

  // Semantic Colors
  static const Color semanticSuccess = Color(0xFF00E676);
  static const Color semanticError = Color(0xFFFF1744);
  static const Color semanticWarning = Color(0xFFFFD600);
  static const Color semanticInfo = Color(0xFF29B6F6);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC1C7D0);
  static const Color textMuted = Color(0xFF7A869A);
  static const Color textOnNeon = Color(0xFF0B0C10);

  // Map Elements
  static const Color mapMaskOverlay = Color(0xFF111111);
  static const Color mapArterialRoads = Color(0xFF263238);

  // ===========================================================================
  // Spacing (Logical pixels)
  // ===========================================================================
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // ===========================================================================
  // Spacing Widgets (SizedBox helpers)
  // ===========================================================================
  static const Widget height4 = SizedBox(height: space4);
  static const Widget height8 = SizedBox(height: space8);
  static const Widget height12 = SizedBox(height: space12);
  static const Widget height16 = SizedBox(height: space16);
  static const Widget height20 = SizedBox(height: space20);
  static const Widget height24 = SizedBox(height: space24);
  static const Widget height32 = SizedBox(height: space32);
  static const Widget height48 = SizedBox(height: space48);
  static const Widget height64 = SizedBox(height: space64);

  static const Widget width4 = SizedBox(width: space4);
  static const Widget width8 = SizedBox(width: space8);
  static const Widget width12 = SizedBox(width: space12);
  static const Widget width16 = SizedBox(width: space16);
  static const Widget width20 = SizedBox(width: space20);
  static const Widget width24 = SizedBox(width: space24);
  static const Widget width32 = SizedBox(width: space32);
  static const Widget width48 = SizedBox(width: space48);
  static const Widget width64 = SizedBox(width: space64);

  // ===========================================================================
  // Border Radius
  // ===========================================================================
  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius24 = 24.0;

  static const BorderRadius borderRadii4 = BorderRadius.all(Radius.circular(radius4));
  static const BorderRadius borderRadii8 = BorderRadius.all(Radius.circular(radius8));
  static const BorderRadius borderRadii12 = BorderRadius.all(Radius.circular(radius12));
  static const BorderRadius borderRadii16 = BorderRadius.all(Radius.circular(radius16));
  static const BorderRadius borderRadii24 = BorderRadius.all(Radius.circular(radius24));

  // ===========================================================================
  // Elevation / Shadows
  // ===========================================================================
  static const List<BoxShadow> shadowNeonGlow = [
    BoxShadow(
      color: Color(0x3300E5FF),
      blurRadius: 12.0,
      spreadRadius: 2.0,
    ),
  ];

  static const List<BoxShadow> shadowPanel = [
    BoxShadow(
      color: Color(0x80000000),
      blurRadius: 16.0,
      offset: Offset(0, 8),
    ),
  ];

  /// Lightweight shadow for floating overlays that should feel unobtrusive.
  static const List<BoxShadow> shadowSubtle = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 8.0,
      offset: Offset(0, 4),
    ),
  ];

  // ===========================================================================
  // Motion / Animation
  // ===========================================================================
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  static const Curve curveStandard = Curves.easeInOutCubic;
  static const Curve curveDecelerate = Curves.easeOutCubic;
  static const Curve curveAccent = Curves.elasticOut;

  // ===========================================================================
  // Glassmorphism
  // ===========================================================================
  static const double glassBlurSigma = 12.0;
  static const double glassBorderWidth = 1.5;

  // ===========================================================================
  // Typography Scale (Outfit-inspired modern tech scale)
  // ===========================================================================
  static const TextStyle display = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: ['Geist', 'Inter', 'system-ui', 'sans-serif'],
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: ['Geist', 'Inter', 'system-ui', 'sans-serif'],
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.25,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: ['Geist', 'Inter', 'system-ui', 'sans-serif'],
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: ['Geist', 'Inter', 'system-ui', 'sans-serif'],
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.1,
  );

  static const TextStyle title = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: ['Geist', 'Inter', 'system-ui', 'sans-serif'],
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: ['Geist', 'Inter', 'system-ui', 'sans-serif'],
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: 0.25,
    height: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: ['Geist', 'Inter', 'system-ui', 'sans-serif'],
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: 0.25,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: ['Geist', 'Inter', 'system-ui', 'sans-serif'],
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textMuted,
    letterSpacing: 0.4,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: ['Geist', 'Inter', 'system-ui', 'sans-serif'],
    fontSize: 11,
    fontWeight: FontWeight.w300,
    color: textMuted,
    letterSpacing: 0.5,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: ['Geist', 'Inter', 'system-ui', 'sans-serif'],
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: brandNeonCyan,
    letterSpacing: 1.5,
  );

  // ===========================================================================
  // Component Sizing
  // ===========================================================================
  static const double iconSizeSmall = 14.0;
  static const double iconSizeMedium = 18.0;
  static const double iconSizeLarge = 24.0;
  static const double buttonHeight = 48.0;
  static const double topNavHeight = 56.0;
  static const double sidebarWidth = 280.0;
  static const double historyPanelWidth = 340.0;
}

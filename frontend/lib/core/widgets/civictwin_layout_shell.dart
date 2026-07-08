import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// **CivicTwinAppShell**
///
/// The top-level layout wrapper for the platform.
/// Handles spatial layout split boundaries between the primary map canvas
/// and overlay interfaces (top bars, bottom overlays, side panels).
class CivicTwinAppShell extends StatelessWidget {
  const CivicTwinAppShell({
    super.key,
    required this.body,
    this.topBar,
    this.sidePanel,
    this.bottomPanel,
    this.endDrawer,
  });

  final Widget body;
  final PreferredSizeWidget? topBar;
  final Widget? sidePanel;
  final Widget? bottomPanel;
  final Widget? endDrawer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.brandObsidianBg,
      appBar: topBar,
      endDrawer: endDrawer,
      body: Stack(
        children: [
          // The base workspace layer (e.g. Map ContentArea)
          Positioned.fill(child: body),

          // Left side dashboard control panel (optional overlay)
          if (sidePanel != null)
            Positioned(
              left: AppDesignSystem.space16,
              top: AppDesignSystem.space16,
              bottom: AppDesignSystem.space16,
              child: sidePanel!,
            ),

          // Bottom recommended cards / timeline overlay (optional overlay)
          if (bottomPanel != null)
            Positioned(
              left: AppDesignSystem.space16,
              right: AppDesignSystem.space16,
              bottom: AppDesignSystem.space16,
              child: bottomPanel!,
            ),
        ],
      ),
    );
  }
}

/// **CivicTwinTopBar**
///
/// Reusable header/navigation bar structured using design system colors and text tokens.
class CivicTwinTopBar extends StatelessWidget implements PreferredSizeWidget {
  const CivicTwinTopBar({
    super.key,
    required this.title,
    this.actions,
  });

  final Widget title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppDesignSystem.brandObsidianBg,
      elevation: 0.0,
      title: title,
      titleTextStyle: AppDesignSystem.heading2.copyWith(
        color: AppDesignSystem.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppDesignSystem.textPrimary),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: AppDesignSystem.brandBorderTranslucent,
          height: 1.0,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60.0);
}

/// **CivicTwinSidePanel**
///
/// Reusable left/right panel layout component.
class CivicTwinSidePanel extends StatelessWidget {
  const CivicTwinSidePanel({
    super.key,
    required this.child,
    this.width = 360.0,
  });

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: child,
    );
  }
}

/// **CivicTwinBottomPanel**
///
/// Reusable bottom panel layout wrapper.
class CivicTwinBottomPanel extends StatelessWidget {
  const CivicTwinBottomPanel({
    super.key,
    required this.child,
    this.height = 240.0,
  });

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: child,
    );
  }
}

/// **CivicTwinFloatingPanel**
///
/// Reusable floating panel for generic control points or legend layers on the map canvas.
class CivicTwinFloatingPanel extends StatelessWidget {
  const CivicTwinFloatingPanel({
    super.key,
    required this.child,
    this.width,
    this.height,
  });

  final Widget child;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }
}

/// **CivicTwinContentArea**
///
/// Unified container for maps or charts.
class CivicTwinContentArea extends StatelessWidget {
  const CivicTwinContentArea({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppDesignSystem.brandObsidianBg,
      child: child,
    );
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/design_system.dart';
import '../../core/widgets/civictwin_spinner.dart';
import '../../core/widgets/civictwin_text_field.dart';
import 'auth_provider.dart';

/// Consistent premium typography font-stack definition.
TextStyle _premiumTextStyle({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
  TextDecoration? decoration,
}) {
  return TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: const ['Geist', 'Inter', 'system-ui', 'sans-serif'],
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    decoration: decoration,
  );
}

/// **SignInScreen**
///
/// Completely redesigned landing/auth experience built from first principles
/// to match Stripe, OpenAI, and Linear aesthetic.
/// Eliminates card-containers to feel open, spacious, and cinematic.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> with TickerProviderStateMixin {
  late final AnimationController _bgAnimationController;
  late final AnimationController _demoLoadingController;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showEmailForm = false;
  bool _isDemoLoading = false;
  bool _isFormSubmitting = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String _loadingStageText = 'Initializing CivicTwin...';

  @override
  void initState() {
    super.initState();
    // Infinite slow loop for the spatial background animation
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    // 3-second demo loading sequence animation controller
    _demoLoadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _demoLoadingController.addListener(_onDemoLoadingTick);
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _demoLoadingController.removeListener(_onDemoLoadingTick);
    _demoLoadingController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onDemoLoadingTick() {
    final val = _demoLoadingController.value;
    setState(() {
      if (val < 0.15) {
        _loadingStageText = 'Initializing CivicTwin...';
      } else if (val < 0.30) {
        _loadingStageText = 'Loading GIS Layers...';
      } else if (val < 0.45) {
        _loadingStageText = 'Reading Telemetry Signals...';
      } else if (val < 0.60) {
        _loadingStageText = 'Analyzing Spatial Data...';
      } else if (val < 0.75) {
        _loadingStageText = 'Generating AI Mission...';
      } else if (val < 0.90) {
        _loadingStageText = 'Optimizing Budget Allocation...';
      } else {
        _loadingStageText = 'Preparing Dashboard Workspace...';
      }
    });
  }

  Future<void> _startDemoLogin() async {
    setState(() {
      _isDemoLoading = true;
      _errorMessage = null;
    });

    _demoLoadingController.reset();
    unawaited(_demoLoadingController.forward());

    // Wait until the loading sequence is 80% complete (2.4s) before executing sign in
    await Future<void>.delayed(const Duration(milliseconds: 2400));

    try {
      await ref.read(authServiceProvider).signInWithEmailAndPassword(
            email: 'test@civictwin.dev',
            password: 'TestPassword123!',
          );
    } catch (exc) {
      if (mounted) {
        setState(() {
          _isDemoLoading = false;
          _errorMessage = 'Demo sign-in failed. Please verify connection.';
        });
        _demoLoadingController.reset();
      }
    }
  }

  Future<void> _submitEmailPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _isFormSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authServiceProvider).signInWithEmailAndPassword(
            email: email,
            password: password,
          );
    } catch (exc) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Authentication failed. Please check credentials.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isFormSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070809),
      body: Stack(
        children: [
          // ─── BACKGROUND: Cinematic Spatial Universe ───
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CivicTwinUniversePainter(
                    animationValue: _bgAnimationController.value,
                  ),
                );
              },
            ),
          ),

          // ─── MAIN CENTER WORKSPACE ───
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.space48,
                vertical: AppDesignSystem.space48,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Brand Header
                    const _BrandHeader(),
                    const SizedBox(height: 72), // Generous spacing

                    // Spacious Floating actions/forms (No card container)
                    AnimatedSize(
                      duration: AppDesignSystem.durationMedium,
                      curve: AppDesignSystem.curveStandard,
                      child: _isDemoLoading
                          ? _buildLoadingState()
                          : _showEmailForm
                              ? _buildEmailLoginForm()
                              : _buildDefaultActions(),
                    ),

                    if (_errorMessage != null && !_isDemoLoading) ...[
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDesignSystem.space16,
                          vertical: AppDesignSystem.space12,
                        ),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.semanticError.withValues(alpha: 0.08),
                          borderRadius: AppDesignSystem.borderRadii8,
                          border: Border.all(
                            color: AppDesignSystem.semanticError.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: _premiumTextStyle(
                            fontSize: 12,
                            color: AppDesignSystem.semanticError,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'Continue to pre-authenticated workspace demo',
          button: true,
          child: _PremiumLoginButton(
            onPressed: _startDemoLogin,
            label: 'Continue Demo',
            isPrimary: true,
            icon: Icons.play_arrow_outlined,
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          label: 'Show credentials login form',
          button: true,
          child: _PremiumLoginButton(
            onPressed: () {
              setState(() {
                _showEmailForm = true;
                _errorMessage = null;
              });
            },
            label: 'Organization Sign In',
            isPrimary: false,
            icon: Icons.business_outlined,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Live Demonstration  •  Mumbai North Constituency',
          style: _premiumTextStyle(
            color: AppDesignSystem.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'ORGANIZATION SIGN IN',
            style: _premiumTextStyle(
              color: AppDesignSystem.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        CivicTwinTextField(
          controller: _emailController,
          labelText: 'Corporate Email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined, size: 16),
        ),
        const SizedBox(height: 16),
        CivicTwinTextField(
          controller: _passwordController,
          labelText: 'Password',
          obscureText: _obscurePassword,
          prefixIcon: const Icon(Icons.lock_outline, size: 16),
          suffixIcon: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 16,
                color: AppDesignSystem.textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _PremiumLoginButton(
          onPressed: _isFormSubmitting ? null : _submitEmailPassword,
          label: 'Sign In',
          isLoading: _isFormSubmitting,
          isPrimary: true,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isFormSubmitting
              ? null
              : () {
                  setState(() {
                    _showEmailForm = false;
                    _errorMessage = null;
                  });
                },
          style: TextButton.styleFrom(
            foregroundColor: AppDesignSystem.textMuted,
            padding: const EdgeInsets.symmetric(vertical: AppDesignSystem.space8),
            shape: RoundedRectangleBorder(
              borderRadius: AppDesignSystem.borderRadii8,
            ),
          ),
          child: Text(
            'Back to Demo',
            style: _premiumTextStyle(
              fontSize: 13,
              color: AppDesignSystem.textSecondary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: CivicTwinSpinner(size: 28),
        ),
        const SizedBox(height: 28),
        Text(
          _loadingStageText,
          style: _premiumTextStyle(
            fontSize: 13,
            color: AppDesignSystem.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _demoLoadingController,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: AppDesignSystem.borderRadii4,
              child: LinearProgressIndicator(
                value: _demoLoadingController.value,
                backgroundColor: AppDesignSystem.brandBorderTranslucent,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppDesignSystem.brandNeonCyan,
                ),
                minHeight: 3,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Bespoke geometric monogram logo and typography presentation with smooth entrance animations.
class _BrandHeader extends StatefulWidget {
  const _BrandHeader();

  @override
  State<_BrandHeader> createState() => _BrandHeaderState();
}

class _BrandHeaderState extends State<_BrandHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom Monogram Logo with soft glow
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF070809),
              border: Border.all(
                color: AppDesignSystem.textPrimary.withValues(alpha: 0.12),
                width: 1.5,
              ),
              borderRadius: AppDesignSystem.borderRadii16,
              boxShadow: [
                BoxShadow(
                  color: AppDesignSystem.brandNeonCyan.withValues(alpha: 0.04),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CustomPaint(
                  painter: _GeometricMonogramPainter(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 1. Brand Label
          Text(
            'CIVICTWIN AI',
            style: _premiumTextStyle(
              color: AppDesignSystem.textSecondary.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 4.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // 2. Hero Title
          Text(
            'The Digital Twin\nfor City Decisions',
            style: _premiumTextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // 3. Supporting Sentence
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Transforming civic data into live spatial intelligence.',
              style: _premiumTextStyle(
                color: AppDesignSystem.textSecondary,
                fontWeight: FontWeight.w400,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom monogram painter drawing interlocking "C" and "T" geometric paths.
class _GeometricMonogramPainter extends CustomPainter {
  const _GeometricMonogramPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintOuter = Paint()
      ..color = AppDesignSystem.textPrimary.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintInner = Paint()
      ..color = AppDesignSystem.brandNeonCyan.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw the "C" outer ring arc
    final pathC = Path();
    pathC.addArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      0.8 * math.pi,
      1.4 * math.pi,
    );
    canvas.drawPath(pathC, paintOuter);

    // Draw the intersecting geometric "T"
    final pathT = Path();
    pathT.moveTo(center.dx - 6, center.dy - 6);
    pathT.lineTo(center.dx + 6, center.dy - 6);
    pathT.moveTo(center.dx, center.dy - 6);
    pathT.lineTo(center.dx, center.dy + 8);
    canvas.drawPath(pathT, paintInner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bespoke buttons with refined hover, depth, scale, and custom shadow configurations.
class _PremiumLoginButton extends StatefulWidget {
  const _PremiumLoginButton({
    required this.onPressed,
    required this.label,
    required this.isPrimary,
    this.isLoading = false,
    this.icon,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool isPrimary;
  final bool isLoading;
  final IconData? icon;

  @override
  State<_PremiumLoginButton> createState() => _PremiumLoginButtonState();
}

class _PremiumLoginButtonState extends State<_PremiumLoginButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 24,
          ),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? (_isHovered ? const Color(0xFF0F1216) : const Color(0xFF0D0F12))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isPrimary
                  ? AppDesignSystem.brandNeonCyan.withValues(alpha: _isHovered ? 0.8 : 0.3)
                  : (_isHovered
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.2)),
              width: 1.2,
            ),
            boxShadow: widget.isPrimary && _isHovered
                ? [
                    BoxShadow(
                      color: AppDesignSystem.brandNeonCyan.withValues(alpha: 0.15),
                      blurRadius: 15,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppDesignSystem.brandNeonCyan),
                    backgroundColor: AppDesignSystem.brandNeonCyanDim,
                  ),
                ),
                const SizedBox(width: 12),
              ] else if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isPrimary ? AppDesignSystem.brandNeonCyan : Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: _premiumTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Breathtaking custom painter drawing radial lighting, GIS waves, node grid, and floating particles.
class _CivicTwinUniversePainter extends CustomPainter {
  _CivicTwinUniversePainter({required this.animationValue});

  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark Obsidian Base Background
    final bgPaint = Paint()..color = const Color(0xFF070809);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Soft Radial Lighting
    final center = Offset(size.width / 2, size.height / 2);
    final radialPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.04),
          const Color(0xFF070809).withValues(alpha: 0.0),
        ],
        radius: 0.7,
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.7));
    canvas.drawCircle(center, size.width * 0.7, radialPaint);

    // 3. GIS Contour Lines
    final contourPaint = Paint()
      ..color = const Color(0xFF1F2B3E).withValues(alpha: 0.15)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final path = Path();
      final yOffset = size.height * (0.3 + i * 0.15);
      path.moveTo(0, yOffset);

      // Draw smooth wave using quadratic bezier curves
      final controlX1 = size.width * 0.25;
      final controlY1 = yOffset + 30 * math.sin(animationValue * 2 * math.pi + i);
      final controlX2 = size.width * 0.75;
      final controlY2 = yOffset - 30 * math.cos(animationValue * 2 * math.pi + i);

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, size.width, yOffset);
      canvas.drawPath(path, contourPaint);
    }

    // 4. Interconnected Nodes / Spatial Grid
    final nodeLinePaint = Paint()
      ..color = const Color(0xFF1F2B3E).withValues(alpha: 0.12)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    final nodeCorePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final cols = 6;
    final rows = 5;
    final cellWidth = size.width / (cols - 1);
    final cellHeight = size.height / (rows - 1);

    final points = <Offset>[];
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        final angle = (animationValue * 2 * math.pi) + (c * 0.7) + (r * 0.6);
        final x = c * cellWidth + 15.0 * math.sin(angle);
        final y = r * cellHeight + 15.0 * math.cos(angle);
        points.add(Offset(x, y));
      }
    }

    // Connect node lines
    for (int i = 0; i < points.length; i++) {
      if ((i + 1) % rows != 0 && (i + 1) < points.length) {
        canvas.drawLine(points[i], points[i + 1], nodeLinePaint);
      }
      if (i + rows < points.length) {
        canvas.drawLine(points[i], points[i + rows], nodeLinePaint);
      }
    }

    // Draw node circles
    for (final pt in points) {
      canvas.drawCircle(pt, 5.0, nodePaint);
      canvas.drawCircle(pt, 1.5, nodeCorePaint);
    }

    // 5. Floating Particles
    final particlePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 15; i++) {
      // Determine vertical particle position moving slowly upwards
      final startX = size.width * ((i * 7) % 10 / 10.0);
      final yProgress = (animationValue + (i * 0.13)) % 1.0;
      final startY = size.height * (1.0 - yProgress);

      final pSize = 1.0 + (i % 3) * 0.6;
      final alpha = (math.sin(yProgress * math.pi) * 0.15).clamp(0.0, 1.0);
      particlePaint.color = const Color(0xFF00E5FF).withValues(alpha: alpha);

      canvas.drawCircle(Offset(startX, startY), pSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CivicTwinUniversePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

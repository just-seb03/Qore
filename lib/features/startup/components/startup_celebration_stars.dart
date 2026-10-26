/// File: startup_celebration_stars.dart
/// Description: Aesthetic particle animation component rendering theme-colored celebration stars
/// shooting upward from the progress bar upon completion of the initial media indexing sequence.
/// Strictly uses the active theme's palette colors with zero rainbow effects.
///
/// Components / Classes / Functions:
/// - StartupCelebrationStars: Animated celebration widget.
/// - _CelebrationStarPainter: CustomPainter rendering 4-pointed sparkle stars.
library;

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/contracts/app_theme_palette.dart';
import 'package:project_anima/core/theme/controllers/theme_controller.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Single particle definition for a celebration star.
class _CelebrationStar {
  final double startX;
  final double endX;
  final double startY;
  final double endY;
  final double size;
  final Color color;
  final double rotation;
  final double delay;

  const _CelebrationStar({
    required this.startX,
    required this.endX,
    required this.startY,
    required this.endY,
    required this.size,
    required this.color,
    required this.rotation,
    required this.delay,
  });
}

/// Upward shooting celebration stars burst mounted when media indexing concludes on first launch.
class StartupCelebrationStars extends StatefulWidget {
  /// Callback triggered once the celebration sequence finishes.
  final VoidCallback? onComplete;

  /// Optional theme palette override. Defaults to [ThemeController.instance.currentPalette].
  final AppThemePalette? palette;

  const StartupCelebrationStars({
    super.key,
    this.onComplete,
    this.palette,
  });

  @override
  State<StartupCelebrationStars> createState() => _StartupCelebrationStarsState();
}

class _StartupCelebrationStarsState extends State<StartupCelebrationStars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_CelebrationStar> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _stars = _generateThemeStars();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_CelebrationStar> _generateThemeStars() {
    final palette = widget.palette ?? ThemeController.instance.currentPalette;

    // Palette colors strictly curated from active theme — no rainbow hues
    final List<Color> themePaletteColors = [
      ...palette.constituentColors,
      palette.accent,
      palette.onSurfaceVariant,
      AppColors.futuristicWhite,
    ];

    final random = math.Random(42); // Deterministic seed for reproducible aesthetic distribution
    const int count = 30;

    final List<_CelebrationStar> stars = [];
    for (int i = 0; i < count; i++) {
      // Bar width is 260px, so spawn points range along x [-125, +125]
      final double startX = (random.nextDouble() - 0.5) * 250.0;
      final double spreadX = (random.nextDouble() - 0.5) * 70.0;
      final double endX = startX + spreadX;

      // Start at bar center (0,0), shoot upward by 70px to 230px
      final double startY = 0.0;
      final double endY = -70.0 - (random.nextDouble() * 160.0);

      final double size = 6.0 + (random.nextDouble() * 11.0);
      final Color color = themePaletteColors[i % themePaletteColors.length];
      final double rotation = (random.nextDouble() - 0.5) * 3.5;
      final double delay = random.nextDouble() * 0.28;

      stars.add(
        _CelebrationStar(
          startX: startX,
          endX: endX,
          startY: startY,
          endY: endY,
          size: size,
          color: color,
          rotation: rotation,
          delay: delay,
        ),
      );
    }

    return stars;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(260.0, 36.0),
          painter: _CelebrationStarPainter(
            stars: _stars,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

/// CustomPainter rendering 4-pointed sparkle stars along their upward physics path.
class _CelebrationStarPainter extends CustomPainter {
  final List<_CelebrationStar> stars;
  final double progress;

  _CelebrationStarPainter({
    required this.stars,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double originX = size.width / 2;
    final double originY = size.height / 2;

    for (final star in stars) {
      if (progress < star.delay) continue;

      final double localProgress =
          ((progress - star.delay) / (1.0 - star.delay)).clamp(0.0, 1.0);
      if (localProgress >= 1.0) continue;

      // Smooth deceleration curve for fireworks/burst effect
      final double curve = Curves.easeOutCubic.transform(localProgress);

      final double x = originX + lerpDouble(star.startX, star.endX, curve)!;
      final double y = originY + lerpDouble(star.startY, star.endY, curve)!;

      // Opacity envelope: quick fade-in, long graceful fade-out
      double opacity;
      if (localProgress < 0.20) {
        opacity = (localProgress / 0.20).clamp(0.0, 1.0);
      } else if (localProgress > 0.55) {
        opacity = ((1.0 - localProgress) / 0.45).clamp(0.0, 1.0);
      } else {
        opacity = 1.0;
      }

      // Scale envelope: pop open quickly and gently shrink
      double scale;
      if (localProgress < 0.25) {
        scale = (localProgress / 0.25).clamp(0.0, 1.0);
      } else {
        scale = 1.0 - ((localProgress - 0.25) * 0.35);
      }

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(star.rotation * curve);
      canvas.scale(scale);

      final paint = Paint()
        ..color = star.color.withValues(alpha: opacity * star.color.a)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      // Draw 4-pointed sparkle star diamond
      final path = _createStarPath(star.size);
      canvas.drawPath(path, paint);

      canvas.restore();
    }
  }

  Path _createStarPath(double size) {
    final path = Path();
    final double half = size / 2;
    final double inner = size / 6;

    path.moveTo(0, -half);
    path.quadraticBezierTo(0, -inner, inner, 0);
    path.quadraticBezierTo(inner, 0, half, 0);
    path.quadraticBezierTo(inner, 0, 0, inner);
    path.quadraticBezierTo(0, inner, 0, half);
    path.quadraticBezierTo(0, inner, -inner, 0);
    path.quadraticBezierTo(-inner, 0, -half, 0);
    path.quadraticBezierTo(-inner, 0, 0, -inner);
    path.quadraticBezierTo(0, -inner, 0, -half);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _CelebrationStarPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

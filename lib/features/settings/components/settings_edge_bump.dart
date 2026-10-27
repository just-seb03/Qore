/// File: settings_edge_bump.dart
/// Description: Material 3 Expressive edge pull indicator ("montañita") that organically
/// protrudes from the screen's left edge as the user swipes right in Space, revealing
/// the theme-accented settings gear icon rotating in real-time.
///
/// Components / Classes / Functions:
/// - SettingsEdgeBump: Visual widget rendering the custom-painted Bezier arch and centered gear.
/// - _ExpressiveEdgeBumpPainter: Custom painter generating the organic Bezier curve.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Material 3 Expressive edge pull indicator that grows outward from the left border.
class SettingsEdgeBump extends StatelessWidget {
  /// Normalized drag progress clamped to [0.0, 1.0].
  final double progress;

  /// Vertical Y position of the user's touch.
  final double currentY;

  /// Whether the gesture has exceeded the threshold to trigger sheet opening.
  final bool isActivating;

  const SettingsEdgeBump({
    super.key,
    required this.progress,
    required this.currentY,
    this.isActivating = false,
  });

  @override
  Widget build(BuildContext context) {
    if (progress <= 0.001) {
      return const SizedBox.shrink();
    }

    final double curvedProgress = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));
    final double maxProtrusion = isActivating ? 74.0 : 66.0;
    final double width = curvedProgress * maxProtrusion;
    final double halfHeight = 44.0 + (curvedProgress * 26.0);

    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ExpressiveEdgeBumpPainter(
          progress: curvedProgress,
          currentY: currentY,
          width: width,
          halfHeight: halfHeight,
          accentColor: AppColors.accent,
        ),
        child: Stack(
          children: [
            Positioned(
              left: (width * 0.42) - 14.0,
              top: currentY - 14.0,
              child: Transform.rotate(
                angle: curvedProgress * math.pi * 0.6,
                child: Transform.scale(
                  scale: 0.6 + (curvedProgress * 0.45),
                  child: Icon(
                    Icons.settings_rounded,
                    size: 26.0,
                    color: AppColors.onAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpressiveEdgeBumpPainter extends CustomPainter {
  final double progress;
  final double currentY;
  final double width;
  final double halfHeight;
  final Color accentColor;

  _ExpressiveEdgeBumpPainter({
    required this.progress,
    required this.currentY,
    required this.width,
    required this.halfHeight,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (width <= 1.0) return;

    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    path.moveTo(0, currentY - halfHeight);

    // Expressive cubic curve to peak
    path.cubicTo(
      width * 0.15,
      currentY - (halfHeight * 0.65),
      width * 0.82,
      currentY - (halfHeight * 0.35),
      width,
      currentY,
    );

    // Expressive cubic curve from peak to bottom
    path.cubicTo(
      width * 0.82,
      currentY + (halfHeight * 0.35),
      width * 0.15,
      currentY + (halfHeight * 0.65),
      0,
      currentY + halfHeight,
    );

    path.close();

    // Subtle ambient glow
    canvas.drawShadow(
      path,
      accentColor.withValues(alpha: 0.35),
      6.0,
      false,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ExpressiveEdgeBumpPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.currentY != currentY ||
        oldDelegate.width != width ||
        oldDelegate.halfHeight != halfHeight ||
        oldDelegate.accentColor != accentColor;
  }
}

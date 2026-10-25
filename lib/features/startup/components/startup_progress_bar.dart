/// File: startup_progress_bar.dart
/// Description: Material Design 3 Expressive squiggly/wavy progress bar component
/// matching the signature expanded player aesthetic with sinusoidal active wave track,
/// continuous phase animation, and circular thumb.
///
/// Components / Classes / Functions:
/// - StartupProgressBar: Statefully animated M3 Expressive wavy progress bar.
/// - _StartupWavyPainter: CustomPainter rendering active wave, inactive rail, and thumb.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Material 3 Expressive wavy progress bar matching the player's expanded progress bar design.
class StartupProgressBar extends StatefulWidget {
  /// Normalized target progress [0.0 - 1.0].
  final double progress;

  /// Total bounded width for the progress bar. Defaults to 260.0.
  final double width;

  /// Total height containing wave amplitude and thumb. Defaults to 32.0.
  final double height;

  const StartupProgressBar({
    super.key,
    required this.progress,
    this.width = 260.0,
    this.height = 32.0,
  });

  @override
  State<StartupProgressBar> createState() => _StartupProgressBarState();
}

class _StartupProgressBarState extends State<StartupProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveAnimationController;

  @override
  void initState() {
    super.initState();
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clamped = widget.progress.clamp(0.0, 1.0);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: clamped),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, animatedProgress, _) {
          return AnimatedBuilder(
            animation: _waveAnimationController,
            builder: (context, _) {
              return CustomPaint(
                size: Size(widget.width, widget.height),
                painter: _StartupWavyPainter(
                  progress: animatedProgress,
                  phase: _waveAnimationController.value * 2 * math.pi,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Custom painter drawing the Material 3 Expressive squiggly wave and scrubber thumb.
class _StartupWavyPainter extends CustomPainter {
  final double progress;
  final double phase;

  static const double trackHeight = 3.5;
  static const double thumbRadius = 5.5;
  static const double wavelength = 22.0;
  static const double waveAmplitude = 3.0;

  const _StartupWavyPainter({
    required this.progress,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cy = size.height / 2;
    final double trackWidth = size.width;
    final double thumbX = (trackWidth * progress).clamp(0.0, trackWidth);

    // 1. Inactive straight track (from thumb to end)
    if (thumbX < trackWidth) {
      final inactivePaint = Paint()
        ..color = AppColors.surfaceContainerHighest
        ..strokeWidth = trackHeight
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(thumbX, cy),
        Offset(trackWidth, cy),
        inactivePaint,
      );
    }

    // 2. Active sinusoidal wavy track (from 0 to thumb)
    if (thumbX > 0) {
      final activePaint = Paint()
        ..color = AppColors.accent
        ..strokeWidth = trackHeight
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final Path wavePath = Path();
      wavePath.moveTo(0, cy);

      const double step = 1.0;
      final double activeLength = thumbX;

      for (double x = 0; x <= activeLength; x += step) {
        // Taper envelope so wave starts smoothly at 0 and connects cleanly to thumb
        double taper = 1.0;
        if (x < 10.0) {
          taper = x / 10.0;
        } else if (activeLength - x < 10.0) {
          taper = (activeLength - x) / 10.0;
        }

        final double y = cy +
            waveAmplitude *
                taper *
                math.sin((x / wavelength) * 2 * math.pi - phase);

        wavePath.lineTo(x, y);
      }

      wavePath.lineTo(thumbX, cy);
      canvas.drawPath(wavePath, activePaint);
    }

    // 3. Circular Scrubber Thumb
    final thumbShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    canvas.drawCircle(Offset(thumbX, cy + 1.0), thumbRadius, thumbShadowPaint);

    final thumbPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(thumbX, cy), thumbRadius, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant _StartupWavyPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.phase != phase;
  }
}

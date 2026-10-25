/// File: startup_progress_bar.dart
/// Description: Material Design 3 Expressive smooth animated progress bar
/// with hardware-accelerated tween interpolation and monochromatic track styling.
///
/// Components / Classes / Functions:
/// - StartupProgressBar: Smoothly animated progress indicator for startup stages.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Expressive progress bar showing startup sequence completion.
class StartupProgressBar extends StatelessWidget {
  /// Target progress fraction [0.0 - 1.0].
  final double progress;

  /// Width constraint of the progress bar track. Defaults to 260.0.
  final double width;

  /// Height thickness of the progress bar track. Defaults to 4.0.
  final double height;

  const StartupProgressBar({
    super.key,
    required this.progress,
    this.width = 260.0,
    this.height = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: clamped),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.onSurfaceVariant,
                      AppColors.futuristicWhite,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.25),
                      blurRadius: 4.0,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

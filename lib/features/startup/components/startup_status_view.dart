/// File: startup_status_view.dart
/// Description: Animated status view displaying stage description, track count,
/// and percentage completion using AnimatedSwitcher for fluid cross-fading.
///
/// Components / Classes / Functions:
/// - StartupStatusView: Animated label and percentage indicator.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/startup/models/startup_stage.dart';

/// Fluid cross-fading status label for the launch screen.
class StartupStatusView extends StatelessWidget {
  /// The active startup stage.
  final StartupStage stage;

  /// The active status text.
  final String statusText;

  /// Normalized progress [0.0 - 1.0].
  final double progress;

  /// Optional total count of discovered tracks.
  final int? totalSongs;

  const StartupStatusView({
    super.key,
    required this.stage,
    required this.statusText,
    required this.progress,
    this.totalSongs,
  });

  @override
  Widget build(BuildContext context) {
    final isReady = stage == StartupStage.ready;
    final int percent = (progress.clamp(0.0, 1.0) * 100).round();
    final stageLabel = stage.localizedLabel(context);
    final resolvedStatus = stageLabel.isNotEmpty ? stageLabel : statusText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Smooth cross-fading stage label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.15),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Row(
            key: ValueKey<String>(resolvedStatus),
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isReady) ...[
                Icon(
                  Icons.check_circle_rounded,
                  size: 14.0,
                  color: AppColors.futuristicWhite,
                ),
                const SizedBox(width: 6.0),
              ],
              Text(
                resolvedStatus,
                style: GoogleFonts.inconsolata(
                  fontSize: 13.5,
                  fontWeight: isReady ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 1.1,
                  color: isReady
                      ? AppColors.futuristicWhite
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8.0),
        // Subtle progress percentage
        Text(
          '$percent%',
          style: GoogleFonts.inconsolata(
            fontSize: 11.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

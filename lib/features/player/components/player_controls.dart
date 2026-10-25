/// File: player_controls.dart
/// Description: Sony Music-styled playback controls row featuring circular bordered
/// navigation buttons (Previous/Next), prominent center Play/Pause action, and
/// shuffle / repeat toggles with active state indicators.
///
/// Components / Classes / Functions:
/// - PlayerControls: Playback control actions row.
library;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Horizontal playback controls row for the maximized player.
class PlayerControls extends StatelessWidget {
  final PlaybackController controller;

  const PlayerControls({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.player;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isPlaying = controller.isPlaying;
        final isShuffle = controller.isShuffleEnabled;
        final loopMode = controller.loopMode;
        final isLoopActive = loopMode != LoopMode.off;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Shuffle Toggle
              IconButton(
                icon: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shuffle_rounded,
                      size: 24.0,
                      color: isShuffle
                          ? AppColors.futuristicWhite
                          : AppColors.onSurfaceDisabled,
                    ),
                    const SizedBox(height: 3.0),
                    Container(
                      width: 4.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isShuffle
                            ? AppColors.futuristicWhite
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
                tooltip: l10n.shuffleTooltip,
                onPressed: () => controller.toggleShuffle(),
              ),

              // 2. Previous Track (Circular Bordered Button)
              _CircularBorderButton(
                icon: Icons.skip_previous_rounded,
                onTap: () => controller.skipToPrevious(),
                tooltip: l10n.previousTooltip,
              ),

              // 3. Play / Pause (Prominent Center Button)
              _PlayPauseCenterButton(
                isPlaying: isPlaying,
                tooltip: isPlaying ? l10n.pauseTooltip : l10n.playTooltip,
                onTap: () => controller.togglePlayPause(),
              ),

              // 4. Next Track (Circular Bordered Button)
              _CircularBorderButton(
                icon: Icons.skip_next_rounded,
                onTap: () => controller.skipToNext(),
                tooltip: l10n.nextTooltip,
              ),

              // 5. Repeat / Loop Mode Toggle
              IconButton(
                icon: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      loopMode == LoopMode.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      size: 24.0,
                      color: isLoopActive
                          ? AppColors.futuristicWhite
                          : AppColors.onSurfaceDisabled,
                    ),
                    const SizedBox(height: 3.0),
                    Container(
                      width: 4.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLoopActive
                            ? AppColors.futuristicWhite
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
                tooltip: l10n.loopTooltip,
                onPressed: () => controller.toggleLoopMode(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Circular outlined button with subtle border for Previous / Next actions.
class _CircularBorderButton extends StatelessWidget {
  static const double _size = 54.0;

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _CircularBorderButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.outline,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(_size / 2),
            onTap: onTap,
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: Center(
              child: Icon(
                icon,
                size: 30.0,
                color: AppColors.futuristicWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Center prominent circular button for Play / Pause.
class _PlayPauseCenterButton extends StatelessWidget {
  static const double _size = 68.0;

  final bool isPlaying;
  final String tooltip;
  final VoidCallback onTap;

  const _PlayPauseCenterButton({
    required this.isPlaying,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.futuristicWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 14.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(_size / 2),
            onTap: onTap,
            splashColor: Colors.black.withValues(alpha: 0.2),
            highlightColor: Colors.black.withValues(alpha: 0.1),
            child: Center(
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 38.0,
                color: AppColors.background,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

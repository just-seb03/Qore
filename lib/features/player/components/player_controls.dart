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
                          ? AppColors.accent
                          : AppColors.onSurfaceDisabled,
                    ),
                    const SizedBox(height: 3.0),
                    Container(
                      width: 4.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        color: isShuffle
                            ? AppColors.accent
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
                tooltip: l10n.shuffleTooltip,
                onPressed: () => controller.toggleShuffle(),
              ),

              // 2. Previous Track (Metro Square Bordered Button)
              _MetroBorderButton(
                icon: Icons.skip_previous_rounded,
                onTap: () => controller.skipToPrevious(),
                tooltip: l10n.previousTooltip,
              ),

              // 3. Play / Pause (Prominent Metro Square Accent Tile)
              _PlayPauseCenterButton(
                isPlaying: isPlaying,
                tooltip: isPlaying ? l10n.pauseTooltip : l10n.playTooltip,
                onTap: () => controller.togglePlayPause(),
              ),

              // 4. Next Track (Metro Square Bordered Button)
              _MetroBorderButton(
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
                          ? AppColors.accent
                          : AppColors.onSurfaceDisabled,
                    ),
                    const SizedBox(height: 3.0),
                    Container(
                      width: 4.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        color: isLoopActive
                            ? AppColors.accent
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

/// Sharp square Metro outlined button for Previous / Next actions.
class _MetroBorderButton extends StatelessWidget {
  static const double _size = 52.0;

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _MetroBorderButton({
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
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: AppColors.outline,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.zero,
          child: InkWell(
            borderRadius: BorderRadius.zero,
            onTap: onTap,
            splashColor: AppColors.accent.withValues(alpha: 0.15),
            highlightColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.25),
            child: Center(
              child: Icon(
                icon,
                size: 30.0,
                color: AppColors.onBackground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Center prominent sharp square Metro tile for Play / Pause.
class _PlayPauseCenterButton extends StatelessWidget {
  static const double _size = 66.0;

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
          borderRadius: BorderRadius.zero,
          color: AppColors.accent,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.zero,
          child: InkWell(
            borderRadius: BorderRadius.zero,
            onTap: onTap,
            splashColor: Colors.black.withValues(alpha: 0.2),
            highlightColor: Colors.black.withValues(alpha: 0.1),
            child: Center(
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 38.0,
                color: AppColors.onAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

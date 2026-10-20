/// File: player_progress_bar.dart
/// Description: Isolated seek bar component for the maximized music player.
/// Efficiently subscribes to playback position and duration streams without
/// triggering parent widget rebuilds.
///
/// Components / Classes / Functions:
/// - PlayerProgressBar: Reactive scrubber bar with timestamps and drag-to-seek support.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Scrubber bar with elapsed and remaining timestamps.
class PlayerProgressBar extends StatefulWidget {
  final PlaybackController controller;

  const PlayerProgressBar({
    super.key,
    required this.controller,
  });

  @override
  State<PlayerProgressBar> createState() => _PlayerProgressBarState();
}

class _PlayerProgressBarState extends State<PlayerProgressBar> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  static final TextStyle _timestampStyle = GoogleFonts.inconsolata(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.5,
  );

  String _formatDuration(Duration duration) {
    final int totalSeconds = duration.inSeconds;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.controller.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? widget.controller.position;
        final duration = widget.controller.duration;

        final double totalMs = duration.inMilliseconds.toDouble();
        final double currentMs = _isDragging
            ? _dragValue
            : position.inMilliseconds.toDouble().clamp(0.0, totalMs > 0 ? totalMs : 0.0);

        final double sliderMax = totalMs > 0 ? totalMs : 1.0;
        final double sliderValue = currentMs.clamp(0.0, sliderMax);

        final currentPositionDuration = Duration(milliseconds: sliderValue.toInt());

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom Monochromatic Sony-styled Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6.0,
                  elevation: 2.0,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 14.0,
                ),
                activeTrackColor: AppColors.futuristicWhite,
                inactiveTrackColor: AppColors.surfaceContainerHighest,
                thumbColor: AppColors.futuristicWhite,
                overlayColor: Colors.white.withValues(alpha: 0.12),
                trackShape: const RectangularSliderTrackShape(),
              ),
              child: Slider(
                min: 0.0,
                max: sliderMax,
                value: sliderValue,
                onChangeStart: (val) {
                  setState(() {
                    _isDragging = true;
                    _dragValue = val;
                  });
                },
                onChanged: (val) {
                  setState(() {
                    _dragValue = val;
                  });
                },
                onChangeEnd: (val) {
                  widget.controller.seek(Duration(milliseconds: val.toInt()));
                  setState(() {
                    _isDragging = false;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(currentPositionDuration),
                    style: _timestampStyle,
                  ),
                  Text(
                    _formatDuration(duration),
                    style: _timestampStyle,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

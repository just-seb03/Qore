/// File: player_progress_bar.dart
/// Description: Material 3 Expressive squiggly/wavy seek bar component with animated
/// active wave track, touch & drag-to-seek interaction, and Inconsolata timestamps.
///
/// Components / Classes / Functions:
/// - PlayerProgressBar: Reactive M3 Expressive wavy progress bar.
/// - _WavyTrackPainter: CustomPainter drawing the animated sinusoidal wave and track.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Material 3 Expressive wavy/squiggly progress bar for the maximized player.
class PlayerProgressBar extends StatefulWidget {
  final PlaybackController controller;

  const PlayerProgressBar({
    super.key,
    required this.controller,
  });

  @override
  State<PlayerProgressBar> createState() => _PlayerProgressBarState();
}

class _PlayerProgressBarState extends State<PlayerProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveAnimationController;

  bool _isDragging = false;
  double _dragProgress = 0.0;

  static TextStyle get _timestampStyle => GoogleFonts.inconsolata(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.5,
  );

  @override
  void initState() {
    super.initState();
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    if (widget.controller.isPlaying) {
      _waveAnimationController.repeat();
    }

    widget.controller.addListener(_onPlaybackStateChanged);
  }

  void _onPlaybackStateChanged() {
    if (widget.controller.isPlaying) {
      if (!_waveAnimationController.isAnimating) {
        _waveAnimationController.repeat();
      }
    } else {
      if (_waveAnimationController.isAnimating) {
        _waveAnimationController.stop();
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPlaybackStateChanged);
    _waveAnimationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final int totalSeconds = duration.inSeconds;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _handleSeek(double progress, Duration totalDuration) {
    final int targetMs = (progress * totalDuration.inMilliseconds).round();
    widget.controller.seek(Duration(milliseconds: targetMs));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.controller.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? widget.controller.position;
        final duration = widget.controller.duration;

        final double totalMs = duration.inMilliseconds.toDouble();
        final double currentMs = position.inMilliseconds.toDouble();

        final double naturalProgress = totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;
        final double displayProgress = _isDragging ? _dragProgress : naturalProgress;

        final currentTimestamp = Duration(
          milliseconds: (displayProgress * totalMs).round(),
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Material 3 Expressive Wavy Seek Bar Area
              SizedBox(
                height: 38.0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    void updateFromLocalDx(double dx) {
                      final progress = (dx / width).clamp(0.0, 1.0);
                      setState(() {
                        _dragProgress = progress;
                      });
                    }

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (details) {
                        setState(() {
                          _isDragging = true;
                        });
                        updateFromLocalDx(details.localPosition.dx);
                      },
                      onHorizontalDragUpdate: (details) {
                        updateFromLocalDx(details.localPosition.dx);
                      },
                      onHorizontalDragEnd: (_) {
                        setState(() {
                          _isDragging = false;
                        });
                        _handleSeek(_dragProgress, duration);
                      },
                      onTapDown: (details) {
                        final progress = (details.localPosition.dx / width).clamp(0.0, 1.0);
                        setState(() {
                          _dragProgress = progress;
                        });
                        _handleSeek(progress, duration);
                      },
                      child: AnimatedBuilder(
                        animation: _waveAnimationController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: Size(width, 38.0),
                            painter: _WavyTrackPainter(
                              progress: displayProgress,
                              phase: _waveAnimationController.value * 2 * math.pi,
                              isPlaying: widget.controller.isPlaying,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // 2. Timestamps Row (Elapsed on Left, Total on Right)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(currentTimestamp),
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
          ),
        );
      },
    );
  }
}

/// Custom painter rendering the Material 3 Expressive squiggly/wavy active track,
/// clean straight inactive track, and circular thumb.
class _WavyTrackPainter extends CustomPainter {
  final double progress;
  final double phase;
  final bool isPlaying;

  static const double trackHeight = 3.5;
  static const double thumbRadius = 6.5;
  static const double wavelength = 24.0;
  static const double waveAmplitude = 3.5;

  static final Path _wavePath = Path();
  static final Paint _inactivePaint = Paint()
    ..strokeWidth = trackHeight
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final Paint _activePaint = Paint()
    ..strokeWidth = trackHeight
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  static final Paint _thumbShadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.4)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
  static final Paint _thumbPaint = Paint()..style = PaintingStyle.fill;

  const _WavyTrackPainter({
    required this.progress,
    required this.phase,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cy = size.height / 2;
    final double trackWidth = size.width;
    final double thumbX = (trackWidth * progress).clamp(0.0, trackWidth);

    // 1. Inactive straight track (from thumb to end)
    if (thumbX < trackWidth) {
      _inactivePaint.color = AppColors.surfaceContainerHighest;
      canvas.drawLine(
        Offset(thumbX, cy),
        Offset(trackWidth, cy),
        _inactivePaint,
      );
    }

    // 2. Active sinusoidal wavy track (from 0 to thumb)
    if (thumbX > 0) {
      _activePaint.color = AppColors.accent;

      _wavePath.reset();
      _wavePath.moveTo(0, cy);

      const double step = 1.0;
      final double activeLength = thumbX;
      final double currentAmplitude = isPlaying ? waveAmplitude : (waveAmplitude * 0.4);

      for (double x = 0; x <= activeLength; x += step) {
        // Taper envelope so wave starts smoothly at (0, cy) and connects cleanly to thumb
        double taper = 1.0;
        if (x < 12.0) {
          taper = x / 12.0;
        } else if (activeLength - x < 12.0) {
          taper = (activeLength - x) / 12.0;
        }

        final double y = cy +
            currentAmplitude *
                taper *
                math.sin((x / wavelength) * 2 * math.pi - phase);

        _wavePath.lineTo(x, y);
      }

      // Ensure path anchors firmly at thumbX
      _wavePath.lineTo(thumbX, cy);

      canvas.drawPath(_wavePath, _activePaint);
    }

    // 3. Circular Scrubber Thumb
    canvas.drawCircle(Offset(thumbX, cy + 1.0), thumbRadius, _thumbShadowPaint);

    _thumbPaint.color = AppColors.accent;
    canvas.drawCircle(Offset(thumbX, cy), thumbRadius, _thumbPaint);
  }

  @override
  bool shouldRepaint(covariant _WavyTrackPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.isPlaying != isPlaying;
  }
}

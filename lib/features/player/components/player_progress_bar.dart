/// File: player_progress_bar.dart
/// Description: Material 3 Expressive squiggly/wavy seek bar component with animated
/// active wave track, touch & drag-to-seek interaction, and Inconsolata timestamps.
///
/// Components / Classes / Functions:
/// - PlayerProgressBar: Reactive M3 Expressive wavy progress bar.
/// - _WavyTrackPainter: CustomPainter drawing the animated sinusoidal wave and track.
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/core/utils/duration_formatter.dart';

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
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<int> _elapsedSecondsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _totalDurationMsNotifier = ValueNotifier<int>(0);
  StreamSubscription<Duration>? _positionSub;

  bool _isDragging = false;
  double _dragProgress = 0.0;

  static TextStyle get _timestampStyle => AppFonts.segoe(
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

    _syncFromController(widget.controller.position);
    _syncWaveAnimation();

    widget.controller.addListener(_onPlaybackStateChanged);
    _positionSub = widget.controller.positionStream.listen(_onPositionUpdate);
  }

  @override
  void didUpdateWidget(covariant PlayerProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onPlaybackStateChanged);
      _positionSub?.cancel();
      widget.controller.addListener(_onPlaybackStateChanged);
      _positionSub = widget.controller.positionStream.listen(_onPositionUpdate);
      _syncFromController(widget.controller.position);
      _syncWaveAnimation();
    }
  }

  void _syncWaveAnimation() {
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

  void _syncFromController(Duration position) {
    final int totalMs = widget.controller.duration.inMilliseconds;
    _totalDurationMsNotifier.value = totalMs;

    if (_isDragging) return;
    final double progress =
        totalMs > 0 ? (position.inMilliseconds / totalMs).clamp(0.0, 1.0) : 0.0;
    _progressNotifier.value = progress;
    _elapsedSecondsNotifier.value = position.inSeconds;
  }

  void _onPositionUpdate(Duration position) {
    if (_isDragging) return;
    _syncFromController(position);
  }

  void _onPlaybackStateChanged() {
    _syncWaveAnimation();
    _syncFromController(widget.controller.position);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPlaybackStateChanged);
    _positionSub?.cancel();
    _waveAnimationController.dispose();
    _progressNotifier.dispose();
    _elapsedSecondsNotifier.dispose();
    _totalDurationMsNotifier.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) => formatDuration(duration);

  void _updateDragProgress(double progress) {
    _dragProgress = progress;
    _progressNotifier.value = progress;
    final int totalMs = _totalDurationMsNotifier.value;
    _elapsedSecondsNotifier.value = ((progress * totalMs) / 1000).round();
  }

  void _handleSeek(double progress, Duration totalDuration) {
    final int targetMs = (progress * totalDuration.inMilliseconds).round();
    widget.controller.seek(Duration(milliseconds: targetMs));
  }

  @override
  Widget build(BuildContext context) {
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

                double localProgress(double dx) =>
                    width > 0 ? (dx / width).clamp(0.0, 1.0) : 0.0;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) {
                    _isDragging = true;
                    _updateDragProgress(localProgress(details.localPosition.dx));
                  },
                  onHorizontalDragUpdate: (details) {
                    _updateDragProgress(localProgress(details.localPosition.dx));
                  },
                  onHorizontalDragEnd: (_) {
                    _isDragging = false;
                    _handleSeek(_dragProgress, widget.controller.duration);
                  },
                  onTapDown: (details) {
                    final progress = localProgress(details.localPosition.dx);
                    _updateDragProgress(progress);
                    _handleSeek(progress, widget.controller.duration);
                  },
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(width, 38.0),
                      painter: _WavyTrackPainter(
                        progressListenable: _progressNotifier,
                        waveAnimation: _waveAnimationController,
                        isPlayingProvider: () => widget.controller.isPlaying,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Timestamps Row (Elapsed updates at most 1 Hz, Total on track duration change)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: _elapsedSecondsNotifier,
                  builder: (context, seconds, _) {
                    return Text(
                      _formatDuration(Duration(seconds: seconds)),
                      style: _timestampStyle,
                    );
                  },
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _totalDurationMsNotifier,
                  builder: (context, totalMs, _) {
                    return Text(
                      _formatDuration(Duration(milliseconds: totalMs)),
                      style: _timestampStyle,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering the Material 3 Expressive squiggly/wavy active track,
/// clean straight inactive track, and circular thumb without widget rebuilds.
class _WavyTrackPainter extends CustomPainter {
  final ValueListenable<double> progressListenable;
  final Animation<double> waveAnimation;
  final bool Function() isPlayingProvider;

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

  _WavyTrackPainter({
    required this.progressListenable,
    required this.waveAnimation,
    required this.isPlayingProvider,
  }) : super(repaint: Listenable.merge([waveAnimation, progressListenable]));

  @override
  void paint(Canvas canvas, Size size) {
    final double progress = progressListenable.value;
    final double phase = waveAnimation.value * 2 * math.pi;
    final bool isPlaying = isPlayingProvider();

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
    return !identical(oldDelegate.progressListenable, progressListenable) ||
        !identical(oldDelegate.waveAnimation, waveAnimation);
  }
}

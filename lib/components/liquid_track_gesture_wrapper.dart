/// File: liquid_track_gesture_wrapper.dart
/// Description: Interactive fluid gesture wrapper for track rows.
/// Implements horizontal liquid wave filling from left to right with soft reddish fluid
/// when held down to toggle favorite status, and smoothly drains when released early.
///
/// Components / Classes / Functions:
/// - LiquidTrackGestureWrapper: StatefulWidget wrapping track rows with fluid fill gestures.
/// - _HorizontalLiquidFillPainter: CustomPainter rendering fluid sinusoidal waves along the X axis.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/models/song.dart';

/// Wraps any song track tile with interactive horizontal liquid fill gesture.
/// Holding fills (or drains) the tile with soft reddish water; completing toggles favorite status.
/// A short tap passes through to [onTap] for regular playback.
class LiquidTrackGestureWrapper extends StatefulWidget {
  final Song song;
  final Widget child;
  final VoidCallback? onTap;

  const LiquidTrackGestureWrapper({
    super.key,
    required this.song,
    required this.child,
    this.onTap,
  });

  @override
  State<LiquidTrackGestureWrapper> createState() => _LiquidTrackGestureWrapperState();
}

class _LiquidTrackGestureWrapperState extends State<LiquidTrackGestureWrapper>
    with TickerProviderStateMixin {
  late final AnimationController _fillController;
  late final AnimationController _waveController;
  late final AnimationController _flashController;

  bool _isHolding = false;
  bool _completed = false;
  bool _wasFavorited = false;
  DateTime? _pointerDownTime;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fillController.addListener(_handleFillTick);
  }

  void _handleFillTick() {
    if (!_isHolding || _completed) return;

    final targetReached = _wasFavorited
        ? _fillController.value <= 0.001
        : _fillController.value >= 0.999;

    if (targetReached) {
      _completed = true;
      _isHolding = false;
      _waveController.stop();

      HapticFeedback.mediumImpact();
      _flashController.forward(from: 0.0).then((_) {
        if (mounted) {
          _flashController.reset();
          _fillController.value = 0.0;
        }
      });

      FavoriteSongsDao.instance.toggleFavorite(widget.song);
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerDownTime = DateTime.now();
    _completed = false;
    _isHolding = true;

    _wasFavorited = FavoriteSongsDao.instance.isFavorite(widget.song.mediaStoreId);

    _waveController.repeat();

    if (_wasFavorited) {
      // Draining animation from 1.0 to 0.0
      _fillController.value = 1.0;
      _fillController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // Filling animation from 0.0 to 1.0
      _fillController.value = 0.0;
      _fillController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_completed) return;
    _isHolding = false;
    _waveController.stop();

    final downTime = _pointerDownTime;
    final elapsedMs = downTime != null
        ? DateTime.now().difference(downTime).inMilliseconds
        : 999;

    if (elapsedMs < 240) {
      // Quick tap -> Regular play trigger
      _fillController.value = 0.0;
      widget.onTap?.call();
    } else {
      // Smoothly drain/restore to resting state
      final restTarget = _wasFavorited ? 1.0 : 0.0;
      _fillController.animateTo(
        restTarget,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      ).then((_) {
        if (mounted && _wasFavorited) {
          _fillController.value = 0.0;
        }
      });
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_completed) return;
    _isHolding = false;
    _waveController.stop();

    final restTarget = _wasFavorited ? 1.0 : 0.0;
    _fillController.animateTo(
      restTarget,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    ).then((_) {
      if (mounted && _wasFavorited) {
        _fillController.value = 0.0;
      }
    });
  }

  @override
  void dispose() {
    _fillController.removeListener(_handleFillTick);
    _fillController.dispose();
    _waveController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Stack(
          children: [
            // Liquid Horizontal Waves Layer
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_fillController, _waveController, _flashController]),
                builder: (context, _) {
                  return CustomPaint(
                    painter: _HorizontalLiquidFillPainter(
                      progress: _fillController.value,
                      wavePhase: _waveController.value * 2 * math.pi,
                      flashOpacity: (1.0 - _flashController.value) * _flashController.value * 4.0,
                    ),
                  );
                },
              ),
            ),

            // Content widget
            widget.child,
          ],
        ),
      ),
    );
  }
}

/// CustomPainter rendering undulating horizontal liquid waves filling from left to right.
class _HorizontalLiquidFillPainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final double flashOpacity;

  const _HorizontalLiquidFillPainter({
    required this.progress,
    required this.wavePhase,
    required this.flashOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Subtle flash pulse when completed
    if (flashOpacity > 0.01) {
      final Paint flashPaint = Paint()
        ..color = const Color(0xFFE50914).withValues(alpha: (0.28 * flashOpacity).clamp(0.0, 0.40))
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), flashPaint);
    }

    if (w <= 0 || h <= 0 || progress <= 0.001) return;

    final double baseX = (progress * w).clamp(0.0, w);

    // Dynamic wave amplitude tapered at extremes
    final double amplitudeTaper = math.min(1.0, math.min(progress, 1.0 - progress) * 6.0);
    final double amp1 = 3.6 * amplitudeTaper;
    final double amp2 = 2.4 * amplitudeTaper;
    const double wavelength1 = 70.0;
    const double wavelength2 = 50.0;

    // 2. Back Wave Layer (softer alpha, shifted phase)
    final Path backWave = Path();
    backWave.moveTo(0, 0);
    backWave.lineTo((baseX + amp1 * math.sin(wavePhase * 0.8)).clamp(0.0, w), 0);

    for (double y = 0; y <= h; y += 3.0) {
      final double x = baseX + amp1 * math.sin((y / wavelength1) * 2 * math.pi + wavePhase * 0.8);
      backWave.lineTo(x.clamp(0.0, w), y);
    }
    backWave.lineTo(0, h);
    backWave.close();

    final Paint backPaint = Paint()
      ..color = const Color(0xFFE50914).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(backWave, backPaint);

    // 3. Front Wave Layer (crisper crest, soft reddish luminous gradient)
    final Path frontWave = Path();
    frontWave.moveTo(0, 0);
    frontWave.lineTo((baseX + amp2 * math.sin(wavePhase + math.pi / 2)).clamp(0.0, w), 0);

    for (double y = 0; y <= h; y += 3.0) {
      final double x = baseX + amp2 * math.sin((y / wavelength2) * 2 * math.pi + wavePhase + math.pi / 2);
      frontWave.lineTo(x.clamp(0.0, w), y);
    }
    frontWave.lineTo(0, h);
    frontWave.close();

    final Rect liquidRect = Rect.fromLTWH(0, 0, math.min(w, baseX + amp2), h);
    final Paint frontPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFFE50914).withValues(alpha: 0.28),
          const Color(0xFFE50914).withValues(alpha: 0.18),
        ],
      ).createShader(liquidRect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(frontWave, frontPaint);
  }

  @override
  bool shouldRepaint(covariant _HorizontalLiquidFillPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.flashOpacity != flashOpacity;
  }
}

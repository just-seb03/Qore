/// File: metro_live_tile.dart
/// Description: Windows Phone-styled Metro Live Tile supporting hardware-accelerated
/// 3D perspective flips (horizontal for square tiles, vertical for rectangular tiles).
/// Staggered periodic timers occasionally flip the tile from front to back, pause on the back
/// to reveal the entity icon on theme background, and flip back to front.
///
/// Components / Classes / Functions:
/// - MetroFlipAxis: Enum distinguishing horizontal (Y-axis) vs vertical (X-axis) flip.
/// - MetroLiveTile: Stateful widget coordinating 3D perspective rotation and live tile lifecycle.
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Axis of 3D rotation for the live tile.
enum MetroFlipAxis {
  /// Rotates around the vertical Y-axis (for square tiles: artist, album, favorites).
  horizontal,

  /// Rotates around the horizontal X-axis (for rectangular tiles: playlists).
  vertical,
}

/// Windows Phone Metro live tile with 3D perspective flip animation.
class MetroLiveTile extends StatefulWidget {
  /// The primary content facing the user (cover, artist avatar, album artwork, heart).
  final Widget front;

  /// The back content revealing the icon and type of the entity.
  final Widget back;

  /// Axis of rotation. Defaults to [MetroFlipAxis.horizontal].
  final MetroFlipAxis flipAxis;

  /// Initial staggered delay before the first flip cycle.
  final Duration initialDelay;

  /// Interval between flip cycles.
  final Duration interval;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Long-press callback (e.g. to unpin).
  final VoidCallback? onLongPress;

  /// Global pause flag for live tile 3D animations.
  static final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);

  /// Optional external flip coordinator trigger emitting the target [flipSlot].
  final ValueListenable<int?>? flipTrigger;

  /// Optional slot identifier matched against [flipTrigger].
  final int? flipSlot;

  const MetroLiveTile({
    super.key,
    required this.front,
    required this.back,
    this.flipAxis = MetroFlipAxis.horizontal,
    this.initialDelay = const Duration(seconds: 20),
    this.interval = const Duration(seconds: 60),
    this.flipTrigger,
    this.flipSlot,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<MetroLiveTile> createState() => _MetroLiveTileState();
}

class _MetroLiveTileState extends State<MetroLiveTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Timer? _staggerTimer;
  Timer? _periodicTimer;
  Timer? _pauseTimer;
  Completer<void>? _pauseCompleter;
  bool _isDisposed = false;
  bool _isTickerEnabled = true;

  bool get _usesExternalCoordinator =>
      widget.flipTrigger != null && widget.flipSlot != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    MetroLiveTile.isPaused.addListener(_onPausedChanged);
    widget.flipTrigger?.addListener(_onExternalTrigger);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool tickerEnabled = TickerMode.valuesOf(context).enabled;
    _isTickerEnabled = tickerEnabled;
    _syncSchedulingState();
  }

  @override
  void didUpdateWidget(covariant MetroLiveTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flipTrigger != oldWidget.flipTrigger) {
      oldWidget.flipTrigger?.removeListener(_onExternalTrigger);
      widget.flipTrigger?.addListener(_onExternalTrigger);
    }
    if (_usesExternalCoordinator) {
      _cancelLocalTimers();
    } else if (_staggerTimer == null && _periodicTimer == null) {
      _syncSchedulingState();
    }
  }

  void _onPausedChanged() {
    if (MetroLiveTile.isPaused.value && mounted && !_isDisposed) {
      _cancelPauseTimer();
      if (_controller.value > 0.0) {
        _controller.reverse();
      }
    }
    _syncSchedulingState();
  }

  void _onExternalTrigger() {
    if (!_usesExternalCoordinator ||
        !_isTickerEnabled ||
        MetroLiveTile.isPaused.value ||
        !mounted ||
        _isDisposed) {
      return;
    }
    if (widget.flipTrigger?.value == widget.flipSlot) {
      _flipTwice();
    }
  }

  void _syncSchedulingState() {
    if (!_isTickerEnabled || MetroLiveTile.isPaused.value || _usesExternalCoordinator) {
      _cancelLocalTimers();
      if (!_isTickerEnabled) {
        _cancelPauseTimer();
        if (_controller.value > 0.0) {
          _controller.reset();
        }
      }
      return;
    }

    if (_staggerTimer == null && _periodicTimer == null) {
      _scheduleFlips();
    }
  }

  void _cancelLocalTimers() {
    _staggerTimer?.cancel();
    _staggerTimer = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  void _cancelPauseTimer() {
    _pauseTimer?.cancel();
    _pauseTimer = null;
    if (_pauseCompleter != null && !_pauseCompleter!.isCompleted) {
      _pauseCompleter!.complete();
    }
  }

  void _scheduleFlips() {
    _cancelLocalTimers();
    _staggerTimer = Timer(widget.initialDelay, () {
      _staggerTimer = null;
      if (!mounted || _isDisposed || !_isTickerEnabled || _usesExternalCoordinator) {
        return;
      }
      if (!MetroLiveTile.isPaused.value) {
        _flipTwice();
      }
      _periodicTimer = Timer.periodic(widget.interval, (_) {
        if (!mounted || _isDisposed || !_isTickerEnabled || _usesExternalCoordinator) {
          return;
        }
        if (!MetroLiveTile.isPaused.value) {
          _flipTwice();
        }
      });
    });
  }

  Future<void> _flipTwice() async {
    if (!mounted ||
        _isDisposed ||
        !_isTickerEnabled ||
        _controller.isAnimating ||
        MetroLiveTile.isPaused.value) {
      return;
    }
    try {
      // 1. First flip: rotate from front to back
      await _controller.forward();
      if (!mounted || _isDisposed || !_isTickerEnabled || MetroLiveTile.isPaused.value) {
        return;
      }

      // 2. Pause on the back to show entity icon (half a second: 500ms)
      _pauseCompleter = Completer<void>();
      _pauseTimer = Timer(const Duration(milliseconds: 500), () {
        if (_pauseCompleter != null && !_pauseCompleter!.isCompleted) {
          _pauseCompleter!.complete();
        }
      });
      await _pauseCompleter!.future;
      if (!mounted || _isDisposed || !_isTickerEnabled || MetroLiveTile.isPaused.value) {
        return;
      }

      // 3. Second flip: rotate back to front
      await _controller.reverse();
    } catch (_) {}
  }

  @override
  void dispose() {
    _isDisposed = true;
    MetroLiveTile.isPaused.removeListener(_onPausedChanged);
    widget.flipTrigger?.removeListener(_onExternalTrigger);
    _cancelLocalTimers();
    _cancelPauseTimer();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final progress = _animation.value;
          final bool isFront = progress < 0.5;

          final double angle = isFront
              ? progress * math.pi
              : (progress - 1.0) * math.pi;

          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0012); // subtle 3D perspective depth

          if (widget.flipAxis == MetroFlipAxis.horizontal) {
            transform.rotateY(angle);
          } else {
            transform.rotateX(angle);
          }

          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: isFront ? widget.front : widget.back,
          );
        },
      ),
    );
  }
}

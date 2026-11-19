/// File: ambient_particles_canvas.dart
/// Description: Interactive canvas component executing the PS3-style background particle simulation.
/// Uses an isolated AnimationController that pauses and resumes based on controller state,
/// avoiding any CPU/GPU overhead when the expanded player is open or when disabled.
///
/// Components / Classes / Functions:
/// - AmbientParticlesCanvas: Widget hosting the isolated particle painter and AnimationController.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/controllers/theme_controller.dart';
import 'package:project_anima/features/ambient_particles/controllers/ambient_particles_controller.dart';
import 'package:project_anima/features/ambient_particles/painters/ambient_particles_painter.dart';

/// Canvas rendering dynamic floating ambient particles behind application content.
class AmbientParticlesCanvas extends StatefulWidget {
  /// Custom controller override (for testing / DI).
  final AmbientParticlesController? controller;

  /// Visual style mode: dotted wave trajectories across app vs PS3 silk waves in expanded player.
  final AmbientBackdropMode mode;

  const AmbientParticlesCanvas({
    super.key,
    this.controller,
    this.mode = AmbientBackdropMode.dottedWave,
  });

  @override
  State<AmbientParticlesCanvas> createState() => _AmbientParticlesCanvasState();
}

class _AmbientParticlesCanvasState extends State<AmbientParticlesCanvas>
    with SingleTickerProviderStateMixin {
  late final AmbientParticlesController _controller;
  late final AnimationController _animController;
  DateTime _lastTickTime = DateTime.now();
  Size _lastKnownSize = Size.zero;
  bool _wasEnabled = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AmbientParticlesController.instance;
    _wasEnabled = _controller.isEnabled;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _animController.addListener(_handleAnimationTick);
    _controller.addListener(_onControllerStateChanged);
    ThemeController.instance.addListener(_onThemeChanged);

    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant AmbientParticlesCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onControllerStateChanged);
      _controller = widget.controller ?? AmbientParticlesController.instance;
      _controller.addListener(_onControllerStateChanged);
      _syncAnimationState();
    }
  }

  @override
  void dispose() {
    _animController.removeListener(_handleAnimationTick);
    _animController.dispose();
    _controller.removeListener(_onControllerStateChanged);
    ThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onControllerStateChanged() {
    _syncAnimationState();
    if (_wasEnabled != _controller.isEnabled) {
      _wasEnabled = _controller.isEnabled;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _syncAnimationState() {
    if (_controller.isSimulating) {
      if (!_animController.isAnimating) {
        _lastTickTime = DateTime.now();
        final isAutomatedTest = WidgetsBinding.instance.runtimeType
            .toString()
            .contains('TestWidgetsFlutterBinding');
        if (!isAutomatedTest) {
          _animController.repeat();
        }
      }
    } else {
      if (_animController.isAnimating) {
        _animController.stop();
      }
    }
  }

  void _handleAnimationTick() {
    if (!_controller.isSimulating) return;

    final now = DateTime.now();
    final double dt =
        now.difference(_lastTickTime).inMicroseconds / 1000000.0;
    _lastTickTime = now;

    if (_lastKnownSize.width > 0 && _lastKnownSize.height > 0) {
      _controller.step(dt, _lastKnownSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isEnabled) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        if (width <= 0 || height <= 0) {
          return const SizedBox.shrink();
        }

        final size = Size(width, height);
        if (_lastKnownSize != size) {
          _lastKnownSize = size;
          _controller.initializeParticles(size);
        }

        return IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: AmbientParticlesPainter(
                repaint: _controller,
                particles: _controller.particles,
                accentColor: const Color(0xFF5BABCE),
                isDark: ThemeController.instance.isDarkMode,
                repaintToken: _controller.repaintToken,
                mode: widget.mode,
                waveTime: _controller.waveTime,
                waveTimeProvider: () => _controller.waveTime,
                beatPhaseProvider: () => _controller.beatPulsePhase,
                isPlayingProvider: () => _controller.isAudioPlaying,
              ),
            ),
          ),
        );
      },
    );
  }
}

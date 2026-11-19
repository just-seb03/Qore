/// File: ambient_particles_controller.dart
/// Description: Centralized controller orchestrating the ambient background particle simulation.
/// Controls lifecycle state (pausing when expanded player is open or app is inactive),
/// particle population, simulation physics, and animation updates.
///
/// Components / Classes / Functions:
/// - AmbientParticlesController: Singleton state manager driving ambient particle physics.
library;

import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:project_anima/core/scanner/bpm_analyzer.dart';
import 'package:project_anima/features/ambient_particles/models/ambient_particle.dart';

/// State and physics coordinator for the PS3-style background particles.
class AmbientParticlesController extends ChangeNotifier {
  AmbientParticlesController._internal();

  /// Global singleton instance.
  static final AmbientParticlesController instance =
      AmbientParticlesController._internal();

  final math.Random _random = math.Random();

  final List<AmbientParticle> _particles = [];
  late final UnmodifiableListView<AmbientParticle> _particlesView =
      UnmodifiableListView(_particles);

  bool _isEnabled = true;
  bool _isExpandedPlayerVisible = false;
  bool _isAppPaused = false;
  double _speedMultiplier = 1.0;
  int _particleCount = 32;
  int _repaintToken = 0;
  double _waveTime = 0.0;
  double? _currentBpm;
  bool _isAudioPlaying = false;
  double _targetBpmSpeed = 1.0;
  double _smoothedBpmSpeed = 1.0;
  double _effectiveVisualBpm = BpmAnalyzer.baselineVisualBpm;
  double _beatPulsePhase = 0.0;
  Size _lastSize = Size.zero;

  /// Whether the ambient background particles feature is enabled.
  bool get isEnabled => _isEnabled;

  /// Whether the maximized full-screen player is currently active.
  /// When active, particle simulation is frozen to save 100% of GPU/CPU resources.
  bool get isExpandedPlayerVisible => _isExpandedPlayerVisible;

  /// Whether the app lifecycle is paused or inactive in the background.
  bool get isAppPaused => _isAppPaused;

  /// Current global speed multiplier.
  double get speedMultiplier => _speedMultiplier;

  /// Number of active particles on canvas.
  int get particleCount => _particleCount;

  /// Monotonically increasing repaint counter for custom painter caching.
  int get repaintToken => _repaintToken;

  /// Continuous phase timer (radians) driving the PS3 XMB background silk wave motion.
  double get waveTime => _waveTime;

  /// Active track BPM currently driving wave velocity, if known.
  double? get currentBpm => _currentBpm;

  /// Whether audio is currently playing.
  bool get isAudioPlaying => _isAudioPlaying;

  /// Equivalent normalized BPM (folded from extreme values like 300 -> 150).
  double get effectiveVisualBpm => _effectiveVisualBpm;

  /// Current smoothed speed multiplier derived from [currentBpm].
  double get smoothedBpmSpeed => _smoothedBpmSpeed;

  /// Beat-synchronized oscillation phase (radians).
  double get beatPulsePhase => _beatPulsePhase;

  /// Active list of simulated particles (cached unmodifiable view).
  List<AmbientParticle> get particles => _particlesView;

  /// Whether the simulation is actively advancing physics.
  bool get isSimulating => _isEnabled && !_isAppPaused;

  /// Initializes or adjusts the particle population to fit the target screen [size].
  void initializeParticles(Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    _lastSize = size;

    if (_particles.length == _particleCount) return;

    _particles.clear();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        AmbientParticle.random(
          width: size.width,
          height: size.height,
          random: _random,
        ),
      );
    }
  }

  /// Advances physics simulation by [dt] seconds.
  void step(double dt, Size size) {
    if (!isSimulating || dt <= 0.0) return;

    if (_particles.isEmpty || _lastSize != size) {
      initializeParticles(size);
    }

    // Clamp dt to avoid physics leaps during frame drops or resumes
    final double safeDt = dt.clamp(0.0, 0.05);

    final double width = size.width > 0 ? size.width : 400.0;
    final double height = size.height > 0 ? size.height : 800.0;

    // Smoothly interpolate toward the target BPM-derived speed to avoid abrupt tempo jumps
    final double blendFactor = math.min(1.0, safeDt * 3.5);
    _smoothedBpmSpeed += (_targetBpmSpeed - _smoothedBpmSpeed) * blendFactor;
    final double effectiveSpeed = _speedMultiplier * _smoothedBpmSpeed;

    for (int i = 0; i < _particles.length; i++) {
      _particles[i].update(
        dt: safeDt,
        width: width,
        height: height,
        speedMultiplier: effectiveSpeed,
      );
    }

    _waveTime += safeDt * 0.95 * effectiveSpeed;
    final double beatRate = _isAudioPlaying ? (_effectiveVisualBpm / 60.0) : 0.45;
    _beatPulsePhase =
        (_beatPulsePhase + safeDt * beatRate * 2.0 * math.pi) % (2.0 * math.pi * 100.0);
    _repaintToken++;
    notifyListeners();
  }

  /// Synchronizes wave velocity and rhythmic beat phase with the currently playing track's BPM.
  void syncWithPlayback({
    double? bpm,
    required bool isPlaying,
  }) {
    _currentBpm = bpm;
    _isAudioPlaying = isPlaying;
    _effectiveVisualBpm = BpmAnalyzer.effectiveVisualBpm(bpm);
    _targetBpmSpeed = isPlaying ? BpmAnalyzer.mapBpmToWaveSpeed(bpm) : 0.60;
    notifyListeners();
  }

  /// Sets whether the full-screen expanded player is open.
  /// Automatically halts rendering while the user is inside the player screen.
  void setExpandedPlayerVisible(bool visible) {
    if (_isExpandedPlayerVisible == visible) return;
    _isExpandedPlayerVisible = visible;
    notifyListeners();
  }

  /// Sets whether the app is paused (e.g. sent to background).
  void setAppPaused(bool paused) {
    if (_isAppPaused == paused) return;
    _isAppPaused = paused;
    notifyListeners();
  }

  /// Toggles or updates the enabled state of the ambient particles.
  void setEnabled(bool enabled) {
    if (_isEnabled == enabled) return;
    _isEnabled = enabled;
    notifyListeners();
  }

  /// Adjusts simulation speed.
  void setSpeedMultiplier(double multiplier) {
    if (_speedMultiplier == multiplier) return;
    _speedMultiplier = multiplier.clamp(0.1, 4.0);
    notifyListeners();
  }

  /// Adjusts particle count (clamped between 8 and 64).
  void setParticleCount(int count) {
    final int safeCount = count.clamp(8, 64);
    if (_particleCount == safeCount) return;
    _particleCount = safeCount;
    if (_lastSize.width > 0 && _lastSize.height > 0) {
      _particles.clear();
      initializeParticles(_lastSize);
    }
    notifyListeners();
  }

  /// Resets particles to random positions (e.g. for testing or screen rotate).
  void reset() {
    _particles.clear();
    if (_lastSize.width > 0 && _lastSize.height > 0) {
      initializeParticles(_lastSize);
    }
    _repaintToken++;
    notifyListeners();
  }
}

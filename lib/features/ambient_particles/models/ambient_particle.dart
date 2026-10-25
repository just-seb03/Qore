/// File: ambient_particle.dart
/// Description: High-performance particle model for the PS3-style ambient background.
/// Holds coordinates, wave oscillation physics, radius, and breathing pulse parameters.
/// Designed for zero-allocation in-place simulation updates.
///
/// Components / Classes / Functions:
/// - AmbientParticle: Mutable value model representing an individual floating dust orb.
library;

import 'dart:math' as math;

/// Single floating particle in the ambient PS3-style dynamic background.
class AmbientParticle {
  /// Current horizontal coordinate on canvas (pixels).
  double x;

  /// Current vertical coordinate on canvas (pixels).
  double y;

  /// Anchor horizontal baseline coordinate around which the particle oscillates.
  double baseX;

  /// Upward float speed (pixels per second).
  double vy;

  /// Core radius of the particle (pixels).
  double radius;

  /// Horizontal oscillation amplitude (pixels).
  double waveAmplitude;

  /// Horizontal oscillation frequency (radians per second).
  double waveFrequency;

  /// Current phase of the horizontal wave (radians).
  double wavePhase;

  /// Breathing opacity frequency (radians per second).
  double pulseFrequency;

  /// Current phase of the opacity breathing pulse (radians).
  double pulsePhase;

  /// Base alpha factor (0.0 to 1.0).
  double baseAlpha;

  /// Depth layer (0: distant tiny speck, 1: mid-ground, 2: foreground soft orb).
  int layer;

  AmbientParticle({
    required this.x,
    required this.y,
    required this.baseX,
    required this.vy,
    required this.radius,
    required this.waveAmplitude,
    required this.waveFrequency,
    required this.wavePhase,
    required this.pulseFrequency,
    required this.pulsePhase,
    required this.baseAlpha,
    required this.layer,
  });

  /// Creates a randomly initialized particle within the given bounds.
  factory AmbientParticle.random({
    required double width,
    required double height,
    required math.Random random,
  }) {
    final double safeWidth = width > 0 ? width : 400.0;
    final double safeHeight = height > 0 ? height : 800.0;

    final double randVal = random.nextDouble();
    int layer;
    double radius;
    double vy;
    double baseAlpha;
    double waveAmplitude;

    if (randVal < 0.60) {
      // 60% Distant tiny dust specks: slow, subtle, small
      layer = 0;
      radius = 1.0 + random.nextDouble() * 1.6;
      vy = 12.0 + random.nextDouble() * 18.0;
      baseAlpha = 0.12 + random.nextDouble() * 0.14;
      waveAmplitude = 8.0 + random.nextDouble() * 16.0;
    } else if (randVal < 0.90) {
      // 30% Mid-ground motes: medium speed, noticeable drift
      layer = 1;
      radius = 2.4 + random.nextDouble() * 2.2;
      vy = 20.0 + random.nextDouble() * 25.0;
      baseAlpha = 0.16 + random.nextDouble() * 0.16;
      waveAmplitude = 14.0 + random.nextDouble() * 22.0;
    } else {
      // 10% Foreground soft orbs: larger bokeh, gentle ethereal float
      layer = 2;
      radius = 4.5 + random.nextDouble() * 3.5;
      vy = 16.0 + random.nextDouble() * 22.0;
      baseAlpha = 0.10 + random.nextDouble() * 0.12;
      waveAmplitude = 20.0 + random.nextDouble() * 30.0;
    }

    final double initX = random.nextDouble() * safeWidth;
    final double initY = random.nextDouble() * safeHeight;

    return AmbientParticle(
      x: initX,
      y: initY,
      baseX: initX,
      vy: vy,
      radius: radius,
      waveAmplitude: waveAmplitude,
      waveFrequency: 0.35 + random.nextDouble() * 0.65,
      wavePhase: random.nextDouble() * 2 * math.pi,
      pulseFrequency: 0.45 + random.nextDouble() * 0.85,
      pulsePhase: random.nextDouble() * 2 * math.pi,
      baseAlpha: baseAlpha,
      layer: layer,
    );
  }

  /// Updates particle coordinates and wave physics in-place based on delta time [dt].
  void update({
    required double dt,
    required double width,
    required double height,
    required double speedMultiplier,
  }) {
    final double safeWidth = width > 0 ? width : 400.0;
    final double safeHeight = height > 0 ? height : 800.0;

    // Upward vertical drift
    y -= vy * speedMultiplier * dt;

    // Harmonic wave and pulse advancement
    wavePhase += waveFrequency * speedMultiplier * dt;
    pulsePhase += pulseFrequency * speedMultiplier * dt;

    // Gentle horizontal sine oscillation around baseline
    x = baseX + math.sin(wavePhase) * waveAmplitude;

    // Wrap around vertical boundary when exiting top
    final double margin = radius * 3.5 + 20.0;
    if (y < -margin) {
      y = safeHeight + margin;
      baseX = (baseX + (math.sin(pulsePhase) * 60.0)) % safeWidth;
      if (baseX < 0) baseX += safeWidth;
      x = baseX;
    }

    // Wrap around horizontal boundaries
    if (x < -margin) {
      baseX = safeWidth + margin;
      x = baseX;
    } else if (x > safeWidth + margin) {
      baseX = -margin;
      x = baseX;
    }
  }

  /// Computes the active modulated alpha (0.0 to 1.0) with breathing effect.
  double computeAlpha({required bool isDark}) {
    // Light themes need slightly reduced maximum alpha to prevent harsh contrast
    final double themeMultiplier = isDark ? 1.0 : 0.75;
    final double pulse = 0.65 + 0.35 * math.sin(pulsePhase);
    return (baseAlpha * pulse * themeMultiplier).clamp(0.0, 1.0);
  }
}

/// File: ambient_particles_painter.dart
/// Description: Optimized CustomPainter drawing PS3-inspired celestial motes and soft glowing orbs.
/// Employs a dual-concentric luminous core and outer halo for ethereal glow without expensive offscreen filters.
///
/// Components / Classes / Functions:
/// - AmbientParticlesPainter: CustomPainter rendering simulated ambient particles.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/features/ambient_particles/models/ambient_particle.dart';

/// Renders a list of [AmbientParticle] with glowing multi-layer circular shapes.
class AmbientParticlesPainter extends CustomPainter {
  /// Unmodifiable view of active particles.
  final List<AmbientParticle> particles;

  /// Dynamic theme accent color.
  final Color accentColor;

  /// Whether active palette is dark mode (adapts opacity bounds).
  final bool isDark;

  /// Animation tick sequence ensuring deterministic repaints.
  final int repaintToken;

  final Paint _haloPaint = Paint()..isAntiAlias = true;
  final Paint _corePaint = Paint()..isAntiAlias = true;
  final Paint _glintPaint = Paint()..isAntiAlias = true;

  AmbientParticlesPainter({
    super.repaint,
    required this.particles,
    required this.accentColor,
    required this.isDark,
    required this.repaintToken,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;

    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];

      // Cull particles outside viewport
      if (particle.y < -30.0 || particle.y > size.height + 30.0) continue;
      if (particle.x < -30.0 || particle.x > size.width + 30.0) continue;

      final double alpha = particle.computeAlpha(isDark: isDark);
      if (alpha <= 0.005) continue;

      final center = Offset(particle.x, particle.y);

      // 1. Soft Outer Halo (Ethereal spread)
      final double haloAlpha = (alpha * 0.35).clamp(0.0, 1.0);
      _haloPaint.color = accentColor.withValues(alpha: haloAlpha);
      canvas.drawCircle(center, particle.radius * 2.2, _haloPaint);

      // 2. Focused Core (Main particle body)
      _corePaint.color = accentColor.withValues(alpha: alpha);
      canvas.drawCircle(center, particle.radius, _corePaint);

      // 3. Central Glint (Delicate high-value speck for luminous shimmer)
      if (particle.layer >= 1) {
        final double glintAlpha = (alpha * 0.50).clamp(0.0, 1.0);
        _glintPaint.color = Colors.white.withValues(alpha: glintAlpha);
        canvas.drawCircle(center, particle.radius * 0.4, _glintPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant AmbientParticlesPainter oldDelegate) {
    return oldDelegate.repaintToken != repaintToken ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.particles != particles;
  }
}

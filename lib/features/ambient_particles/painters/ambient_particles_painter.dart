/// File: ambient_particles_painter.dart
/// Description: GPU-accelerated CustomPainter rendering PS3 XMB-inspired translucent silk
/// ribbon waves paired with floating celestial motes in the #5BABCE accent palette.
/// Uses pre-allocated vertex buffers and multi-band triangle-mesh gradients (via ui.Vertices)
/// for smooth 3D-twisted satin folds and soft glowing creases without blur layers.
///
/// Components / Classes / Functions:
/// - _XmbRibbonSpec: Immutable geometric & optical definition for a silk wave sheet.
/// - AmbientParticlesPainter: CustomPainter rendering the XMB waves and ambient particles.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:project_anima/features/ambient_particles/models/ambient_particle.dart';

/// Immutable geometric and optical parameters for a single XMB silk ribbon fold.
class _XmbRibbonSpec {
  final Offset startNorm;
  final Offset endNorm;
  final double spineAmp1;
  final double spineFreq1;
  final double spineSpeed1;
  final double spinePhase1;
  final double spineAmp2;
  final double spineFreq2;
  final double spineSpeed2;
  final double spinePhase2;
  final double crestAmp;
  final double crestFreq;
  final double crestSpeed;
  final double crestPhase;
  final double tailBaseNorm;
  final double tailTwistAmp;
  final double tailTwistFreq;
  final double tailTwistSpeed;
  final double tailTwistPhase;
  final double tailTangentAmp;
  final double veilAlphaDark;
  final double veilAlphaLight;
  final double crestAlphaDark;
  final double crestAlphaLight;

  const _XmbRibbonSpec({
    required this.startNorm,
    required this.endNorm,
    required this.spineAmp1,
    required this.spineFreq1,
    required this.spineSpeed1,
    required this.spinePhase1,
    required this.spineAmp2,
    required this.spineFreq2,
    required this.spineSpeed2,
    required this.spinePhase2,
    required this.crestAmp,
    required this.crestFreq,
    required this.crestSpeed,
    required this.crestPhase,
    required this.tailBaseNorm,
    required this.tailTwistAmp,
    required this.tailTwistFreq,
    required this.tailTwistSpeed,
    required this.tailTwistPhase,
    required this.tailTangentAmp,
    required this.veilAlphaDark,
    required this.veilAlphaLight,
    required this.crestAlphaDark,
    required this.crestAlphaLight,
  });
}

/// Renders PS3 XMB-style translucent folded silk waves and [AmbientParticle] motes.
class AmbientParticlesPainter extends CustomPainter {
  /// Unmodifiable view of active particles.
  final List<AmbientParticle> particles;

  /// Dynamic accent color (#5BABCE in canvas).
  final Color accentColor;

  /// Whether active palette is dark mode (adapts opacity bounds & blend mode).
  final bool isDark;

  /// Animation tick sequence ensuring deterministic repaints.
  final int repaintToken;

  /// Continuous wave phase (radians) driving smooth ribbon motion.
  final double waveTime;

  final Paint _haloPaint = Paint()..isAntiAlias = true;
  final Paint _corePaint = Paint()..isAntiAlias = true;
  final Paint _glintPaint = Paint()..isAntiAlias = true;
  final Paint _veilMeshPaint = Paint()..isAntiAlias = true;
  final Paint _crestBloomPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Paint _crestSoftPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static const int _ribbonSteps = 76;
  static const int _cols = _ribbonSteps + 1;
  // 3 smooth exponential falloff bands per slice = 6 triangles = 18 vertices per slice
  static const int _triVertexCount = _ribbonSteps * 6 * 3;

  // Reusable scratch buffers (zero per-frame list allocations)
  final List<Offset> _crestPts = List<Offset>.filled(_cols, Offset.zero);
  final List<Offset> _mid1Pts = List<Offset>.filled(_cols, Offset.zero);
  final List<Offset> _mid2Pts = List<Offset>.filled(_cols, Offset.zero);
  final List<Offset> _tailPts = List<Offset>.filled(_cols, Offset.zero);
  final List<Color> _crestCols = List<Color>.filled(_cols, Colors.transparent);
  final List<Color> _mid1Cols = List<Color>.filled(_cols, Colors.transparent);
  final List<Color> _mid2Cols = List<Color>.filled(_cols, Colors.transparent);
  final List<Color> _tailCols = List<Color>.filled(_cols, Colors.transparent);
  final List<Offset> _positions = List<Offset>.filled(_triVertexCount, Offset.zero);
  final List<Color> _colors = List<Color>.filled(_triVertexCount, Colors.transparent);
  final Path _crestPath = Path();

  /// Three overlapping broad silk waves recreating the iconic PS3 XMB diagonal flow.
  static const List<_XmbRibbonSpec> _ribbons = [
    // 1. Broad diagonal atmospheric silk curtain sweeping upper-left to bottom-right
    _XmbRibbonSpec(
      startNorm: Offset(-0.25, -0.02),
      endNorm: Offset(1.24, 0.78),
      spineAmp1: 0.095,
      spineFreq1: 1.65 * math.pi,
      spineSpeed1: 0.36,
      spinePhase1: 0.2,
      spineAmp2: 0.045,
      spineFreq2: 2.8 * math.pi,
      spineSpeed2: -0.24,
      spinePhase2: 1.4,
      crestAmp: 0.055,
      crestFreq: 1.45 * math.pi,
      crestSpeed: 0.40,
      crestPhase: 0.6,
      tailBaseNorm: 0.30,
      tailTwistAmp: 0.36,
      tailTwistFreq: 1.55 * math.pi,
      tailTwistSpeed: 0.32,
      tailTwistPhase: 0.25,
      tailTangentAmp: 0.12,
      veilAlphaDark: 0.26,
      veilAlphaLight: 0.16,
      crestAlphaDark: 0.20,
      crestAlphaLight: 0.14,
    ),
    // 2. Main foreground folding wave with wide luminous satin skirt
    _XmbRibbonSpec(
      startNorm: Offset(-0.24, 0.14),
      endNorm: Offset(1.25, 1.04),
      spineAmp1: 0.115,
      spineFreq1: 1.95 * math.pi,
      spineSpeed1: 0.46,
      spinePhase1: 1.1,
      spineAmp2: 0.055,
      spineFreq2: 3.1 * math.pi,
      spineSpeed2: -0.32,
      spinePhase2: 2.3,
      crestAmp: 0.085,
      crestFreq: 1.85 * math.pi,
      crestSpeed: 0.52,
      crestPhase: 1.8,
      tailBaseNorm: 0.20,
      tailTwistAmp: 0.42,
      tailTwistFreq: 1.95 * math.pi,
      tailTwistSpeed: 0.42,
      tailTwistPhase: 1.15,
      tailTangentAmp: 0.15,
      veilAlphaDark: 0.38,
      veilAlphaLight: 0.23,
      crestAlphaDark: 0.32,
      crestAlphaLight: 0.20,
    ),
    // 3. Upper intersecting ribbon fold pinching smoothly across center-mid
    _XmbRibbonSpec(
      startNorm: Offset(-0.18, -0.14),
      endNorm: Offset(1.26, 0.56),
      spineAmp1: 0.105,
      spineFreq1: 2.1 * math.pi,
      spineSpeed1: -0.40,
      spinePhase1: 2.1,
      spineAmp2: 0.048,
      spineFreq2: 3.4 * math.pi,
      spineSpeed2: 0.30,
      spinePhase2: 0.7,
      crestAmp: 0.075,
      crestFreq: 2.0 * math.pi,
      crestSpeed: -0.46,
      crestPhase: 2.8,
      tailBaseNorm: 0.16,
      tailTwistAmp: 0.34,
      tailTwistFreq: 2.1 * math.pi,
      tailTwistSpeed: -0.38,
      tailTwistPhase: 2.35,
      tailTangentAmp: 0.13,
      veilAlphaDark: 0.32,
      veilAlphaLight: 0.19,
      crestAlphaDark: 0.28,
      crestAlphaLight: 0.18,
    ),
  ];

  AmbientParticlesPainter({
    super.repaint,
    required this.particles,
    required this.accentColor,
    required this.isDark,
    required this.repaintToken,
    this.waveTime = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Render PS3 XMB-style translucent overlapping satin waves
    for (int i = 0; i < _ribbons.length; i++) {
      _paintRibbon(canvas, size, _ribbons[i]);
    }

    // 2. Render subtle floating celestial particles drifting through the wave
    if (particles.isEmpty) return;

    final Color glintColor = Color.lerp(
      accentColor,
      Colors.white,
      isDark ? 0.65 : 0.25,
    )!;

    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];

      if (particle.y < -30.0 || particle.y > size.height + 30.0) continue;
      if (particle.x < -30.0 || particle.x > size.width + 30.0) continue;

      final double alpha = particle.computeAlpha(isDark: isDark);
      if (alpha <= 0.005) continue;

      final center = Offset(particle.x, particle.y);

      final double haloAlpha = (alpha * 0.36).clamp(0.0, 1.0);
      _haloPaint.color = accentColor.withValues(alpha: haloAlpha);
      canvas.drawCircle(center, particle.radius * 2.2, _haloPaint);

      _corePaint.color =
          accentColor.withValues(alpha: (alpha * 1.15).clamp(0.0, 1.0));
      canvas.drawCircle(center, particle.radius, _corePaint);

      if (particle.layer >= 1) {
        final double glintAlpha = (alpha * 0.65).clamp(0.0, 1.0);
        _glintPaint.color = glintColor.withValues(alpha: glintAlpha);
        canvas.drawCircle(center, particle.radius * 0.42, _glintPaint);
      }
    }
  }

  void _paintRibbon(Canvas canvas, Size size, _XmbRibbonSpec spec) {
    final double w = size.width;
    final double h = size.height;
    final double scaleDim = math.min(w, h) * 0.72 + math.max(w, h) * 0.28;

    final Offset start = Offset(spec.startNorm.dx * w, spec.startNorm.dy * h);
    final Offset end = Offset(spec.endNorm.dx * w, spec.endNorm.dy * h);
    final Offset axis = end - start;
    final double axisLen = axis.distance;
    if (axisLen <= 1e-3) return;

    final Offset dir = axis / axisLen;
    final Offset normal = Offset(-dir.dy, dir.dx);

    final Color baseVeilColor = isDark
        ? accentColor
        : Color.lerp(accentColor, const Color(0xFF2E7EA3), 0.16)!;
    final Color crestHighlightColor = isDark
        ? Color.lerp(accentColor, Colors.white, 0.58)!
        : Color.lerp(accentColor, const Color(0xFF246F92), 0.24)!;
    final Color crestEdgeColor =
        Color.lerp(baseVeilColor, crestHighlightColor, 0.52)!;

    final double veilPeak = isDark ? spec.veilAlphaDark : spec.veilAlphaLight;
    final double crestPeak =
        isDark ? spec.crestAlphaDark : spec.crestAlphaLight;

    _crestPath.reset();

    for (int i = 0; i < _cols; i++) {
      final double u = i / _ribbonSteps;
      final Offset spineBase = Offset.lerp(start, end, u)!;

      final double spineWave = (spec.spineAmp1 *
                  math.sin(spec.spineFreq1 * u + waveTime * spec.spineSpeed1 + spec.spinePhase1) +
              spec.spineAmp2 *
                  math.cos(spec.spineFreq2 * u + waveTime * spec.spineSpeed2 + spec.spinePhase2)) *
          scaleDim;

      final Offset spine = spineBase + normal * spineWave;

      final double crestOff = spec.crestAmp *
          math.sin(spec.crestFreq * u + waveTime * spec.crestSpeed + spec.crestPhase) *
          scaleDim;

      final double twistAngle =
          spec.tailTwistFreq * u + waveTime * spec.tailTwistSpeed + spec.tailTwistPhase;
      final double tailSpread =
          (spec.tailBaseNorm + spec.tailTwistAmp * math.sin(twistAngle)) * scaleDim;
      // Tangential 3D twist offset produces curved XMB silk folds instead of sharp cusps
      final double tailTan = spec.tailTangentAmp * math.cos(twistAngle) * scaleDim;

      final Offset pCrest = spine + normal * crestOff;
      final Offset pTail =
          spine + normal * (crestOff - tailSpread) + dir * tailTan;

      final Offset pMid1 = Offset.lerp(pCrest, pTail, 0.24)!;
      final Offset pMid2 = Offset.lerp(pCrest, pTail, 0.62)!;

      _crestPts[i] = pCrest;
      _mid1Pts[i] = pMid1;
      _mid2Pts[i] = pMid2;
      _tailPts[i] = pTail;

      final double spreadNorm =
          (tailSpread.abs() / (scaleDim * 0.28)).clamp(0.15, 1.4);
      final double foldFocus = (1.18 - 0.30 * spreadNorm).clamp(0.75, 1.18);
      final double edgeEnvelope =
          (0.35 + 0.65 * math.sin(u * math.pi)).clamp(0.0, 1.0);
      final double aCrest =
          (veilPeak * foldFocus * edgeEnvelope).clamp(0.0, 0.72);

      _crestCols[i] = crestEdgeColor.withValues(alpha: aCrest);
      _mid1Cols[i] = baseVeilColor.withValues(alpha: aCrest * 0.68);
      _mid2Cols[i] = baseVeilColor.withValues(alpha: aCrest * 0.26);
      _tailCols[i] = baseVeilColor.withValues(alpha: 0.0);

      if (i == 0) {
        _crestPath.moveTo(pCrest.dx, pCrest.dy);
      } else {
        _crestPath.lineTo(pCrest.dx, pCrest.dy);
      }
    }

    int v = 0;
    for (int i = 0; i < _ribbonSteps; i++) {
      v = _emitBandSlice(
        v,
        _crestPts[i],
        _crestPts[i + 1],
        _mid1Pts[i],
        _mid1Pts[i + 1],
        _crestCols[i],
        _crestCols[i + 1],
        _mid1Cols[i],
        _mid1Cols[i + 1],
      );
      v = _emitBandSlice(
        v,
        _mid1Pts[i],
        _mid1Pts[i + 1],
        _mid2Pts[i],
        _mid2Pts[i + 1],
        _mid1Cols[i],
        _mid1Cols[i + 1],
        _mid2Cols[i],
        _mid2Cols[i + 1],
      );
      v = _emitBandSlice(
        v,
        _mid2Pts[i],
        _mid2Pts[i + 1],
        _tailPts[i],
        _tailPts[i + 1],
        _mid2Cols[i],
        _mid2Cols[i + 1],
        _tailCols[i],
        _tailCols[i + 1],
      );
    }

    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      _positions,
      colors: _colors,
    );

    _veilMeshPaint.blendMode = isDark ? BlendMode.plus : BlendMode.srcOver;
    canvas.drawVertices(
      vertices,
      BlendMode.srcOver,
      _veilMeshPaint,
    );

    // Wide soft atmospheric sheen along the silk fold
    _crestBloomPaint
      ..strokeWidth = 14.0
      ..blendMode = isDark ? BlendMode.plus : BlendMode.srcOver
      ..color =
          baseVeilColor.withValues(alpha: (crestPeak * 0.22).clamp(0.0, 1.0));
    canvas.drawPath(_crestPath, _crestBloomPaint);

    _crestSoftPaint
      ..strokeWidth = 2.8
      ..blendMode = isDark ? BlendMode.plus : BlendMode.srcOver
      ..color = crestHighlightColor
          .withValues(alpha: (crestPeak * 0.45).clamp(0.0, 1.0));
    canvas.drawPath(_crestPath, _crestSoftPaint);
  }

  int _emitBandSlice(
    int v,
    Offset a0,
    Offset a1,
    Offset b0,
    Offset b1,
    Color ca0,
    Color ca1,
    Color cb0,
    Color cb1,
  ) {
    _positions[v] = a0;
    _colors[v++] = ca0;
    _positions[v] = a1;
    _colors[v++] = ca1;
    _positions[v] = b0;
    _colors[v++] = cb0;

    _positions[v] = a1;
    _colors[v++] = ca1;
    _positions[v] = b1;
    _colors[v++] = cb1;
    _positions[v] = b0;
    _colors[v++] = cb0;
    return v;
  }

  @override
  bool shouldRepaint(covariant AmbientParticlesPainter oldDelegate) {
    return oldDelegate.repaintToken != repaintToken ||
        oldDelegate.waveTime != waveTime ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.particles != particles;
  }
}

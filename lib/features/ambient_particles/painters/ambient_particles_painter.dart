/// File: ambient_particles_painter.dart
/// Description: GPU-accelerated CustomPainter supporting two visual backdrop modes in `#5BABCE`:
/// - [AmbientBackdropMode.particles]: Used across the app — classic floating celestial bokeh motes
///   with soft outer halo, focused core, and subtle white glint.
/// - [AmbientBackdropMode.silkWave]: Used inside the expanded PlayerScreen — smooth, continuous
///   PS3 XMB translucent silk ribbon waves whose glide velocity scales cleanly to song BPM
///   without jarring beat jumps.
///
/// Components / Classes / Functions:
/// - AmbientBackdropMode: Visual backdrop rendering style selector.
/// - _XmbRibbonSpec: Immutable geometric & optical definition for a silk wave sheet.
/// - AmbientParticlesPainter: CustomPainter rendering floating particles or XMB silk waves.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:project_anima/features/ambient_particles/models/ambient_particle.dart';

/// Visual mode for [AmbientParticlesPainter] and [AmbientParticlesCanvas].
enum AmbientBackdropMode {
  /// Classic floating glowing celestial motes (used across standard app screens).
  particles,

  /// Softly translucent PS3 XMB silk wave ribbons (used exclusively inside maximized PlayerScreen).
  silkWave,
}

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

/// Renders either classic floating `#5BABCE` particles ([AmbientBackdropMode.particles])
/// or smooth translucent PS3 XMB silk waves ([AmbientBackdropMode.silkWave]).
class AmbientParticlesPainter extends CustomPainter {
  /// Unmodifiable view of active floating particles (used in [AmbientBackdropMode.particles]).
  final List<AmbientParticle> particles;

  /// Dynamic accent color (`#5BABCE` in canvas).
  final Color accentColor;

  /// Whether active palette is dark mode (adapts opacity bounds & blend mode).
  final bool isDark;

  /// Animation tick sequence ensuring deterministic repaints.
  final int repaintToken;

  /// Backdrop style mode (`particles` across app screens, `silkWave` in expanded PlayerScreen).
  final AmbientBackdropMode mode;

  /// Fallback static phase (radians) when [waveTimeProvider] is omitted.
  final double waveTime;

  /// Live time reader evaluated on every `paint()` tick triggered by [super.repaint].
  final double Function()? waveTimeProvider;

  /// Live wave color reader allowing silk waves to smoothly adapt to active cover art.
  final Color Function()? waveColorProvider;

  /// Kept for backward API compatibility.
  final double Function()? beatPhaseProvider;

  /// Kept for backward API compatibility.
  final bool Function()? isPlayingProvider;

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

  static const int _ribbonSteps = 40;
  static const int _cols = _ribbonSteps + 1;
  static const int _triVertexCount = _ribbonSteps * 6 * 3;

  // Reusable scratch buffers for silk wave geometry (zero per-frame heap churn)
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

  int? _cachedRawColorArgb;
  bool? _cachedIsDark;
  Color _cachedBaseVeilColor = Colors.transparent;
  Color _cachedCrestHighlightColor = Colors.transparent;
  Color _cachedCrestEdgeColor = Colors.transparent;

  /// Three overlapping broad silk waves recreating the iconic PS3 XMB diagonal flow.
  static const List<_XmbRibbonSpec> _ribbons = [
    // 1. Broad diagonal atmospheric silk curtain sweeping upper-left to bottom-right
    _XmbRibbonSpec(
      startNorm: Offset(-0.25, -0.02),
      endNorm: Offset(1.24, 0.78),
      spineAmp1: 0.095,
      spineFreq1: 1.65 * math.pi,
      spineSpeed1: 0.55,
      spinePhase1: 0.2,
      spineAmp2: 0.045,
      spineFreq2: 2.8 * math.pi,
      spineSpeed2: -0.38,
      spinePhase2: 1.4,
      crestAmp: 0.055,
      crestFreq: 1.45 * math.pi,
      crestSpeed: 0.62,
      crestPhase: 0.6,
      tailBaseNorm: 0.30,
      tailTwistAmp: 0.36,
      tailTwistFreq: 1.55 * math.pi,
      tailTwistSpeed: 0.48,
      tailTwistPhase: 0.25,
      tailTangentAmp: 0.12,
      veilAlphaDark: 0.10,
      veilAlphaLight: 0.07,
      crestAlphaDark: 0.09,
      crestAlphaLight: 0.07,
    ),
    // 2. Main foreground folding wave with wide luminous satin skirt
    _XmbRibbonSpec(
      startNorm: Offset(-0.24, 0.14),
      endNorm: Offset(1.25, 1.04),
      spineAmp1: 0.115,
      spineFreq1: 1.95 * math.pi,
      spineSpeed1: 0.72,
      spinePhase1: 1.1,
      spineAmp2: 0.055,
      spineFreq2: 3.1 * math.pi,
      spineSpeed2: -0.50,
      spinePhase2: 2.3,
      crestAmp: 0.085,
      crestFreq: 1.85 * math.pi,
      crestSpeed: 0.80,
      crestPhase: 1.8,
      tailBaseNorm: 0.20,
      tailTwistAmp: 0.42,
      tailTwistFreq: 1.95 * math.pi,
      tailTwistSpeed: 0.65,
      tailTwistPhase: 1.15,
      tailTangentAmp: 0.15,
      veilAlphaDark: 0.15,
      veilAlphaLight: 0.10,
      crestAlphaDark: 0.15,
      crestAlphaLight: 0.11,
    ),
    // 3. Upper intersecting ribbon fold pinching smoothly across center-mid
    _XmbRibbonSpec(
      startNorm: Offset(-0.18, -0.14),
      endNorm: Offset(1.26, 0.56),
      spineAmp1: 0.105,
      spineFreq1: 2.1 * math.pi,
      spineSpeed1: -0.64,
      spinePhase1: 2.1,
      spineAmp2: 0.048,
      spineFreq2: 3.4 * math.pi,
      spineSpeed2: 0.46,
      spinePhase2: 0.7,
      crestAmp: 0.075,
      crestFreq: 2.0 * math.pi,
      crestSpeed: -0.74,
      crestPhase: 2.8,
      tailBaseNorm: 0.16,
      tailTwistAmp: 0.34,
      tailTwistFreq: 2.1 * math.pi,
      tailTwistSpeed: -0.58,
      tailTwistPhase: 2.35,
      tailTangentAmp: 0.13,
      veilAlphaDark: 0.12,
      veilAlphaLight: 0.08,
      crestAlphaDark: 0.13,
      crestAlphaLight: 0.09,
    ),
  ];

  AmbientParticlesPainter({
    super.repaint,
    this.particles = const [],
    required this.accentColor,
    required this.isDark,
    required this.repaintToken,
    this.mode = AmbientBackdropMode.particles,
    this.waveTime = 0.0,
    this.waveTimeProvider,
    this.waveColorProvider,
    this.beatPhaseProvider,
    this.isPlayingProvider,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    if (mode == AmbientBackdropMode.silkWave) {
      final double activeTime = waveTimeProvider?.call() ?? waveTime;
      for (int i = 0; i < _ribbons.length; i++) {
        _paintSilkRibbon(canvas, size, _ribbons[i], activeTime);
      }
      return;
    }

    _paintParticles(canvas, size);
  }

  /// Renders the classic glowing multi-layer floating particles across the rest of the app.
  void _paintParticles(Canvas canvas, Size size) {
    if (particles.isEmpty) return;

    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];

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

  /// Renders smooth, continuous PS3 XMB silk waves without beat-bounce jerking.
  void _paintSilkRibbon(
    Canvas canvas,
    Size size,
    _XmbRibbonSpec spec,
    double t,
  ) {
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

    // Resolve dynamic cover color and cache HSL/lerp derivations until color or brightness changes
    final Color rawColor = waveColorProvider?.call() ?? accentColor;
    final int rawArgb = rawColor.toARGB32();
    if (_cachedRawColorArgb != rawArgb || _cachedIsDark != isDark) {
      final HSLColor rawHsl = HSLColor.fromColor(rawColor);
      final double clampedLightness = isDark
          ? rawHsl.lightness.clamp(0.42, 0.68)
          : rawHsl.lightness.clamp(0.35, 0.56);
      final Color adaptedColor = rawHsl.withLightness(clampedLightness).toColor();

      _cachedBaseVeilColor = isDark
          ? Color.lerp(adaptedColor, const Color(0xFF0E0E10), 0.14)!
          : Color.lerp(adaptedColor, const Color(0xFF1F3B4D), 0.10)!;
      _cachedCrestHighlightColor = isDark
          ? Color.lerp(adaptedColor, Colors.white, 0.30)!
          : Color.lerp(adaptedColor, const Color(0xFF1A252B), 0.18)!;
      _cachedCrestEdgeColor =
          Color.lerp(_cachedBaseVeilColor, _cachedCrestHighlightColor, 0.42)!;
      _cachedRawColorArgb = rawArgb;
      _cachedIsDark = isDark;
    }

    final Color baseVeilColor = _cachedBaseVeilColor;
    final Color crestHighlightColor = _cachedCrestHighlightColor;
    final Color crestEdgeColor = _cachedCrestEdgeColor;

    final double veilPeak = isDark ? spec.veilAlphaDark : spec.veilAlphaLight;
    final double crestPeak =
        isDark ? spec.crestAlphaDark : spec.crestAlphaLight;

    _crestPath.reset();

    for (int i = 0; i < _cols; i++) {
      final double u = i / _ribbonSteps;
      final Offset spineBase = Offset.lerp(start, end, u)!;

      final double spineWave = (spec.spineAmp1 *
                  math.sin(spec.spineFreq1 * u + t * spec.spineSpeed1 + spec.spinePhase1) +
              spec.spineAmp2 *
                  math.cos(spec.spineFreq2 * u + t * spec.spineSpeed2 + spec.spinePhase2)) *
          scaleDim;

      final Offset spine = spineBase + normal * spineWave;

      final double crestOff = spec.crestAmp *
          math.sin(spec.crestFreq * u + t * spec.crestSpeed + spec.crestPhase) *
          scaleDim;

      final double twistAngle =
          spec.tailTwistFreq * u + t * spec.tailTwistSpeed + spec.tailTwistPhase;
      final double tailSpread =
          (spec.tailBaseNorm + spec.tailTwistAmp * math.sin(twistAngle)) * scaleDim;
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
      _mid1Cols[i] = baseVeilColor.withValues(alpha: aCrest * 0.56);
      _mid2Cols[i] = baseVeilColor.withValues(alpha: aCrest * 0.18);
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

    _crestBloomPaint
      ..strokeWidth = 14.0
      ..blendMode = isDark ? BlendMode.plus : BlendMode.srcOver
      ..color =
          baseVeilColor.withValues(alpha: (crestPeak * 0.18).clamp(0.0, 1.0));
    canvas.drawPath(_crestPath, _crestBloomPaint);

    _crestSoftPaint
      ..strokeWidth = 2.2
      ..blendMode = isDark ? BlendMode.plus : BlendMode.srcOver
      ..color = crestHighlightColor
          .withValues(alpha: (crestPeak * 0.34).clamp(0.0, 1.0));
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
        oldDelegate.mode != mode ||
        oldDelegate.waveTime != waveTime ||
        oldDelegate.waveTimeProvider != waveTimeProvider ||
        oldDelegate.waveColorProvider != waveColorProvider ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.particles != particles;
  }
}

/// File: ambient_particles_painter.dart
/// Description: GPU-accelerated CustomPainter supporting two cohesive PS3-inspired backdrop modes
/// in the #5BABCE accent palette, driven by the active track's BPM:
/// - [AmbientBackdropMode.dottedWave]: Used across the app — undulating dotted wave streams
///   arranged along overlapping PS3-style curved ribbon paths.
/// - [AmbientBackdropMode.silkWave]: Used inside the expanded PlayerScreen — subtle translucent
///   PS3 XMB silk ribbon waves synchronized to track BPM.
///
/// Components / Classes / Functions:
/// - AmbientBackdropMode: Visual backdrop rendering style selector.
/// - _XmbRibbonSpec: Immutable geometric & optical definition for a wave ribbon.
/// - AmbientParticlesPainter: CustomPainter rendering dotted wave streams or XMB silk waves.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:project_anima/features/ambient_particles/models/ambient_particle.dart';

/// Visual mode for [AmbientParticlesPainter] and [AmbientParticlesCanvas].
enum AmbientBackdropMode {
  /// Flowing wave contours formed out of softly glowing `#5BABCE` points (used across app screens).
  dottedWave,

  /// Softly translucent PS3 XMB silk wave ribbons (used exclusively inside maximized PlayerScreen).
  silkWave,
}

/// Immutable geometric and optical parameters for a single XMB wave ribbon.
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
  final int dotCount;
  final double dotDriftSpeed;

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
    required this.dotCount,
    required this.dotDriftSpeed,
  });
}

/// Renders either curved dotted wave streams ([AmbientBackdropMode.dottedWave]) or
/// translucent PS3 XMB silk waves ([AmbientBackdropMode.silkWave]) in `#5BABCE`.
class AmbientParticlesPainter extends CustomPainter {
  /// Kept for backward API compatibility.
  final List<AmbientParticle> particles;

  /// Dynamic accent color (`#5BABCE` in canvas).
  final Color accentColor;

  /// Whether active palette is dark mode (adapts opacity bounds & blend mode).
  final bool isDark;

  /// Animation tick sequence ensuring deterministic repaints.
  final int repaintToken;

  /// Backdrop style mode (`dottedWave` across app screens, `silkWave` in expanded PlayerScreen).
  final AmbientBackdropMode mode;

  /// Fallback static phase (radians) when [waveTimeProvider] is omitted.
  final double waveTime;

  /// Live time reader evaluated on every `paint()` tick triggered by [super.repaint].
  final double Function()? waveTimeProvider;

  /// Live beat phase reader evaluated on every `paint()` tick for subtle rhythmic pulsing.
  final double Function()? beatPhaseProvider;

  /// Live playback status reader for subtle beat reactivity.
  final bool Function()? isPlayingProvider;

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
  final Paint _dotHaloPaint = Paint()..isAntiAlias = true;
  final Paint _dotCorePaint = Paint()..isAntiAlias = true;

  static const int _ribbonSteps = 76;
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

  /// Overlapping wave ribbons shared between translucent silk (PlayerScreen) and dotted waves (app).
  static const List<_XmbRibbonSpec> _ribbons = [
    // 1. Broad diagonal wave sweeping upper-left to bottom-right
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
      dotCount: 54,
      dotDriftSpeed: 0.018,
    ),
    // 2. Main foreground folding wave with wide luminous contour
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
      dotCount: 64,
      dotDriftSpeed: 0.024,
    ),
    // 3. Intersecting upper-center ribbon pinch
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
      dotCount: 50,
      dotDriftSpeed: -0.016,
    ),
  ];

  AmbientParticlesPainter({
    super.repaint,
    this.particles = const [],
    required this.accentColor,
    required this.isDark,
    required this.repaintToken,
    this.mode = AmbientBackdropMode.dottedWave,
    this.waveTime = 0.0,
    this.waveTimeProvider,
    this.beatPhaseProvider,
    this.isPlayingProvider,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double activeTime = waveTimeProvider?.call() ?? waveTime;
    final double beatPhase = beatPhaseProvider?.call() ?? 0.0;
    final bool isPlaying = isPlayingProvider?.call() ?? false;
    final double beatPulse = isPlaying ? (0.5 + 0.5 * math.sin(beatPhase)) : 0.0;

    if (mode == AmbientBackdropMode.silkWave) {
      for (int i = 0; i < _ribbons.length; i++) {
        _paintSilkRibbon(canvas, size, _ribbons[i], activeTime, beatPulse);
      }
    } else {
      for (int i = 0; i < _ribbons.length; i++) {
        _paintDottedWaveRibbon(canvas, size, _ribbons[i], activeTime, beatPulse);
      }
    }
  }

  /// Evaluates `(pCrest, pTail, tailSpread, scaleDim)` along a wave ribbon at parameter `u`.
  ({Offset crest, Offset tail, double spread, double scaleDim}) _evaluateRibbonPoint(
    Size size,
    _XmbRibbonSpec spec,
    double u,
    double t,
    double beatPulse,
  ) {
    final double w = size.width;
    final double h = size.height;
    final double scaleDim = math.min(w, h) * 0.72 + math.max(w, h) * 0.28;

    final Offset start = Offset(spec.startNorm.dx * w, spec.startNorm.dy * h);
    final Offset end = Offset(spec.endNorm.dx * w, spec.endNorm.dy * h);
    final Offset axis = end - start;
    final double axisLen = axis.distance;
    if (axisLen <= 1e-3) {
      return (crest: Offset.zero, tail: Offset.zero, spread: 0.0, scaleDim: scaleDim);
    }

    final Offset dir = axis / axisLen;
    final Offset normal = Offset(-dir.dy, dir.dx);
    final Offset spineBase = Offset.lerp(start, end, u)!;

    final double beatSwell = 1.0 + 0.08 * beatPulse;
    final double spineWave = (spec.spineAmp1 *
                beatSwell *
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
    final Offset pTail = spine + normal * (crestOff - tailSpread) + dir * tailTan;

    return (crest: pCrest, tail: pTail, spread: tailSpread, scaleDim: scaleDim);
  }

  /// Renders wave contours as multi-lane streams of luminous `#5BABCE` dots ("ondas de puntos").
  void _paintDottedWaveRibbon(
    Canvas canvas,
    Size size,
    _XmbRibbonSpec spec,
    double t,
    double beatPulse,
  ) {
    final Color baseColor = isDark
        ? accentColor
        : Color.lerp(accentColor, const Color(0xFF2E7EA3), 0.20)!;
    final Color glintColor = isDark
        ? Color.lerp(accentColor, Colors.white, 0.35)!
        : baseColor;

    // 4 closely aligned filament dot lanes across each wave so curves read clearly as dotted waves
    const List<({double laneFrac, double alphaScale, double baseRadius, int skipMod})> lanes = [
      (laneFrac: 0.00, alphaScale: 1.00, baseRadius: 1.75, skipMod: 1),
      (laneFrac: 0.09, alphaScale: 0.72, baseRadius: 1.40, skipMod: 1),
      (laneFrac: 0.22, alphaScale: 0.45, baseRadius: 1.15, skipMod: 1),
      (laneFrac: 0.40, alphaScale: 0.24, baseRadius: 0.90, skipMod: 2),
    ];

    final double baseOpacity = isDark ? 0.30 : 0.24;
    final double beatGlow = 1.0 + 0.16 * beatPulse;

    for (int laneIdx = 0; laneIdx < lanes.length; laneIdx++) {
      final lane = lanes[laneIdx];
      final int count = spec.dotCount;
      final double laneShift = laneIdx * 0.008;

      for (int k = 0; k < count; k++) {
        if (lane.skipMod > 1 && k % lane.skipMod != 0) continue;

        double u = ((k / count) + laneShift + t * spec.dotDriftSpeed) % 1.0;
        if (u < 0.0) u += 1.0;

        final pt = _evaluateRibbonPoint(size, spec, u, t, beatPulse);
        final Offset pos = Offset.lerp(pt.crest, pt.tail, lane.laneFrac)!;

        if (pos.dx < -16.0 ||
            pos.dx > size.width + 16.0 ||
            pos.dy < -16.0 ||
            pos.dy > size.height + 16.0) {
          continue;
        }

        // Smooth edge fade + subtle rhythmic shimmer along each dotted wave filament
        final double edgeFade = math.sin(u * math.pi).clamp(0.0, 1.0);
        final double shimmer =
            0.72 + 0.28 * math.sin(u * 10.0 * math.pi - t * 1.6 + laneIdx * 1.4);
        final double alpha =
            (baseOpacity * lane.alphaScale * edgeFade * shimmer * beatGlow).clamp(0.0, 0.55);
        if (alpha <= 0.01) continue;

        final double radius = lane.baseRadius * (0.85 + 0.25 * shimmer);

        _dotHaloPaint.color = baseColor.withValues(alpha: (alpha * 0.30).clamp(0.0, 1.0));
        canvas.drawCircle(pos, radius * 2.1, _dotHaloPaint);

        _dotCorePaint.color = glintColor.withValues(alpha: alpha);
        canvas.drawCircle(pos, radius, _dotCorePaint);
      }
    }
  }

  /// Renders smooth translucent PS3 XMB silk waves exclusively inside the maximized player.
  void _paintSilkRibbon(
    Canvas canvas,
    Size size,
    _XmbRibbonSpec spec,
    double t,
    double beatPulse,
  ) {
    final Color baseVeilColor = isDark
        ? Color.lerp(accentColor, const Color(0xFF1A4356), 0.22)!
        : Color.lerp(accentColor, const Color(0xFF2E7EA3), 0.14)!;
    final Color crestHighlightColor = isDark
        ? Color.lerp(accentColor, Colors.white, 0.32 + 0.08 * beatPulse)!
        : Color.lerp(accentColor, const Color(0xFF246F92), 0.22)!;
    final Color crestEdgeColor =
        Color.lerp(baseVeilColor, crestHighlightColor, 0.42)!;

    final double beatMul = 1.0 + 0.14 * beatPulse;
    final double veilPeak = (isDark ? spec.veilAlphaDark : spec.veilAlphaLight) * beatMul;
    final double crestPeak =
        (isDark ? spec.crestAlphaDark : spec.crestAlphaLight) * beatMul;

    _crestPath.reset();

    for (int i = 0; i < _cols; i++) {
      final double u = i / _ribbonSteps;
      final pt = _evaluateRibbonPoint(size, spec, u, t, beatPulse);
      final Offset pCrest = pt.crest;
      final Offset pTail = pt.tail;

      final Offset pMid1 = Offset.lerp(pCrest, pTail, 0.24)!;
      final Offset pMid2 = Offset.lerp(pCrest, pTail, 0.62)!;

      _crestPts[i] = pCrest;
      _mid1Pts[i] = pMid1;
      _mid2Pts[i] = pMid2;
      _tailPts[i] = pTail;

      final double spreadNorm =
          (pt.spread.abs() / (pt.scaleDim * 0.28)).clamp(0.15, 1.4);
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
        oldDelegate.beatPhaseProvider != beatPhaseProvider ||
        oldDelegate.isPlayingProvider != isPlayingProvider ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.particles != particles;
  }
}

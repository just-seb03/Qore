/// File: ambient_particles_feature_test.dart
/// Description: Comprehensive test suite for the PS3-style ambient particles background feature.
/// Tests physics simulation, lifecycle coordination, expanded player pausing, painter rendering,
/// and widget hierarchy integration.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/player/screens/player_screen.dart';

void main() {
  group('AmbientParticle Model Tests', () {
    test('AmbientParticle.random generates valid non-null coordinates within boundaries', () {
      final random = math.Random(42);
      final particle = AmbientParticle.random(
        width: 400.0,
        height: 800.0,
        random: random,
      );

      expect(particle.x, inInclusiveRange(0.0, 400.0));
      expect(particle.y, inInclusiveRange(0.0, 800.0));
      expect(particle.radius, greaterThan(0.5));
      expect(particle.vy, greaterThan(5.0));
      expect(particle.baseAlpha, inInclusiveRange(0.05, 0.50));
      expect(particle.layer, inInclusiveRange(0, 2));
    });

    test('AmbientParticle.update shifts y upwards and calculates sine-wave x', () {
      final particle = AmbientParticle(
        x: 100.0,
        y: 500.0,
        baseX: 100.0,
        vy: 20.0,
        radius: 2.0,
        waveAmplitude: 15.0,
        waveFrequency: 1.0,
        wavePhase: 0.0,
        pulseFrequency: 1.0,
        pulsePhase: 0.0,
        baseAlpha: 0.20,
        layer: 1,
      );

      particle.update(
        dt: 1.0,
        width: 400.0,
        height: 800.0,
        speedMultiplier: 1.0,
      );

      // Moved upwards
      expect(particle.y, equals(480.0));
      // Phase advanced by 1.0 rad
      expect(particle.wavePhase, equals(1.0));
      // Oscillated horizontally around 100
      expect(particle.x, equals(100.0 + math.sin(1.0) * 15.0));
    });

    test('AmbientParticle wraps around top when exiting viewport', () {
      final particle = AmbientParticle(
        x: 100.0,
        y: -100.0,
        baseX: 100.0,
        vy: 20.0,
        radius: 2.0,
        waveAmplitude: 15.0,
        waveFrequency: 1.0,
        wavePhase: 0.0,
        pulseFrequency: 1.0,
        pulsePhase: 0.0,
        baseAlpha: 0.20,
        layer: 1,
      );

      particle.update(
        dt: 0.01,
        width: 400.0,
        height: 800.0,
        speedMultiplier: 1.0,
      );

      // Y was recycled to near bottom (height + margin)
      expect(particle.y, greaterThan(750.0));
    });

    test('AmbientParticle.computeAlpha adapts between dark and light modes', () {
      final particle = AmbientParticle(
        x: 100.0,
        y: 200.0,
        baseX: 100.0,
        vy: 20.0,
        radius: 2.0,
        waveAmplitude: 15.0,
        waveFrequency: 1.0,
        wavePhase: 0.0,
        pulseFrequency: 1.0,
        pulsePhase: 0.0,
        baseAlpha: 0.20,
        layer: 1,
      );

      final darkAlpha = particle.computeAlpha(isDark: true);
      final lightAlpha = particle.computeAlpha(isDark: false);

      expect(darkAlpha, greaterThan(0.0));
      expect(lightAlpha, greaterThan(0.0));
      // Light alpha is tempered to ensure high subtlety
      expect(lightAlpha, lessThan(darkAlpha));
    });
  });

  group('AmbientParticlesController Lifecycle Tests', () {
    late AmbientParticlesController controller;

    setUp(() {
      controller = AmbientParticlesController.instance;
      controller.setEnabled(true);
      controller.setExpandedPlayerVisible(false);
      controller.setAppPaused(false);
      controller.setSpeedMultiplier(1.0);
      controller.setParticleCount(32);
    });

    test('isSimulating reflects compound lifecycle states', () {
      expect(controller.isSimulating, isTrue);

      controller.setExpandedPlayerVisible(true);
      expect(controller.isSimulating, isTrue);

      controller.setExpandedPlayerVisible(false);
      expect(controller.isSimulating, isTrue);

      controller.setAppPaused(true);
      expect(controller.isSimulating, isFalse);

      controller.setAppPaused(false);
      expect(controller.isSimulating, isTrue);

      controller.setEnabled(false);
      expect(controller.isSimulating, isFalse);
    });

    test('initializeParticles sets up requested population size', () {
      controller.initializeParticles(const Size(400, 800));
      expect(controller.particles.length, equals(32));
    });

    test('step updates repaintToken, waveTime, and particle coordinates when simulating', () {
      controller.initializeParticles(const Size(400, 800));
      final initialToken = controller.repaintToken;
      final initialWaveTime = controller.waveTime;
      final initialY = controller.particles.first.y;

      controller.step(0.03, const Size(400, 800));

      expect(controller.repaintToken, equals(initialToken + 1));
      expect(controller.waveTime, greaterThan(initialWaveTime));
      expect(controller.particles.first.y, isNot(equals(initialY)));
    });

    test('step does not advance physics when isSimulating is false', () {
      controller.initializeParticles(const Size(400, 800));
      controller.setAppPaused(true);
      final initialToken = controller.repaintToken;
      final initialY = controller.particles.first.y;

      controller.step(0.03, const Size(400, 800));

      expect(controller.repaintToken, equals(initialToken));
      expect(controller.particles.first.y, equals(initialY));
      controller.setAppPaused(false);
    });
  });

  group('AmbientParticlesPainter Tests', () {
    test('paints PS3 XMB silk waves without particle dots and animates via waveTimeProvider', () async {
      double liveTime = 0.0;
      final painter = AmbientParticlesPainter(
        particles: const [],
        accentColor: const Color(0xFF5BABCE),
        isDark: true,
        repaintToken: 1,
        mode: AmbientBackdropMode.silkWave,
        waveTimeProvider: () => liveTime,
      );

      Future<List<int>> renderBytes() async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        painter.paint(canvas, const Size(200, 400));
        final pic = recorder.endRecording();
        final img = await pic.toImage(200, 400);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
        return bytes!.buffer.asUint8List();
      }

      final frame0 = await renderBytes();
      liveTime = 2.5;
      final frame1 = await renderBytes();

      expect(frame0, isNotEmpty);
      // Same painter instance must produce visibly different pixels as waveTime advances
      expect(frame1, isNot(equals(frame0)));
    });

    test('shouldRepaint detects repaintToken, waveTime, and color alterations', () {
      final p1 = AmbientParticlesPainter(
        particles: [],
        accentColor: const Color(0xFF5BABCE),
        isDark: true,
        repaintToken: 1,
        waveTime: 0.0,
      );
      final p2 = AmbientParticlesPainter(
        particles: [],
        accentColor: const Color(0xFF5BABCE),
        isDark: true,
        repaintToken: 2,
        waveTime: 0.0,
      );
      final p3 = AmbientParticlesPainter(
        particles: [],
        accentColor: Colors.red,
        isDark: true,
        repaintToken: 1,
        waveTime: 0.0,
      );
      final p4 = AmbientParticlesPainter(
        particles: [],
        accentColor: const Color(0xFF5BABCE),
        isDark: true,
        repaintToken: 1,
        waveTime: 0.5,
      );

      expect(p2.shouldRepaint(p1), isTrue);
      expect(p3.shouldRepaint(p1), isTrue);
      expect(p4.shouldRepaint(p1), isTrue);
      expect(p1.shouldRepaint(p1), isFalse);
    });
  });

  group('AmbientParticlesBackground & Canvas Widget Tests', () {
    testWidgets('AmbientParticlesBackground mounts backdrop and renders child content',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AmbientParticlesBackground(
            child: Scaffold(
              body: Center(
                child: Text('Foreground Test'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Foreground Test'), findsOneWidget);
      expect(find.byType(AmbientParticlesCanvas), findsOneWidget);
    });

    testWidgets('AmbientParticlesCanvas renders SizedBox.shrink when disabled',
        (tester) async {
      final controller = AmbientParticlesController.instance;
      controller.setEnabled(false);

      await tester.pumpWidget(
        MaterialApp(
          home: AmbientParticlesBackground(
            controller: controller,
            child: const Scaffold(
              body: Center(child: Text('Hello')),
            ),
          ),
        ),
      );

      final particlePaintFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is AmbientParticlesPainter,
      );

      expect(particlePaintFinder, findsNothing);

      // Resume
      controller.setEnabled(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(particlePaintFinder, findsOneWidget);
    });

    testWidgets('PlayerScreen correctly notifies AmbientParticlesController on mount and unmount',
        (tester) async {
      final controller = AmbientParticlesController.instance;
      controller.setExpandedPlayerVisible(false);
      expect(controller.isExpandedPlayerVisible, isFalse);

      await tester.pumpWidget(
        const MaterialApp(
          home: PlayerScreen(),
        ),
      );
      await tester.pump(); // Allow postFrameCallback to complete

      // Mounted PlayerScreen sets expanded player visible and keeps particles simulating
      expect(controller.isExpandedPlayerVisible, isTrue);
      expect(controller.isSimulating, isTrue);
      expect(find.byType(AmbientParticlesCanvas), findsOneWidget);

      // Unmount
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Closed')),
        ),
      );

      // Disposed PlayerScreen clears expanded player flag
      expect(controller.isExpandedPlayerVisible, isFalse);
      expect(controller.isSimulating, isTrue);
    });
  });
}

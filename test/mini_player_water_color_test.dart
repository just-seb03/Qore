/// File: mini_player_water_color_test.dart
/// Description: Unit and widget pixel tests verifying that MiniPlayer liquid water waves
/// adopt the active track's dynamic cover color (falling back to #5BABCE when no cover exists).
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/artwork_color_extractor.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/controllers/theme_controller.dart';
import 'package:project_anima/features/ambient_particles/controllers/ambient_particles_controller.dart';
import 'package:project_anima/features/player/components/mini_player.dart';

class _FakeMiniPlayerController extends ChangeNotifier implements PlaybackController {
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();

  Song? _song;
  bool _playing = false;
  final Duration _duration = const Duration(seconds: 200);

  void setState({Song? song, bool playing = false}) {
    _song = song;
    _playing = playing;
    notifyListeners();
  }

  void emitPosition(Duration position) {
    _positionController.add(position);
  }

  @override
  Song? get currentSong => _song;

  @override
  bool get isPlaying => _playing;

  @override
  Duration get duration => _duration;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Future<void> dispose() async {
    await _positionController.close();
    super.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<({double avgR, double avgG, double avgB, double avgA})> _sampleBottomBand(
  CustomPainter painter,
) async {
  const size = Size(320, 64);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = byteData!.buffer.asUint8List();

  double sumR = 0;
  double sumG = 0;
  double sumB = 0;
  double sumA = 0;
  int count = 0;

  // Sample bottom band (y in 48..60) completely submerged when progress >= 0.5
  for (int y = 48; y < 60; y++) {
    for (int x = 20; x < 300; x++) {
      final idx = (y * size.width.toInt() + x) * 4;
      sumR += bytes[idx];
      sumG += bytes[idx + 1];
      sumB += bytes[idx + 2];
      sumA += bytes[idx + 3];
      count++;
    }
  }

  return (
    avgR: sumR / count,
    avgG: sumG / count,
    avgB: sumB / count,
    avgA: sumA / count,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('MiniPlayer.resolveWaterColor Tests', () {
    test('preserves cyan hue for #5BABCE default fallback and clamps extreme monochrome covers', () {
      final darkFallback = MiniPlayer.resolveWaterColor(
        ArtworkColorExtractor.defaultWaveColor,
        isDark: true,
      );
      final lightFallback = MiniPlayer.resolveWaterColor(
        ArtworkColorExtractor.defaultWaveColor,
        isDark: false,
      );
      expect(HSLColor.fromColor(darkFallback).hue, closeTo(198.0, 2.0));
      expect(HSLColor.fromColor(lightFallback).hue, closeTo(198.0, 2.0));

      final liftedBlack = MiniPlayer.resolveWaterColor(
        const Color(0xFF040406),
        isDark: true,
      );
      expect(HSLColor.fromColor(liftedBlack).lightness, greaterThanOrEqualTo(0.43));

      final softenedWhite = MiniPlayer.resolveWaterColor(
        const Color(0xFFFCFCFE),
        isDark: false,
      );
      expect(HSLColor.fromColor(softenedWhite).lightness, lessThanOrEqualTo(0.62));
    });
  });

  group('MiniPlayer Dynamic Cover Water Color Widget Tests', () {
    late _FakeMiniPlayerController fakeController;
    final sampleSong = Song(
      mediaStoreId: 9001,
      title: 'Tinted Tide',
      artist: 'Color Synth',
      album: 'Spectrum',
      duration: 200000,
      path: '/music/tinted_tide.mp3',
      dateModified: 1700000000,
    );

    setUp(() {
      fakeController = _FakeMiniPlayerController();
      fakeController.setState(song: sampleSong, playing: false);
      ThemeController.instance.setDarkMode(true);
      AmbientParticlesController.instance.syncWithPlayback(
        bpm: 120.0,
        isPlaying: false,
        waveColor: ArtworkColorExtractor.defaultWaveColor,
      );
    });

    tearDown(() async {
      ThemeController.instance.setDarkMode(true);
      AmbientParticlesController.instance.syncWithPlayback(
        bpm: null,
        isPlaying: false,
        waveColor: ArtworkColorExtractor.defaultWaveColor,
      );
      await fakeController.dispose();
    });

    testWidgets('uses #5BABCE fallback color and animates smoothly to active cover color',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            bottomNavigationBar: MiniPlayer(controller: fakeController),
          ),
        ),
      );

      fakeController.emitPosition(const Duration(seconds: 120)); // 60% filled
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final paintFinder = find.byKey(const ValueKey('mini_player_liquid_paint'));
      expect(paintFinder, findsOneWidget);

      final fallbackSample = (await tester.runAsync(
        () => _sampleBottomBand(tester.widget<CustomPaint>(paintFinder).painter!),
      ))!;
      expect(fallbackSample.avgA, greaterThan(0.0));
      // #5BABCE is cool cyan: blue channel clearly outweighs red channel
      expect(fallbackSample.avgB, greaterThan(fallbackSample.avgR * 1.4));

      // Switch active track wave color to warm crimson cover color
      AmbientParticlesController.instance.setWaveColor(const Color(0xFFE53935));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      final crimsonSample = (await tester.runAsync(
        () => _sampleBottomBand(tester.widget<CustomPaint>(paintFinder).painter!),
      ))!;
      expect(crimsonSample.avgA, greaterThan(0.0));
      // Crimson cover water: red channel clearly outweighs blue channel
      expect(crimsonSample.avgR, greaterThan(crimsonSample.avgB * 1.5));

      // Switch to Light mode and ensure water remains visibly crimson-tinted
      ThemeController.instance.setDarkMode(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      final lightCrimsonSample = (await tester.runAsync(
        () => _sampleBottomBand(tester.widget<CustomPaint>(paintFinder).painter!),
      ))!;
      expect(lightCrimsonSample.avgA, greaterThan(0.0));
      expect(lightCrimsonSample.avgR, greaterThan(lightCrimsonSample.avgB * 1.5));
    });
  });
}

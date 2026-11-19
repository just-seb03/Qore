/// File: bpm_analysis_and_wave_test.dart
/// Description: Unit and widget tests covering BPM signal onset detection, WAV PCM decoding,
/// octave-equivalent visual wave speed mapping (e.g. 300 BPM -> 150 BPM equivalent),
/// SQLite BPM schema/backfill via MusicIndexer, and split dottedWave vs silkWave backdrop modes.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/scanner/bpm_analyzer.dart';
import 'package:project_anima/core/scanner/music_indexer.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/player/screens/player_screen.dart';

Uint8List _buildClickWavBytes({
  required double bpm,
  int sampleRate = 8000,
  int seconds = 10,
}) {
  final int totalSamples = sampleRate * seconds;
  final int beatIntervalSamples = (sampleRate * 60.0 / bpm).round();
  final int clickSamples = (sampleRate * 0.025).round(); // 25ms percussive click

  final Int16List pcm = Int16List(totalSamples);
  for (int i = 0; i < totalSamples; i++) {
    final int posInBeat = i % beatIntervalSamples;
    if (posInBeat < clickSamples) {
      final double env = 1.0 - (posInBeat / clickSamples);
      final double tone = math.sin(2.0 * math.pi * 220.0 * i / sampleRate);
      pcm[i] = (env * tone * 26000).round();
    } else {
      pcm[i] = 0;
    }
  }

  final int dataSize = totalSamples * 2;
  final ByteData header = ByteData(44);
  header.setUint32(0, 0x52494646, Endian.big); // "RIFF"
  header.setUint32(4, 36 + dataSize, Endian.little);
  header.setUint32(8, 0x57415645, Endian.big); // "WAVE"
  header.setUint32(12, 0x666D7420, Endian.big); // "fmt "
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, 1, Endian.little); // Mono
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  header.setUint32(36, 0x64617461, Endian.big); // "data"
  header.setUint32(40, dataSize, Endian.little);

  final BytesBuilder builder = BytesBuilder();
  builder.add(header.buffer.asUint8List());
  builder.add(pcm.buffer.asUint8List());
  return builder.toBytes();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppDatabase.initializeFfiIfNeeded();
  });

  group('BpmAnalyzer Tempo Detection & Speed Mapping Tests', () {
    test('detects BPM accurately from synthetic 128 BPM onset envelope', () {
      const double frameRate = 100.0; // 10ms frames
      const int frames = 1200; // 12 seconds
      final double beatPeriodFrames = 60.0 * frameRate / 128.0; // ~46.875 frames

      final List<double> energies = List<double>.filled(frames, 0.02);
      for (double b = 5.0; b < frames - 3; b += beatPeriodFrames) {
        final int idx = b.round();
        energies[idx] = 0.85;
        if (idx + 1 < frames) energies[idx + 1] = 0.45;
      }

      final detected = BpmAnalyzer.estimateBpmFromOnsetEnvelope(
        energies,
        frameRateHz: frameRate,
      );
      expect(detected, isNotNull);
      expect(detected!, closeTo(128.0, 2.5));
    });

    test('decodes WAV PCM waveform and detects 120 BPM click track', () async {
      final tempDir = await Directory.systemTemp.createTemp('bpm_wav_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final wavFile = File(p.join(tempDir.path, 'pulse_120.wav'));
      await wavFile.writeAsBytes(_buildClickWavBytes(bpm: 120.0));

      final bpm = await BpmAnalyzer.analyzeAudioFile(wavFile.path, durationMs: 10000);
      expect(bpm, isNotNull);
      expect(bpm!, closeTo(120.0, 2.5));
    });

    test('maps extreme BPM (e.g. 300 BPM) to smooth octave-equivalent visual speed', () {
      expect(BpmAnalyzer.effectiveVisualBpm(300.0), equals(150.0));
      expect(BpmAnalyzer.effectiveVisualBpm(240.0), equals(120.0));
      expect(BpmAnalyzer.effectiveVisualBpm(40.0), equals(80.0));

      final slowSpeed = BpmAnalyzer.mapBpmToWaveSpeed(70.0);
      final midSpeed = BpmAnalyzer.mapBpmToWaveSpeed(115.0);
      final fastSpeed = BpmAnalyzer.mapBpmToWaveSpeed(150.0);
      final extreme300Speed = BpmAnalyzer.mapBpmToWaveSpeed(300.0);

      expect(slowSpeed, lessThan(midSpeed));
      expect(midSpeed, closeTo(1.0, 0.01));
      expect(fastSpeed, greaterThan(midSpeed));
      // 300 BPM renders at the exact 150 BPM equivalent, bounded cleanly (< 1.48)
      expect(extreme300Speed, closeTo(fastSpeed, 0.001));
      expect(extreme300Speed, inInclusiveRange(0.55, 1.48));
    });
  });

  group('SQLite BPM Schema & MusicIndexer Re-analysis Tests', () {
    late AppDatabase appDatabase;
    late SongDao songDao;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('bpm_db_test_');
      appDatabase = AppDatabase.instance;
      await appDatabase.initDatabase(customPath: p.join(tempDir.path, 'bpm_test.db'));
      songDao = SongDao(appDatabase: appDatabase);
    });

    tearDown(() async {
      await appDatabase.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('MusicIndexer.analyzeMissingBpms persists BPM values into SQLite songs.bpm column', () async {
      final wavFile = File(p.join(tempDir.path, 'track_124.wav'));
      await wavFile.writeAsBytes(_buildClickWavBytes(bpm: 124.0));

      await songDao.syncDelta(
        toInsertOrUpdate: [
          Song(
            mediaStoreId: 777,
            title: 'Pulse Track',
            artist: 'Tester',
            album: 'Beats',
            duration: 10000,
            path: wavFile.path,
            dateModified: 1700000000,
          ),
        ],
        toDelete: [],
      );

      final before = await songDao.getSongByMediaStoreId(777);
      expect(before?.bpm, isNull);

      final indexer = MusicIndexer(songDao: songDao);
      final analyzed = await indexer.analyzeMissingBpms();
      expect(analyzed, 1);

      final after = await songDao.getSongByMediaStoreId(777);
      expect(after?.bpm, isNotNull);
      expect(after!.bpm!, closeTo(124.0, 2.5));
      expect(await songDao.isBpmBackfilled(), isTrue);
    });
  });

  group('Split Backdrop Modes & BPM Speed Integration Tests', () {
    testWidgets('PlayerScreen uses silkWave exclusively while AmbientParticlesBackground uses particles',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AmbientParticlesBackground(
            child: Scaffold(body: Text('App Screen')),
          ),
        ),
      );
      final appCanvas = tester.widget<AmbientParticlesCanvas>(find.byType(AmbientParticlesCanvas));
      expect(appCanvas.mode, AmbientBackdropMode.particles);

      await tester.pumpWidget(
        const MaterialApp(
          home: PlayerScreen(),
        ),
      );
      await tester.pump();
      final playerCanvas =
          tester.widget<AmbientParticlesCanvas>(find.byType(AmbientParticlesCanvas));
      expect(playerCanvas.mode, AmbientBackdropMode.silkWave);
    });

    test('silkWave animates smoothly over waveTime and stepFrame deduplicates identical frame stamps', () async {
      Future<List<int>> renderBytes(AmbientBackdropMode mode, double t) async {
        final painter = AmbientParticlesPainter(
          particles: [
            AmbientParticle(
              x: 100.0,
              y: 150.0,
              baseX: 100.0,
              vy: 20.0,
              radius: 3.0,
              waveAmplitude: 10.0,
              waveFrequency: 1.0,
              wavePhase: 0.0,
              pulseFrequency: 1.0,
              pulsePhase: 0.0,
              baseAlpha: 0.25,
              layer: 2,
            ),
          ],
          accentColor: const Color(0xFF5BABCE),
          isDark: true,
          repaintToken: 1,
          mode: mode,
          waveTime: t,
        );
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        painter.paint(canvas, const Size(240, 480));
        final pic = recorder.endRecording();
        final img = await pic.toImage(240, 480);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
        return bytes!.buffer.asUint8List();
      }

      final silk0 = await renderBytes(AmbientBackdropMode.silkWave, 0.0);
      final silk1 = await renderBytes(AmbientBackdropMode.silkWave, 1.8);
      final dots = await renderBytes(AmbientBackdropMode.particles, 0.0);

      expect(silk1, isNot(equals(silk0)));
      expect(dots, isNot(equals(silk0)));

      // Verify stepFrame skips duplicate calls for the same vsync frameStamp
      final ctrl = AmbientParticlesController.instance;
      ctrl.setEnabled(true);
      ctrl.setAppPaused(false);
      ctrl.initializeParticles(const Size(400, 800));
      final double tBefore = ctrl.waveTime;
      const Duration stamp = Duration(milliseconds: 12345);
      ctrl.stepFrame(0.016, const Size(400, 800), stamp);
      final double tAfterFirst = ctrl.waveTime;
      ctrl.stepFrame(0.016, const Size(400, 800), stamp);
      expect(tAfterFirst, greaterThan(tBefore));
      expect(ctrl.waveTime, equals(tAfterFirst));
    });
  });
}


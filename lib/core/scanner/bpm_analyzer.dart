/// File: bpm_analyzer.dart
/// Description: Audio BPM (tempo) extraction, signal onset-flux estimation, and
/// perceptually bounded octave-equivalent wave speed mapping.
///
/// Components / Classes / Functions:
/// - BpmAnalyzer: Multi-strategy BPM resolver (ID3/Vorbis tags, Android MediaCodec native PCM,
///   desktop WAV PCM onset analysis) and visual speed scaling helpers.
library;

import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/services.dart';

/// Pure-Dart isolate worker verifying existence and reading embedded BPM tags.
({bool exists, double? tagBpm}) _probeAudioFileForBpmIsolate(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return (exists: false, tagBpm: null);
  }
  return (exists: true, tagBpm: BpmAnalyzer.extractEmbeddedBpmTag(file));
}

/// Analyzes song tempo (BPM) from metadata tags or decoded audio PCM waveforms,
/// and converts raw BPM values into smooth octave-equivalent wave speeds.
abstract final class BpmAnalyzer {
  static const MethodChannel _mediaStoreChannel =
      MethodChannel('project_anima/media_store');

  /// Minimum and maximum realistic musical BPM bounds for raw metadata/signal parsing.
  static const double minValidBpm = 35.0;
  static const double maxValidBpm = 350.0;

  /// Canonical visual tempo pocket used so extreme BPMs (e.g. 300 BPM) fold
  /// into their musical half-time equivalent (150 BPM).
  static const double minVisualBpm = 55.0;
  static const double maxVisualBpm = 180.0;
  static const double baselineVisualBpm = 115.0;

  /// Resolves BPM using embedded tags first (in a background isolate),
  /// falling back to platform PCM audio analysis or windowed WAV decoding.
  static Future<double?> analyzeAudioFile(
    String path, {
    int durationMs = 0,
  }) async {
    if (path.isEmpty) return null;

    // 1. Fast path inside background isolate: file existence + embedded TBPM / BPM / TEMPO tag
    final probe = await Isolate.run(() => _probeAudioFileForBpmIsolate(path));
    if (!probe.exists) return null;
    if (probe.tagBpm != null) return probe.tagBpm;

    // 2. Android native MediaExtractor + MediaCodec fast PCM decode + beat estimation
    if (Platform.isAndroid) {
      try {
        final double? nativeBpm = await _mediaStoreChannel.invokeMethod<double>(
          'analyzeBpm',
          {'path': path, 'durationMs': durationMs},
        );
        return _sanitizeBpm(nativeBpm);
      } catch (_) {
        // Channel unavailable or corrupt audio stream
      }
    }

    // 3. Desktop/fallback pure-Dart WAV PCM waveform analysis off the UI isolate
    if (path.toLowerCase().endsWith('.wav')) {
      return Isolate.run(() => analyzeWavPcm(File(path)));
    }

    return null;
  }

  /// Extracts BPM from ID3 `TBPM`, custom frames, or Vorbis `BPM`/`TEMPO` tags.
  static double? extractEmbeddedBpmTag(File file) {
    try {
      final tags = readAllMetadata(file, getImage: false);
      if (tags is Mp3Metadata) {
        final direct = _parseBpmString(tags.bpm);
        if (direct != null) return direct;
        for (final key in const ['BPM', 'TBPM', 'TEMPO', 'bpm', 'tempo']) {
          final parsed = _parseBpmString(tags.customMetadata[key]);
          if (parsed != null) return parsed;
        }
      } else if (tags is VorbisMetadata) {
        for (final entry in tags.unknowns.entries) {
          final lowerKey = entry.key.trim().toLowerCase();
          if (lowerKey == 'bpm' || lowerKey == 'tbpm' || lowerKey == 'tempo') {
            final parsed = _parseBpmString(entry.value);
            if (parsed != null) return parsed;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Decodes a standard RIFF/WAVE PCM file into ~10ms RMS energy frames and estimates BPM
  /// using bounded [RandomAccessFile] reads instead of loading the entire audio file.
  static double? analyzeWavPcm(File file, {int maxSeconds = 22}) {
    RandomAccessFile? raf;
    try {
      raf = file.openSync(mode: FileMode.read);
      final int fileLength = raf.lengthSync();
      if (fileLength < 44) return null;

      final header = raf.readSync(12);
      if (header.lengthInBytes < 12) return null;
      final headerData = ByteData.sublistView(header);
      // Verify "RIFF" and "WAVE"
      if (headerData.getUint32(0, Endian.big) != 0x52494646 ||
          headerData.getUint32(8, Endian.big) != 0x57415645) {
        return null;
      }

      int offset = 12;
      int audioFormat = 1;
      int channels = 1;
      int sampleRate = 44100;
      int bitsPerSample = 16;
      int? dataStart;
      int dataSize = 0;

      while (offset + 8 <= fileLength) {
        raf.setPositionSync(offset);
        final chunkHdr = raf.readSync(8);
        if (chunkHdr.lengthInBytes < 8) break;
        final chunkHdrData = ByteData.sublistView(chunkHdr);
        final chunkId = chunkHdrData.getUint32(0, Endian.big);
        final chunkSize = chunkHdrData.getUint32(4, Endian.little);
        final bodyStart = offset + 8;

        if (chunkId == 0x666D7420 && chunkSize >= 16 && bodyStart + 16 <= fileLength) {
          // "fmt "
          final fmtBytes = raf.readSync(16);
          if (fmtBytes.lengthInBytes < 16) return null;
          final fmtData = ByteData.sublistView(fmtBytes);
          audioFormat = fmtData.getUint16(0, Endian.little);
          channels = fmtData.getUint16(2, Endian.little);
          sampleRate = fmtData.getUint32(4, Endian.little);
          bitsPerSample = fmtData.getUint16(14, Endian.little);
        } else if (chunkId == 0x64617461) {
          // "data"
          dataStart = bodyStart;
          dataSize = math.min(chunkSize, fileLength - bodyStart);
          break;
        }
        offset = bodyStart + chunkSize + (chunkSize.isOdd ? 1 : 0);
      }

      if (audioFormat != 1 ||
          dataStart == null ||
          dataSize <= 0 ||
          sampleRate <= 0 ||
          channels <= 0 ||
          (bitsPerSample != 16 && bitsPerSample != 8)) {
        return null;
      }

      final bytesPerSample = bitsPerSample ~/ 8;
      final bytesPerFrame = bytesPerSample * channels;
      final totalFrames = dataSize ~/ bytesPerFrame;
      final maxWindowFrames = sampleRate * maxSeconds;
      final startFrame = totalFrames > maxWindowFrames * 2
          ? (totalFrames * 0.25).round()
          : 0;
      final framesToRead = math.min(maxWindowFrames, totalFrames - startFrame);
      if (framesToRead <= 0) return null;

      final int bytesToRead = framesToRead * bytesPerFrame;
      raf.setPositionSync(dataStart + startFrame * bytesPerFrame);
      final pcmBytes = raf.readSync(bytesToRead);
      final int actualFrames = pcmBytes.lengthInBytes ~/ bytesPerFrame;
      if (actualFrames <= 0) return null;

      final pcmData = ByteData.sublistView(pcmBytes);
      const double frameRateHz = 100.0; // 10ms RMS windows
      final int samplesPerHop = math.max(1, (sampleRate / frameRateHz).round());
      final List<double> energies = [];

      double accSq = 0.0;
      int hopCount = 0;
      int bytePos = 0;

      for (int f = 0; f < actualFrames; f++) {
        double monoSample = 0.0;
        for (int c = 0; c < channels; c++) {
          if (bitsPerSample == 16) {
            monoSample += pcmData.getInt16(bytePos, Endian.little) / 32768.0;
          } else {
            monoSample += (pcmBytes[bytePos] - 128) / 128.0;
          }
          bytePos += bytesPerSample;
        }
        monoSample /= channels;
        accSq += monoSample * monoSample;
        hopCount++;

        if (hopCount >= samplesPerHop) {
          energies.add(math.sqrt(accSq / hopCount));
          accSq = 0.0;
          hopCount = 0;
        }
      }

      return estimateBpmFromOnsetEnvelope(energies, frameRateHz: frameRateHz);
    } catch (_) {
      return null;
    } finally {
      try {
        raf?.closeSync();
      } catch (_) {}
    }
  }

  /// Estimates BPM from a sequence of ~10ms RMS energy values using half-wave rectified
  /// log onset flux and normalized harmonic autocorrelation weighted around human tempo.
  static double? estimateBpmFromOnsetEnvelope(
    List<double> energies, {
    double frameRateHz = 100.0,
  }) {
    if (energies.length < (frameRateHz * 3).round()) return null;

    final int n = energies.length;
    final List<double> logEnergy = List<double>.filled(n, 0.0);
    double maxLog = 0.0;
    for (int i = 0; i < n; i++) {
      final v = math.log(1.0 + 16.0 * energies[i].abs());
      logEnergy[i] = v;
      if (v > maxLog) maxLog = v;
    }
    if (maxLog < 1e-4) return null; // Silence

    // 1. Half-wave rectified differential onset flux
    final List<double> flux = List<double>.filled(n, 0.0);
    for (int i = 1; i < n; i++) {
      final diff = logEnergy[i] - logEnergy[i - 1];
      flux[i] = diff > 0 ? diff : 0.0;
    }

    // 2. Adaptive moving threshold subtraction to sharpen beat transients
    final int halfWin = math.max(4, (frameRateHz * 0.09).round());
    final List<double> onsets = List<double>.filled(n, 0.0);
    double onsetSum = 0.0;
    for (int i = 0; i < n; i++) {
      final int start = math.max(0, i - halfWin);
      final int end = math.min(n - 1, i + halfWin);
      double localMean = 0.0;
      for (int k = start; k <= end; k++) {
        localMean += flux[k];
      }
      localMean /= (end - start + 1);
      final double v = flux[i] - localMean * 0.9;
      if (v > 0) {
        onsets[i] = v;
        onsetSum += v;
      }
    }
    if (onsetSum <= 1e-5) return null;

    // Normalize onsets to zero-mean for clean autocorrelation contrast
    final double mean = onsetSum / n;
    for (int i = 0; i < n; i++) {
      onsets[i] -= mean;
    }

    final int lagMin = math.max(2, (60.0 * frameRateHz / 205.0).floor());
    final int lagMax = math.min(n ~/ 2 - 1, (60.0 * frameRateHz / 52.0).ceil());
    if (lagMax <= lagMin + 2) return null;

    // 3. Normalized ACF per candidate lag
    final List<double> acf = List<double>.filled(lagMax + 1, 0.0);
    for (int lag = lagMin; lag <= lagMax; lag++) {
      double corr = 0.0;
      double energyA = 0.0;
      double energyB = 0.0;
      final int limit = n - lag;
      for (int i = 0; i < limit; i++) {
        final a = onsets[i];
        final b = onsets[i + lag];
        corr += a * b;
        energyA += a * a;
        energyB += b * b;
      }
      final double denom = math.sqrt(energyA * energyB);
      acf[lag] = denom > 1e-9 ? math.max(0.0, corr / denom) : 0.0;
    }

    // 4. Score lags with octave-harmonic support and perceptual log-tempo prior (~118 BPM)
    const double priorBpm = 118.0;
    const double sigmaOctaves = 0.72;
    int bestLag = lagMin;
    double bestScore = -1.0;

    for (int lag = lagMin; lag <= lagMax; lag++) {
      final double candBpm = 60.0 * frameRateHz / lag;
      double combined = acf[lag];

      final int doubleLag = lag * 2;
      if (doubleLag <= lagMax) {
        combined += 0.45 * acf[doubleLag];
      }
      final int halfLag = (lag / 2).round();
      if (halfLag >= lagMin) {
        combined += 0.25 * acf[halfLag];
      }

      final double logDist = math.log(candBpm / priorBpm) / math.ln2;
      final double priorWeight =
          math.exp(-(logDist * logDist) / (2.0 * sigmaOctaves * sigmaOctaves));
      final double score = combined * priorWeight;

      if (score > bestScore) {
        bestScore = score;
        bestLag = lag;
      }
    }

    if (bestScore <= 0.02) return null;

    // 5. Parabolic sub-frame refinement around the winning lag
    double refinedLag = bestLag.toDouble();
    if (bestLag > lagMin && bestLag < lagMax) {
      final double y0 = acf[bestLag - 1];
      final double y1 = acf[bestLag];
      final double y2 = acf[bestLag + 1];
      final double denom = 2.0 * (y0 - 2.0 * y1 + y2);
      if (denom.abs() > 1e-6) {
        final double delta = ((y0 - y2) / denom).clamp(-0.5, 0.5);
        refinedLag += delta;
      }
    }

    final double rawBpm = 60.0 * frameRateHz / refinedLag;
    return _sanitizeBpm(rawBpm);
  }

  /// Normalizes extreme BPMs (e.g., 300 BPM -> 150 BPM, 40 BPM -> 80 BPM) into
  /// an equivalent musical feel pocket `[55, 180]` BPM.
  static double effectiveVisualBpm(double? bpm) {
    if (bpm == null || bpm <= 0 || bpm.isNaN || bpm.isInfinite) {
      return baselineVisualBpm;
    }
    double effective = bpm.clamp(minValidBpm, maxValidBpm);
    while (effective > maxVisualBpm) {
      effective /= 2.0;
    }
    while (effective < minVisualBpm) {
      effective *= 2.0;
    }
    return effective;
  }

  /// Maps any track [bpm] (including extremes like 300 BPM) to a perceptually responsive,
  /// octave-equivalent wave motion speed multiplier in `[0.38, 1.92]`, centered around `115 BPM`.
  static double mapBpmToWaveSpeed(double? bpm) {
    if (bpm == null || bpm <= 0 || bpm.isNaN || bpm.isInfinite) {
      return 1.0;
    }
    final double effective = effectiveVisualBpm(bpm);
    final double x = (effective - baselineVisualBpm) / 42.0;
    final double ex = math.exp(x);
    final double enx = math.exp(-x);
    final double tanhX = (ex - enx) / (ex + enx);
    return (1.05 + 0.85 * tanhX).clamp(0.38, 1.92);
  }

  static double? _parseBpmString(String? raw) {
    if (raw == null) return null;
    final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(raw.trim());
    if (match == null) return null;
    final normalized = match.group(1)!.replaceAll(',', '.');
    return _sanitizeBpm(double.tryParse(normalized));
  }

  static double? _sanitizeBpm(double? bpm) {
    if (bpm == null || bpm.isNaN || bpm.isInfinite) return null;
    if (bpm < minValidBpm || bpm > maxValidBpm) return null;
    return (bpm * 10.0).round() / 10.0;
  }
}


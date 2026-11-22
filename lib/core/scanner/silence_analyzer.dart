/// File: silence_analyzer.dart
/// Description: Cross-format leading digital silence detector using Android's
/// native MediaExtractor + MediaCodec decoder (MP3, FLAC, AAC/M4A, OGG, WAV, OPUS).
///
/// Components / Classes / Functions:
/// - SilenceAnalyzer: Singleton service detecting leading silence duration in milliseconds.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native-backed analyzer detecting leading silence across all audio formats.
class SilenceAnalyzer {
  SilenceAnalyzer._();
  static final SilenceAnalyzer instance = SilenceAnalyzer._();

  static const MethodChannel _channel = MethodChannel('project_anima/media_store');

  /// Returns leading silence duration in milliseconds for [filePath], or `null`
  /// if unavailable/unsupported on the current platform.
  Future<int?> detectLeadingSilence(
    String filePath, {
    int maxScanMs = 8000,
  }) async {
    if (kIsWeb || !Platform.isAndroid || filePath.trim().isEmpty) {
      return null;
    }
    try {
      final int? result = await _channel.invokeMethod<int>(
        'detectLeadingSilence',
        {
          'path': filePath,
          'maxScanMs': maxScanMs,
        },
      );
      if (result == null || result < 0) return null;
      return result;
    } catch (_) {
      return null;
    }
  }
}

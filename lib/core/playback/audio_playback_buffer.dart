/// File: audio_playback_buffer.dart
/// Description: High-performance, gapless audio source buffering engine.
/// Manages ConcatenatingAudioSource with lookahead pre-buffering (useLazyPreparation),
/// optimized native LoadControl buffer thresholds (AndroidLoadControl & DarwinLoadControl),
/// and dynamic queue mutations to guarantee 0ms transitions between tracks.
///
/// Components / Classes / Functions:
/// - AudioPlaybackBuffer: Dedicated buffer and playlist engine for zero-latency audio playback.
library;

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:project_anima/core/database/models/song.dart';

/// Coordinator for zero-latency audio buffering and ConcatenatingAudioSource lifecycle.
class AudioPlaybackBuffer {
  /// Queues above this size hydrate around the active index in bounded windows to
  /// avoid transferring thousands of native AudioSource items across platform channels.
  static const int largeQueueThreshold = 150;
  static const int windowBackPadding = 40;
  static const int windowTailPrefetchThreshold = 20;
  static const int windowExpandBatchSize = 50;

  final AudioPlayer player;
  ConcatenatingAudioSource? _source;
  List<Song> _bufferedSongs = [];
  int _windowStart = 0;
  bool _isExpandingWindow = false;

  AudioPlaybackBuffer({required this.player});

  /// Creates a custom-tuned AudioPlayer with ultra-low buffer start thresholds
  /// (150ms vs default 2500ms) and lightweight forward buffers optimized for local audio,
  /// guaranteeing instant playback and 0ms gapless transitions with minimal native RAM.
  static AudioPlayer createOptimizedPlayer() {
    return AudioPlayer(
      audioLoadConfiguration: const AudioLoadConfiguration(
        androidLoadControl: AndroidLoadControl(
          minBufferDuration: Duration(seconds: 4),
          maxBufferDuration: Duration(seconds: 12),
          bufferForPlaybackDuration: Duration(milliseconds: 150),
          bufferForPlaybackAfterRebufferDuration: Duration(milliseconds: 300),
          prioritizeTimeOverSizeThresholds: true,
          backBufferDuration: Duration(seconds: 3),
        ),
        darwinLoadControl: DarwinLoadControl(
          automaticallyWaitsToMinimizeStalling: false,
          preferredForwardBufferDuration: Duration(seconds: 12),
        ),
      ),
    );
  }

  /// Whether an active ConcatenatingAudioSource is loaded.
  bool get hasSource => _source != null;

  /// Logical queue length across all buffered tracks.
  int get length => _bufferedSongs.length;

  /// Starting logical index mapped to index 0 of the active native [ConcatenatingAudioSource].
  int get windowStart => _windowStart;

  /// Number of [AudioSource]s currently loaded in the native [ConcatenatingAudioSource] window.
  int get windowLength => _source?.length ?? 0;

  /// Maps a native [player] window index to its logical index in [bufferedSongs].
  int? toLogicalIndex(int? playerIndex) =>
      playerIndex == null ? null : _windowStart + playerIndex;

  /// Maps a logical queue index to its offset inside the active native window.
  int toWindowIndex(int logicalIndex) => logicalIndex - _windowStart;

  bool _isInWindow(int logicalIndex) =>
      _source != null &&
      logicalIndex >= _windowStart &&
      logicalIndex < _windowStart + _source!.length;

  /// Unmodifiable zero-copy view of all tracks in the active queue.
  List<Song> get bufferedSongs => UnmodifiableListView(_bufferedSongs);

  /// Converts a [Song] domain model into an optimized [AudioSource].
  AudioSource _buildAudioSource(Song song) {
    return AudioSource.file(
      song.path,
      tag: song,
    );
  }

  /// Loads a song queue into the buffer engine, using bounded windowed loading when
  /// [songs.length] exceeds [largeQueueThreshold] to keep native ExoPlayer allocation fast.
  Future<void> loadQueue(
    List<Song> songs, {
    int initialIndex = 0,
    Duration? initialPosition,
  }) async {
    if (songs.isEmpty) {
      await clear();
      return;
    }

    final safeIndex = initialIndex.clamp(0, songs.length - 1);
    _bufferedSongs = List<Song>.from(songs);
    _isExpandingWindow = false;

    final List<Song> windowSongs;
    if (songs.length <= largeQueueThreshold) {
      _windowStart = 0;
      windowSongs = songs;
    } else {
      _windowStart = math.max(0, safeIndex - windowBackPadding);
      final int windowEnd = math.min(songs.length, _windowStart + largeQueueThreshold);
      windowSongs = songs.sublist(_windowStart, windowEnd);
    }

    final sources = windowSongs.map(_buildAudioSource).toList();
    _source = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: sources,
    );

    try {
      await player.setAudioSource(
        _source!,
        initialIndex: safeIndex - _windowStart,
        initialPosition: initialPosition,
      );
    } catch (e) {
      debugPrint('AudioPlaybackBuffer Error loading audio source: $e');
      rethrow;
    }
  }

  /// Extends the active native window forward when playback nears its trailing edge.
  Future<void> ensureWindowForIndex(int logicalIndex) async {
    final source = _source;
    if (source == null || _isExpandingWindow) return;

    final int currentWindowEnd = _windowStart + source.length;
    if (logicalIndex >= currentWindowEnd - windowTailPrefetchThreshold &&
        currentWindowEnd < _bufferedSongs.length) {
      _isExpandingWindow = true;
      try {
        final int nextEnd = math.min(
          currentWindowEnd + windowExpandBatchSize,
          _bufferedSongs.length,
        );
        final nextSources =
            _bufferedSongs.sublist(currentWindowEnd, nextEnd).map(_buildAudioSource).toList();
        await source.addAll(nextSources);
      } catch (e) {
        debugPrint('AudioPlaybackBuffer Error extending forward window: $e');
      } finally {
        _isExpandingWindow = false;
      }
    }
  }

  /// Seeks to a logical [index] in the active buffer, re-centering the window if needed.
  Future<void> seekToIndex(int index, {Duration position = Duration.zero}) async {
    if (_source == null || index < 0 || index >= _bufferedSongs.length) return;
    try {
      if (_isInWindow(index)) {
        await player.seek(position, index: index - _windowStart);
        unawaited(ensureWindowForIndex(index));
      } else {
        await loadQueue(
          List<Song>.from(_bufferedSongs),
          initialIndex: index,
          initialPosition: position,
        );
      }
    } catch (e) {
      debugPrint('AudioPlaybackBuffer Error seeking to index $index: $e');
    }
  }

  /// Advances to next pre-buffered track.
  Future<void> seekToNext() async {
    if (player.hasNext) {
      await player.seekToNext();
    } else if (_source != null && _bufferedSongs.isNotEmpty) {
      await seekToIndex(0);
    }
  }

  /// Rewinds to previous track.
  Future<void> seekToPrevious() async {
    if (player.hasPrevious) {
      await player.seekToPrevious();
    } else if (_bufferedSongs.isNotEmpty) {
      await seekToIndex(_bufferedSongs.length - 1);
    }
  }

  /// Dynamically inserts a track into the buffer (e.g. "Play Next").
  Future<void> insert(int index, Song song) async {
    if (_source == null) return;
    try {
      final safeIndex = index.clamp(0, _bufferedSongs.length);
      _bufferedSongs.insert(safeIndex, song);

      if (safeIndex < _windowStart) {
        _windowStart++;
      } else if (safeIndex <= _windowStart + _source!.length) {
        await _source!.insert(safeIndex - _windowStart, _buildAudioSource(song));
      }
    } catch (e) {
      debugPrint('AudioPlaybackBuffer Error inserting song into buffer: $e');
    }
  }

  /// Dynamically appends a track to the end of the queue/buffer.
  Future<void> add(Song song) async {
    if (_source == null) return;
    try {
      final int currentEnd = _windowStart + _source!.length;
      final bool windowCoversEnd = currentEnd == _bufferedSongs.length;
      _bufferedSongs.add(song);
      if (windowCoversEnd) {
        await _source!.add(_buildAudioSource(song));
      }
    } catch (e) {
      debugPrint('AudioPlaybackBuffer Error appending song to buffer: $e');
    }
  }

  /// Dynamically removes a track from the buffer.
  Future<void> removeAt(int index) async {
    if (_source == null || index < 0 || index >= _bufferedSongs.length) return;
    try {
      _bufferedSongs.removeAt(index);
      if (index < _windowStart) {
        _windowStart = math.max(0, _windowStart - 1);
      } else if (index < _windowStart + _source!.length) {
        await _source!.removeAt(index - _windowStart);
      }
    } catch (e) {
      debugPrint('AudioPlaybackBuffer Error removing song from buffer: $e');
    }
  }

  /// Reorders items in the queue and updates the active window if affected.
  Future<void> move(int currentIndex, int newIndex) async {
    if (_source == null) return;
    if (currentIndex < 0 || currentIndex >= _bufferedSongs.length) return;
    final targetIndex = newIndex.clamp(0, _bufferedSongs.length - 1);
    if (currentIndex == targetIndex) return;

    try {
      final item = _bufferedSongs.removeAt(currentIndex);
      _bufferedSongs.insert(targetIndex, item);

      final int sourceEnd = _windowStart + _source!.length;
      final bool fromInWindow =
          currentIndex >= _windowStart && currentIndex < sourceEnd;
      final bool toInWindow =
          targetIndex >= _windowStart && targetIndex <= sourceEnd;

      if (fromInWindow && toInWindow) {
        await _source!.move(
          currentIndex - _windowStart,
          targetIndex.clamp(_windowStart, sourceEnd - 1) - _windowStart,
        );
      } else if (fromInWindow) {
        await _source!.removeAt(currentIndex - _windowStart);
        if (targetIndex < _windowStart) {
          _windowStart++;
        }
      } else if (toInWindow) {
        if (currentIndex < _windowStart) {
          _windowStart = math.max(0, _windowStart - 1);
        }
        await _source!.insert(
          (targetIndex - _windowStart).clamp(0, _source!.length),
          _buildAudioSource(item),
        );
      } else if (currentIndex < _windowStart && targetIndex > _windowStart) {
        _windowStart = math.max(0, _windowStart - 1);
      } else if (currentIndex > _windowStart && targetIndex < _windowStart) {
        _windowStart++;
      }
    } catch (e) {
      debugPrint('AudioPlaybackBuffer Error moving song in buffer: $e');
    }
  }

  /// Clears upcoming tracks in the queue after [currentIndex], preserving the active track.
  Future<void> clearUpcoming(int currentIndex) async {
    if (_source == null) return;
    try {
      final int safeCurrent = currentIndex.clamp(0, _bufferedSongs.length - 1);
      if (safeCurrent + 1 < _bufferedSongs.length) {
        _bufferedSongs.removeRange(safeCurrent + 1, _bufferedSongs.length);
      }
      final int localCurrent = safeCurrent - _windowStart;
      for (int i = _source!.length - 1; i > localCurrent && i >= 0; i--) {
        await _source!.removeAt(i);
      }
    } catch (e) {
      debugPrint('AudioPlaybackBuffer Error clearing upcoming buffer: $e');
    }
  }

  /// Completely clears the buffer.
  Future<void> clear() async {
    _bufferedSongs.clear();
    _windowStart = 0;
    _isExpandingWindow = false;
    if (_source != null) {
      try {
        await _source!.clear();
      } catch (_) {}
      _source = null;
    }
  }

  /// Disposes buffer resources.
  void dispose() {
    _bufferedSongs.clear();
    _windowStart = 0;
    _isExpandingWindow = false;
    _source = null;
  }
}

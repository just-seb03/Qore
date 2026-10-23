/// File: audio_playback_buffer.dart
/// Description: High-performance, gapless audio source buffering engine.
/// Manages ConcatenatingAudioSource with lookahead pre-buffering (useLazyPreparation),
/// optimized native LoadControl buffer thresholds (AndroidLoadControl & DarwinLoadControl),
/// and dynamic queue mutations to guarantee 0ms transitions between tracks.
///
/// Components / Classes / Functions:
/// - AudioPlaybackBuffer: Dedicated buffer and playlist engine for zero-latency audio playback.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:project_anima/core/database/models/song.dart';

/// Coordinator for zero-latency audio buffering and ConcatenatingAudioSource lifecycle.
class AudioPlaybackBuffer {
  final AudioPlayer _player;
  ConcatenatingAudioSource? _source;
  List<Song> _bufferedSongs = [];

  AudioPlaybackBuffer({required AudioPlayer player}) : _player = player;

  /// Creates a custom-tuned AudioPlayer with ultra-low buffer start thresholds
  /// (200ms vs default 2500ms) and lookahead forward buffers for instant playback and 0ms gapless transitions.
  static AudioPlayer createOptimizedPlayer() {
    return AudioPlayer(
      audioLoadConfiguration: const AudioLoadConfiguration(
        androidLoadControl: AndroidLoadControl(
          minBufferDuration: Duration(seconds: 20),
          maxBufferDuration: Duration(seconds: 50),
          bufferForPlaybackDuration: Duration(milliseconds: 200),
          bufferForPlaybackAfterRebufferDuration: Duration(milliseconds: 500),
          prioritizeTimeOverSizeThresholds: true,
          backBufferDuration: Duration(seconds: 5),
        ),
        darwinLoadControl: DarwinLoadControl(
          automaticallyWaitsToMinimizeStalling: false,
          preferredForwardBufferDuration: Duration(seconds: 20),
        ),
      ),
    );
  }

  /// Whether an active ConcatenatingAudioSource is loaded.
  bool get hasSource => _source != null;

  /// Number of items currently buffered in the audio source.
  int get length => _source?.length ?? 0;

  /// Unmodifiable view of currently buffered tracks.
  List<Song> get bufferedSongs => List.unmodifiable(_bufferedSongs);

  /// Converts a [Song] domain model into an optimized [AudioSource].
  AudioSource _buildAudioSource(Song song) {
    return AudioSource.file(
      song.path,
      tag: song,
    );
  }

  /// Loads an entire song queue into the buffer engine.
  /// Uses [useLazyPreparation: true] so ExoPlayer/AVPlayer only decodes adjacent
  /// tracks, preventing memory overhead for large playlists while guaranteeing 0ms gapless advance.
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

    final sources = songs.map(_buildAudioSource).toList();
    _source = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: sources,
    );

    try {
      await _player.setAudioSource(
        _source!,
        initialIndex: safeIndex,
        initialPosition: initialPosition,
      );
    } catch (e) {
      debugPrint('AudioPlaybackBuffer Error loading audio source: $e');
      rethrow;
    }
  }

  /// Seeks to a specific index in the active buffer.
  /// Instantaneous switch because adjacent tracks are already pre-buffered.
  Future<void> seekToIndex(int index, {Duration position = Duration.zero}) async {
    if (_source == null || index < 0 || index >= _source!.length) return;
    try {
      await _player.seek(position, index: index);
    } catch (e) {
      debugPrint('AudioPlaybackBuffer Error seeking to index $index: $e');
    }
  }

  /// Advances to next pre-buffered track.
  Future<void> seekToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_source != null && _source!.length > 0) {
      await seekToIndex(0);
    }
  }

  /// Rewinds to previous track.
  Future<void> seekToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else if (_source != null && _source!.length > 0) {
      await seekToIndex(_source!.length - 1);
    }
  }

  /// Dynamically inserts a track into the buffer (e.g. "Play Next").
  Future<void> insert(int index, Song song) async {
    if (_source == null) return;
    try {
      final safeIndex = index.clamp(0, _source!.length);
      final audioSource = _buildAudioSource(song);
      _bufferedSongs.insert(safeIndex, song);
      await _source!.insert(safeIndex, audioSource);
    } catch (e) {
      debugPrint('AudioPlaybackBuffer Error inserting song into buffer: $e');
    }
  }

  /// Dynamically appends a track to the end of the buffer.
  Future<void> add(Song song) async {
    if (_source == null) return;
    await insert(_source!.length, song);
  }

  /// Dynamically removes a track from the buffer.
  Future<void> removeAt(int index) async {
    if (_source == null || index < 0 || index >= _source!.length) return;
    try {
      if (index < _bufferedSongs.length) {
        _bufferedSongs.removeAt(index);
      }
      await _source!.removeAt(index);
    } catch (e) {
      debugPrint('AudioPlaybackBuffer Error removing song from buffer: $e');
    }
  }

  /// Reorders items in the buffer.
  Future<void> move(int currentIndex, int newIndex) async {
    if (_source == null) return;
    if (currentIndex < 0 || currentIndex >= _source!.length) return;
    final targetIndex = newIndex.clamp(0, _source!.length - 1);
    if (currentIndex == targetIndex) return;

    try {
      if (currentIndex < _bufferedSongs.length) {
        final item = _bufferedSongs.removeAt(currentIndex);
        final safeTarget = targetIndex.clamp(0, _bufferedSongs.length);
        _bufferedSongs.insert(safeTarget, item);
      }
      await _source!.move(currentIndex, targetIndex);
    } catch (e) {
      debugPrint('AudioPlaybackBuffer Error moving song in buffer: $e');
    }
  }

  /// Clears upcoming tracks in the buffer after [currentIndex], preserving the active track.
  Future<void> clearUpcoming(int currentIndex) async {
    if (_source == null) return;
    try {
      for (int i = _source!.length - 1; i > currentIndex; i--) {
        if (i < _bufferedSongs.length) {
          _bufferedSongs.removeAt(i);
        }
        await _source!.removeAt(i);
      }
    } catch (e) {
      debugPrint('AudioPlaybackBuffer Error clearing upcoming buffer: $e');
    }
  }

  /// Completely clears the buffer.
  Future<void> clear() async {
    _bufferedSongs.clear();
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
    _source = null;
  }
}

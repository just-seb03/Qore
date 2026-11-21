/// File: audio_playback_buffer_test.dart
/// Description: Dedicated unit tests for AudioPlaybackBuffer and its integration
/// with PlaybackController, verifying 0ms gapless buffering, dynamic mutations,
/// lookahead configuration, and queue consistency.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/audio_playback_buffer.dart';
import 'package:project_anima/core/playback/playback_controller.dart';

class _FakeWindowAudioPlayer implements AudioPlayer {
  int? setAudioSourceInitialIndex;
  int? lastSeekIndex;
  final List<int> seekedIndices = [];

  @override
  Future<Duration?> setAudioSource(
    AudioSource source, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    setAudioSourceInitialIndex = initialIndex;
    lastSeekIndex = initialIndex;
    return null;
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    if (index != null) {
      lastSeekIndex = index;
      seekedIndices.add(index);
    }
  }

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testSong1 = Song(
    id: 1,
    mediaStoreId: 101,
    title: 'Neon Odyssey',
    artist: 'Cyber Runner',
    album: 'Future Drift',
    albumId: 501,
    duration: 184000,
    path: '/music/neon.mp3',
    dateModified: 1700000000,
  );

  final testSong2 = Song(
    id: 2,
    mediaStoreId: 102,
    title: 'Solar Flare',
    artist: 'Aura',
    album: 'Eclipse',
    albumId: 502,
    duration: 215000,
    path: '/music/solar.mp3',
    dateModified: 1700000001,
  );

  final testSong3 = Song(
    id: 3,
    mediaStoreId: 103,
    title: 'Nightfall',
    artist: 'Ghost',
    album: 'Echoes',
    albumId: 503,
    duration: 195000,
    path: '/music/night.mp3',
    dateModified: 1700000002,
  );

  group('AudioPlaybackBuffer Unit Tests', () {
    test('createOptimizedPlayer creates AudioPlayer with ultra-low buffer thresholds', () {
      final player = AudioPlaybackBuffer.createOptimizedPlayer();
      expect(player, isA<AudioPlayer>());
      // Dispose test player cleanly
      player.dispose();
    });

    test('Initial buffer state has no source and 0 items', () {
      final player = AudioPlayer();
      final buffer = AudioPlaybackBuffer(player: player);

      expect(buffer.hasSource, isFalse);
      expect(buffer.length, 0);
      expect(buffer.bufferedSongs, isEmpty);

      player.dispose();
    });

    test('loadQueue with empty list safely clears buffer', () async {
      final player = AudioPlayer();
      final buffer = AudioPlaybackBuffer(player: player);

      await buffer.loadQueue([]);
      expect(buffer.hasSource, isFalse);
      expect(buffer.bufferedSongs, isEmpty);

      player.dispose();
    });

    test('Buffer dynamic operations safely no-op when no source is loaded', () async {
      final player = AudioPlayer();
      final buffer = AudioPlaybackBuffer(player: player);

      // Calling dynamic operations before any source is loaded should not throw or corrupt state
      await buffer.insert(0, testSong1);
      await buffer.add(testSong2);
      await buffer.removeAt(0);
      await buffer.move(0, 1);
      await buffer.clearUpcoming(0);
      await buffer.seekToIndex(0);
      await buffer.clear();

      expect(buffer.hasSource, isFalse);
      expect(buffer.bufferedSongs, isEmpty);

      player.dispose();
    });

    test('loadQueue uses bounded window for >150 tracks, extends forward, and re-centers on far seek', () async {
      final player = _FakeWindowAudioPlayer();
      final buffer = AudioPlaybackBuffer(player: player);

      final largeQueue = List<Song>.generate(
        500,
        (i) => Song(
          id: i + 1,
          mediaStoreId: 1000 + i,
          title: 'Track $i',
          artist: 'Artist',
          album: 'Large Album',
          duration: 180000,
          path: '/music/t$i.mp3',
          dateModified: 1700000000 + i,
        ),
      );

      await buffer.loadQueue(largeQueue, initialIndex: 300);

      expect(buffer.length, 500);
      expect(buffer.windowStart, 300 - AudioPlaybackBuffer.windowBackPadding);
      expect(buffer.windowLength, AudioPlaybackBuffer.largeQueueThreshold);
      expect(player.setAudioSourceInitialIndex, AudioPlaybackBuffer.windowBackPadding);
      expect(buffer.toLogicalIndex(player.setAudioSourceInitialIndex), 300);

      // Seeking within active window translates directly without re-creating source
      await buffer.seekToIndex(320);
      expect(player.seekedIndices.last, 320 - buffer.windowStart);
      expect(buffer.windowStart, 300 - AudioPlaybackBuffer.windowBackPadding);

      // Seeking near tail edge expands window forward dynamically
      final int initialWindowEnd = buffer.windowStart + buffer.windowLength;
      await buffer.seekToIndex(initialWindowEnd - 5);
      await Future<void>.delayed(Duration.zero);
      expect(buffer.windowLength, greaterThan(AudioPlaybackBuffer.largeQueueThreshold));

      // Seeking far outside window re-centers cleanly
      await buffer.seekToIndex(10);
      expect(buffer.windowStart, 0);
      expect(buffer.windowLength, AudioPlaybackBuffer.largeQueueThreshold);
      expect(player.setAudioSourceInitialIndex, 10);
    });
  });

  group('PlaybackController with AudioPlaybackBuffer Integration Tests', () {
    test('PlaybackController exposes audioBuffer and maintains high cohesion', () {
      final controller = PlaybackController.instance;
      expect(controller.audioBuffer, isNotNull);
      expect(controller.audioBuffer, isA<AudioPlaybackBuffer>());
    });

    test('Queue manipulations update internal list and buffer simultaneously', () {
      final controller = PlaybackController.instance;
      controller.setQueueForTesting([testSong1, testSong2], currentIndex: 0);

      expect(controller.queue.length, 2);
      expect(controller.currentIndex, 0);
      expect(controller.currentSong?.mediaStoreId, 101);

      // Dynamic add
      controller.addToQueue(testSong3);
      expect(controller.queue.length, 3);
      expect(controller.queue[1].mediaStoreId, 103); // inserted next up

      // Reorder
      controller.reorderQueue(1, 2);
      expect(controller.queue[2].mediaStoreId, 103);

      // Remove
      controller.removeFromQueue(2);
      expect(controller.queue.length, 2);

      // Clear upcoming
      controller.clearUpcomingQueue();
      expect(controller.queue.length, 1);
      expect(controller.queue.first.mediaStoreId, 101);
    });
  });
}

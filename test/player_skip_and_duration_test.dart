/// File: player_skip_and_duration_test.dart
/// Description: Unit tests for deterministic PlaybackController.skipToNext / skipToPrevious
/// transitions and H:MM:SS duration formatting for tracks >= 1 hour.
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/audio_playback_buffer.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/utils/duration_formatter.dart';

class _FakeAudioPlayer implements AudioPlayer {
  final _playerStateController = StreamController<PlayerState>.broadcast();
  final _processingStateController = StreamController<ProcessingState>.broadcast();
  final _currentIndexController = StreamController<int?>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();

  Duration _position = Duration.zero;
  LoopMode _loopMode = LoopMode.off;
  bool _playing = false;
  int? _currentIndex = 0;
  int seekToZeroCount = 0;

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  @override
  Stream<ProcessingState> get processingStateStream => _processingStateController.stream;

  @override
  Stream<int?> get currentIndexStream => _currentIndexController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Duration get position => _position;

  set testPosition(Duration value) => _position = value;

  @override
  Duration? get duration => const Duration(minutes: 4);

  @override
  LoopMode get loopMode => _loopMode;

  @override
  bool get playing => _playing;

  @override
  int? get currentIndex => _currentIndex;

  @override
  bool get hasNext => false; // Intentionally false (e.g., LoopMode.one / lazy buffer)

  @override
  bool get hasPrevious => false;

  @override
  bool get shuffleModeEnabled => false;

  @override
  Future<void> play() async {
    _playing = true;
  }

  @override
  Future<void> pause() async {
    _playing = false;
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    if (position == Duration.zero && index == null) {
      seekToZeroCount++;
    }
    _position = position ?? Duration.zero;
    if (index != null) {
      _currentIndex = index;
    }
  }

  @override
  Future<void> setLoopMode(LoopMode mode) async {
    _loopMode = mode;
  }

  @override
  Future<void> setShuffleModeEnabled(bool enabled) async {}

  @override
  Future<Duration?> setAudioSource(
    AudioSource source, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    _currentIndex = initialIndex ?? 0;
    _position = initialPosition ?? Duration.zero;
    return const Duration(minutes: 4);
  }

  @override
  Future<void> dispose() async {
    await _playerStateController.close();
    await _processingStateController.close();
    await _currentIndexController.close();
    await _positionController.close();
    await _durationController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAudioBuffer extends AudioPlaybackBuffer {
  bool _hasSource = true;
  final List<int> seekedIndices = [];

  _FakeAudioBuffer(AudioPlayer player) : super(player: player);

  @override
  bool get hasSource => _hasSource;

  @override
  Future<void> loadQueue(
    List<Song> songs, {
    int initialIndex = 0,
    Duration? initialPosition,
  }) async {
    _hasSource = songs.isNotEmpty;
    await player.seek(initialPosition ?? Duration.zero, index: initialIndex);
  }

  @override
  Future<void> seekToIndex(int index, {Duration position = Duration.zero}) async {
    seekedIndices.add(index);
    await player.seek(position, index: index);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final songs = [
    Song(
      id: 1,
      mediaStoreId: 101,
      title: 'Track 1',
      artist: 'Artist A',
      album: 'Album X',
      duration: 240000,
      path: '/music/t1.mp3',
      dateModified: 1700000000,
    ),
    Song(
      id: 2,
      mediaStoreId: 102,
      title: 'Track 2',
      artist: 'Artist A',
      album: 'Album X',
      duration: 240000,
      path: '/music/t2.mp3',
      dateModified: 1700000001,
    ),
    Song(
      id: 3,
      mediaStoreId: 103,
      title: 'Track 3',
      artist: 'Artist A',
      album: 'Album X',
      duration: 240000,
      path: '/music/t3.mp3',
      dateModified: 1700000002,
    ),
  ];

  group('Duration Formatter Tests', () {
    test('formats durations under 1 hour as M:SS', () {
      expect(formatDuration(Duration.zero), '0:00');
      expect(formatDuration(const Duration(seconds: 9)), '0:09');
      expect(formatDuration(const Duration(minutes: 4, seconds: 5)), '4:05');
      expect(formatDuration(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('formats durations >= 1 hour as H:MM:SS instead of total minutes', () {
      expect(formatDuration(const Duration(hours: 1)), '1:00:00');
      expect(formatDuration(const Duration(minutes: 73, seconds: 54)), '1:13:54');
      expect(formatDuration(const Duration(hours: 1, minutes: 23, seconds: 42)), '1:23:42');
      expect(formatDurationMs((73 * 60 + 54) * 1000), '1:13:54');
    });
  });

  group('PlaybackController.skipToNext Deterministic Tests', () {
    test('advances immediately regardless of current position or LoopMode.one', () async {
      final player = _FakeAudioPlayer();
      final buffer = _FakeAudioBuffer(player);
      final controller = PlaybackController(
        player: player,
        audioBuffer: buffer,
      );
      addTearDown(controller.dispose);

      await controller.playSong(songs[0], queue: songs);
      expect(controller.currentIndex, 0);
      expect(controller.currentSong?.title, 'Track 1');

      // Simulate mid-song playback (e.g. 45s) and even LoopMode.one active
      player.testPosition = const Duration(seconds: 45);
      await player.setLoopMode(LoopMode.one);

      // Must advance directly to Track 2 without restarting Track 1 to 0:00
      await controller.skipToNext();
      expect(controller.currentIndex, 1);
      expect(controller.currentSong?.title, 'Track 2');
      expect(buffer.seekedIndices.last, 1);
      expect(player.seekToZeroCount, 0);

      // Advance again to Track 3 even while position > 0
      player.testPosition = const Duration(seconds: 120);
      await controller.skipToNext();
      expect(controller.currentIndex, 2);
      expect(controller.currentSong?.title, 'Track 3');
      expect(buffer.seekedIndices.last, 2);
      expect(player.seekToZeroCount, 0);
    });

    test('wraps to index 0 at end of queue when LoopMode.all is active', () async {
      final player = _FakeAudioPlayer();
      final buffer = _FakeAudioBuffer(player);
      final controller = PlaybackController(
        player: player,
        audioBuffer: buffer,
      );
      addTearDown(controller.dispose);

      await controller.playSong(songs[2], queue: songs);
      await player.setLoopMode(LoopMode.all);

      await controller.skipToNext();
      expect(controller.currentIndex, 0);
      expect(controller.currentSong?.title, 'Track 1');
    });
  });
}

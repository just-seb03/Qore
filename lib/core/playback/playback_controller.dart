/// File: playback_controller.dart
/// Description: High-performance, zero-jank audio playback controller coordinating
/// just_audio ExoPlayer backend, AudioPlaybackBuffer 0ms gapless buffering, AudioSession
/// audio focus, queue management, and reactive playback states for Project Anima.
///
/// Components / Classes / Functions:
/// - PlaybackController: Singleton ChangeNotifier coordinating playback, streams, and queue.
library;

import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/audio_handler.dart';
import 'package:project_anima/core/playback/audio_playback_buffer.dart';
import 'package:project_anima/core/playback/playback_persistence_coordinator.dart';

/// Centralized audio playback coordinator.
class PlaybackController extends ChangeNotifier {
  static final PlaybackController instance = PlaybackController._internal();

  final AudioPlayer _player;
  final SongDao _songDao;
  final PlaybackPersistenceCoordinator _persistenceCoordinator;
  final AudioPlaybackBuffer _audioBuffer;
  AnimaAudioHandler? _audioHandler;

  Song? _currentSong;
  List<Song> _queue = [];
  int _currentIndex = -1;
  int? _activePlaylistId;
  bool _isBuffering = false;
  bool _isInitialized = false;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<ProcessingState>? _processingStateSubscription;
  StreamSubscription<int?>? _currentIndexSubscription;

  PlaybackController({
    AudioPlayer? player,
    SongDao? songDao,
    PlaybackPersistenceCoordinator? persistenceCoordinator,
    AudioPlaybackBuffer? audioBuffer,
  }) : this._withPlayer(
          player ?? AudioPlaybackBuffer.createOptimizedPlayer(),
          songDao: songDao,
          persistenceCoordinator: persistenceCoordinator,
          audioBuffer: audioBuffer,
        );

  PlaybackController._internal()
      : this(
          player: AudioPlaybackBuffer.createOptimizedPlayer(),
          songDao: SongDao(),
          persistenceCoordinator: PlaybackPersistenceCoordinator(),
        );

  PlaybackController._withPlayer(
    AudioPlayer player, {
    SongDao? songDao,
    PlaybackPersistenceCoordinator? persistenceCoordinator,
    AudioPlaybackBuffer? audioBuffer,
  })  : _player = player,
        _songDao = songDao ?? SongDao(),
        _persistenceCoordinator = persistenceCoordinator ??
            PlaybackPersistenceCoordinator(songDao: songDao ?? SongDao()),
        _audioBuffer = audioBuffer ?? AudioPlaybackBuffer(player: player) {
    _initAudioSession();
    _listenToStreams();
  }

  /// Reference to persistence coordinator for testing or inspection.
  PlaybackPersistenceCoordinator get persistenceCoordinator =>
      _persistenceCoordinator;

  /// Reference to the gapless audio playback buffer.
  AudioPlaybackBuffer get audioBuffer => _audioBuffer;

  /// Reference to active system notification handler.
  AnimaAudioHandler? get audioHandler => _audioHandler;

  /// Active track currently playing or paused.
  Song? get currentSong => _currentSong;

  /// Database ID of the playlist currently playing, if any.
  int? get activePlaylistId => _activePlaylistId;

  /// Current playback queue.
  List<Song> get queue => List.unmodifiable(_queue);

  /// Current 0-based index in the queue.
  int get currentIndex => _currentIndex;

  /// Whether audio is actively playing.
  bool get isPlaying => _player.playing;

  /// Whether audio is loading/buffering.
  bool get isBuffering => _isBuffering;

  /// Current playback position.
  Duration get position => _player.position;

  /// Total duration of the current audio source.
  Duration get duration => _player.duration ?? Duration.zero;

  /// Whether shuffle is enabled.
  bool get isShuffleEnabled => _player.shuffleModeEnabled;

  /// Current repeat mode.
  LoopMode get loopMode => _player.loopMode;

  /// High-frequency position stream for seek bars.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Duration stream reflecting the loaded audio duration.
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Player state stream for play/pause transitions.
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Configures native Android/iOS audio session for music playback with ducking/interruption handling.
  Future<void> _initAudioSession() async {
    if (_isInitialized) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(0.5);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              _player.pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(1.0);
              break;
            case AudioInterruptionType.pause:
              _player.play();
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      });
      _isInitialized = true;
    } catch (_) {
      // AudioSession may be unavailable in test environments
    }
  }

  /// Initializes the system media notification service with controls:
  /// [Favorite, Previous, Play/Pause, Next] and no stop button.
  Future<void> initAudioService() async {
    if (_audioHandler != null) return;
    try {
      _audioHandler = await AudioService.init(
        builder: () => AnimaAudioHandler(
          _player,
          onSkipToNext: skipToNext,
          onSkipToPrevious: skipToPrevious,
          onToggleFavorite: toggleCurrentSongFavorite,
          isFavorite: () =>
              _currentSong != null &&
              FavoriteSongsDao.instance.isFavorite(_currentSong!.mediaStoreId),
        ),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.example.project_anima.channel.audio',
          androidNotificationChannelName: 'Project Anima Reproductor',
          androidNotificationChannelDescription:
              'Control de reproducción y notificación en tiempo real de Project Anima',
          androidNotificationIcon: 'mipmap/ic_launcher',
          androidNotificationOngoing: false,
          androidStopForegroundOnPause: true,
          androidResumeOnClick: false,
        ),
      );

      FavoriteSongsDao.instance.favoritesRevision.addListener(_onFavoritesRevisionChanged);
    } catch (e) {
      debugPrint('PlaybackController Error initializing AudioService: $e');
    }
  }

  void _onFavoritesRevisionChanged() {
    _audioHandler?.broadcastCurrentState();
  }

  /// Toggles favorite status for the currently playing song from system notification or UI.
  Future<void> toggleCurrentSongFavorite() async {
    if (_currentSong == null) return;
    await FavoriteSongsDao.instance.toggleFavorite(_currentSong!);
    _audioHandler?.broadcastCurrentState();
  }

  /// Completely stops audio playback, dismisses notification, and clears buffer.
  Future<void> stopAndClose() async {
    try {
      _stopPersistencePersister();
      await saveCurrentSessionImmediate();
      await _player.stop();
      await _audioBuffer.clear();
      await _audioHandler?.stop();
      _currentSong = null;
      _activePlaylistId = null;
      _queue.clear();
      _currentIndex = -1;
      notifyListeners();
    } catch (e) {
      debugPrint('PlaybackController Error stopping playback: $e');
    }
  }

  /// Starts periodic persistence while audio is playing.
  void _startPersistencePersister() {
    _persistenceCoordinator.startThrottledPersister(
      isPlaying: () => _player.playing,
      getCurrentSong: () => _currentSong,
      getQueue: () => _queue,
      getCurrentIndex: () => _currentIndex,
      getPosition: () => _player.position,
      isShuffleEnabled: () => _player.shuffleModeEnabled,
      getLoopMode: () => _player.loopMode,
    );
  }

  /// Stops periodic persistence when audio is paused or stopped.
  void _stopPersistencePersister() {
    _persistenceCoordinator.stopThrottledPersister();
  }

  /// Internal unawaited trigger for immediate state persistence.
  void _persistCurrentSessionImmediate({Duration? overridePosition}) {
    if (_currentSong == null) return;
    unawaited(_persistenceCoordinator.persistImmediate(
      currentSong: _currentSong,
      queue: _queue,
      currentIndex: _currentIndex,
      position: overridePosition ?? _player.position,
      shuffleEnabled: _player.shuffleModeEnabled,
      loopMode: _player.loopMode,
    ));
  }

  /// Immediately persists the active playback session snapshot to SQLite.
  Future<void> saveCurrentSessionImmediate() async {
    if (_currentSong == null) return;
    await _persistenceCoordinator.persistImmediate(
      currentSong: _currentSong,
      queue: _queue,
      currentIndex: _currentIndex,
      position: _player.position,
      shuffleEnabled: _player.shuffleModeEnabled,
      loopMode: _player.loopMode,
    );
  }

  /// Restores the last active playback session from SQLite across app restarts.
  /// Preloads the audio source queue into the buffer in a paused state.
  Future<bool> restoreLastSession() async {
    final data = await _persistenceCoordinator.restoreSession();
    if (data == null) return false;

    _queue = data.queue;
    _currentIndex = data.currentIndex;
    _currentSong = data.song;

    try {
      await _player.setShuffleModeEnabled(data.shuffleEnabled);
      await _player.setLoopMode(data.loopMode);
      if (_queue.isNotEmpty) {
        await _audioBuffer.loadQueue(
          _queue,
          initialIndex: data.currentIndex,
          initialPosition: data.position,
        );
      } else {
        await _player.setFilePath(data.song.path, initialPosition: data.position);
      }
      await _player.pause();
    } catch (e) {
      debugPrint('PlaybackController Error preloading restored audio file: $e');
    }

    _updateSystemNotification(data.song);
    notifyListeners();
    return true;
  }

  /// Binds listeners to internal audio player streams.
  void _listenToStreams() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      _isBuffering = state.processingState == ProcessingState.buffering ||
          state.processingState == ProcessingState.loading;
      if (state.playing) {
        _startPersistencePersister();
      } else {
        _stopPersistencePersister();
      }
      notifyListeners();
    });

    _processingStateSubscription =
        _player.processingStateStream.listen((processingState) {
      if (processingState == ProcessingState.completed) {
        _handleTrackCompleted();
      }
    });

    _currentIndexSubscription = _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _queue.length) {
        _onTrackTransition(index);
      }
    });
  }

  /// Handles seamless 0ms track transition emitted by the audio buffer engine.
  void _onTrackTransition(int index) {
    if (index < 0 || index >= _queue.length) return;
    if (_currentIndex == index && _currentSong?.mediaStoreId == _queue[index].mediaStoreId) {
      return;
    }

    _currentIndex = index;
    _currentSong = _queue[index];

    _updateSystemNotification(_currentSong!);
    _persistCurrentSessionImmediate();
    _recordPlaybackHistory(_currentSong!);
    notifyListeners();
  }

  /// Records playback history in SQLite asynchronously without blocking the audio engine.
  void _recordPlaybackHistory(Song song) {
    unawaited(() async {
      try {
        var songDbId = song.id;
        if (songDbId == null) {
          final dbSong = await _songDao.getSongByMediaStoreId(song.mediaStoreId);
          songDbId = dbSong?.id ?? song.mediaStoreId;
        }
        await _songDao.recordPlayback(
          songId: songDbId,
          artist: song.artist,
        );
      } catch (e) {
        debugPrint('PlaybackController Error recording playback history: $e');
      }
    }());
  }

  /// Auto-advances or stops when the entire playlist reaches completion.
  void _handleTrackCompleted() {
    if (_player.loopMode == LoopMode.one) {
      _player.seek(Duration.zero);
      _player.play();
      return;
    }

    if (_player.loopMode == LoopMode.all && _queue.isNotEmpty) {
      if (_audioBuffer.hasSource) {
        _audioBuffer.seekToIndex(0);
        _player.play();
      } else {
        _playIndex(0);
      }
      return;
    }

    // Natural end of queue with LoopMode.off
    _player.pause();
    _player.seek(Duration.zero);
    _persistCurrentSessionImmediate(overridePosition: Duration.zero);
    notifyListeners();
  }

  /// Resolves the filesystem URI or MediaStore content URI for notification artwork.
  Uri? _resolveArtUri(Song song) {
    try {
      final coverPath = ArtworkService.instance.getCoverPath(
        song.mediaStoreId,
        albumId: song.albumId,
      );
      if (coverPath != null && File(coverPath).existsSync()) {
        return Uri.file(coverPath);
      }
      final thumbPath = ArtworkService.instance.getThumbnailPath(
        song.mediaStoreId,
        albumId: song.albumId,
      );
      if (thumbPath != null && File(thumbPath).existsSync()) {
        return Uri.file(thumbPath);
      }
      if (song.albumId != null && song.albumId! > 0) {
        return Uri.parse('content://media/external/audio/albumart/${song.albumId}');
      }
    } catch (_) {}
    return null;
  }

  /// Updates the system notification metadata (title, artist, album, artUri, duration).
  void _updateSystemNotification(Song song) {
    final title = song.title.trim().isEmpty ? 'Canción' : song.title;
    final artist = (song.artist == null || song.artist!.trim().isEmpty)
        ? '<Desconocido>'
        : song.artist!;
    final album = (song.album == null || song.album!.trim().isEmpty)
        ? '<Desconocido>'
        : song.album!;

    final mediaItem = MediaItem(
      id: '${song.id ?? song.mediaStoreId}',
      album: album,
      title: title,
      artist: artist,
      duration: Duration(milliseconds: song.duration),
      artUri: _resolveArtUri(song),
    );

    _audioHandler?.updateMetadata(mediaItem);
    _audioHandler?.broadcastCurrentState();
  }

  /// Requests notification permissions on Android 13+ (API 33+) to guarantee system media widget display.
  Future<void> _checkNotificationPermission() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      }
    } catch (_) {}
  }

  /// Checks whether a new queue matches the currently active queue in memory and buffer.
  bool _isSameQueue(List<Song>? newQueue) {
    if (newQueue == null || newQueue.isEmpty) return false;
    if (!_audioBuffer.hasSource || _queue.length != newQueue.length) return false;
    if (_queue.first.mediaStoreId != newQueue.first.mediaStoreId ||
        _queue.last.mediaStoreId != newQueue.last.mediaStoreId) {
      return false;
    }
    for (int i = 0; i < _queue.length; i++) {
      if (_queue[i].mediaStoreId != newQueue[i].mediaStoreId) return false;
    }
    return true;
  }

  /// Plays a specific [Song] and optionally initializes or replaces the active [queue].
  /// Utilizes the gapless [AudioPlaybackBuffer] with lookahead pre-buffering for 0ms transitions.
  /// If the track belongs to the already active queue, seeks instantly without rebuilding the buffer.
  Future<void> playSong(Song song, {List<Song>? queue, int? playlistId}) async {
    unawaited(_checkNotificationPermission());

    _activePlaylistId = playlistId;

    // Fast-path: If the queue is identical to what's already buffered, seek instantly in 0ms!
    if (_isSameQueue(queue)) {
      final targetIndex = _queue.indexWhere((s) => s.id == song.id || s.mediaStoreId == song.mediaStoreId);
      if (targetIndex != -1) {
        _currentIndex = targetIndex;
        _currentSong = _queue[targetIndex];
        notifyListeners();

        try {
          await _audioBuffer.seekToIndex(targetIndex);
          await _player.play();

          _persistCurrentSessionImmediate();
          _updateSystemNotification(_currentSong!);
          _recordPlaybackHistory(_currentSong!);
        } catch (e) {
          debugPrint('PlaybackController Error seeking to track in active buffer: $e');
        }
        return;
      }
    }

    // 1. Update queue in memory
    if (queue != null && queue.isNotEmpty) {
      _queue = List<Song>.from(queue);
      _currentIndex = _queue.indexWhere((s) => s.id == song.id || s.mediaStoreId == song.mediaStoreId);
      if (_currentIndex == -1) {
        _queue.insert(0, song);
        _currentIndex = 0;
      }
    } else {
      _queue = [song];
      _currentIndex = 0;
    }

    _currentSong = song;
    notifyListeners();

    // 2. Load queue into the 0ms pre-buffering engine and start playback
    try {
      await _audioBuffer.loadQueue(
        _queue,
        initialIndex: _currentIndex,
        initialPosition: Duration.zero,
      );
      await _player.play();

      _persistCurrentSessionImmediate();
      _updateSystemNotification(song);
      _recordPlaybackHistory(song);
    } catch (e) {
      debugPrint('PlaybackController Error loading audio queue: $e');
    }
  }

  /// Internal helper to play a track by queue index using the buffer.
  Future<void> _playIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    try {
      _currentIndex = index;
      _currentSong = _queue[index];
      notifyListeners();

      if (_audioBuffer.hasSource) {
        await _audioBuffer.seekToIndex(index);
      } else {
        await _audioBuffer.loadQueue(_queue, initialIndex: index);
      }
      await _player.play();

      _persistCurrentSessionImmediate();
      _updateSystemNotification(_currentSong!);
      _recordPlaybackHistory(_currentSong!);
    } catch (e) {
      debugPrint('PlaybackController Error loading audio buffer at index $index: $e');
    }
  }

  /// Toggles between playing and paused states.
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  /// Resumes playback.
  Future<void> play() async {
    await _player.play();
    _persistCurrentSessionImmediate();
    notifyListeners();
  }

  /// Pauses playback.
  Future<void> pause() async {
    await _player.pause();
    _persistCurrentSessionImmediate();
    notifyListeners();
  }

  /// Seeks to a specific [position].
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _persistCurrentSessionImmediate(overridePosition: position);
  }

  /// Skips to the next track in the queue with instantaneous 0ms transition.
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;

    if (_audioBuffer.hasSource && _player.hasNext) {
      await _audioBuffer.seekToNext();
    } else if (_currentIndex < _queue.length - 1) {
      await _playIndex(_currentIndex + 1);
    } else if (_player.loopMode == LoopMode.all && _queue.isNotEmpty) {
      if (_audioBuffer.hasSource) {
        await _audioBuffer.seekToIndex(0);
      } else {
        await _playIndex(0);
      }
    } else {
      await _player.seek(Duration.zero);
      _persistCurrentSessionImmediate(overridePosition: Duration.zero);
    }
  }

  /// Skips to the previous track or restarts the current song if past 3 seconds.
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;

    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      _persistCurrentSessionImmediate(overridePosition: Duration.zero);
      return;
    }

    if (_audioBuffer.hasSource && _player.hasPrevious) {
      await _audioBuffer.seekToPrevious();
    } else if (_currentIndex > 0) {
      await _playIndex(_currentIndex - 1);
    } else if (_player.loopMode == LoopMode.all && _queue.isNotEmpty) {
      if (_audioBuffer.hasSource) {
        await _audioBuffer.seekToIndex(_queue.length - 1);
      } else {
        await _playIndex(_queue.length - 1);
      }
    } else {
      await _player.seek(Duration.zero);
      _persistCurrentSessionImmediate(overridePosition: Duration.zero);
    }
  }

  /// Toggles shuffle mode.
  Future<void> toggleShuffle() async {
    final nextShuffle = !_player.shuffleModeEnabled;
    if (nextShuffle) {
      await _player.shuffle();
    }
    await _player.setShuffleModeEnabled(nextShuffle);
    _persistCurrentSessionImmediate();
    notifyListeners();
  }

  /// Cycles loop mode: off -> all -> one -> off.
  Future<void> toggleLoopMode() async {
    final LoopMode nextMode;
    switch (_player.loopMode) {
      case LoopMode.off:
        nextMode = LoopMode.all;
        break;
      case LoopMode.all:
        nextMode = LoopMode.one;
        break;
      case LoopMode.one:
        nextMode = LoopMode.off;
        break;
    }
    await _player.setLoopMode(nextMode);
    _persistCurrentSessionImmediate();
    notifyListeners();
  }

  /// Adds a song to the beginning of the active queue (next up to play) without interrupting playback.
  /// Dynamically inserts the track into the pre-buffering engine so it is preloaded next.
  void addToQueue(Song song) => addToQueueFirst(song);

  /// Adds a song to the beginning of upcoming queue (play next) without interrupting playback.
  void addToQueueFirst(Song song) {
    if (_queue.isEmpty || _currentIndex < 0) {
      _queue.insert(0, song);
      _currentIndex = 0;
      _currentSong = song;
      unawaited(_audioBuffer.insert(0, song));
    } else {
      final insertIndex = (_currentIndex + 1).clamp(0, _queue.length);
      _queue.insert(insertIndex, song);
      unawaited(_audioBuffer.insert(insertIndex, song));
    }
    notifyListeners();
  }

  /// Appends a song to the very end of the playback queue without interrupting playback.
  void addToQueueEnd(Song song) {
    if (_queue.isEmpty || _currentIndex < 0) {
      _queue.add(song);
      _currentIndex = 0;
      _currentSong = song;
      unawaited(_audioBuffer.add(song));
    } else {
      _queue.add(song);
      unawaited(_audioBuffer.add(song));
    }
    notifyListeners();
  }

  /// Plays the song at the specified [index] within the active queue.
  Future<void> playFromQueue(int index) async {
    await _playIndex(index);
  }

  /// Reorders items in the queue from [oldIndex] to [newIndex] and updates the buffer.
  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    final currentPlaying = _currentSong;
    final movedItem = _queue.removeAt(oldIndex);
    final targetIndex = newIndex.clamp(0, _queue.length);
    _queue.insert(targetIndex, movedItem);

    if (currentPlaying != null) {
      _currentIndex = _queue.indexOf(currentPlaying);
    }
    unawaited(_audioBuffer.move(oldIndex, targetIndex));
    notifyListeners();
  }

  /// Removes the song at [index] from the queue and updates the buffer.
  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    final currentPlaying = _currentSong;
    _queue.removeAt(index);

    if (currentPlaying != null) {
      _currentIndex = _queue.indexOf(currentPlaying);
    }
    unawaited(_audioBuffer.removeAt(index));
    notifyListeners();
  }

  /// Clears upcoming tracks in the queue while preserving the active song.
  void clearUpcomingQueue() {
    if (_currentSong != null) {
      _queue = [_currentSong!];
      _currentIndex = 0;
      unawaited(_audioBuffer.clearUpcoming(0));
    } else {
      _queue.clear();
      _currentIndex = -1;
      unawaited(_audioBuffer.clear());
    }
    notifyListeners();
  }

  /// Injects a testing queue and current index without triggering audio player.
  @visibleForTesting
  void setQueueForTesting(List<Song> testQueue, {int currentIndex = 0}) {
    _queue = List<Song>.from(testQueue);
    _currentIndex = currentIndex;
    if (currentIndex >= 0 && currentIndex < testQueue.length) {
      _currentSong = testQueue[currentIndex];
    } else {
      _currentSong = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    FavoriteSongsDao.instance.favoritesRevision.removeListener(_onFavoritesRevisionChanged);
    _persistenceCoordinator.dispose();
    _playerStateSubscription?.cancel();
    _processingStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _audioBuffer.dispose();
    _player.dispose();
    super.dispose();
  }
}

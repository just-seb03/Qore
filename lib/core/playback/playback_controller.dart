/// File: playback_controller.dart
/// Description: High-performance, zero-jank audio playback controller coordinating
/// just_audio ExoPlayer backend, AudioPlaybackBuffer 0ms gapless buffering, AudioSession
/// audio focus, queue management, and reactive playback states for Project Anima.
///
/// Components / Classes / Functions:
/// - PlaybackController: Singleton ChangeNotifier coordinating playback, streams, and queue.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project_anima/core/artwork/artwork_color_extractor.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/dao/app_metadata_dao.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/audio_handler.dart';
import 'package:project_anima/core/playback/audio_playback_buffer.dart';
import 'package:project_anima/core/playback/playback_persistence_coordinator.dart';
import 'package:project_anima/core/scanner/bpm_analyzer.dart';
import 'package:project_anima/features/ambient_particles/controllers/ambient_particles_controller.dart';

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
  List<Song> _originalQueue = [];
  int _currentIndex = -1;
  int? _activePlaylistId;
  bool _isBuffering = false;
  bool _isInitialized = false;
  bool _isShuffleEnabled = false;
  bool _isSyncingBuffer = false;
  int? _resolvingBpmMediaStoreId;
  int? _resolvingColorMediaStoreId;
  int? _resolvedCoverColorSongId;
  int? _notifiedArtUriSongId;

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
    ArtworkService.instance.addListener(_onArtworkServiceUpdated);
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

  /// Current playback queue (zero-copy unmodifiable view).
  List<Song> get queue => UnmodifiableListView(_queue);

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
  bool get isShuffleEnabled => _isShuffleEnabled;

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
      unawaited(syncListeningTimeFromStorage());
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
      _originalQueue.clear();
      _currentIndex = -1;
      _resolvedCoverColorSongId = null;
      AmbientParticlesController.instance.syncWithPlayback(
        bpm: null,
        isPlaying: false,
        waveColor: ArtworkColorExtractor.defaultWaveColor,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('PlaybackController Error stopping playback: $e');
    }
  }

  final Stopwatch _listeningStopwatch = Stopwatch();
  Timer? _listeningUiTimer;
  int _persistedBaseListeningMs = 0;
  int _listeningTickCount = 0;

  /// Live total active listening time in milliseconds (updated every second while playing).
  final ValueNotifier<int> liveListeningTimeMsNotifier = ValueNotifier<int>(0);

  /// Starts periodic persistence while audio is playing.
  void _startPersistencePersister() {
    _startListeningTracker();
    _persistenceCoordinator.startThrottledPersister(
      isPlaying: () => _player.playing,
      getCurrentSong: () => _currentSong,
      getQueue: () => _queue,
      getCurrentIndex: () => _currentIndex,
      getPosition: () => _player.position,
      isShuffleEnabled: () => _isShuffleEnabled,
      getLoopMode: () => _player.loopMode,
    );
  }

  /// Stops periodic persistence when audio is paused or stopped.
  void _stopPersistencePersister() {
    _stopListeningTracker();
    _persistenceCoordinator.stopThrottledPersister();
  }

  void _startListeningTracker() {
    if (!_listeningStopwatch.isRunning) {
      _listeningStopwatch.start();
    }
    _listeningUiTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      final int liveMs =
          _persistedBaseListeningMs + _listeningStopwatch.elapsedMilliseconds;
      if (liveListeningTimeMsNotifier.value != liveMs) {
        liveListeningTimeMsNotifier.value = liveMs;
      }
      _listeningTickCount++;
      if (_listeningTickCount >= 15) {
        _listeningTickCount = 0;
        unawaited(flushListeningTime());
      }
    });
  }

  void _stopListeningTracker() {
    _listeningUiTimer?.cancel();
    _listeningUiTimer = null;
    _listeningTickCount = 0;
    if (_listeningStopwatch.isRunning) {
      _listeningStopwatch.stop();
    }
    unawaited(flushListeningTime());
  }

  /// Flushes any accumulated real playback milliseconds to SQLite `app_metadata`.
  Future<void> flushListeningTime() async {
    final int delta = _listeningStopwatch.elapsedMilliseconds;
    if (delta <= 0) return;
    _listeningStopwatch.reset();
    _persistedBaseListeningMs = await AppMetadataDao.instance.addListeningTimeMs(
      delta,
    );
    liveListeningTimeMsNotifier.value =
        _persistedBaseListeningMs + _listeningStopwatch.elapsedMilliseconds;
  }

  /// Reloads persisted listening time into the live notifier (e.g. after JSON import).
  Future<void> syncListeningTimeFromStorage() async {
    _listeningStopwatch.reset();
    _persistedBaseListeningMs =
        await AppMetadataDao.instance.getTotalListeningTimeMs();
    liveListeningTimeMsNotifier.value = _persistedBaseListeningMs;
  }

  /// Resets in-memory listening time counters to 0 (e.g. after clearing user data).
  void resetListeningTime() {
    _listeningStopwatch.reset();
    _persistedBaseListeningMs = 0;
    liveListeningTimeMsNotifier.value = 0;
  }

  /// Internal unawaited trigger for immediate state persistence.
  void _persistCurrentSessionImmediate({Duration? overridePosition}) {
    if (_currentSong == null) return;
    unawaited(_persistenceCoordinator.persistImmediate(
      currentSong: _currentSong,
      queue: _queue,
      currentIndex: _currentIndex,
      position: overridePosition ?? _player.position,
      shuffleEnabled: _isShuffleEnabled,
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
      shuffleEnabled: _isShuffleEnabled,
      loopMode: _player.loopMode,
    );
  }

  /// Restores the last active playback session from SQLite across app restarts.
  /// Preloads the audio source queue into the buffer in a paused state.
  Future<bool> restoreLastSession() async {
    final data = await _persistenceCoordinator.restoreSession();
    if (data == null) return false;

    _queue = data.queue;
    _originalQueue = List<Song>.from(data.queue);
    _currentIndex = data.currentIndex;
    _currentSong = data.song;
    _isShuffleEnabled = data.shuffleEnabled;

    try {
      await _player.setShuffleModeEnabled(false);
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
    _syncAmbientBackdropBpm(resolveIfMissing: true);
    notifyListeners();
    return true;
  }

  void _onArtworkServiceUpdated() {
    final active = _currentSong;
    if (active == null) return;
    if (_notifiedArtUriSongId != active.mediaStoreId) {
      final artUri = _resolveArtUri(active);
      if (artUri != null) {
        _updateSystemNotification(active);
      }
    }
    if (_resolvedCoverColorSongId == active.mediaStoreId) return;
    unawaited(_resolvePlayingSongCoverColor(active));
  }

  void _prioritizeActiveAndNeighborArtwork() {
    if (_queue.isEmpty || _currentIndex < 0 || _currentIndex >= _queue.length) return;
    final List<int> ids = [_queue[_currentIndex].mediaStoreId];
    if (_queue.length > 1) {
      final int nextIdx = (_currentIndex + 1) % _queue.length;
      final int prevIdx = (_currentIndex - 1 + _queue.length) % _queue.length;
      ids.add(_queue[nextIdx].mediaStoreId);
      if (prevIdx != nextIdx) ids.add(_queue[prevIdx].mediaStoreId);
    }
    ArtworkService.instance.prioritizeSongIds(ids);
  }

  /// Synchronizes ambient wave velocity, cover color, and rhythmic beat phase with active playback.
  void _syncAmbientBackdropBpm({
    bool resolveIfMissing = false,
    bool? overridePlaying,
  }) {
    _prioritizeActiveAndNeighborArtwork();
    final active = _currentSong;
    final bool isPlaying = overridePlaying ?? _player.playing;
    final Color? cachedColor =
        active != null ? ArtworkColorExtractor.getCachedColorForSong(active) : null;

    AmbientParticlesController.instance.syncWithPlayback(
      bpm: active?.bpm,
      isPlaying: isPlaying,
      waveColor: cachedColor,
    );

    if (active == null) return;

    if (cachedColor != null) {
      _resolvedCoverColorSongId = active.mediaStoreId;
    } else if (_resolvingColorMediaStoreId != active.mediaStoreId) {
      unawaited(_resolvePlayingSongCoverColor(active));
    }

    if (resolveIfMissing &&
        (active.bpm == null || active.bpm! <= 0) &&
        _resolvingBpmMediaStoreId != active.mediaStoreId) {
      unawaited(_resolvePlayingSongBpm(active));
    }
  }

  /// Resolves the dominant cover art color for the currently playing song on demand.
  Future<void> _resolvePlayingSongCoverColor(Song song) async {
    _resolvingColorMediaStoreId = song.mediaStoreId;
    try {
      final Color resolvedColor =
          await ArtworkColorExtractor.getDominantColorForSong(song);
      if (resolvedColor != ArtworkColorExtractor.defaultWaveColor) {
        _resolvedCoverColorSongId = song.mediaStoreId;
      }
      if (_currentSong?.mediaStoreId == song.mediaStoreId) {
        AmbientParticlesController.instance.setWaveColor(resolvedColor);
      }
    } finally {
      if (_resolvingColorMediaStoreId == song.mediaStoreId) {
        _resolvingColorMediaStoreId = null;
      }
    }
  }

  /// Lazily resolves a missing BPM for the currently playing track without blocking playback.
  Future<void> _resolvePlayingSongBpm(Song song) async {
    _resolvingBpmMediaStoreId = song.mediaStoreId;
    try {
      double? resolvedBpm;
      try {
        final dbSong = await _songDao.getSongByMediaStoreId(song.mediaStoreId);
        if (dbSong?.bpm != null && dbSong!.bpm! > 0) {
          resolvedBpm = dbSong.bpm;
        }
      } catch (_) {}

      if (resolvedBpm == null && song.path.isNotEmpty && File(song.path).existsSync()) {
        resolvedBpm = await BpmAnalyzer.analyzeAudioFile(
          song.path,
          durationMs: song.duration,
        );
        if (resolvedBpm != null && resolvedBpm > 0) {
          try {
            await _songDao.updateSongBpm(
              mediaStoreId: song.mediaStoreId,
              bpm: resolvedBpm,
            );
          } catch (_) {}
        }
      }

      if (resolvedBpm != null && resolvedBpm > 0) {
        final qIdx = _queue.indexWhere((s) => s.mediaStoreId == song.mediaStoreId);
        if (qIdx != -1) {
          _queue[qIdx] = _queue[qIdx].copyWith(bpm: resolvedBpm);
        }
        if (_currentSong?.mediaStoreId == song.mediaStoreId) {
          _currentSong = _currentSong!.copyWith(bpm: resolvedBpm);
          AmbientParticlesController.instance.syncWithPlayback(
            bpm: resolvedBpm,
            isPlaying: _player.playing,
          );
          notifyListeners();
        }
      }
    } finally {
      if (_resolvingBpmMediaStoreId == song.mediaStoreId) {
        _resolvingBpmMediaStoreId = null;
      }
    }
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
      _syncAmbientBackdropBpm();
      notifyListeners();
    });

    _processingStateSubscription =
        _player.processingStateStream.listen((processingState) {
      if (processingState == ProcessingState.completed) {
        _handleTrackCompleted();
      }
    });

    _currentIndexSubscription = _player.currentIndexStream.listen((index) {
      if (_isSyncingBuffer) return;
      final logicalIndex = _audioBuffer.toLogicalIndex(index);
      if (logicalIndex != null && logicalIndex >= 0 && logicalIndex < _queue.length) {
        _onTrackTransition(logicalIndex);
      }
    });
  }

  /// Handles seamless 0ms track transition emitted by the audio buffer engine.
  void _onTrackTransition(int index) {
    if (index < 0 || index >= _queue.length) return;
    unawaited(_audioBuffer.ensureWindowForIndex(index));
    if (_currentIndex == index && _currentSong?.mediaStoreId == _queue[index].mediaStoreId) {
      return;
    }

    _currentIndex = index;
    _currentSong = _queue[index];

    _updateSystemNotification(_currentSong!, forcePlaying: _player.playing);
    _persistCurrentSessionImmediate();
    _recordPlaybackHistory(_currentSong!);
    _syncAmbientBackdropBpm(resolveIfMissing: true);
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
        album: song.album,
        artist: song.albumArtist ?? song.artist,
      );
      if (coverPath != null && File(coverPath).existsSync()) {
        return Uri.file(coverPath);
      }
      final thumbPath = ArtworkService.instance.getThumbnailPath(
        song.mediaStoreId,
        albumId: song.albumId,
        album: song.album,
        artist: song.albumArtist ?? song.artist,
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
  void _updateSystemNotification(Song song, {bool? forcePlaying}) {
    final title = song.title.trim().isEmpty ? 'Canción' : song.title;
    final artist = (song.artist == null || song.artist!.trim().isEmpty)
        ? '<Desconocido>'
        : song.artist!;
    final album = (song.album == null || song.album!.trim().isEmpty)
        ? '<Desconocido>'
        : song.album!;

    final resolvedDuration = song.duration > 0
        ? Duration(milliseconds: song.duration)
        : (_player.duration ?? Duration.zero);
    final artUri = _resolveArtUri(song);
    if (artUri != null) {
      _notifiedArtUriSongId = song.mediaStoreId;
    }

    final mediaItem = MediaItem(
      id: '${song.mediaStoreId}_${song.path.hashCode}',
      album: album,
      title: title,
      artist: artist,
      duration: resolvedDuration,
      artUri: artUri,
    );

    _audioHandler?.updateMetadata(mediaItem, forcePlaying: forcePlaying);
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

  /// Null-safe identity check for matching two [Song] instances.
  bool _matchesSong(Song a, Song b) {
    if (a.mediaStoreId > 0 && b.mediaStoreId > 0) {
      return a.mediaStoreId == b.mediaStoreId;
    }
    if (a.id != null && b.id != null) {
      return a.id == b.id;
    }
    return a.path == b.path;
  }

  /// Builds a shuffled queue keeping [current] at index 0 followed by all remaining tracks shuffled.
  List<Song> _buildShuffledQueue(Song current, List<Song> sourceQueue) {
    final remaining = sourceQueue.where((s) => !_matchesSong(s, current)).toList();
    remaining.shuffle();
    return [current, ...remaining];
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

  /// Resolves and applies standard Spotify queue rules for [song] and [queue]
  /// without invoking the native audio player backend.
  @visibleForTesting
  void prepareQueueForSong(Song song, {List<Song>? queue, int? playlistId}) {
    _activePlaylistId = playlistId;

    final List<Song> resolvedContext;
    if (queue != null && queue.isNotEmpty) {
      resolvedContext = List<Song>.from(queue);
      if (!resolvedContext.any((s) => _matchesSong(s, song))) {
        resolvedContext.insert(0, song);
      }
    } else {
      resolvedContext = [song];
    }
    _originalQueue = resolvedContext;

    if (_isShuffleEnabled && resolvedContext.length > 1) {
      _queue = _buildShuffledQueue(song, resolvedContext);
      _currentIndex = 0;
    } else {
      _queue = List<Song>.from(resolvedContext);
      _currentIndex = _queue.indexWhere((s) => _matchesSong(s, song));
      if (_currentIndex == -1) {
        _queue.insert(0, song);
        _currentIndex = 0;
      }
    }

    _currentSong = song;
    notifyListeners();
  }

  /// Plays a specific [Song] and optionally initializes or replaces the active [queue].
  /// Follows standard Spotify / conventional player queue rules:
  /// - Preserves full album/playlist/disc context in `_originalQueue`.
  /// - When shuffle is enabled, keeps the selected [song] at index 0 and shuffles all remaining context tracks into Up Next.
  /// - When shuffle is disabled, plays the context in natural order starting at [song]'s index.
  Future<void> playSong(
    Song song, {
    List<Song>? queue,
    int? playlistId,
    bool forceSequential = false,
  }) async {
    unawaited(_checkNotificationPermission());

    if (forceSequential && _isShuffleEnabled) {
      _isShuffleEnabled = false;
    }

    _activePlaylistId = playlistId;

    // 1. Fast-path: If shuffle is off and queue matches what's already buffered, seek instantly in 0ms!
    if (!_isShuffleEnabled && _isSameQueue(queue)) {
      final targetIndex = _queue.indexWhere((s) => _matchesSong(s, song));
      if (targetIndex != -1) {
        _currentIndex = targetIndex;
        _currentSong = _queue[targetIndex];
        notifyListeners();

        _isSyncingBuffer = true;
        try {
          await _audioBuffer.seekToIndex(targetIndex);
          unawaited(_player.play());

          _persistCurrentSessionImmediate();
          _updateSystemNotification(_currentSong!, forcePlaying: true);
          _recordPlaybackHistory(_currentSong!);
          _syncAmbientBackdropBpm(resolveIfMissing: true, overridePlaying: true);
        } catch (e) {
          debugPrint('PlaybackController Error seeking to track in active buffer: $e');
        } finally {
          _isSyncingBuffer = false;
        }
        return;
      }
    }

    // 2. Build active playback queue according to Spotify/conventional rules
    prepareQueueForSong(song, queue: queue, playlistId: playlistId);

    // 3. Load queue into the 0ms pre-buffering engine and start playback
    _isSyncingBuffer = true;
    try {
      if (_player.shuffleModeEnabled) {
        await _player.setShuffleModeEnabled(false);
      }
      await _audioBuffer.loadQueue(
        _queue,
        initialIndex: _currentIndex,
        initialPosition: Duration.zero,
      );
      if (_audioBuffer.toLogicalIndex(_player.currentIndex) != _currentIndex) {
        await _audioBuffer.seekToIndex(_currentIndex);
      }
      unawaited(_player.play());

      _persistCurrentSessionImmediate();
      _updateSystemNotification(song, forcePlaying: true);
      _recordPlaybackHistory(song);
      _syncAmbientBackdropBpm(resolveIfMissing: true, overridePlaying: true);
    } catch (e) {
      debugPrint('PlaybackController Error loading audio queue: $e');
    } finally {
      _isSyncingBuffer = false;
    }
  }

  /// Internal helper to play a track by queue index using the buffer.
  Future<void> _playIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _isSyncingBuffer = true;
    try {
      _currentIndex = index;
      _currentSong = _queue[index];
      notifyListeners();

      if (_audioBuffer.hasSource) {
        await _audioBuffer.seekToIndex(index);
      } else {
        await _audioBuffer.loadQueue(_queue, initialIndex: index);
      }
      unawaited(_player.play());

      _persistCurrentSessionImmediate();
      _updateSystemNotification(_currentSong!, forcePlaying: true);
      _recordPlaybackHistory(_currentSong!);
      _syncAmbientBackdropBpm(resolveIfMissing: true, overridePlaying: true);
    } catch (e) {
      debugPrint('PlaybackController Error loading audio buffer at index $index: $e');
    } finally {
      _isSyncingBuffer = false;
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
    AmbientParticlesController.instance.syncWithPlayback(
      bpm: _currentSong?.bpm,
      isPlaying: true,
    );
    await _player.play();
    _persistCurrentSessionImmediate();
    notifyListeners();
  }

  /// Pauses playback.
  Future<void> pause() async {
    await _player.pause();
    _syncAmbientBackdropBpm();
    _persistCurrentSessionImmediate();
    notifyListeners();
  }

  /// Seeks to a specific [position].
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _persistCurrentSessionImmediate(overridePosition: position);
  }

  /// Skips to the next track in the queue immediately, regardless of current playback position or state.
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;

    if (_currentIndex < 0) {
      await _playIndex(0);
    } else if (_currentIndex < _queue.length - 1) {
      await _playIndex(_currentIndex + 1);
    } else if (_player.loopMode == LoopMode.all) {
      await _playIndex(0);
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

    if (_currentIndex > 0) {
      await _playIndex(_currentIndex - 1);
    } else if (_player.loopMode == LoopMode.all) {
      await _playIndex(_queue.length - 1);
    } else {
      await _player.seek(Duration.zero);
      _persistCurrentSessionImmediate(overridePosition: Duration.zero);
    }
  }

  /// Toggles shuffle mode following standard Spotify queue rules:
  /// - Turning ON keeps the current song playing at index 0 and shuffles all remaining tracks.
  /// - Turning OFF restores the natural context order starting from the current song.
  Future<void> toggleShuffle() async {
    _isShuffleEnabled = !_isShuffleEnabled;
    final activeSong = _currentSong;

    if (activeSong != null && _queue.length > 1) {
      if (_isShuffleEnabled) {
        if (_originalQueue.isEmpty) {
          _originalQueue = List<Song>.from(_queue);
        }
        _queue = _buildShuffledQueue(activeSong, _queue);
        _currentIndex = 0;
      } else {
        if (_originalQueue.isNotEmpty) {
          _queue = List<Song>.from(_originalQueue);
          final idx = _queue.indexWhere((s) => _matchesSong(s, activeSong));
          _currentIndex = idx != -1 ? idx : 0;
        }
      }

      if (_audioBuffer.hasSource) {
        _isSyncingBuffer = true;
        try {
          final currentPos = _player.position;
          final wasPlaying = _player.playing;
          if (_player.shuffleModeEnabled) {
            await _player.setShuffleModeEnabled(false);
          }
          await _audioBuffer.loadQueue(
            _queue,
            initialIndex: _currentIndex,
            initialPosition: currentPos,
          );
          if (wasPlaying) {
            await _player.play();
          }
        } catch (e) {
          debugPrint('PlaybackController Error syncing shuffled queue: $e');
        } finally {
          _isSyncingBuffer = false;
        }
      }
    }

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
      _originalQueue.insert(0, song);
      _currentIndex = 0;
      _currentSong = song;
      if (_audioBuffer.hasSource) {
        unawaited(_audioBuffer.insert(0, song));
      } else {
        unawaited(_audioBuffer.loadQueue(_queue, initialIndex: 0));
      }
    } else {
      final insertIndex = (_currentIndex + 1).clamp(0, _queue.length);
      _queue.insert(insertIndex, song);
      if (!_originalQueue.any((s) => _matchesSong(s, song))) {
        _originalQueue.add(song);
      }
      if (_audioBuffer.hasSource) {
        unawaited(_audioBuffer.insert(insertIndex, song));
      }
    }
    _persistCurrentSessionImmediate();
    notifyListeners();
  }

  /// Appends a song to the very end of the playback queue without interrupting playback.
  void addToQueueEnd(Song song) {
    if (_queue.isEmpty || _currentIndex < 0) {
      _queue.add(song);
      _originalQueue.add(song);
      _currentIndex = 0;
      _currentSong = song;
      if (_audioBuffer.hasSource) {
        unawaited(_audioBuffer.add(song));
      } else {
        unawaited(_audioBuffer.loadQueue(_queue, initialIndex: 0));
      }
    } else {
      _queue.add(song);
      if (!_originalQueue.any((s) => _matchesSong(s, song))) {
        _originalQueue.add(song);
      }
      if (_audioBuffer.hasSource) {
        unawaited(_audioBuffer.add(song));
      }
    }
    _persistCurrentSessionImmediate();
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
      _originalQueue = [_currentSong!];
      _currentIndex = 0;
      unawaited(_audioBuffer.clearUpcoming(0));
    } else {
      _queue.clear();
      _originalQueue.clear();
      _currentIndex = -1;
      unawaited(_audioBuffer.clear());
    }
    _persistCurrentSessionImmediate();
    notifyListeners();
  }

  /// Injects a testing queue and current index without triggering audio player.
  @visibleForTesting
  void setQueueForTesting(List<Song> testQueue, {int currentIndex = 0, bool shuffleEnabled = false}) {
    _queue = List<Song>.from(testQueue);
    _originalQueue = List<Song>.from(testQueue);
    _isShuffleEnabled = shuffleEnabled;
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
    ArtworkService.instance.removeListener(_onArtworkServiceUpdated);
    FavoriteSongsDao.instance.favoritesRevision.removeListener(_onFavoritesRevisionChanged);
    _listeningUiTimer?.cancel();
    if (_listeningStopwatch.isRunning) {
      _listeningStopwatch.stop();
    }
    liveListeningTimeMsNotifier.dispose();
    _persistenceCoordinator.dispose();
    _playerStateSubscription?.cancel();
    _processingStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _audioBuffer.dispose();
    _player.dispose();
    super.dispose();
  }
}

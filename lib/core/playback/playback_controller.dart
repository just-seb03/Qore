/// File: playback_controller.dart
/// Description: High-performance, zero-jank audio playback controller coordinating
/// just_audio ExoPlayer backend, AudioSession audio focus, queue management,
/// and reactive playback states for Project Anima.
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
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/audio_handler.dart';

/// Centralized audio playback coordinator.
class PlaybackController extends ChangeNotifier {
  static final PlaybackController instance = PlaybackController._internal();

  final AudioPlayer _player;
  final SongDao _songDao;
  AnimaAudioHandler? _audioHandler;

  Song? _currentSong;
  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isBuffering = false;
  bool _isInitialized = false;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<ProcessingState>? _processingStateSubscription;

  PlaybackController({AudioPlayer? player, SongDao? songDao})
      : _player = player ?? AudioPlayer(),
        _songDao = songDao ?? SongDao() {
    _initAudioSession();
    _listenToStreams();
  }

  PlaybackController._internal()
      : _player = AudioPlayer(),
        _songDao = SongDao() {
    _initAudioSession();
    _listenToStreams();
  }

  /// Reference to active system notification handler.
  AnimaAudioHandler? get audioHandler => _audioHandler;

  /// Active track currently playing or paused.
  Song? get currentSong => _currentSong;

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

  /// Initializes the system media notification service with strict 3-button layout
  /// [Previous, Play/Pause, Next] and no stop button.
  Future<void> initAudioService() async {
    if (_audioHandler != null) return;
    try {
      _audioHandler = await AudioService.init(
        builder: () => AnimaAudioHandler(
          _player,
          onSkipToNext: skipToNext,
          onSkipToPrevious: skipToPrevious,
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
    } catch (e) {
      debugPrint('PlaybackController Error initializing AudioService: $e');
    }
  }

  /// Completely stops audio playback and dismisses the system media notification widget.
  Future<void> stopAndClose() async {
    try {
      await _player.stop();
      await _audioHandler?.stop();
      _currentSong = null;
      notifyListeners();
    } catch (e) {
      debugPrint('PlaybackController Error stopping playback: $e');
    }
  }

  /// Binds listeners to internal audio player streams.
  void _listenToStreams() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      _isBuffering = state.processingState == ProcessingState.buffering ||
          state.processingState == ProcessingState.loading;
      notifyListeners();
    });

    _processingStateSubscription =
        _player.processingStateStream.listen((processingState) {
      if (processingState == ProcessingState.completed) {
        _handleTrackCompleted();
      }
    });
  }

  /// Auto-advances to next track upon song completion based on queue and loop mode.
  void _handleTrackCompleted() {
    if (_player.loopMode == LoopMode.one) {
      _player.seek(Duration.zero);
      _player.play();
      return;
    }

    if (_queue.isNotEmpty && _currentIndex < _queue.length - 1) {
      skipToNext();
    } else if (_player.loopMode == LoopMode.all && _queue.isNotEmpty) {
      _playIndex(0);
    } else {
      _player.pause();
      _player.seek(Duration.zero);
    }
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

  /// Plays a specific [Song] and optionally initializes or replaces the active [queue].
  Future<void> playSong(Song song, {List<Song>? queue}) async {
    unawaited(_checkNotificationPermission());

    // 1. Update queue
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

    // 2. Load audio file and start playback
    try {
      await _player.setFilePath(song.path);
      await _player.play();

      // 3. Update system notification widget metadata
      _updateSystemNotification(song);

      // 4. Record playback history asynchronously in SQLite
      final songId = song.id ?? song.mediaStoreId;
      _songDao.recordPlayback(
        songId: songId,
        artist: song.artist,
      );
    } catch (e) {
      debugPrint('PlaybackController Error loading audio file: $e');
    }
  }

  /// Internal helper to play a track by queue index.
  Future<void> _playIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    try {
      _currentIndex = index;
      _currentSong = _queue[index];
      notifyListeners();

      await _player.setFilePath(_currentSong!.path);
      await _player.play();

      _updateSystemNotification(_currentSong!);

      final songId = _currentSong!.id ?? _currentSong!.mediaStoreId;
      _songDao.recordPlayback(
        songId: songId,
        artist: _currentSong!.artist,
      );
    } catch (e) {
      debugPrint('PlaybackController Error loading audio file at index $index: $e');
    }
  }

  /// Toggles between playing and paused states.
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  /// Resumes playback.
  Future<void> play() async {
    await _player.play();
    notifyListeners();
  }

  /// Pauses playback.
  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  /// Seeks to a specific [position].
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Skips to the next track in the queue.
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;

    if (_currentIndex < _queue.length - 1) {
      await _playIndex(_currentIndex + 1);
    } else if (_player.loopMode == LoopMode.all && _queue.isNotEmpty) {
      await _playIndex(0);
    } else {
      await _player.seek(Duration.zero);
    }
  }

  /// Skips to the previous track or restarts the current song if past 3 seconds.
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;

    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    if (_currentIndex > 0) {
      await _playIndex(_currentIndex - 1);
    } else if (_player.loopMode == LoopMode.all && _queue.isNotEmpty) {
      await _playIndex(_queue.length - 1);
    } else {
      await _player.seek(Duration.zero);
    }
  }

  /// Toggles shuffle mode.
  Future<void> toggleShuffle() async {
    final nextShuffle = !_player.shuffleModeEnabled;
    if (nextShuffle) {
      await _player.shuffle();
    }
    await _player.setShuffleModeEnabled(nextShuffle);
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
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _processingStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}

/// File: playback_persistence_coordinator.dart
/// Description: High-performance, low-coupling playback session persistence coordinator.
/// Manages intelligent write throttling during active playback and orchestrates
/// atomic state restoration on cold startup for Project Anima.
///
/// Components / Classes / Functions:
/// - PlaybackSessionRestorationData: Immutable record containing hydrated session state.
/// - PlaybackPersistenceCoordinator: Coordinates SQLite persistence and session hydration.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:project_anima/core/database/dao/playback_session_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/playback_session.dart';
import 'package:project_anima/core/database/models/song.dart';

/// Hydrated playback state ready to be applied to the audio engine.
class PlaybackSessionRestorationData {
  final Song song;
  final List<Song> queue;
  final int currentIndex;
  final Duration position;
  final bool shuffleEnabled;
  final LoopMode loopMode;

  const PlaybackSessionRestorationData({
    required this.song,
    required this.queue,
    required this.currentIndex,
    required this.position,
    required this.shuffleEnabled,
    required this.loopMode,
  });
}

/// Orchestrates disk writes and restoration with zero-jank throttling.
class PlaybackPersistenceCoordinator {
  final PlaybackSessionDao _sessionDao;
  final SongDao _songDao;

  Timer? _throttledTimer;
  int _lastPersistedPositionMs = -1;
  int? _lastPersistedSongId;
  bool _hasSavedFullSession = false;

  PlaybackPersistenceCoordinator({
    PlaybackSessionDao? sessionDao,
    SongDao? songDao,
  })  : _sessionDao = sessionDao ?? PlaybackSessionDao(),
        _songDao = songDao ?? SongDao();

  /// Starts periodic background persistence timer.
  /// Checks every 12 seconds and writes only `position_ms` when the track/queue hasn't changed.
  void startThrottledPersister({
    required bool Function() isPlaying,
    required Song? Function() getCurrentSong,
    required List<Song> Function() getQueue,
    required int Function() getCurrentIndex,
    required Duration Function() getPosition,
    required bool Function() isShuffleEnabled,
    required LoopMode Function() getLoopMode,
  }) {
    _throttledTimer?.cancel();
    _throttledTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!isPlaying()) return;
      final currentSong = getCurrentSong();
      if (currentSong == null) return;

      final currentPos = getPosition();
      final posDelta = (currentPos.inMilliseconds - _lastPersistedPositionMs).abs();
      final songChanged = _lastPersistedSongId != currentSong.mediaStoreId;

      if (songChanged || !_hasSavedFullSession) {
        _lastPersistedPositionMs = currentPos.inMilliseconds;
        _lastPersistedSongId = currentSong.mediaStoreId;
        _hasSavedFullSession = true;

        _sessionDao.saveSession(PlaybackSession(
          songMediaStoreId: currentSong.mediaStoreId,
          songId: currentSong.id,
          position: currentPos,
          queueMediaStoreIds: getQueue().map((s) => s.mediaStoreId).toList(),
          currentIndex: getCurrentIndex(),
          shuffleEnabled: isShuffleEnabled(),
          loopMode: getLoopMode(),
          updatedAt: DateTime.now(),
        ));
      } else if (posDelta >= 2000) {
        _lastPersistedPositionMs = currentPos.inMilliseconds;
        _sessionDao.updatePositionOnly(currentPos.inMilliseconds);
      }
    });
  }

  /// Stops the active periodic persister when playback is stopped or paused.
  void stopThrottledPersister() {
    _throttledTimer?.cancel();
    _throttledTimer = null;
  }

  /// Immediately persists active session snapshot to SQLite (bypassing throttle).
  /// Triggered on pause, seek, track change, and app lifecycle state detach.
  Future<void> persistImmediate({
    required Song? currentSong,
    required List<Song> queue,
    required int currentIndex,
    required Duration position,
    required bool shuffleEnabled,
    required LoopMode loopMode,
  }) async {
    if (currentSong == null) return;

    _lastPersistedPositionMs = position.inMilliseconds;
    _lastPersistedSongId = currentSong.mediaStoreId;
    _hasSavedFullSession = true;

    await _sessionDao.saveSession(PlaybackSession(
      songMediaStoreId: currentSong.mediaStoreId,
      songId: currentSong.id,
      position: position,
      queueMediaStoreIds: queue.map((s) => s.mediaStoreId).toList(),
      currentIndex: currentIndex,
      shuffleEnabled: shuffleEnabled,
      loopMode: loopMode,
      updatedAt: DateTime.now(),
    ));
  }

  /// Restores the last recorded playback session from SQLite.
  /// Verifies song and file integrity before returning restoration data.
  Future<PlaybackSessionRestorationData?> restoreSession() async {
    try {
      final session = await _sessionDao.getLastSession();
      if (session == null || session.songMediaStoreId == null) {
        return null;
      }

      // 1. Fetch active song from database
      final Song? activeSong =
          await _songDao.getSongByMediaStoreId(session.songMediaStoreId!);
      if (activeSong == null) {
        return null;
      }

      // 2. Validate file existence on device filesystem
      final file = File(activeSong.path);
      if (!await file.exists()) {
        debugPrint('Playback persistence: Audio file not found at ${activeSong.path}');
        return null;
      }

      // 3. Batch fetch queue maintaining original ordering
      List<Song> restoredQueue = [];
      if (session.queueMediaStoreIds.isNotEmpty) {
        restoredQueue =
            await _songDao.getSongsByMediaStoreIds(session.queueMediaStoreIds);
      }

      if (restoredQueue.isEmpty) {
        restoredQueue = [activeSong];
      } else if (!restoredQueue.any((s) => s.mediaStoreId == activeSong.mediaStoreId)) {
        restoredQueue.insert(0, activeSong);
      }

      // 4. Resolve safe queue index
      int index = session.currentIndex;
      if (index < 0 ||
          index >= restoredQueue.length ||
          restoredQueue[index].mediaStoreId != activeSong.mediaStoreId) {
        final found = restoredQueue
            .indexWhere((s) => s.mediaStoreId == activeSong.mediaStoreId);
        index = found != -1 ? found : 0;
      }

      // 5. Sanitize position bounds
      final safePosition =
          session.position.inMilliseconds >= activeSong.duration
              ? Duration.zero
              : session.position;

      _lastPersistedPositionMs = safePosition.inMilliseconds;
      _lastPersistedSongId = activeSong.mediaStoreId;
      _hasSavedFullSession = true;

      return PlaybackSessionRestorationData(
        song: activeSong,
        queue: restoredQueue,
        currentIndex: index,
        position: safePosition,
        shuffleEnabled: session.shuffleEnabled,
        loopMode: session.loopMode,
      );
    } catch (e) {
      debugPrint('PlaybackPersistenceCoordinator error restoring session: $e');
      return null;
    }
  }

  /// Clears the saved session from disk.
  Future<void> clearSession() async {
    _hasSavedFullSession = false;
    await _sessionDao.clearSession();
  }

  /// Disposes background timer.
  void dispose() {
    _throttledTimer?.cancel();
    _throttledTimer = null;
  }
}

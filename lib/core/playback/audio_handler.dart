/// File: audio_handler.dart
/// Description: Dedicated AudioService background handler for Project Anima.
/// Enforces a strict 4-action media notification layout [Favorite, Previous, Play/Pause, Next]
/// and guarantees immediate MediaMetadata + PlaybackState updates across Android / MIUI MediaSession.
///
/// Components / Classes / Functions:
/// - AnimaAudioHandler: Custom BaseAudioHandler routing system media controls to AudioPlayer.
library;

import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Custom background AudioHandler providing rock-solid notification controls & live metadata sync.
class AnimaAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;
  final Future<void> Function() onSkipToNext;
  final Future<void> Function() onSkipToPrevious;
  final Future<void> Function()? onToggleFavorite;
  final bool Function()? isFavorite;

  MediaItem? _lastMediaItem;
  StreamSubscription<PlaybackEvent>? _playbackEventSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration?>? _durationSub;

  AnimaAudioHandler(
    this._player, {
    required this.onSkipToNext,
    required this.onSkipToPrevious,
    this.onToggleFavorite,
    this.isFavorite,
  }) {
    _broadcastState(_player.playbackEvent);
    _playbackEventSub = _player.playbackEventStream.listen(_broadcastState);
    _playerStateSub = _player.playerStateStream.listen(
      (_) => _broadcastState(_player.playbackEvent),
    );
    _durationSub = _player.durationStream.listen((resolvedDuration) {
      if (resolvedDuration != null &&
          resolvedDuration > Duration.zero &&
          _lastMediaItem != null &&
          _lastMediaItem!.duration != resolvedDuration) {
        final updated = _lastMediaItem!.copyWith(duration: resolvedDuration);
        _lastMediaItem = updated;
        mediaItem.add(updated);
        queue.add([updated]);
        _broadcastState(_player.playbackEvent);
      }
    });
  }

  /// Manually re-broadcasts playback state (e.g. when favorite status toggles).
  void broadcastCurrentState({bool? forcePlaying}) {
    _broadcastState(_player.playbackEvent, forcePlaying: forcePlaying);
  }

  void _broadcastState(PlaybackEvent event, {bool? forcePlaying}) {
    final playing = forcePlaying ?? _player.playing;
    final isFav = isFavorite?.call() ?? false;

    final favoriteControl = MediaControl.custom(
      androidIcon: isFav ? 'drawable/ic_heart_filled' : 'drawable/ic_heart_outline',
      label: isFav ? 'Favorited' : 'Favorite',
      name: 'toggleFavorite',
    );

    // Media notification controls: [Favorite, Previous, Play/Pause, Next].
    final controls = [
      favoriteControl,
      MediaControl.skipToPrevious,
      playing ? MediaControl.pause : MediaControl.play,
      MediaControl.skipToNext,
    ];

    playbackState.add(playbackState.value.copyWith(
      controls: controls,
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.setRating,
      },
      androidCompactActionIndices: const [1, 2, 3],
      processingState: switch (_player.processingState) {
        ProcessingState.idle => forcePlaying == true
            ? AudioProcessingState.ready
            : AudioProcessingState.idle,
        ProcessingState.completed => AudioProcessingState.completed,
        ProcessingState.loading ||
        ProcessingState.buffering ||
        ProcessingState.ready =>
          AudioProcessingState.ready,
      },
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _lastMediaItem != null ? 0 : event.currentIndex,
    ));
  }

  /// Updates system notification metadata (`title`, `artist`, `album`, `artUri`, `duration`)
  /// and forces sequential `PlaybackStateCompat` refreshes so Android/MIUI SystemUI redraws reliably.
  void updateMetadata(MediaItem item, {bool? forcePlaying}) {
    _lastMediaItem = item;
    queue.add([item]);
    mediaItem.add(item);

    // Re-broadcast immediately and after channel delivery so Android/MIUI never drops metadata changes
    Future.microtask(() {
      if (_lastMediaItem?.id == item.id) {
        _broadcastState(_player.playbackEvent, forcePlaying: forcePlaying);
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      if (_lastMediaItem?.id == item.id) {
        _broadcastState(_player.playbackEvent);
      }
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => onSkipToNext();

  @override
  Future<void> skipToPrevious() => onSkipToPrevious();

  @override
  Future<void> setRating(Rating rating, [Map<String, dynamic>? extras]) async {
    await onToggleFavorite?.call();
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'toggleFavorite') {
      await onToggleFavorite?.call();
      return true;
    }
    return super.customAction(name, extras);
  }

  @override
  Future<void> stop() async {
    await _playbackEventSub?.cancel();
    await _playerStateSub?.cancel();
    await _durationSub?.cancel();
    await _player.stop();
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
    await super.stop();
  }
}

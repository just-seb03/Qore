/// File: audio_handler.dart
/// Description: Dedicated AudioService background handler for Project Anima.
/// Enforces a strict 3-action media notification layout [Previous, Play/Pause, Next]
/// with no redundant Stop button, eliminating action jumping and layout bugs on Android/MIUI.
///
/// Components / Classes / Functions:
/// - AnimaAudioHandler: Custom BaseAudioHandler routing system media controls to AudioPlayer.
library;

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Custom background AudioHandler providing rock-solid notification controls.
class AnimaAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;
  final Future<void> Function() onSkipToNext;
  final Future<void> Function() onSkipToPrevious;

  AnimaAudioHandler(
    this._player, {
    required this.onSkipToNext,
    required this.onSkipToPrevious,
  }) {
    _broadcastState(_player.playbackEvent);
    _player.playbackEventStream.listen(_broadcastState);
    _player.playerStateStream.listen((_) => _broadcastState(_player.playbackEvent));
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;

    // Strict 3-action control list: [Previous, Play/Pause, Next].
    // MediaControl.stop is strictly omitted to prevent Android/MIUI notification corruption.
    final controls = [
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
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: switch (_player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
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
      queueIndex: event.currentIndex,
    ));
  }

  /// Updates the system notification metadata (title, artist, album, artUri, duration).
  void updateMetadata(MediaItem item) {
    mediaItem.add(item);
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
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
    await super.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }
}

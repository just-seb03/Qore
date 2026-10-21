/// File: playback_session.dart
/// Description: Immutable data model encapsulating persistent playback session state,
/// including current track, queue order, seek position, shuffle, and repeat modes.
///
/// Components / Classes / Functions:
/// - PlaybackSession: Data class representing the active playback session snapshot.
library;

import 'dart:convert';
import 'package:just_audio/just_audio.dart';

/// Snapshot of the active playback session stored across app closures.
class PlaybackSession {
  final int? songMediaStoreId;
  final int? songId;
  final Duration position;
  final List<int> queueMediaStoreIds;
  final int currentIndex;
  final bool shuffleEnabled;
  final LoopMode loopMode;
  final DateTime updatedAt;

  const PlaybackSession({
    this.songMediaStoreId,
    this.songId,
    this.position = Duration.zero,
    this.queueMediaStoreIds = const [],
    this.currentIndex = 0,
    this.shuffleEnabled = false,
    this.loopMode = LoopMode.off,
    required this.updatedAt,
  });

  /// Serializes session state into SQLite column mapping.
  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'song_media_store_id': songMediaStoreId,
      'song_id': songId,
      'position_ms': position.inMilliseconds,
      'queue_media_store_ids': jsonEncode(queueMediaStoreIds),
      'current_index': currentIndex,
      'shuffle_enabled': shuffleEnabled ? 1 : 0,
      'loop_mode': loopMode.name,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Deserializes database record into a [PlaybackSession].
  factory PlaybackSession.fromMap(Map<String, dynamic> map) {
    List<int> decodedQueue = [];
    if (map['queue_media_store_ids'] != null) {
      try {
        final decoded = jsonDecode(map['queue_media_store_ids'] as String);
        if (decoded is List) {
          decodedQueue = decoded.map((e) => (e as num).toInt()).toList();
        }
      } catch (_) {}
    }

    final loopModeStr = map['loop_mode'] as String? ?? 'off';
    final parsedLoopMode = LoopMode.values.firstWhere(
      (m) => m.name == loopModeStr,
      orElse: () => LoopMode.off,
    );

    return PlaybackSession(
      songMediaStoreId: map['song_media_store_id'] as int?,
      songId: map['song_id'] as int?,
      position: Duration(milliseconds: (map['position_ms'] as int?) ?? 0),
      queueMediaStoreIds: decodedQueue,
      currentIndex: (map['current_index'] as int?) ?? 0,
      shuffleEnabled: ((map['shuffle_enabled'] as int?) ?? 0) == 1,
      loopMode: parsedLoopMode,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updated_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  PlaybackSession copyWith({
    int? songMediaStoreId,
    int? songId,
    Duration? position,
    List<int>? queueMediaStoreIds,
    int? currentIndex,
    bool? shuffleEnabled,
    LoopMode? loopMode,
    DateTime? updatedAt,
  }) {
    return PlaybackSession(
      songMediaStoreId: songMediaStoreId ?? this.songMediaStoreId,
      songId: songId ?? this.songId,
      position: position ?? this.position,
      queueMediaStoreIds: queueMediaStoreIds ?? this.queueMediaStoreIds,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      loopMode: loopMode ?? this.loopMode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackSession &&
          runtimeType == other.runtimeType &&
          songMediaStoreId == other.songMediaStoreId &&
          songId == other.songId &&
          position == other.position &&
          currentIndex == other.currentIndex &&
          shuffleEnabled == other.shuffleEnabled &&
          loopMode == other.loopMode;

  @override
  int get hashCode => Object.hash(
        songMediaStoreId,
        songId,
        position,
        currentIndex,
        shuffleEnabled,
        loopMode,
      );
}

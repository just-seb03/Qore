/// File: song.dart
/// Description: Immutable data model representing an audio track stored in SQLite.
/// Matches the schema and index specifications defined for high-performance retrieval.
///
/// Components / Classes / Functions:
/// - Song: Data class encapsulating song metadata and database mapping.
library;

/// Immutable domain and persistence model representing an audio track.
class Song {
  /// Internal SQLite primary key (auto-incremented).
  final int? id;

  /// Android MediaStore ID or deterministic unique integer ID across platforms.
  final int mediaStoreId;

  /// Song track title.
  final String title;

  /// Performing artist name. Defaults to `'<Desconocido>'` if null.
  final String? artist;

  /// Album title. Defaults to `'<Desconocido>'` if null.
  final String? album;

  /// Android MediaStore album ID, if available.
  final int? albumId;

  /// Track duration in milliseconds.
  final int duration;

  /// Full absolute filesystem path to the audio file.
  final String path;

  /// Last modification timestamp in seconds.
  final int dateModified;

  /// Timestamp when the track was added to the media store or filesystem.
  final int? dateAdded;

  /// File size in bytes.
  final int? size;

  const Song({
    this.id,
    required this.mediaStoreId,
    required this.title,
    this.artist,
    this.album,
    this.albumId,
    required this.duration,
    required this.path,
    required this.dateModified,
    this.dateAdded,
    this.size,
  });

  /// Converts the [Song] instance into a map for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'media_store_id': mediaStoreId,
      'title': title,
      'artist': (artist == null || artist!.trim().isEmpty) ? '<Desconocido>' : artist,
      'album': (album == null || album!.trim().isEmpty) ? '<Desconocido>' : album,
      'album_id': albumId,
      'duration': duration,
      'path': path,
      'date_modified': dateModified,
      'date_added': dateAdded,
      'size': size,
    };
  }

  /// Instantiates a [Song] from an SQLite query result map.
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as int?,
      mediaStoreId: map['media_store_id'] as int,
      title: map['title'] as String,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      albumId: map['album_id'] as int?,
      duration: (map['duration'] as int?) ?? 0,
      path: map['path'] as String,
      dateModified: (map['date_modified'] as int?) ?? 0,
      dateAdded: map['date_added'] as int?,
      size: map['size'] as int?,
    );
  }

  /// Creates a copy of this song with specified attributes updated.
  Song copyWith({
    int? id,
    int? mediaStoreId,
    String? title,
    String? artist,
    String? album,
    int? albumId,
    int? duration,
    String? path,
    int? dateModified,
    int? dateAdded,
    int? size,
  }) {
    return Song(
      id: id ?? this.id,
      mediaStoreId: mediaStoreId ?? this.mediaStoreId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      duration: duration ?? this.duration,
      path: path ?? this.path,
      dateModified: dateModified ?? this.dateModified,
      dateAdded: dateAdded ?? this.dateAdded,
      size: size ?? this.size,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song &&
          runtimeType == other.runtimeType &&
          mediaStoreId == other.mediaStoreId &&
          path == other.path;

  @override
  int get hashCode => mediaStoreId.hashCode ^ path.hashCode;

  @override
  String toString() {
    return 'Song(id: $id, mediaStoreId: $mediaStoreId, title: $title, artist: $artist, album: $album, duration: ${duration}ms)';
  }
}

/// File: playlist.dart
/// Description: Immutable domain model representing a user-created Playlist.
/// Contains metadata, track count, total duration, and optional cover artwork path.
///
/// Components / Classes / Functions:
/// - Playlist: Data class for playlists in the SQLite database.
library;

/// Immutable playlist data model.
class Playlist {
  /// Unique database identifier.
  final int? id;

  /// Custom name given to the playlist.
  final String name;

  /// Local filesystem path to custom picked playlist cover image, if any.
  final String? coverPath;

  /// Unix timestamp in milliseconds when playlist was created.
  final int createdAt;

  /// Unix timestamp in milliseconds when playlist was last modified.
  final int updatedAt;

  /// Total number of tracks in this playlist.
  final int songCount;

  /// Total cumulative duration of all songs in milliseconds.
  final int totalDuration;

  /// Representative MediaStore ID of the first song, used as cover fallback.
  final int? firstMediaStoreId;

  const Playlist({
    this.id,
    required this.name,
    this.coverPath,
    required this.createdAt,
    required this.updatedAt,
    this.songCount = 0,
    this.totalDuration = 0,
    this.firstMediaStoreId,
  });

  /// Instantiates a [Playlist] from an SQLite query row.
  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: (map['id'] as num?)?.toInt(),
      name: (map['name'] as String?) ?? 'Untitled Playlist',
      coverPath: map['cover_path'] as String?,
      createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
      updatedAt: (map['updated_at'] as num?)?.toInt() ?? 0,
      songCount: (map['song_count'] as num?)?.toInt() ?? 0,
      totalDuration: (map['total_duration'] as num?)?.toInt() ?? 0,
      firstMediaStoreId: (map['first_media_store_id'] as num?)?.toInt(),
    );
  }

  /// Converts this [Playlist] into SQLite column map for inserts/updates.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'cover_path': coverPath,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Playlist copyWith({
    int? id,
    String? name,
    String? coverPath,
    int? createdAt,
    int? updatedAt,
    int? songCount,
    int? totalDuration,
    int? firstMediaStoreId,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      coverPath: coverPath ?? this.coverPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      songCount: songCount ?? this.songCount,
      totalDuration: totalDuration ?? this.totalDuration,
      firstMediaStoreId: firstMediaStoreId ?? this.firstMediaStoreId,
    );
  }

  @override
  String toString() {
    return 'Playlist(id: $id, name: $name, songs: $songCount, duration: ${totalDuration}ms)';
  }
}

/// File: album_discovery_item.dart
/// Description: Immutable aggregated domain model representing an album in Discovery/Library.
/// Produced by a single relational SQL query (Anti-N+1 Rule 4.2) joining songs and playback_history.
///
/// Components / Classes / Functions:
/// - AlbumDiscoveryItem: Aggregated data class containing track count, duration, and artwork pointers.
library;

/// Aggregated album summary for Discovery and Library screens.
class AlbumDiscoveryItem {
  /// Album name.
  final String name;

  /// Performing artist name.
  final String artist;

  /// Android MediaStore album ID, if available.
  final int? albumId;

  /// MediaStore ID of a representative track used for Frame 0 artwork lookup.
  final int representativeSongId;

  /// Total number of tracks in this album.
  final int songCount;

  /// Combined total duration in milliseconds of all tracks in the album.
  final int totalDuration;

  /// Unix timestamp in seconds of when this album was last played, if any.
  final int? lastPlayed;

  const AlbumDiscoveryItem({
    required this.name,
    required this.artist,
    this.albumId,
    required this.representativeSongId,
    required this.songCount,
    required this.totalDuration,
    this.lastPlayed,
  });

  /// Instantiates an [AlbumDiscoveryItem] from the relational SQL projection row.
  factory AlbumDiscoveryItem.fromMap(Map<String, dynamic> map) {
    return AlbumDiscoveryItem(
      name: (map['name'] as String?) ?? '<Desconocido>',
      artist: (map['artist'] as String?) ?? '<Desconocido>',
      albumId: (map['album_id'] as num?)?.toInt(),
      representativeSongId: (map['representative_song_id'] as num?)?.toInt() ?? 0,
      songCount: (map['song_count'] as num?)?.toInt() ?? 0,
      totalDuration: (map['total_duration'] as num?)?.toInt() ?? 0,
      lastPlayed: (map['last_played'] as num?)?.toInt(),
    );
  }

  @override
  String toString() {
    return 'AlbumDiscoveryItem(name: $name, artist: $artist, songs: $songCount, duration: ${totalDuration}ms)';
  }
}

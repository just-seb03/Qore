/// File: artist_discovery_item.dart
/// Description: Immutable aggregated domain model representing an artist in Discovery/Home.
/// Produced by a single relational SQL query (Anti-N+1 Rule 4.2) joining songs and playback_history.
///
/// Components / Classes / Functions:
/// - ArtistDiscoveryItem: Aggregated data class containing track count, album count, and playback stats.
library;

/// Aggregated artist summary for Discovery and Library screens.
class ArtistDiscoveryItem {
  /// Artist name.
  final String name;

  /// Total number of tracks indexed by this artist.
  final int songCount;

  /// Number of distinct albums indexed by this artist.
  final int albumCount;

  /// MediaStore ID of a representative track used for Frame 0 artwork lookup.
  final int representativeSongId;

  /// Optional MediaStore Album ID of a representative track.
  final int? representativeAlbumId;

  /// Unix timestamp in seconds of when this artist was last played, if any.
  final int? lastPlayed;

  const ArtistDiscoveryItem({
    required this.name,
    required this.songCount,
    required this.albumCount,
    required this.representativeSongId,
    this.representativeAlbumId,
    this.lastPlayed,
  });

  /// Instantiates an [ArtistDiscoveryItem] from the relational SQL projection row.
  factory ArtistDiscoveryItem.fromMap(Map<String, dynamic> map) {
    return ArtistDiscoveryItem(
      name: (map['name'] as String?) ?? '<Desconocido>',
      songCount: (map['song_count'] as num?)?.toInt() ?? 0,
      albumCount: (map['album_count'] as num?)?.toInt() ?? 0,
      representativeSongId: (map['representative_song_id'] as num?)?.toInt() ?? 0,
      representativeAlbumId: (map['representative_album_id'] as num?)?.toInt(),
      lastPlayed: (map['last_played'] as num?)?.toInt(),
    );
  }

  @override
  String toString() {
    return 'ArtistDiscoveryItem(name: $name, songs: $songCount, albums: $albumCount, lastPlayed: $lastPlayed)';
  }
}

/// File: genre_discovery_item.dart
/// Description: Immutable aggregated domain model representing a music genre in Library.
///
/// Components / Classes / Functions:
/// - GenreDiscoveryItem: Aggregated data class containing genre name, song count,
///   representative song metadata, and associated songs.
library;

import 'package:project_anima/core/database/models/song.dart';

/// Aggregated genre summary for the Library Genres view.
class GenreDiscoveryItem {
  /// Display name of the genre.
  final String name;

  /// Total number of tracks tagged with this genre.
  final int songCount;

  /// MediaStore ID of a representative track used for artwork lookup.
  final int representativeSongId;

  /// Optional MediaStore Album ID of a representative track.
  final int? representativeAlbumId;

  /// Pre-loaded songs belonging to this genre, sorted alphabetically by title.
  final List<Song> songs;

  const GenreDiscoveryItem({
    required this.name,
    required this.songCount,
    required this.representativeSongId,
    this.representativeAlbumId,
    this.songs = const [],
  });

  @override
  String toString() {
    return 'GenreDiscoveryItem(name: $name, songCount: $songCount)';
  }
}

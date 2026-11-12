/// File: library_strings.dart
/// Description: Interface Segregation contract defining strings for the Library feature,
/// including category filter pills, section headers, and empty states.
///
/// Components / Classes / Functions:
/// - LibraryStrings: Abstract contract for Library feature localization.
library;

/// Contract defining localized strings for the Library feature.
abstract class LibraryStrings {
  /// Header title for the library screen (e.g. 'Library').
  String get headerTitle;

  /// Filter pill label for Albums view (e.g. 'Albums').
  String get filterAlbums;

  /// Filter pill label for Artists view (e.g. 'Artists').
  String get filterArtists;

  /// Filter pill label for Songs view (e.g. 'Songs').
  String get filterSongs;

  /// Filter pill label for Playlists view (e.g. 'Playlists').
  String get filterPlaylists;

  /// Empty state title when no songs are indexed.
  String get emptySongsTitle;

  /// Empty state subtitle when no songs are indexed.
  String get emptySongsSubtitle;

  /// Empty state title when no albums are indexed.
  String get emptyAlbumsTitle;

  /// Empty state subtitle when no albums are indexed.
  String get emptyAlbumsSubtitle;

  /// Empty state title when no artists are indexed.
  String get emptyArtistsTitle;

  /// Empty state subtitle when no artists are indexed.
  String get emptyArtistsSubtitle;

  /// Empty state title when no playlists exist yet.
  String get emptyPlaylistsTitle;

  /// Empty state subtitle when no playlists exist yet.
  String get emptyPlaylistsSubtitle;

  /// Subtitle label for artist list tiles (e.g. 'Artist').
  String get artistSubtitle;
}

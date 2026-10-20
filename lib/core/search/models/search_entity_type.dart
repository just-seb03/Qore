/// File: search_entity_type.dart
/// Description: Enumeration defining the categorical types of audio entities supported
/// by the Spotify-style multi-tiered search architecture.
///
/// Components / Classes / Functions:
/// - SearchEntityType: Enum denoting artist, album, or song category.
library;

/// Represents the classification type of a search result.
enum SearchEntityType {
  artist,
  album,
  song;

  /// Human-readable uppercase badge title (e.g. for Spotify-style top result chip).
  String get label {
    switch (this) {
      case SearchEntityType.artist:
        return 'ARTIST';
      case SearchEntityType.album:
        return 'ALBUM';
      case SearchEntityType.song:
        return 'SONG';
    }
  }
}

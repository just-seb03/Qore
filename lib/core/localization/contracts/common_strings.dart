/// File: common_strings.dart
/// Description: Interface Segregation contract defining common, shared application
/// strings such as global action tooltips, fallback labels, and generic placeholders.
///
/// Components / Classes / Functions:
/// - CommonStrings: Abstract contract for shared string resources.
library;

/// Contract defining shared strings across multiple features in Project Anima.
abstract class CommonStrings {
  /// Tooltip when adding a track/album to favorites.
  String get addToFavorites;

  /// Tooltip when removing a track/album from favorites.
  String get removeFromFavorites;

  /// Tooltip when adding a track/item to the playback queue.
  String get addToQueue;

  /// Fallback label when an artist name is unknown or missing.
  String get unknownArtist;

  /// Fallback label when an album title is unknown or missing.
  String get unknownAlbum;

  /// Fallback label when a song title is unknown or missing.
  String get unknownTitle;

  /// Fallback label when a genre is unknown or missing.
  String get unknownGenre;

  /// General confirmation label (e.g. 'Done', 'Listo').
  String get done;
}

/// File: album_strings.dart
/// Description: Interface Segregation contract defining strings specific to the
/// Album feature, including tracklist headers, multi-disc dividers, and metadata.
///
/// Components / Classes / Functions:
/// - AlbumStrings: Abstract contract for Album feature localization.
library;

/// Contract defining localized strings for the Album feature.
abstract class AlbumStrings {
  /// Header label displayed above the album tracklist (e.g. 'TRACKS').
  String get tracksHeader;

  /// Header label for a specific disc number in multi-disc albums (e.g. 'DISC 1').
  String discHeader(int discNumber);

  /// Pluralized song count label (e.g. '1 song', '12 songs').
  String songCount(int count);

  /// Total duration formatted with hours and minutes (e.g. '1 hr 14 min').
  String durationHoursMinutes(int hours, int minutes);

  /// Total duration formatted in minutes only (e.g. '42 mins').
  String durationMinutes(int minutes);

  /// Subtitle combining song count and duration formatted together (e.g. '12 songs • 42 mins').
  String metadataSubtitle({required String countStr, String? durationStr});

  /// Fallback label when the album artist is unknown.
  String get unknownArtist;
}

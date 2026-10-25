/// File: artist_tracks_strings.dart
/// Description: Interface Segregation contract defining strings for the Artist Tracks
/// list screen and header component.
///
/// Components / Classes / Functions:
/// - ArtistTracksStrings: Abstract contract for Artist Tracks localization.
library;

/// Contract defining localized strings for the Artist Tracks feature.
abstract class ArtistTracksStrings {
  /// Header category label for the full artist tracks view (e.g. 'TRACKS').
  String get headerTitle;

  /// Pluralized count of tracks in the list (e.g. '1 track', '48 tracks').
  String trackCount(int count);

  /// Total duration formatted with hours and minutes (e.g. '2 hr 15 min').
  String totalDuration(int hours, int minutes);

  /// Total duration formatted in minutes only (e.g. '45 mins').
  String totalDurationMinutes(int minutes);
}

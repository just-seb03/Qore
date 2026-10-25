/// File: artist_discography_strings.dart
/// Description: Interface Segregation contract defining strings for the Artist Discography
/// modal grid screen and components.
///
/// Components / Classes / Functions:
/// - ArtistDiscographyStrings: Abstract contract for Artist Discography localization.
library;

/// Contract defining localized strings for the Artist Discography feature.
abstract class ArtistDiscographyStrings {
  /// Header category label for the full discography view (e.g. 'DISCOGRAPHY').
  String get headerTitle;

  /// Pluralized count of albums in discography (e.g. '1 album', '5 albums').
  String albumCount(int count);

  /// Pluralized count of tracks inside an album card (e.g. '1 track', '12 tracks').
  String trackCount(int count);
}

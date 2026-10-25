/// File: artist_strings.dart
/// Description: Interface Segregation contract defining strings for the Artist feature,
/// including category headers ('FEATURED', 'DISCOGRAPHY', 'SONGS') and photo sheet actions.
///
/// Components / Classes / Functions:
/// - ArtistStrings: Abstract contract for Artist feature localization.
library;

/// Contract defining localized strings for the Artist feature.
abstract class ArtistStrings {
  /// Header label for the top featured songs section (e.g. 'FEATURED').
  String get featuredHeader;

  /// Header label for the discography section (e.g. 'DISCOGRAPHY').
  String get discographyHeader;

  /// Header label for the 'Appears On' section (e.g. 'APPEARS ON').
  String get appearsOnHeader;

  /// Header label for the assorted songs section (e.g. 'SONGS').
  String get songsHeader;

  /// Action sheet option to change the artist avatar image.
  String get changeArtistPhoto;

  /// Action sheet option to remove a custom artist avatar.
  String get removeCustomPhoto;

  /// Pluralized count of songs in an album (e.g. '1 song', '10 songs').
  String albumSongCount(int count);

  /// Pluralized count of tracks in an album (e.g. '1 track', '10 tracks').
  String albumTrackCount(int count);

  /// Pluralized general count of songs (e.g. '1 song', '25 songs').
  String songCount(int count);

  /// Tooltip to pin artist to favorite artists.
  String get pinArtistTooltip;

  /// Tooltip to unpin artist from favorite artists.
  String get unpinArtistTooltip;

  /// SnackBar message when artist photo is reset to default.
  String get photoResetSuccess;

  /// SnackBar message when artist photo is updated.
  String get photoUpdateSuccess;
}

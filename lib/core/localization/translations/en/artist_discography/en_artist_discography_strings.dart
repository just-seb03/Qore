/// File: en_artist_discography_strings.dart
/// Description: English implementation of the [ArtistDiscographyStrings] contract.
///
/// Components / Classes / Functions:
/// - EnArtistDiscographyStrings: Concrete English string resources for Artist Discography.
library;

import 'package:project_anima/core/localization/contracts/artist_discography_strings.dart';

/// English translations for the Artist Discography feature.
class EnArtistDiscographyStrings implements ArtistDiscographyStrings {
  const EnArtistDiscographyStrings();

  @override
  String get headerTitle => 'DISCOGRAPHY';

  @override
  String albumCount(int count) => '$count ${count == 1 ? "album" : "albums"}';

  @override
  String trackCount(int count) => '$count ${count == 1 ? "track" : "tracks"}';
}

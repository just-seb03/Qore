/// File: es_artist_discography_strings.dart
/// Description: Spanish implementation of the [ArtistDiscographyStrings] contract.
///
/// Components / Classes / Functions:
/// - EsArtistDiscographyStrings: Concrete Spanish string resources for Artist Discography.
library;

import 'package:project_anima/core/localization/contracts/artist_discography_strings.dart';

/// Spanish translations for the Artist Discography feature.
class EsArtistDiscographyStrings implements ArtistDiscographyStrings {
  const EsArtistDiscographyStrings();

  @override
  String get headerTitle => 'DISCOGRAFÍA';

  @override
  String albumCount(int count) => '$count ${count == 1 ? "álbum" : "álbumes"}';

  @override
  String trackCount(int count) => '$count ${count == 1 ? "pista" : "pistas"}';
}

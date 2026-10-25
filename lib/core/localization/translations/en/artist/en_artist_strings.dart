/// File: en_artist_strings.dart
/// Description: English implementation of the [ArtistStrings] contract.
///
/// Components / Classes / Functions:
/// - EnArtistStrings: Concrete English string resources for the Artist feature.
library;

import 'package:project_anima/core/localization/contracts/artist_strings.dart';

/// English translations for the Artist feature.
class EnArtistStrings implements ArtistStrings {
  const EnArtistStrings();

  @override
  String get featuredHeader => 'FEATURED';

  @override
  String get discographyHeader => 'DISCOGRAPHY';

  @override
  String get appearsOnHeader => 'APPEARS ON';

  @override
  String get songsHeader => 'SONGS';

  @override
  String get changeArtistPhoto => 'Change artist photo';

  @override
  String get removeCustomPhoto => 'Remove custom photo';

  @override
  String albumSongCount(int count) => '$count ${count == 1 ? "song" : "songs"}';

  @override
  String albumTrackCount(int count) =>
      '$count ${count == 1 ? "track" : "tracks"}';

  @override
  String songCount(int count) => '$count ${count == 1 ? "song" : "songs"}';

  @override
  String get pinArtistTooltip => 'Pin artist to favorites';

  @override
  String get unpinArtistTooltip => 'Unpin artist from favorites';

  @override
  String get photoResetSuccess => 'Artist photo reset to default';

  @override
  String get photoUpdateSuccess => 'Artist photo updated successfully';
}

/// File: en_artist_tracks_strings.dart
/// Description: English implementation of the [ArtistTracksStrings] contract.
///
/// Components / Classes / Functions:
/// - EnArtistTracksStrings: Concrete English string resources for Artist Tracks.
library;

import 'package:project_anima/core/localization/contracts/artist_tracks_strings.dart';

/// English translations for the Artist Tracks feature.
class EnArtistTracksStrings implements ArtistTracksStrings {
  const EnArtistTracksStrings();

  @override
  String get headerTitle => 'TRACKS';

  @override
  String trackCount(int count) => '$count ${count == 1 ? "track" : "tracks"}';

  @override
  String totalDuration(int hours, int minutes) => '$hours hr $minutes min';

  @override
  String totalDurationMinutes(int minutes) => '$minutes mins';
}

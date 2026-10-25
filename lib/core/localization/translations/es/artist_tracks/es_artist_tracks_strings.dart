/// File: es_artist_tracks_strings.dart
/// Description: Spanish implementation of the [ArtistTracksStrings] contract.
///
/// Components / Classes / Functions:
/// - EsArtistTracksStrings: Concrete Spanish string resources for Artist Tracks feature.
library;

import 'package:project_anima/core/localization/contracts/artist_tracks_strings.dart';

/// Spanish translations for the Artist Tracks feature.
class EsArtistTracksStrings implements ArtistTracksStrings {
  const EsArtistTracksStrings();

  @override
  String get headerTitle => 'PISTAS';

  @override
  String trackCount(int count) => '$count ${count == 1 ? "pista" : "pistas"}';

  @override
  String totalDuration(int hours, int minutes) => '$hours h $minutes min';

  @override
  String totalDurationMinutes(int minutes) => '$minutes mins';
}

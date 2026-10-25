/// File: en_album_strings.dart
/// Description: English implementation of the [AlbumStrings] contract.
///
/// Components / Classes / Functions:
/// - EnAlbumStrings: Concrete English string resources for the Album feature.
library;

import 'package:project_anima/core/localization/contracts/album_strings.dart';

/// English translations for the Album feature.
class EnAlbumStrings implements AlbumStrings {
  const EnAlbumStrings();

  @override
  String get tracksHeader => 'TRACKS';

  @override
  String discHeader(int discNumber) => 'DISC $discNumber';

  @override
  String songCount(int count) => '$count ${count == 1 ? "song" : "songs"}';

  @override
  String durationHoursMinutes(int hours, int minutes) =>
      '$hours hr $minutes min';

  @override
  String durationMinutes(int minutes) => '$minutes mins';

  @override
  String metadataSubtitle({required String countStr, String? durationStr}) {
    if (durationStr != null && durationStr.isNotEmpty) {
      return '$countStr • $durationStr';
    }
    return countStr;
  }

  @override
  String get unknownArtist => 'Unknown Artist';
}

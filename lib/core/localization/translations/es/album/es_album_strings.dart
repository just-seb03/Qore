/// File: es_album_strings.dart
/// Description: Spanish implementation of the [AlbumStrings] contract.
///
/// Components / Classes / Functions:
/// - EsAlbumStrings: Concrete Spanish string resources for Album detail feature.
library;

import 'package:project_anima/core/localization/contracts/album_strings.dart';

/// Spanish translations for the Album detail feature.
class EsAlbumStrings implements AlbumStrings {
  const EsAlbumStrings();

  @override
  String get tracksHeader => 'PISTAS';

  @override
  String discHeader(int discNumber) => 'DISCO $discNumber';

  @override
  String songCount(int count) => '$count ${count == 1 ? "canción" : "canciones"}';

  @override
  String durationHoursMinutes(int hours, int minutes) => '$hours h $minutes min';

  @override
  String durationMinutes(int minutes) => '$minutes mins';

  @override
  String metadataSubtitle({
    required String countStr,
    String? durationStr,
  }) {
    if (durationStr == null || durationStr.trim().isEmpty) {
      return countStr;
    }
    return '$countStr • $durationStr';
  }

  @override
  String get unknownArtist => 'Artista desconocido';
}

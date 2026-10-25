/// File: es_artist_strings.dart
/// Description: Spanish implementation of the [ArtistStrings] contract.
///
/// Components / Classes / Functions:
/// - EsArtistStrings: Concrete Spanish string resources for Artist feature.
library;

import 'package:project_anima/core/localization/contracts/artist_strings.dart';

/// Spanish translations for the Artist feature.
class EsArtistStrings implements ArtistStrings {
  const EsArtistStrings();

  @override
  String get featuredHeader => 'DESTACADOS';

  @override
  String get discographyHeader => 'DISCOGRAFÍA';

  @override
  String get appearsOnHeader => 'APARECE EN';

  @override
  String get songsHeader => 'CANCIONES';

  @override
  String get changeArtistPhoto => 'Cambiar foto de artista';

  @override
  String get removeCustomPhoto => 'Eliminar foto personalizada';

  @override
  String albumSongCount(int count) => '$count ${count == 1 ? "canción" : "canciones"}';

  @override
  String albumTrackCount(int count) => '$count ${count == 1 ? "pista" : "pistas"}';

  @override
  String songCount(int count) => '$count ${count == 1 ? "canción" : "canciones"}';

  @override
  String get pinArtistTooltip => 'Fijar artista en favoritos';

  @override
  String get unpinArtistTooltip => 'Desfijar artista de favoritos';

  @override
  String get photoResetSuccess => 'Foto de artista restaurada a la predeterminada';

  @override
  String get photoUpdateSuccess => 'Foto de artista actualizada correctamente';
}

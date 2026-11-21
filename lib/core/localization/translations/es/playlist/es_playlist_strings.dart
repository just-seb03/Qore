/// File: es_playlist_strings.dart
/// Description: Spanish implementation of the [PlaylistStrings] contract.
///
/// Components / Classes / Functions:
/// - EsPlaylistStrings: Concrete Spanish string resources for Playlist feature.
library;

import 'package:project_anima/core/localization/contracts/playlist_strings.dart';

/// Spanish translations for the Playlist feature.
class EsPlaylistStrings implements PlaylistStrings {
  const EsPlaylistStrings();

  @override
  String get headerCategory => 'LISTA';

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
  String get createPlaylistTitle => 'Crear lista';

  @override
  String get editPlaylistTitle => 'Editar lista';

  @override
  String get playlistNameHint => 'Nombre de la lista';

  @override
  String get saveAction => 'Guardar';

  @override
  String get changeCover => 'Cambiar banner (1920x620)';

  @override
  String get addCover => 'Elegir banner (1920x620)';

  @override
  String get typographySection => 'TIPOGRAFÍA';

  @override
  String get songsInPlaylistSection => 'CANCIONES EN LA LISTA';

  @override
  String get emptyPlaylistTitle => 'NO HAY PISTAS EN ESTA LISTA';

  @override
  String get emptyPlaylistSubtitle =>
      'Añade pistas a tu lista editándola.';

  @override
  String get addSongsButton => 'Añadir canciones';

  @override
  String get searchSongsPlaceholder => '¿Qué canción quieres añadir?';

  @override
  String get noSongsFound =>
      'No se encontraron canciones en tu biblioteca';

  @override
  String addedSongSuccess(String title) => 'Se añadió "$title" a la lista';

  @override
  String savePlaylistError(String error) => 'Error al guardar la lista: $error';

  @override
  String get galleryPickError => 'Error al seleccionar imagen de la galería';

  @override
  String get discardDialogTitle => '¿Descartar lista?';

  @override
  String get discardDialogMessage =>
      'Tienes cambios sin guardar. ¿Seguro que quieres salir sin guardar?';

  @override
  String get keepEditingAction => 'Seguir editando';

  @override
  String get discardAction => 'Descartar';

  @override
  String get playAction => 'Reproducir';

  @override
  String get shuffleAction => 'Aleatorio';

  @override
  String get tracksHeader => 'PISTAS';

  @override
  String tracksHeaderWithCount(int count) => 'PISTAS ($count)';

  @override
  String get dragToReorder => 'Arrastra para reordenar';

  @override
  String get noSongsAddedYet =>
      'Aún no has añadido canciones.\nBusca arriba para añadir canciones a tu lista.';

  @override
  String get removeTrackTooltip => 'Quitar pista';

  @override
  String get addSongsSection => 'AÑADIR CANCIONES';

  @override
  String get defaultPlaylistName => 'Mi lista';

  @override
  String get heroBannerPlaceholder => 'BANNER 1920x620';

  @override
  String get editPlaylistTooltip => 'Editar lista';

  @override
  String get enableShuffleTooltip => 'Activar aleatorio';

  @override
  String get disableShuffleTooltip => 'Desactivar aleatorio';

  @override
  String get playPlaylistTooltip => 'Reproducir lista';

  @override
  String get pausePlaylistTooltip => 'Pausar lista';

  @override
  String get alreadyAddedTooltip => 'Ya añadida';

  @override
  String get addToPlaylistTooltip => 'Añadir a la lista';

  @override
  String get addToListTitle => 'Añadir a lista';
}

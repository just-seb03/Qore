/// File: es_library_strings.dart
/// Description: Spanish implementation of the [LibraryStrings] contract.
///
/// Components / Classes / Functions:
/// - EsLibraryStrings: Concrete Spanish string resources for Library feature.
library;

import 'package:project_anima/core/localization/contracts/library_strings.dart';

/// Spanish translations for the Library feature.
class EsLibraryStrings implements LibraryStrings {
  const EsLibraryStrings();

  @override
  String get headerTitle => 'Biblioteca';

  @override
  String get filterAlbums => 'Álbumes';

  @override
  String get filterArtists => 'Artistas';

  @override
  String get filterSongs => 'Canciones';

  @override
  String get filterPlaylists => 'Listas';

  @override
  String get emptySongsTitle => 'NO SE ENCONTRARON CANCIONES';

  @override
  String get emptySongsSubtitle =>
      'Añade música a tu dispositivo para ver tus canciones aquí';

  @override
  String get artistSubtitle => 'Artista';

  @override
  String get emptyAlbumsTitle => 'NO SE ENCONTRARON ÁLBUMES';

  @override
  String get emptyAlbumsSubtitle =>
      'Añade música a tu dispositivo para ver tus álbumes aquí';

  @override
  String get emptyArtistsTitle => 'NO SE ENCONTRARON ARTISTAS';

  @override
  String get emptyArtistsSubtitle =>
      'Añade música a tu dispositivo para ver tus artistas aquí';

  @override
  String get emptyPlaylistsTitle => 'AÚN NO HAY LISTAS';

  @override
  String get emptyPlaylistsSubtitle => 'Las listas personalizadas aparecerán aquí';
}

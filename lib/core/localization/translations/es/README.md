# Directorio de Localización en Español (`es`)

Este directorio contiene las implementaciones activas en idioma español para cada módulo/feature de Project Anima, implementando los contratos definidos en `lib/core/localization/contracts/`:

- `album/es_album_strings.dart` (implementa `AlbumStrings`)
- `artist/es_artist_strings.dart` (implementa `ArtistStrings`)
- `artist_discography/es_artist_discography_strings.dart` (implementa `ArtistDiscographyStrings`)
- `artist_tracks/es_artist_tracks_strings.dart` (implementa `ArtistTracksStrings`)
- `home/es_home_strings.dart` (implementa `HomeStrings`)
- `library/es_library_strings.dart` (implementa `LibraryStrings`)
- `navigation/es_navigation_strings.dart` (implementa `NavigationStrings`)
- `player/es_player_strings.dart` (implementa `PlayerStrings`)
- `playlist/es_playlist_strings.dart` (implementa `PlaylistStrings`)
- `search/es_search_strings.dart` (implementa `SearchStrings`)
- `startup/es_startup_strings.dart` (implementa `StartupStrings`)
- `common/es_common_strings.dart` (implementa `CommonStrings`)
- `es_strings.dart` (implementa `AppStrings`)

De esta forma se mantiene el principio de Open-Closed: el sistema está abierto a la extensión (nuevos idiomas) y cerrado a la modificación de las interfaces existentes. La selección de idioma se gestiona de forma reactiva y automática a través de `LocalizationController`.

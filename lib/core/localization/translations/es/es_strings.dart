/// File: es_strings.dart
/// Description: Root Spanish translations class implementing the [AppStrings] contract.
/// Composes concrete Spanish resources across all domains with const immutability.
///
/// Components / Classes / Functions:
/// - EsStrings: Root Spanish translation aggregator.
library;

import 'package:project_anima/core/localization/contracts/app_strings.dart';
import 'package:project_anima/core/localization/translations/es/album/es_album_strings.dart';
import 'package:project_anima/core/localization/translations/es/artist/es_artist_strings.dart';
import 'package:project_anima/core/localization/translations/es/artist_discography/es_artist_discography_strings.dart';
import 'package:project_anima/core/localization/translations/es/artist_tracks/es_artist_tracks_strings.dart';
import 'package:project_anima/core/localization/translations/es/common/es_common_strings.dart';
import 'package:project_anima/core/localization/translations/es/home/es_home_strings.dart';
import 'package:project_anima/core/localization/translations/es/library/es_library_strings.dart';
import 'package:project_anima/core/localization/translations/es/navigation/es_navigation_strings.dart';
import 'package:project_anima/core/localization/translations/es/player/es_player_strings.dart';
import 'package:project_anima/core/localization/translations/es/playlist/es_playlist_strings.dart';
import 'package:project_anima/core/localization/translations/es/search/es_search_strings.dart';
import 'package:project_anima/core/localization/translations/es/startup/es_startup_strings.dart';

/// Spanish translation suite for Project Anima.
class EsStrings implements AppStrings {
  const EsStrings();

  @override
  final CommonStrings common = const EsCommonStrings();

  @override
  final AlbumStrings album = const EsAlbumStrings();

  @override
  final ArtistStrings artist = const EsArtistStrings();

  @override
  final ArtistDiscographyStrings artistDiscography =
      const EsArtistDiscographyStrings();

  @override
  final ArtistTracksStrings artistTracks = const EsArtistTracksStrings();

  @override
  final HomeStrings home = const EsHomeStrings();

  @override
  final LibraryStrings library = const EsLibraryStrings();

  @override
  final NavigationStrings navigation = const EsNavigationStrings();

  @override
  final PlayerStrings player = const EsPlayerStrings();

  @override
  final PlaylistStrings playlist = const EsPlaylistStrings();

  @override
  final SearchStrings search = const EsSearchStrings();

  @override
  final StartupStrings startup = const EsStartupStrings();
}

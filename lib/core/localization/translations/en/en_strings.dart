/// File: en_strings.dart
/// Description: Root English translations class implementing the [AppStrings] contract.
/// Composes concrete English resources across all domains with const immutability.
///
/// Components / Classes / Functions:
/// - EnStrings: Root English translation aggregator.
library;

import 'package:project_anima/core/localization/contracts/app_strings.dart';
import 'package:project_anima/core/localization/translations/en/album/en_album_strings.dart';
import 'package:project_anima/core/localization/translations/en/artist/en_artist_strings.dart';
import 'package:project_anima/core/localization/translations/en/artist_discography/en_artist_discography_strings.dart';
import 'package:project_anima/core/localization/translations/en/artist_tracks/en_artist_tracks_strings.dart';
import 'package:project_anima/core/localization/translations/en/common/en_common_strings.dart';
import 'package:project_anima/core/localization/translations/en/home/en_home_strings.dart';
import 'package:project_anima/core/localization/translations/en/library/en_library_strings.dart';
import 'package:project_anima/core/localization/translations/en/navigation/en_navigation_strings.dart';
import 'package:project_anima/core/localization/translations/en/player/en_player_strings.dart';
import 'package:project_anima/core/localization/translations/en/playlist/en_playlist_strings.dart';
import 'package:project_anima/core/localization/translations/en/search/en_search_strings.dart';
import 'package:project_anima/core/localization/translations/en/settings/en_settings_strings.dart';
import 'package:project_anima/core/localization/translations/en/startup/en_startup_strings.dart';

/// English translation suite for Project Anima.
class EnStrings implements AppStrings {
  const EnStrings();

  @override
  final CommonStrings common = const EnCommonStrings();

  @override
  final AlbumStrings album = const EnAlbumStrings();

  @override
  final ArtistStrings artist = const EnArtistStrings();

  @override
  final ArtistDiscographyStrings artistDiscography =
      const EnArtistDiscographyStrings();

  @override
  final ArtistTracksStrings artistTracks = const EnArtistTracksStrings();

  @override
  final HomeStrings home = const EnHomeStrings();

  @override
  final LibraryStrings library = const EnLibraryStrings();

  @override
  final NavigationStrings navigation = const EnNavigationStrings();

  @override
  final PlayerStrings player = const EnPlayerStrings();

  @override
  final PlaylistStrings playlist = const EnPlaylistStrings();

  @override
  final SearchStrings search = const EnSearchStrings();

  @override
  final SettingsStrings settings = const EnSettingsStrings();

  @override
  final StartupStrings startup = const EnStartupStrings();
}

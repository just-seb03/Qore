/// File: app_strings.dart
/// Description: Root aggregator contract composing feature-specific localization
/// contracts. Enables high cohesion within features and low coupling across them.
///
/// Components / Classes / Functions:
/// - AppStrings: Root interface exposing sub-domain string contracts.
library;

import 'package:project_anima/core/localization/contracts/album_strings.dart';
import 'package:project_anima/core/localization/contracts/artist_discography_strings.dart';
import 'package:project_anima/core/localization/contracts/artist_strings.dart';
import 'package:project_anima/core/localization/contracts/artist_tracks_strings.dart';
import 'package:project_anima/core/localization/contracts/common_strings.dart';
import 'package:project_anima/core/localization/contracts/home_strings.dart';
import 'package:project_anima/core/localization/contracts/library_strings.dart';
import 'package:project_anima/core/localization/contracts/navigation_strings.dart';
import 'package:project_anima/core/localization/contracts/player_strings.dart';
import 'package:project_anima/core/localization/contracts/playlist_strings.dart';
import 'package:project_anima/core/localization/contracts/search_strings.dart';
import 'package:project_anima/core/localization/contracts/startup_strings.dart';

export 'package:project_anima/core/localization/contracts/album_strings.dart';
export 'package:project_anima/core/localization/contracts/artist_discography_strings.dart';
export 'package:project_anima/core/localization/contracts/artist_strings.dart';
export 'package:project_anima/core/localization/contracts/artist_tracks_strings.dart';
export 'package:project_anima/core/localization/contracts/common_strings.dart';
export 'package:project_anima/core/localization/contracts/home_strings.dart';
export 'package:project_anima/core/localization/contracts/library_strings.dart';
export 'package:project_anima/core/localization/contracts/navigation_strings.dart';
export 'package:project_anima/core/localization/contracts/player_strings.dart';
export 'package:project_anima/core/localization/contracts/playlist_strings.dart';
export 'package:project_anima/core/localization/contracts/search_strings.dart';
export 'package:project_anima/core/localization/contracts/startup_strings.dart';

/// Aggregator contract providing structured, domain-isolated localized strings.
abstract class AppStrings {
  /// Common shared strings (action tooltips, generic fallback labels).
  CommonStrings get common;

  /// Strings belonging to the Album detail feature.
  AlbumStrings get album;

  /// Strings belonging to the Artist overview feature.
  ArtistStrings get artist;

  /// Strings belonging to the Artist Discography feature.
  ArtistDiscographyStrings get artistDiscography;

  /// Strings belonging to the Artist Tracks feature.
  ArtistTracksStrings get artistTracks;

  /// Strings belonging to the Home feature.
  HomeStrings get home;

  /// Strings belonging to the Library feature.
  LibraryStrings get library;

  /// Strings belonging to root navigation components.
  NavigationStrings get navigation;

  /// Strings belonging to the Player & Queue feature.
  PlayerStrings get player;

  /// Strings belonging to the Playlist feature.
  PlaylistStrings get playlist;

  /// Strings belonging to the Search feature.
  SearchStrings get search;

  /// Strings belonging to the Startup initialization feature.
  StartupStrings get startup;
}

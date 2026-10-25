/// File: en_library_strings.dart
/// Description: English implementation of the [LibraryStrings] contract.
///
/// Components / Classes / Functions:
/// - EnLibraryStrings: Concrete English string resources for the Library feature.
library;

import 'package:project_anima/core/localization/contracts/library_strings.dart';

/// English translations for the Library feature.
class EnLibraryStrings implements LibraryStrings {
  const EnLibraryStrings();

  @override
  String get headerTitle => 'Library';

  @override
  String get filterAlbums => 'Albums';

  @override
  String get filterArtists => 'Artists';

  @override
  String get filterPlaylists => 'Playlists';

  @override
  String get emptyAlbumsTitle => 'NO ALBUMS FOUND';

  @override
  String get emptyAlbumsSubtitle =>
      'Add music to your device to see your albums here';

  @override
  String get emptyArtistsTitle => 'NO ARTISTS FOUND';

  @override
  String get emptyArtistsSubtitle =>
      'Add music to your device to see your artists here';

  @override
  String get emptyPlaylistsTitle => 'NO PLAYLISTS YET';

  @override
  String get emptyPlaylistsSubtitle => 'Custom playlists will appear here';

  @override
  String get artistSubtitle => 'Artist';
}

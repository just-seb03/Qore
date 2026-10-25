/// File: en_playlist_strings.dart
/// Description: English implementation of the [PlaylistStrings] contract.
///
/// Components / Classes / Functions:
/// - EnPlaylistStrings: Concrete English string resources for the Playlist feature.
library;

import 'package:project_anima/core/localization/contracts/playlist_strings.dart';

/// English translations for the Playlist feature.
class EnPlaylistStrings implements PlaylistStrings {
  const EnPlaylistStrings();

  @override
  String get headerCategory => 'PLAYLIST';

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
  String get createPlaylistTitle => 'Create Playlist';

  @override
  String get editPlaylistTitle => 'Edit Playlist';

  @override
  String get playlistNameHint => 'Playlist Name';

  @override
  String get saveAction => 'Save';

  @override
  String get changeCover => 'Change hero banner (1920x620)';

  @override
  String get addCover => 'Choose hero banner (1920x620)';

  @override
  String get typographySection => 'TYPOGRAPHY';

  @override
  String get songsInPlaylistSection => 'SONGS IN PLAYLIST';

  @override
  String get emptyPlaylistTitle => 'NO TRACKS IN THIS PLAYLIST';

  @override
  String get emptyPlaylistSubtitle =>
      'Add tracks to your playlist by editing it.';

  @override
  String get addSongsButton => 'Add Songs';

  @override
  String get searchSongsPlaceholder => 'What song do you want to add?';

  @override
  String get noSongsFound => 'No matching songs found in your library';

  @override
  String addedSongSuccess(String title) => 'Added "$title" to playlist';

  @override
  String savePlaylistError(String error) => 'Failed to save playlist: $error';

  @override
  String get galleryPickError => 'Failed to pick image from gallery';

  @override
  String get discardDialogTitle => 'Discard playlist?';

  @override
  String get discardDialogMessage =>
      'You have unsaved changes. Are you sure you want to leave without saving?';

  @override
  String get keepEditingAction => 'Keep editing';

  @override
  String get discardAction => 'Discard';

  @override
  String get playAction => 'Play';

  @override
  String get shuffleAction => 'Shuffle';

  @override
  String get tracksHeader => 'TRACKS';

  @override
  String tracksHeaderWithCount(int count) => 'TRACKS ($count)';

  @override
  String get dragToReorder => 'Drag to reorder';

  @override
  String get noSongsAddedYet =>
      'No songs added yet.\nSearch above to add songs to your playlist.';

  @override
  String get removeTrackTooltip => 'Remove track';

  @override
  String get addSongsSection => 'ADD SONGS';

  @override
  String get defaultPlaylistName => 'My Playlist';

  @override
  String get editPlaylistTooltip => 'Edit playlist';

  @override
  String get enableShuffleTooltip => 'Enable shuffle';

  @override
  String get disableShuffleTooltip => 'Disable shuffle';

  @override
  String get playPlaylistTooltip => 'Play playlist';

  @override
  String get pausePlaylistTooltip => 'Pause playlist';

  @override
  String get alreadyAddedTooltip => 'Already added';

  @override
  String get addToPlaylistTooltip => 'Add to playlist';

  @override
  String get heroBannerPlaceholder => 'HERO BANNER 1920x620';
}

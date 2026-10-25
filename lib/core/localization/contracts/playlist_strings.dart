/// File: playlist_strings.dart
/// Description: Interface Segregation contract defining strings for the Playlist feature,
/// including creation, editing, cover art customization, reordering, and detail views.
///
/// Components / Classes / Functions:
/// - PlaylistStrings: Abstract contract for Playlist feature localization.
library;

/// Contract defining localized strings for the Playlist feature.
abstract class PlaylistStrings {
  /// Category label in playlist detail header (e.g. 'PLAYLIST').
  String get headerCategory;

  /// Pluralized count of songs in a playlist (e.g. '1 song', '18 songs').
  String songCount(int count);

  /// Duration formatted with hours and minutes (e.g. '1 hr 12 min').
  String durationHoursMinutes(int hours, int minutes);

  /// Duration formatted in minutes only (e.g. '38 mins').
  String durationMinutes(int minutes);

  /// Subtitle combining count and total duration (e.g. '18 songs • 38 mins').
  String metadataSubtitle({required String countStr, String? durationStr});

  /// Screen title when creating a new playlist (e.g. 'Create Playlist').
  String get createPlaylistTitle;

  /// Screen title when editing an existing playlist (e.g. 'Edit Playlist').
  String get editPlaylistTitle;

  /// Input hint for the playlist title TextField (e.g. 'Playlist Name').
  String get playlistNameHint;

  /// Save action button label (e.g. 'Save').
  String get saveAction;

  /// Option to change an existing playlist cover (e.g. 'Change Cover').
  String get changeCover;

  /// Option to upload/select a cover image (e.g. 'Add Cover').
  String get addCover;

  /// Section label for typography selection (e.g. 'TYPOGRAPHY').
  String get typographySection;

  /// Section label for songs list in editor (e.g. 'SONGS IN PLAYLIST').
  String get songsInPlaylistSection;

  /// Empty state title when a playlist contains no songs.
  String get emptyPlaylistTitle;

  /// Empty state subtitle when a playlist contains no songs.
  String get emptyPlaylistSubtitle;

  /// Action button to open search and add songs (e.g. 'Add Songs').
  String get addSongsButton;

  /// Search bar input placeholder (e.g. 'Search songs to add...').
  String get searchSongsPlaceholder;

  /// Search results message when no tracks match query (e.g. 'No matching songs found').
  String get noSongsFound;

  /// SnackBar message when a song is successfully added to playlist.
  String addedSongSuccess(String title);

  /// SnackBar error message when saving a playlist fails.
  String savePlaylistError(String error);

  /// SnackBar error message when picking an image from the gallery fails.
  String get galleryPickError;

  /// Discard confirmation dialog title (e.g. 'DISCARD CHANGES?').
  String get discardDialogTitle;

  /// Discard confirmation dialog body message.
  String get discardDialogMessage;

  /// Dialog button to continue editing (e.g. 'Keep editing').
  String get keepEditingAction;

  /// Dialog button to discard unsaved changes (e.g. 'Discard').
  String get discardAction;

  /// Button label to play playlist tracks (e.g. 'Play').
  String get playAction;

  /// Button label to shuffle playlist tracks (e.g. 'Shuffle').
  String get shuffleAction;

  /// Section label for tracks (e.g. 'TRACKS').
  String get tracksHeader;

  /// Section label for tracks with count (e.g. 'TRACKS (4)').
  String tracksHeaderWithCount(int count);

  /// Helper label indicating drag to reorder behavior (e.g. 'Drag to reorder').
  String get dragToReorder;

  /// Message when no songs have been added yet in playlist editor.
  String get noSongsAddedYet;

  /// Tooltip to remove a song from playlist editor.
  String get removeTrackTooltip;

  /// Section title for adding songs in playlist editor (e.g. 'ADD SONGS').
  String get addSongsSection;

  /// Default fallback name for an untitled new playlist (e.g. 'My Playlist').
  String get defaultPlaylistName;

  /// Tooltip for editing a playlist.
  String get editPlaylistTooltip;

  /// Tooltip for enabling shuffle.
  String get enableShuffleTooltip;

  /// Tooltip for disabling shuffle.
  String get disableShuffleTooltip;

  /// Tooltip for playing playlist.
  String get playPlaylistTooltip;

  /// Tooltip for pausing playlist.
  String get pausePlaylistTooltip;

  /// Tooltip indicating song is already in the playlist.
  String get alreadyAddedTooltip;

  /// Tooltip for adding a song to the playlist.
  String get addToPlaylistTooltip;

  /// Placeholder label for hero banner artwork (e.g. 'HERO BANNER 1920x620').
  String get heroBannerPlaceholder;
}

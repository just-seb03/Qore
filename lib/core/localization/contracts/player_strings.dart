/// File: player_strings.dart
/// Description: Interface Segregation contract defining strings for the Player feature,
/// including playback controls, queue management, and metadata fallbacks.
///
/// Components / Classes / Functions:
/// - PlayerStrings: Abstract contract for Player feature localization.
library;

/// Contract defining localized strings for the Player feature.
abstract class PlayerStrings {
  /// Header label in queue sheet for currently active track (e.g. 'NOW PLAYING').
  String get nowPlayingHeader;

  /// Fallback title when no track is currently playing (e.g. 'No playback').
  String get noPlayback;

  /// Title for the playback queue sheet (e.g. 'PLAYING QUEUE').
  String get queueTitle;

  /// Section header for upcoming tracks with plural count (e.g. 'UP NEXT • 4 TRACKS').
  String upNextHeader(int count);

  /// Empty state message when the queue has no upcoming songs (e.g. 'Queue is empty').
  String get emptyQueue;

  /// Action button label to clear the queue (e.g. 'Clear').
  String get clearQueue;

  /// Tooltip for the shuffle toggle button.
  String get shuffleTooltip;

  /// Tooltip for the previous track button.
  String get previousTooltip;

  /// Tooltip for the next track button.
  String get nextTooltip;

  /// Tooltip for the play button.
  String get playTooltip;

  /// Tooltip for the pause button.
  String get pauseTooltip;

  /// Tooltip for the repeat / loop toggle button.
  String get loopTooltip;

  /// Tooltip for the queue button.
  String get queueTooltip;
}

/// File: en_player_strings.dart
/// Description: English implementation of the [PlayerStrings] contract.
///
/// Components / Classes / Functions:
/// - EnPlayerStrings: Concrete English string resources for the Player feature.
library;

import 'package:project_anima/core/localization/contracts/player_strings.dart';

/// English translations for the Player feature.
class EnPlayerStrings implements PlayerStrings {
  const EnPlayerStrings();

  @override
  String get nowPlayingHeader => 'NOW PLAYING';

  @override
  String get noPlayback => 'No playback';

  @override
  String get queueTitle => 'PLAYING QUEUE';

  @override
  String upNextHeader(int count) =>
      'UP NEXT • $count ${count == 1 ? "TRACK" : "TRACKS"}';

  @override
  String get emptyQueue => 'Queue is empty';

  @override
  String get clearQueue => 'Clear';

  @override
  String get shuffleTooltip => 'Shuffle mode';

  @override
  String get previousTooltip => 'Previous track';

  @override
  String get nextTooltip => 'Next track';

  @override
  String get playTooltip => 'Play';

  @override
  String get pauseTooltip => 'Pause';

  @override
  String get loopTooltip => 'Repeat mode';

  @override
  String get queueTooltip => 'Playback queue';
}

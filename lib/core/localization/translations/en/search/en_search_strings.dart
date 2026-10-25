/// File: en_search_strings.dart
/// Description: English implementation of the [SearchStrings] contract.
///
/// Components / Classes / Functions:
/// - EnSearchStrings: Concrete English string resources for the Search feature.
library;

import 'package:project_anima/core/localization/contracts/search_strings.dart';

/// English translations for the Search feature.
class EnSearchStrings implements SearchStrings {
  const EnSearchStrings();

  @override
  String get headerTitle => 'Search';

  @override
  String get searchPlaceholder => 'What do you want to listen to?';

  @override
  String get emptyLibraryTitle => 'SEARCH YOUR LIBRARY';

  @override
  String get emptyLibrarySubtitle => 'Indexed titles, artists, or albums';

  @override
  String get noResultsTitle => 'NO RESULTS FOUND';

  @override
  String noResultsSubtitle(String query) => 'No matches found for "$query"';

  @override
  String get recentSearchesHeader => 'RECENT SEARCHES';

  @override
  String get clearAllRecentAction => 'Clear all';

  @override
  String get removeRecentTooltip => 'Remove from recents';

  @override
  String get topResultHeader => 'TOP RESULT';

  @override
  String get albumsSectionHeader => 'ALBUMS';

  @override
  String get artistsSectionHeader => 'ARTISTS';

  @override
  String get songsSectionHeader => 'SONGS';

  @override
  String get artistSubtitle => 'Artist';

  @override
  String songCount(int count) => '$count ${count == 1 ? "song" : "songs"}';

  @override
  String get clearSearchTooltip => 'Clear search';
}

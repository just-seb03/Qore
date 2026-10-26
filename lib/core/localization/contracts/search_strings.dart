/// File: search_strings.dart
/// Description: Interface Segregation contract defining strings for the Search feature,
/// including headers, search bar hints, empty views, recent searches, and result sections.
///
/// Components / Classes / Functions:
/// - SearchStrings: Abstract contract for Search feature localization.
library;

/// Contract defining localized strings for the Search feature.
abstract class SearchStrings {
  /// Top header title for the Search screen (e.g. 'Search').
  String get headerTitle;

  /// Placeholder hint inside search input bar (e.g. 'What do you want to listen to?').
  String get searchPlaceholder;

  /// Header for initial empty library search prompt (e.g. 'SEARCH YOUR LIBRARY').
  String get emptyLibraryTitle;

  /// Subtitle for initial empty library search prompt (e.g. 'Indexed titles, artists, or albums').
  String get emptyLibrarySubtitle;

  /// Header displayed when a search yields zero matches (e.g. 'NO RESULTS FOUND').
  String get noResultsTitle;

  /// Subtitle displayed when a search yields zero matches (e.g. 'No matches found for "query"').
  String noResultsSubtitle(String query);

  /// Header for recent searches list (e.g. 'RECENT SEARCHES').
  String get recentSearchesHeader;

  /// Action button label to clear all recent searches (e.g. 'Clear all').
  String get clearAllRecentAction;

  /// Tooltip to remove an item from recent searches.
  String get removeRecentTooltip;

  /// Section header for the dominant top result card (e.g. 'TOP RESULT').
  String get topResultHeader;

  /// Section header for secondary albums carousel (e.g. 'ALBUMS').
  String get albumsSectionHeader;

  /// Section header for secondary artists carousel (e.g. 'ARTISTS').
  String get artistsSectionHeader;

  /// Section header for matching songs list (e.g. 'SONGS').
  String get songsSectionHeader;

  /// Subtitle badge for artist cards (e.g. 'Artist').
  String get artistSubtitle;

  /// Pluralized count of songs in an album result (e.g. '1 song', '12 songs').
  String songCount(int count);

  /// Tooltip for the clear search button.
  String get clearSearchTooltip;

  /// Section header for the newest albums carousel in search discovery (e.g. 'NEW ALBUMS').
  String get newAlbumsSectionHeader;

  /// Section header for the newest artists carousel in search discovery (e.g. 'NEW ARTISTS').
  String get newArtistsSectionHeader;

  /// Title for the Today's Selection system playlist card.
  String get todaySelectionTitle;

  /// Title for the Recently Played system playlist card.
  String get recentlyPlayedTitle;

  /// Section header for the featured/highlighted playlists section (e.g. 'DESTACADAS').
  String get featuredSectionHeader;
}

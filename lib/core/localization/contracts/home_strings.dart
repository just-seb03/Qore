/// File: home_strings.dart
/// Description: Interface Segregation contract defining strings for the Home feature,
/// including welcome banner, hero card titles, and slot grid edit actions.
///
/// Components / Classes / Functions:
/// - HomeStrings: Abstract contract for Home feature localization.
library;

/// Contract defining localized strings for the Home feature.
abstract class HomeStrings {
  /// Header title for the space screen (e.g. 'Space').
  String get spaceTitle;

  /// Header title for the home screen (e.g. 'WELCOME').
  String get welcomeTitle;

  /// Title for the user favorites hero card (e.g. 'Favorites').
  String get favoritesHeroTitle;

  /// Title for the curated daily selection hero card (e.g. 'Today Selection').
  String get todaySelectionHeroTitle;

  /// Default subtitle for pinned artist cards (e.g. 'Artist').
  String get artistSubtitle;

  /// Tooltip for the checkmark button exiting arranging mode (e.g. 'Done').
  String get doneButtonTooltip;

  /// Space intro step 1 welcome message.
  String get spaceIntroWelcome;

  /// Space intro step 2 favorites explanation.
  String get spaceIntroFavorites;

  /// Space intro step 3 direct access explanation.
  String get spaceIntroDirectAccess;
}

/// File: navigation_strings.dart
/// Description: Interface Segregation contract defining strings for root application navigation,
/// including primary bottom navigation tabs, tooltips, and destination labels.
///
/// Components / Classes / Functions:
/// - NavigationStrings: Abstract contract for root navigation localization.
library;

/// Contract defining localized strings for application navigation components.
abstract class NavigationStrings {
  /// Label for the Explore bottom navigation tab (e.g. 'Explore').
  String get exploreTab;

  /// Tooltip for the Explore bottom navigation tab (e.g. 'Explore').
  String get exploreTabTooltip;

  /// Label for the Search bottom navigation tab (e.g. 'Search').
  String get searchTab;

  /// Tooltip for the Search bottom navigation tab (e.g. 'Search').
  String get searchTabTooltip;

  /// Label for the Home / Space bottom navigation tab (e.g. 'Space').
  String get homeTab;

  /// Tooltip for the Home / Space bottom navigation tab (e.g. 'Space').
  String get homeTabTooltip;

  /// Label for the Library bottom navigation tab (e.g. 'Library').
  String get libraryTab;

  /// Tooltip for the Library bottom navigation tab (e.g. 'Library').
  String get libraryTabTooltip;

  /// Label for the Profile bottom navigation tab (e.g. 'Profile').
  String get profileTab;

  /// Tooltip for the Profile bottom navigation tab (e.g. 'Profile').
  String get profileTabTooltip;
}

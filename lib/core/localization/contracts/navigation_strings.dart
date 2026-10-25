/// File: navigation_strings.dart
/// Description: Interface Segregation contract defining strings for root application navigation,
/// including primary bottom navigation tabs, tooltips, and destination labels.
///
/// Components / Classes / Functions:
/// - NavigationStrings: Abstract contract for root navigation localization.
library;

/// Contract defining localized strings for application navigation components.
abstract class NavigationStrings {
  /// Label for the Home bottom navigation tab (e.g. 'Home').
  String get homeTab;

  /// Tooltip for the Home bottom navigation tab (e.g. 'Home').
  String get homeTabTooltip;

  /// Label for the Search bottom navigation tab (e.g. 'Search').
  String get searchTab;

  /// Tooltip for the Search bottom navigation tab (e.g. 'Search').
  String get searchTabTooltip;

  /// Label for the Library bottom navigation tab (e.g. 'Library').
  String get libraryTab;

  /// Tooltip for the Library bottom navigation tab (e.g. 'Library').
  String get libraryTabTooltip;
}

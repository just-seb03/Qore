/// File: en_navigation_strings.dart
/// Description: English implementation of the [NavigationStrings] contract.
///
/// Components / Classes / Functions:
/// - EnNavigationStrings: Concrete English string resources for navigation components.
library;

import 'package:project_anima/core/localization/contracts/navigation_strings.dart';

/// English translations for root navigation components.
class EnNavigationStrings implements NavigationStrings {
  const EnNavigationStrings();

  @override
  String get homeTab => 'Space';

  @override
  String get homeTabTooltip => 'Space';

  @override
  String get searchTab => 'Search';

  @override
  String get searchTabTooltip => 'Search';

  @override
  String get libraryTab => 'Library';

  @override
  String get libraryTabTooltip => 'Library';
}

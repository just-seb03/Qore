/// File: en_home_strings.dart
/// Description: English implementation of the [HomeStrings] contract.
///
/// Components / Classes / Functions:
/// - EnHomeStrings: Concrete English string resources for the Home feature.
library;

import 'package:project_anima/core/localization/contracts/home_strings.dart';

/// English translations for the Home feature.
class EnHomeStrings implements HomeStrings {
  const EnHomeStrings();

  @override
  String get spaceTitle => 'Space';

  @override
  String get welcomeTitle => 'WELCOME';

  @override
  String get favoritesHeroTitle => 'Favorites';

  @override
  String get todaySelectionHeroTitle => 'Today Selection';

  @override
  String get artistSubtitle => 'Artist';

  @override
  String get doneButtonTooltip => 'Done';
}

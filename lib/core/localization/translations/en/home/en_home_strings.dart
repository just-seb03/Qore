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

  @override
  String get spaceIntroWelcome =>
      'Welcome to Space, the place for your favorite content';

  @override
  String get spaceIntroFavorites =>
      'Here, all content you have saved with a ❤️ will appear pinned';

  @override
  String get spaceIntroDirectAccess =>
      'This way you will have direct access to the music you love the most';
}

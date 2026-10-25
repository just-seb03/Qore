/// File: en_common_strings.dart
/// Description: English implementation of the [CommonStrings] contract.
///
/// Components / Classes / Functions:
/// - EnCommonStrings: Concrete English string resources for shared UI elements.
library;

import 'package:project_anima/core/localization/contracts/common_strings.dart';

/// English translations for shared common strings.
class EnCommonStrings implements CommonStrings {
  const EnCommonStrings();

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get addToQueue => 'Add to queue';

  @override
  String get unknownArtist => 'Unknown Artist';

  @override
  String get unknownAlbum => 'Unknown Album';

  @override
  String get unknownTitle => 'Unknown Title';

  @override
  String get unknownGenre => 'Unknown Genre';

  @override
  String get done => 'Done';
}

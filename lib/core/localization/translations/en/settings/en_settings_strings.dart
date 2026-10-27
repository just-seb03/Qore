/// File: en_settings_strings.dart
/// Description: English concrete implementation of the [SettingsStrings] contract.
///
/// Components / Classes / Functions:
/// - EnSettingsStrings: Concrete English localized strings for Settings.
library;

import 'package:project_anima/core/localization/contracts/settings_strings.dart';

/// English implementation of [SettingsStrings].
class EnSettingsStrings implements SettingsStrings {
  const EnSettingsStrings();

  @override
  final String title = 'SETTINGS';

  @override
  final String themeTitle = 'STYLE & THEME';

  @override
  final String themeModeTitle = 'PALETTE MODE';

  @override
  final String languageTitle = 'LANGUAGE';
}

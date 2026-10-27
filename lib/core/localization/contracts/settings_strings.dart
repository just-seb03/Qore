/// File: settings_strings.dart
/// Description: Contract definition for localized strings used within the
/// Settings lateral side sheet feature.
///
/// Components / Classes / Functions:
/// - SettingsStrings: Abstract interface defining settings string accessors.
library;

/// Contract definition for Settings feature localized strings.
abstract class SettingsStrings {
  /// Header title for the Settings side sheet.
  String get title;

  /// Header title for the theme selector section.
  String get themeTitle;

  /// Header title for the brightness/mode selector section.
  String get themeModeTitle;

  /// Header title for the language selector section.
  String get languageTitle;
}

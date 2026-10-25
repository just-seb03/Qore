/// File: startup_strings.dart
/// Description: Interface Segregation contract defining strings for the Startup feature,
/// including launch branding, permission request screens, and initialization progress stages.
///
/// Components / Classes / Functions:
/// - StartupStrings: Abstract contract for Startup feature localization.
library;

/// Contract defining localized strings for the Startup initialization feature.
abstract class StartupStrings {
  /// Brand application title (e.g. 'PROJECT ANIMA').
  String get appTitle;

  /// Title for permission required screen (e.g. 'AUDIO ACCESS REQUIRED').
  String get audioAccessRequiredTitle;

  /// Explanatory message for permission request screen.
  String get audioAccessRequiredMessage;

  /// Action button to grant permissions (e.g. 'CONTINUE').
  String get continueAction;

  /// Stage progress label during initial filesystem discovery (e.g. 'Scanning library...').
  String get scanningLibrary;

  /// Stage progress label during track persistence (e.g. 'Saving your tracks...').
  String get savingTracks;

  /// Stage progress label during cover art extraction (e.g. 'Saving covers...').
  String get savingCovers;

  /// Stage progress label during final component caching (e.g. 'Finalizing setup...').
  String get finalizingSetup;

  /// Stage progress label upon successful completion (e.g. 'All set!').
  String get allSet;
}

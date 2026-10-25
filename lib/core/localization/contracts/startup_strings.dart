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

  /// Card title requesting permissions (e.g. 'PERMISSIONS REQUIRED').
  String get permissionsCardTitle;

  /// Explanatory description of required device permissions.
  String get permissionsCardDescription;

  /// Title for local music and storage access.
  String get musicAccessTitle;

  /// Description of music and storage access.
  String get musicAccessDescription;

  /// Title for playback notification access.
  String get notificationAccessTitle;

  /// Description of playback notification access.
  String get notificationAccessDescription;

  /// Action button on permission card (e.g. 'GRANT PERMISSIONS').
  String get grantPermissionsButton;

  /// Header title for the theme selector screen (e.g. 'SELECT THEME').
  String get themeSelectorTitle;

  /// Name of the initial monochrome dark theme ('Monochrome').
  String get themeNameMonochrome;

  /// Action button on theme selector (e.g. 'ACCEPT').
  String get acceptThemeAction;

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

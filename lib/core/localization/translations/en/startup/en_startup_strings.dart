/// File: en_startup_strings.dart
/// Description: English implementation of the [StartupStrings] contract.
///
/// Components / Classes / Functions:
/// - EnStartupStrings: Concrete English string resources for the Startup feature.
library;

import 'package:project_anima/core/localization/contracts/startup_strings.dart';

/// English translations for the Startup initialization feature.
class EnStartupStrings implements StartupStrings {
  const EnStartupStrings();

  @override
  String get appTitle => 'QORE';

  @override
  String get welcomeLine1 => 'Welcome';

  @override
  String get welcomeLine2 => 'To';

  @override
  String get welcomeLine3 => 'Qore';

  @override
  String get musicAccessPrompt =>
      'In order to use Qore you need to grant access to your music files';

  @override
  String get notificationAccessPrompt =>
      'It also needs access to the notification system for background playback features';

  @override
  String get permissionDeniedPrompt =>
      'The necessary permissions were not granted. Please try again to continue.';

  @override
  String get nextAction => 'NEXT';

  @override
  String get audioAccessRequiredTitle => 'AUDIO ACCESS REQUIRED';

  @override
  String get audioAccessRequiredMessage =>
      'Qore requires access to your audio files to discover, organize, and play your local music library.';

  @override
  String get continueAction => 'CONTINUE';

  @override
  String get permissionsCardTitle => 'PERMISSIONS REQUIRED';

  @override
  String get permissionsCardDescription =>
      'Qore needs the following permissions to deliver a complete, seamless listening experience:';

  @override
  String get musicAccessTitle => 'Music & Audio Access';

  @override
  String get musicAccessDescription =>
      'Access local media storage to discover, index, and play your audio library.';

  @override
  String get notificationAccessTitle => 'Notification Controls';

  @override
  String get notificationAccessDescription =>
      'Display playback controls, artist info, and lock screen media widgets.';

  @override
  String get grantPermissionsButton => 'GRANT PERMISSIONS';

  @override
  String get themeNameMonochrome => 'Monochrome';

  @override
  String get darkModeLabel => 'Dark';

  @override
  String get lightModeLabel => 'Light';

  @override
  String get scanningLibrary => 'Scanning library...';

  @override
  String get savingTracks => 'Saving your tracks...';

  @override
  String get savingCovers => 'Saving covers...';

  @override
  String get finalizingSetup => 'Finalizing setup...';

  @override
  String get allSet => 'All set!';
}

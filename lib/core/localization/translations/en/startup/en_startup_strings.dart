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
  String get appTitle => 'PROJECT ANIMA';

  @override
  String get audioAccessRequiredTitle => 'AUDIO ACCESS REQUIRED';

  @override
  String get audioAccessRequiredMessage =>
      'Project Anima requires access to your audio files to discover, organize, and play your local music library.';

  @override
  String get continueAction => 'CONTINUE';

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

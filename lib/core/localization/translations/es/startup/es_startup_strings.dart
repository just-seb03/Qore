/// File: es_startup_strings.dart
/// Description: Spanish implementation of the [StartupStrings] contract.
///
/// Components / Classes / Functions:
/// - EsStartupStrings: Concrete Spanish string resources for Startup feature.
library;

import 'package:project_anima/core/localization/contracts/startup_strings.dart';

/// Spanish translations for the Startup initialization feature.
class EsStartupStrings implements StartupStrings {
  const EsStartupStrings();

  @override
  String get appTitle => 'PROJECT ANIMA';

  @override
  String get audioAccessRequiredTitle => 'ACCESO A AUDIO REQUERIDO';

  @override
  String get audioAccessRequiredMessage =>
      'Project Anima requiere acceso a tus archivos de audio para descubrir, organizar y reproducir tu biblioteca local de música.';

  @override
  String get continueAction => 'CONTINUAR';

  @override
  String get scanningLibrary => 'Escaneando biblioteca...';

  @override
  String get savingTracks => 'Guardando tus canciones...';

  @override
  String get savingCovers => 'Guardando portadas...';

  @override
  String get finalizingSetup => 'Finalizando configuración...';

  @override
  String get allSet => '¡Todo listo!';
}

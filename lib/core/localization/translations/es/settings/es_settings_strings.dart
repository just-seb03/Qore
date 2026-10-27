/// File: es_settings_strings.dart
/// Description: Spanish concrete implementation of the [SettingsStrings] contract.
///
/// Components / Classes / Functions:
/// - EsSettingsStrings: Concrete Spanish localized strings for Settings.
library;

import 'package:project_anima/core/localization/contracts/settings_strings.dart';

/// Spanish implementation of [SettingsStrings].
class EsSettingsStrings implements SettingsStrings {
  const EsSettingsStrings();

  @override
  final String title = 'CONFIGURACIÓN';

  @override
  final String themeTitle = 'ESTILO Y TEMA';

  @override
  final String themeModeTitle = 'MODO DE PALETA';

  @override
  final String languageTitle = 'IDIOMA';
}

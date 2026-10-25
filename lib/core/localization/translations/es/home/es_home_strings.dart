/// File: es_home_strings.dart
/// Description: Spanish implementation of the [HomeStrings] contract.
///
/// Components / Classes / Functions:
/// - EsHomeStrings: Concrete Spanish string resources for Home screen.
library;

import 'package:project_anima/core/localization/contracts/home_strings.dart';

/// Spanish translations for the Home feature.
class EsHomeStrings implements HomeStrings {
  const EsHomeStrings();

  @override
  String get welcomeTitle => 'BIENVENIDO';

  @override
  String get doneButtonTooltip => 'Listo';

  @override
  String get favoritesHeroTitle => 'Favoritos';

  @override
  String get todaySelectionHeroTitle => 'Selección de hoy';

  @override
  String get artistSubtitle => 'Artista';
}

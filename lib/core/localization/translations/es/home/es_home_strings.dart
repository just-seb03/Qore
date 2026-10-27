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
  String get spaceTitle => 'Space';

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

  @override
  String get spaceIntroWelcome =>
      'Bienvenido a Space, el lugar para tu contenido favorito';

  @override
  String get spaceIntroFavorites =>
      'Aquí todo el contenido que tengas guardado con un ❤️ aparecerá anclado';

  @override
  String get spaceIntroDirectAccess =>
      'Así tendrás acceso directo a la música que más amas';
}

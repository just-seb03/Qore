/// File: es_navigation_strings.dart
/// Description: Spanish implementation of the [NavigationStrings] contract.
///
/// Components / Classes / Functions:
/// - EsNavigationStrings: Concrete Spanish string resources for navigation components.
library;

import 'package:project_anima/core/localization/contracts/navigation_strings.dart';

/// Spanish translations for root navigation components.
class EsNavigationStrings implements NavigationStrings {
  const EsNavigationStrings();

  @override
  String get homeTab => 'Inicio';

  @override
  String get homeTabTooltip => 'Inicio';

  @override
  String get searchTab => 'Buscar';

  @override
  String get searchTabTooltip => 'Buscar';

  @override
  String get libraryTab => 'Biblioteca';

  @override
  String get libraryTabTooltip => 'Biblioteca';
}

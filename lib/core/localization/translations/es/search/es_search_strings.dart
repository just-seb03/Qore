/// File: es_search_strings.dart
/// Description: Spanish implementation of the [SearchStrings] contract.
///
/// Components / Classes / Functions:
/// - EsSearchStrings: Concrete Spanish string resources for Search feature.
library;

import 'package:project_anima/core/localization/contracts/search_strings.dart';

/// Spanish translations for the Search feature.
class EsSearchStrings implements SearchStrings {
  const EsSearchStrings();

  @override
  String get headerTitle => 'Buscar';

  @override
  String get searchPlaceholder => '¿Qué quieres escuchar?';

  @override
  String get emptyLibraryTitle => 'BUSCA EN TU BIBLIOTECA';

  @override
  String get emptyLibrarySubtitle => 'Títulos, artistas o álbumes indexados';

  @override
  String get noResultsTitle => 'NO SE ENCONTRARON RESULTADOS';

  @override
  String noResultsSubtitle(String query) => 'No se encontraron coincidencias para "$query"';

  @override
  String get recentSearchesHeader => 'BÚSQUEDAS RECIENTES';

  @override
  String get clearAllRecentAction => 'Borrar todo';

  @override
  String get removeRecentTooltip => 'Eliminar de recientes';

  @override
  String get topResultHeader => 'MEJOR RESULTADO';

  @override
  String get albumsSectionHeader => 'ÁLBUMES';

  @override
  String get artistsSectionHeader => 'ARTISTAS';

  @override
  String get songsSectionHeader => 'CANCIONES';

  @override
  String get artistSubtitle => 'Artista';

  @override
  String songCount(int count) => '$count ${count == 1 ? "canción" : "canciones"}';

  @override
  String get clearSearchTooltip => 'Borrar búsqueda';
}

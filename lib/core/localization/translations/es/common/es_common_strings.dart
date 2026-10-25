/// File: es_common_strings.dart
/// Description: Spanish implementation of the [CommonStrings] contract.
///
/// Components / Classes / Functions:
/// - EsCommonStrings: Concrete Spanish common string resources.
library;

import 'package:project_anima/core/localization/contracts/common_strings.dart';

/// Spanish translations for shared/common application strings.
class EsCommonStrings implements CommonStrings {
  const EsCommonStrings();

  @override
  String get addToFavorites => 'Añadir a favoritos';

  @override
  String get removeFromFavorites => 'Quitar de favoritos';

  @override
  String get addToQueue => 'Añadir a la cola';

  @override
  String get unknownArtist => 'Artista desconocido';

  @override
  String get unknownAlbum => 'Álbum desconocido';

  @override
  String get unknownTitle => 'Título desconocido';

  @override
  String get unknownGenre => 'Género desconocido';

  @override
  String get done => 'Listo';
}

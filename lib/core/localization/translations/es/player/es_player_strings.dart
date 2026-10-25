/// File: es_player_strings.dart
/// Description: Spanish implementation of the [PlayerStrings] contract.
///
/// Components / Classes / Functions:
/// - EsPlayerStrings: Concrete Spanish string resources for Player feature.
library;

import 'package:project_anima/core/localization/contracts/player_strings.dart';

/// Spanish translations for the Player feature.
class EsPlayerStrings implements PlayerStrings {
  const EsPlayerStrings();

  @override
  String get nowPlayingHeader => 'EN REPRODUCCIÓN';

  @override
  String get noPlayback => 'Sin reproducción';

  @override
  String get queueTitle => 'COLA DE REPRODUCCIÓN';

  @override
  String upNextHeader(int count) =>
      'A CONTINUACIÓN • $count ${count == 1 ? "PISTA" : "PISTAS"}';

  @override
  String get emptyQueue => 'La cola está vacía';

  @override
  String get clearQueue => 'Limpiar';

  @override
  String get shuffleTooltip => 'Modo aleatorio';

  @override
  String get previousTooltip => 'Pista anterior';

  @override
  String get nextTooltip => 'Siguiente pista';

  @override
  String get playTooltip => 'Reproducir';

  @override
  String get pauseTooltip => 'Pausar';

  @override
  String get loopTooltip => 'Modo repetición';

  @override
  String get queueTooltip => 'Cola de reproducción';
}

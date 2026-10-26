/// File: playlist_effect_helper.dart
/// Description: Curated visual typography effect options (Drop Shadow, Neon Glow, Glitch,
/// Crisp Outline, Retro 3D extrusion) and dynamic Shadow resolution for playlist title banners.
///
/// Components / Classes / Functions:
/// - PlaylistEffectOption: Data class representing a selectable title effect.
/// - availablePlaylistEffects: Curated list of 6 distinct visual effects.
/// - getPlaylistTextEffectShadows: Generates the List of Shadow instances for an effect.
library;

import 'package:flutter/material.dart';

/// Represents a visual style/shadow effect choice for playlist titles.
class PlaylistEffectOption {
  /// Unique identifier saved in SQLite (e.g. 'none', 'shadow', 'neon', etc.).
  final String id;

  /// User-facing display label.
  final String displayName;

  const PlaylistEffectOption({
    required this.id,
    required this.displayName,
  });
}

/// Curated selection of 6 distinctive typography effects.
const List<PlaylistEffectOption> availablePlaylistEffects = [
  PlaylistEffectOption(id: 'none', displayName: 'Ninguno'),
  PlaylistEffectOption(id: 'shadow', displayName: 'Sombra'),
  PlaylistEffectOption(id: 'neon', displayName: 'Neón'),
  PlaylistEffectOption(id: 'glitch', displayName: 'Glitch'),
  PlaylistEffectOption(id: 'outline', displayName: 'Contorno'),
  PlaylistEffectOption(id: 'retro3d', displayName: 'Retro 3D'),
];

/// Returns the list of [Shadow] elements corresponding to the given [effectId].
List<Shadow> getPlaylistTextEffectShadows(String? effectId, {int textColor = 0xFFFFFFFF}) {
  switch (effectId?.toLowerCase().trim()) {
    case 'shadow':
      return [
        Shadow(
          color: Colors.black.withValues(alpha: 0.95),
          blurRadius: 8.0,
          offset: const Offset(2.0, 4.0),
        ),
        Shadow(
          color: Colors.black.withValues(alpha: 0.70),
          blurRadius: 18.0,
          offset: const Offset(4.0, 8.0),
        ),
      ];

    case 'neon':
      final glow = Color(textColor).withValues(alpha: 0.90);
      return [
        Shadow(color: glow, blurRadius: 8.0, offset: Offset.zero),
        Shadow(color: glow, blurRadius: 18.0, offset: Offset.zero),
        Shadow(color: glow, blurRadius: 32.0, offset: Offset.zero),
        const Shadow(color: Colors.white, blurRadius: 4.0, offset: Offset.zero),
        Shadow(
          color: Colors.black.withValues(alpha: 0.80),
          blurRadius: 12.0,
          offset: const Offset(0, 2),
        ),
      ];

    case 'glitch':
      return [
        const Shadow(
          color: Color(0xFF00E5FF),
          blurRadius: 2.0,
          offset: Offset(-3.5, 0),
        ),
        const Shadow(
          color: Color(0xFFFF0055),
          blurRadius: 2.0,
          offset: Offset(3.5, 0),
        ),
        Shadow(
          color: Colors.black.withValues(alpha: 0.85),
          blurRadius: 6.0,
          offset: const Offset(0, 3),
        ),
      ];

    case 'outline':
      return [
        const Shadow(color: Colors.black, blurRadius: 0, offset: Offset(-2.0, -2.0)),
        const Shadow(color: Colors.black, blurRadius: 0, offset: Offset(2.0, -2.0)),
        const Shadow(color: Colors.black, blurRadius: 0, offset: Offset(-2.0, 2.0)),
        const Shadow(color: Colors.black, blurRadius: 0, offset: Offset(2.0, 2.0)),
        const Shadow(color: Colors.black, blurRadius: 0, offset: Offset(0, -2.5)),
        const Shadow(color: Colors.black, blurRadius: 0, offset: Offset(0, 2.5)),
        const Shadow(color: Colors.black, blurRadius: 0, offset: Offset(-2.5, 0)),
        const Shadow(color: Colors.black, blurRadius: 0, offset: Offset(2.5, 0)),
        Shadow(
          color: Colors.black.withValues(alpha: 0.75),
          blurRadius: 8.0,
          offset: const Offset(0, 3),
        ),
      ];

    case 'retro3d':
      return [
        const Shadow(color: Color(0xFF1B1B2F), blurRadius: 0, offset: Offset(1.5, 1.5)),
        const Shadow(color: Color(0xFF162447), blurRadius: 0, offset: Offset(3.0, 3.0)),
        const Shadow(color: Color(0xFF1F4068), blurRadius: 0, offset: Offset(4.5, 4.5)),
        const Shadow(color: Color(0xFFE43F5A), blurRadius: 0, offset: Offset(6.0, 6.0)),
        Shadow(
          color: Colors.black.withValues(alpha: 0.85),
          blurRadius: 8.0,
          offset: const Offset(7.5, 7.5),
        ),
      ];

    case 'none':
    default:
      return const [];
  }
}

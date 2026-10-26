/// File: playlist_font_helper.dart
/// Description: Curated typography helper for playlist titles.
/// Provides a variety of expressive font options (Monospace, Editorial Serif,
/// Modern Geometric, Handwritten, Display, Futuristic) and safe font resolution.
///
/// Components / Classes / Functions:
/// - PlaylistFontOption: Data class representing a selectable font option.
/// - availablePlaylistFonts: List of curated font choices for playlists.
/// - getPlaylistTitleFont: Safe dynamic TextStyle generator with Inconsolata fallback.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Represents a typography choice for playlist titles.
class PlaylistFontOption {
  /// Font family key identifier saved in SQLite.
  final String id;

  /// User-facing display label.
  final String displayName;

  const PlaylistFontOption({
    required this.id,
    required this.displayName,
  });
}

/// Curated selection of expressive Google Fonts for playlist presentation.
const List<PlaylistFontOption> availablePlaylistFonts = [
  PlaylistFontOption(id: 'UnifrakturMaguntia', displayName: 'UnifrakturMaguntia'),
  PlaylistFontOption(id: 'Fascinate Inline', displayName: 'Fascinate Inline'),
  PlaylistFontOption(id: 'Permanent Marker', displayName: 'Permanent Marker'),
  PlaylistFontOption(id: 'Splash', displayName: 'Splash'),
  PlaylistFontOption(id: 'Monoton', displayName: 'Monoton'),
  PlaylistFontOption(id: 'Alien Block', displayName: 'Alien Block'),
  PlaylistFontOption(id: 'Michroma', displayName: 'Michroma'),
  PlaylistFontOption(id: 'Silkscreen', displayName: 'Silkscreen'),
  PlaylistFontOption(id: 'DotGothic16', displayName: 'DotGothic16'),
  PlaylistFontOption(id: 'Press Start 2P', displayName: 'Press Start 2P'),
  PlaylistFontOption(id: 'Rubik Glitch', displayName: 'Rubik Glitch'),
  PlaylistFontOption(id: 'Audiowide', displayName: 'Audiowide'),
];

/// Safely resolves a [TextStyle] for the requested [fontFamily] using GoogleFonts.
/// Falls back gracefully to Inconsolata if offline or in unit tests.
TextStyle getPlaylistTitleFont(String? fontFamily, {TextStyle? baseStyle}) {
  final cleanFamily = fontFamily?.trim();
  if (cleanFamily == null || cleanFamily.isEmpty) {
    try {
      return GoogleFonts.unifrakturMaguntia(textStyle: baseStyle);
    } catch (_) {
      return (baseStyle ?? const TextStyle()).copyWith(fontFamily: 'UnifrakturMaguntia');
    }
  }

  try {
    return GoogleFonts.getFont(cleanFamily, textStyle: baseStyle);
  } catch (_) {
    try {
      return GoogleFonts.inconsolata(textStyle: baseStyle);
    } catch (_) {
      return (baseStyle ?? const TextStyle()).copyWith(fontFamily: cleanFamily);
    }
  }
}

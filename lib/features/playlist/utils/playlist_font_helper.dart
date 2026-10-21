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

/// Curated selection of expressive fonts for playlist presentation.
const List<PlaylistFontOption> availablePlaylistFonts = [
  PlaylistFontOption(id: 'Inconsolata', displayName: 'Inconsolata'),
  PlaylistFontOption(id: 'Outfit', displayName: 'Outfit'),
  PlaylistFontOption(id: 'Cinzel', displayName: 'Cinzel'),
  PlaylistFontOption(id: 'Playfair Display', displayName: 'Playfair'),
  PlaylistFontOption(id: 'Bebas Neue', displayName: 'Bebas Neue'),
  PlaylistFontOption(id: 'Caveat', displayName: 'Caveat'),
  PlaylistFontOption(id: 'Space Grotesk', displayName: 'Space Grotesk'),
  PlaylistFontOption(id: 'Syne', displayName: 'Syne'),
  PlaylistFontOption(id: 'Montserrat', displayName: 'Montserrat'),
  PlaylistFontOption(id: 'Lobster', displayName: 'Lobster'),
];

/// Safely resolves a [TextStyle] for the requested [fontFamily] using GoogleFonts.
/// Falls back gracefully to Inconsolata if offline or in unit tests.
TextStyle getPlaylistTitleFont(String? fontFamily, {TextStyle? baseStyle}) {
  final cleanFamily = fontFamily?.trim();
  if (cleanFamily == null ||
      cleanFamily.isEmpty ||
      cleanFamily.toLowerCase() == 'inconsolata') {
    try {
      return GoogleFonts.inconsolata(textStyle: baseStyle);
    } catch (_) {
      return (baseStyle ?? const TextStyle()).copyWith(fontFamily: 'Inconsolata');
    }
  }

  try {
    return GoogleFonts.getFont(cleanFamily, textStyle: baseStyle);
  } catch (_) {
    try {
      return GoogleFonts.inconsolata(textStyle: baseStyle);
    } catch (_) {
      return baseStyle ?? const TextStyle();
    }
  }
}

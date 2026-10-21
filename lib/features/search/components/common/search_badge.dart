/// File: search_badge.dart
/// Description: Spotify-styled pill badge displaying entity category
/// ('SONG', 'ALBUM', 'ARTIST') in Top Result cards.
///
/// Components / Classes / Functions:
/// - SearchBadge: Pill container with dark background and Inconsolata label.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pill badge displaying category type in Top Result cards.
class SearchBadge extends StatelessWidget {
  /// Category label text (e.g. 'SONG', 'ALBUM', 'ARTIST').
  final String label;

  /// Background color of the badge. Defaults to #282828.
  final Color backgroundColor;

  /// Text color. Defaults to white.
  final Color textColor;

  const SearchBadge({
    super.key,
    required this.label,
    this.backgroundColor = const Color(0xFF282828),
    this.textColor = Colors.white,
  });

  static final TextStyle _badgeTextStyle = GoogleFonts.inconsolata(
    fontSize: 11.5,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Text(
        label,
        style: _badgeTextStyle.copyWith(color: textColor),
      ),
    );
  }
}

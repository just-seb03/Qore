/// File: library_playlists_placeholder.dart
/// Description: Placeholder state widget for the Playlists tab in the Library.
/// Displays an icon and informative text indicating playlists will be available in future releases.
///
/// Components / Classes / Functions:
/// - LibraryPlaylistsPlaceholder: Stateless placeholder widget.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Placeholder state widget for the Playlists view.
class LibraryPlaylistsPlaceholder extends StatelessWidget {
  const LibraryPlaylistsPlaceholder({super.key});

  static final TextStyle _headerStyle = GoogleFonts.zenDots(
    fontSize: 13.0,
    letterSpacing: 1.5,
    color: AppColors.futuristicWhite.withValues(alpha: 0.35),
  );

  static final TextStyle _subtitleStyle = GoogleFonts.inconsolata(
    fontSize: 13.5,
    color: AppColors.futuristicWhite.withValues(alpha: 0.25),
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.queue_music_rounded,
              size: 56.0,
              color: AppColors.futuristicWhite.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16.0),
            Text(
              'NO PLAYLISTS YET',
              textAlign: TextAlign.center,
              style: _headerStyle,
            ),
            const SizedBox(height: 6.0),
            Text(
              'Custom playlists will appear here',
              textAlign: TextAlign.center,
              style: _subtitleStyle,
            ),
          ],
        ),
      ),
    );
  }
}

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
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Placeholder state widget for the Playlists view.
class LibraryPlaylistsPlaceholder extends StatelessWidget {
  /// Optional callback invoked when tapping the create playlist action.
  final VoidCallback? onCreatePlaylist;

  const LibraryPlaylistsPlaceholder({
    super.key,
    this.onCreatePlaylist,
  });

  static final TextStyle _headerStyle = GoogleFonts.inconsolata(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
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
              context.l10n.library.emptyPlaylistsTitle,
              textAlign: TextAlign.center,
              style: _headerStyle,
            ),
            const SizedBox(height: 6.0),
            Text(
              context.l10n.library.emptyPlaylistsSubtitle,
              textAlign: TextAlign.center,
              style: _subtitleStyle,
            ),
            if (onCreatePlaylist != null) ...[
              const SizedBox(height: 22.0),
              OutlinedButton.icon(
                key: const ValueKey('library_empty_create_playlist_button'),
                onPressed: onCreatePlaylist,
                icon: const Icon(Icons.add_rounded, size: 20.0),
                label: Text(
                  context.l10n.playlist.createPlaylistTitle,
                  style: GoogleFonts.inconsolata(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

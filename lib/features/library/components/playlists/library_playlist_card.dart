/// File: library_playlist_card.dart
/// Description: Individual playlist card widget for the Library playlists 2-per-row grid.
/// Enforces sharp 90-degree square corners without rounded borders,
/// rich elevation shadows, and Inconsolata typography for playlist title and metadata.
///
/// Components / Classes / Functions:
/// - LibraryPlaylistCard: Stateless card widget presenting playlist artwork, title, and song count.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Card widget rendering a playlist in the Library grid (2 per row).
class LibraryPlaylistCard extends StatelessWidget {
  /// Playlist model data.
  final Playlist playlist;

  /// Callback when the playlist card is tapped.
  final VoidCallback? onTap;

  const LibraryPlaylistCard({
    super.key,
    required this.playlist,
    this.onTap,
  });

  static final TextStyle _titleStyle = GoogleFonts.inconsolata(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.1,
  );

  static final TextStyle _subtitleStyle = GoogleFonts.inconsolata(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFB3B3B3),
    letterSpacing: 0.1,
  );

  String _formatDuration(int ms) {
    final minutes = ms ~/ 60000;
    if (minutes < 1) return '< 1 min';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remMin = minutes % 60;
    return '${hours}h ${remMin}m';
  }

  @override
  Widget build(BuildContext context) {
    final songStr = playlist.songCount == 1 ? '1 song' : '${playlist.songCount} songs';
    final durationStr = playlist.totalDuration > 0
        ? ' • ${_formatDuration(playlist.totalDuration)}'
        : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFF282828),
        highlightColor: const Color(0xFF1E1E1E),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Square Artwork with Shadow (unrounded, matches album card)
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 10.0,
                      spreadRadius: 1.0,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _buildCoverWidget(),
              ),
            ),
            const SizedBox(height: 10.0),

            // 2. Playlist Name
            Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _titleStyle,
            ),
            const SizedBox(height: 2.0),

            // 3. Track Count & Duration
            Text(
              '$songStr$durationStr',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _subtitleStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverWidget() {
    // 1. Custom Picked Image
    if (playlist.coverPath != null && File(playlist.coverPath!).existsSync()) {
      return Image.file(
        File(playlist.coverPath!),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    // 2. First Song Artwork Fallback
    if (playlist.firstMediaStoreId != null && playlist.firstMediaStoreId! > 0) {
      return AnimaArtworkImage(
        mediaStoreId: playlist.firstMediaStoreId!,
        width: double.infinity,
        height: double.infinity,
        borderRadius: 0.0,
        fallbackIcon: Symbols.queue_music_rounded,
        isThumbnail: false,
        fit: BoxFit.cover,
      );
    }

    // 3. Generic Playlist Icon
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Symbols.queue_music_rounded,
          size: 48.0,
          color: AppColors.futuristicWhite.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

/// File: search_discovery_card.dart
/// Description: Square card widget for Discovery sections (e.g. Today Selection and Recientes)
/// mirroring the LibraryAlbumCard visual styling: sharp 90-degree square corners, rich elevation
/// shadow, Inconsolata typography, and a 4-cover compilation (2x2 grid) or empty vinyl placeholder.
///
/// Components / Classes / Functions:
/// - SearchDiscoveryCard: Square discovery card widget with 2x2 artwork collage or vinyl fallback.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/selection/today_selection_service.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Card widget rendering a 1:1 square cover with 4-cover collage and Inconsolata text.
class SearchDiscoveryCard extends StatelessWidget {
  /// Primary title (e.g. 'Today Selection' or 'Recientes').
  final String title;

  /// Secondary subtitle (e.g. '20 canciones').
  final String subtitle;

  /// Songs used to construct the 4-cover compilation (when [icon] is null).
  final List<Song> songs;

  /// Optional icon displayed on the square cover (e.g. today or clock).
  final IconData? icon;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  const SearchDiscoveryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.songs,
    this.icon,
    this.onTap,
  });

  static TextStyle get _titleStyle => GoogleFonts.inconsolata(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    letterSpacing: 0.1,
  );

  static TextStyle get _subtitleStyle => GoogleFonts.inconsolata(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.1,
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.3),
        highlightColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Square Artwork with Shadow (sharp 90-degree corners)
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 10.0,
                      spreadRadius: 1.0,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _buildCover(context),
              ),
            ),
            const SizedBox(height: 10.0),

            // 2. Card Title
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _titleStyle,
            ),
            const SizedBox(height: 2.0),

            // 3. Subtitle / Track Count
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _subtitleStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    if (icon != null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 52.0,
            color: AppColors.accent,
          ),
        ),
      );
    }

    if (songs.isEmpty) {
      return _buildEmptyCover(context);
    }

    final collage = TodaySelectionService.instance.getCollageSongs(songs);
    if (collage.isEmpty) {
      return _buildEmptyCover(context);
    }

    if (collage.length == 1) {
      return AnimaArtworkImage(
        mediaStoreId: collage[0].mediaStoreId,
        albumId: collage[0].albumId,
        albumName: collage[0].album,
        artistName: collage[0].albumArtist ?? collage[0].artist,
        width: double.infinity,
        height: double.infinity,
        borderRadius: 0.0,
        fallbackIcon: Icons.album_rounded,
        isThumbnail: false,
        fit: BoxFit.cover,
      );
    }

    // 2x2 4-cover compilation (wrapping around if fewer than 4 distinct songs)
    final cell0 = collage[0];
    final cell1 = collage[1 % collage.length];
    final cell2 = collage[2 % collage.length];
    final cell3 = collage[3 % collage.length];

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildArtworkTile(cell0)),
              Expanded(child: _buildArtworkTile(cell1)),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildArtworkTile(cell2)),
              Expanded(child: _buildArtworkTile(cell3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArtworkTile(Song song) {
    return AnimaArtworkImage(
      mediaStoreId: song.mediaStoreId,
      albumId: song.albumId,
      albumName: song.album,
      artistName: song.albumArtist ?? song.artist,
      width: double.infinity,
      height: double.infinity,
      borderRadius: 0.0,
      fallbackIcon: Icons.album_rounded,
      isThumbnail: true,
      fit: BoxFit.cover,
    );
  }

  Widget _buildEmptyCover(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.album_rounded,
          size: 48.0,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

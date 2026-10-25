/// File: album_header_view.dart
/// Description: Dedicated header component for AlbumDetailScreen rendering the large
/// unrounded square album artwork with deep cinematic drop-shadow, album title,
/// tappable artist navigation link, and total duration metadata.
///
/// Components / Classes / Functions:
/// - AlbumHeaderView: Cohesive header component for album presentation.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/components/favorite_heart_button.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/search/models/recent_search_item.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';

/// Cohesive album header displaying large sharp artwork, title, artist link, and duration.
class AlbumHeaderView extends StatelessWidget {
  /// Name of the album to display.
  final String albumName;

  /// Primary or credited artist of the album, if known.
  final String? artistName;

  /// Android MediaStore album ID, if available.
  final int? albumId;

  /// Representative song ID used for artwork resolution.
  final int? representativeSongId;

  /// Total number of tracks in the album.
  final int songCount;

  /// Combined duration in milliseconds across all album tracks.
  final int totalDurationMs;

  /// Whether the album is pinned to favorites.
  final bool isPinned;

  /// Callback when the favorite heart button is tapped.
  final VoidCallback? onToggleFavorite;

  const AlbumHeaderView({
    super.key,
    required this.albumName,
    this.artistName,
    this.albumId,
    this.representativeSongId,
    required this.songCount,
    required this.totalDurationMs,
    this.isPinned = false,
    this.onToggleFavorite,
  });

  String _formatTotalDuration(BuildContext context, int totalMs) {
    if (totalMs <= 0) return '';
    final totalSeconds = totalMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0) {
      return context.l10n.album
          .durationHoursMinutes(hours, remainingMinutes);
    }
    return context.l10n.album.durationMinutes(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double coverSize = (screenSize.width - 88.0).clamp(220.0, 300.0);

    final durationStr = _formatTotalDuration(context, totalDurationMs);
    final countStr = context.l10n.album.songCount(songCount);
    final metadataSubtitle = context.l10n.album.metadataSubtitle(
      countStr: countStr,
      durationStr: durationStr,
    );

    final sanitizedArtist = sanitizeArtistName(artistName);
    final unknownArtist = context.l10n.album.unknownArtist;
    final displayArtist = (sanitizedArtist != null &&
            sanitizedArtist.trim().isNotEmpty &&
            sanitizedArtist != '<Desconocido>')
        ? sanitizedArtist
        : unknownArtist;

    final hasValidArtist = displayArtist != unknownArtist;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Large Sharp Square Album Artwork with Deep Shadow (Not rounded)
        Container(
          width: coverSize,
          height: coverSize,
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 36.0,
                spreadRadius: 2.0,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimaArtworkImage(
            mediaStoreId: representativeSongId ?? 0,
            albumId: albumId,
            albumName: albumName,
            artistName: artistName,
            width: coverSize,
            height: coverSize,
            borderRadius: 0.0,
            isThumbnail: false,
            fallbackIcon: Icons.album_rounded,
          ),
        ),
        const SizedBox(height: 24.0),

        // 2. Album Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            albumName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 24.0,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 6.0),

        // 3. Artist Link (Tappable to Artist Profile)
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.0),
            onTap: hasValidArtist
                ? () {
                    Navigator.of(context).push(
                      ArtistDetailScreen.route(displayArtist),
                    );
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
              child: Text(
                displayArtist,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4.0),

        // 4. Album Duration & Track Count
        Text(
          metadataSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inconsolata(
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
        if (onToggleFavorite != null) ...[
          const SizedBox(height: 12.0),
          FavoriteHeartButton(
            isPinned: isPinned,
            onToggle: onToggleFavorite!,
            size: 28.0,
          ),
        ],
      ],
    );
  }
}

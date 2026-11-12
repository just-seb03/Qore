/// File: artist_discography_album_card.dart
/// Description: Individual album card widget for the Artist Discography 2-per-row grid.
/// Enforces sharp 90-degree square corners without rounded borders,
/// rich elevation shadows, and Inconsolata typography for album and track count metadata.
///
/// Components / Classes / Functions:
/// - ArtistDiscographyAlbumCard: Stateless card widget presenting album artwork, title, and metadata.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';

/// Card widget rendering an individual album in the Artist Discography grid.
class ArtistDiscographyAlbumCard extends StatelessWidget {
  /// Aggregated album data.
  final AlbumDiscoveryItem album;

  /// Optional tap callback. If null, navigates to [AlbumDetailScreen].
  final VoidCallback? onTap;

  const ArtistDiscographyAlbumCard({
    super.key,
    required this.album,
    this.onTap,
  });

  static TextStyle get _titleStyle => AppFonts.segoe(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    letterSpacing: 0.1,
  );

  static TextStyle get _metaStyle => AppFonts.segoe(
    fontSize: 12.0,
    fontWeight: FontWeight.w300,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.1,
  );

  @override
  Widget build(BuildContext context) {
    final countLabel =
        context.l10n.artistDiscography.trackCount(album.songCount);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: onTap ??
            () {
              Navigator.of(context).push(
                AlbumDetailScreen.route(
                  albumName: album.name,
                  artistName: album.artist,
                  albumId: album.albumId,
                  representativeSongId: album.representativeSongId,
                ),
              );
            },
        splashColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.3),
        highlightColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Sharp square artwork without drop shadow
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.zero,
                ),
                child: AnimaArtworkImage(
                  mediaStoreId: album.representativeSongId,
                  albumName: album.name,
                  artistName: album.artist,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 0.0,
                  fallbackIcon: Icons.album_rounded,
                  isThumbnail: false,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 10.0),

            // 2. Album Title
            Text(
              album.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _titleStyle,
            ),
            const SizedBox(height: 2.0),

            // 3. Track Count Metadata
            Text(
              countLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _metaStyle,
            ),
          ],
        ),
      ),
    );
  }
}

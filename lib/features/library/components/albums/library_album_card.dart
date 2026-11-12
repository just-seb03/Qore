/// File: library_album_card.dart
/// Description: Album item widget for the Library. Supports both authentic Windows Phone
/// Metro list tile presentation (with sharp 90-degree square cover on the left and typography
/// on the right) as well as the classic 2-column card presentation.
///
/// Components / Classes / Functions:
/// - LibraryAlbumCard: Stateless widget presenting album artwork, title, and artist.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Card/Tile widget rendering an album in the Library.
class LibraryAlbumCard extends StatelessWidget {
  /// Standard height when rendered in Metro list tile mode.
  static const double tileHeight = 70.0;

  /// Aggregated album data.
  final AlbumDiscoveryItem album;

  /// Callback when the album is tapped.
  final VoidCallback? onTap;

  /// Whether to render as a Metro horizontal list row instead of a vertical card.
  final bool isListTile;

  const LibraryAlbumCard({
    super.key,
    required this.album,
    this.onTap,
    this.isListTile = false,
  });

  static TextStyle get _titleStyle => AppFonts.segoe(
    fontSize: 15.5,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    letterSpacing: -0.1,
  );

  static TextStyle get _artistStyle => AppFonts.segoe(
    fontSize: 12.5,
    fontWeight: FontWeight.w300,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.1,
  );

  @override
  Widget build(BuildContext context) {
    if (isListTile) {
      return SizedBox(
        height: tileHeight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.3),
            highlightColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // 1. Square Artwork with Shadow (Metro sharp corners)
                  Container(
                    width: 54.0,
                    height: 54.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.zero,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 6.0,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: AnimaArtworkImage(
                      mediaStoreId: album.representativeSongId,
                      albumName: album.name,
                      artistName: album.artist,
                      width: 54.0,
                      height: 54.0,
                      borderRadius: 0.0,
                      fallbackIcon: Icons.album_rounded,
                      isThumbnail: true,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14.0),

                  // 2. Album Title & Artist
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          album.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _titleStyle,
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          album.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _artistStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
            // 1. Square Artwork with Shadow (no rounded corners)
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.zero,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 10.0,
                      spreadRadius: 1.0,
                      offset: const Offset(0, 5),
                    ),
                  ],
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

            // 3. Album Artist
            Text(
              album.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _artistStyle,
            ),
          ],
        ),
      ),
    );
  }
}

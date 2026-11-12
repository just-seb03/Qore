/// File: explore_metro_album_tile.dart
/// Description: Authentic Windows Phone Metro album tile widget for the Explore screen.
/// Features sharp 90-degree corners, zero drop shadows, full-bleed album artwork,
/// and Segoe UI Light/Semilight typography overlay.
///
/// Components / Classes / Functions:
/// - ExploreMetroAlbumTile: Album tile widget adhering to Windows Phone Metro design principles.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Authentic Windows Phone Metro sharp square album tile for horizontal carousels or grids.
class ExploreMetroAlbumTile extends StatelessWidget {
  /// Album item to display.
  final AlbumDiscoveryItem album;

  /// Callback when the album tile is tapped.
  final VoidCallback? onTap;

  /// Width and height of the square tile. Defaults to 135.0.
  final double size;

  const ExploreMetroAlbumTile({
    super.key,
    required this.album,
    this.onTap,
    this.size = 135.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        // Authentic Metro: Zero border radius, zero drop shadows
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.zero,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: AppColors.surfaceContainer,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white24,
            highlightColor: Colors.white12,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Full-bleed square album artwork (sharp corners)
                AnimaArtworkImage(
                  mediaStoreId: album.representativeSongId,
                  albumId: album.albumId,
                  albumName: album.name,
                  artistName: album.artist,
                  borderRadius: 0.0,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),

                // 2. High-contrast gradient scrim for legible typography
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black12,
                        Colors.black87,
                      ],
                      stops: [0.35, 0.65, 1.0],
                    ),
                  ),
                ),

                // 3. Metro Segoe UI typography at bottom
                Positioned(
                  left: 8.0,
                  right: 8.0,
                  bottom: 8.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        album.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.segoe(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 1.5),
                      Text(
                        album.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.segoe(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w300,
                          color: Colors.white70,
                          letterSpacing: 0.2,
                        ),
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
}


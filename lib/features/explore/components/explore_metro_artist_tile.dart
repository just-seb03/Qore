/// File: explore_metro_artist_tile.dart
/// Description: Authentic Windows Phone Metro artist tile widget for the Explore screen.
/// Adheres strictly to the Metro rule: "People tiles are square" (no circles).
/// Features sharp 90-degree corners, zero drop shadows, full-bleed photography or
/// minimalist initial fallback, and Segoe UI Light/Semilight typography overlay.
///
/// Components / Classes / Functions:
/// - ExploreMetroArtistTile: Square artist tile widget conforming to Windows Phone Metro design principles.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Authentic Windows Phone Metro sharp square artist tile.
class ExploreMetroArtistTile extends StatelessWidget {
  /// Artist item to display.
  final ArtistDiscoveryItem artist;

  /// Callback when the artist tile is tapped.
  final VoidCallback? onTap;

  /// Width and height of the square tile. Defaults to 135.0.
  final double size;

  const ExploreMetroArtistTile({
    super.key,
    required this.artist,
    this.onTap,
    this.size = 135.0,
  });

  Widget _buildFallback(BuildContext context) {
    final initial = artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?';
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Text(
          initial,
          style: AppFonts.segoe(
            fontSize: 40.0,
            fontWeight: FontWeight.w300,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        // Authentic Metro: Zero border radius, zero drop shadows, square shape (no circles!)
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
                // 1. Full-bleed square artist artwork or initial letter fallback
                AnimaArtworkImage(
                  mediaStoreId: artist.representativeSongId,
                  artistName: artist.name,
                  borderRadius: 0.0,
                  isCircular: false,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  fallback: _buildFallback(context),
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
                        artist.name,
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
                        '${artist.songCount} ${artist.songCount == 1 ? "canción" : "canciones"}',
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


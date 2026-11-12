/// File: explore_metro_tile.dart
/// Description: Authentic Windows Phone Metro Live Tile widget for the Explore screen.
/// Features sharp 90-degree corners, zero drop shadows, full-bleed artwork collage or flat
/// accent background, and Segoe UI Light/Semilight typography overlay.
///
/// Components / Classes / Functions:
/// - ExploreMetroTile: Live Tile widget conforming to Windows Phone Metro design principles.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Authentic Windows Phone Metro Live Tile for featured discovery items.
class ExploreMetroTile extends StatelessWidget {
  /// The title displayed in Segoe UI on the tile.
  final String title;

  /// Subtitle or counter label (e.g. '24 canciones').
  final String subtitle;

  /// Songs used for generating 4-cover or 1-cover artwork.
  final List<Song> songs;

  /// Optional Metro icon displayed on the tile.
  final IconData? icon;

  /// Callback when the tile is tapped.
  final VoidCallback? onTap;

  const ExploreMetroTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.songs,
    this.icon,
    this.onTap,
  });

  Widget _buildArtworkBackdrop(BuildContext context) {
    if (songs.isEmpty) {
      return Container(
        color: AppColors.surfaceContainer,
        child: Center(
          child: Icon(
            icon ?? Icons.music_note_rounded,
            size: 40.0,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    if (songs.length >= 4) {
      // 2x2 Collage with sharp 90-degree corners
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimaArtworkImage(
                    mediaStoreId: songs[0].mediaStoreId,
                    borderRadius: 0.0,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Expanded(
                  child: AnimaArtworkImage(
                    mediaStoreId: songs[1].mediaStoreId,
                    borderRadius: 0.0,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimaArtworkImage(
                    mediaStoreId: songs[2].mediaStoreId,
                    borderRadius: 0.0,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Expanded(
                  child: AnimaArtworkImage(
                    mediaStoreId: songs[3].mediaStoreId,
                    borderRadius: 0.0,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Single full-bleed cover
    return AnimaArtworkImage(
      mediaStoreId: songs.first.mediaStoreId,
      borderRadius: 0.0,
      width: double.infinity,
      height: double.infinity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
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
                // 1. Full-bleed artwork / collage
                _buildArtworkBackdrop(context),

                // 2. High-contrast gradient scrim for legible Metro typography
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black26,
                        Colors.black87,
                      ],
                      stops: [0.3, 0.65, 1.0],
                    ),
                  ),
                ),

                // 3. Optional Metro corner icon
                if (icon != null)
                  Positioned(
                    top: 10.0,
                    right: 10.0,
                    child: Icon(
                      icon,
                      size: 20.0,
                      color: Colors.white70,
                    ),
                  ),

                // 4. Metro Segoe UI Typography at bottom-left
                Positioned(
                  left: 10.0,
                  right: 10.0,
                  bottom: 10.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.segoe(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.segoe(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w300,
                          color: Colors.white70,
                          letterSpacing: 0.3,
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


/// File: explore_metro_tile.dart
/// Description: Authentic Windows Phone Metro Live Tile widget for the Explore screen.
/// Features sharp 90-degree corners, zero drop shadows, solid color or artwork backdrops,
/// and Segoe UI Light/Semilight typography.
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

  /// Songs used for generating 4-cover or 1-cover artwork when not [isSolid].
  final List<Song> songs;

  /// Optional Metro icon displayed on the tile.
  final IconData? icon;

  /// Callback when the tile is tapped.
  final VoidCallback? onTap;

  /// Whether to render as a solid color tile with centered icon and typography.
  final bool isSolid;

  /// Aspect ratio of the tile. Defaults to 1.0 (square). For wide tiles, use ~2.2.
  final double aspectRatio;

  const ExploreMetroTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.songs = const [],
    this.icon,
    this.onTap,
    this.isSolid = false,
    this.aspectRatio = 1.0,
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

  Widget _buildCenteredSolidContent(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 32.0,
                color: AppColors.onSurface,
              ),
              const SizedBox(height: 8.0),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.segoe(
                fontSize: 16.5,
                fontWeight: FontWeight.w400,
                color: AppColors.onSurface,
                letterSpacing: 0.3,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 3.0),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.segoe(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w300,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
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
            child: isSolid
                ? _buildCenteredSolidContent(context)
                : Stack(
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

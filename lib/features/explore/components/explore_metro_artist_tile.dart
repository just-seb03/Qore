/// File: explore_metro_artist_tile.dart
/// Description: Authentic Windows Phone Metro artist tile widget for the Explore screen.
/// Adheres strictly to the Metro rule: "People tiles are square" (no circles) and complies
/// with the rule that artists display their profile (custom photo or silhouette icon),
/// NEVER album covers.
///
/// Components / Classes / Functions:
/// - ExploreMetroArtistTile: Square artist tile widget conforming to Windows Phone Metro design principles.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Authentic Windows Phone Metro sharp square artist tile displaying artist profiles.
class ExploreMetroArtistTile extends StatelessWidget {
  /// Artist item to display.
  final ArtistDiscoveryItem artist;

  /// Callback when the artist tile is tapped.
  final VoidCallback? onTap;

  /// Width and height of the square tile. Defaults to 135.0.
  final double size;

  /// Optional direct file path to custom avatar image.
  final String? customImagePath;

  const ExploreMetroArtistTile({
    super.key,
    required this.artist,
    this.onTap,
    this.size = 135.0,
    this.customImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        // Authentic Metro: Zero border radius, zero drop shadows, square shape
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.zero,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: AppColors.surfaceContainerHigh,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white24,
            highlightColor: Colors.white12,
            child: ListenableBuilder(
              listenable: ArtworkService.instance,
              builder: (context, _) {
                final directPath = customImagePath != null && File(customImagePath!).existsSync()
                    ? customImagePath
                    : null;
                final customPath = directPath ??
                    ArtworkService.instance.getCustomArtistAvatar(artist.name);
                final hasCustomPhoto = customPath != null && File(customPath).existsSync();

                if (hasCustomPhoto) {
                  final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.5;
                  final int pixelSize = (size * dpr).round().clamp(64, 400);

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Full-bleed real artist photo
                      Image(
                        image: ResizeImage(
                          FileImage(File(customPath)),
                          width: pixelSize,
                          height: pixelSize,
                          policy: ResizeImagePolicy.fit,
                        ),
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
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
                  );
                }

                // Silhouette Profile: No album cover!
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Centered profile silhouette
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Icon(
                          Icons.person_rounded,
                          size: 50.0,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),

                    // Typography at bottom
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
                              color: AppColors.onSurface,
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
                              color: AppColors.onSurfaceVariant,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

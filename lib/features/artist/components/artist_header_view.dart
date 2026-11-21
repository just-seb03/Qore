/// File: artist_header_view.dart
/// Description: Large interactive artist header component featuring circular avatar,
/// atmospheric halo glow, floating pencil edit badge, and centered artist name.
///
/// Components / Classes / Functions:
/// - ArtistHeaderView: Top header view presenting the artist avatar and title.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project_anima/components/favorite_heart_button.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Authentic Windows Phone Metro artist header featuring a sharp square portrait,
/// sharp corner tile edit badge, majestic Segoe UI Light typography, and favorite heart toggle.
class ArtistHeaderView extends StatelessWidget {
  /// Name of the artist to display.
  final String artistName;

  /// Callback invoked when the user taps the edit photo badge.
  final VoidCallback onEditTap;

  /// Whether the artist is pinned to favorites.
  final bool isPinned;

  /// Callback when the favorite heart button is tapped.
  final VoidCallback? onToggleFavorite;

  const ArtistHeaderView({
    super.key,
    required this.artistName,
    required this.onEditTap,
    this.isPinned = false,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    const double avatarSize = 160.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Authentic Metro Sharp Square Artist Portrait (tap portrait directly to edit/add/remove)
          SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: Material(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.zero,
              child: InkWell(
                key: const ValueKey('artist_avatar_tap_target'),
                onTap: onEditTap,
                splashColor: AppColors.accent.withValues(alpha: 0.2),
                highlightColor: Colors.transparent,
                borderRadius: BorderRadius.zero,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListenableBuilder(
                    listenable: ArtworkService.instance,
                    builder: (context, _) {
                      final customSquare = ArtworkService.instance
                              .getCustomArtistSquarePhoto(artistName) ??
                          ArtworkService.instance
                              .getCustomArtistAvatar(artistName);
                      final hasCustomPhoto = customSquare != null &&
                          File(customSquare).existsSync();

                      if (hasCustomPhoto) {
                        return Image(
                          image: ResizeImage(
                            FileImage(File(customSquare)),
                            width: (avatarSize * 2.5).round(),
                            height: (avatarSize * 2.5).round(),
                            policy: ResizeImagePolicy.fit,
                          ),
                          fit: BoxFit.cover,
                          width: avatarSize,
                          height: avatarSize,
                        );
                      }

                      return Container(
                        color: AppColors.surfaceContainerHigh,
                        child: Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 80.0,
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14.0),

          // 2. Large Segoe UI Light/Semilight Artist Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              artistName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.segoe(
                fontSize: 32.0,
                fontWeight: FontWeight.w300,
                color: AppColors.onBackground,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // 3. Favorite Heart Button directly below title
          if (onToggleFavorite != null) ...[
            const SizedBox(height: 10.0),
            FavoriteHeartButton(
              isPinned: isPinned,
              onToggle: onToggleFavorite!,
              size: 28.0,
            ),
          ],
        ],
      ),
    );
  }
}

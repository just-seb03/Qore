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

  /// Callback when the Metro play button is tapped.
  final VoidCallback? onPlayTap;

  const ArtistHeaderView({
    super.key,
    required this.artistName,
    required this.onEditTap,
    this.isPinned = false,
    this.onToggleFavorite,
    this.onPlayTap,
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
                      final hasCustomPhoto =
                          customSquare != null && customSquare.isNotEmpty;
                      final int avatarVersion =
                          ArtworkService.instance.getArtistAvatarVersion(artistName);

                      Widget buildFallback() => Container(
                            color: AppColors.surfaceContainerHigh,
                            child: Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 80.0,
                                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                          );

                      if (hasCustomPhoto) {
                        return Image(
                          key: ValueKey('${customSquare}_v$avatarVersion'),
                          image: ResizeImage(
                            FileImage(File(customSquare)),
                            width: (avatarSize * 2.5).round(),
                            height: (avatarSize * 2.5).round(),
                            policy: ResizeImagePolicy.fit,
                          ),
                          fit: BoxFit.cover,
                          width: avatarSize,
                          height: avatarSize,
                          errorBuilder: (_, _, _) => buildFallback(),
                        );
                      }

                      return buildFallback();
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

          // 3. Action row: Favorite Heart on left margin, Metro Play button on right margin
          if (onToggleFavorite != null || onPlayTap != null) ...[
            const SizedBox(height: 12.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  if (onToggleFavorite != null)
                    FavoriteHeartButton(
                      key: const ValueKey('artist_favorite_button'),
                      isPinned: isPinned,
                      onToggle: onToggleFavorite!,
                      size: 28.0,
                    ),
                  const Spacer(),
                  if (onPlayTap != null)
                    Material(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.zero,
                      child: InkWell(
                        key: const ValueKey('artist_play_button'),
                        onTap: onPlayTap,
                        borderRadius: BorderRadius.zero,
                        splashColor: AppColors.onAccent.withValues(alpha: 0.2),
                        child: SizedBox(
                          width: 40.0,
                          height: 40.0,
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 26.0,
                            color: AppColors.onAccent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

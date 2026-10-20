/// File: anima_artwork_image.dart
/// Description: Optimized artwork rendering widget fulfilling the Dual-Tier rules (Section 6.2).
/// Implements Frame 0 instantaneous painting, strict ImageCache bounds (cacheWidth/cacheHeight: 100),
/// zero-cost graceful placeholder, and reactive updates without screen-wide rebuilds.
///
/// Components / Classes / Functions:
/// - AnimaArtworkImage: Stateless reactive widget rendering thumbnails or full covers.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';

/// Reusable artwork image widget enforcing Dual-Tier memory constraints and Frame 0 rendering.
class AnimaArtworkImage extends StatelessWidget {
  /// Unique identifier of the audio track (MediaStore ID).
  final int mediaStoreId;

  /// Optional album ID used as fallback identifier for shared album art.
  final int? albumId;

  /// Target display width.
  final double? width;

  /// Target display height.
  final double? height;

  /// Corner radius for rounded artwork cards. Defaults to 8.0.
  final double borderRadius;

  /// Whether to render as a perfect circle (Spotify artist avatar style).
  final bool isCircular;

  /// Custom icon used for the fallback container (e.g. person, album, or music note).
  final IconData? fallbackIcon;

  /// Whether to display the 100x100 thumbnail or the 800x800 full cover.
  final bool isThumbnail;

  /// How the image should be inscribed into the box. Defaults to [BoxFit.cover].
  final BoxFit fit;

  /// Custom fallback widget when no artwork is available.
  final Widget? fallback;

  const AnimaArtworkImage({
    super.key,
    required this.mediaStoreId,
    this.albumId,
    this.width = 48.0,
    this.height = 48.0,
    this.borderRadius = 8.0,
    this.isCircular = false,
    this.fallbackIcon,
    this.isThumbnail = true,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ArtworkService.instance,
      builder: (context, _) {
        final coverPath = ArtworkService.instance.getCoverPath(mediaStoreId, albumId: albumId);
        final thumbPath = ArtworkService.instance.getThumbnailPath(mediaStoreId, albumId: albumId);

        // Prioritize full high-resolution cover when not in thumbnail mode
        // or whenever widget dimensions exceed compact list tiles (> 64dp).
        final bool preferCover = !isThumbnail || ((width ?? 48.0) > 64.0);
        final String? path = preferCover
            ? (coverPath ?? thumbPath)
            : (thumbPath ?? coverPath);

        if (path != null) {
          final file = File(path);
          final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.5;
          final int cacheSize = preferCover
              ? (width != null ? (width! * dpr).round().clamp(240, 800) : 800)
              : (width != null ? (width! * dpr).round().clamp(100, 240) : 150);

          final imageWidget = Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            filterQuality: FilterQuality.medium,
            cacheWidth: cacheSize,
            cacheHeight: cacheSize,
            errorBuilder: (ctx, err, stack) => _buildFallback(context),
          );

          if (isCircular) {
            return ClipOval(child: imageWidget);
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: imageWidget,
          );
        }

        return _buildFallback(context);
      },
    );
  }

  Widget _buildFallback(BuildContext context) {
    if (fallback != null) return fallback!;

    final theme = Theme.of(context);
    final iconSize = ((width ?? 48.0) * 0.45).clamp(16.0, 64.0);
    final icon = fallbackIcon ?? Icons.music_note_rounded;

    final containerChild = Center(
      child: Icon(
        icon,
        size: iconSize,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );

    if (isCircular) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
        child: containerChild,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
        child: containerChild,
      ),
    );
  }
}

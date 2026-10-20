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
    this.isThumbnail = true,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ArtworkService.instance,
      builder: (context, _) {
        final path = isThumbnail
            ? ArtworkService.instance.getThumbnailPath(mediaStoreId, albumId: albumId)
            : ArtworkService.instance.getCoverPath(mediaStoreId, albumId: albumId);

        if (path != null) {
          final file = File(path);
          if (file.existsSync()) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image.file(
                file,
                width: width,
                height: height,
                fit: fit,
                // Crucial Rule 6.2.2: Prevent PaintingBinding.imageCache overflow
                cacheWidth: isThumbnail ? 100 : 800,
                cacheHeight: isThumbnail ? 100 : 800,
                errorBuilder: (ctx, err, stack) => _buildFallback(context),
              ),
            );
          }
        }

        return _buildFallback(context);
      },
    );
  }

  Widget _buildFallback(BuildContext context) {
    if (fallback != null) return fallback!;

    final theme = Theme.of(context);
    final iconSize = ((width ?? 48.0) * 0.45).clamp(16.0, 64.0);

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
        child: Center(
          child: Icon(
            Icons.music_note_rounded,
            size: iconSize,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

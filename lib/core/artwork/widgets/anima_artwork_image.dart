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

  /// Optional album name to resolve artwork if mediaStoreId has not yet been extracted.
  final String? albumName;

  /// Optional artist name to resolve artwork if mediaStoreId has not yet been extracted.
  final String? artistName;

  /// How the image should be inscribed into the box. Defaults to [BoxFit.cover].
  final BoxFit fit;

  /// Custom fallback widget when no artwork is available.
  final Widget? fallback;

  const AnimaArtworkImage({
    super.key,
    required this.mediaStoreId,
    this.albumId,
    this.albumName,
    this.artistName,
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
        var coverPath = ArtworkService.instance.getCoverPath(
          mediaStoreId,
          albumId: albumId,
          album: albumName,
          artist: artistName,
        );
        var thumbPath = ArtworkService.instance.getThumbnailPath(
          mediaStoreId,
          albumId: albumId,
          album: albumName,
          artist: artistName,
        );

        // Fallback to album name & artist lookup if representative ID has no cover yet
        if ((coverPath == null || thumbPath == null) &&
            albumName != null &&
            artistName != null) {
          coverPath ??= ArtworkService.instance.getCoverForAlbum(albumName!, artistName!);
          thumbPath ??= ArtworkService.instance.getThumbnailForAlbum(albumName!, artistName!);
        }

        // Prioritize full high-resolution cover when not in thumbnail mode
        // or whenever widget dimensions exceed compact list tiles (> 64dp).
        final bool hasFiniteWidth = width != null && width!.isFinite;
        final bool preferCover =
            !isThumbnail || (hasFiniteWidth ? (width! > 64.0) : true);
        final String? path = preferCover
            ? (coverPath ?? thumbPath)
            : (thumbPath ?? coverPath);

        if (path != null) {
          final file = File(path);
          final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.5;
          final int cacheSize = preferCover
              ? (hasFiniteWidth ? (width! * dpr).round().clamp(200, 500) : 450)
              : (hasFiniteWidth ? (width! * dpr).round().clamp(100, 200) : 150);

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

          if (borderRadius > 0.0) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: imageWidget,
            );
          }

          return imageWidget;
        }

        return _buildFallback(context);
      },
    );
  }

  Widget _buildFallback(BuildContext context) {
    if (fallback != null) return fallback!;

    final theme = Theme.of(context);
    final double effectiveWidth =
        (width != null && width!.isFinite) ? width! : 48.0;
    final iconSize = (effectiveWidth * 0.45).clamp(16.0, 64.0);
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

    final decoration = BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius:
          borderRadius > 0.0 ? BorderRadius.circular(borderRadius) : null,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.05),
        width: 0.5,
      ),
    );

    if (borderRadius > 0.0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: width,
          height: height,
          decoration: decoration,
          child: containerChild,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: decoration,
      child: containerChild,
    );
  }
}

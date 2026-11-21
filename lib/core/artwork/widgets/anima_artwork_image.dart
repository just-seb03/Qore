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

  /// Computes the exact integer decode dimension used in Flutter's [ImageCache]
  /// so `Image.file` and `precacheImage` share identical cache keys.
  static int resolveCacheSize({
    double? width,
    bool isThumbnail = true,
    double? screenWidth,
    double? devicePixelRatio,
  }) {
    final bool hasFiniteWidth = width != null && width.isFinite;
    final bool preferCover = !isThumbnail;
    final double dpr = devicePixelRatio ?? 3.0;

    if (preferCover) {
      if (hasFiniteWidth) {
        if (width <= 300.0) {
          return (width * dpr).round().clamp(360, 640);
        } else {
          return (width * dpr).round().clamp(720, 1200);
        }
      } else {
        final double effectiveScreenWidth = screenWidth ?? 400.0;
        return (effectiveScreenWidth * 0.5 * dpr).round().clamp(360, 640);
      }
    } else {
      final double baseWidth = hasFiniteWidth ? width : 48.0;
      return (baseWidth * dpr).round().clamp(120, 240);
    }
  }

  /// Resolves the cached on-disk artwork file path for a track/album, if available.
  static String? resolveArtworkPath({
    required int mediaStoreId,
    int? albumId,
    String? albumName,
    String? artistName,
    bool isThumbnail = true,
  }) {
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

    if ((coverPath == null || thumbPath == null) &&
        albumName != null &&
        artistName != null) {
      coverPath ??= ArtworkService.instance.getCoverForAlbum(albumName, artistName);
      thumbPath ??= ArtworkService.instance.getThumbnailForAlbum(albumName, artistName);
    }

    return isThumbnail ? (thumbPath ?? coverPath) : (coverPath ?? thumbPath);
  }

  /// Builds the exact [ResizeImage] provider matching [AnimaArtworkImage] rendering.
  static ImageProvider<Object>? resolveImageProvider({
    required int mediaStoreId,
    int? albumId,
    String? albumName,
    String? artistName,
    double? width,
    bool isThumbnail = true,
    double? screenWidth,
    double? devicePixelRatio,
  }) {
    final path = resolveArtworkPath(
      mediaStoreId: mediaStoreId,
      albumId: albumId,
      albumName: albumName,
      artistName: artistName,
      isThumbnail: isThumbnail,
    );
    if (path == null) return null;

    final int cacheSize = resolveCacheSize(
      width: width,
      isThumbnail: isThumbnail,
      screenWidth: screenWidth,
      devicePixelRatio: devicePixelRatio,
    );

    return ResizeImage(
      FileImage(File(path)),
      width: cacheSize,
      height: cacheSize,
    );
  }

  /// Pre-decodes a track/album artwork into Flutter's [ImageCache] so transitions
  /// render on Frame 0 without blank gaps.
  static Future<void> precacheSongArtwork(
    BuildContext context, {
    required int mediaStoreId,
    int? albumId,
    String? albumName,
    String? artistName,
    double? width,
    bool isThumbnail = false,
  }) async {
    final provider = resolveImageProvider(
      mediaStoreId: mediaStoreId,
      albumId: albumId,
      albumName: albumName,
      artistName: artistName,
      width: width,
      isThumbnail: isThumbnail,
      screenWidth: MediaQuery.maybeSizeOf(context)?.width,
      devicePixelRatio: MediaQuery.maybeDevicePixelRatioOf(context),
    );
    if (provider == null) return;
    try {
      await precacheImage(provider, context);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ArtworkService.instance,
      builder: (context, _) {
        final String? path = resolveArtworkPath(
          mediaStoreId: mediaStoreId,
          albumId: albumId,
          albumName: albumName,
          artistName: artistName,
          isThumbnail: isThumbnail,
        );

        if (path != null) {
          final file = File(path);
          final int cacheSize = resolveCacheSize(
            width: width,
            isThumbnail: isThumbnail,
            screenWidth: MediaQuery.maybeSizeOf(context)?.width,
            devicePixelRatio: MediaQuery.maybeDevicePixelRatioOf(context),
          );

          final imageWidget = Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            gaplessPlayback: true,
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

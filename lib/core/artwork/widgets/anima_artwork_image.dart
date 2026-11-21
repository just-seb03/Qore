/// File: anima_artwork_image.dart
/// Description: Optimized artwork rendering widget fulfilling the Dual-Tier rules (Section 6.2).
/// Implements Frame 0 instantaneous painting, strict ImageCache bounds (cacheWidth/cacheHeight: 100),
/// zero-cost graceful placeholder, and reactive updates without screen-wide rebuilds.
///
/// Components / Classes / Functions:
/// - AnimaArtworkImage: Stateful reactive widget rendering thumbnails or full covers.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';

/// Reusable artwork image widget enforcing Dual-Tier memory constraints and Frame 0 rendering.
class AnimaArtworkImage extends StatefulWidget {
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
  State<AnimaArtworkImage> createState() => _AnimaArtworkImageState();
}

class _AnimaArtworkImageState extends State<AnimaArtworkImage> {
  String? _resolvedPath;
  bool _isListening = false;

  String? _resolvePath() {
    return AnimaArtworkImage.resolveArtworkPath(
      mediaStoreId: widget.mediaStoreId,
      albumId: widget.albumId,
      albumName: widget.albumName,
      artistName: widget.artistName,
      isThumbnail: widget.isThumbnail,
    );
  }

  void _subscribe() {
    if (_isListening) return;
    _isListening = true;
    ArtworkService.instance.addListener(_onArtworkUpdated);
  }

  void _unsubscribe() {
    if (!_isListening) return;
    _isListening = false;
    ArtworkService.instance.removeListener(_onArtworkUpdated);
  }

  void _syncListener() {
    if (_resolvedPath == null) {
      _subscribe();
    } else {
      _unsubscribe();
    }
  }

  void _onArtworkUpdated() {
    if (!mounted) return;
    final String? nextPath = _resolvePath();
    if (nextPath != null && nextPath != _resolvedPath) {
      _unsubscribe();
      setState(() {
        _resolvedPath = nextPath;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _resolvedPath = _resolvePath();
    _syncListener();
  }

  @override
  void didUpdateWidget(covariant AnimaArtworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mediaStoreId != oldWidget.mediaStoreId ||
        widget.albumId != oldWidget.albumId ||
        widget.albumName != oldWidget.albumName ||
        widget.artistName != oldWidget.artistName ||
        widget.isThumbnail != oldWidget.isThumbnail) {
      _resolvedPath = _resolvePath();
      _syncListener();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? path = _resolvedPath;
    if (path == null) {
      return _buildFallback(context);
    }

    final int cacheSize = AnimaArtworkImage.resolveCacheSize(
      width: widget.width,
      isThumbnail: widget.isThumbnail,
      screenWidth: MediaQuery.maybeSizeOf(context)?.width,
      devicePixelRatio: MediaQuery.maybeDevicePixelRatioOf(context),
    );

    final imageWidget = Image.file(
      File(path),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      cacheWidth: cacheSize,
      cacheHeight: cacheSize,
      errorBuilder: (_, _, _) => _buildFallback(context),
    );

    if (widget.isCircular) {
      return ClipOval(child: imageWidget);
    }

    if (widget.borderRadius > 0.0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildFallback(BuildContext context) {
    if (widget.fallback != null) return widget.fallback!;

    final theme = Theme.of(context);
    final double effectiveWidth =
        (widget.width != null && widget.width!.isFinite) ? widget.width! : 48.0;
    final iconSize = (effectiveWidth * 0.45).clamp(16.0, 64.0);
    final icon = widget.fallbackIcon ?? Icons.music_note_rounded;

    final containerChild = Center(
      child: Icon(
        icon,
        size: iconSize,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );

    if (widget.isCircular) {
      return Container(
        width: widget.width,
        height: widget.height,
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
      borderRadius: widget.borderRadius > 0.0
          ? BorderRadius.circular(widget.borderRadius)
          : null,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.05),
        width: 0.5,
      ),
    );

    if (widget.borderRadius > 0.0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: decoration,
          child: containerChild,
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: decoration,
      child: containerChild,
    );
  }
}

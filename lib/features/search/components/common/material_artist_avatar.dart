/// File: material_artist_avatar.dart
/// Description: Native Material Design circular avatar used for Artist representation.
/// Complies with the project-wide constraint that artists do NOT display album covers,
/// but instead use a clean, futuristic circular avatar with an icon silhouette.
///
/// Components / Classes / Functions:
/// - MaterialArtistAvatar: Reusable circular avatar widget for artists.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Reusable circular Material Design avatar for artists.
/// Dynamically renders custom artist photos persisted in [ArtworkService],
/// falling back to the native Material silhouette icon.
class MaterialArtistAvatar extends StatelessWidget {
  /// Radius of the avatar circle.
  final double radius;

  /// Background color of the avatar. Defaults to dynamic [AppColors.surfaceContainerHigh].
  final Color? backgroundColor;

  /// Foreground icon color. Defaults to dynamic [AppColors.onSurfaceVariant].
  final Color? iconColor;

  /// Optional custom icon. Defaults to [Icons.person_rounded].
  final IconData icon;

  /// Artist name used to query persistent custom artwork.
  final String? artistName;

  /// Optional direct file path to custom avatar image.
  final String? customImagePath;

  const MaterialArtistAvatar({
    super.key,
    this.radius = 24.0,
    this.backgroundColor,
    this.iconColor,
    this.icon = Icons.person_rounded,
    this.artistName,
    this.customImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.surfaceContainerHigh;
    final effectiveIconColor = iconColor ?? AppColors.onSurfaceVariant;
    final size = radius * 2;

    return ListenableBuilder(
      listenable: ArtworkService.instance,
      builder: (context, _) {
        final directPath = customImagePath != null && File(customImagePath!).existsSync()
            ? customImagePath
            : null;
        final customPath = directPath ??
            ArtworkService.instance.getCustomArtistSquarePhoto(artistName) ??
            ArtworkService.instance.getCustomArtistAvatar(artistName);

        if (customPath != null && File(customPath).existsSync()) {
          final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.5;
          final int pixelSize = (size * dpr).round().clamp(64, 400);

          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: effectiveBg,
              borderRadius: BorderRadius.zero,
            ),
            clipBehavior: Clip.hardEdge,
            child: Image(
              image: ResizeImage(
                FileImage(File(customPath)),
                width: pixelSize,
                height: pixelSize,
                policy: ResizeImagePolicy.fit,
              ),
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          );
        }

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.zero,
          ),
          child: Center(
            child: Icon(
              icon,
              size: radius * 1.15,
              color: effectiveIconColor,
            ),
          ),
        );
      },
    );
  }
}

/// File: metro_artist_tile.dart
/// Description: Windows Phone Metro square live tile for a pinned Artist.
/// Displays square full-bleed artist photo with bottom typography scrim, large bold artist name,
/// sharp 90-degree corners, zero shadows, and horizontal 3D flip with frosted glass back.
///
/// Components / Classes / Functions:
/// - MetroArtistTile: Square live tile presenting a pinned artist with horizontal flip.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';
import 'package:project_anima/features/home/components/metro_live_tile.dart';
import 'package:project_anima/features/home/components/tiles/metro_tile_glass_back.dart';

/// Square Windows Phone Metro live tile for a pinned artist.
class MetroArtistTile extends StatelessWidget {
  /// The pinned artist entity.
  final PinnedFavorite artist;

  /// Staggered initial delay for the flip animation.
  final Duration initialDelay;

  /// Optional external flip coordinator trigger.
  final ValueListenable<int?>? flipTrigger;

  /// Optional tile slot matched against [flipTrigger].
  final int? flipSlot;

  /// Optional tap callback.
  final VoidCallback? onTap;

  /// Optional long press callback.
  final VoidCallback? onLongPress;

  const MetroArtistTile({
    super.key,
    required this.artist,
    this.initialDelay = const Duration(seconds: 40),
    this.flipTrigger,
    this.flipSlot,
    this.onTap,
    this.onLongPress,
  });

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    Navigator.of(context).push(
      ArtistDetailScreen.route(artist.title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: MetroLiveTile(
        flipAxis: MetroFlipAxis.horizontal,
        initialDelay: initialDelay,
        interval: const Duration(seconds: 75),
        flipTrigger: flipTrigger,
        flipSlot: flipSlot,
        onTap: () => _handleTap(context),
        onLongPress: onLongPress,
        front: _buildFront(context),
        back: MetroTileGlassBack(
          icon: Icons.person_rounded,
          label: Localizations.localeOf(context).languageCode == 'es'
              ? 'ARTISTA'
              : 'ARTIST',
        ),
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    return ListenableBuilder(
      listenable: ArtworkService.instance,
      builder: (context, _) {
        final directPath = (artist.coverPath != null && artist.coverPath!.isNotEmpty)
            ? artist.coverPath
            : null;
        final photoPath = directPath ??
            ArtworkService.instance.getCustomArtistSquarePhoto(artist.title);

        final bool hasPhoto = photoPath != null && photoPath.isNotEmpty;

        Widget buildSilhouette() => Center(
              child: Icon(
                Icons.person_rounded,
                size: 72.0,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            );

        return Container(
          color: AppColors.surfaceContainerHigh,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Square Artist Photo or Native Silhouette
              if (hasPhoto)
                Image.file(
                  File(photoPath),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => buildSilhouette(),
                )
              else
                buildSilhouette(),

              // 2. Bottom gradient scrim with prominent bold artist name
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: hasPhoto
                          ? const [
                              Colors.black87,
                              Colors.transparent,
                            ]
                          : [
                              Colors.black45,
                              Colors.transparent,
                            ],
                    ),
                  ),
                  child: Text(
                    artist.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.segoe(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// File: metro_album_tile.dart
/// Description: Windows Phone Metro square live tile for a pinned Album.
/// Full-bleed square album artwork with bottom typography scrim, sharp 90-degree corners,
/// zero shadows, zero padding, and horizontal 3D perspective flip revealing the Album icon.
///
/// Components / Classes / Functions:
/// - MetroAlbumTile: Square live tile presenting a pinned album with horizontal flip.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';
import 'package:project_anima/features/home/components/metro_live_tile.dart';
import 'package:project_anima/features/home/components/tiles/metro_tile_glass_back.dart';

/// Square Windows Phone Metro live tile for a pinned album.
class MetroAlbumTile extends StatelessWidget {
  /// The pinned album entity.
  final PinnedFavorite album;

  /// Staggered initial delay for the flip animation.
  final Duration initialDelay;

  /// Optional external flip coordinator trigger.
  final ValueListenable<int?>? flipTrigger;

  /// Optional tile slot matched against [flipTrigger].
  final int? flipSlot;

  /// Optional tap callback override.
  final VoidCallback? onTap;

  /// Optional long press callback (e.g. unpin).
  final VoidCallback? onLongPress;

  const MetroAlbumTile({
    super.key,
    required this.album,
    this.initialDelay = const Duration(seconds: 30),
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
      AlbumDetailScreen.route(
        albumName: album.title,
        artistName: album.subtitle,
        albumId: album.albumId,
        representativeSongId: album.representativeSongId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: MetroLiveTile(
        flipAxis: MetroFlipAxis.horizontal,
        initialDelay: initialDelay,
        interval: const Duration(seconds: 68),
        flipTrigger: flipTrigger,
        flipSlot: flipSlot,
        onTap: () => _handleTap(context),
        onLongPress: onLongPress,
        front: _buildFront(context),
        back: MetroTileGlassBack(
          icon: Icons.album_rounded,
          label: Localizations.localeOf(context).languageCode == 'es'
              ? 'ÁLBUM'
              : 'ALBUM',
        ),
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed HD artwork with 0 border radius
          AnimaArtworkImage(
            mediaStoreId: album.representativeSongId ?? 0,
            albumId: album.albumId,
            albumName: album.title,
            artistName: album.subtitle,
            width: double.infinity,
            height: double.infinity,
            borderRadius: 0.0,
            fallbackIcon: Icons.album_rounded,
            isThumbnail: false,
            fit: BoxFit.cover,
          ),

          // Bottom gradient scrim with title & artist
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black87,
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    album.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.segoe(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  if (album.subtitle != null && album.subtitle!.isNotEmpty)
                    Text(
                      album.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.segoe(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// File: metro_artist_tile.dart
/// Description: Windows Phone Metro square live tile for a pinned Artist.
/// Displays circular avatar with artist photo and name inside the square tile container,
/// sharp 90-degree corners, zero shadows, and horizontal 3D flip revealing the Artist icon.
///
/// Components / Classes / Functions:
/// - MetroArtistTile: Square live tile presenting a pinned artist with horizontal flip.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';
import 'package:project_anima/features/home/components/metro_live_tile.dart';

/// Square Windows Phone Metro live tile for a pinned artist.
class MetroArtistTile extends StatelessWidget {
  /// The pinned artist entity.
  final PinnedFavorite artist;

  /// Staggered initial delay for the flip animation.
  final Duration initialDelay;

  /// Optional tap callback.
  final VoidCallback? onTap;

  /// Optional long press callback.
  final VoidCallback? onLongPress;

  const MetroArtistTile({
    super.key,
    required this.artist,
    this.initialDelay = const Duration(seconds: 5),
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
        interval: const Duration(seconds: 15),
        onTap: () => _handleTap(context),
        onLongPress: onLongPress,
        front: _buildFront(context),
        back: _buildBack(context),
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular avatar inside the square cover tile
          AnimaArtworkImage(
            mediaStoreId: artist.representativeSongId ?? 0,
            albumId: artist.albumId,
            artistName: artist.title,
            isCircular: true,
            width: 82.0,
            height: 82.0,
            borderRadius: 41.0,
            fallbackIcon: Icons.person_rounded,
            isThumbnail: true,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 10.0),

          // Artist name inside the square cover tile
          Text(
            artist.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inconsolata(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_rounded,
              size: 48.0,
              color: AppColors.accent,
            ),
            const SizedBox(height: 8.0),
            Text(
              'ARTISTA',
              style: GoogleFonts.inconsolata(
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

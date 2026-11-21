/// File: metro_favorites_tile.dart
/// Description: Windows Phone Metro live tile for Favorited Songs placed at the top-left of Space.
/// Features a large filled heart icon in the theme's active accent color, zero shadows, sharp
/// 90-degree corners, and horizontal 3D flip animation.
///
/// Components / Classes / Functions:
/// - MetroFavoritesTile: Square live tile presenting favorites with horizontal flip.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/home/components/metro_live_tile.dart';
import 'package:project_anima/features/home/components/tiles/metro_tile_glass_back.dart';
import 'package:project_anima/features/playlist/screens/playlist_detail_screen.dart';

/// Square Windows Phone Metro live tile for Favorite Songs.
class MetroFavoritesTile extends StatelessWidget {
  /// Staggered initial delay for the flip animation.
  final Duration initialDelay;

  /// Optional external flip coordinator trigger.
  final ValueListenable<int?>? flipTrigger;

  /// Optional tile slot matched against [flipTrigger].
  final int? flipSlot;

  /// Optional pre-loaded favorite songs for testing.
  final List<Song>? initialSongs;

  const MetroFavoritesTile({
    super.key,
    this.initialDelay = const Duration(seconds: 16),
    this.flipTrigger,
    this.flipSlot,
    this.initialSongs,
  });

  void _handleTap(BuildContext context) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final favoritesPlaylist = Playlist(
      id: PlaylistDetailScreen.favoritesPlaylistId,
      name: "Favorites",
      createdAt: nowMs,
      updatedAt: nowMs,
      firstMediaStoreId:
          initialSongs != null && initialSongs!.isNotEmpty ? initialSongs!.first.mediaStoreId : null,
    );

    Navigator.of(context).push(
      PlaylistDetailScreen.route(
        playlist: favoritesPlaylist,
        initialSongs: initialSongs,
        isEditable: false,
        showHeroCover: false,
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
        interval: const Duration(seconds: 55),
        flipTrigger: flipTrigger,
        flipSlot: flipSlot,
        onTap: () => _handleTap(context),
        front: _buildFront(context),
        back: const MetroTileGlassBack(
          icon: Icons.favorite_rounded,
          label: 'CANCIONES',
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
          // Centered large filled heart with active theme accent color
          Center(
            child: Icon(
              Icons.favorite_rounded,
              size: 64.0,
              color: AppColors.accent,
            ),
          ),

          // Bottom label
          Positioned(
            left: 12.0,
            right: 12.0,
            bottom: 10.0,
            child: Text(
              'FAVORITOS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.segoe(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.4,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// File: metro_favorites_tile.dart
/// Description: Windows Phone Metro live tile for Favorited Songs placed at the top-left of Space.
/// Features a large filled heart icon in the theme's active accent color, zero shadows, sharp
/// 90-degree corners, and horizontal 3D flip animation.
///
/// Components / Classes / Functions:
/// - MetroFavoritesTile: Square live tile presenting favorites with horizontal flip.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/home/components/metro_live_tile.dart';
import 'package:project_anima/features/playlist/screens/playlist_detail_screen.dart';

/// Square Windows Phone Metro live tile for Favorite Songs.
class MetroFavoritesTile extends StatelessWidget {
  /// Staggered initial delay for the flip animation.
  final Duration initialDelay;

  /// Optional pre-loaded favorite songs for testing.
  final List<Song>? initialSongs;

  const MetroFavoritesTile({
    super.key,
    this.initialDelay = const Duration(seconds: 3),
    this.initialSongs,
  });

  Future<void> _handleTap(BuildContext context) async {
    final songs = initialSongs ?? await FavoriteSongsDao.instance.getAllFavorites();
    if (!context.mounted) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final favoritesPlaylist = Playlist(
      id: -2,
      name: "Favorites",
      createdAt: nowMs,
      updatedAt: nowMs,
      firstMediaStoreId: songs.isNotEmpty ? songs.first.mediaStoreId : null,
    );

    Navigator.of(context).push(
      PlaylistDetailScreen.route(
        playlist: favoritesPlaylist,
        initialSongs: songs,
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
        interval: const Duration(seconds: 13),
        onTap: () => _handleTap(context),
        front: _buildFront(context),
        back: _buildBack(context),
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
              style: GoogleFonts.inconsolata(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: AppColors.onSurface,
              ),
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
              Icons.favorite_rounded,
              size: 48.0,
              color: AppColors.accent,
            ),
            const SizedBox(height: 8.0),
            Text(
              'CANCIONES',
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

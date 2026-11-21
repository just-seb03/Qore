/// File: home_favorites_hero_card.dart
/// Description: Hero banner card widget for 'Favorites' playlist on Home screen.
/// Positioned below 'Today Selection' and above pinned user items.
/// Features a 1920x620 aspect ratio, multi-cover horizontal collage of favorited tracks,
/// cinematic gradient overlay, 'Favorites' Outfit title, and responsive Play/Pause toggle button.
///
/// Components / Classes / Functions:
/// - HomeFavoritesHeroCard: Stateful/stateless hero banner card for user favorite songs.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/playlist/screens/playlist_detail_screen.dart';

/// Hero banner card widget rendering 'Favorites' on the Home screen.
class HomeFavoritesHeroCard extends StatelessWidget {
  /// All user favorited songs.
  final List<Song> songs;

  /// Optional custom onPlay callback.
  final VoidCallback? onPlayTap;

  const HomeFavoritesHeroCard({
    super.key,
    required this.songs,
    this.onPlayTap,
  });

  static const int _kFavoritesPlaylistId = PlaylistDetailScreen.favoritesPlaylistId;

  static final TextStyle _titleStyle = AppFonts.segoe(
    fontSize: 22.0,
    fontWeight: FontWeight.w800,
    color: AppColors.futuristicWhite,
    letterSpacing: -0.4,
    shadows: const [
      Shadow(
        color: Colors.black87,
        blurRadius: 8.0,
        offset: Offset(0, 2),
      ),
    ],
  );

  void _handleOpen(BuildContext context) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final favoritesPlaylist = Playlist(
      id: _kFavoritesPlaylistId,
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

  List<Song> _getCollageSongs() {
    if (songs.isEmpty) return const [];
    final seen = <int>{};
    final result = <Song>[];
    for (final song in songs) {
      final key = song.albumId ?? song.mediaStoreId;
      if (!seen.contains(key)) {
        seen.add(key);
        result.add(song);
        if (result.length == 4) break;
      }
    }
    if (result.length < 4 && songs.length >= 4) {
      for (final song in songs) {
        if (!result.contains(song)) {
          result.add(song);
          if (result.length == 4) break;
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final collageSongs = _getCollageSongs();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 135.0),
        child: AspectRatio(
          aspectRatio: 1920 / 620,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 24.0,
                  spreadRadius: 2.0,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8.0,
                  offset: const Offset(0, 3),
                ),
              ],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleOpen(context),
                  splashColor: Colors.white.withValues(alpha: 0.08),
                  highlightColor: Colors.white.withValues(alpha: 0.04),
                  child: Stack(
                    children: [
                      // 1. Horizontal 4-Cover Collage Artwork or Subtle Gradient
                      Positioned.fill(
                        child: _buildCollage(collageSongs),
                      ),

                      // 2. Cinematic Gradient Scrim (Dark on left for title legibility, subtle crimson undertone)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.90),
                                Colors.black.withValues(alpha: 0.65),
                                Colors.black.withValues(alpha: 0.35),
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              stops: const [0.0, 0.45, 0.75, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // 3. Information Overlay (Centered along Y axis)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              context.l10n.home.favoritesHeroTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _titleStyle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollage(List<Song> collageSongs) {
    if (collageSongs.isEmpty) {
      return Container(
        color: AppColors.surfaceContainer,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: collageSongs.map((song) {
        return Expanded(
          child: AnimaArtworkImage(
            mediaStoreId: song.mediaStoreId,
            albumId: song.albumId,
            albumName: song.album,
            artistName: song.albumArtist ?? song.artist,
            borderRadius: 0.0,
            isThumbnail: false,
            fit: BoxFit.cover,
          ),
        );
      }).toList(),
    );
  }
}

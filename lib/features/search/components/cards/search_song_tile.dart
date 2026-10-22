/// File: search_song_tile.dart
/// Description: Spotify-styled song row tile displaying 48x48 artwork, title,
/// artist and album subtitle, formatted duration, and options action.
///
/// Components / Classes / Functions:
/// - SearchSongTile: Reusable Spotify-styled song row tile.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/components/liquid_track_gesture_wrapper.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/playback_controller.dart';

/// Reusable Spotify-styled song row item.
class SearchSongTile extends StatelessWidget {
  /// The song entity to display.
  final Song song;

  /// Callback when the tile is tapped.
  final VoidCallback? onTap;

  /// Optional callback for the trailing options icon.
  final VoidCallback? onOptionsTap;

  const SearchSongTile({
    super.key,
    required this.song,
    this.onTap,
    this.onOptionsTap,
  });

  static final TextStyle _titleStyle = GoogleFonts.inconsolata(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static final TextStyle _artistAlbumStyle = GoogleFonts.inconsolata(
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFB3B3B3),
  );

  static final TextStyle _durationStyle = GoogleFonts.inconsolata(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFB3B3B3),
  );

  String _formatDuration(int ms) {
    final int totalSeconds = ms ~/ 1000;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoriteSongsDao.instance.favoritesRevision,
      builder: (context, _) {
        final isFav = FavoriteSongsDao.instance.isFavorite(song.mediaStoreId);

        return LiquidTrackGestureWrapper(
          song: song,
          onTap: onTap,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: const Color(0xFF282828),
              highlightColor: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    // 48x48 Spotify-style square thumbnail
                    AnimaArtworkImage(
                      mediaStoreId: song.mediaStoreId,
                      albumId: song.albumId,
                      width: 48.0,
                      height: 48.0,
                      borderRadius: 4.0,
                      isThumbnail: true,
                    ),
                    const SizedBox(width: 14.0),
                    // Title and Artist/Album
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _titleStyle,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '${song.artist != null && song.artist!.isNotEmpty && song.artist != "<Desconocido>" ? song.artist : "Unknown Artist"} • ${song.album != null && song.album!.isNotEmpty && song.album != "<Desconocido>" ? song.album : "Unknown Album"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _artistAlbumStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    // Favorite Heart Indicator
                    if (isFav)
                      const Padding(
                        padding: EdgeInsets.only(right: 4.0),
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 14.0,
                          color: Colors.white,
                        ),
                      ),
                    // Add to queue icon
                    IconButton(
                      icon: const Icon(
                        Icons.playlist_add_rounded,
                        size: 20.0,
                        color: Color(0xFFB3B3B3),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28.0, minHeight: 28.0),
                      splashRadius: 16.0,
                      tooltip: 'Añadir a la cola',
                      onPressed: () {
                        PlaybackController.instance.addToQueue(song);
                        HapticFeedback.lightImpact();
                      },
                    ),
                    const SizedBox(width: 4.0),
                    // Duration
                    Text(
                      _formatDuration(song.duration),
                      style: _durationStyle,
                    ),
                    const SizedBox(width: 8.0),
                    // Spotify more-options icon
                    IconButton(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 20.0,
                        color: Color(0xFFB3B3B3),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28.0, minHeight: 28.0),
                      splashRadius: 18.0,
                      onPressed: onOptionsTap,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

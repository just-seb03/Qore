/// File: artist_top_track_tile.dart
/// Description: Track tile component for Top 3 most listened artist songs,
/// rendering cover thumbnail, title, album, duration, and active play/pause indicators.
///
/// Components / Classes / Functions:
/// - ArtistTopTrackTile: Tile widget for individual featured artist tracks.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Track tile for Top 3 most listened songs (cover thumbnail, title, album, duration, no margin rank numbers).
class ArtistTopTrackTile extends StatelessWidget {
  /// The song represented by this tile.
  final Song song;

  /// Full queue of artist songs to enqueue when this track is played.
  final List<Song> allArtistSongs;

  const ArtistTopTrackTile({
    super.key,
    required this.song,
    required this.allArtistSongs,
  });

  String _formatDuration(int? ms) {
    if (ms == null || ms <= 0) return '';
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final activeController = PlaybackController.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([activeController, FavoriteSongsDao.instance.favoritesRevision]),
      builder: (context, _) {
        final isCurrentTrack =
            activeController.currentSong?.mediaStoreId == song.mediaStoreId;
        final isPlaying = isCurrentTrack && activeController.isPlaying;
        final isFav = FavoriteSongsDao.instance.isFavorite(song.mediaStoreId);
        final durationStr = _formatDuration(song.duration);

        void handleTap() {
          if (isCurrentTrack) {
            activeController.togglePlayPause();
          } else {
            activeController.playSong(song, queue: allArtistSongs);
          }
        }

        return Material(
          color: isCurrentTrack
              ? AppColors.surfaceContainerHigh.withValues(alpha: 0.6)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(14.0),
              onTap: handleTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Row(
                  children: [
                    // Artwork Thumbnail
                    AnimaArtworkImage(
                      mediaStoreId: song.mediaStoreId,
                      albumId: song.albumId,
                      width: 48.0,
                      height: 48.0,
                      borderRadius: 11.0,
                      isThumbnail: true,
                    ),
                    const SizedBox(width: 14.0),

                    // Song Title & Album Name (No play count, no margin numbers)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w600,
                              color: isCurrentTrack
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            song.album ?? 'Unknown Album',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inconsolata(
                              fontSize: 12.5,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Favorite Heart Button (Direct toggle without playing)
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 19.0,
                        color: isFav ? Colors.white : AppColors.onSurfaceVariant.withValues(alpha: 0.65),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30.0, minHeight: 30.0),
                      splashRadius: 16.0,
                      tooltip: isFav ? 'Quitar de favoritos' : 'Añadir a favoritos',
                      onPressed: () {
                        FavoriteSongsDao.instance.toggleFavorite(song);
                        HapticFeedback.lightImpact();
                      },
                    ),

                    // Add to Playback Queue Icon
                    IconButton(
                      icon: const Icon(
                        Icons.playlist_add_rounded,
                        size: 20.0,
                        color: AppColors.onSurfaceVariant,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30.0, minHeight: 30.0),
                      splashRadius: 16.0,
                      tooltip: 'Añadir a la cola',
                      onPressed: () {
                        activeController.addToQueue(song);
                        HapticFeedback.lightImpact();
                      },
                    ),

                    // Duration text
                    if (durationStr.isNotEmpty && !isCurrentTrack)
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                        child: Text(
                          durationStr,
                          style: GoogleFonts.inconsolata(
                            fontSize: 12.0,
                            color: AppColors.onSurfaceDisabled,
                          ),
                        ),
                      ),

                    // Active Play/Pause Indicator Icon
                    if (isCurrentTrack)
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, right: 2.0),
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22.0,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
}

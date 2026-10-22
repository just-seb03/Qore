/// File: playlist_track_tile.dart
/// Description: Clean track tile for playlist songs showing margin track index number,
/// song title, artist, duration, and active playback state highlighting without artwork cover.
///
/// Components / Classes / Functions:
/// - PlaylistTrackTile: Cohesive track row component for playlist tracklists.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/components/liquid_track_gesture_wrapper.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Clean track tile for playlist songs showing margin track index, title, artist, duration.
class PlaylistTrackTile extends StatelessWidget {
  /// The song represented by this tile.
  final Song song;

  /// 1-based sequential track index within the playlist.
  final int trackIndex;

  /// Full playlist queue for seamless sequential playback upon selection.
  final List<Song> allPlaylistSongs;

  /// Optional playlist ID for active playlist state tracking.
  final int? playlistId;

  const PlaylistTrackTile({
    super.key,
    required this.song,
    required this.trackIndex,
    required this.allPlaylistSongs,
    this.playlistId,
  });

  String _formatDuration(int? ms) {
    if (ms == null || ms <= 0) return '';
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get _displayTrackNumber {
    return trackIndex.toString().padLeft(2, '0');
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
            activeController.playSong(
              song,
              queue: allPlaylistSongs,
              playlistId: playlistId,
            );
          }
        }

        return LiquidTrackGestureWrapper(
          song: song,
          onTap: handleTap,
          child: Material(
            color: isCurrentTrack
                ? AppColors.surfaceContainerHigh.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(10.0),
              onTap: handleTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Row(
                  children: [
                    // 1. Margin Track Number (Aligned, Monospaced)
                    SizedBox(
                      width: 32.0,
                      child: isPlaying
                          ? const Icon(
                              Icons.equalizer_rounded,
                              size: 18.0,
                              color: Colors.white,
                            )
                          : Text(
                              _displayTrackNumber,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inconsolata(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: isCurrentTrack
                                    ? Colors.white
                                    : AppColors.onSurfaceVariant.withValues(alpha: 0.75),
                              ),
                            ),
                    ),
                    const SizedBox(width: 8.0),

                    // 2. Song Title & Artist (No cover)
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
                              fontWeight: isCurrentTrack ? FontWeight.w600 : FontWeight.w400,
                              color: isCurrentTrack ? Colors.white : const Color(0xFFEEEEEE),
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            song.artist ?? 'Unknown Artist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inconsolata(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. Favorite Heart Indicator
                    if (isFav)
                      const Padding(
                        padding: EdgeInsets.only(right: 4.0),
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 14.0,
                          color: Colors.white,
                        ),
                      ),

                    // 4. Add to Playback Queue Icon
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

                    // 5. Track Duration
                    if (durationStr.isNotEmpty) ...[
                      const SizedBox(width: 6.0),
                      Text(
                        durationStr,
                        style: GoogleFonts.inconsolata(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
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

/// File: artist_compact_track_tile.dart
/// Description: Compact track tile without covers, featuring clean typography and PlaybackController
/// integration for the artist assorted chronological songs list.
///
/// Components / Classes / Functions:
/// - ArtistCompactTrackTile: Compact tile widget for chronological songs.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/song_options_pill.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Compact track tile without covers, clean typography for the up to 5 assorted tracks list.
class ArtistCompactTrackTile extends StatelessWidget {
  /// Song represented by this tile.
  final Song song;

  /// Full queue of artist songs to enqueue when this track is played.
  final List<Song> allArtistSongs;

  const ArtistCompactTrackTile({
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
      listenable: activeController,
      builder: (context, _) {
        final isCurrentTrack =
            activeController.currentSong?.mediaStoreId == song.mediaStoreId;
        final isPlaying = isCurrentTrack && activeController.isPlaying;
        final durationStr = _formatDuration(song.duration);

        void handleTap() {
          SongOptionsPillCoordinator.instance.close();
          if (isCurrentTrack) {
            activeController.togglePlayPause();
          } else {
            activeController.playSong(song, queue: allArtistSongs);
          }
        }

        return Material(
          color: isCurrentTrack
              ? AppColors.surfaceContainerHigh.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(10.0),
              onTap: handleTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
                child: Row(
                  children: [
                    // Title & Album only (No cover)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.segoe(
                              fontSize: 14.0,
                              fontWeight: isCurrentTrack
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isCurrentTrack
                                  ? AppColors.accent
                                  : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 1.5),
                          Text(
                            song.album ?? 'Unknown Album',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.segoe(
                              fontSize: 11.5,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Track Options Pill (beside duration with 3-dots trigger)
                    SongOptionsPill(
                      song: song,
                      durationText: isCurrentTrack ? null : durationStr,
                    ),

                    // Active Play/Pause Indicator Icon
                    if (isCurrentTrack)
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AppColors.accent,
                          size: 20.0,
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

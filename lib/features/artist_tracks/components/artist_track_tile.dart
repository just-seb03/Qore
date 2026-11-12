/// File: artist_track_tile.dart
/// Description: Ultra-high performance track tile component for the Artist Tracks feature.
/// Features a strict fixed-height layout (64dp) for O(1) ListView virtualization,
/// isolated GPU RepaintBoundary boundaries, scoped local state listening for playback
/// and favorite events, and smooth monochromatic dark aesthetic styling.
///
/// Components / Classes / Functions:
/// - ArtistTrackTile: High-performance virtualized track row widget.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/song_options_pill.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Highly optimized track tile rendering artwork thumbnail, title, album, duration, and favorite toggle.
class ArtistTrackTile extends StatelessWidget {
  /// The song represented by this tile.
  final Song song;

  /// Full queue of artist songs to enqueue when this track is selected.
  final List<Song> allArtistSongs;

  /// Standard tile height matching the virtualized list itemExtent.
  static const double tileHeight = 64.0;

  const ArtistTrackTile({
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

    return RepaintBoundary(
      child: SizedBox(
        height: tileHeight,
        child: ListenableBuilder(
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
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  child: Row(
                    children: [
                      // 1. Artwork Thumbnail (48x48)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimaArtworkImage(
                            mediaStoreId: song.mediaStoreId,
                            albumId: song.albumId,
                            width: 48.0,
                            height: 48.0,
                            borderRadius: 0.0,
                            isThumbnail: true,
                          ),
                          if (isPlaying)
                            Container(
                              width: 48.0,
                              height: 48.0,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                              ),
                              child: Icon(
                                Icons.equalizer_rounded,
                                color: AppColors.accent,
                                size: 22.0,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14.0),

                      // 2. Title & Album Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.segoe(
                                fontSize: 14.5,
                                fontWeight: isCurrentTrack
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isCurrentTrack
                                    ? AppColors.accent
                                    : AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              song.album ?? context.l10n.common.unknownAlbum,
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
                      // 3. Track Options Pill (beside duration with 3-dots trigger)
                      SongOptionsPill(
                        song: song,
                        durationText: isCurrentTrack ? null : durationStr,
                      ),
                      if (isCurrentTrack)
                        SizedBox(
                          width: 36.0,
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
        ),
      ),
    );
  }
}

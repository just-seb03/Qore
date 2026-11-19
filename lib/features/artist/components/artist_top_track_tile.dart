/// File: artist_top_track_tile.dart
/// Description: Track tile component for Top 3 most listened artist songs,
/// rendering cover thumbnail, title, album, duration, and active play/pause indicators.
///
/// Components / Classes / Functions:
/// - ArtistTopTrackTile: Tile widget for individual featured artist tracks.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/song_options_pill.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/core/utils/duration_formatter.dart';

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
    return formatDurationMs(ms);
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
          borderRadius: BorderRadius.zero,
          child: InkWell(
            borderRadius: BorderRadius.zero,
            onTap: handleTap,
            splashColor: AppColors.accent.withValues(alpha: 0.15),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Row(
                children: [
                  // Artwork Thumbnail (sharp 90-degree corners)
                  AnimaArtworkImage(
                    mediaStoreId: song.mediaStoreId,
                    albumId: song.albumId,
                    width: 48.0,
                    height: 48.0,
                    borderRadius: 0.0,
                    isThumbnail: true,
                  ),
                  const SizedBox(width: 14.0),

                  // Song Title & Album Name in Segoe UI
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
                            fontSize: 15.0,
                            fontWeight: isCurrentTrack
                                ? FontWeight.w600
                                : FontWeight.w400,
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
                            fontSize: 12.5,
                            fontWeight: FontWeight.w300,
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
                        padding: const EdgeInsets.only(left: 4.0, right: 2.0),
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AppColors.accent,
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

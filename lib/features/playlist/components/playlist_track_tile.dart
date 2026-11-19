/// File: playlist_track_tile.dart
/// Description: Clean track tile for playlist songs showing margin track index number,
/// song title, artist, duration, and active playback state highlighting without artwork cover.
///
/// Components / Classes / Functions:
/// - PlaylistTrackTile: Cohesive track row component for playlist tracklists.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/song_options_pill.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/core/utils/duration_formatter.dart';

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
    return formatDurationMs(ms);
  }

  String get _displayTrackNumber {
    return trackIndex.toString().padLeft(2, '0');
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
            activeController.playSong(
              song,
              queue: allPlaylistSongs,
              playlistId: playlistId,
            );
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
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Row(
                  children: [
                    // 1. Margin Track Number (Aligned, Monospaced)
                    SizedBox(
                      width: 26.0,
                      child: isPlaying
                          ? Icon(
                              Icons.equalizer_rounded,
                              size: 17.0,
                              color: AppColors.accent,
                            )
                          : Text(
                              _displayTrackNumber,
                              textAlign: TextAlign.center,
                              style: AppFonts.segoe(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: isCurrentTrack
                                    ? AppColors.accent
                                    : AppColors.onSurfaceVariant.withValues(alpha: 0.75),
                              ),
                            ),
                    ),
                    const SizedBox(width: 8.0),

                    // 2. Song Cover Artwork (Sharp unrounded 90-degree corners in playlists)
                    AnimaArtworkImage(
                      mediaStoreId: song.mediaStoreId,
                      albumId: song.albumId,
                      width: 42.0,
                      height: 42.0,
                      borderRadius: 0.0,
                      fallbackIcon: Icons.music_note_rounded,
                      isThumbnail: true,
                    ),
                    const SizedBox(width: 10.0),

                    // 3. Song Title & Artist
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
                              fontWeight: isCurrentTrack ? FontWeight.w600 : FontWeight.w400,
                              color: isCurrentTrack ? AppColors.accent : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            song.artist ?? context.l10n.common.unknownArtist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.segoe(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6.0),

                    // 4. Options Pill with 3-dots trigger beside track duration
                    SongOptionsPill(
                      song: song,
                      durationText: durationStr,
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

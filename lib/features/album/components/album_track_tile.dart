/// File: album_track_tile.dart
/// Description: Clean track tile for album songs showing margin track index number,
/// song title, artist, duration, active playback state highlighting, without artwork cover.
///
/// Components / Classes / Functions:
/// - AlbumTrackTile: Cohesive track row component for album tracklists.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/components/song_options_pill.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Clean track tile for album songs showing margin track number, title, artist, duration.
class AlbumTrackTile extends StatelessWidget {
  /// The song represented by this tile.
  final Song song;

  /// 1-based sequential track index within the album.
  final int trackIndex;

  /// Full album queue for seamless sequential playback upon selection.
  final List<Song> allAlbumSongs;

  const AlbumTrackTile({
    super.key,
    required this.song,
    required this.trackIndex,
    required this.allAlbumSongs,
  });

  String _formatDuration(int? ms) {
    if (ms == null || ms <= 0) return '';
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get _displayTrackNumber {
    if (song.trackNumber != null && song.trackNumber! > 0) {
      final numInDisc = song.trackNumber! % 1000;
      return numInDisc.toString().padLeft(2, '0');
    }
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
          if (isCurrentTrack) {
            activeController.togglePlayPause();
          } else {
            activeController.playSong(song, queue: allAlbumSongs);
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
                      width: 32.0,
                      child: Text(
                        _displayTrackNumber,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inconsolata(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: isCurrentTrack
                              ? AppColors.accent
                              : AppColors.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),

                    // 2. Song Title & Artist (No cover!)
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
                            song.artist ?? context.l10n.common.unknownArtist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inconsolata(
                              fontSize: 12.0,
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

                    // 4. Active Play/Pause Indicator Icon
                    if (isCurrentTrack)
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, right: 2.0),
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AppColors.accent,
                          size: 21.0,
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

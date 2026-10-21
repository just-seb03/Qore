/// File: playlist_track_tile.dart
/// Description: Clean track tile for playlist songs showing margin track index number,
/// song title, artist, duration, and active playback state highlighting without artwork cover.
///
/// Components / Classes / Functions:
/// - PlaylistTrackTile: Cohesive track row component for playlist tracklists.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  const PlaylistTrackTile({
    super.key,
    required this.song,
    required this.trackIndex,
    required this.allPlaylistSongs,
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
      listenable: activeController,
      builder: (context, _) {
        final isCurrentTrack =
            activeController.currentSong?.mediaStoreId == song.mediaStoreId;
        final isPlaying = isCurrentTrack && activeController.isPlaying;
        final durationStr = _formatDuration(song.duration);

        return Material(
          color: isCurrentTrack
              ? AppColors.surfaceContainerHigh.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(10.0),
            onTap: () {
              if (isCurrentTrack) {
                activeController.togglePlayPause();
              } else {
                activeController.playSong(song, queue: allPlaylistSongs);
              }
            },
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

                  // 3. Track Duration
                  if (durationStr.isNotEmpty) ...[
                    const SizedBox(width: 12.0),
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
        );
      },
    );
  }
}

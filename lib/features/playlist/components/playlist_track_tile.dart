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
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
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
                      child: isPlaying
                          ? Icon(
                              Icons.equalizer_rounded,
                              size: 18.0,
                              color: AppColors.accent,
                            )
                          : Text(
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
                              color: isCurrentTrack ? AppColors.accent : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            song.artist ?? context.l10n.common.unknownArtist,
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

                    // 3. Favorite Heart Button (Direct toggle without playing)
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 19.0,
                        color: isFav ? AppColors.accent : AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30.0, minHeight: 30.0),
                      splashRadius: 16.0,
                      tooltip: isFav
                          ? context.l10n.common.removeFromFavorites
                          : context.l10n.common.addToFavorites,
                      onPressed: () {
                        FavoriteSongsDao.instance.toggleFavorite(song);
                        HapticFeedback.lightImpact();
                      },
                    ),

                    // 4. Add to Playback Queue Icon
                    IconButton(
                      icon: Icon(
                        Icons.playlist_add_rounded,
                        size: 20.0,
                        color: AppColors.onSurfaceVariant,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30.0, minHeight: 30.0),
                      splashRadius: 16.0,
                      tooltip: context.l10n.common.addToQueue,
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
          );
        },
      );
    }
}

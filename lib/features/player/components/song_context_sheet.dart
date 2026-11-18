/// File: song_context_sheet.dart
/// Description: Contextual bottom sheet displayed when tapping the song title in the expanded player.
/// Features three centered action icons (Add to Playlist, Favorite Heart toggle, Delete song)
/// followed by an audio metadata specification card displaying audio format, quality (kHz), and file size.
///
/// Components / Classes / Functions:
/// - SongContextSheet: Modal bottom sheet for song contextual actions.
/// - SongAudioInfo: Data holder extracting format, sample rate, and size from audio files.
library;

import 'dart:io';
import 'dart:ui';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/player/components/song_delete_dialog.dart';
import 'package:project_anima/features/player/components/song_playlist_picker_sheet.dart';

/// Audio metadata statistics extracted for a track.
class SongAudioInfo {
  final String format;
  final String quality;
  final String size;

  const SongAudioInfo({
    required this.format,
    required this.quality,
    required this.size,
  });

  /// Factory inspecting the song filesystem and tags to extract audio technical metrics.
  static SongAudioInfo fromSong(Song song) {
    // 1. Audio Format / Extension
    String ext = 'MP3';
    if (song.path.contains('.')) {
      final candidate = song.path.split('.').last.toUpperCase().trim();
      if (candidate.isNotEmpty && candidate.length <= 5) {
        ext = candidate;
      }
    }

    // 2. File Size
    int? bytes = song.size;
    if (bytes == null || bytes <= 0) {
      try {
        final f = File(song.path);
        if (f.existsSync()) {
          bytes = f.lengthSync();
        }
      } catch (_) {}
    }
    String sizeStr = '—';
    if (bytes != null && bytes > 0) {
      if (bytes < 1024 * 1024) {
        sizeStr = '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        sizeStr = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    }

    // 3. Audio Quality / kHz sample rate
    String qualityStr = '44.1 kHz';
    int? sampleRate;
    try {
      final f = File(song.path);
      if (f.existsSync()) {
        final metadata = readMetadata(f, getImage: false);
        sampleRate = metadata.sampleRate;
      }
    } catch (_) {}

    if (sampleRate != null && sampleRate > 0) {
      qualityStr = '${(sampleRate / 1000).toStringAsFixed(1)} kHz';
    }

    return SongAudioInfo(
      format: ext,
      quality: qualityStr,
      size: sizeStr,
    );
  }
}

/// Contextual bottom sheet presentation widget for the active song.
class SongContextSheet extends StatelessWidget {
  final Song song;
  final SongDao? songDao;
  final PlaylistDao? playlistDao;

  const SongContextSheet({
    super.key,
    required this.song,
    this.songDao,
    this.playlistDao,
  });

  /// Presents the contextual bottom sheet for the given track.
  static Future<void> show(
    BuildContext context, {
    required Song song,
    SongDao? songDao,
    PlaylistDao? playlistDao,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => SongContextSheet(
        song: song,
        songDao: songDao,
        playlistDao: playlistDao,
      ),
    );
  }

  Widget _buildActionButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
    Key? key,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: key,
          onPressed: onTap,
          icon: icon,
          iconSize: 28.0,
          splashRadius: 26.0,
          padding: const EdgeInsets.all(12.0),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(
                color: AppColors.outline.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6.0),
        Text(
          label,
          style: AppFonts.segoe(
            fontSize: 12.0,
            fontWeight: FontWeight.w400,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppFonts.segoe(
            fontSize: 11.0,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.4,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: AppFonts.segoe(
            fontSize: 15.0,
            fontWeight: FontWeight.w400,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioInfo = SongAudioInfo.fromSong(song);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
      child: Container(
        padding: const EdgeInsets.only(bottom: 24.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.96),
          borderRadius: BorderRadius.zero,
          border: Border(
            top: BorderSide(
              color: AppColors.accent,
              width: 2.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Universal Dismiss Chevron
            const SizedBox(height: 6.0),
            ModalDismissIndicator(
              onDismiss: () => Navigator.of(context).pop(),
              size: 32.0,
              color: AppColors.onSurfaceVariant,
              animate: false,
              padding: const EdgeInsets.symmetric(vertical: 6.0),
            ),

            // 2. Track Title & Artist header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
              child: Column(
                children: [
                  Text(
                    song.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.light(
                      fontSize: 21.0,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    song.artist ?? 'Artista desconocido',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.segoe(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w300,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // 3. Three Centered Action Buttons: Add to Playlist | Favorite | Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Button 1: Add to playlist
                _buildActionButton(
                  key: const ValueKey('context_add_to_playlist_button'),
                  icon: Icon(
                    Icons.playlist_add_rounded,
                    color: AppColors.onSurface,
                  ),
                  label: 'Playlist',
                  onTap: () {
                    Navigator.of(context).pop();
                    SongPlaylistPickerSheet.show(
                      context,
                      song: song,
                      playlistDao: playlistDao,
                    );
                  },
                ),
                const SizedBox(width: 24.0),

                // Button 2: Toggle favorite
                ListenableBuilder(
                  listenable: FavoriteSongsDao.instance.favoritesRevision,
                  builder: (context, _) {
                    final isFav = FavoriteSongsDao.instance.isFavorite(song.mediaStoreId);
                    return _buildActionButton(
                      key: const ValueKey('context_toggle_favorite_button'),
                      icon: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? AppColors.accent : AppColors.onSurface,
                      ),
                      label: isFav ? 'Favorito' : 'Favorito',
                      onTap: () {
                        FavoriteSongsDao.instance.toggleFavorite(song);
                        HapticFeedback.mediumImpact();
                      },
                    );
                  },
                ),
                const SizedBox(width: 24.0),

                // Button 3: Delete song
                _buildActionButton(
                  key: const ValueKey('context_delete_song_button'),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFFF5252),
                  ),
                  label: 'Eliminar',
                  onTap: () async {
                    final confirmed = await SongDeleteDialog.show(
                      context,
                      songTitle: song.title,
                    );

                    if (confirmed == true && context.mounted) {
                      final effectiveSongDao = songDao ?? SongDao();
                      await effectiveSongDao.deleteSong(song.mediaStoreId);

                      try {
                        final file = File(song.path);
                        if (file.existsSync()) {
                          await file.delete();
                        }
                      } catch (_) {}

                      if (PlaybackController.instance.currentSong?.mediaStoreId ==
                          song.mediaStoreId) {
                        await PlaybackController.instance.skipToNext();
                      }

                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Canción eliminada de la biblioteca',
                              style: AppFonts.segoe(color: AppColors.onSurface),
                            ),
                            backgroundColor: AppColors.surfaceContainerHigh,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 18.0),

            // 4. Audio Technical Information Card: Format | Quality (kHz) | Size
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAudioStat('FORMATO', audioInfo.format),
                    Container(
                      width: 1.0,
                      height: 28.0,
                      color: AppColors.outline.withValues(alpha: 0.25),
                    ),
                    _buildAudioStat('CALIDAD', audioInfo.quality),
                    Container(
                      width: 1.0,
                      height: 28.0,
                      color: AppColors.outline.withValues(alpha: 0.25),
                    ),
                    _buildAudioStat('PESO', audioInfo.size),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

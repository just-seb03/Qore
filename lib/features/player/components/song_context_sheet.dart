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
import 'dart:isolate';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';
import 'package:project_anima/features/player/components/song_delete_dialog.dart';
import 'package:project_anima/features/player/components/song_playlist_picker_sheet.dart';

String _formatExtension(String path) {
  String ext = 'MP3';
  if (path.contains('.')) {
    final candidate = path.split('.').last.toUpperCase().trim();
    if (candidate.isNotEmpty && candidate.length <= 5) {
      ext = candidate;
    }
  }
  return ext;
}

String _formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return '—';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Pure-Dart isolate worker reading file size and audio sample rate off the UI thread.
({String format, String quality, String size}) _extractAudioInfoIsolate(
  String path,
  int? cachedBytes,
) {
  final ext = _formatExtension(path);

  int? bytes = cachedBytes;
  if (bytes == null || bytes <= 0) {
    try {
      final f = File(path);
      if (f.existsSync()) {
        bytes = f.lengthSync();
      }
    } catch (_) {}
  }

  String qualityStr = '44.1 kHz';
  try {
    final f = File(path);
    if (f.existsSync()) {
      final metadata = readMetadata(f, getImage: false);
      final sampleRate = metadata.sampleRate;
      if (sampleRate != null && sampleRate > 0) {
        qualityStr = '${(sampleRate / 1000).toStringAsFixed(1)} kHz';
      }
    }
  } catch (_) {}

  return (format: ext, quality: qualityStr, size: _formatBytes(bytes));
}

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongAudioInfo &&
          other.format == format &&
          other.quality == quality &&
          other.size == size;

  @override
  int get hashCode => Object.hash(format, quality, size);

  /// Synchronous zero-I/O initial summary derived purely from in-memory [Song] fields.
  static SongAudioInfo initialFromSong(Song song) {
    return SongAudioInfo(
      format: _formatExtension(song.path),
      quality: '44.1 kHz',
      size: _formatBytes(song.size),
    );
  }

  /// Synchronous factory inspecting the song filesystem and tags (for non-UI callers).
  static SongAudioInfo fromSong(Song song) {
    final raw = _extractAudioInfoIsolate(song.path, song.size);
    return SongAudioInfo(
      format: raw.format,
      quality: raw.quality,
      size: raw.size,
    );
  }

  /// Reads audio file size and sample rate tags inside a background [Isolate.run].
  static Future<SongAudioInfo> loadAsync(Song song) async {
    final raw = await Isolate.run(
      () => _extractAudioInfoIsolate(song.path, song.size),
    );
    return SongAudioInfo(
      format: raw.format,
      quality: raw.quality,
      size: raw.size,
    );
  }
}

/// Contextual bottom sheet presentation widget for the active song.
class SongContextSheet extends StatefulWidget {
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

  @override
  State<SongContextSheet> createState() => _SongContextSheetState();
}

class _SongContextSheetState extends State<SongContextSheet> {
  late SongAudioInfo _audioInfo;

  @override
  void initState() {
    super.initState();
    _audioInfo = SongAudioInfo.initialFromSong(widget.song);
    _loadMetadataAsync();
  }

  @override
  void didUpdateWidget(covariant SongContextSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.song != oldWidget.song) {
      _audioInfo = SongAudioInfo.initialFromSong(widget.song);
      _loadMetadataAsync();
    }
  }

  Future<void> _loadMetadataAsync() async {
    try {
      final loaded = await SongAudioInfo.loadAsync(widget.song);
      if (mounted && loaded != _audioInfo) {
        setState(() {
          _audioInfo = loaded;
        });
      }
    } catch (_) {}
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
    final song = widget.song;
    final audioInfo = _audioInfo;
    final effectiveSongDao = widget.songDao;
    final playlistDao = widget.playlistDao;

    return Container(
      padding: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.zero,
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
                    label: Localizations.localeOf(context).languageCode == 'es'
                        ? 'Favorito'
                        : 'Favorite',
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
                label: Localizations.localeOf(context).languageCode == 'es'
                    ? 'Eliminar'
                    : 'Delete',
                onTap: () async {
                  final isSpanish =
                      Localizations.localeOf(context).languageCode == 'es';
                  final confirmed = await SongDeleteDialog.show(
                    context,
                    songTitle: song.title,
                  );

                  if (confirmed == true && context.mounted) {
                    final resolvedSongDao = effectiveSongDao ?? SongDao();
                    await resolvedSongDao.deleteSong(song.mediaStoreId);

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
                            isSpanish
                                ? 'Canción eliminada de la biblioteca'
                                : 'Track removed from library',
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
                  _buildAudioStat(
                    Localizations.localeOf(context).languageCode == 'es'
                        ? 'FORMATO'
                        : 'FORMAT',
                    audioInfo.format,
                  ),
                  Container(
                    width: 1.0,
                    height: 28.0,
                    color: AppColors.outline.withValues(alpha: 0.25),
                  ),
                  _buildAudioStat(
                    Localizations.localeOf(context).languageCode == 'es'
                        ? 'CALIDAD'
                        : 'QUALITY',
                    audioInfo.quality,
                  ),
                  Container(
                    width: 1.0,
                    height: 28.0,
                    color: AppColors.outline.withValues(alpha: 0.25),
                  ),
                  _buildAudioStat(
                    Localizations.localeOf(context).languageCode == 'es'
                        ? 'PESO'
                        : 'SIZE',
                    audioInfo.size,
                  ),
                ],
              ),
            ),
          ),

          // 5. Artists Section (Spotify-style list with square artist portrait on left)
          if (song.artists.isNotEmpty) ...[
            const SizedBox(height: 18.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  Localizations.localeOf(context).languageCode == 'es'
                      ? 'ARTISTAS'
                      : 'ARTISTS',
                  style: AppFonts.segoe(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 190.0),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: song.artists.length,
                itemBuilder: (context, index) {
                  final artistName = song.artists[index];
                  return _ContextArtistRow(
                    artistName: artistName,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        ArtistDetailScreen.route(artistName),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContextArtistRow extends StatelessWidget {
  final String artistName;
  final VoidCallback onTap;

  const _ContextArtistRow({
    required this.artistName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final customSquare = ArtworkService.instance.getCustomArtistSquarePhoto(artistName);
    final hasCustomPhoto = customSquare != null && customSquare.isNotEmpty;

    Widget buildFallbackIcon() => Icon(
          Icons.person_rounded,
          size: 20.0,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('context_artist_row_$artistName'),
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7.0),
          child: Row(
            children: [
              Container(
                width: 38.0,
                height: 38.0,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.zero,
                ),
                clipBehavior: Clip.antiAlias,
                child: hasCustomPhoto
                    ? Image(
                        image: ResizeImage(
                          FileImage(File(customSquare)),
                          width: 96,
                          height: 96,
                          policy: ResizeImagePolicy.fit,
                        ),
                        fit: BoxFit.cover,
                        width: 38.0,
                        height: 38.0,
                        errorBuilder: (_, _, _) => buildFallbackIcon(),
                      )
                    : buildFallbackIcon(),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.segoe(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18.0,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

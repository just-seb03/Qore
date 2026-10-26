/// File: song_playlist_picker_sheet.dart
/// Description: Modal bottom sheet displaying the user's playlists in Space style (2:1 widescreen
/// sharp unrounded banners) allowing one-tap addition or removal of the current track.
/// Playlists containing the track are darkened with a checkmark badge.
///
/// Components / Classes / Functions:
/// - SongPlaylistPickerSheet: Bottom sheet playlist picker widget.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/playlist/components/playlist_text_banner.dart';

/// Modal bottom sheet for toggling song membership in playlists with Space 2:1 tile aesthetics.
class SongPlaylistPickerSheet extends StatefulWidget {
  final Song song;
  final PlaylistDao? playlistDao;

  const SongPlaylistPickerSheet({
    super.key,
    required this.song,
    this.playlistDao,
  });

  /// Displays the modal playlist picker sheet for the given track.
  static Future<void> show(
    BuildContext context, {
    required Song song,
    PlaylistDao? playlistDao,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => SongPlaylistPickerSheet(
        song: song,
        playlistDao: playlistDao,
      ),
    );
  }

  @override
  State<SongPlaylistPickerSheet> createState() => _SongPlaylistPickerSheetState();
}

class _SongPlaylistPickerSheetState extends State<SongPlaylistPickerSheet> {
  late final PlaylistDao _playlistDao;
  List<Playlist>? _playlists;
  final Set<int> _containedPlaylistIds = <int>{};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _playlistDao = widget.playlistDao ?? PlaylistDao();
    _loadPlaylistsAndMembership();
  }

  Future<void> _loadPlaylistsAndMembership() async {
    try {
      final playlists = await _playlistDao.getPlaylists();
      final containedIds = await _playlistDao.getPlaylistIdsContainingSong(
        widget.song.mediaStoreId,
      );

      if (mounted) {
        setState(() {
          _playlists = playlists;
          _containedPlaylistIds.clear();
          _containedPlaylistIds.addAll(containedIds);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [SongPlaylistPickerSheet] Error loading playlists: $e');
      if (mounted) {
        setState(() {
          _playlists = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePlaylist(Playlist playlist) async {
    if (playlist.id == null) return;
    HapticFeedback.mediumImpact();

    final isContained = _containedPlaylistIds.contains(playlist.id!);

    setState(() {
      if (isContained) {
        _containedPlaylistIds.remove(playlist.id!);
      } else {
        _containedPlaylistIds.add(playlist.id!);
      }
    });

    try {
      if (isContained) {
        await _playlistDao.removeSongFromPlaylist(
          playlist.id!,
          widget.song.mediaStoreId,
        );
      } else {
        await _playlistDao.addSongToPlaylist(
          playlist.id!,
          widget.song,
        );
      }
    } catch (e) {
      debugPrint('⚠️ [SongPlaylistPickerSheet] Error updating playlist membership: $e');
      // Rollback on failure
      if (mounted) {
        setState(() {
          if (isContained) {
            _containedPlaylistIds.add(playlist.id!);
          } else {
            _containedPlaylistIds.remove(playlist.id!);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
      child: Container(
        height: screenHeight * 0.75,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          border: Border.all(
            color: AppColors.outline.withValues(alpha: 0.25),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.75),
              blurRadius: 32.0,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
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

            // 2. Header: Title & Track Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
              child: Column(
                children: [
                  Text(
                    'AÑADIR A PLAYLIST',
                    style: GoogleFonts.inconsolata(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    widget.song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inconsolata(
                      fontSize: 13.0,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8.0),

            // 3. Playlists list in Space style
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.accent,
                      ),
                    )
                  : (_playlists == null || _playlists!.isEmpty)
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              'No tienes playlists creadas todavía',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inconsolata(
                                fontSize: 14.0,
                                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          itemCount: _playlists!.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 14.0),
                          itemBuilder: (context, index) {
                            final playlist = _playlists![index];
                            final isContained = playlist.id != null &&
                                _containedPlaylistIds.contains(playlist.id!);

                            return AspectRatio(
                              aspectRatio: 2.0, // Space 2:1 Aspect Ratio
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.zero, // Sharp corners
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      blurRadius: 10.0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    key: ValueKey('playlist_picker_tile_${playlist.id ?? index}'),
                                    onTap: () => _togglePlaylist(playlist),
                                    splashColor: Colors.white.withValues(alpha: 0.12),
                                    highlightColor: Colors.white.withValues(alpha: 0.06),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // 1. Space 2:1 Text Banner Artwork
                                        PlaylistTextBanner(
                                          title: playlist.name,
                                          coverPath: playlist.coverPath,
                                          representativeSongId: playlist.firstMediaStoreId,
                                          fontFamily: playlist.fontFamily,
                                          textAlignX: playlist.textAlignX,
                                          textAlignY: playlist.textAlignY,
                                          textColor: playlist.textColor,
                                          textGradientColor: playlist.textGradientColor,
                                          fontSize: playlist.fontSize,
                                          textEffect: playlist.textEffect,
                                          isInteractive: false,
                                        ),

                                        // 2. Darkening veil when already in playlist
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          color: isContained
                                              ? Colors.black.withValues(alpha: 0.62)
                                              : Colors.transparent,
                                        ),

                                        // 3. Status Badge in Top-Right
                                        if (isContained)
                                          Positioned(
                                            top: 10.0,
                                            right: 10.0,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 9.0,
                                                vertical: 4.0,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.accent,
                                                borderRadius: BorderRadius.circular(10.0),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.4),
                                                    blurRadius: 4.0,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.check_rounded,
                                                    color: Colors.white,
                                                    size: 14.0,
                                                  ),
                                                  const SizedBox(width: 4.0),
                                                  Text(
                                                    'EN PLAYLIST',
                                                    style: GoogleFonts.inconsolata(
                                                      fontSize: 11.0,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.white,
                                                      letterSpacing: 0.8,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// File: song_playlist_picker_sheet.dart
/// Description: Windows Phone Metro modal bottom sheet listing the user's playlists
/// by name with a sharp square accent checkmark toggle for adding or removing a track.
///
/// Components / Classes / Functions:
/// - SongPlaylistPickerSheet: Metro bottom sheet playlist picker widget.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Metro modal bottom sheet for toggling song membership in playlists.
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
    HapticFeedback.selectionClick();

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

    return Container(
      height: screenHeight * 0.65,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.zero,
        border: Border(
          top: BorderSide(
            color: AppColors.outline.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6.0),
            ModalDismissIndicator(
              onDismiss: () => Navigator.of(context).pop(),
              size: 32.0,
              color: AppColors.onSurfaceVariant,
              animate: false,
              padding: const EdgeInsets.symmetric(vertical: 6.0),
            ),

            // Header: "Añadir a lista" + track subtitle
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.playlist.addToListTitle.toUpperCase(),
                    style: AppFonts.segoe(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    widget.song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.segoe(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              color: AppColors.outlineVariant.withValues(alpha: 0.25),
              height: 1.0,
            ),

            // Metro Playlist Name List with Square Accent Checkmark
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
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
                              style: AppFonts.segoe(
                                fontSize: 14.0,
                                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          itemCount: _playlists!.length,
                          separatorBuilder: (context, index) => Divider(
                            color: AppColors.outlineVariant.withValues(alpha: 0.18),
                            height: 1.0,
                            indent: 20.0,
                            endIndent: 20.0,
                          ),
                          itemBuilder: (context, index) {
                            final playlist = _playlists![index];
                            final isContained = playlist.id != null &&
                                _containedPlaylistIds.contains(playlist.id!);

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: ValueKey('playlist_picker_tile_${playlist.id ?? index}'),
                                onTap: () => _togglePlaylist(playlist),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0,
                                    vertical: 14.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          playlist.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppFonts.segoe(
                                            fontSize: 16.0,
                                            fontWeight: isContained
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12.0),
                                      Container(
                                        width: 24.0,
                                        height: 24.0,
                                        decoration: BoxDecoration(
                                          color: isContained
                                              ? AppColors.accent
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.zero,
                                          border: Border.all(
                                            color: isContained
                                                ? AppColors.accent
                                                : AppColors.outline.withValues(alpha: 0.6),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: isContained
                                            ? Icon(
                                                Icons.check_rounded,
                                                size: 16.0,
                                                color: AppColors.onAccent,
                                              )
                                            : null,
                                      ),
                                    ],
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

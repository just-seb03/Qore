/// File: playlist_tracks_edit_screen.dart
/// Description: Dedicated full-screen editor specifically for playlist tracks/songs.
/// Allows reordering tracks via drag handles and removing tracks with native trash icons,
/// as well as querying and adding tracks from the local music library.
///
/// Components / Classes / Functions:
/// - PlaylistTracksEditScreen: Stateful screen for track reordering, deletion, and addition.
/// - _PlaylistTracksEditScreenState: Coordinates track mutations, search, and persistence.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/playlist/components/playlist_discard_dialog.dart';
import 'package:project_anima/features/playlist/components/playlist_reorderable_song_list.dart';
import 'package:project_anima/features/playlist/components/playlist_song_search_results.dart';
import 'package:project_anima/features/search/components/search_bar.dart';

/// Screen specifically for reordering, deleting, and adding songs in a playlist.
class PlaylistTracksEditScreen extends StatefulWidget {
  final Playlist playlist;
  final List<Song>? initialSongs;
  final PlaylistDao? playlistDao;
  final SongDao? songDao;
  final bool animateBounce;

  const PlaylistTracksEditScreen({
    super.key,
    required this.playlist,
    this.initialSongs,
    this.playlistDao,
    this.songDao,
    this.animateBounce = true,
  });

  /// Factory helper for smooth bottom-to-top modal slide transition.
  static Route<List<Song>?> route({
    required Playlist playlist,
    List<Song>? initialSongs,
    PlaylistDao? playlistDao,
    SongDao? songDao,
    bool animateBounce = true,
  }) {
    return PageRouteBuilder<List<Song>?>(
      pageBuilder: (context, animation, secondaryAnimation) => PlaylistTracksEditScreen(
        playlist: playlist,
        initialSongs: initialSongs,
        playlistDao: playlistDao,
        songDao: songDao,
        animateBounce: animateBounce,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  State<PlaylistTracksEditScreen> createState() => _PlaylistTracksEditScreenState();
}

class _PlaylistTracksEditScreenState extends State<PlaylistTracksEditScreen>
    with SingleTickerProviderStateMixin {
  late final PlaylistDao _playlistDao;
  late final SongDao _songDao;

  final List<Song> _songs = [];
  bool _isLoading = true;
  bool _hasChanges = false;
  bool _isSaving = false;

  final TextEditingController _searchController = TextEditingController();
  List<Song> _searchResults = [];
  bool _isSearching = false;

  double _dragOffset = 0.0;
  late final AnimationController _springController;
  Animation<double>? _springAnimation;

  @override
  void initState() {
    super.initState();
    _playlistDao = widget.playlistDao ?? PlaylistDao();
    _songDao = widget.songDao ?? SongDao();

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_springAnimation != null) {
          setState(() {
            _dragOffset = _springAnimation!.value;
          });
        }
      });

    if (widget.initialSongs != null) {
      _songs.addAll(widget.initialSongs!);
      _isLoading = false;
    } else if (widget.playlist.id != null) {
      _loadSongs();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _playlistDao.getPlaylistSongs(widget.playlist.id!);
      if (mounted) {
        setState(() {
          _songs.clear();
          _songs.addAll(songs);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistTracksEditScreen] Error loading songs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _springController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(double delta) {
    if (_springController.isAnimating) {
      _springController.stop();
    }
    setState(() {
      _dragOffset = math.max(0.0, _dragOffset + delta);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragOffset > 90.0 || velocity > 320.0) {
      _handleDismiss();
    } else if (_dragOffset > 0.0) {
      _springAnimation = Tween<double>(
        begin: _dragOffset,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: _springController,
          curve: Curves.easeOutQuad,
        ),
      );
      _springController.forward(from: 0.0);
    }
  }

  Future<void> _handleDismiss() async {
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    final confirmed = await PlaylistDiscardDialog.show(context);
    if (confirmed && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _searchSongs(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _songDao.searchSongs(trimmed);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistTracksEditScreen] Search error: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _addSong(Song song) {
    HapticFeedback.lightImpact();
    setState(() {
      _songs.add(song);
      _hasChanges = true;
    });
  }

  void _removeSong(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _songs.removeAt(index);
      _hasChanges = true;
    });
  }

  void _reorderSongs(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final song = _songs.removeAt(oldIndex);
      _songs.insert(newIndex, song);
      _hasChanges = true;
    });
  }

  Future<void> _saveTracks() async {
    if (widget.playlist.id == null) {
      Navigator.of(context).pop(_songs);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _playlistDao.updatePlaylist(
        widget.playlist.id!,
        songs: _songs,
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(_songs);
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistTracksEditScreen] Save error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar las canciones',
              style: AppFonts.segoe(color: AppColors.onSurface),
            ),
            backgroundColor: AppColors.surfaceContainerHigh,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleDismiss();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Transform.translate(
            offset: Offset(0.0, _dragOffset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Universal Animated Dismiss Chevron
                const SizedBox(height: 4.0),
                ModalDismissIndicator(
                  onDismiss: _handleDismiss,
                  onDragUpdate: _handleDragUpdate,
                  onDragEnd: _handleDragEnd,
                  size: 34.0,
                  color: AppColors.onSurfaceVariant,
                  animate: widget.animateBounce,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6.0,
                    horizontal: 36.0,
                  ),
                ),
                const SizedBox(height: 4.0),

                // 2. Navigation & Actions Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppColors.onSurface,
                        onPressed: _handleDismiss,
                        tooltip: 'Volver',
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EDITAR CANCIONES',
                              style: AppFonts.segoe(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              context.l10n.playlist.tracksHeaderWithCount(_songs.length),
                              style: AppFonts.segoe(
                                fontSize: 12.5,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        key: const ValueKey('playlist_tracks_save_button'),
                        onPressed: _isSaving ? null : _saveTracks,
                        icon: _isSaving
                            ? SizedBox(
                                width: 14.0,
                                height: 14.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: AppColors.onAccent,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 18.0),
                        label: Text(
                          context.l10n.playlist.saveAction,
                          style: AppFonts.segoe(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.onAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8.0),

                // 3. Search Bar for Adding Songs (shared Metro AppSearchBar)
                AppSearchBar(
                  controller: _searchController,
                  onChanged: _searchSongs,
                  onClear: () => _searchSongs(''),
                  hintText: 'Buscar canciones para añadir...',
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                ),

                const SizedBox(height: 10.0),

                // 4. Content Area: Search Results or Reorderable Song List
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.accent,
                          ),
                        )
                      : _searchController.text.trim().isNotEmpty
                          ? _isSearching
                              ? Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    color: AppColors.accent,
                                  ),
                                )
                              : PlaylistSongSearchResults(
                                  results: _searchResults,
                                  addedSongIds: _songs.map((s) => s.mediaStoreId).toSet(),
                                  onSongAdd: _addSong,
                                )
                          : PlaylistReorderableSongList(
                              songs: _songs,
                              onRemove: _removeSong,
                              onReorder: _reorderSongs,
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

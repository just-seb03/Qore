/// File: playlist_edit_screen.dart
/// Description: Windows Phone Metro + Spotify-inspired coordinator for creating and editing playlists.
/// Clean layout: Metro header + Save, playlist name on top, photo-only 2:1 cover picker,
/// shared Metro AppSearchBar, and a focused song list showing only added tracks or matching search results.
///
/// Components / Classes / Functions:
/// - PlaylistEditScreen: Full-screen Metro playlist creator and editor.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/database/dao/pinned_favorites_dao.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/search/fuzzy_search_engine.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/playlist/components/playlist_cover_banner_picker.dart';
import 'package:project_anima/features/playlist/components/playlist_discard_dialog.dart';
import 'package:project_anima/features/playlist/components/playlist_song_pick_row.dart';
import 'package:project_anima/features/search/components/search_bar.dart';

/// Full-screen Metro playlist creator and editor.
class PlaylistEditScreen extends StatefulWidget {
  /// Existing playlist to edit, or null when creating a new playlist.
  final Playlist? initialPlaylist;

  /// Optional initial songs when editing.
  final List<Song>? initialSongs;

  /// Optional PlaylistDao for dependency injection.
  final PlaylistDao? playlistDao;

  /// Optional SongDao for dependency injection.
  final SongDao? songDao;

  /// Optional FuzzySearchEngine retained for caller/test compatibility.
  final FuzzySearchEngine? fuzzySearchEngine;

  /// Whether to run continuous floating bounce animation on top dismiss arrow.
  final bool animateBounce;

  const PlaylistEditScreen({
    super.key,
    this.initialPlaylist,
    this.initialSongs,
    this.playlistDao,
    this.songDao,
    this.fuzzySearchEngine,
    this.animateBounce = true,
  });

  /// Factory helper for smooth bottom-to-top modal slide transition.
  static Route<Playlist?> route({
    Playlist? initialPlaylist,
    List<Song>? initialSongs,
    PlaylistDao? playlistDao,
    SongDao? songDao,
    FuzzySearchEngine? fuzzySearchEngine,
    bool animateBounce = true,
  }) {
    return PageRouteBuilder<Playlist?>(
      pageBuilder: (context, animation, secondaryAnimation) => PlaylistEditScreen(
        initialPlaylist: initialPlaylist,
        initialSongs: initialSongs,
        playlistDao: playlistDao,
        songDao: songDao,
        fuzzySearchEngine: fuzzySearchEngine,
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
  State<PlaylistEditScreen> createState() => _PlaylistEditScreenState();
}

class _PlaylistEditScreenState extends State<PlaylistEditScreen> {
  static const int _maxSearchResults = 50;

  late final PlaylistDao _playlistDao;
  late final SongDao _songDao;

  late final TextEditingController _nameController;
  late final TextEditingController _songSearchController;

  String? _coverPath;
  final List<Song> _playlistSongs = [];
  final Set<int> _selectedMediaStoreIds = {};
  List<Song> _allLibrarySongs = [];
  List<Song> _searchResults = [];
  bool _isLoadingLibrary = true;
  bool _isSaving = false;
  bool _tracksChanged = false;

  @override
  void initState() {
    super.initState();
    _playlistDao = widget.playlistDao ?? PlaylistDao();
    _songDao = widget.songDao ?? SongDao();

    _nameController = TextEditingController(
      text: widget.initialPlaylist?.name ?? '',
    );

    _songSearchController = TextEditingController()
      ..addListener(_onSearchChanged);

    _coverPath = widget.initialPlaylist?.coverPath;

    if (widget.initialSongs != null) {
      _playlistSongs.addAll(widget.initialSongs!);
      for (final s in widget.initialSongs!) {
        _selectedMediaStoreIds.add(s.mediaStoreId);
      }
    } else if (widget.initialPlaylist?.id != null) {
      _loadExistingSongs(widget.initialPlaylist!.id!);
    }

    _loadLibrarySongs();
  }

  Future<void> _loadExistingSongs(int playlistId) async {
    try {
      final songs = await _playlistDao.getPlaylistSongs(playlistId);
      if (mounted) {
        setState(() {
          _playlistSongs
            ..clear()
            ..addAll(songs);
          _selectedMediaStoreIds
            ..clear()
            ..addAll(songs.map((s) => s.mediaStoreId));
        });
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistEditScreen] Error loading playlist songs: $e');
    }
  }

  Future<void> _loadLibrarySongs() async {
    try {
      final songs = widget.songDao != null
          ? await _songDao.getAllSongs()
          : await _songDao.getSearchDictionarySongs();
      if (mounted) {
        setState(() {
          _allLibrarySongs = songs;
          _isLoadingLibrary = false;
        });
        _onSearchChanged();
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistEditScreen] Error loading library songs: $e');
      if (mounted) {
        setState(() => _isLoadingLibrary = false);
      }
    }
  }

  void _onSearchChanged() {
    final query = _songSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = const [];
        });
      }
      return;
    }

    final exactPrefix = <Song>[];
    final containsMatch = <Song>[];
    for (final song in _allLibrarySongs) {
      final title = song.title.toLowerCase();
      final artist = (song.artist ?? '').toLowerCase();
      final album = (song.album ?? '').toLowerCase();
      if (title.startsWith(query) || artist.startsWith(query)) {
        exactPrefix.add(song);
      } else if (title.contains(query) ||
          artist.contains(query) ||
          album.contains(query)) {
        containsMatch.add(song);
      }
      if (exactPrefix.length + containsMatch.length >= _maxSearchResults * 2) {
        break;
      }
    }

    final combined = [...exactPrefix, ...containsMatch];
    final capped = combined.length > _maxSearchResults
        ? combined.sublist(0, _maxSearchResults)
        : combined;

    if (mounted) {
      setState(() {
        _searchResults = capped;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _songSearchController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final initialName = widget.initialPlaylist?.name ?? '';
    final currentName = _nameController.text.trim();
    if (currentName != initialName && currentName.isNotEmpty) return true;
    if (_coverPath != widget.initialPlaylist?.coverPath) return true;
    if (_tracksChanged) return true;
    return false;
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

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 96,
        maxWidth: 1600,
        maxHeight: 900,
      );
      if (file != null && mounted) {
        setState(() {
          _coverPath = file.path;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistEditScreen] Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.playlist.galleryPickError),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _clearCover() {
    if (_coverPath == null) return;
    setState(() {
      _coverPath = null;
    });
  }

  void _toggleSong(Song song) {
    HapticFeedback.selectionClick();
    setState(() {
      _tracksChanged = true;
      if (_selectedMediaStoreIds.contains(song.mediaStoreId)) {
        _selectedMediaStoreIds.remove(song.mediaStoreId);
        _playlistSongs.removeWhere((s) => s.mediaStoreId == song.mediaStoreId);
      } else {
        _selectedMediaStoreIds.add(song.mediaStoreId);
        _playlistSongs.add(song);
      }
    });
  }

  Future<void> _savePlaylist() async {
    final name = _nameController.text.trim().isEmpty
        ? context.l10n.playlist.defaultPlaylistName
        : _nameController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      Playlist savedPlaylist;
      if (widget.initialPlaylist?.id != null) {
        await _playlistDao.updatePlaylist(
          widget.initialPlaylist!.id!,
          name: name,
          coverPath: _coverPath,
          clearGradient: true,
          songs: _playlistSongs,
        );
        savedPlaylist = widget.initialPlaylist!.copyWith(
          name: name,
          coverPath: _coverPath,
          clearGradient: true,
          songCount: _playlistSongs.length,
          firstMediaStoreId:
              _playlistSongs.isNotEmpty ? _playlistSongs.first.mediaStoreId : null,
        );
      } else {
        savedPlaylist = await _playlistDao.createPlaylist(
          name,
          coverPath: _coverPath,
          songs: _playlistSongs,
        );
      }

      PinnedFavoritesDao.revision.value++;

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).clearSnackBars();
        Navigator.of(context).pop(savedPlaylist);
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistEditScreen] Error saving playlist: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.playlist.savePlaylistError(e.toString())),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.initialPlaylist?.id != null;
    final bool hasQuery = _songSearchController.text.trim().isNotEmpty;
    final List<Song> visibleSongs = hasQuery ? _searchResults : _playlistSongs;
    final int? repSongId = _playlistSongs.isNotEmpty
        ? _playlistSongs.first.mediaStoreId
        : widget.initialPlaylist?.firstMediaStoreId;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleDismiss();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bottomNavBackground,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header + Name Input (on top) + Photo-only 2:1 Banner + AppSearchBar
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ModalDismissIndicator(
                      onDismiss: _handleDismiss,
                      animate: widget.animateBounce,
                      padding: const EdgeInsets.only(top: 6.0, bottom: 2.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 2.0, 20.0, 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              isEditing
                                  ? context.l10n.playlist.editPlaylistTitle
                                  : context.l10n.playlist.createPlaylistTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.light(
                                fontSize: 28.0,
                                letterSpacing: -0.4,
                                color: AppColors.onBackground,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          _MetroSaveButton(
                            key: const ValueKey('playlist_edit_save_button'),
                            isSaving: _isSaving,
                            label: context.l10n.playlist.saveAction,
                            onPressed: _isSaving ? null : _savePlaylist,
                          ),
                        ],
                      ),
                    ),

                    // 2. Playlist Name on Top
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(
                            color: AppColors.outline.withValues(alpha: 0.7),
                            width: 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14.0),
                        child: TextField(
                          key: const ValueKey('playlist_name_input'),
                          controller: _nameController,
                          style: AppFonts.segoe(
                            fontSize: 19.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurface,
                          ),
                          cursorColor: AppColors.accent,
                          decoration: InputDecoration(
                            hintText: context.l10n.playlist.playlistNameHint,
                            hintStyle: AppFonts.segoe(
                              fontSize: 17.5,
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.55),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 11.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14.0),

                    // 3. Photo-only 2:1 Cover Banner (no action row below)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: PlaylistCoverBannerPicker(
                        coverPath: _coverPath,
                        representativeSongId: repSongId,
                        onPickCover: _pickImage,
                        onClearCover: _coverPath != null ? _clearCover : null,
                      ),
                    ),
                    const SizedBox(height: 18.0),

                    // 4. Shared Metro Search Bar (same as Search screen)
                    AppSearchBar(
                      key: const ValueKey('playlist_edit_song_search'),
                      controller: _songSearchController,
                      onClear: () => _songSearchController.clear(),
                      hintText: context.l10n.playlist.searchSongsPlaceholder,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    ),

                    if (_playlistSongs.isNotEmpty || hasQuery)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              hasQuery
                                  ? 'RESULTADOS (${_searchResults.length})'
                                  : 'CANCIONES (${_playlistSongs.length})',
                              style: AppFonts.segoe(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.3,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            if (hasQuery && _playlistSongs.isNotEmpty)
                              Text(
                                context.l10n.playlist.songCount(_playlistSongs.length),
                                style: AppFonts.segoe(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // 5. Focused List: only search results when searching, or added tracks when idle
              if (_isLoadingLibrary && hasQuery)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                )
              else if (visibleSongs.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 36.0),
                    child: Text(
                      hasQuery
                          ? 'Sin resultados para "${_songSearchController.text.trim()}".'
                          : 'Busca canciones arriba para añadirlas a tu playlist.',
                      textAlign: TextAlign.center,
                      style: AppFonts.segoe(
                        fontSize: 13.5,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20.0,
                    2.0,
                    20.0,
                    MediaQuery.paddingOf(context).bottom + 36.0,
                  ),
                  sliver: SliverList.builder(
                    itemCount: visibleSongs.length,
                    itemBuilder: (context, index) {
                      final song = visibleSongs[index];
                      final isSelected =
                          _selectedMediaStoreIds.contains(song.mediaStoreId);
                      return PlaylistSongPickRow(
                        key: ValueKey('playlist_pick_row_${song.mediaStoreId}'),
                        song: song,
                        isSelected: isSelected,
                        onTap: () => _toggleSong(song),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetroSaveButton extends StatelessWidget {
  final bool isSaving;
  final String label;
  final VoidCallback? onPressed;

  const _MetroSaveButton({
    super.key,
    required this.isSaving,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: 36.0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          alignment: Alignment.center,
          child: isSaving
              ? SizedBox(
                  width: 14.0,
                  height: 14.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: AppColors.onAccent,
                  ),
                )
              : Text(
                  label.toUpperCase(),
                  style: AppFonts.segoe(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.onAccent,
                  ),
                ),
        ),
      ),
    );
  }
}

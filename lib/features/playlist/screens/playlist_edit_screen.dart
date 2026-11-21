/// File: playlist_edit_screen.dart
/// Description: Windows Phone Metro + Spotify-inspired coordinator for creating and editing playlists.
/// Streamlined around the essentials: 2:1 Metro cover picker, playlist title input, and an
/// instant virtualized song selector with in-memory search filtering.
///
/// Components / Classes / Functions:
/// - PlaylistEditScreen: Full-screen Metro playlist creator and editor.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/dao/pinned_favorites_dao.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/search/fuzzy_search_engine.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/core/utils/duration_formatter.dart';
import 'package:project_anima/features/playlist/components/playlist_discard_dialog.dart';
import 'package:project_anima/features/playlist/components/playlist_text_banner.dart';

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
  late final PlaylistDao _playlistDao;
  late final SongDao _songDao;

  late final TextEditingController _nameController;
  late final TextEditingController _songSearchController;

  String? _coverPath;
  final List<Song> _playlistSongs = [];
  final Set<int> _selectedMediaStoreIds = {};
  List<Song> _allLibrarySongs = [];
  List<Song> _filteredLibrarySongs = [];
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
    )..addListener(() {
        if (mounted) setState(() {});
      });

    _songSearchController = TextEditingController()
      ..addListener(_filterLibrarySongs);

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
        _filterLibrarySongs();
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistEditScreen] Error loading library songs: $e');
      if (mounted) {
        setState(() => _isLoadingLibrary = false);
      }
    }
  }

  void _filterLibrarySongs() {
    final query = _songSearchController.text.trim().toLowerCase();
    final List<Song> nextFiltered;
    if (query.isEmpty) {
      // Keep selected songs surfaced first, followed by remaining library songs
      final selected = <Song>[];
      final unselected = <Song>[];
      for (final song in _allLibrarySongs) {
        if (_selectedMediaStoreIds.contains(song.mediaStoreId)) {
          selected.add(song);
        } else {
          unselected.add(song);
        }
      }
      nextFiltered = [...selected, ...unselected];
    } else {
      nextFiltered = _allLibrarySongs.where((s) {
        final title = s.title.toLowerCase();
        final artist = (s.artist ?? '').toLowerCase();
        final album = (s.album ?? '').toLowerCase();
        return title.contains(query) ||
            artist.contains(query) ||
            album.contains(query);
      }).toList();
    }

    if (mounted) {
      setState(() {
        _filteredLibrarySongs = nextFiltered;
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
              // 1. Metro Top Header + Dismiss Indicator + Save Action
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ModalDismissIndicator(
                      onDismiss: _handleDismiss,
                      animate: widget.animateBounce,
                      padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 2.0, 20.0, 14.0),
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
                                fontSize: 30.0,
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

                    // 2. 2:1 Metro Cover Banner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: PlaylistTextBanner(
                          title: _nameController.text,
                          coverPath: _coverPath,
                          representativeSongId: repSongId,
                          showCameraBadge: true,
                          onTap: _pickImage,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),

                    // Cover Actions Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          _MetroOutlineAction(
                            icon: Icons.image_outlined,
                            label: _coverPath != null
                                ? context.l10n.playlist.changeCover
                                : context.l10n.playlist.addCover,
                            onTap: _pickImage,
                          ),
                          if (_coverPath != null) ...[
                            const SizedBox(width: 10.0),
                            _MetroOutlineAction(
                              icon: Icons.close_rounded,
                              label: 'QUITAR',
                              onTap: _clearCover,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // 3. Sharp Metro Name Input
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
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
                        child: TextField(
                          key: const ValueKey('playlist_name_input'),
                          controller: _nameController,
                          style: AppFonts.segoe(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurface,
                          ),
                          cursorColor: AppColors.accent,
                          decoration: InputDecoration(
                            hintText: context.l10n.playlist.playlistNameHint,
                            hintStyle: AppFonts.segoe(
                              fontSize: 17.0,
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.55),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 11.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22.0),

                    // 4. Spotify-style Quick Track Selector Header + Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CANCIONES',
                            style: AppFonts.segoe(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            context.l10n.playlist.songCount(_playlistSongs.length),
                            style: AppFonts.segoe(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(
                            color: AppColors.outline.withValues(alpha: 0.55),
                            width: 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 19.0,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: TextField(
                                key: const ValueKey('playlist_edit_song_search'),
                                controller: _songSearchController,
                                style: AppFonts.segoe(
                                  fontSize: 14.5,
                                  color: AppColors.onSurface,
                                ),
                                cursorColor: AppColors.accent,
                                decoration: InputDecoration(
                                  hintText: context.l10n.playlist.searchSongsPlaceholder,
                                  hintStyle: AppFonts.segoe(
                                    fontSize: 14.0,
                                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.55),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 11.0),
                                ),
                              ),
                            ),
                            if (_songSearchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () => _songSearchController.clear(),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18.0,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                  ],
                ),
              ),

              // 5. Virtualized Song Selector List
              if (_isLoadingLibrary)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                )
              else if (_filteredLibrarySongs.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                    child: Text(
                      _allLibrarySongs.isEmpty
                          ? 'No hay canciones indexadas en tu biblioteca.'
                          : 'Sin resultados para "${_songSearchController.text.trim()}".',
                      textAlign: TextAlign.center,
                      style: AppFonts.segoe(
                        fontSize: 13.5,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20.0,
                    0.0,
                    20.0,
                    MediaQuery.paddingOf(context).bottom + 36.0,
                  ),
                  sliver: SliverList.builder(
                    itemCount: _filteredLibrarySongs.length,
                    itemBuilder: (context, index) {
                      final song = _filteredLibrarySongs[index];
                      final isSelected =
                          _selectedMediaStoreIds.contains(song.mediaStoreId);
                      return _MetroPlaylistSongPickRow(
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: isSaving
              ? SizedBox(
                  width: 16.0,
                  height: 16.0,
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
                    letterSpacing: 1.3,
                    color: AppColors.onAccent,
                  ),
                ),
        ),
      ),
    );
  }
}

class _MetroOutlineAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MetroOutlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.6),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15.0, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6.0),
              Text(
                label.toUpperCase(),
                style: AppFonts.segoe(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetroPlaylistSongPickRow extends StatelessWidget {
  final Song song;
  final bool isSelected;
  final VoidCallback onTap;

  const _MetroPlaylistSongPickRow({
    super.key,
    required this.song,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.surfaceContainerHigh.withValues(alpha: 0.75)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.35),
                width: 0.6,
              ),
            ),
          ),
          child: Row(
            children: [
              AnimaArtworkImage(
                mediaStoreId: song.mediaStoreId,
                albumId: song.albumId,
                width: 42.0,
                height: 42.0,
                borderRadius: 0.0,
                fallbackIcon: Icons.music_note_rounded,
                isThumbnail: true,
              ),
              const SizedBox(width: 12.0),
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
                        fontSize: 14.5,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.accent : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '${song.artist ?? context.l10n.common.unknownArtist} · ${formatDurationMs(song.duration)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.segoe(
                        fontSize: 12.0,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10.0),
              Container(
                width: 28.0,
                height: 28.0,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.outline.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  isSelected ? Icons.check_rounded : Icons.add_rounded,
                  size: 17.0,
                  color: isSelected ? AppColors.onAccent : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

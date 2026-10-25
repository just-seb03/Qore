/// File: playlist_edit_screen.dart
/// Description: Dedicated full-screen modal coordinator for creating and editing playlists.
/// Features a generic/custom cover picker, editable playlist title, song search & addition,
/// reorderable song list with drag handles, M3 Expressive discard confirmation dialog,
/// and a floating theme-styled 'Save' action button. Excludes the global mini-player.
///
/// Components / Classes / Functions:
/// - PlaylistEditScreen: Full-screen playlist editor widget.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/search/fuzzy_search_engine.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/playlist/components/playlist_cover_picker.dart';
import 'package:project_anima/features/playlist/components/playlist_discard_dialog.dart';
import 'package:project_anima/features/playlist/components/playlist_reorderable_song_list.dart';
import 'package:project_anima/features/playlist/components/playlist_song_search_bar.dart';
import 'package:project_anima/features/playlist/components/playlist_song_search_results.dart';
import 'package:project_anima/features/playlist/utils/playlist_font_helper.dart';

/// Screen widget for creating or editing user playlists.
class PlaylistEditScreen extends StatefulWidget {
  /// Existing playlist to edit, or null when creating a new playlist.
  final Playlist? initialPlaylist;

  /// Optional initial songs when editing.
  final List<Song>? initialSongs;

  /// Optional PlaylistDao for dependency injection.
  final PlaylistDao? playlistDao;

  /// Optional SongDao for dependency injection.
  final SongDao? songDao;

  /// Optional FuzzySearchEngine for dependency injection.
  final FuzzySearchEngine? fuzzySearchEngine;

  /// Whether to run continuous floating bounce animation on top dismiss arrow (defaults to true).
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
  late final FuzzySearchEngine _fuzzySearchEngine;

  late final TextEditingController _nameController;
  late final TextEditingController _searchController;

  String? _coverPath;
  String? _selectedFontFamily;
  final List<Song> _playlistSongs = [];
  List<Song> _searchResults = [];
  bool _isSearching = false;
  bool _isSaving = false;

  static TextStyle get _nameHintStyle => GoogleFonts.outfit(
    fontSize: 22.0,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceVariant.withValues(alpha: 0.45),
    letterSpacing: -0.3,
  );

  static TextStyle get _sectionHeaderStyle => GoogleFonts.inconsolata(
    fontSize: 13.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle get _saveButtonStyle => GoogleFonts.inconsolata(
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: AppColors.onSurface,
  );

  @override
  void initState() {
    super.initState();
    _playlistDao = widget.playlistDao ?? PlaylistDao();
    _songDao = widget.songDao ?? SongDao();
    _fuzzySearchEngine = widget.fuzzySearchEngine ?? FuzzySearchEngine(songDao: _songDao);

    _nameController = TextEditingController(
      text: widget.initialPlaylist?.name ?? '',
    );
    _searchController = TextEditingController();
    _coverPath = widget.initialPlaylist?.coverPath;
    _selectedFontFamily = widget.initialPlaylist?.fontFamily ?? 'Inconsolata';

    if (widget.initialSongs != null) {
      _playlistSongs.addAll(widget.initialSongs!);
    } else if (widget.initialPlaylist?.id != null) {
      _loadExistingSongs(widget.initialPlaylist!.id!);
    }
  }

  Future<void> _loadExistingSongs(int playlistId) async {
    try {
      final songs = await _playlistDao.getPlaylistSongs(playlistId);
      if (mounted) {
        setState(() {
          _playlistSongs.clear();
          _playlistSongs.addAll(songs);
        });
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistEditScreen] Error loading songs: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final initialName = widget.initialPlaylist?.name ?? '';
    final currentName = _nameController.text.trim();
    if (currentName != initialName && currentName.isNotEmpty) return true;
    if (_coverPath != widget.initialPlaylist?.coverPath) return true;
    if (_selectedFontFamily != widget.initialPlaylist?.fontFamily) return true;
    if (_playlistSongs.length != (widget.initialSongs?.length ?? 0)) return true;
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

  Future<void> _onSearchQueryChanged(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _fuzzySearchEngine.searchOnlySongs(clean, limit: 20);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistEditScreen] Search error: $e');
    }
  }

  void _addSongToPlaylist(Song song) {
    setState(() {
      _playlistSongs.add(song);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.playlist.addedSongSuccess(song.title)),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeSongFromPlaylist(int index) {
    setState(() {
      _playlistSongs.removeAt(index);
    });
  }

  void _onReorderSongs(int oldIndex, int newIndex) {
    setState(() {
      final song = _playlistSongs.removeAt(oldIndex);
      _playlistSongs.insert(newIndex, song);
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
          fontFamily: _selectedFontFamily,
          songs: _playlistSongs,
        );
        savedPlaylist = widget.initialPlaylist!.copyWith(
          name: name,
          coverPath: _coverPath,
          fontFamily: _selectedFontFamily,
          songCount: _playlistSongs.length,
        );
      } else {
        savedPlaylist = await _playlistDao.createPlaylist(
          name,
          coverPath: _coverPath,
          fontFamily: _selectedFontFamily,
          songs: _playlistSongs,
        );
      }

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
    final addedSongIds = _playlistSongs.map((s) => s.mediaStoreId).toSet();

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
          child: Stack(
            children: [
              // 1. Scrollable Form Content
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120.0),
                child: Column(
                  children: [
                    // Top Exit Chevron Arrow
                    ModalDismissIndicator(
                      onDismiss: _handleDismiss,
                      animate: widget.animateBounce,
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    ),

                    // Hero Banner Cover Photo Picker (1920x620)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: PlaylistCoverPicker(
                        coverPath: _coverPath,
                        onCoverPicked: (path) {
                          setState(() {
                            _coverPath = path;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Playlist Name Input Container with dynamic font preview
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: AppColors.outline.withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                      ),
                      child: TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: getPlaylistTitleFont(
                          _selectedFontFamily,
                          baseStyle: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        cursorColor: AppColors.accent,
                        decoration: InputDecoration(
                          hintText: context.l10n.playlist.playlistNameHint,
                          hintStyle: _nameHintStyle,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Font Family Selector Carousel
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.l10n.playlist.typographySection,
                          style: _sectionHeaderStyle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    SizedBox(
                      height: 42.0,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: availablePlaylistFonts.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8.0),
                        itemBuilder: (context, index) {
                          final font = availablePlaylistFonts[index];
                          final isSelected = (_selectedFontFamily ?? 'Inconsolata').toLowerCase() ==
                              font.id.toLowerCase();
                          return Material(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(22.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22.0),
                              onTap: () {
                                setState(() {
                                  _selectedFontFamily = font.id;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22.0),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.onAccent
                                        : AppColors.outline.withValues(alpha: 0.35),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  font.displayName,
                                  style: getPlaylistTitleFont(
                                    font.id,
                                    baseStyle: TextStyle(
                                      fontSize: 13.0,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? AppColors.onAccent : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Add Songs Section Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.l10n.playlist.addSongsSection,
                          style: _sectionHeaderStyle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6.0),

                    // Song Search Bar
                    PlaylistSongSearchBar(
                      controller: _searchController,
                      onChanged: _onSearchQueryChanged,
                      onClear: () {
                        setState(() {
                          _isSearching = false;
                          _searchResults = [];
                        });
                      },
                    ),

                    // Real-time Song Search Results (if searching)
                    if (_isSearching) ...[
                      PlaylistSongSearchResults(
                        results: _searchResults,
                        addedSongIds: addedSongIds,
                        onSongAdd: _addSongToPlaylist,
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    // Current Playlist Song List (Reorderable)
                    PlaylistReorderableSongList(
                      songs: _playlistSongs,
                      onRemove: _removeSongFromPlaylist,
                      onReorder: _onReorderSongs,
                    ),
                  ],
                ),
              ),

              // 2. Floating Save Button
              Positioned(
                left: 24.0,
                right: 24.0,
                bottom: MediaQuery.paddingOf(context).bottom + 20.0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 18.0,
                          spreadRadius: 1.0,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _savePlaylist,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navIndicator,
                        foregroundColor: AppColors.futuristicWhite,
                        minimumSize: const Size(180.0, 50.0),
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          side: BorderSide(
                            color: AppColors.outline.withValues(alpha: 0.5),
                            width: 1.0,
                          ),
                        ),
                      ),
                      icon: _isSaving
                          ? SizedBox(
                              width: 18.0,
                              height: 18.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: AppColors.accent,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 20.0),
                      label: Text(
                        context.l10n.playlist.saveAction,
                        style: _saveButtonStyle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

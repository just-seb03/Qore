/// File: library.dart
/// Description: Library screen displaying the centered Inconsolata LibraryHeader,
/// the Material Design 3 Expressive single-selection connected pill filter component,
/// active entity view (Albums 2-per-row grid, Artists list, or Playlists view),
/// and the global AppBottomNav, coordinated by LibraryTransitionControl.
///
/// Components / Classes / Functions:
/// - Library: Type alias for LibraryScreen.
/// - LibraryScreen: Screen widget coordinating the Library views.
/// - _LibraryScreenState: State class managing active filter and view switching.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/library/components/albums/library_albums_grid.dart';
import 'package:project_anima/features/library/components/artists/library_artists_list.dart';
import 'package:project_anima/features/library/components/library_filter_pills.dart';
import 'package:project_anima/features/library/components/library_header.dart';
import 'package:project_anima/features/library/components/playlists/library_playlists_view.dart';
import 'package:project_anima/features/library/controls/library_transition_controller.dart';
import 'package:project_anima/features/playlist/screens/playlist_edit_screen.dart';

/// Type alias allowing both `Library` and `LibraryScreen` across the codebase.
typedef Library = LibraryScreen;

/// Primary Library screen for the application.
class LibraryScreen extends StatefulWidget {
  /// Whether to display the bottom navigation bar. Defaults to true.
  final bool showBottomNav;

  /// Initial active filter. Defaults to [LibraryFilter.albums].
  final LibraryFilter initialFilter;

  /// Optional pre-loaded albums for dependency injection.
  final List<AlbumDiscoveryItem>? initialAlbums;

  /// Optional pre-loaded artists for dependency injection.
  final List<ArtistDiscoveryItem>? initialArtists;

  /// Optional pre-loaded playlists for dependency injection.
  final List<Playlist>? initialPlaylists;

  /// Optional PlaylistDao for dependency injection.
  final PlaylistDao? playlistDao;

  /// Optional SongDao for dependency injection.
  final SongDao? songDao;

  /// Optional transition controller for dependency injection and testing.
  final LibraryTransitionController? transitionController;

  const LibraryScreen({
    super.key,
    this.showBottomNav = true,
    this.initialFilter = LibraryFilter.albums,
    this.initialAlbums,
    this.initialArtists,
    this.initialPlaylists,
    this.playlistDao,
    this.songDao,
    this.transitionController,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late LibraryTransitionController _transitionController;
  bool _internalControllerCreated = false;
  final GlobalKey<LibraryPlaylistsViewState> _playlistsViewKey =
      GlobalKey<LibraryPlaylistsViewState>();

  @override
  void initState() {
    super.initState();
    if (widget.transitionController != null) {
      _transitionController = widget.transitionController!;
      _internalControllerCreated = false;
    } else {
      _transitionController = LibraryTransitionController(
        initialFilter: widget.initialFilter,
      );
      _internalControllerCreated = true;
    }
  }

  @override
  void didUpdateWidget(covariant LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transitionController != oldWidget.transitionController) {
      if (_internalControllerCreated) {
        _transitionController.dispose();
      }
      if (widget.transitionController != null) {
        _transitionController = widget.transitionController!;
        _internalControllerCreated = false;
      } else {
        _transitionController = LibraryTransitionController(
          initialFilter: widget.initialFilter,
        );
        _internalControllerCreated = true;
      }
    } else if (widget.initialFilter != oldWidget.initialFilter &&
        widget.initialFilter != _transitionController.currentFilter) {
      _transitionController.animateTo(widget.initialFilter);
    }
  }

  @override
  void dispose() {
    if (_internalControllerCreated) {
      _transitionController.dispose();
    }
    super.dispose();
  }

  Future<void> _openCreatePlaylistScreen() async {
    await Navigator.of(context).push<Playlist?>(
      PlaylistEditScreen.route(
        playlistDao: widget.playlistDao,
        songDao: widget.songDao,
      ),
    );

    if (mounted) {
      await _playlistsViewKey.currentState?.reloadPlaylists();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        PlaybackController.instance,
        _transitionController,
      ]),
      builder: (context, _) {
        final currentFilter = _transitionController.currentFilter;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                const LibraryHeader(),
                LibraryFilterPills(
                  selectedFilter: currentFilter,
                  onFilterChanged: (filter) {
                    _transitionController.animateTo(filter);
                  },
                ),
                Expanded(
                  child: LibraryTransitionControl(
                    controller: _transitionController,
                    children: [
                      LibraryAlbumsGrid(
                        key: const ValueKey('library_albums_view'),
                        albums: widget.initialAlbums,
                        songDao: widget.songDao,
                      ),
                      LibraryArtistsList(
                        key: const ValueKey('library_artists_view'),
                        artists: widget.initialArtists,
                        songDao: widget.songDao,
                      ),
                      LibraryPlaylistsView(
                        key: _playlistsViewKey,
                        playlists: widget.initialPlaylists,
                        playlistDao: widget.playlistDao,
                        songDao: widget.songDao,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: currentFilter == LibraryFilter.playlists
              ? FloatingActionButton(
                  key: const ValueKey('library_create_playlist_fab'),
                  onPressed: _openCreatePlaylistScreen,
                  backgroundColor: AppColors.navIndicator,
                  foregroundColor: AppColors.futuristicWhite,
                  elevation: 6.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    side: BorderSide(
                      color: AppColors.outline,
                      width: 1.0,
                    ),
                  ),
                  child: const Icon(Icons.add_rounded, size: 28.0),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: widget.showBottomNav
              ? const AppBottomNav(
                  currentIndex: 2,
                )
              : null,
        );
      },
    );
  }
}


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
import 'package:flutter/rendering.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/components/scroll_edge_fade_mask.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/library/components/albums/library_albums_grid.dart';
import 'package:project_anima/features/library/components/artists/library_artists_list.dart';
import 'package:project_anima/features/library/components/library_category_bar.dart';
import 'package:project_anima/features/library/components/library_filter_pills.dart';
import 'package:project_anima/features/library/components/library_header.dart';
import 'package:project_anima/features/library/components/playlists/library_playlists_view.dart';
import 'package:project_anima/features/library/components/songs/library_songs_list.dart';
import 'package:project_anima/features/library/controls/library_transition_controller.dart';
import 'package:project_anima/features/playlist/screens/playlist_edit_screen.dart';

/// Dedicated FloatingActionButtonLocation for Library that elevates the FAB
/// above the bottom navigation bar and active mini player, avoiding obstruction.
class LibraryPlaylistsFabLocation extends FloatingActionButtonLocation {
  final double bottomOffset;

  const LibraryPlaylistsFabLocation(this.bottomOffset);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.floatingActionButtonSize.width -
        16.0;
    final double fabY = scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        bottomOffset;
    return Offset(fabX, fabY);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LibraryPlaylistsFabLocation &&
        (other.bottomOffset - bottomOffset).abs() < 0.5;
  }

  @override
  int get hashCode => bottomOffset.round().hashCode;
}

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

  /// Optional pre-loaded songs for dependency injection.
  final List<Song>? initialSongs;

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
    this.initialSongs,
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
  bool _isHeaderVisible = true;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final metrics = notification.metrics;

    // 1. If at or near top, always keep header visible
    if (metrics.pixels <= 25.0) {
      if (!_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = true;
        });
      }
      return false;
    }

    // 2. Ignore overscroll and bottom bounce to prevent snap-back jitter
    if (metrics.outOfRange || metrics.pixels >= metrics.maxScrollExtent - 40.0) {
      return false;
    }

    // 3. Process scrolling movements with threshold
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0.0;
      if (delta > 6.0 && metrics.pixels > 35.0) {
        if (_isHeaderVisible) {
          setState(() {
            _isHeaderVisible = false;
          });
        }
      } else if (delta < -6.0) {
        if (!_isHeaderVisible) {
          setState(() {
            _isHeaderVisible = true;
          });
        }
      }
    } else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse && metrics.pixels > 35.0) {
        if (_isHeaderVisible) {
          setState(() {
            _isHeaderVisible = false;
          });
        }
      } else if (notification.direction == ScrollDirection.forward) {
        if (!_isHeaderVisible) {
          setState(() {
            _isHeaderVisible = true;
          });
        }
      }
    }

    return false;
  }

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
    return Container(
      color: AppColors.bottomNavBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dynamic ambient particles simulation backdrop (persistent across section transitions)
          const AmbientParticlesCanvas(),

          ListenableBuilder(
            listenable: Listenable.merge([
              PlaybackController.instance,
              _transitionController,
            ]),
            builder: (context, _) {
              final currentFilter = _transitionController.currentFilter;
              final hasMiniPlayer = PlaybackController.instance.currentSong != null;
              final mqBottom = MediaQuery.paddingOf(context).bottom;
              // When hosted in MenuTransitionControl, mqBottom already contains the exact height
              // of the bottom navigation bar (and MiniPlayer if active) plus device safe area.
              // In standalone/test environments, fallback to explicit baseline offsets.
              const double separation = 16.0;
              final double baseBottomOffset = (mqBottom > 60.0)
                  ? mqBottom
                  : (80.0 + (hasMiniPlayer ? 72.0 : 0.0) + mqBottom);
              final fabBottomOffset = baseBottomOffset + separation;

              return Scaffold(
                extendBody: true,
                backgroundColor: Colors.transparent,
                body: SafeArea(
                  bottom: false,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScrollNotification,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRect(
                          child: AnimatedAlign(
                            alignment: Alignment.topCenter,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            heightFactor: _isHeaderVisible ? 1.0 : 0.0,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              opacity: _isHeaderVisible ? 1.0 : 0.0,
                              child: const LibraryHeader(isMetro: true),
                            ),
                          ),
                        ),
                        LibraryCategoryBar(
                          showChevrons: false,
                          selectedFilter: currentFilter,
                          onFilterChanged: (filter) {
                            _transitionController.animateTo(filter);
                          },
                          onPrevious: () => _transitionController.animateToPrevious(),
                          onNext: () => _transitionController.animateToNext(),
                        ),
                        const SizedBox(height: 6.0),
                        Expanded(
                          child: ScrollEdgeFadeMask(
                            key: const ValueKey('library_scroll_edge_fade_mask'),
                            topFadeExtent: 36.0,
                            bottomFadeExtent: 64.0,
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
                                LibrarySongsList(
                                  key: const ValueKey('library_songs_view'),
                                  songs: widget.initialSongs ??
                                      ((widget.initialAlbums != null || widget.initialArtists != null)
                                          ? const []
                                          : null),
                                  songDao: widget.songDao,
                                ),
                                LibraryPlaylistsView(
                                  key: _playlistsViewKey,
                                  playlists: widget.initialPlaylists ??
                                      ((widget.initialAlbums != null || widget.initialArtists != null)
                                          ? const []
                                          : null),
                                  playlistDao: widget.playlistDao,
                                  songDao: widget.songDao,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                floatingActionButton: currentFilter == LibraryFilter.playlists
                    ? Container(
                        key: const ValueKey('library_create_playlist_fab_container'),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.zero,
                        ),
                        child: FloatingActionButton(
                          key: const ValueKey('library_create_playlist_fab'),
                          onPressed: _openCreatePlaylistScreen,
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.onAccent,
                          elevation: 0.0,
                          highlightElevation: 0.0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          child: const Icon(Icons.add_rounded, size: 28.0),
                        ),
                      )
                    : null,
                floatingActionButtonLocation: currentFilter == LibraryFilter.playlists
                    ? LibraryPlaylistsFabLocation(fabBottomOffset)
                    : null,
                floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
                bottomNavigationBar: widget.showBottomNav
                    ? const AppBottomNav(
                        currentIndex: 3,
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}


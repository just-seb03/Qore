/// File: library.dart
/// Description: Library screen displaying the centered Zen Dots LibraryHeader,
/// the Material Design 3 Expressive single-selection connected pill filter component,
/// active entity view (Albums 2-per-row grid, Artists list, or Playlists placeholder),
/// and the global AppBottomNav.
///
/// Components / Classes / Functions:
/// - Library: Type alias for LibraryScreen.
/// - LibraryScreen: Screen widget coordinating the Library views.
/// - _LibraryScreenState: State class managing active filter and view switching.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/library/components/albums/library_albums_grid.dart';
import 'package:project_anima/features/library/components/artists/library_artists_list.dart';
import 'package:project_anima/features/library/components/library_filter_pills.dart';
import 'package:project_anima/features/library/components/library_header.dart';
import 'package:project_anima/features/library/components/playlists/library_playlists_placeholder.dart';

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

  /// Optional SongDao for dependency injection.
  final SongDao? songDao;

  const LibraryScreen({
    super.key,
    this.showBottomNav = true,
    this.initialFilter = LibraryFilter.albums,
    this.initialAlbums,
    this.initialArtists,
    this.songDao,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late LibraryFilter _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bottomNavBackground,
      body: SafeArea(
        child: Column(
          children: [
            const LibraryHeader(),
            LibraryFilterPills(
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
            Expanded(
              child: _buildActiveView(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const AppBottomNav(
              currentIndex: 2,
            )
          : null,
    );
  }

  Widget _buildActiveView() {
    switch (_selectedFilter) {
      case LibraryFilter.albums:
        return LibraryAlbumsGrid(
          key: const ValueKey('library_albums_view'),
          albums: widget.initialAlbums,
          songDao: widget.songDao,
        );
      case LibraryFilter.artists:
        return LibraryArtistsList(
          key: const ValueKey('library_artists_view'),
          artists: widget.initialArtists,
          songDao: widget.songDao,
        );
      case LibraryFilter.playlists:
        return const LibraryPlaylistsPlaceholder(
          key: ValueKey('library_playlists_view'),
        );
    }
  }
}

/// File: search.dart
/// Description: Search screen displaying the centered Zen Dots SearchHeader and
/// the Material Design 3 Expressive AppSearchBar with the global AppBottomNav below.
/// Optimized to eliminate global setState rebuilds on keystrokes by delegating
/// clear-action state reactively to AppSearchBar.
///
/// Components / Classes / Functions:
/// - Search: Type alias for SearchScreen.
/// - SearchScreen: Screen widget displaying the Search interface.
/// - _SearchScreenState: State class managing the search controller input.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/controls/navigation_controller.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/search/models/recent_search_item.dart';
import 'package:project_anima/core/search/music_search_controller.dart';
import 'package:project_anima/core/search/recent_search_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';
import 'package:project_anima/features/player/screens/player_screen.dart';
import 'package:project_anima/features/search/components/search_bar.dart';
import 'package:project_anima/features/search/components/search_header.dart';
import 'package:project_anima/features/search/components/search_results_list.dart';

/// Type alias allowing both `Search` and `SearchScreen` across the codebase.
typedef Search = SearchScreen;

/// Primary Search screen for the application.
class SearchScreen extends StatefulWidget {
  /// Whether to display the bottom navigation bar. Defaults to true.
  final bool showBottomNav;

  const SearchScreen({
    super.key,
    this.showBottomNav = true,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final MusicSearchController _searchEngine = MusicSearchController();
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    RecentSearchController.instance.init();
    NavigationController.instance.searchResetNotifier.addListener(_onSearchReset);
    NavigationController.instance.searchScrollToTopNotifier.addListener(_onScrollToTop);
  }

  Future<void> _handleRecentItemTap(RecentSearchItem item) async {
    RecentSearchController.instance.touchItem(item);
    if (item.type == RecentSearchType.song) {
      final song = await SongDao().getSongByMediaStoreId(item.representativeSongId);
      if (song != null && mounted) {
        _handleSongTap(song);
        return;
      }
    } else if (item.type == RecentSearchType.artist) {
      if (mounted) {
        Navigator.of(context).push(ArtistDetailScreen.route(item.title));
        return;
      }
    } else if (item.type == RecentSearchType.album) {
      if (mounted) {
        Navigator.of(context).push(
          AlbumDetailScreen.route(
            albumName: item.title,
            artistName: item.subtitle,
            albumId: item.albumId,
            representativeSongId: item.representativeSongId,
          ),
        );
        return;
      }
    }
    _searchController.text = item.title;
    _searchEngine.onQueryChanged(item.title);
  }

  void _handleArtistTap(ArtistDiscoveryItem artist) {
    Navigator.of(context).push(ArtistDetailScreen.route(artist.name));
  }

  void _handleAlbumTap(AlbumDiscoveryItem album) {
    Navigator.of(context).push(
      AlbumDetailScreen.route(
        albumName: album.name,
        artistName: album.artist,
        albumId: album.albumId,
        representativeSongId: album.representativeSongId,
      ),
    );
  }

  void _handleSongTap(Song song) {
    PlaybackController.instance.playSong(
      song,
      queue: _searchEngine.resultsGroup.matchedSongs.isNotEmpty
          ? _searchEngine.resultsGroup.matchedSongs
          : [song],
    );
    Navigator.of(context).push(PlayerScreen.route());
  }

  /// Resets search query, engine results, and scroll offset back to initial state.
  /// Triggered strictly when the user taps the search button twice in a row on the bottom nav.
  void _onSearchReset() {
    if (!mounted) return;
    _searchController.clear();
    _searchEngine.clear();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
    FocusScope.of(context).unfocus();
  }

  /// Smoothly scrolls results back to top when single-tapping the already active search tab.
  void _onScrollToTop() {
    if (!mounted) return;
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    NavigationController.instance.searchResetNotifier.removeListener(_onSearchReset);
    NavigationController.instance.searchScrollToTopNotifier.removeListener(_onScrollToTop);
    _searchController.dispose();
    _searchEngine.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.bottomNavBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SearchHeader(),
            AppSearchBar(
              controller: _searchController,
              onChanged: (text) => _searchEngine.onQueryChanged(text),
              onClear: () => _searchEngine.clear(),
            ),
            Expanded(
              child: SearchResultsList(
                controller: _searchEngine,
                scrollController: _scrollController,
                onSongTap: _handleSongTap,
                onAlbumTap: _handleAlbumTap,
                onArtistTap: _handleArtistTap,
                onRecentItemTap: _handleRecentItemTap,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const AppBottomNav(
              currentIndex: 1,
            )
          : null,
    );
  }
}

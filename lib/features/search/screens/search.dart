/// File: search.dart
/// Description: Search screen displaying the centered Inconsolata SearchHeader and
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
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/search/models/recent_search_item.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/core/search/music_search_controller.dart';
import 'package:project_anima/core/search/recent_search_controller.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
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
  final FocusNode _searchFocusNode = FocusNode();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    RecentSearchController.instance.init();
    NavigationController.instance.searchResetNotifier.addListener(_onSearchReset);
    NavigationController.instance.searchScrollToTopNotifier.addListener(_onScrollToTop);
    _searchFocusNode.addListener(_syncSearchBackInterception);
    _searchController.addListener(_syncSearchBackInterception);
  }

  void _syncSearchBackInterception() {
    if (!mounted) return;
    final isTabVisible = TickerMode.valuesOf(context).enabled;
    NavigationController.instance.setSearchInterceptsBack(
      isTabVisible && (_searchFocusNode.hasFocus || _searchController.text.isNotEmpty),
    );
  }

  Future<void> _handleRecentItemTap(RecentSearchItem item) async {
    _searchFocusNode.unfocus();
    void deferTouch() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 400), () {
          RecentSearchController.instance.touchItem(item);
        });
      });
    }

    if (item.type == RecentSearchType.song) {
      final song = await SongDao().getSongByMediaStoreId(item.representativeSongId);
      if (song != null && mounted) {
        _handleSongTap(song);
        deferTouch();
        return;
      }
    } else if (item.type == RecentSearchType.artist) {
      if (mounted) {
        Navigator.of(context).push(ArtistDetailScreen.route(item.title));
        deferTouch();
        return;
      }
    } else if (item.type == RecentSearchType.album) {
      if (mounted) {
        Navigator.of(context).push(
          AlbumDetailScreen.route(
            albumName: item.title,
            artistName: item.cleanArtistName,
            albumId: item.albumId,
            representativeSongId: item.representativeSongId,
          ),
        );
        deferTouch();
        return;
      }
    }
    _searchController.text = item.title;
    _searchEngine.onQueryChanged(item.title);
    deferTouch();
  }

  final SongDao _songDao = SongDao();

  void _handleArtistTap(ArtistDiscoveryItem artist) {
    _searchFocusNode.unfocus();
    Navigator.of(context).push(ArtistDetailScreen.route(artist.name));
  }

  Future<void> _handleArtistPlayTap(ArtistDiscoveryItem artist) async {
    _searchFocusNode.unfocus();
    try {
      final songs = await _songDao.getSongsByArtist(artist.name);
      if (songs.isNotEmpty) {
        final shuffled = List<Song>.from(songs)..shuffle();
        await PlaybackController.instance.playSong(
          shuffled.first,
          queue: shuffled,
        );
        if (mounted) {
          Navigator.of(context).push(PlayerScreen.route());
        }
      }
    } catch (e) {
      debugPrint('Error playing artist songs on shuffle: $e');
    }
  }

  void _handleAlbumTap(AlbumDiscoveryItem album) {
    _searchFocusNode.unfocus();
    Navigator.of(context).push(
      AlbumDetailScreen.route(
        albumName: album.name,
        artistName: album.artist,
        albumId: album.albumId,
        representativeSongId: album.representativeSongId,
      ),
    );
  }

  Future<void> _handleAlbumPlayTap(AlbumDiscoveryItem album) async {
    _searchFocusNode.unfocus();
    try {
      var songs = await _songDao.getSongsByAlbum(
        album.name,
        artist: album.artist,
        albumId: album.albumId,
      );
      if (songs.isEmpty) {
        songs = await _songDao.getSongsByAlbum(
          album.name,
          albumId: album.albumId,
        );
      }
      if (songs.isNotEmpty) {
        // Play songs in sequential album tracklist order
        if (PlaybackController.instance.isShuffleEnabled) {
          await PlaybackController.instance.toggleShuffle();
        }
        await PlaybackController.instance.playSong(
          songs.first,
          queue: songs,
        );
        if (mounted) {
          Navigator.of(context).push(PlayerScreen.route());
        }
      }
    } catch (e) {
      debugPrint('Error playing album songs in order: $e');
    }
  }

  Future<void> _handleSongTap(Song song) async {
    _searchFocusNode.unfocus();
    List<Song> relatedQueue = const [];

    try {
      final hasAlbum = song.album != null &&
          song.album!.trim().isNotEmpty &&
          song.album != '<Desconocido>' &&
          song.album != 'Unknown Album';
      if (hasAlbum) {
        final albumSongs = await _songDao.getSongsByAlbum(
          song.album!.trim(),
          artist: song.albumArtist ?? song.artist,
          albumId: song.albumId,
        );
        if (albumSongs.length > 1) {
          relatedQueue = albumSongs;
        }
      }

      if (relatedQueue.isEmpty) {
        final hasArtist = song.artist != null &&
            song.artist!.trim().isNotEmpty &&
            song.artist != '<Desconocido>' &&
            song.artist != 'Unknown Artist';
        if (hasArtist) {
          final artistSongs = await _songDao.getSongsByArtist(song.artist!.trim());
          if (artistSongs.length > 1) {
            relatedQueue = artistSongs;
          }
        }
      }
    } catch (_) {}

    if (relatedQueue.isEmpty) {
      relatedQueue = _searchEngine.resultsGroup.matchedSongs.isNotEmpty
          ? _searchEngine.resultsGroup.matchedSongs
          : [song];
    }

    PlaybackController.instance.playSong(
      song,
      queue: relatedQueue,
    );
    if (mounted) {
      Navigator.of(context).push(PlayerScreen.route());
    }
  }

  void _handleTopSongCardTap(Song song) {
    _searchFocusNode.unfocus();
    final albumName = (song.album != null &&
            song.album!.trim().isNotEmpty &&
            song.album != '<Desconocido>')
        ? song.album!.trim()
        : context.l10n.common.unknownAlbum;

    Navigator.of(context).push(
      AlbumDetailScreen.route(
        albumName: albumName,
        artistName: song.artist,
        albumId: song.albumId,
        representativeSongId: song.mediaStoreId,
      ),
    );
  }

  /// Resets search query, engine results, and scroll offset back to initial state.
  /// Triggered strictly when the user taps the search button twice in a row on the bottom nav.
  void _onSearchReset() {
    if (!mounted) return;
    _searchController.clear();
    _searchEngine.clear();
    _searchFocusNode.unfocus();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
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
    NavigationController.instance.setSearchInterceptsBack(false);
    _searchFocusNode.removeListener(_syncSearchBackInterception);
    _searchController.removeListener(_syncSearchBackInterception);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _searchEngine.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isTabVisible = TickerMode.valuesOf(context).enabled;
    NavigationController.instance.setSearchInterceptsBack(
      isTabVisible && (_searchFocusNode.hasFocus || _searchController.text.isNotEmpty),
    );

    return PopScope(
      canPop: !isTabVisible || (!_searchFocusNode.hasFocus && _searchController.text.isEmpty),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // 1. If keyboard / search bar is focused, just close keyboard
        if (_searchFocusNode.hasFocus) {
          NavigationController.instance.notifySearchHandledBack();
          _searchFocusNode.unfocus();
          return;
        }

        // 2. If keyboard is already closed and in query mode, clear query
        if (_searchController.text.isNotEmpty) {
          NavigationController.instance.notifySearchHandledBack();
          _searchController.clear();
          _searchEngine.clear();
          _searchFocusNode.unfocus();
          return;
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        backgroundColor: AppColors.bottomNavBackground,
        body: Stack(
          children: [
            const AmbientParticlesCanvas(),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SearchHeader(isMetro: true),
                  AppSearchBar(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (text) => _searchEngine.onQueryChanged(text),
                    onClear: () => _searchEngine.clear(),
                  ),
                  const SizedBox(height: 8.0),
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: [
                            0.0,
                            0.04,
                            0.92,
                            1.0,
                          ],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: SearchResultsList(
                        key: const ValueKey('search_results_list'),
                        controller: _searchEngine,
                        scrollController: _scrollController,
                        onSongTap: _handleSongTap,
                        onSongPlayTap: _handleSongTap,
                        onTopSongCardTap: _handleTopSongCardTap,
                        onAlbumTap: _handleAlbumTap,
                        onAlbumPlayTap: _handleAlbumPlayTap,
                        onArtistTap: _handleArtistTap,
                        onArtistPlayTap: _handleArtistPlayTap,
                        onRecentItemTap: _handleRecentItemTap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: widget.showBottomNav
            ? const AppBottomNav(
                currentIndex: 1,
              )
            : null,
      ),
    );
  }
}

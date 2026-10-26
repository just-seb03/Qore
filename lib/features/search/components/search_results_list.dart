/// File: search_results_list.dart
/// Description: Spotify-styled dynamic search results coordinator.
/// Orchestrates Top Result, Songs, Albums, and Artists sections dynamically based on
/// entity relevance, while delegating state views (empty, loading, no-results) to
/// dedicated, cohesive components.
///
/// Components / Classes / Functions:
/// - SearchResultsList: Reactive coordinator widget for search states and result sections.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/search/models/recent_search_item.dart';
import 'package:project_anima/core/search/models/search_entity_type.dart';
import 'package:project_anima/core/search/models/search_results_group.dart';
import 'package:project_anima/core/search/music_search_controller.dart';
import 'package:project_anima/core/search/recent_search_controller.dart';
import 'package:project_anima/features/search/components/cards/search_top_result_card.dart';
import 'package:project_anima/features/search/components/sections/search_albums_section.dart';
import 'package:project_anima/features/search/components/sections/search_artists_section.dart';
import 'package:project_anima/features/search/components/sections/search_songs_section.dart';
import 'package:project_anima/features/search/components/states/search_empty_view.dart';
import 'package:project_anima/features/search/components/states/search_loading_view.dart';
import 'package:project_anima/features/search/components/states/search_no_results_view.dart';

/// Dynamic, Spotify-style multi-tier search results view.
class SearchResultsList extends StatelessWidget {
  /// The reactive search engine controller.
  final MusicSearchController controller;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  /// Callback when a song is tapped.
  final ValueChanged<Song>? onSongTap;

  /// Callback when the Play button on a Top Result song is tapped.
  final ValueChanged<Song>? onSongPlayTap;

  /// Callback when the card body of a Top Result song is tapped.
  final ValueChanged<Song>? onTopSongCardTap;

  /// Callback when an album is tapped.
  final ValueChanged<AlbumDiscoveryItem>? onAlbumTap;

  /// Callback when the Play button on a Top Result album is tapped.
  final ValueChanged<AlbumDiscoveryItem>? onAlbumPlayTap;

  /// Callback when an artist is tapped.
  final ValueChanged<ArtistDiscoveryItem>? onArtistTap;

  /// Callback when the Play button on a Top Result artist is tapped.
  final ValueChanged<ArtistDiscoveryItem>? onArtistPlayTap;

  /// Callback when a recent search item is tapped.
  final ValueChanged<RecentSearchItem>? onRecentItemTap;

  /// Optional injected RecentSearchController for testing and customization.
  final RecentSearchController? recentSearchController;

  const SearchResultsList({
    super.key,
    required this.controller,
    this.scrollController,
    this.onSongTap,
    this.onSongPlayTap,
    this.onTopSongCardTap,
    this.onAlbumTap,
    this.onAlbumPlayTap,
    this.onArtistTap,
    this.onArtistPlayTap,
    this.onRecentItemTap,
    this.recentSearchController,
  });

  RecentSearchController get _recentSearchController =>
      recentSearchController ?? RecentSearchController.instance;

  void _handleSongTap(Song song) {
    onSongTap?.call(song);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        _recentSearchController.addSong(song);
      });
    });
  }

  void _handleSongPlayTap(Song song) {
    if (onSongPlayTap != null) {
      onSongPlayTap!.call(song);
    } else {
      _handleSongTap(song);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        _recentSearchController.addSong(song);
      });
    });
  }

  void _handleTopSongCardTap(Song song) {
    if (onTopSongCardTap != null) {
      onTopSongCardTap!.call(song);
    } else {
      _handleSongTap(song);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        _recentSearchController.addSong(song);
      });
    });
  }

  void _handleAlbumTap(AlbumDiscoveryItem album) {
    onAlbumTap?.call(album);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        _recentSearchController.addAlbum(album);
      });
    });
  }

  void _handleAlbumPlayTap(AlbumDiscoveryItem album) {
    onAlbumPlayTap?.call(album);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        _recentSearchController.addAlbum(album);
      });
    });
  }

  void _handleArtistTap(ArtistDiscoveryItem artist) {
    onArtistTap?.call(artist);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        _recentSearchController.addArtist(artist);
      });
    });
  }

  void _handleArtistPlayTap(ArtistDiscoveryItem artist) {
    onArtistPlayTap?.call(artist);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        _recentSearchController.addArtist(artist);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final ctrl = controller;
        final results = ctrl.resultsGroup;

        // 1. Initial State: Empty query
        if (ctrl.query.isEmpty) {
          return SearchEmptyView(
            scrollController: scrollController,
            onRecentItemTap: onRecentItemTap,
          );
        }

        // 2. Loading state while waiting for debounce/search
        if (ctrl.isLoading && results.isEmpty) {
          return const SearchLoadingView();
        }

        // 3. No matches found
        if (results.isEmpty) {
          return SearchNoResultsView(query: ctrl.query);
        }

        // 4. Render Dynamic Spotify-style Hierarchical Sections
        return ListView(
          controller: scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 8.0, bottom: 160.0),
          children: _buildDynamicSections(results),
        );
      },
    );
  }

  /// Builds the dynamic component order based on the dominant entity type.
  List<Widget> _buildDynamicSections(SearchResultsGroup results) {
    final List<Widget> widgets = [];
    final primaryType = results.primaryType;
    final topResult = results.topResult;

    // Helper builders for secondary sections
    Widget? buildSongsSection() {
      if (results.matchedSongs.isEmpty) return null;
      return SearchSongsSection(
        songs: results.matchedSongs,
        onSongTap: _handleSongTap,
      );
    }

    Widget? buildAlbumsSection() {
      if (results.matchedAlbums.isEmpty) return null;
      return SearchAlbumsSection(
        albums: results.matchedAlbums,
        onAlbumTap: _handleAlbumTap,
      );
    }

    Widget? buildArtistsSection() {
      if (results.matchedArtists.isEmpty) return null;
      return SearchArtistsSection(
        artists: results.matchedArtists,
        onArtistTap: _handleArtistTap,
      );
    }

    // 1. Prominent Top Result Card
    final topArtist = topResult?.artist;
    final topAlbum = topResult?.album;
    final topSong = topResult?.song;

    if (primaryType == SearchEntityType.artist && topArtist != null) {
      widgets.add(
        SearchTopResultCard.artist(
          artist: topArtist,
          onTap: () => _handleArtistTap(topArtist),
          onPlayTap: () => _handleArtistPlayTap(topArtist),
        ),
      );
    } else if (primaryType == SearchEntityType.album && topAlbum != null) {
      widgets.add(
        SearchTopResultCard.album(
          album: topAlbum,
          onTap: () => _handleAlbumTap(topAlbum),
          onPlayTap: () => _handleAlbumPlayTap(topAlbum),
        ),
      );
    } else if (topSong != null) {
      widgets.add(
        SearchTopResultCard.song(
          song: topSong,
          onTap: () => _handleTopSongCardTap(topSong),
          onPlayTap: () => _handleSongPlayTap(topSong),
        ),
      );
    }

    // 2. Secondary Sections Ordered By Dominant Entity
    final List<Widget?> orderedSections = [];

    if (primaryType == SearchEntityType.artist) {
      orderedSections.addAll([
        buildSongsSection(),
        buildAlbumsSection(),
        buildArtistsSection(),
      ]);
    } else if (primaryType == SearchEntityType.album) {
      orderedSections.addAll([
        buildSongsSection(),
        buildArtistsSection(),
        buildAlbumsSection(),
      ]);
    } else {
      orderedSections.addAll([
        buildSongsSection(),
        buildArtistsSection(),
        buildAlbumsSection(),
      ]);
    }

    // 3. Assemble with uniform spacing
    for (final section in orderedSections) {
      if (section != null) {
        if (widgets.isNotEmpty) {
          widgets.add(const SizedBox(height: 24.0));
        }
        widgets.add(section);
      }
    }

    return widgets;
  }
}

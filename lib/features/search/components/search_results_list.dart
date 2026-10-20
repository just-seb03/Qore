/// File: search_results_list.dart
/// Description: Spotify-styled dynamic search results coordinator.
/// Orchestrates SearchArtistComponent, SearchAlbumComponent, and SearchSongComponent,
/// dynamically prioritizing the dominant category (Artist, Album, or Song) as the Top Result,
/// followed by secondary sections (up to 5 songs, albums, and artists).
///
/// Components / Classes / Functions:
/// - SearchResultsList: Reactive scrollable results list orchestrating the three search components.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/search/models/recent_search_item.dart';
import 'package:project_anima/core/search/models/search_entity_type.dart';
import 'package:project_anima/core/search/music_search_controller.dart';
import 'package:project_anima/core/search/recent_search_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/search/components/search_album_component.dart';
import 'package:project_anima/features/search/components/search_artist_component.dart';
import 'package:project_anima/features/search/components/search_recent_list.dart';
import 'package:project_anima/features/search/components/search_song_component.dart';

/// Dynamic, Spotify-style multi-tier search results view.
class SearchResultsList extends StatelessWidget {
  final MusicSearchController controller;
  final ScrollController? scrollController;
  final ValueChanged<Song>? onSongTap;
  final ValueChanged<AlbumDiscoveryItem>? onAlbumTap;
  final ValueChanged<ArtistDiscoveryItem>? onArtistTap;
  final ValueChanged<RecentSearchItem>? onRecentItemTap;

  const SearchResultsList({
    super.key,
    required this.controller,
    this.scrollController,
    this.onSongTap,
    this.onAlbumTap,
    this.onArtistTap,
    this.onRecentItemTap,
  });

  static final TextStyle _emptyHeaderStyle = GoogleFonts.zenDots(
    fontSize: 13.0,
    letterSpacing: 1.5,
    color: AppColors.futuristicWhite.withValues(alpha: 0.35),
  );

  static final TextStyle _emptySubtitleStyle = GoogleFonts.inconsolata(
    fontSize: 13.5,
    color: AppColors.futuristicWhite.withValues(alpha: 0.25),
  );

  static final TextStyle _noResultsHeaderStyle = GoogleFonts.zenDots(
    fontSize: 13.0,
    letterSpacing: 1.2,
    color: AppColors.futuristicWhite.withValues(alpha: 0.4),
  );

  static final TextStyle _noResultsSubtitleStyle = GoogleFonts.inconsolata(
    fontSize: 13.5,
    color: AppColors.futuristicWhite.withValues(alpha: 0.3),
  );

  void _handleSongTap(Song song) {
    RecentSearchController.instance.addSong(song);
    onSongTap?.call(song);
  }

  void _handleAlbumTap(AlbumDiscoveryItem album) {
    RecentSearchController.instance.addAlbum(album);
    onAlbumTap?.call(album);
  }

  void _handleArtistTap(ArtistDiscoveryItem artist) {
    RecentSearchController.instance.addArtist(artist);
    onArtistTap?.call(artist);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final ctrl = controller;
        final results = ctrl.resultsGroup;

        // 1. Initial State: Empty query -> Show Recent Searches if present, else fallback placeholder
        if (ctrl.query.isEmpty) {
          return ListenableBuilder(
            listenable: RecentSearchController.instance,
            builder: (context, _) {
              final recentItems = RecentSearchController.instance.items;
              if (recentItems.isNotEmpty) {
                return SearchRecentList(
                  scrollController: scrollController,
                  onItemTap: (item) {
                    if (onRecentItemTap != null) {
                      onRecentItemTap!(item);
                    } else if (item.type == RecentSearchType.song) {
                      _handleSongTap(
                        Song(
                          mediaStoreId: item.representativeSongId,
                          title: item.title,
                          artist: item.subtitle.replaceFirst('Canción • ', ''),
                          album: '',
                          albumId: item.albumId,
                          duration: 0,
                          path: '',
                          dateModified: 0,
                        ),
                      );
                    }
                  },
                );
              }

              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.manage_search_rounded,
                      size: 64.0,
                      color: AppColors.futuristicWhite.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'BUSCAR EN LA BIBLIOTECA',
                      style: _emptyHeaderStyle,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Títulos, artistas o álbumes indexados',
                      style: _emptySubtitleStyle,
                    ),
                  ],
                ),
              );
            },
          );
        }

        // 2. Loading state while waiting for debounce/search
        if (ctrl.isLoading && results.isEmpty) {
          return const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: AppColors.futuristicWhite,
              ),
            ),
          );
        }

        // 3. No matches found across any category
        if (results.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 56.0,
                    color: AppColors.futuristicWhite.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'SIN RESULTADOS',
                    style: _noResultsHeaderStyle,
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    'No encontramos coincidencias para "${ctrl.query}"',
                    textAlign: TextAlign.center,
                    style: _noResultsSubtitleStyle,
                  ),
                ],
              ),
            ),
          );
        }

        // 4. Render Dynamic Spotify-style Hierarchical Sections
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.only(top: 8.0, bottom: 32.0),
          children: _buildDynamicSections(results),
        );
      },
    );
  }

  /// Builds the dynamic component order based on the dominant entity type.
  List<Widget> _buildDynamicSections(dynamic results) {
    final List<Widget> widgets = [];
    final primaryType = results.primaryType;
    final topResult = results.topResult;

    if (primaryType == SearchEntityType.artist) {
      // 1. Dominant Artist Top Result
      if (topResult?.artist != null) {
        widgets.add(
          SearchArtistComponent(
            topResultArtist: topResult!.artist,
            isTopResultOnly: true,
            onArtistTap: _handleArtistTap,
          ),
        );
        widgets.add(const SizedBox(height: 20.0));
      }

      // 2. Secondary Songs (Up to 5)
      if (results.matchedSongs.isNotEmpty) {
        widgets.add(
          SearchSongComponent(
            songs: results.matchedSongs,
            onSongTap: _handleSongTap,
          ),
        );
        widgets.add(const SizedBox(height: 24.0));
      }

      // 3. Secondary Albums
      if (results.matchedAlbums.isNotEmpty) {
        widgets.add(
          SearchAlbumComponent(
            secondaryAlbums: results.matchedAlbums,
            onAlbumTap: _handleAlbumTap,
          ),
        );
        widgets.add(const SizedBox(height: 24.0));
      }

      // 4. Secondary Artists
      if (results.matchedArtists.isNotEmpty) {
        widgets.add(
          SearchArtistComponent(
            secondaryArtists: results.matchedArtists,
            onArtistTap: _handleArtistTap,
          ),
        );
      }
    } else if (primaryType == SearchEntityType.album) {
      // 1. Dominant Album Top Result
      if (topResult?.album != null) {
        widgets.add(
          SearchAlbumComponent(
            topResultAlbum: topResult!.album,
            isTopResultOnly: true,
            onAlbumTap: _handleAlbumTap,
          ),
        );
        widgets.add(const SizedBox(height: 20.0));
      }

      // 2. Secondary Songs (Up to 5)
      if (results.matchedSongs.isNotEmpty) {
        widgets.add(
          SearchSongComponent(
            songs: results.matchedSongs,
            onSongTap: _handleSongTap,
          ),
        );
        widgets.add(const SizedBox(height: 24.0));
      }

      // 3. Artists
      if (results.matchedArtists.isNotEmpty) {
        widgets.add(
          SearchArtistComponent(
            secondaryArtists: results.matchedArtists,
            onArtistTap: _handleArtistTap,
          ),
        );
        widgets.add(const SizedBox(height: 24.0));
      }

      // 4. Secondary Albums
      if (results.matchedAlbums.isNotEmpty) {
        widgets.add(
          SearchAlbumComponent(
            secondaryAlbums: results.matchedAlbums,
            onAlbumTap: _handleAlbumTap,
          ),
        );
      }
    } else {
      // 1. Dominant Song Top Result
      if (topResult?.song != null) {
        widgets.add(
          SearchSongComponent(
            topResultSong: topResult!.song,
            isTopResultOnly: true,
            onSongTap: _handleSongTap,
          ),
        );
        widgets.add(const SizedBox(height: 20.0));
      }

      // 2. Secondary Songs (Up to 5)
      if (results.matchedSongs.isNotEmpty) {
        widgets.add(
          SearchSongComponent(
            songs: results.matchedSongs,
            onSongTap: _handleSongTap,
          ),
        );
        widgets.add(const SizedBox(height: 24.0));
      }

      // 3. Artists
      if (results.matchedArtists.isNotEmpty) {
        widgets.add(
          SearchArtistComponent(
            secondaryArtists: results.matchedArtists,
            onArtistTap: _handleArtistTap,
          ),
        );
        widgets.add(const SizedBox(height: 24.0));
      }

      // 4. Albums
      if (results.matchedAlbums.isNotEmpty) {
        widgets.add(
          SearchAlbumComponent(
            secondaryAlbums: results.matchedAlbums,
            onAlbumTap: _handleAlbumTap,
          ),
        );
      }
    }

    return widgets;
  }
}


/// File: search_results_list.dart
/// Description: Paginated, zero-jank search results list component for SearchScreen.
/// Displays indexed audio tracks with dual-tier 100x100 thumbnails (AnimaArtworkImage),
/// formatted duration, and infinite scroll pagination driven by MusicSearchController.
///
/// Components / Classes / Functions:
/// - SearchResultsList: Reactive scrollable results list with infinite loading.
/// - SearchSongTile: Individual song item tile enforcing 100x100 thumbnail memory limits.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/search/music_search_controller.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Scrollable results list connected to [MusicSearchController] with infinite scroll.
class SearchResultsList extends StatefulWidget {
  final MusicSearchController controller;
  final ValueChanged<Song>? onSongTap;

  const SearchResultsList({
    super.key,
    required this.controller,
    this.onSongTap,
  });

  @override
  State<SearchResultsList> createState() => _SearchResultsListState();
}

class _SearchResultsListState extends State<SearchResultsList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // Trigger loadMore when scrolled to 80% of current list extent
    if (currentScroll >= (maxScroll * 0.8)) {
      widget.controller.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;

        // 1. Initial State: Empty query
        if (ctrl.query.isEmpty) {
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
                  style: GoogleFonts.zenDots(
                    fontSize: 13.0,
                    letterSpacing: 1.5,
                    color: AppColors.futuristicWhite.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Títulos, artistas o álbumes indexados',
                  style: GoogleFonts.inconsolata(
                    fontSize: 13.5,
                    color: AppColors.futuristicWhite.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          );
        }

        // 2. Loading initial search results
        if (ctrl.isLoading && ctrl.results.isEmpty) {
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

        // 3. No matches found
        if (ctrl.results.isEmpty) {
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
                    style: GoogleFonts.zenDots(
                      fontSize: 13.0,
                      letterSpacing: 1.2,
                      color: AppColors.futuristicWhite.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    'No encontramos coincidencias para "${ctrl.query}"',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inconsolata(
                      fontSize: 13.5,
                      color: AppColors.futuristicWhite.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 4. Render Paginated Results List
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: ctrl.results.length + (ctrl.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == ctrl.results.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: AppColors.futuristicWhite,
                    ),
                  ),
                ),
              );
            }

            final song = ctrl.results[index];
            return SearchSongTile(
              song: song,
              onTap: () => widget.onSongTap?.call(song),
            );
          },
        );
      },
    );
  }
}

/// Individual item tile rendering track metadata and 100x100 thumbnail.
class SearchSongTile extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;

  const SearchSongTile({
    super.key,
    required this.song,
    this.onTap,
  });

  String _formatDuration(int ms) {
    final int totalSeconds = ms ~/ 1000;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                // Module 6 Dual-Tier thumbnail (100x100 cache protected)
                AnimaArtworkImage(
                  mediaStoreId: song.mediaStoreId,
                  albumId: song.albumId,
                  width: 48.0,
                  height: 48.0,
                  borderRadius: 8.0,
                  isThumbnail: true,
                ),
                const SizedBox(width: 14.0),
                // Song Title & Artist / Album metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inconsolata(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.futuristicWhite,
                        ),
                      ),
                      const SizedBox(height: 3.0),
                      Text(
                        '${song.artist ?? '<Desconocido>'} • ${song.album ?? '<Desconocido>'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inconsolata(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w400,
                          color: AppColors.futuristicWhite.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10.0),
                // Formatted Duration
                Text(
                  _formatDuration(song.duration),
                  style: GoogleFonts.inconsolata(
                    fontSize: 12.5,
                    color: AppColors.futuristicWhite.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// File: library_genres_list.dart
/// Description: Scrollable list widget displaying music genres in the Library styled
/// in Windows Phone Metro Jump-List design language. Features an interactive alphabet
/// scrubber rail (#, A-Z) and navigation to GenreDetailScreen.
///
/// Components / Classes / Functions:
/// - LibraryGenresList: Stateful coordinator widget managing genre list rendering and indexing.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/genre_discovery_item.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/library/components/common/metro_alphabet_scroller.dart';
import 'package:project_anima/features/library/components/genres/genre_detail_screen.dart';
import 'package:project_anima/features/library/components/genres/library_genre_tile.dart';

/// List widget rendering user genres in an authentic Metro jump-list.
class LibraryGenresList extends StatefulWidget {
  /// Optional pre-loaded genres (used for testing or pre-fetching).
  final List<GenreDiscoveryItem>? genres;

  /// Optional SongDao for dependency injection.
  final SongDao? songDao;

  /// Optional custom callback when a genre is tapped.
  final ValueChanged<GenreDiscoveryItem>? onGenreTap;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  const LibraryGenresList({
    super.key,
    this.genres,
    this.songDao,
    this.onGenreTap,
    this.scrollController,
  });

  @override
  State<LibraryGenresList> createState() => _LibraryGenresListState();
}

class _LibraryGenresListState extends State<LibraryGenresList> {
  late final SongDao _songDao;
  List<GenreDiscoveryItem>? _genres;
  bool _isLoading = true;

  static final TextStyle _emptyHeaderStyle = AppFonts.segoe(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.futuristicWhite.withValues(alpha: 0.35),
  );

  static final TextStyle _emptySubtitleStyle = AppFonts.segoe(
    fontSize: 13.5,
    color: AppColors.futuristicWhite.withValues(alpha: 0.25),
  );

  @override
  void initState() {
    super.initState();
    _songDao = widget.songDao ?? SongDao();
    if (widget.genres != null) {
      _genres = widget.genres;
      _isLoading = false;
    } else {
      _loadGenres();
    }
  }

  @override
  void didUpdateWidget(covariant LibraryGenresList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.genres != null && widget.genres != oldWidget.genres) {
      setState(() {
        _genres = widget.genres;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await _songDao.getLibraryGenres();
      if (mounted) {
        setState(() {
          _genres = genres;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [LibraryGenresList] Error loading library genres: $e');
      if (mounted) {
        setState(() {
          _genres = [];
          _isLoading = false;
        });
      }
    }
  }

  void _handleTap(GenreDiscoveryItem genre) {
    if (widget.onGenreTap != null) {
      widget.onGenreTap!(genre);
      return;
    }

    Navigator.of(context).push(GenreDetailScreen.route(genre));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.navIndicator,
        ),
      );
    }

    final genres = _genres ?? const [];
    if (genres.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.category_outlined,
                size: 56.0,
                color: AppColors.futuristicWhite.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 16.0),
              Text(
                context.l10n.library.emptyGenresTitle,
                textAlign: TextAlign.center,
                style: _emptyHeaderStyle,
              ),
              const SizedBox(height: 6.0),
              Text(
                context.l10n.library.emptyGenresSubtitle,
                textAlign: TextAlign.center,
                style: _emptySubtitleStyle,
              ),
            ],
          ),
        ),
      );
    }

    return MetroAlphabetScroller<GenreDiscoveryItem>(
      items: genres,
      scrollController: widget.scrollController,
      titleSelector: (genre) => genre.name,
      itemExtent: LibraryGenreTile.tileHeight,
      itemBuilder: (context, index, genre, isCurrentSection) {
        return LibraryGenreTile(
          genre: genre,
          onTap: () => _handleTap(genre),
        );
      },
    );
  }
}

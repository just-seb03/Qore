/// File: library_artists_list.dart
/// Description: Scrollable list widget displaying user artists in the Library.
/// Features asynchronous retrieval from SongDao, empty state invitation,
/// and navigation to ArtistDetailScreen.
///
/// Components / Classes / Functions:
/// - LibraryArtistsList: Stateful coordinator widget managing artist list rendering.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';
import 'package:project_anima/features/library/components/artists/library_artist_tile.dart';

/// List widget rendering user artists in alphabetical order.
class LibraryArtistsList extends StatefulWidget {
  /// Optional pre-loaded artists (used for testing or pre-fetching).
  final List<ArtistDiscoveryItem>? artists;

  /// Optional SongDao for dependency injection.
  final SongDao? songDao;

  /// Optional custom callback when an artist is tapped.
  final ValueChanged<ArtistDiscoveryItem>? onArtistTap;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  const LibraryArtistsList({
    super.key,
    this.artists,
    this.songDao,
    this.onArtistTap,
    this.scrollController,
  });

  @override
  State<LibraryArtistsList> createState() => _LibraryArtistsListState();
}

class _LibraryArtistsListState extends State<LibraryArtistsList> {
  late final SongDao _songDao;
  List<ArtistDiscoveryItem>? _artists;
  bool _isLoading = true;

  static final TextStyle _emptyHeaderStyle = GoogleFonts.zenDots(
    fontSize: 13.0,
    letterSpacing: 1.5,
    color: AppColors.futuristicWhite.withValues(alpha: 0.35),
  );

  static final TextStyle _emptySubtitleStyle = GoogleFonts.inconsolata(
    fontSize: 13.5,
    color: AppColors.futuristicWhite.withValues(alpha: 0.25),
  );

  @override
  void initState() {
    super.initState();
    _songDao = widget.songDao ?? SongDao();
    if (widget.artists != null) {
      _artists = widget.artists;
      _isLoading = false;
    } else {
      _loadArtists();
    }
  }

  @override
  void didUpdateWidget(covariant LibraryArtistsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.artists != null && widget.artists != oldWidget.artists) {
      setState(() {
        _artists = widget.artists;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadArtists() async {
    try {
      final artists = await _songDao.getLibraryArtists();
      if (mounted) {
        setState(() {
          _artists = artists;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [LibraryArtistsList] Error loading library artists: $e');
      if (mounted) {
        setState(() {
          _artists = [];
          _isLoading = false;
        });
      }
    }
  }

  void _handleTap(ArtistDiscoveryItem artist) {
    if (widget.onArtistTap != null) {
      widget.onArtistTap!(artist);
      return;
    }

    Navigator.of(context).push(ArtistDetailScreen.route(artist.name));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.navIndicator,
        ),
      );
    }

    final artists = _artists ?? const [];
    if (artists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 56.0,
                color: AppColors.futuristicWhite.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 16.0),
              Text(
                'NO ARTISTS FOUND',
                textAlign: TextAlign.center,
                style: _emptyHeaderStyle,
              ),
              const SizedBox(height: 6.0),
              Text(
                'Add music to your device to see your artists here',
                textAlign: TextAlign.center,
                style: _emptySubtitleStyle,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.only(
        top: 8.0,
        bottom: 96.0,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return LibraryArtistTile(
          artist: artist,
          onTap: () => _handleTap(artist),
        );
      },
    );
  }
}

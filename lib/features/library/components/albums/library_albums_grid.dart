/// File: library_albums_grid.dart
/// Description: Grid layout widget displaying 2 album cards per row in the Library.
/// Features asynchronous retrieval from SongDao (filtered by album artist to avoid duplicates),
/// empty state invitation, and seamless routing to AlbumDetailScreen.
///
/// Components / Classes / Functions:
/// - LibraryAlbumsGrid: Stateful coordinator widget managing album grid rendering.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';
import 'package:project_anima/features/library/components/albums/library_album_card.dart';

/// Grid widget rendering user albums 2 per row.
class LibraryAlbumsGrid extends StatefulWidget {
  /// Optional pre-loaded albums (used for testing or pre-fetching).
  final List<AlbumDiscoveryItem>? albums;

  /// Optional SongDao for dependency injection.
  final SongDao? songDao;

  /// Optional custom callback when an album is tapped.
  final ValueChanged<AlbumDiscoveryItem>? onAlbumTap;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  const LibraryAlbumsGrid({
    super.key,
    this.albums,
    this.songDao,
    this.onAlbumTap,
    this.scrollController,
  });

  @override
  State<LibraryAlbumsGrid> createState() => _LibraryAlbumsGridState();
}

class _LibraryAlbumsGridState extends State<LibraryAlbumsGrid> {
  late final SongDao _songDao;
  List<AlbumDiscoveryItem>? _albums;
  bool _isLoading = true;

  static final TextStyle _emptyHeaderStyle = GoogleFonts.inconsolata(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
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
    if (widget.albums != null) {
      _albums = widget.albums;
      _isLoading = false;
    } else {
      _loadAlbums();
    }
  }

  @override
  void didUpdateWidget(covariant LibraryAlbumsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.albums != null && widget.albums != oldWidget.albums) {
      setState(() {
        _albums = widget.albums;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAlbums() async {
    try {
      final albums = await _songDao.getLibraryAlbums();
      final repIds = albums.map((a) => a.representativeSongId).toList();
      ArtworkService.instance.prioritizeSongIds(repIds);
      if (mounted) {
        setState(() {
          _albums = albums;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [LibraryAlbumsGrid] Error loading library albums: $e');
      if (mounted) {
        setState(() {
          _albums = [];
          _isLoading = false;
        });
      }
    }
  }

  void _handleTap(AlbumDiscoveryItem album) {
    if (widget.onAlbumTap != null) {
      widget.onAlbumTap!(album);
      return;
    }

    Navigator.of(context).push(
      AlbumDetailScreen.route(
        albumName: album.name,
        artistName: album.artist,
        albumId: album.albumId,
        representativeSongId: album.representativeSongId,
      ),
    );
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

    final albums = _albums ?? const [];
    if (albums.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.album_outlined,
                size: 56.0,
                color: AppColors.futuristicWhite.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 16.0),
              Text(
                'NO ALBUMS FOUND',
                textAlign: TextAlign.center,
                style: _emptyHeaderStyle,
              ),
              const SizedBox(height: 6.0),
              Text(
                'Add music to your device to see your albums here',
                textAlign: TextAlign.center,
                style: _emptySubtitleStyle,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 12.0,
        bottom: 96.0,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 20.0,
        childAspectRatio: 0.74,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return LibraryAlbumCard(
          album: album,
          onTap: () => _handleTap(album),
        );
      },
    );
  }
}

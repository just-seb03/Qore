/// File: library_albums_grid.dart
/// Description: Album collection view for the Library styled in Windows Phone Metro Jump-List
/// design language. Features a vertical list of album tiles with sharp square artwork,
/// and an interactive alphabet scrubber rail (#, A-Z) with kinetic depth translation.
///
/// Components / Classes / Functions:
/// - LibraryAlbumsGrid: Stateful coordinator widget managing album list rendering and indexing.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';
import 'package:project_anima/features/library/components/albums/library_album_card.dart';
import 'package:project_anima/features/library/components/common/metro_alphabet_scroller.dart';

/// Album collection view rendering albums in an authentic Metro jump-list.
class LibraryAlbumsGrid extends StatefulWidget {
  /// Optional pre-loaded albums (used for testing or pre-fetching).
  final List<AlbumDiscoveryItem>? albums;

  /// Optional SongDao for dependency injection.
  final SongDao? songDao;

  /// Optional custom callback when an album is tapped.
  final ValueChanged<AlbumDiscoveryItem>? onAlbumTap;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  /// When true, displays only single-track releases (`songCount == 1`).
  final bool singlesOnly;

  const LibraryAlbumsGrid({
    super.key,
    this.albums,
    this.songDao,
    this.onAlbumTap,
    this.scrollController,
    this.singlesOnly = false,
  });

  @override
  State<LibraryAlbumsGrid> createState() => _LibraryAlbumsGridState();
}

class _LibraryAlbumsGridState extends State<LibraryAlbumsGrid> {
  late final SongDao _songDao;
  List<AlbumDiscoveryItem>? _albums;
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

  List<AlbumDiscoveryItem> _applyFilter(List<AlbumDiscoveryItem> source) {
    if (widget.singlesOnly) {
      return source.where((album) => album.songCount == 1).toList();
    }
    return source.where((album) => album.songCount > 1).toList();
  }

  @override
  void initState() {
    super.initState();
    _songDao = widget.songDao ?? SongDao();
    if (widget.albums != null) {
      _albums = _applyFilter(widget.albums!);
      _isLoading = false;
    } else {
      _loadAlbums();
    }
  }

  @override
  void didUpdateWidget(covariant LibraryAlbumsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.albums != null &&
        (widget.albums != oldWidget.albums ||
            widget.singlesOnly != oldWidget.singlesOnly)) {
      setState(() {
        _albums = _applyFilter(widget.albums!);
        _isLoading = false;
      });
    } else if (widget.albums == null &&
        widget.singlesOnly != oldWidget.singlesOnly) {
      _loadAlbums();
    }
  }

  Future<void> _loadAlbums() async {
    try {
      final albums = _applyFilter(await _songDao.getLibraryAlbums());
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

  Future<void> _handleTap(AlbumDiscoveryItem album) async {
    if (widget.onAlbumTap != null) {
      widget.onAlbumTap!(album);
      return;
    }

    if (widget.singlesOnly) {
      try {
        final singles = _albums ?? const [];
        final ids = singles
            .map((a) => a.representativeSongId)
            .where((id) => id > 0)
            .toList();
        final songs = await _songDao.getSongsByMediaStoreIds(ids);
        Song? target;
        for (final s in songs) {
          if (s.mediaStoreId == album.representativeSongId) {
            target = s;
            break;
          }
        }
        target ??= await _songDao.getSongByMediaStoreId(album.representativeSongId);
        if (target == null) return;

        final queue = songs.isNotEmpty ? songs : [target];
        await PlaybackController.instance.playSong(target, queue: queue);
      } catch (e) {
        debugPrint('⚠️ [LibraryAlbumsGrid] Error playing single: $e');
      }
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
      return Center(
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
                widget.singlesOnly
                    ? context.l10n.library.emptySinglesTitle
                    : context.l10n.library.emptyAlbumsTitle,
                textAlign: TextAlign.center,
                style: _emptyHeaderStyle,
              ),
              const SizedBox(height: 6.0),
              Text(
                widget.singlesOnly
                    ? context.l10n.library.emptySinglesSubtitle
                    : context.l10n.library.emptyAlbumsSubtitle,
                textAlign: TextAlign.center,
                style: _emptySubtitleStyle,
              ),
            ],
          ),
        ),
      );
    }

    return MetroAlphabetScroller<AlbumDiscoveryItem>(
      items: albums,
      scrollController: widget.scrollController,
      titleSelector: (album) => album.name,
      itemExtent: LibraryAlbumCard.tileHeight,
      itemBuilder: (context, index, album, isCurrentSection) {
        return LibraryAlbumCard(
          album: album,
          isListTile: true,
          onTap: () => _handleTap(album),
        );
      },
    );
  }
}

/// File: library_songs_list.dart
/// Description: Scrollable list widget displaying all user tracks in the Library styled
/// in Windows Phone Metro Jump-List design language. Features an interactive alphabet
/// scrubber rail (#, A-Z), smooth playback coordination, and empty state messaging.
///
/// Components / Classes / Functions:
/// - LibrarySongsList: Stateful coordinator widget managing track list rendering and indexing.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/library/components/common/metro_alphabet_scroller.dart';
import 'package:project_anima/features/library/components/songs/library_song_tile.dart';

/// List widget rendering user songs in an authentic Metro jump-list.
class LibrarySongsList extends StatefulWidget {
  /// Optional pre-loaded songs (used for testing or pre-fetching).
  final List<Song>? songs;

  /// Optional SongDao for dependency injection.
  final SongDao? songDao;

  /// Optional custom callback when a song is tapped.
  final ValueChanged<Song>? onSongTap;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  const LibrarySongsList({
    super.key,
    this.songs,
    this.songDao,
    this.onSongTap,
    this.scrollController,
  });

  @override
  State<LibrarySongsList> createState() => _LibrarySongsListState();
}

class _LibrarySongsListState extends State<LibrarySongsList> {
  late final SongDao _songDao;
  List<Song>? _songs;
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
    if (widget.songs != null) {
      _songs = widget.songs;
      _isLoading = false;
    } else {
      _loadSongs();
    }
  }

  @override
  void didUpdateWidget(covariant LibrarySongsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.songs != null && widget.songs != oldWidget.songs) {
      setState(() {
        _songs = widget.songs;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _songDao.getAllSongs();
      final ids = songs.map((s) => s.id).whereType<int>().toList();
      ArtworkService.instance.prioritizeSongIds(ids);
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [LibrarySongsList] Error loading library songs: $e');
      if (mounted) {
        setState(() {
          _songs = [];
          _isLoading = false;
        });
      }
    }
  }

  void _handleTap(Song song) {
    if (widget.onSongTap != null) {
      widget.onSongTap!(song);
      return;
    }

    final songs = _songs ?? const [];
    PlaybackController.instance.playSong(song, queue: songs);
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

    final songs = _songs ?? const [];
    if (songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.music_note_outlined,
                size: 56.0,
                color: AppColors.futuristicWhite.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 16.0),
              Text(
                context.l10n.library.emptySongsTitle,
                textAlign: TextAlign.center,
                style: _emptyHeaderStyle,
              ),
              const SizedBox(height: 6.0),
              Text(
                context.l10n.library.emptySongsSubtitle,
                textAlign: TextAlign.center,
                style: _emptySubtitleStyle,
              ),
            ],
          ),
        ),
      );
    }

    return MetroAlphabetScroller<Song>(
      items: songs,
      scrollController: widget.scrollController,
      titleSelector: (song) => song.title,
      itemExtent: LibrarySongTile.tileHeight,
      itemBuilder: (context, index, song, isCurrentSection) {
        return LibrarySongTile(
          song: song,
          onTap: () => _handleTap(song),
        );
      },
    );
  }
}

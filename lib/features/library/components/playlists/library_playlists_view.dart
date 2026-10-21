/// File: library_playlists_view.dart
/// Description: Playlists coordinator view within the Library.
/// Queries user playlists from PlaylistDao, displaying an empty placeholder
/// when no playlists exist, or a 2-per-row grid of LibraryPlaylistCard items.
/// Supports inspecting playlists via PlaylistDetailScreen and reloading upon updates.
///
/// Components / Classes / Functions:
/// - LibraryPlaylistsView: Stateful coordinator widget for library playlists.
/// - LibraryPlaylistsViewState: State class handling asynchronous loading and navigation.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/library/components/playlists/library_playlist_card.dart';
import 'package:project_anima/features/library/components/playlists/library_playlists_placeholder.dart';
import 'package:project_anima/features/playlist/screens/playlist_detail_screen.dart';

/// Coordinator view presenting user playlists in the Library tab.
class LibraryPlaylistsView extends StatefulWidget {
  /// Preloaded playlists for dependency injection and testing.
  final List<Playlist>? playlists;

  /// Optional PlaylistDao for dependency injection.
  final PlaylistDao? playlistDao;

  /// Optional SongDao for dependency injection.
  final SongDao? songDao;

  /// Optional callback invoked when a playlist card is tapped.
  final ValueChanged<Playlist>? onPlaylistTap;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  const LibraryPlaylistsView({
    super.key,
    this.playlists,
    this.playlistDao,
    this.songDao,
    this.onPlaylistTap,
    this.scrollController,
  });

  @override
  State<LibraryPlaylistsView> createState() => LibraryPlaylistsViewState();
}

class LibraryPlaylistsViewState extends State<LibraryPlaylistsView> {
  late final PlaylistDao _playlistDao;
  late final SongDao _songDao;

  List<Playlist>? _playlists;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _playlistDao = widget.playlistDao ?? PlaylistDao();
    _songDao = widget.songDao ?? SongDao();

    PlaylistDao.playlistRevision.addListener(_onPlaylistRevisionChanged);

    if (widget.playlists != null) {
      _playlists = List.of(widget.playlists!);
      _isLoading = false;
    } else {
      _loadPlaylists();
    }
  }

  void _onPlaylistRevisionChanged() {
    if (mounted) {
      _loadPlaylists();
    }
  }

  @override
  void dispose() {
    PlaylistDao.playlistRevision.removeListener(_onPlaylistRevisionChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LibraryPlaylistsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playlists != null && widget.playlists != oldWidget.playlists) {
      setState(() {
        _playlists = List.of(widget.playlists!);
        _isLoading = false;
      });
    }
  }

  /// Reloads all user playlists from the database.
  Future<void> reloadPlaylists() async {
    await _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final playlists = await _playlistDao.getPlaylists();
      if (mounted) {
        setState(() {
          _playlists = playlists;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [LibraryPlaylistsView] Error loading playlists: $e');
      if (mounted) {
        setState(() {
          _playlists = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePlaylistTap(Playlist playlist) async {
    if (widget.onPlaylistTap != null) {
      widget.onPlaylistTap!(playlist);
      return;
    }

    await Navigator.of(context).push<Playlist?>(
      PlaylistDetailScreen.route(
        playlist: playlist,
        playlistDao: _playlistDao,
        songDao: _songDao,
      ),
    );

    if (mounted) {
      await reloadPlaylists();
    }
  }

  Future<void> _handlePlayTap(Playlist playlist) async {
    if (playlist.id == null) return;
    final controller = PlaybackController.instance;

    // If this playlist is currently active: toggle play/pause!
    if (controller.activePlaylistId == playlist.id) {
      await controller.togglePlayPause();
      return;
    }

    try {
      final songs = await _playlistDao.getPlaylistSongs(playlist.id!);
      if (songs.isNotEmpty) {
        await controller.playSong(
          songs.first,
          queue: songs,
          playlistId: playlist.id,
        );
      }
    } catch (e) {
      debugPrint('⚠️ [LibraryPlaylistsView] Play error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          color: AppColors.navActiveIcon,
        ),
      );
    }

    final playlists = _playlists ?? [];

    if (playlists.isEmpty) {
      return const LibraryPlaylistsPlaceholder(
        key: ValueKey('library_playlists_empty_placeholder'),
      );
    }

    return ListView.separated(
      key: const ValueKey('library_playlists_grid'),
      controller: widget.scrollController,
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 14.0,
        bottom: 96.0,
      ),
      separatorBuilder: (context, index) => const SizedBox(height: 14.0),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return LibraryPlaylistCard(
          key: ValueKey('library_playlist_card_${playlist.id ?? index}'),
          playlist: playlist,
          onTap: () => _handlePlaylistTap(playlist),
          onPlayTap: () => _handlePlayTap(playlist),
        );
      },
    );
  }
}


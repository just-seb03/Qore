/// File: search_discovery_view.dart
/// Description: Search Discovery view presenting the newest 5 albums carousel at the top,
/// newest 5 artists carousel below it, and a 2-cover row featuring 'Today Selection' and
/// 'Recientes' system playlists with 4-cover collages or empty vinyl fallbacks.
/// Renders nothing (SizedBox.shrink) if the user has no songs in their library.
///
/// Components / Classes / Functions:
/// - SearchDiscoveryView: Stateful coordinator widget managing discovery content rendering.
/// - _SearchDiscoveryViewState: State class asynchronously loading newest albums, artists, and playlists.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/selection/today_selection_service.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';
import 'package:project_anima/features/playlist/screens/playlist_detail_screen.dart';
import 'package:project_anima/features/search/components/cards/search_discovery_card.dart';
import 'package:project_anima/features/search/components/common/search_section_header.dart';
import 'package:project_anima/features/search/components/sections/search_albums_section.dart';
import 'package:project_anima/features/search/components/sections/search_artists_section.dart';

/// Discovery content displayed on the Search screen when the search bar is inactive.
class SearchDiscoveryView extends StatefulWidget {
  /// Optional pre-loaded albums for testing or pre-fetching.
  final List<AlbumDiscoveryItem>? initialAlbums;

  /// Optional pre-loaded artists for testing or pre-fetching.
  final List<ArtistDiscoveryItem>? initialArtists;

  /// Optional pre-loaded today selection songs.
  final List<Song>? initialTodaySongs;

  /// Optional pre-loaded recently played songs.
  final List<Song>? initialRecentSongs;

  /// Optional total song count (when 0, renders nothing).
  final int? initialSongCount;

  /// Optional SongDao for dependency injection.
  final SongDao? songDao;

  /// Optional TodaySelectionService for dependency injection.
  final TodaySelectionService? todaySelectionService;

  /// Optional custom callback when an album card is tapped.
  final ValueChanged<AlbumDiscoveryItem>? onAlbumTap;

  /// Optional custom callback when an artist card is tapped.
  final ValueChanged<ArtistDiscoveryItem>? onArtistTap;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  const SearchDiscoveryView({
    super.key,
    this.initialAlbums,
    this.initialArtists,
    this.initialTodaySongs,
    this.initialRecentSongs,
    this.initialSongCount,
    this.songDao,
    this.todaySelectionService,
    this.onAlbumTap,
    this.onArtistTap,
    this.scrollController,
  });

  @override
  State<SearchDiscoveryView> createState() => _SearchDiscoveryViewState();
}

class _SearchDiscoveryViewState extends State<SearchDiscoveryView> {
  late final SongDao _songDao;
  late final TodaySelectionService _todaySelectionService;

  int _songCount = 0;
  List<AlbumDiscoveryItem> _newestAlbums = const [];
  List<ArtistDiscoveryItem> _newestArtists = const [];
  List<Song> _todaySongs = const [];
  List<Song> _recentlyPlayedSongs = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _songDao = widget.songDao ?? SongDao();
    _todaySelectionService =
        widget.todaySelectionService ?? TodaySelectionService.instance;

    SongDao.playbackHistoryRevision.addListener(_onPlaybackHistoryChanged);

    if (widget.initialSongCount != null) {
      _songCount = widget.initialSongCount!;
      _newestAlbums = widget.initialAlbums ?? const [];
      _newestArtists = widget.initialArtists ?? const [];
      _todaySongs = widget.initialTodaySongs ?? const [];
      _recentlyPlayedSongs = widget.initialRecentSongs ?? const [];
      _isLoading = false;
    } else {
      _loadDiscoveryData();
    }
  }

  @override
  void dispose() {
    SongDao.playbackHistoryRevision.removeListener(_onPlaybackHistoryChanged);
    super.dispose();
  }

  void _onPlaybackHistoryChanged() {
    _reloadRecentlyPlayed();
  }

  Future<void> _reloadRecentlyPlayed() async {
    try {
      final recentSongs = await _songDao.getRecentlyPlayedSongs(limit: 20);
      if (!mounted) return;
      setState(() {
        _recentlyPlayedSongs = recentSongs;
      });
      final repIds = recentSongs.take(4).map((s) => s.mediaStoreId).toList();
      ArtworkService.instance.prioritizeSongIds(repIds);
    } catch (e) {
      debugPrint('⚠️ [SearchDiscoveryView] Error reloading recently played: $e');
    }
  }

  Future<void> _loadDiscoveryData() async {
    try {
      final count = await _songDao.getSongCount();
      if (!mounted) return;

      if (count == 0) {
        setState(() {
          _songCount = 0;
          _isLoading = false;
        });
        return;
      }

      // Concurrently query newest albums, newest artists, today's selection, and recently played
      final results = await Future.wait([
        _songDao.getNewestAlbums(limit: 5),
        _songDao.getNewestArtists(limit: 5),
        _todaySelectionService.getTodaySelection(songDao: _songDao),
        _songDao.getRecentlyPlayedSongs(limit: 20),
      ]);

      if (!mounted) return;

      final albums = results[0] as List<AlbumDiscoveryItem>;
      final artists = results[1] as List<ArtistDiscoveryItem>;
      final todaySongs = results[2] as List<Song>;
      final recentSongs = results[3] as List<Song>;

      // Prioritize frame-0 thumbnail artwork in cache
      final repIds = <int>[
        ...albums.map((a) => a.representativeSongId),
        ...todaySongs.take(4).map((s) => s.mediaStoreId),
        ...recentSongs.take(4).map((s) => s.mediaStoreId),
      ];
      ArtworkService.instance.prioritizeSongIds(repIds);

      setState(() {
        _songCount = count;
        _newestAlbums = albums;
        _newestArtists = artists;
        _todaySongs = todaySongs;
        _recentlyPlayedSongs = recentSongs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('⚠️ [SearchDiscoveryView] Error loading discovery data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleAlbumTap(AlbumDiscoveryItem album) {
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

  void _handleArtistTap(ArtistDiscoveryItem artist) {
    if (widget.onArtistTap != null) {
      widget.onArtistTap!(artist);
      return;
    }

    Navigator.of(context).push(
      ArtistDetailScreen.route(artist.name),
    );
  }

  void _handleOpenTodaySelection(BuildContext context) {
    if (_todaySongs.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final todayPlaylist = Playlist(
      id: -1,
      name: context.l10n.search.todaySelectionTitle,
      createdAt: nowMs,
      updatedAt: nowMs,
      firstMediaStoreId:
          _todaySongs.isNotEmpty ? _todaySongs.first.mediaStoreId : null,
    );

    Navigator.of(context).push(
      PlaylistDetailScreen.route(
        playlist: todayPlaylist,
        initialSongs: _todaySongs,
        isEditable: false,
        showHeroCover: false,
      ),
    );
  }

  void _handleOpenRecientes(BuildContext context) {
    if (_recentlyPlayedSongs.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final recentPlaylist = Playlist(
      id: -2,
      name: context.l10n.search.recentlyPlayedTitle,
      createdAt: nowMs,
      updatedAt: nowMs,
      firstMediaStoreId: _recentlyPlayedSongs.isNotEmpty
          ? _recentlyPlayedSongs.first.mediaStoreId
          : null,
    );

    Navigator.of(context).push(
      PlaylistDetailScreen.route(
        playlist: recentPlaylist,
        initialSongs: _recentlyPlayedSongs,
        isEditable: false,
        showHeroCover: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If loading or the user has no music in the library, show nothing
    if (_isLoading || _songCount == 0) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;

    return SingleChildScrollView(
      controller: widget.scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8.0, bottom: 160.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Destacadas Section (Today Selection and Recientes)
          SearchSectionHeader(
            title: l10n.search.featuredSectionHeader,
          ),
          const SizedBox(height: 6.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today Selection Card
                Expanded(
                  child: SearchDiscoveryCard(
                    title: l10n.search.todaySelectionTitle,
                    subtitle: l10n.search.songCount(_todaySongs.length),
                    songs: _todaySongs,
                    icon: Icons.today_rounded,
                    onTap: () => _handleOpenTodaySelection(context),
                  ),
                ),
                const SizedBox(width: 16.0),

                // Recientes Card
                Expanded(
                  child: SearchDiscoveryCard(
                    title: l10n.search.recentlyPlayedTitle,
                    subtitle: l10n.search.songCount(_recentlyPlayedSongs.length),
                    songs: _recentlyPlayedSongs,
                    icon: Icons.access_time_rounded,
                    onTap: () => _handleOpenRecientes(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18.0),

          // 2. Nuevos Álbumes Section (top 5 newest albums)
          if (_newestAlbums.isNotEmpty) ...[
            SearchAlbumsSection(
              albums: _newestAlbums,
              showHeader: true,
              headerTitle: l10n.search.newAlbumsSectionHeader,
              onAlbumTap: _handleAlbumTap,
            ),
            const SizedBox(height: 18.0),
          ],

          // 3. Artistas Nuevos Section (top 5 newest artists)
          if (_newestArtists.isNotEmpty) ...[
            SearchArtistsSection(
              artists: _newestArtists,
              showHeader: true,
              headerTitle: l10n.search.newArtistsSectionHeader,
              onArtistTap: _handleArtistTap,
            ),
          ],
        ],
      ),
    );
  }
}

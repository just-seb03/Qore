/// File: explore_metro_view.dart
/// Description: Discovery view for the Explore screen designed faithfully in the
/// Windows Phone Metro design language. Combines large Segoe UI Light headers,
/// sharp 90-degree Live Tiles with zero drop shadows, square artist and album tiles,
/// and reactive library integration.
///
/// Components / Classes / Functions:
/// - ExploreMetroView: Stateful discovery widget orchestrating Metro tiles and DAO queries.
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
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';
import 'package:project_anima/features/explore/components/explore_metro_album_tile.dart';
import 'package:project_anima/features/explore/components/explore_metro_artist_tile.dart';
import 'package:project_anima/features/explore/components/explore_metro_tile.dart';
import 'package:project_anima/features/playlist/screens/playlist_detail_screen.dart';

/// Authentic Windows Phone Metro discovery view for ExploreScreen.
class ExploreMetroView extends StatefulWidget {
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

  /// Optional custom callback when an album tile is tapped.
  final ValueChanged<AlbumDiscoveryItem>? onAlbumTap;

  /// Optional custom callback when an artist tile is tapped.
  final ValueChanged<ArtistDiscoveryItem>? onArtistTap;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  const ExploreMetroView({
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
  State<ExploreMetroView> createState() => _ExploreMetroViewState();
}

class _ExploreMetroViewState extends State<ExploreMetroView> {
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
      debugPrint('⚠️ [ExploreMetroView] Error reloading recently played: $e');
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
      debugPrint('⚠️ [ExploreMetroView] Error loading discovery data: $e');
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

  Widget _buildMetroSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Text(
        title.toLowerCase(),
        style: AppFonts.segoe(
          fontSize: 21.0,
          fontWeight: FontWeight.w300,
          color: AppColors.onBackground,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _songCount == 0) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 4.0, bottom: 140.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Featured Metro Live Tiles (Today Selection & Recientes)
          _buildMetroSectionHeader(l10n.search.featuredSectionHeader),
          const SizedBox(height: 10.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today Selection Live Tile
                Expanded(
                  child: ExploreMetroTile(
                    title: l10n.search.todaySelectionTitle,
                    subtitle: l10n.search.songCount(_todaySongs.length),
                    songs: _todaySongs,
                    icon: Icons.today_rounded,
                    onTap: () => _handleOpenTodaySelection(context),
                  ),
                ),
                const SizedBox(width: 12.0),

                // Recientes Live Tile
                Expanded(
                  child: ExploreMetroTile(
                    title: l10n.search.recentlyPlayedTitle,
                    subtitle: l10n.search.songCount(_recentlyPlayedSongs.length),
                    songs: _recentlyPlayedSongs,
                    icon: Icons.history_rounded,
                    onTap: () => _handleOpenRecientes(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          // 2. Nuevos Álbumes Section (top 5 newest albums)
          if (_newestAlbums.isNotEmpty) ...[
            _buildMetroSectionHeader(l10n.search.newAlbumsSectionHeader),
            const SizedBox(height: 10.0),
            SizedBox(
              height: 135.0,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: _newestAlbums.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10.0),
                itemBuilder: (context, index) {
                  final album = _newestAlbums[index];
                  return ExploreMetroAlbumTile(
                    album: album,
                    onTap: () => _handleAlbumTap(album),
                  );
                },
              ),
            ),
            const SizedBox(height: 24.0),
          ],

          // 3. Artistas Section (top 5 newest artists)
          if (_newestArtists.isNotEmpty) ...[
            _buildMetroSectionHeader(l10n.search.newArtistsSectionHeader),
            const SizedBox(height: 10.0),
            SizedBox(
              height: 135.0,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: _newestArtists.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10.0),
                itemBuilder: (context, index) {
                  final artist = _newestArtists[index];
                  return ExploreMetroArtistTile(
                    artist: artist,
                    onTap: () => _handleArtistTap(artist),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}


/// File: explore_metro_view.dart
/// Description: Discovery view for the Explore screen designed faithfully in the
/// Windows Phone Metro design language. Combines large Segoe UI Light headers with
/// capitalized initial letters, a wide Daily Mix Live Tile, square artist profile tiles,
/// and a dedicated Recientes section with up to 10 recently played tracks.
///
/// Components / Classes / Functions:
/// - ExploreMetroView: Stateful discovery widget orchestrating Metro tiles, track lists, and DAO queries.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/selection/today_selection_service.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';
import 'package:project_anima/features/explore/components/explore_metro_album_tile.dart';
import 'package:project_anima/features/explore/components/explore_metro_artist_tile.dart';
import 'package:project_anima/features/explore/components/explore_metro_tile.dart';
import 'package:project_anima/features/explore/components/explore_metro_track_tile.dart';
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

  /// Optional custom callback when a recent song is tapped.
  final ValueChanged<Song>? onSongTap;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  /// Optional top padding for the scroll view. Defaults to 74.0.
  final double topPadding;

  /// Optional bottom padding for the scroll view. Defaults to 84.0.
  final double bottomPadding;

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
    this.onSongTap,
    this.scrollController,
    this.topPadding = 74.0,
    this.bottomPadding = 84.0,
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
      final repIds = recentSongs.take(10).map((s) => s.mediaStoreId).toList();
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
        ...recentSongs.take(10).map((s) => s.mediaStoreId),
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

  void _handleOpenDailyMix(BuildContext context) {
    if (_todaySongs.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final todayPlaylist = Playlist(
      id: -1,
      name: 'Daily Mix',
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

  void _handleTrackTap(Song song, int index) {
    if (widget.onSongTap != null) {
      widget.onSongTap!(song);
      return;
    }

    final recent10 = _recentlyPlayedSongs.take(10).toList();
    PlaybackController.instance.playSong(
      song,
      queue: recent10,
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    final lower = text.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  Widget _buildMetroSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Text(
        _capitalize(title),
        style: AppFonts.segoe(
          fontSize: 22.0,
          fontWeight: FontWeight.w300,
          color: AppColors.onBackground,
          letterSpacing: -0.2,
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
    final recentSongs10 = _recentlyPlayedSongs.take(10).toList();

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.only(
        top: widget.topPadding,
        bottom: widget.bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Featured Section (Daily Mix occupying full width / 2 cuadros, solid color with centered icon)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ExploreMetroTile(
              title: 'Daily Mix',
              subtitle: l10n.search.songCount(_todaySongs.length),
              icon: Icons.today_rounded,
              isSolid: true,
              aspectRatio: 2.3,
              onTap: () => _handleOpenDailyMix(context),
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

          // 3. Artistas Nuevos Section (top 5 newest artists)
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
            const SizedBox(height: 24.0),
          ],

          // 4. Recientes Section (up to 10 recently played songs)
          if (recentSongs10.isNotEmpty) ...[
            _buildMetroSectionHeader(l10n.search.recentlyPlayedTitle),
            const SizedBox(height: 8.0),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentSongs10.length,
              itemBuilder: (context, index) {
                final song = recentSongs10[index];
                return ExploreMetroTrackTile(
                  song: song,
                  onTap: () => _handleTrackTap(song, index),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

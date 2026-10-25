/// File: home.dart
/// Description: Home screen featuring futuristic 'WELCOME' header, 'Today's Selection'
/// 20-track system playlist collage banner, and reactive gapless pinned favorites section.
/// Maintains low coupling and shares the monochromatic theme palette.
///
/// Components / Classes / Functions:
/// - Home: Type alias pointing to HomeScreen for flexible naming conventions.
/// - HomeScreen: Screen widget displaying HomeHeader, TodaySelectionHeroCard, and HomePinnedSection.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/dao/pinned_favorites_dao.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/permissions/audio_permission_service.dart';
import 'package:project_anima/core/scanner/music_indexer.dart';
import 'package:project_anima/core/selection/today_selection_service.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';
import 'package:project_anima/features/home/components/home_header.dart';
import 'package:project_anima/features/home/controls/home_layout_controller.dart';
import 'package:project_anima/features/home/controls/home_slot_grid.dart';
import 'package:project_anima/features/playlist/screens/playlist_detail_screen.dart';

/// Type alias allowing both `Home` and `HomeScreen` to be used cleanly across the codebase.
typedef Home = HomeScreen;

/// Home screen with the futuristic header, Today's Selection, Favorites, and pinned favorites.
class HomeScreen extends StatefulWidget {
  /// Whether to display the bottom navigation bar. Defaults to true.
  final bool showBottomNav;

  /// Optional pre-loaded today's selection songs (for testing/DI).
  final List<Song>? initialTodaySongs;

  /// Optional pre-loaded favorites songs (for testing/DI).
  final List<Song>? initialFavoriteSongs;

  /// Optional pre-loaded pinned items (for testing/DI).
  final List<PinnedFavorite>? initialPinnedItems;

  const HomeScreen({
    super.key,
    this.showBottomNav = true,
    this.initialTodaySongs,
    this.initialFavoriteSongs,
    this.initialPinnedItems,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Song> _todaySongs = [];
  List<Song> _favoriteSongs = [];
  List<PinnedFavorite> _pinnedItems = [];
  final HomeLayoutController _layoutController = HomeLayoutController.instance;

  @override
  void initState() {
    super.initState();
    if (widget.initialTodaySongs != null) {
      _todaySongs = widget.initialTodaySongs!;
    }
    if (widget.initialFavoriteSongs != null) {
      _favoriteSongs = widget.initialFavoriteSongs!;
    }
    if (widget.initialPinnedItems != null) {
      _pinnedItems = widget.initialPinnedItems!;
    }

    _syncLayout();

    PinnedFavoritesDao.revision.addListener(_onPinnedRevisionChanged);
    FavoriteSongsDao.instance.favoritesRevision.addListener(_onFavoritesRevisionChanged);
    MusicIndexer.revision.addListener(_onIndexerRevisionChanged);

    final isTesting = widget.initialTodaySongs != null ||
        widget.initialFavoriteSongs != null ||
        widget.initialPinnedItems != null;

    if (!isTesting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestInitialPermissions();
        _loadHomeData();
      });

      _layoutController.init().then((_) {
        if (mounted) _syncLayout();
      });
    }
  }

  @override
  void dispose() {
    PinnedFavoritesDao.revision.removeListener(_onPinnedRevisionChanged);
    FavoriteSongsDao.instance.favoritesRevision.removeListener(_onFavoritesRevisionChanged);
    MusicIndexer.revision.removeListener(_onIndexerRevisionChanged);
    super.dispose();
  }

  void _onIndexerRevisionChanged() {
    _loadHomeData();
  }

  void _onPinnedRevisionChanged() {
    _loadPinnedFavorites();
  }

  void _onFavoritesRevisionChanged() {
    _loadFavoriteSongs();
  }

  void _syncLayout() {
    _layoutController.syncItems(
      pinnedItems: _pinnedItems,
      showToday: true,
      showFavorites: true,
    );
  }

  Future<void> _requestInitialPermissions() async {
    final hasPermission = await AudioPermissionService.instance.hasPermission();
    if (!hasPermission) {
      final status = await AudioPermissionService.instance.requestPermission();
      if (status.isGranted) {
        MusicIndexer.instance.syncWithDevice();
      }
    }
  }

  Future<void> _loadHomeData() async {
    try {
      final songs = widget.initialTodaySongs ??
          await TodaySelectionService.instance.getTodaySelection();
      final favs = widget.initialFavoriteSongs ??
          await FavoriteSongsDao.instance.getAllFavorites();
      final pinned = widget.initialPinnedItems ??
          await PinnedFavoritesDao.instance.getAllPinned();

      if (mounted) {
        setState(() {
          _todaySongs = songs;
          _favoriteSongs = favs;
          _pinnedItems = pinned;
        });
        _syncLayout();
      }
    } catch (e) {
      debugPrint('⚠️ [HomeScreen] Error loading home data: $e');
    }
  }

  Future<void> _loadFavoriteSongs() async {
    try {
      final favs = await FavoriteSongsDao.instance.getAllFavorites();
      if (mounted) {
        setState(() {
          _favoriteSongs = favs;
        });
        _syncLayout();
      }
    } catch (e) {
      debugPrint('⚠️ [HomeScreen] Error refreshing favorite songs: $e');
    }
  }

  Future<void> _loadPinnedFavorites() async {
    try {
      final pinned = await PinnedFavoritesDao.instance.getAllPinned();
      if (mounted) {
        setState(() {
          _pinnedItems = pinned;
        });
        _syncLayout();
      }
    } catch (e) {
      debugPrint('⚠️ [HomeScreen] Error refreshing pinned favorites: $e');
    }
  }

  void _openAlbum(PinnedFavorite item) {
    Navigator.of(context).push(
      AlbumDetailScreen.route(
        albumName: item.title,
        artistName: item.subtitle,
        albumId: item.albumId,
        representativeSongId: item.representativeSongId,
      ),
    );
  }

  void _openPlaylist(PinnedFavorite item) {
    final playlist = Playlist(
      id: item.playlistId,
      name: item.title,
      coverPath: item.coverPath,
      fontFamily: item.fontFamily,
      firstMediaStoreId: item.representativeSongId,
      createdAt: item.pinnedAt.millisecondsSinceEpoch,
      updatedAt: item.pinnedAt.millisecondsSinceEpoch,
    );

    Navigator.of(context).push(
      PlaylistDetailScreen.route(playlist: playlist),
    );
  }

  void _openArtist(PinnedFavorite item) {
    Navigator.of(context).push(
      ArtistDetailScreen.route(item.title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bottomNavBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Futuristic Header ("WELCOME") with ticket/check when in arranging mode
              ListenableBuilder(
                listenable: _layoutController,
                builder: (context, _) {
                  return HomeHeader(
                    isArranging: _layoutController.isArranging,
                    onDoneTap: () => _layoutController.exitArrangingMode(),
                  );
                },
              ),

              // 2. Defined-Places Grid (System Playlists & User-Pinned Favorites)
              HomeSlotGrid(
                todaySongs: _todaySongs,
                favoriteSongs: _favoriteSongs,
                controller: _layoutController,
                onOpenAlbum: _openAlbum,
                onOpenPlaylist: _openPlaylist,
                onOpenArtist: _openArtist,
              ),

              // Spacing above bottom MiniPlayer / Bottom Navigation Bar
              const SizedBox(height: 36.0),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const AppBottomNav(
              currentIndex: 0,
            )
          : null,
    );
  }
}

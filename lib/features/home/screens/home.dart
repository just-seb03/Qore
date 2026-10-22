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
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/permissions/audio_permission_service.dart';
import 'package:project_anima/core/scanner/music_indexer.dart';
import 'package:project_anima/core/selection/today_selection_service.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/home/components/home_favorites_hero_card.dart';
import 'package:project_anima/features/home/components/home_header.dart';
import 'package:project_anima/features/home/components/home_pinned_section.dart';
import 'package:project_anima/features/home/components/today_selection_hero_card.dart';

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

    PinnedFavoritesDao.revision.addListener(_onPinnedRevisionChanged);
    FavoriteSongsDao.instance.favoritesRevision.addListener(_onFavoritesRevisionChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestInitialPermissions();
      _loadHomeData();
    });
  }

  @override
  void dispose() {
    PinnedFavoritesDao.revision.removeListener(_onPinnedRevisionChanged);
    FavoriteSongsDao.instance.favoritesRevision.removeListener(_onFavoritesRevisionChanged);
    super.dispose();
  }

  void _onPinnedRevisionChanged() {
    _loadPinnedFavorites();
  }

  void _onFavoritesRevisionChanged() {
    _loadFavoriteSongs();
  }

  Future<void> _requestInitialPermissions() async {
    final hasPermission = await AudioPermissionService.instance.hasPermission();
    if (!hasPermission) {
      final status = await AudioPermissionService.instance.requestPermission();
      if (status.isGranted) {
        MusicIndexer.instance.syncWithDevice();
      }
    } else {
      MusicIndexer.instance.syncWithDevice();
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
      }
    } catch (e) {
      debugPrint('⚠️ [HomeScreen] Error refreshing pinned favorites: $e');
    }
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
              // 1. Futuristic Header ("WELCOME")
              const HomeHeader(),

              // 2. "Today's Selection" System 20-Track Playlist Collage Hero
              TodaySelectionHeroCard(songs: _todaySongs),
              const SizedBox(height: 16.0),

              // 3. "Favorites" System Playlist Collage Hero
              HomeFavoritesHeroCard(songs: _favoriteSongs),
              const SizedBox(height: 32.0),

              // 4. User-Pinned Favorites (Albums, Artists, Playlists) with Gapless Packing
              HomePinnedSection(items: _pinnedItems),

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

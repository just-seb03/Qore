/// File: profile.dart
/// Description: Windows Phone Metro Profile screen displaying the user's global top played
/// songs (without play counters), most played artist, most played album, and a Metro-styled
/// Settings button over the persistent AmbientParticlesCanvas backdrop.
///
/// Components / Classes / Functions:
/// - Profile: Type alias for ProfileScreen.
/// - ProfileScreen: Stateful Metro Profile screen widget.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/components/song_options_pill.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';
import 'package:project_anima/features/profile/components/profile_header.dart';
import 'package:project_anima/features/search/components/common/material_artist_avatar.dart';
import 'package:project_anima/features/settings/screens/settings_screen.dart';

/// Type alias allowing both `Profile` and `ProfileScreen` across the codebase.
typedef Profile = ProfileScreen;

/// Primary Metro Profile screen displaying global listening stats and Settings button.
class ProfileScreen extends StatefulWidget {
  /// Whether to display the bottom navigation bar. Defaults to true.
  final bool showBottomNav;

  /// Optional SongDao for dependency injection in tests.
  final SongDao? songDao;

  /// Optional pre-loaded top songs (skips async DB load in tests).
  final List<Song>? initialTopSongs;

  /// Optional pre-loaded most played artist.
  final ArtistDiscoveryItem? initialTopArtist;

  /// Optional pre-loaded most played album.
  final AlbumDiscoveryItem? initialTopAlbum;

  const ProfileScreen({
    super.key,
    this.showBottomNav = true,
    this.songDao,
    this.initialTopSongs,
    this.initialTopArtist,
    this.initialTopAlbum,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  late final SongDao _songDao;

  List<Song> _topSongs = const [];
  ArtistDiscoveryItem? _topArtist;
  AlbumDiscoveryItem? _topAlbum;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _songDao = widget.songDao ?? SongDao();
    SongDao.playbackHistoryRevision.addListener(_onPlaybackHistoryChanged);

    if (widget.initialTopSongs != null ||
        widget.initialTopArtist != null ||
        widget.initialTopAlbum != null) {
      _topSongs = widget.initialTopSongs ?? const [];
      _topArtist = widget.initialTopArtist;
      _topAlbum = widget.initialTopAlbum;
      _isLoading = false;
    } else {
      _loadProfileStats();
    }
  }

  @override
  void dispose() {
    SongDao.playbackHistoryRevision.removeListener(_onPlaybackHistoryChanged);
    super.dispose();
  }

  void _onPlaybackHistoryChanged() {
    _loadProfileStats();
  }

  Future<void> _loadProfileStats() async {
    try {
      final results = await Future.wait([
        _songDao.getTopSongsGlobal(limit: 5),
        _songDao.getMostPlayedArtist(),
        _songDao.getMostPlayedAlbum(),
      ]);

      if (!mounted) return;

      final topSongs = results[0] as List<Song>;
      final topArtist = results[1] as ArtistDiscoveryItem?;
      final topAlbum = results[2] as AlbumDiscoveryItem?;

      final ids = <int>[
        ...topSongs.map((s) => s.mediaStoreId),
        if (topAlbum != null && topAlbum.representativeSongId > 0)
          topAlbum.representativeSongId,
      ];
      if (ids.isNotEmpty) {
        ArtworkService.instance.prioritizeSongIds(ids);
      }

      setState(() {
        _topSongs = topSongs;
        _topArtist = topArtist;
        _topAlbum = topAlbum;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('⚠️ [ProfileScreen] Error loading stats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDuration(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.bottomNavBackground,
      body: Stack(
        children: [
          const AmbientParticlesCanvas(),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ProfileHeader(isMetro: true),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: AppColors.accent,
                          ),
                        )
                      : ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.white,
                                Colors.white,
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.03, 0.92, 1.0],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.only(
                              top: 8.0,
                              bottom: 196.0 + MediaQuery.paddingOf(context).bottom,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 1. Artista Más Escuchado
                                if (_topArtist != null) ...[
                                  _buildSectionHeader(
                                    isSpanish
                                        ? 'ARTISTA MÁS ESCUCHADO'
                                        : 'MOST PLAYED ARTIST',
                                  ),
                                  const SizedBox(height: 6.0),
                                  _buildTopArtistTile(context, _topArtist!, isSpanish),
                                  const SizedBox(height: 24.0),
                                ],

                                // 2. Álbum Más Escuchado
                                if (_topAlbum != null) ...[
                                  _buildSectionHeader(
                                    isSpanish
                                        ? 'ÁLBUM MÁS ESCUCHADO'
                                        : 'MOST PLAYED ALBUM',
                                  ),
                                  const SizedBox(height: 6.0),
                                  _buildTopAlbumTile(context, _topAlbum!, isSpanish),
                                  const SizedBox(height: 24.0),
                                ],

                                // 3. Top Canciones Generales (sin contador)
                                if (_topSongs.isNotEmpty) ...[
                                  _buildSectionHeader(
                                    isSpanish ? 'TOP CANCIONES' : 'TOP SONGS',
                                  ),
                                  const SizedBox(height: 4.0),
                                  for (final song in _topSongs)
                                    _buildTopSongTile(context, song),
                                  const SizedBox(height: 28.0),
                                ],

                                // Empty state if no listening history yet
                                if (_topSongs.isEmpty &&
                                    _topArtist == null &&
                                    _topAlbum == null) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                      vertical: 32.0,
                                    ),
                                    child: Text(
                                      isSpanish
                                          ? 'Reproduce música para ver tus canciones, artista y álbum más escuchados.'
                                          : 'Play music to see your top songs, artist, and album.',
                                      style: AppFonts.light(
                                        fontSize: 16.0,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],

                                // 4. Metro Settings Button (placeholder, non-functional for now)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainer
                                          .withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.zero,
                                      border: Border.all(
                                        color: AppColors.outline.withValues(alpha: 0.35),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.zero,
                                      child: InkWell(
                                        key: const ValueKey('profile_settings_button'),
                                        borderRadius: BorderRadius.zero,
                                        splashColor: AppColors.accent.withValues(alpha: 0.15),
                                        onTap: () {
                                          Navigator.of(context).push(
                                            SettingsScreen.route(),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                            vertical: 14.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.settings_outlined,
                                                size: 22.0,
                                                color: AppColors.onSurface,
                                              ),
                                              const SizedBox(width: 14.0),
                                              Expanded(
                                                child: Text(
                                                  isSpanish ? 'Ajustes' : 'Settings',
                                                  style: AppFonts.segoe(
                                                    fontSize: 15.5,
                                                    fontWeight: FontWeight.w400,
                                                    color: AppColors.onSurface,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.chevron_right_rounded,
                                                size: 20.0,
                                                color: AppColors.onSurfaceVariant,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const AppBottomNav(
              currentIndex: 4,
            )
          : null,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      child: Text(
        title,
        style: AppFonts.segoe(
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.5,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildTopSongTile(BuildContext context, Song song) {
    final artist = (song.artist != null &&
            song.artist!.trim().isNotEmpty &&
            song.artist != '<Desconocido>' &&
            song.artist != 'Unknown Artist')
        ? song.artist!
        : context.l10n.common.unknownArtist;
    final album = (song.album != null &&
            song.album!.trim().isNotEmpty &&
            song.album != '<Desconocido>' &&
            song.album != 'Unknown Album')
        ? song.album!
        : context.l10n.common.unknownAlbum;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        splashColor: AppColors.accent.withValues(alpha: 0.15),
        highlightColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.2),
        onTap: () {
          SongOptionsPillCoordinator.instance.close();
          PlaybackController.instance.playSong(song, queue: _topSongs);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            children: [
              AnimaArtworkImage(
                mediaStoreId: song.mediaStoreId,
                albumId: song.albumId,
                albumName: song.album,
                artistName: song.albumArtist ?? song.artist,
                width: 48.0,
                height: 48.0,
                borderRadius: 0.0,
                isThumbnail: true,
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.segoe(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      '$artist • $album',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.segoe(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w300,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6.0),
              SongOptionsPill(
                song: song,
                durationText: _formatDuration(song.duration),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopArtistTile(
    BuildContext context,
    ArtistDiscoveryItem artist,
    bool isSpanish,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.85),
          borderRadius: BorderRadius.zero,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.zero,
          child: InkWell(
            borderRadius: BorderRadius.zero,
            splashColor: AppColors.accent.withValues(alpha: 0.15),
            onTap: () {
              Navigator.of(context).push(
                ArtistDetailScreen.route(artist.name),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  MaterialArtistAvatar(
                    radius: 34.0,
                    artistName: artist.name,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          artist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.light(
                            fontSize: 21.0,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3.0),
                        Text(
                          isSpanish ? 'Artista' : 'Artist',
                          style: AppFonts.segoe(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 22.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopAlbumTile(
    BuildContext context,
    AlbumDiscoveryItem album,
    bool isSpanish,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.85),
          borderRadius: BorderRadius.zero,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.zero,
          child: InkWell(
            borderRadius: BorderRadius.zero,
            splashColor: AppColors.accent.withValues(alpha: 0.15),
            onTap: () {
              Navigator.of(context).push(
                AlbumDetailScreen.route(
                  albumName: album.name,
                  artistName: album.artist,
                  albumId: album.albumId,
                  representativeSongId: album.representativeSongId,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  AnimaArtworkImage(
                    mediaStoreId: album.representativeSongId,
                    albumId: album.albumId,
                    albumName: album.name,
                    artistName: album.artist,
                    width: 68.0,
                    height: 68.0,
                    borderRadius: 0.0,
                    isThumbnail: false,
                    fallbackIcon: Icons.album_rounded,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          album.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.light(
                            fontSize: 20.0,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3.0),
                        Text(
                          album.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.segoe(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w300,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 22.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

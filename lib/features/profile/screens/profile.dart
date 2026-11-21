/// File: profile.dart
/// Description: Windows Phone Metro Profile screen displaying total listening time
/// (days, hours, minutes), top 3 artists, top 3 albums, top 5 songs, favorite genre,
/// and a Metro-styled Settings button over the persistent AmbientParticlesCanvas backdrop.
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
import 'package:project_anima/core/utils/duration_formatter.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/profile/components/profile_header.dart';
import 'package:project_anima/features/profile/components/profile_stats_widgets.dart';
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

  /// Optional pre-loaded most played artist (backward compatible single-item test helper).
  final ArtistDiscoveryItem? initialTopArtist;

  /// Optional pre-loaded most played album (backward compatible single-item test helper).
  final AlbumDiscoveryItem? initialTopAlbum;

  /// Optional pre-loaded top 3 artists.
  final List<ArtistDiscoveryItem>? initialTopArtists;

  /// Optional pre-loaded top 3 albums.
  final List<AlbumDiscoveryItem>? initialTopAlbums;

  /// Optional pre-loaded total playback time in milliseconds.
  final int? initialTotalPlaybackMs;

  /// Optional pre-loaded favorite genre.
  final String? initialFavoriteGenre;

  const ProfileScreen({
    super.key,
    this.showBottomNav = true,
    this.songDao,
    this.initialTopSongs,
    this.initialTopArtist,
    this.initialTopAlbum,
    this.initialTopArtists,
    this.initialTopAlbums,
    this.initialTotalPlaybackMs,
    this.initialFavoriteGenre,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  late final SongDao _songDao;

  List<Song> _topSongs = const [];
  List<ArtistDiscoveryItem> _topArtists = const [];
  List<AlbumDiscoveryItem> _topAlbums = const [];
  int _totalPlaybackMs = 0;
  String? _favoriteGenre;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _songDao = widget.songDao ?? SongDao();
    SongDao.playbackHistoryRevision.addListener(_onPlaybackHistoryChanged);

    final hasInitialData = widget.initialTopSongs != null ||
        widget.initialTopArtist != null ||
        widget.initialTopAlbum != null ||
        widget.initialTopArtists != null ||
        widget.initialTopAlbums != null ||
        widget.initialTotalPlaybackMs != null ||
        widget.initialFavoriteGenre != null;

    if (hasInitialData) {
      _topSongs = widget.initialTopSongs ?? const [];
      _topArtists = widget.initialTopArtists ??
          (widget.initialTopArtist != null
              ? [widget.initialTopArtist!]
              : const []);
      _topAlbums = widget.initialTopAlbums ??
          (widget.initialTopAlbum != null
              ? [widget.initialTopAlbum!]
              : const []);
      _totalPlaybackMs = widget.initialTotalPlaybackMs ?? 0;
      _favoriteGenre = widget.initialFavoriteGenre;
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
        _songDao.getTotalPlaybackTimeMs().catchError((_) => 0),
        _songDao
            .getTopPlayedArtists(limit: 3)
            .catchError((_) => const <ArtistDiscoveryItem>[]),
        _songDao
            .getTopPlayedAlbums(limit: 3)
            .catchError((_) => const <AlbumDiscoveryItem>[]),
        _songDao.getTopSongsGlobal(limit: 5).catchError((_) => const <Song>[]),
        _songDao.getFavoriteGenre().catchError((_) => null),
      ]);

      if (!mounted) return;

      final totalPlaybackMs = results[0] as int;
      final topArtists = results[1] as List<ArtistDiscoveryItem>;
      final topAlbums = results[2] as List<AlbumDiscoveryItem>;
      final topSongs = results[3] as List<Song>;
      final favoriteGenre = results[4] as String?;

      final ids = <int>[
        ...topSongs.map((s) => s.mediaStoreId),
        ...topAlbums
            .where((a) => a.representativeSongId > 0)
            .map((a) => a.representativeSongId),
      ];
      if (ids.isNotEmpty) {
        ArtworkService.instance.prioritizeSongIds(ids);
      }

      setState(() {
        _totalPlaybackMs = totalPlaybackMs;
        _topArtists = topArtists;
        _topAlbums = topAlbums;
        _topSongs = topSongs;
        _favoriteGenre = favoriteGenre;
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

  String _formatDuration(int ms) => formatDurationMs(ms);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final bool hasAnyHistory = _totalPlaybackMs > 0 ||
        _topArtists.isNotEmpty ||
        _topAlbums.isNotEmpty ||
        _topSongs.isNotEmpty;

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
                                // 1. Tiempo Total Reproducido (Días, Horas, Minutos)
                                _buildSectionHeader(
                                  isSpanish
                                      ? 'TIEMPO REPRODUCIDO'
                                      : 'LISTENING TIME',
                                ),
                                const SizedBox(height: 8.0),
                                ProfileListeningTimeRow(
                                  totalPlaybackMs: _totalPlaybackMs,
                                  isSpanish: isSpanish,
                                ),
                                const SizedBox(height: 22.0),

                                // 2. Top 3 Artistas Más Escuchados
                                if (_topArtists.isNotEmpty) ...[
                                  _buildSectionHeader(
                                    isSpanish
                                        ? 'ARTISTAS MÁS ESCUCHADOS'
                                        : 'MOST PLAYED ARTISTS',
                                  ),
                                  const SizedBox(height: 8.0),
                                  for (int i = 0; i < _topArtists.length; i++) ...[
                                    ProfileTopArtistTile(
                                      artist: _topArtists[i],
                                      rank: i + 1,
                                      isSpanish: isSpanish,
                                    ),
                                    if (i < _topArtists.length - 1)
                                      const SizedBox(height: 6.0),
                                  ],
                                  const SizedBox(height: 22.0),
                                ],

                                // 3. Top 3 Álbumes Más Escuchados
                                if (_topAlbums.isNotEmpty) ...[
                                  _buildSectionHeader(
                                    isSpanish
                                        ? 'ÁLBUMES MÁS ESCUCHADOS'
                                        : 'MOST PLAYED ALBUMS',
                                  ),
                                  const SizedBox(height: 8.0),
                                  for (int i = 0; i < _topAlbums.length; i++) ...[
                                    ProfileTopAlbumTile(
                                      album: _topAlbums[i],
                                      rank: i + 1,
                                    ),
                                    if (i < _topAlbums.length - 1)
                                      const SizedBox(height: 6.0),
                                  ],
                                  const SizedBox(height: 22.0),
                                ],

                                // 4. Top 5 Canciones Más Escuchadas
                                if (_topSongs.isNotEmpty) ...[
                                  _buildSectionHeader(
                                    isSpanish ? 'TOP CANCIONES' : 'TOP SONGS',
                                  ),
                                  const SizedBox(height: 6.0),
                                  for (int i = 0; i < _topSongs.length; i++) ...[
                                    _buildTopSongTile(context, _topSongs[i]),
                                    if (i < _topSongs.length - 1)
                                      Divider(
                                        height: 1.0,
                                        thickness: 0.5,
                                        indent: 82.0,
                                        endIndent: 20.0,
                                        color: AppColors.outline.withValues(alpha: 0.16),
                                      ),
                                  ],
                                  const SizedBox(height: 22.0),
                                ],

                                // 5. Género Favorito
                                if (_favoriteGenre != null &&
                                    _favoriteGenre!.isNotEmpty) ...[
                                  _buildSectionHeader(
                                    isSpanish
                                        ? 'GÉNERO FAVORITO'
                                        : 'FAVORITE GENRE',
                                  ),
                                  const SizedBox(height: 8.0),
                                  ProfileFavoriteGenreTile(
                                    genre: _favoriteGenre!,
                                  ),
                                  const SizedBox(height: 22.0),
                                ],

                                // Empty state if no listening history yet
                                if (!hasAnyHistory) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                      vertical: 24.0,
                                    ),
                                    child: Text(
                                      isSpanish
                                          ? 'Reproduce música para ver tus estadísticas de escucha.'
                                          : 'Play music to see your listening stats.',
                                      style: AppFonts.light(
                                        fontSize: 16.0,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],

                                // 6. Metro Settings Button
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainer
                                          .withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.zero,
                                      border: Border.all(
                                        color: AppColors.outline.withValues(alpha: 0.30),
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
                                                color: AppColors.accent,
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
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      child: Text(
        title,
        style: AppFonts.segoe(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
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
}

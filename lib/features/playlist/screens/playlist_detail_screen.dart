/// File: playlist_detail_screen.dart
/// Description: Dedicated full-screen playlist detail screen mirroring AlbumDetailScreen aesthetics.
/// Features universal animated dismiss chevron, drag-to-dismiss gesture physics, large sharp
/// playlist artwork with deep shadow, interactive Shuffle (left) and Play (right) controls,
/// ordered track list with playback highlighting, bottom MiniPlayer, and seamless edit routing.
///
/// Components / Classes / Functions:
/// - PlaylistDetailScreen: Stateful screen widget for playlist presentation and playback.
/// - _PlaylistDetailScreenState: State class coordinating playback, drag gestures, and tracks.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/database/dao/pinned_favorites_dao.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/navigation/app_route_tracker.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/player/components/mini_player.dart';
import 'package:project_anima/features/playlist/components/playlist_detail_header.dart';
import 'package:project_anima/features/playlist/components/playlist_track_tile.dart';
import 'package:project_anima/features/playlist/screens/playlist_edit_screen.dart';
import 'package:project_anima/features/playlist/screens/playlist_tracks_edit_screen.dart';

/// Full-screen playlist detail and playback screen.
class PlaylistDetailScreen extends StatefulWidget {
  /// The playlist entity to display.
  final Playlist playlist;

  /// Optional pre-loaded playlist songs for dependency injection and testing.
  final List<Song>? initialSongs;

  /// Optional PlaylistDao for dependency injection.
  final PlaylistDao? playlistDao;

  /// Optional SongDao for dependency injection.
  final SongDao? songDao;

  /// Whether to run continuous floating bounce animation on the dismiss chevron.
  final bool animateBounce;

  /// Whether the playlist can be edited.
  final bool isEditable;

  /// Whether to show the widescreen 1920x620 hero banner cover.
  final bool showHeroCover;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    this.initialSongs,
    this.playlistDao,
    this.songDao,
    this.animateBounce = true,
    this.isEditable = true,
    this.showHeroCover = true,
  });

  /// Factory helper for smooth bottom-to-top modal slide transition.
  static Route<Playlist?> route({
    required Playlist playlist,
    List<Song>? initialSongs,
    PlaylistDao? playlistDao,
    SongDao? songDao,
    bool animateBounce = true,
    bool isEditable = true,
    bool showHeroCover = true,
  }) {
    return PageRouteBuilder<Playlist?>(
      settings: RouteSettings(
        name: AppRouteTracker.playlistRouteName(
          playlistId: playlist.id,
          name: playlist.name,
        ),
      ),
      pageBuilder: (context, animation, secondaryAnimation) => PlaylistDetailScreen(
        playlist: playlist,
        initialSongs: initialSongs,
        playlistDao: playlistDao,
        songDao: songDao,
        animateBounce: animateBounce,
        isEditable: isEditable,
        showHeroCover: showHeroCover,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen>
    with SingleTickerProviderStateMixin {
  late final PlaylistDao _playlistDao;
  late final SongDao _songDao;

  late Playlist _playlist;
  List<Song> _songs = [];
  bool _isLoading = true;
  bool _isPinned = false;
  bool _isFlashingRed = false;

  /// Whether this playlist is currently pinned to favorites.
  bool get isPinned => _isPinned;

  String get _playlistKey => PinnedFavoritesDao.playlistKey(_playlist.id ?? -1);

  double _dragOffset = 0.0;
  late final AnimationController _springController;
  Animation<double>? _springAnimation;

  @override
  void initState() {
    super.initState();
    _playlistDao = widget.playlistDao ?? PlaylistDao();
    _songDao = widget.songDao ?? SongDao();
    _playlist = widget.playlist;

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_springAnimation != null) {
          setState(() {
            _dragOffset = _springAnimation!.value;
          });
        }
      });

    PlaylistDao.playlistRevision.addListener(_onPlaylistRevisionChanged);
    if (_playlist.id == -2) {
      SongDao.playbackHistoryRevision.addListener(_onPlaybackHistoryChanged);
    }

    if (widget.initialSongs != null) {
      _songs = List.of(widget.initialSongs!);
      _isLoading = false;
    } else if (_playlist.id == -2) {
      _loadRecentSongs();
    } else if (_playlist.id != null) {
      _loadPlaylistSongs();
    } else {
      _isLoading = false;
    }

    _checkPinnedStatus();
  }

  Future<void> _checkPinnedStatus() async {
    try {
      if (_playlist.id != null && _playlist.id! > 0) {
        final pinned = await PinnedFavoritesDao.instance.isPinned(_playlistKey);
        if (mounted) {
          setState(() {
            _isPinned = pinned;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _togglePinned() async {
    if (_playlist.id == null || _playlist.id! <= 0) return;
    try {
      final willPin = !_isPinned;
      HapticFeedback.mediumImpact();

      if (willPin && mounted) {
        setState(() {
          _isFlashingRed = true;
        });
      }

      final newStatus = await PinnedFavoritesDao.instance.togglePin(
        PinnedFavorite(
          itemType: PinnedItemType.playlist,
          itemKey: _playlistKey,
          title: _playlist.name,
          subtitle: mounted
              ? context.l10n.playlist.songCount(_songs.length)
              : '${_songs.length} ${_songs.length == 1 ? "track" : "tracks"}',
          playlistId: _playlist.id,
          coverPath: _playlist.coverPath,
          fontFamily: _playlist.fontFamily,
          representativeSongId: _playlist.firstMediaStoreId,
          textAlignX: _playlist.textAlignX,
          textAlignY: _playlist.textAlignY,
          textColor: _playlist.textColor,
          textGradientColor: _playlist.textGradientColor,
          fontSize: _playlist.fontSize,
          textEffect: _playlist.textEffect,
          pinnedAt: DateTime.now(),
        ),
      );

      if (mounted) {
        setState(() {
          _isPinned = newStatus;
        });
      }

      if (willPin) {
        await Future.delayed(const Duration(milliseconds: 650));
        if (mounted) {
          setState(() {
            _isFlashingRed = false;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistDetailScreen] Error toggling pin: $e');
      if (mounted) {
        setState(() {
          _isFlashingRed = false;
        });
      }
    }
  }

  void _onPlaylistRevisionChanged() {
    if (mounted && _playlist.id != null && _playlist.id! > 0) {
      _loadPlaylistSongs();
    }
  }

  void _onPlaybackHistoryChanged() {
    if (mounted && _playlist.id == -2) {
      _loadRecentSongs();
    }
  }

  Future<void> _loadRecentSongs() async {
    try {
      final songs = await SongDao().getRecentlyPlayedSongs(limit: 50);
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistDetailScreen] Error reloading recent songs: $e');
    }
  }

  @override
  void dispose() {
    PlaylistDao.playlistRevision.removeListener(_onPlaylistRevisionChanged);
    if (_playlist.id == -2) {
      SongDao.playbackHistoryRevision.removeListener(_onPlaybackHistoryChanged);
    }
    _springController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylistSongs() async {
    try {
      final songs = await _playlistDao.getPlaylistSongs(_playlist.id!);
      final updatedPlaylist = await _playlistDao.getPlaylistById(_playlist.id!);
      if (mounted) {
        setState(() {
          _songs = songs;
          if (updatedPlaylist != null) {
            _playlist = updatedPlaylist;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [PlaylistDetailScreen] Error loading songs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleDragUpdate(double delta) {
    if (_springController.isAnimating) {
      _springController.stop();
    }
    setState(() {
      _dragOffset = math.max(0.0, _dragOffset + delta);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragOffset > 90.0 || velocity > 320.0) {
      Navigator.of(context).pop(_playlist);
    } else if (_dragOffset > 0.0) {
      _springAnimation = Tween<double>(
        begin: _dragOffset,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: _springController,
          curve: Curves.easeOutQuad,
        ),
      );
      _springController.forward(from: 0.0);
    }
  }

  void _handleDismiss() {
    Navigator.of(context).pop(_playlist);
  }

  void _playFromStart() {
    if (_songs.isEmpty) return;
    final controller = PlaybackController.instance;
    if (controller.activePlaylistId == _playlist.id) {
      controller.togglePlayPause();
      return;
    }
    controller.playSong(_songs.first, queue: _songs, playlistId: _playlist.id);
  }

  void _toggleShuffle() {
    PlaybackController.instance.toggleShuffle();
  }

  Future<void> _editPlaylist() async {
    final result = await Navigator.of(context).push<Playlist?>(
      PlaylistEditScreen.route(
        initialPlaylist: _playlist,
        initialSongs: _songs,
        playlistDao: _playlistDao,
        songDao: _songDao,
        animateBounce: widget.animateBounce,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _playlist = result;
        _isLoading = true;
      });
      await _loadPlaylistSongs();
    }
  }

  Future<void> _editPlaylistTracks() async {
    final updatedSongs = await Navigator.of(context).push<List<Song>?>(
      PlaylistTracksEditScreen.route(
        playlist: _playlist,
        initialSongs: _songs,
        playlistDao: _playlistDao,
        songDao: _songDao,
        animateBounce: widget.animateBounce,
      ),
    );

    if (updatedSongs != null && mounted) {
      setState(() {
        _songs = List.of(updatedSongs);
        _isLoading = true;
      });
      await _loadPlaylistSongs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = _songs.fold<int>(0, (sum, s) => sum + s.duration);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_playlist);
        }
      },
      child: ListenableBuilder(
        listenable: PlaybackController.instance,
        builder: (context, _) {
        return AnimatedContainer(
          duration: Duration(milliseconds: _isFlashingRed ? 250 : 500),
          curve: _isFlashingRed ? Curves.easeOutCubic : Curves.easeInCubic,
          color: _isFlashingRed ? AppColors.pinnedRedBackground : AppColors.background,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            bottomNavigationBar: const SafeArea(
              top: false,
              child: MiniPlayer(),
            ),
            body: SafeArea(
              bottom: false,
              child: Transform.translate(
                offset: Offset(0.0, _dragOffset),
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.accent,
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. Universal Animated Dismiss Chevron
                            const SizedBox(height: 4.0),
                            ModalDismissIndicator(
                              onDismiss: _handleDismiss,
                              onDragUpdate: _handleDragUpdate,
                              onDragEnd: _handleDragEnd,
                              size: 34.0,
                              color: AppColors.onSurfaceVariant,
                              animate: widget.animateBounce,
                              padding: const EdgeInsets.symmetric(
                                vertical: 6.0,
                                horizontal: 36.0,
                              ),
                            ),
                            const SizedBox(height: 8.0),

                            // 2. Cohesive Playlist Header: Artwork + Controls (Shuffle | Info | Play)
                            PlaylistDetailHeader(
                              playlist: _playlist,
                              songCount: _songs.length,
                              totalDurationMs: totalMs,
                              isShuffleEnabled: PlaybackController.instance.isShuffleEnabled,
                              onPlay: _playFromStart,
                              onToggleShuffle: _toggleShuffle,
                              isPinned: _isPinned,
                              onToggleFavorite: widget.showHeroCover ? _togglePinned : null,
                              showHeroCover: widget.showHeroCover,
                              isEditable: widget.isEditable,
                              onEdit: widget.isEditable ? _editPlaylist : null,
                            ),
                            const SizedBox(height: 24.0),

                            // 3. Tracks Section
                            _buildTracksSection(),

                            // Spacing above bottom MiniPlayer
                            const SizedBox(height: 28.0),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildTracksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Header with Edit Pencil on Right Margin
        Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                context.l10n.playlist.tracksHeader,
                style: AppFonts.segoe(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (widget.isEditable)
                IconButton(
                  key: const ValueKey('playlist_detail_edit_button'),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20.0,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onPressed: _editPlaylistTracks,
                  tooltip: context.l10n.playlist.editPlaylistTooltip,
                  splashRadius: 20.0,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8.0),

        if (_songs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.playlist.emptyPlaylistTitle,
                    textAlign: TextAlign.center,
                    style: AppFonts.segoe(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    context.l10n.playlist.emptyPlaylistSubtitle,
                    textAlign: TextAlign.center,
                    style: AppFonts.segoe(
                      fontSize: 13.5,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  if (widget.isEditable) ...[
                    const SizedBox(height: 16.0),
                    OutlinedButton.icon(
                      key: const ValueKey('playlist_detail_add_songs_button'),
                      onPressed: _editPlaylistTracks,
                      icon: const Icon(Icons.add_rounded, size: 18.0),
                      label: Text(context.l10n.playlist.addSongsButton),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurface,
                        side: BorderSide(color: AppColors.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          // Ordered Tracklist
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int index = 0; index < _songs.length; index++) ...[
                  if (index > 0) const SizedBox(height: 2.0),
                  PlaylistTrackTile(
                    key: ValueKey('playlist_track_tile_${_songs[index].mediaStoreId}_$index'),
                    song: _songs[index],
                    trackIndex: index + 1,
                    allPlaylistSongs: _songs,
                    playlistId: _playlist.id,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

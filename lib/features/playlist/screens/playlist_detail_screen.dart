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
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/player/components/mini_player.dart';
import 'package:project_anima/features/playlist/components/playlist_detail_header.dart';
import 'package:project_anima/features/playlist/components/playlist_track_tile.dart';
import 'package:project_anima/features/playlist/screens/playlist_edit_screen.dart';

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

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    this.initialSongs,
    this.playlistDao,
    this.songDao,
    this.animateBounce = true,
  });

  /// Factory helper for smooth bottom-to-top modal slide transition.
  static Route<Playlist?> route({
    required Playlist playlist,
    List<Song>? initialSongs,
    PlaylistDao? playlistDao,
    SongDao? songDao,
    bool animateBounce = true,
  }) {
    return PageRouteBuilder<Playlist?>(
      pageBuilder: (context, animation, secondaryAnimation) => PlaylistDetailScreen(
        playlist: playlist,
        initialSongs: initialSongs,
        playlistDao: playlistDao,
        songDao: songDao,
        animateBounce: animateBounce,
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

    if (widget.initialSongs != null) {
      _songs = List.of(widget.initialSongs!);
      _isLoading = false;
    } else if (_playlist.id != null) {
      _loadPlaylistSongs();
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
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
    PlaybackController.instance.playSong(_songs.first, queue: _songs);
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

  @override
  Widget build(BuildContext context) {
    final totalMs = _songs.fold<int>(0, (sum, s) => sum + s.duration);

    return ListenableBuilder(
      listenable: PlaybackController.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          bottomNavigationBar: const SafeArea(
            top: false,
            child: MiniPlayer(),
          ),
          body: SafeArea(
            bottom: false,
            child: Transform.translate(
              offset: Offset(0.0, _dragOffset),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. Universal Animated Dismiss Chevron
                          const SizedBox(height: 10.0),
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
                          const SizedBox(height: 14.0),

                          // 2. Cohesive Playlist Header: Artwork + Controls (Shuffle | Info | Play)
                          PlaylistDetailHeader(
                            playlist: _playlist,
                            songCount: _songs.length,
                            totalDurationMs: totalMs,
                            isShuffleEnabled: PlaybackController.instance.isShuffleEnabled,
                            onPlay: _playFromStart,
                            onToggleShuffle: _toggleShuffle,
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
        );
      },
    );
  }

  Widget _buildTracksSection() {
    if (_songs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NO TRACKS IN THIS PLAYLIST',
                textAlign: TextAlign.center,
                style: GoogleFonts.zenDots(
                  fontSize: 12.0,
                  letterSpacing: 1.2,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Add tracks to your playlist by editing it.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inconsolata(
                  fontSize: 13.5,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 16.0),
              OutlinedButton.icon(
                key: const ValueKey('playlist_detail_edit_button'),
                onPressed: _editPlaylist,
                icon: const Icon(Icons.add_rounded, size: 18.0),
                label: const Text('Add Songs'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.futuristicWhite,
                  side: const BorderSide(color: AppColors.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Header with subtle pencil icon on the right margin
        Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TRACKS',
                style: GoogleFonts.inconsolata(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              IconButton(
                key: const ValueKey('playlist_detail_edit_button'),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 19.0,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: _editPlaylist,
                tooltip: 'Edit playlist',
                splashRadius: 18.0,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8.0),

        // Ordered Tracklist
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          itemCount: _songs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 2.0),
          itemBuilder: (context, index) {
            final song = _songs[index];
            return PlaylistTrackTile(
              key: ValueKey('playlist_track_tile_${song.mediaStoreId}_$index'),
              song: song,
              trackIndex: index + 1,
              allPlaylistSongs: _songs,
            );
          },
        ),
      ],
    );
  }
}

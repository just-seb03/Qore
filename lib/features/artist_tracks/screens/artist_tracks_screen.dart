/// File: artist_tracks_screen.dart
/// Description: Dedicated full-screen modal view presenting an artist's complete tracklist.
/// Features high-speed itemExtent virtualization for smooth 120fps scrolling,
/// dynamic top and bottom scroll transparency mask, floating MiniPlayer with downward
/// dismiss chevron underneath, and interactive pull-down modal exit transitions.
///
/// Components / Classes / Functions:
/// - ArtistTracksScreen: Coordinator screen for an artist's complete track collection.
/// - _ArtistTracksScreenState: State managing drag dismiss, async controller, and scroll sync.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/components/scroll_edge_fade_mask.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/artist_tracks/components/artist_tracks_header.dart';
import 'package:project_anima/features/artist_tracks/components/artist_tracks_list.dart';
import 'package:project_anima/features/artist_tracks/controls/artist_tracks_controller.dart';
import 'package:project_anima/features/player/components/mini_player.dart';

/// Full-screen track catalog view presenting all songs recorded by an artist.
class ArtistTracksScreen extends StatefulWidget {
  /// Name of the artist whose tracks are listed.
  final String artistName;

  /// Optional SongDao for dependency injection.
  final SongDao? songDao;

  /// Optional ArtworkService for dependency injection.
  final ArtworkService? artworkService;

  /// Optional controller override for testing and state management.
  final ArtistTracksController? controller;

  /// Whether to run continuous floating bounce animation on the dismiss indicator.
  final bool animateBounce;

  /// Whether to display the floating MiniPlayer when active. Defaults to true.
  final bool showMiniPlayer;

  const ArtistTracksScreen({
    super.key,
    required this.artistName,
    this.songDao,
    this.artworkService,
    this.controller,
    this.animateBounce = true,
    this.showMiniPlayer = true,
  });

  /// Factory route for smooth bottom-to-top modal slide transition.
  static Route<void> route({
    required String artistName,
    SongDao? songDao,
    ArtworkService? artworkService,
    ArtistTracksController? controller,
    bool animateBounce = true,
    bool showMiniPlayer = true,
  }) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ArtistTracksScreen(
        artistName: artistName,
        songDao: songDao,
        artworkService: artworkService,
        controller: controller,
        animateBounce: animateBounce,
        showMiniPlayer: showMiniPlayer,
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
  State<ArtistTracksScreen> createState() => _ArtistTracksScreenState();
}

class _ArtistTracksScreenState extends State<ArtistTracksScreen>
    with SingleTickerProviderStateMixin {
  late final ArtistTracksController _controller;
  final ScrollController _scrollController = ScrollController();

  double _dragOffset = 0.0;
  late final AnimationController _springController;
  Animation<double>? _springAnimation;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        ArtistTracksController(
          artistName: widget.artistName,
          songDao: widget.songDao,
          artworkService: widget.artworkService,
        );

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

    if (widget.controller == null) {
      _controller.loadTracks();
    }
  }

  @override
  void dispose() {
    _springController.dispose();
    _scrollController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
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
      Navigator.of(context).pop();
    } else if (_dragOffset > 0.0) {
      _springAnimation = Tween<double>(
        begin: _dragOffset,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: _springController,
          curve: Curves.easeOutCubic,
        ),
      );
      _springController.forward(from: 0.0);
    }
  }

  void _handleDismiss() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const AmbientParticlesCanvas(),
          Scaffold(
            backgroundColor: Colors.transparent,
        bottomNavigationBar: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showMiniPlayer) ...[
                const SizedBox(height: 6.0),
                const MiniPlayer(),
                const SizedBox(height: 6.0),
              ],
              ModalDismissIndicator(
                onDismiss: _handleDismiss,
                onDragUpdate: _handleDragUpdate,
                onDragEnd: _handleDragEnd,
                size: 34.0,
                color: AppColors.onSurfaceVariant,
                animate: widget.animateBounce,
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 40.0,
                ),
              ),
              const SizedBox(height: 12.0),
            ],
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: Transform.translate(
            offset: Offset(0.0, _dragOffset),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.accent,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Section Header (Category, Artist Name, Stats)
                    ArtistTracksHeader(
                      artistName: widget.artistName,
                      songCount: _controller.songCount,
                      totalDurationMs: _controller.totalDurationMs,
                    ),
                    const SizedBox(height: 4.0),

                    // 2. High-performance virtualized tracks list with edge fade mask
                    Expanded(
                      child: ScrollEdgeFadeMask(
                        scrollController: _scrollController,
                        child: ArtistTracksList(
                          songs: _controller.songs,
                          scrollController: _scrollController,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ],
  ),
);
  }
}

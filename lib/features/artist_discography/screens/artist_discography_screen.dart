/// File: artist_discography_screen.dart
/// Description: Dedicated full-screen modal view presenting an artist's complete discography.
/// Displays albums in a 2-per-row grid matching the Library styling, applies a dynamic
/// top and bottom edge scroll transparency mask, hosts the floating MiniPlayer with
/// downward dismiss chevron underneath, and supports interactive drag-to-dismiss.
///
/// Components / Classes / Functions:
/// - ArtistDiscographyScreen: Coordinator screen for an artist's complete album catalog.
/// - _ArtistDiscographyScreenState: State managing drag dismiss, async controller, and scroll sync.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/components/scroll_edge_fade_mask.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/artist_discography/components/artist_discography_grid.dart';
import 'package:project_anima/features/artist_discography/components/artist_discography_header.dart';
import 'package:project_anima/features/artist_discography/controls/artist_discography_controller.dart';
import 'package:project_anima/features/player/components/mini_player.dart';

/// Full-screen discography view presenting an artist's entire catalog of albums.
class ArtistDiscographyScreen extends StatefulWidget {
  /// Name of the artist whose discography is viewed.
  final String artistName;

  /// Optional SongDao for dependency injection.
  final SongDao? songDao;

  /// Optional ArtworkService for dependency injection.
  final ArtworkService? artworkService;

  /// Optional controller override for testing and state management.
  final ArtistDiscographyController? controller;

  /// Whether to run continuous floating bounce animation on the dismiss indicator.
  final bool animateBounce;

  /// Whether to display the floating MiniPlayer when active. Defaults to true.
  final bool showMiniPlayer;

  const ArtistDiscographyScreen({
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
    ArtistDiscographyController? controller,
    bool animateBounce = true,
    bool showMiniPlayer = true,
  }) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ArtistDiscographyScreen(
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
  State<ArtistDiscographyScreen> createState() => _ArtistDiscographyScreenState();
}

class _ArtistDiscographyScreenState extends State<ArtistDiscographyScreen>
    with SingleTickerProviderStateMixin {
  late final ArtistDiscographyController _controller;
  final ScrollController _scrollController = ScrollController();

  double _dragOffset = 0.0;
  late final AnimationController _springController;
  Animation<double>? _springAnimation;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        ArtistDiscographyController(
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
      _controller.loadDiscography();
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
      child: Scaffold(
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
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Section Header (Category, Artist Name, Album Count)
                    ArtistDiscographyHeader(
                      artistName: widget.artistName,
                      albumCount: _controller.albumCount,
                    ),
                    const SizedBox(height: 4.0),

                    // 2. 2-per-row Albums Grid with dynamic scroll edge transparency
                    Expanded(
                      child: ScrollEdgeFadeMask(
                        scrollController: _scrollController,
                        child: ArtistDiscographyGrid(
                          albums: _controller.albums,
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
    );
  }
}

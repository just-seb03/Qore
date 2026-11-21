/// File: explore.dart
/// Description: Dedicated Explore screen designed authentically in the Windows Phone Metro
/// design language. Features sharp 90-degree corners, zero drop shadows, large panoramic
/// Segoe UI Light typography, Live Tiles, square artist tiles, dynamic ambient particles,
/// and an interactive collapsible header overlay that slides away on scroll down and reappears
/// on scroll up without resizing the scrollable viewport.
///
/// Components / Classes / Functions:
/// - Explore: Type alias for ExploreScreen.
/// - ExploreScreen: Screen widget displaying the Windows Phone Metro Explore discovery interface.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';
import 'package:project_anima/features/explore/components/explore_header.dart';
import 'package:project_anima/features/explore/components/explore_metro_view.dart';

/// Type alias allowing both `Explore` and `ExploreScreen` across the codebase.
typedef Explore = ExploreScreen;

/// Primary Windows Phone Metro Explore discovery screen for the application.
class ExploreScreen extends StatefulWidget {
  /// Whether to display the bottom navigation bar. Defaults to true.
  final bool showBottomNav;

  /// Whether to mount the local [AmbientParticlesCanvas] backdrop behind this screen.
  final bool showAmbientBackdrop;

  /// Optional initial song count for testing or pre-fetching.
  final int? initialSongCount;

  /// Optional initial albums.
  final List<AlbumDiscoveryItem>? initialAlbums;

  /// Optional initial artists.
  final List<ArtistDiscoveryItem>? initialArtists;

  /// Optional initial today selection songs.
  final List<Song>? initialTodaySongs;

  /// Optional initial recent songs.
  final List<Song>? initialRecentSongs;

  const ExploreScreen({
    super.key,
    this.showBottomNav = true,
    this.showAmbientBackdrop = true,
    this.initialSongCount,
    this.initialAlbums,
    this.initialArtists,
    this.initialTodaySongs,
    this.initialRecentSongs,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  bool _isHeaderVisible = true;

  void _handleAlbumTap(BuildContext context, AlbumDiscoveryItem album) {
    Navigator.of(context).push(
      AlbumDetailScreen.route(
        albumName: album.name,
        artistName: album.artist,
        albumId: album.albumId,
        representativeSongId: album.representativeSongId,
      ),
    );
  }

  void _handleArtistTap(BuildContext context, ArtistDiscoveryItem artist) {
    Navigator.of(context).push(
      ArtistDetailScreen.route(artist.name),
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final metrics = notification.metrics;

    // 1. If at or near top, always keep header visible
    if (metrics.pixels <= 25.0) {
      if (!_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = true;
        });
      }
      return false;
    }

    // 2. Ignore overscroll and bottom bounce to prevent false triggers or snap-back jitter
    if (metrics.outOfRange || metrics.pixels >= metrics.maxScrollExtent - 40.0) {
      return false;
    }

    // 3. Process scrolling movements with threshold
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0.0;
      if (delta > 6.0 && metrics.pixels > 50.0) {
        if (_isHeaderVisible) {
          setState(() {
            _isHeaderVisible = false;
          });
        }
      } else if (delta < -6.0) {
        if (!_isHeaderVisible) {
          setState(() {
            _isHeaderVisible = true;
          });
        }
      }
    } else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse && metrics.pixels > 50.0) {
        if (_isHeaderVisible) {
          setState(() {
            _isHeaderVisible = false;
          });
        }
      } else if (notification.direction == ScrollDirection.forward) {
        if (!_isHeaderVisible) {
          setState(() {
            _isHeaderVisible = true;
          });
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.showAmbientBackdrop
          ? AppColors.bottomNavBackground
          : Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dynamic ambient particles simulation backdrop
          if (widget.showAmbientBackdrop) const AmbientParticlesCanvas(),

          // Windows Phone Metro Explore UI
          Scaffold(
            extendBody: true,
            backgroundColor: Colors.transparent,
            body: SafeArea(
              bottom: false,
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: Stack(
                  children: [
                    // 1. Content view with constant viewport constraints (never resizes during scroll)
                    Positioned.fill(
                      child: ShaderMask(
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
                            stops: [
                              0.0,
                              0.015,
                              0.985,
                              1.0,
                            ],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: ExploreMetroView(
                          key: const ValueKey('explore_discovery_view'),
                          initialSongCount: widget.initialSongCount,
                          initialAlbums: widget.initialAlbums,
                          initialArtists: widget.initialArtists,
                          initialTodaySongs: widget.initialTodaySongs,
                          initialRecentSongs: widget.initialRecentSongs,
                          topPadding: 74.0,
                          bottomPadding: 84.0,
                          onAlbumTap: (album) => _handleAlbumTap(context, album),
                          onArtistTap: (artist) => _handleArtistTap(context, artist),
                        ),
                      ),
                    ),

                    // 2. Animated header overlay: slides up when scrolling down, slides back when scrolling up
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        ignoring: !_isHeaderVisible,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.fastOutSlowIn,
                          offset: _isHeaderVisible ? Offset.zero : const Offset(0, -1.1),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            opacity: _isHeaderVisible ? 1.0 : 0.0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.bottomNavBackground.withValues(alpha: 0.95),
                                    AppColors.bottomNavBackground.withValues(alpha: 0.6),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.7, 1.0],
                                ),
                              ),
                              child: const ExploreHeader(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: widget.showBottomNav
                ? const AppBottomNav(
                    currentIndex: 0,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

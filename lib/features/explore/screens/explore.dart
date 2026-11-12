/// File: explore.dart
/// Description: Dedicated Explore screen designed authentically in the Windows Phone Metro
/// design language. Features sharp 90-degree corners, zero drop shadows, large panoramic
/// Segoe UI Light typography, Live Tiles, square artist tiles, dynamic ambient particles,
/// and an interactive collapsible header that disappears on scroll down and reappears on scroll up.
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

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0.0;
      if (delta > 2.0 && notification.metrics.pixels > 15.0) {
        if (_isHeaderVisible) {
          setState(() {
            _isHeaderVisible = false;
          });
        }
      } else if (delta < -2.0) {
        if (!_isHeaderVisible) {
          setState(() {
            _isHeaderVisible = true;
          });
        }
      }
    } else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse &&
          notification.metrics.pixels > 15.0) {
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

    if (notification.metrics.pixels <= 10.0 && !_isHeaderVisible) {
      setState(() {
        _isHeaderVisible = true;
      });
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bottomNavBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dynamic ambient particles simulation backdrop
          const AmbientParticlesCanvas(),

          // Windows Phone Metro Explore UI
          Scaffold(
            extendBody: true,
            backgroundColor: Colors.transparent,
            body: SafeArea(
              bottom: false,
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dynamic collapsible header: hides on scroll down, slides back on scroll up
                    ClipRect(
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.fastOutSlowIn,
                        alignment: Alignment.topLeft,
                        heightFactor: _isHeaderVisible ? 1.0 : 0.0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _isHeaderVisible ? 1.0 : 0.0,
                          child: const ExploreHeader(),
                        ),
                      ),
                    ),
                    Expanded(
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
                          onAlbumTap: (album) => _handleAlbumTap(context, album),
                          onArtistTap: (artist) => _handleArtistTap(context, artist),
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

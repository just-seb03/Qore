/// File: explore.dart
/// Description: Dedicated Explore screen designed authentically in the Windows Phone Metro
/// design language. Features sharp 90-degree corners, zero drop shadows, large panoramic
/// Segoe UI Light typography, Live Tiles, square artist tiles, and dynamic ambient particles.
///
/// Components / Classes / Functions:
/// - Explore: Type alias for ExploreScreen.
/// - ExploreScreen: Screen widget displaying the Windows Phone Metro Explore discovery interface.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';
import 'package:project_anima/features/explore/components/explore_header.dart';
import 'package:project_anima/features/explore/components/explore_metro_view.dart';

/// Type alias allowing both `Explore` and `ExploreScreen` across the codebase.
typedef Explore = ExploreScreen;

/// Primary Windows Phone Metro Explore discovery screen for the application.
class ExploreScreen extends StatelessWidget {
  /// Whether to display the bottom navigation bar. Defaults to true.
  final bool showBottomNav;

  const ExploreScreen({
    super.key,
    this.showBottomNav = true,
  });

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ExploreHeader(),
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
                            0.02,
                            0.94,
                            1.0,
                          ],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: ExploreMetroView(
                        key: const ValueKey('explore_discovery_view'),
                        onAlbumTap: (album) => _handleAlbumTap(context, album),
                        onArtistTap: (artist) => _handleArtistTap(context, artist),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: showBottomNav
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

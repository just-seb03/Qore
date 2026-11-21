/// File: home.dart
/// Description: Space screen (formerly Home) with clean Inconsolata 'Space' header
/// matching the Library and Search top bars, and hosting the exclusive dynamic
/// PS3-style ambient particle simulation backdrop.
///
/// Components / Classes / Functions:
/// - Space: Type alias pointing to HomeScreen.
/// - SpaceScreen: Type alias pointing to HomeScreen.
/// - Home: Type alias pointing to HomeScreen for backward compatibility.
/// - HomeScreen: Screen widget displaying SpaceHeader and AmbientParticlesCanvas.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/home/components/space_intro_overlay.dart';
import 'package:project_anima/features/home/components/space_tiles_grid.dart';

/// Type alias allowing both `Space` / `SpaceScreen` and `Home` / `HomeScreen` to be used cleanly.
typedef Space = HomeScreen;
typedef SpaceScreen = HomeScreen;
typedef Home = HomeScreen;

/// Space screen with full-space Windows Phone Metro live tiles grid and exclusive ambient particle canvas.
class HomeScreen extends StatelessWidget {
  /// Whether to display the bottom navigation bar. Defaults to true.
  final bool showBottomNav;

  /// Whether to mount the local [AmbientParticlesCanvas] backdrop behind this screen.
  final bool showAmbientBackdrop;

  /// Optional pre-loaded today's selection songs (retained for backward compatibility/testing).
  final List<Song>? initialTodaySongs;

  /// Optional pre-loaded favorites songs (retained for backward compatibility/testing).
  final List<Song>? initialFavoriteSongs;

  /// Optional pre-loaded pinned items (retained for backward compatibility/testing).
  final List<PinnedFavorite>? initialPinnedItems;

  /// Optional override to enable or disable the first-time Space intro tour.
  final bool? enableIntro;

  const HomeScreen({
    super.key,
    this.showBottomNav = true,
    this.showAmbientBackdrop = true,
    this.initialTodaySongs,
    this.initialFavoriteSongs,
    this.initialPinnedItems,
    this.enableIntro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: showAmbientBackdrop ? AppColors.bottomNavBackground : Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Exclusive dynamic PS3-style ambient particles
          if (showAmbientBackdrop) const AmbientParticlesCanvas(),

          // Space screen with full-screen Windows Phone Metro live tiles grid
          Scaffold(
            extendBody: true,
            backgroundColor: Colors.transparent,
            body: SpaceTilesGrid(
              initialPinnedItems: initialPinnedItems,
              initialFavoriteSongs: initialFavoriteSongs,
            ),
            bottomNavigationBar: showBottomNav
                ? const AppBottomNav(
                    currentIndex: 2,
                  )
                : null,
          ),

          // First-time onboarding tour for Space
          SpaceIntroOverlay(
            forceShow: enableIntro,
          ),
        ],
      ),
    );
  }
}

/// File: player_screen.dart
/// Description: Maximized Sony Music-styled music player screen featuring
/// monochromatic aesthetic, high-resolution album artwork, isolated scrubber bar,
/// circular navigation playback controls, and a minimalist dismiss chevron.
///
/// Components / Classes / Functions:
/// - PlayerScreen: Maximized player screen widget.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/player/components/player_artwork_view.dart';
import 'package:project_anima/features/player/components/player_controls.dart';
import 'package:project_anima/features/player/components/player_metadata_view.dart';
import 'package:project_anima/features/player/components/player_progress_bar.dart';

/// Full-screen maximized Sony Music-style player.
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  /// Factory helper for smooth bottom-to-top modal slide transition.
  static Route<void> route() {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
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
  Widget build(BuildContext context) {
    final controller = PlaybackController.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final song = controller.currentSong;

          return LayoutBuilder(
            builder: (context, constraints) {
              // Giant square cover at the top:
              // On portrait phones (e.g. 390x844), maxWidth < maxHeight * 0.52,
              // so coverHeight == maxWidth (an edge-to-edge 100% full-width giant square).
              // On shorter viewports or landscape/tests (e.g. 800x600), it scales cleanly
              // to maxHeight * 0.50 so that neither the cover nor the controls overflow.
              final double coverHeight = math.min(
                constraints.maxWidth,
                constraints.maxHeight * 0.50,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Giant Square Cover covering entire upper width with overlaid back arrow
                  PlayerArtworkView(
                    song: song,
                    height: coverHeight,
                    width: constraints.maxWidth,
                    onDismiss: () => Navigator.of(context).pop(),
                  ),

                  // 2. Lower Section: Metadata, M3 Expressive Wavy Progress Bar, Controls
                  Expanded(
                    child: SafeArea(
                      top: false,
                      child: LayoutBuilder(
                        builder: (context, lowerConstraints) {
                          return SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: lowerConstraints.maxHeight,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                  vertical: 8.0,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    PlayerMetadataView(song: song),
                                    PlayerProgressBar(controller: controller),
                                    PlayerControls(controller: controller),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

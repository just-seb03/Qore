/// File: player_screen.dart
/// Description: Maximized Sony Music-styled music player screen featuring
/// monochromatic aesthetic, high-resolution album artwork, isolated scrubber bar,
/// circular navigation playback controls, and a minimalist dismiss chevron.
///
/// Components / Classes / Functions:
/// - PlayerScreen: Maximized player screen widget.
library;

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
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final song = controller.currentSong;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Minimalist Header: Single Back / Dismiss Chevron
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 36.0,
                          color: AppColors.futuristicWhite,
                        ),
                        splashRadius: 24.0,
                        tooltip: 'Minimizar reproductor',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // 2. Upper Section: Prominent Album Artwork
                Expanded(
                  flex: 5,
                  child: PlayerArtworkView(
                    song: song,
                  ),
                ),

                const SizedBox(height: 16.0),

                // 3. Lower Section: Metadata Stack (Title, Artist, Album)
                PlayerMetadataView(
                  song: song,
                ),

                const SizedBox(height: 20.0),

                // 4. Scrubber / Progress Bar with Timestamps
                PlayerProgressBar(
                  controller: controller,
                ),

                const SizedBox(height: 16.0),

                // 5. Playback Controls Row (Shuffle, Prev, Play/Pause, Next, Repeat)
                PlayerControls(
                  controller: controller,
                ),

                const SizedBox(height: 28.0),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// File: mini_player.dart
/// Description: Global floating mini-player component situated above the bottom navigation bar.
/// Features rounded corners, subtle elevation, album cover art, song title and artist metadata,
/// and responsive playback controls (Previous, Play/Pause, Next) with isolated rebuild boundaries.
/// Tapping anywhere on the mini-player (except controls) opens the maximized player screen.
///
/// Components / Classes / Functions:
/// - MiniPlayer: Floating mini-player widget.
/// - _MiniPlayerProgressBar: Micro-height progress indicator at the base of the mini-player.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/player/screens/player_screen.dart';

/// Global floating mini-player bar positioned directly above the bottom navigation bar.
class MiniPlayer extends StatelessWidget {
  /// Custom controller instance override. Defaults to [PlaybackController.instance].
  final PlaybackController? controller;

  /// Optional callback override when mini-player card is tapped.
  /// Defaults to navigating to [PlayerScreen].
  final VoidCallback? onTap;

  const MiniPlayer({
    super.key,
    this.controller,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeController = controller ?? PlaybackController.instance;

    return ListenableBuilder(
      listenable: activeController,
      builder: (context, _) {
        final currentSong = activeController.currentSong;

        return AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: currentSong == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 8.0),
                  child: Container(
                    height: 58.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24),
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 14.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14.0),
                      child: Stack(
                        children: [
                          // 1. Tappable Card Surface
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14.0),
                              onTap: onTap ??
                                  () {
                                    Navigator.of(context).push(PlayerScreen.route());
                                  },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  children: [
                                    // 1. Album Artwork Thumbnail (Dual-Tier fast cache)
                                    AnimaArtworkImage(
                                      mediaStoreId: currentSong.mediaStoreId,
                                      albumId: currentSong.albumId,
                                      width: 44.0,
                                      height: 44.0,
                                      borderRadius: 8.0,
                                      isThumbnail: true,
                                      fit: BoxFit.cover,
                                      fallbackIcon: Icons.music_note_rounded,
                                    ),
                                    const SizedBox(width: 10.0),

                                    // 2. Song Metadata (Title + Artist)
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currentSong.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'Inconsolata',
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.futuristicWhite,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 2.0),
                                          Text(
                                            currentSong.artist ?? '<Desconocido>',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'Inconsolata',
                                              fontSize: 11.5,
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 3. Playback Controls Row (Prev, Play/Pause, Next)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Previous Track Button
                                        IconButton(
                                          icon: const Icon(
                                            Icons.skip_previous_rounded,
                                            size: 24.0,
                                            color: AppColors.futuristicWhite,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 36.0,
                                            minHeight: 36.0,
                                          ),
                                          splashRadius: 18.0,
                                          tooltip: 'Canción anterior',
                                          onPressed: () => activeController.skipToPrevious(),
                                        ),

                                        // Center Play / Pause Button
                                        IconButton(
                                          icon: Icon(
                                            activeController.isPlaying
                                                ? Icons.pause_rounded
                                                : Icons.play_arrow_rounded,
                                            size: 28.0,
                                            color: AppColors.futuristicWhite,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 38.0,
                                            minHeight: 38.0,
                                          ),
                                          splashRadius: 20.0,
                                          tooltip: activeController.isPlaying
                                              ? 'Pausar'
                                              : 'Reproducir',
                                          onPressed: () => activeController.togglePlayPause(),
                                        ),

                                        // Next Track Button
                                        IconButton(
                                          icon: const Icon(
                                            Icons.skip_next_rounded,
                                            size: 24.0,
                                            color: AppColors.futuristicWhite,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 36.0,
                                            minHeight: 36.0,
                                          ),
                                          splashRadius: 18.0,
                                          tooltip: 'Siguiente canción',
                                          onPressed: () => activeController.skipToNext(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // 2. Micro Progress Bar at base of card
                          Positioned(
                            left: 14.0,
                            right: 14.0,
                            bottom: 0.0,
                            child: _MiniPlayerProgressBar(
                              controller: activeController,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

/// Isolated micro-progress line at the bottom of the mini player card.
class _MiniPlayerProgressBar extends StatelessWidget {
  final PlaybackController controller;

  const _MiniPlayerProgressBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: controller.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = controller.duration;
        final double progress = total.inMilliseconds > 0
            ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(14.0),
            bottomRight: Radius.circular(14.0),
          ),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 2.0,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.futuristicWhite.withValues(alpha: 0.8),
            ),
          ),
        );
      },
    );
  }
}

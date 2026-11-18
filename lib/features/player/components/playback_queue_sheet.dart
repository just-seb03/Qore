/// File: playback_queue_sheet.dart
/// Description: Optimized modal bottom sheet displaying the active playback queue.
/// Lightweight and responsive without blur/bloom overhead, featuring Now Playing
/// header and reorderable list of upcoming tracks following the currently playing song.
///
/// Components / Classes / Functions:
/// - PlaybackQueueSheet: Global bottom sheet coordinator for upcoming playback queue.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Highly optimized modal bottom sheet presenting the audio playback queue.
class PlaybackQueueSheet extends StatelessWidget {
  const PlaybackQueueSheet({super.key});

  /// Displays the modal playback queue sheet globally over the active view.
  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (ctx) => const PlaybackQueueSheet(),
    );
  }

  String _formatDuration(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = PlaybackController.instance;
    final screenHeight = MediaQuery.of(context).size.height;

    // Direct solid flat Metro container without drop shadow or rounded corners
    return Container(
      height: screenHeight * 0.82,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.zero,
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final queue = controller.queue;
              final currentSong = controller.currentSong;
              final currentIndex = controller.currentIndex;

              // Display only upcoming tracks (excluding past songs and active current song)
              final upcomingSongs = (currentIndex >= 0 && currentIndex + 1 < queue.length)
                  ? queue.sublist(currentIndex + 1)
                  : (currentIndex < 0 && queue.isNotEmpty ? queue : const []);

              final int upcomingStartIndex = currentIndex >= 0 ? currentIndex + 1 : 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Drag Dismiss Handle
                  const SizedBox(height: 10.0),
                  Center(
                    child: ModalDismissIndicator(
                      onDismiss: () => Navigator.of(context).pop(),
                      size: 36.0,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 36.0),
                    ),
                  ),
                  const SizedBox(height: 14.0),

                  // 2. Now Playing Mini Card Header (visual representation of currently playing track)
                  if (currentSong != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        context.l10n.player.nowPlayingHeader,
                        style: AppFonts.segoe(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(
                            color: AppColors.outline.withValues(alpha: 0.25),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimaArtworkImage(
                              mediaStoreId: currentSong.mediaStoreId,
                              albumId: currentSong.albumId,
                              albumName: currentSong.album,
                              artistName: currentSong.artist,
                              width: 44.0,
                              height: 44.0,
                              borderRadius: 0.0,
                              isThumbnail: true,
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    currentSong.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppFonts.segoe(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    currentSong.artist ?? context.l10n.common.unknownArtist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppFonts.segoe(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w300,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                controller.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: AppColors.accent,
                                size: 28.0,
                              ),
                              onPressed: () => controller.togglePlayPause(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                  ],

                  // 3. Queue Section Title & Clear Action
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.player.upNextHeader(upcomingSongs.length),
                          style: AppFonts.segoe(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.5,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (upcomingSongs.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              controller.clearUpcomingQueue();
                              HapticFeedback.lightImpact();
                            },
                            style: TextButton.styleFrom(
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: Text(
                              context.l10n.player.clearQueue,
                              style: AppFonts.segoe(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w400,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4.0),

                  // 4. Reorderable Queue List of upcoming tracks
                  Expanded(
                    child: upcomingSongs.isEmpty
                        ? Center(
                            child: Text(
                              context.l10n.player.emptyQueue,
                              style: AppFonts.segoe(
                                fontSize: 14.0,
                                color: AppColors.onSurfaceDisabled,
                              ),
                            ),
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                            itemCount: upcomingSongs.length,
                            onReorderItem: (oldIndex, newIndex) {
                              controller.reorderQueue(
                                upcomingStartIndex + oldIndex,
                                upcomingStartIndex + newIndex,
                              );
                            },
                            itemBuilder: (context, index) {
                              final song = upcomingSongs[index];
                              final realIndex = upcomingStartIndex + index;

                              return Padding(
                                key: ValueKey('queue_song_${song.mediaStoreId}_$index'),
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.zero,
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                                    dense: true,
                                    leading: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 24.0,
                                          child: Text(
                                            '${index + 1}',
                                            textAlign: TextAlign.center,
                                            style: AppFonts.segoe(
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8.0),
                                        AnimaArtworkImage(
                                          mediaStoreId: song.mediaStoreId,
                                          albumId: song.albumId,
                                          albumName: song.album,
                                          artistName: song.artist,
                                          width: 38.0,
                                          height: 38.0,
                                          borderRadius: 0.0,
                                          isThumbnail: true,
                                        ),
                                      ],
                                    ),
                                    title: Text(
                                      song.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFonts.segoe(
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${song.artist ?? context.l10n.common.unknownArtist} • ${_formatDuration(song.duration)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFonts.segoe(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w300,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Remove from queue button
                                        IconButton(
                                          icon: Icon(
                                            Icons.close_rounded,
                                            size: 18.0,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints:
                                              const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
                                          splashRadius: 16.0,
                                          tooltip: 'Remove',
                                          onPressed: () {
                                            controller.removeFromQueue(realIndex);
                                          },
                                        ),
                                        // Drag reorder handle
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6.0, vertical: 8.0),
                                            child: Icon(
                                              Icons.drag_handle_rounded,
                                              size: 20.0,
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      controller.playFromQueue(realIndex);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

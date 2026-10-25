/// File: playback_queue_sheet.dart
/// Description: Global modal bottom sheet displaying the active playback queue.
/// Features a blurred backdrop, elevated dark container, Now Playing card header,
/// and reorderable track list with drag-and-drop reordering, swipe deletion, and direct playback.
///
/// Components / Classes / Functions:
/// - PlaybackQueueSheet: Global bottom sheet coordinator for playback queue management.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Global modal bottom sheet presenting the audio playback queue with reordering.
class PlaybackQueueSheet extends StatelessWidget {
  const PlaybackQueueSheet({super.key});

  /// Displays the modal playback queue sheet globally over the active view.
  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
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

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
      child: Container(
        height: screenHeight * 0.82,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.75),
              blurRadius: 32.0,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Material(
          color: const Color(0xFF131317),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.0,
            ),
          ),
          child: SafeArea(
            top: false,
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
              final queue = controller.queue;
              final currentSong = controller.currentSong;
              final currentIndex = controller.currentIndex;

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

                  // 2. Now Playing Mini Card Header (visual effect of mini-player sliding up)
                  if (currentSong != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        context.l10n.player.nowPlayingHeader,
                        style: GoogleFonts.inconsolata(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
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
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
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
                              borderRadius: 10.0,
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
                                    style: GoogleFonts.outfit(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    currentSong.artist ?? context.l10n.common.unknownArtist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inconsolata(
                                      fontSize: 12.5,
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
                                color: Colors.white,
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
                          context.l10n.player.upNextHeader(queue.length),
                          style: GoogleFonts.inconsolata(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (queue.length > 1)
                          TextButton(
                            onPressed: () {
                              controller.clearUpcomingQueue();
                              HapticFeedback.lightImpact();
                            },
                            child: Text(
                              context.l10n.player.clearQueue,
                              style: GoogleFonts.inconsolata(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4.0),

                  // 4. Reorderable Queue List
                  Expanded(
                    child: queue.isEmpty
                        ? Center(
                            child: Text(
                              context.l10n.player.emptyQueue,
                              style: GoogleFonts.inconsolata(
                                fontSize: 14.0,
                                color: AppColors.onSurfaceDisabled,
                              ),
                            ),
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                            itemCount: queue.length,
                            onReorderItem: (oldIndex, newIndex) {
                              controller.reorderQueue(oldIndex, newIndex);
                            },
                            itemBuilder: (context, index) {
                              final song = queue[index];
                              final isCurrent = index == currentIndex;

                              return Padding(
                                key: ValueKey('queue_song_${song.mediaStoreId}_$index'),
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Material(
                                  color: isCurrent
                                      ? AppColors.surfaceContainerHigh.withValues(alpha: 0.65)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                                  dense: true,
                                  leading: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 24.0,
                                        child: isCurrent && controller.isPlaying
                                            ? const Icon(
                                                Icons.equalizer_rounded,
                                                size: 16.0,
                                                color: Colors.white,
                                              )
                                            : Text(
                                                '${index + 1}',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.inconsolata(
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.w600,
                                                  color: isCurrent
                                                      ? Colors.white
                                                      : AppColors.onSurfaceVariant,
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
                                        borderRadius: 8.0,
                                        isThumbnail: true,
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14.5,
                                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                                      color: isCurrent ? Colors.white : const Color(0xFFEEEEEE),
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${song.artist ?? context.l10n.common.unknownArtist} • ${_formatDuration(song.duration)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inconsolata(
                                      fontSize: 12.0,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Remove from queue button
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 18.0,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
                                        splashRadius: 16.0,
                                        tooltip: 'Remove',
                                        onPressed: () {
                                          controller.removeFromQueue(index);
                                        },
                                      ),
                                      // Drag reorder handle
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
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
                                    controller.playFromQueue(index);
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
  ),
);
}
}

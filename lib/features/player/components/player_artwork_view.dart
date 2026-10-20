/// File: player_artwork_view.dart
/// Description: Full-width giant square album artwork component covering the entire
/// upper portion of the screen, featuring high-resolution decoding, top vignette scrim,
/// and overlaid dismiss chevron.
///
/// Components / Classes / Functions:
/// - PlayerArtworkView: Edge-to-edge square artwork container for the maximized player.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/song.dart';

/// Full-width edge-to-edge square artwork view occupying the upper screen.
class PlayerArtworkView extends StatelessWidget {
  /// The song whose artwork is to be displayed.
  final Song? song;

  /// Optional custom dismiss callback. Defaults to Navigator.pop.
  final VoidCallback? onDismiss;

  /// Target height for the artwork container.
  final double? height;

  /// Target width for the artwork container.
  final double? width;

  const PlayerArtworkView({
    super.key,
    required this.song,
    this.onDismiss,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final double effectiveWidth = width ?? screenWidth;
    final double effectiveHeight = height ?? screenWidth;

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight, // Edge-to-edge giant square covering full width
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Giant Cover Art (Full bleed, BoxFit.cover)
          if (song != null)
            AnimaArtworkImage(
              mediaStoreId: song!.mediaStoreId,
              albumId: song!.albumId,
              width: effectiveWidth,
              height: effectiveHeight,
              borderRadius: 0.0,
              isThumbnail: false,
              fit: BoxFit.cover,
              fallbackIcon: Icons.music_note_rounded,
            )
          else
            Container(
              color: const Color(0xFF141417),
              child: const Center(
                child: Icon(
                  Icons.music_note_rounded,
                  size: 96.0,
                  color: Color(0xFF4A4A52),
                ),
              ),
            ),

          // 2. Dismiss Chevron Button at top-left with localized frosted chip
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0, top: 8.0),
                child: Container(
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 30.0,
                      color: Colors.white,
                    ),
                    splashRadius: 20.0,
                    tooltip: 'Cerrar reproductor',
                    onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

  /// Target height for the artwork container.
  final double? height;

  /// Target width for the artwork container.
  final double? width;

  /// Optional callback to notify parent during an interactive vertical pull down.
  final ValueChanged<double>? onDragUpdate;

  /// Optional callback when an interactive drag completes.
  final ValueChanged<DragEndDetails>? onDragEnd;

  const PlayerArtworkView({
    super.key,
    required this.song,
    this.height,
    this.width,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final double effectiveWidth = width ?? screenWidth;
    final double effectiveHeight = height ?? screenWidth;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: onDragUpdate != null
          ? (details) => onDragUpdate!(details.primaryDelta ?? 0.0)
          : null,
      onVerticalDragEnd: onDragEnd,
      child: SizedBox(
        width: effectiveWidth,
        height: effectiveHeight, // Edge-to-edge giant square covering full width
        child: song != null
            ? AnimaArtworkImage(
                mediaStoreId: song!.mediaStoreId,
                albumId: song!.albumId,
                width: effectiveWidth,
                height: effectiveHeight,
                borderRadius: 0.0,
                isThumbnail: false,
                fit: BoxFit.cover,
                fallbackIcon: Icons.music_note_rounded,
              )
            : Container(
                color: const Color(0xFF141417),
                child: const Center(
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 96.0,
                    color: Color(0xFF4A4A52),
                  ),
                ),
              ),
      ),
    );
  }
}

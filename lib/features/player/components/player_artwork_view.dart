/// File: player_artwork_view.dart
/// Description: Sony Music-styled prominent album artwork presentation component
/// with elevation shadows, rounded corners, and high-resolution Frame 0 decoding.
///
/// Components / Classes / Functions:
/// - PlayerArtworkView: High-resolution artwork container for the maximized player.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/song.dart';

/// Prominent album artwork card for the maximized player view.
class PlayerArtworkView extends StatelessWidget {
  /// The song whose artwork is to be displayed.
  final Song? song;

  /// Explicit size constraint. If null, sizes responsively to viewport width.
  final double? size;

  const PlayerArtworkView({
    super.key,
    required this.song,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    // Responsive sizing: ensure artwork fits harmoniously on compact screens
    final double computedSize = size ??
        (screenWidth * 0.82).clamp(240.0, (screenHeight * 0.42).clamp(240.0, 360.0));

    return Center(
      child: Container(
        width: computedSize,
        height: computedSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 28.0,
              spreadRadius: 2.0,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: song != null
              ? AnimaArtworkImage(
                  mediaStoreId: song!.mediaStoreId,
                  albumId: song!.albumId,
                  width: computedSize,
                  height: computedSize,
                  borderRadius: 16.0,
                  isThumbnail: false,
                  fallbackIcon: Icons.music_note_rounded,
                )
              : Container(
                  color: const Color(0xFF181818),
                  child: const Center(
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 64.0,
                      color: Color(0xFF4A4A52),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

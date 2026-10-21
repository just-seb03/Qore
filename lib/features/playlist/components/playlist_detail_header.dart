/// File: playlist_detail_header.dart
/// Description: Dedicated header component for PlaylistDetailScreen.
/// Renders the large unrounded square playlist artwork with deep cinematic drop-shadow,
/// followed by an interactive action row with Shuffle on the left, centered title and
/// duration metadata, Play on the right, and an edit playlist action.
///
/// Components / Classes / Functions:
/// - PlaylistDetailHeader: Cohesive header component for playlist presentation.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Cohesive header for PlaylistDetailScreen displaying artwork, title, metadata,
/// and Shuffle toggle (left) and Play (right) icon action triggers.
class PlaylistDetailHeader extends StatelessWidget {
  final Playlist playlist;
  final int songCount;
  final int totalDurationMs;
  final bool isShuffleEnabled;
  final VoidCallback onPlay;
  final VoidCallback onToggleShuffle;

  const PlaylistDetailHeader({
    super.key,
    required this.playlist,
    required this.songCount,
    required this.totalDurationMs,
    required this.isShuffleEnabled,
    required this.onPlay,
    required this.onToggleShuffle,
  });

  String _formatTotalDuration(int totalMs) {
    if (totalMs <= 0) return '';
    final totalSeconds = totalMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '$hours hr $remainingMinutes min';
    }
    return '$minutes mins';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double coverSize = (screenSize.width - 88.0).clamp(220.0, 300.0);

    final durationStr = _formatTotalDuration(totalDurationMs);
    final countStr = '$songCount ${songCount == 1 ? "song" : "songs"}';
    final metadataSubtitle = durationStr.isNotEmpty ? '$countStr • $durationStr' : countStr;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Large Sharp Square Playlist Artwork with Deep Cinematic Shadow
        Container(
          width: coverSize,
          height: coverSize,
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 36.0,
                spreadRadius: 2.0,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildCoverWidget(coverSize),
        ),
        const SizedBox(height: 24.0),

        // 2. Interactive Controls Row: Shuffle Toggle (Left) | Title & Metadata (Center) | Play (Right)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Shuffle Toggle Icon (no background circle)
              IconButton(
                key: const ValueKey('playlist_detail_shuffle_button'),
                onPressed: songCount > 0 ? onToggleShuffle : null,
                icon: Icon(
                  Icons.shuffle_rounded,
                  size: 26.0,
                  color: isShuffleEnabled
                      ? AppColors.futuristicWhite
                      : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                tooltip: isShuffleEnabled ? 'Disable shuffle' : 'Enable shuffle',
                splashRadius: 22.0,
              ),
              const SizedBox(width: 8.0),

              // Center: Playlist Name & Metadata
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      playlist.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      metadataSubtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inconsolata(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),

              // Right: Play Action Icon (no background circle)
              IconButton(
                key: const ValueKey('playlist_detail_play_button'),
                onPressed: songCount > 0 ? onPlay : null,
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  size: 38.0,
                  color: AppColors.futuristicWhite,
                ),
                tooltip: 'Play playlist',
                splashRadius: 24.0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverWidget(double size) {
    if (playlist.coverPath != null && File(playlist.coverPath!).existsSync()) {
      return Image.file(
        File(playlist.coverPath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    if (playlist.firstMediaStoreId != null && playlist.firstMediaStoreId! > 0) {
      return AnimaArtworkImage(
        mediaStoreId: playlist.firstMediaStoreId!,
        width: size,
        height: size,
        borderRadius: 0.0,
        isThumbnail: false,
        fallbackIcon: Symbols.queue_music_rounded,
      );
    }

    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Symbols.queue_music_rounded,
          size: 72.0,
          color: AppColors.futuristicWhite.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

/// File: playlist_detail_header.dart
/// Description: Dedicated header component for PlaylistDetailScreen.
/// Renders the widescreen 1920x620 hero banner playlist artwork with deep cinematic shadow,
/// followed by an interactive action row with Shuffle on the left, centered title styled
/// with custom typography and duration metadata, and Play on the right.
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
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/playlist/utils/playlist_font_helper.dart';

/// Cohesive header for PlaylistDetailScreen displaying a 1920x620 hero banner, title, metadata,
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
    final durationStr = _formatTotalDuration(totalDurationMs);
    final countStr = '$songCount ${songCount == 1 ? "song" : "songs"}';
    final metadataSubtitle = durationStr.isNotEmpty ? '$countStr • $durationStr' : countStr;

    final titleStyle = getPlaylistTitleFont(
      playlist.fontFamily,
      baseStyle: const TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.3,
        shadows: [
          Shadow(
            color: Colors.black54,
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Large 1920x620 Widescreen Hero Banner with Cinematic Shadow
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AspectRatio(
            aspectRatio: 1920 / 620,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 32.0,
                    spreadRadius: 2.0,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRect(
                child: _buildCoverWidget(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20.0),

        // 2. Interactive Controls Row: Shuffle Toggle (Left) | Title & Metadata (Center) | Play (Right)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Shuffle Toggle Icon
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
                      style: titleStyle,
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

              // Right: Play / Pause Action Icon
              IconButton(
                key: const ValueKey('playlist_detail_play_button'),
                onPressed: songCount > 0 ? onPlay : null,
                icon: Icon(
                  playlist.id != null &&
                          PlaybackController.instance.activePlaylistId == playlist.id &&
                          PlaybackController.instance.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 38.0,
                  color: AppColors.futuristicWhite,
                ),
                tooltip: playlist.id != null &&
                        PlaybackController.instance.activePlaylistId == playlist.id &&
                        PlaybackController.instance.isPlaying
                    ? 'Pause playlist'
                    : 'Play playlist',
                splashRadius: 24.0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverWidget() {
    if (playlist.coverPath != null && File(playlist.coverPath!).existsSync()) {
      return Image.file(
        File(playlist.coverPath!),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    if (playlist.firstMediaStoreId != null && playlist.firstMediaStoreId! > 0) {
      return AnimaArtworkImage(
        mediaStoreId: playlist.firstMediaStoreId!,
        width: double.infinity,
        height: double.infinity,
        borderRadius: 0.0,
        isThumbnail: false,
        fit: BoxFit.cover,
        fallbackIcon: Symbols.queue_music_rounded,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF242436),
            Color(0xFF161622),
            Color(0xFF101018),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.crop_landscape_rounded,
              size: 52.0,
              color: AppColors.futuristicWhite.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 6.0),
            Text(
              'HERO BANNER 1920x620',
              style: GoogleFonts.inconsolata(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
                color: AppColors.futuristicWhite.withValues(alpha: 0.40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

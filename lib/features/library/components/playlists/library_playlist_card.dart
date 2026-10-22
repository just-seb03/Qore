/// File: library_playlist_card.dart
/// Description: Individual playlist card widget for the Library playlist list view.
/// Styled as a full-bleed 1920x620 hero banner with the playlist cover covering the
/// entire card space, custom selected typography for the title on the left margin,
/// and a prominent direct Play button on the right margin.
///
/// Components / Classes / Functions:
/// - LibraryPlaylistCard: Hero banner card widget for playlists in Library.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/playlist/utils/playlist_font_helper.dart';

/// Hero banner card widget rendering a playlist in the Library list view.
/// Features a 1920x620 aspect ratio, full-space cover artwork, gradient scrim,
/// left-aligned title with custom typography, and right-aligned Play trigger.
class LibraryPlaylistCard extends StatelessWidget {
  /// Playlist model data.
  final Playlist playlist;

  /// Callback when the playlist card is tapped.
  final VoidCallback? onTap;

  /// Callback when the right Play button is tapped.
  final VoidCallback? onPlayTap;

  const LibraryPlaylistCard({
    super.key,
    required this.playlist,
    this.onTap,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = getPlaylistTitleFont(
      playlist.fontFamily,
      baseStyle: const TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.4,
        shadows: [
          Shadow(
            color: Colors.black,
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
          Shadow(
            color: Colors.black54,
            blurRadius: 16.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
    );

    return AspectRatio(
      aspectRatio: 1920 / 620,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.70),
              blurRadius: 14.0,
              spreadRadius: 1.0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Hero Artwork spanning the whole card space
              _buildHeroCover(),

              // 2. Dual-gradient Scrim for maximum contrast and cinematic depth
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.88),
                      Colors.black.withValues(alpha: 0.60),
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.70),
                    ],
                    stops: const [0.0, 0.40, 0.70, 1.0],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.20),
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),

              // 3. Foreground Interactive Row: Left Title | Right Play Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  splashColor: Colors.white.withValues(alpha: 0.08),
                  highlightColor: Colors.white.withValues(alpha: 0.04),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Playlist Title (Custom Font, Large & Centered on Y axis)
                        Expanded(
                          child: Text(
                            playlist.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                        ),
                        const SizedBox(width: 14.0),

                        // Right: Floating Play / Pause Trigger Button
                        _buildPlayButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return ListenableBuilder(
      listenable: PlaybackController.instance,
      builder: (context, _) {
        final controller = PlaybackController.instance;
        final isThisPlaylistPlaying = playlist.id != null &&
            controller.activePlaylistId == playlist.id &&
            controller.isPlaying;

        return Material(
          color: isThisPlaylistPlaying
              ? AppColors.navIndicator.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.18),
          shape: const CircleBorder(),
          child: InkWell(
            key: ValueKey('library_playlist_play_${playlist.id ?? 0}'),
            customBorder: const CircleBorder(),
            onTap: onPlayTap ?? onTap,
            splashColor: AppColors.navIndicator.withValues(alpha: 0.4),
            child: Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isThisPlaylistPlaying
                      ? AppColors.futuristicWhite
                      : Colors.white.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isThisPlaylistPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 26.0,
                  color: AppColors.futuristicWhite,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCover() {
    // 1. Custom Picked Image Hero
    if (playlist.coverPath != null && File(playlist.coverPath!).existsSync()) {
      return Image.file(
        File(playlist.coverPath!),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      );
    }

    // 2. First Song Artwork Fallback
    if (playlist.firstMediaStoreId != null && playlist.firstMediaStoreId! > 0) {
      return AnimaArtworkImage(
        mediaStoreId: playlist.firstMediaStoreId!,
        width: double.infinity,
        height: double.infinity,
        borderRadius: 0.0,
        fallbackIcon: Symbols.queue_music_rounded,
        isThumbnail: false,
        fit: BoxFit.cover,
      );
    }

    // 3. Artistic Hero Gradient Pattern Fallback
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1E2E),
            Color(0xFF28283E),
            Color(0xFF14141E),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Symbols.queue_music_rounded,
          size: 56.0,
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

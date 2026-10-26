/// File: metro_playlist_tile.dart
/// Description: Windows Phone Metro rectangular live tile for a pinned Playlist.
/// Spans across 2 columns (2:1 aspect ratio), sharp 90-degree corners, zero shadows,
/// zero padding, custom typography, and vertical 3D perspective flip revealing the Playlist icon.
///
/// Components / Classes / Functions:
/// - MetroPlaylistTile: Rectangular live tile presenting a pinned playlist with vertical flip.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/home/components/metro_live_tile.dart';
import 'package:project_anima/features/playlist/screens/playlist_detail_screen.dart';
import 'package:project_anima/features/playlist/utils/playlist_font_helper.dart';

/// Rectangular Windows Phone Metro live tile for a pinned playlist.
class MetroPlaylistTile extends StatelessWidget {
  /// The pinned playlist entity.
  final PinnedFavorite playlistItem;

  /// Staggered initial delay for the flip animation.
  final Duration initialDelay;

  /// Optional tap callback override.
  final VoidCallback? onTap;

  /// Optional long press callback (e.g. unpin).
  final VoidCallback? onLongPress;

  const MetroPlaylistTile({
    super.key,
    required this.playlistItem,
    this.initialDelay = const Duration(seconds: 6),
    this.onTap,
    this.onLongPress,
  });

  Playlist _toPlaylist() {
    return Playlist(
      id: playlistItem.playlistId,
      name: playlistItem.title,
      coverPath: playlistItem.coverPath,
      fontFamily: playlistItem.fontFamily,
      firstMediaStoreId: playlistItem.representativeSongId,
      createdAt: playlistItem.pinnedAt.millisecondsSinceEpoch,
      updatedAt: playlistItem.pinnedAt.millisecondsSinceEpoch,
    );
  }

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    Navigator.of(context).push(
      PlaylistDetailScreen.route(
        playlist: _toPlaylist(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.0, // 2 columns wide by 1 row high
      child: MetroLiveTile(
        flipAxis: MetroFlipAxis.vertical,
        initialDelay: initialDelay,
        interval: const Duration(seconds: 16),
        onTap: () => _handleTap(context),
        onLongPress: onLongPress,
        front: _buildFront(context),
        back: _buildBack(context),
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    final titleStyle = getPlaylistTitleFont(
      playlistItem.fontFamily,
      baseStyle: const TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.3,
        shadows: [
          Shadow(
            color: Colors.black,
            blurRadius: 6.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );

    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Cover artwork
          _buildCover(),

          // 2. Linear gradient scrim for legibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.40),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // 3. Playlist title & subtitle
          Positioned(
            left: 14.0,
            right: 14.0,
            bottom: 12.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  playlistItem.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
                const SizedBox(height: 2.0),
                Text(
                  'PLAYLIST',
                  style: GoogleFonts.inconsolata(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover() {
    if (playlistItem.coverPath != null && File(playlistItem.coverPath!).existsSync()) {
      return Image.file(
        File(playlistItem.coverPath!),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      );
    }

    if (playlistItem.representativeSongId != null &&
        playlistItem.representativeSongId! > 0) {
      return AnimaArtworkImage(
        mediaStoreId: playlistItem.representativeSongId!,
        borderRadius: 0.0,
        fallbackIcon: Icons.queue_music_rounded,
        isThumbnail: false,
        fit: BoxFit.cover,
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceContainerHigh,
            AppColors.surfaceContainerHighest,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.queue_music_rounded,
          size: 48.0,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.queue_music_rounded,
              size: 48.0,
              color: AppColors.accent,
            ),
            const SizedBox(height: 8.0),
            Text(
              'PLAYLIST',
              style: GoogleFonts.inconsolata(
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

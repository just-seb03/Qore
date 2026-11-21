/// File: playlist_detail_header.dart
/// Description: Dedicated header component for PlaylistDetailScreen.
/// Renders the widescreen 1920x620 hero banner playlist artwork with deep cinematic shadow,
/// followed by an interactive action row with Shuffle on the left, centered title styled
/// with custom typography and duration metadata, and Play on the right.
///
/// Components / Classes / Functions:
/// - PlaylistDetailHeader: Cohesive header component for playlist presentation.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/components/favorite_heart_button.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/playlist/components/playlist_text_banner.dart';

/// Cohesive header for PlaylistDetailScreen displaying a 2:1 Space-styled banner with custom typography,
/// metadata, and Shuffle toggle (left), Play (center), and Favorite Heart (right) icon action triggers.
class PlaylistDetailHeader extends StatelessWidget {
  final Playlist playlist;
  final int songCount;
  final int totalDurationMs;
  final bool isShuffleEnabled;
  final VoidCallback onPlay;
  final VoidCallback onToggleShuffle;

  /// Whether the playlist is pinned to favorites.
  final bool isPinned;

  /// Callback when the favorite heart button is tapped.
  final VoidCallback? onToggleFavorite;

  /// Whether to render the 2:1 hero banner cover.
  final bool showHeroCover;

  /// Whether the playlist can be edited.
  final bool isEditable;

  /// Callback when edit button is tapped.
  final VoidCallback? onEdit;

  const PlaylistDetailHeader({
    super.key,
    required this.playlist,
    required this.songCount,
    required this.totalDurationMs,
    required this.isShuffleEnabled,
    required this.onPlay,
    required this.onToggleShuffle,
    this.isPinned = false,
    this.onToggleFavorite,
    this.showHeroCover = true,
    this.isEditable = false,
    this.onEdit,
  });

  String _formatTotalDuration(BuildContext context, int totalMs) {
    if (totalMs <= 0) return '';
    final totalSeconds = totalMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0) {
      return context.l10n.playlist.durationHoursMinutes(hours, remainingMinutes);
    }
    return context.l10n.playlist.durationMinutes(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final durationStr = _formatTotalDuration(context, totalDurationMs);
    final countStr = context.l10n.playlist.songCount(songCount);
    final metadataSubtitle = context.l10n.playlist.metadataSubtitle(
      countStr: countStr,
      durationStr: durationStr.isNotEmpty ? durationStr : null,
    );

    final titleStyle = AppFonts.light(
      fontSize: 28.0,
      color: AppColors.onBackground,
      letterSpacing: -0.4,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showHeroCover) ...[
          // 1. Flat Metro 2:1 Rectangular Cover (photo-only, title placed below like AlbumHeaderView)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: PlaylistTextBanner(
              title: playlist.name,
              coverPath: playlist.coverPath,
              representativeSongId: playlist.firstMediaStoreId,
              showTitle: false,
            ),
          ),
          const SizedBox(height: 22.0),
        ] else
          const SizedBox(height: 12.0),

        // 2. Playlist Name below Cover (Segoe UI Light, matching AlbumHeaderView)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            playlist.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
        ),
        const SizedBox(height: 6.0),

        // 3. Track count & duration (Centered, matching AlbumHeaderView)
        Text(
          metadataSubtitle,
          textAlign: TextAlign.center,
          style: AppFonts.segoe(
            fontSize: 13.0,
            fontWeight: FontWeight.w300,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 16.0),

        // 4. Centered Playlist Action Menu: Shuffle | Play/Pause | Favorite Heart
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
                    ? AppColors.accent
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              tooltip: isShuffleEnabled
                  ? context.l10n.playlist.disableShuffleTooltip
                  : context.l10n.playlist.enableShuffleTooltip,
              splashRadius: 22.0,
            ),
            const SizedBox(width: 20.0),

            // Center: Play / Pause Action Icon
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
                color: AppColors.accent,
              ),
              tooltip: playlist.id != null &&
                      PlaybackController.instance.activePlaylistId == playlist.id &&
                      PlaybackController.instance.isPlaying
                  ? context.l10n.playlist.pausePlaylistTooltip
                  : context.l10n.playlist.playPlaylistTooltip,
              splashRadius: 24.0,
            ),

            // Right: Favorite Heart Toggle Button (No circle background)
            if (onToggleFavorite != null) ...[
              const SizedBox(width: 20.0),
              FavoriteHeartButton(
                key: const ValueKey('playlist_detail_favorite_button'),
                isPinned: isPinned,
                onToggle: onToggleFavorite!,
                showBackground: false,
                size: 26.0,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

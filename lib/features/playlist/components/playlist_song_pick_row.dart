/// File: playlist_song_pick_row.dart
/// Description: Compact Metro song row for adding or removing tracks in playlist
/// creation and editing flows.
///
/// Components / Classes / Functions:
/// - PlaylistSongPickRow: Stateless song row with sharp artwork and Metro toggle box.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/core/utils/duration_formatter.dart';

/// Compact Metro song row used inside playlist creation and editing lists.
class PlaylistSongPickRow extends StatelessWidget {
  final Song song;
  final bool isSelected;
  final VoidCallback onTap;

  const PlaylistSongPickRow({
    super.key,
    required this.song,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final artistLabel = (song.artist == null || song.artist!.trim().isEmpty)
        ? context.l10n.common.unknownArtist
        : song.artist!;

    return Material(
      color: isSelected
          ? AppColors.accent.withValues(alpha: 0.12)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
                width: 0.6,
              ),
            ),
          ),
          child: Row(
            children: [
              AnimaArtworkImage(
                mediaStoreId: song.mediaStoreId,
                albumId: song.albumId,
                width: 44.0,
                height: 44.0,
                borderRadius: 0.0,
                fallbackIcon: Icons.music_note_rounded,
                isThumbnail: true,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.segoe(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '$artistLabel • ${formatDuration(Duration(milliseconds: song.duration))}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.segoe(
                        fontSize: 12.0,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10.0),
              Container(
                width: 30.0,
                height: 30.0,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.outline.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  isSelected ? Icons.check_rounded : Icons.add_rounded,
                  size: 17.0,
                  color: isSelected ? AppColors.onAccent : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

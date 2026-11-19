/// File: explore_metro_track_tile.dart
/// Description: Authentic Windows Phone Metro track row component for the Recientes section
/// in ExploreScreen. Features sharp 90-degree square artwork, Segoe UI Light/Semilight
/// typography, and playback coordination.
///
/// Components / Classes / Functions:
/// - ExploreMetroTrackTile: Track row widget conforming to Windows Phone Metro design principles.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/core/utils/duration_formatter.dart';

/// Authentic Windows Phone Metro track tile for recently played songs list.
class ExploreMetroTrackTile extends StatelessWidget {
  /// The song item to display.
  final Song song;

  /// Callback when the track row is tapped.
  final VoidCallback? onTap;

  const ExploreMetroTrackTile({
    super.key,
    required this.song,
    this.onTap,
  });

  String _formatDuration(int ms) => formatDurationMs(ms);

  @override
  Widget build(BuildContext context) {
    final artist = (song.artist != null &&
            song.artist!.isNotEmpty &&
            song.artist != "<Desconocido>" &&
            song.artist != "Unknown Artist")
        ? song.artist!
        : context.l10n.common.unknownArtist;

    final album = (song.album != null &&
            song.album!.isNotEmpty &&
            song.album != "<Desconocido>" &&
            song.album != "Unknown Album")
        ? song.album!
        : '';

    final subtitle = album.isNotEmpty ? '$artist • $album' : artist;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.3),
        highlightColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 7.0),
          child: Row(
            children: [
              // Sharp 90-degree square artwork
              AnimaArtworkImage(
                mediaStoreId: song.mediaStoreId,
                albumId: song.albumId,
                width: 44.0,
                height: 44.0,
                borderRadius: 0.0,
                isThumbnail: true,
              ),
              const SizedBox(width: 14.0),

              // Title and Artist/Album
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
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurface,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2.5),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.segoe(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w300,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),

              // Formatted Duration
              Text(
                _formatDuration(song.duration),
                style: AppFonts.segoe(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w300,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

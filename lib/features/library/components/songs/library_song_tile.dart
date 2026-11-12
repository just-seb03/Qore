/// File: library_song_tile.dart
/// Description: Authentic Windows Phone Metro track row component for the Songs section
/// in LibraryScreen. Features sharp 90-degree square artwork, Segoe UI Light/Semilight
/// typography, track duration, and playback coordination.
///
/// Components / Classes / Functions:
/// - LibrarySongTile: Track row widget conforming to Windows Phone Metro design principles.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Row tile presenting a song in the Library songs list.
class LibrarySongTile extends StatelessWidget {
  /// Strict fixed tile height matching virtualized ListView itemExtent.
  static const double tileHeight = 68.0;

  /// The song item to display.
  final Song song;

  /// Callback when the track row is tapped.
  final VoidCallback? onTap;

  const LibrarySongTile({
    super.key,
    required this.song,
    this.onTap,
  });

  static TextStyle get _titleStyle => AppFonts.segoe(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    letterSpacing: -0.1,
  );

  static TextStyle get _subtitleStyle => AppFonts.segoe(
    fontSize: 12.0,
    fontWeight: FontWeight.w300,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.1,
  );

  static TextStyle get _durationStyle => AppFonts.segoe(
    fontSize: 12.0,
    fontWeight: FontWeight.w300,
    color: AppColors.onSurfaceVariant.withValues(alpha: 0.65),
    letterSpacing: 0.2,
  );

  String _formatDuration(int ms) {
    final int totalSeconds = ms ~/ 1000;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

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

    return SizedBox(
      height: tileHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.3),
          highlightColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                // 1. Sharp 90-degree square artwork with subtle shadow
                Container(
                  width: 50.0,
                  height: 50.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.zero,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.40),
                        blurRadius: 5.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AnimaArtworkImage(
                    mediaStoreId: song.mediaStoreId,
                    albumId: song.albumId,
                    width: 50.0,
                    height: 50.0,
                    borderRadius: 0.0,
                    isThumbnail: true,
                    fallbackIcon: Icons.music_note_rounded,
                  ),
                ),
                const SizedBox(width: 14.0),

                // 2. Song Title and Artist/Album
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _titleStyle,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _subtitleStyle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10.0),

                // 3. Duration
                Text(
                  _formatDuration(song.duration),
                  style: _durationStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

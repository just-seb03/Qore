/// File: search_song_tile.dart
/// Description: Spotify-styled song row tile displaying 48x48 artwork, title,
/// artist and album subtitle, formatted duration, and options action.
///
/// Components / Classes / Functions:
/// - SearchSongTile: Reusable Spotify-styled song row tile.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Reusable Spotify-styled song row item.
class SearchSongTile extends StatelessWidget {
  /// The song entity to display.
  final Song song;

  /// Callback when the tile is tapped.
  final VoidCallback? onTap;

  /// Optional callback for the trailing options icon.
  final VoidCallback? onOptionsTap;

  const SearchSongTile({
    super.key,
    required this.song,
    this.onTap,
    this.onOptionsTap,
  });

  static TextStyle get _titleStyle => GoogleFonts.inconsolata(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static TextStyle get _artistAlbumStyle => GoogleFonts.inconsolata(
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle get _durationStyle => GoogleFonts.inconsolata(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  String _formatDuration(int ms) {
    final int totalSeconds = ms ~/ 1000;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoriteSongsDao.instance.favoritesRevision,
      builder: (context, _) {
        final isFav = FavoriteSongsDao.instance.isFavorite(song.mediaStoreId);
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
            : context.l10n.common.unknownAlbum;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.3),
            highlightColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // 48x48 Spotify-style square thumbnail
                  AnimaArtworkImage(
                    mediaStoreId: song.mediaStoreId,
                    albumId: song.albumId,
                    width: 48.0,
                    height: 48.0,
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
                          style: _titleStyle,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '$artist • $album',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _artistAlbumStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  // Favorite Heart Button (Direct toggle without playing)
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 20.0,
                      color: isFav ? AppColors.accent : AppColors.onSurfaceVariant.withValues(alpha: 0.65),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30.0, minHeight: 30.0),
                    splashRadius: 16.0,
                    tooltip: isFav
                        ? context.l10n.common.removeFromFavorites
                        : context.l10n.common.addToFavorites,
                    onPressed: () {
                      FavoriteSongsDao.instance.toggleFavorite(song);
                      HapticFeedback.lightImpact();
                    },
                  ),
                  // Add to queue icon
                  IconButton(
                    icon: Icon(
                      Icons.playlist_add_rounded,
                      size: 20.0,
                      color: AppColors.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28.0, minHeight: 28.0),
                    splashRadius: 16.0,
                    tooltip: context.l10n.common.addToQueue,
                    onPressed: () {
                      PlaybackController.instance.addToQueue(song);
                      HapticFeedback.lightImpact();
                    },
                  ),
                  const SizedBox(width: 4.0),
                  // Duration
                  Text(
                    _formatDuration(song.duration),
                    style: _durationStyle,
                  ),
                  const SizedBox(width: 8.0),
                  // Spotify more-options icon
                  IconButton(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20.0,
                      color: AppColors.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28.0, minHeight: 28.0),
                    splashRadius: 18.0,
                    onPressed: onOptionsTap,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

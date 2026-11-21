/// File: playlist_song_search_results.dart
/// Description: Search results panel presenting matched songs with instant add buttons
/// for assembling a playlist.
///
/// Components / Classes / Functions:
/// - PlaylistSongSearchResults: Stateless widget rendering matched song items.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Renders search results matching user query with quick add actions.
class PlaylistSongSearchResults extends StatelessWidget {
  final List<Song> results;
  final Set<int> addedSongIds;
  final ValueChanged<Song> onSongAdd;

  const PlaylistSongSearchResults({
    super.key,
    required this.results,
    required this.addedSongIds,
    required this.onSongAdd,
  });

  static TextStyle get _titleStyle => AppFonts.segoe(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static TextStyle get _artistStyle => AppFonts.segoe(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Center(
          child: Text(
            context.l10n.playlist.noSongsFound,
            style: AppFonts.segoe(
              fontSize: 13.5,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 40.0),
      physics: const BouncingScrollPhysics(),
      itemCount: results.length,
      separatorBuilder: (context, index) => Divider(
        color: AppColors.outlineVariant.withValues(alpha: 0.25),
        height: 1.0,
        indent: 64.0,
      ),
      itemBuilder: (context, index) {
        final song = results[index];
        final bool isAlreadyAdded = addedSongIds.contains(song.mediaStoreId);

        return Material(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.65),
          child: InkWell(
            onTap: () => onSongAdd(song),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                          style: _titleStyle,
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          song.artist ?? context.l10n.common.unknownArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _artistStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Tooltip(
                    message: isAlreadyAdded
                        ? context.l10n.playlist.alreadyAddedTooltip
                        : context.l10n.playlist.addToPlaylistTooltip,
                    child: Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        color: isAlreadyAdded
                            ? AppColors.accent
                            : AppColors.surfaceContainerHighest,
                        border: Border.all(
                          color: isAlreadyAdded
                              ? AppColors.accent
                              : AppColors.outline.withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        isAlreadyAdded ? Icons.check_rounded : Icons.add_rounded,
                        color: isAlreadyAdded
                            ? AppColors.onAccent
                            : AppColors.onSurface,
                        size: 18.0,
                      ),
                    ),
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

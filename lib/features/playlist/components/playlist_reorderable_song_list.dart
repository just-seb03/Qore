/// File: playlist_reorderable_song_list.dart
/// Description: Interactive reorderable list of songs selected for a playlist.
/// Provides drag handles for custom track sequencing and individual remove actions.
///
/// Components / Classes / Functions:
/// - PlaylistReorderableSongList: Stateful reorderable list of playlist tracks.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Reorderable track list component for the playlist editor.
class PlaylistReorderableSongList extends StatelessWidget {
  final List<Song> songs;
  final ValueChanged<int> onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  const PlaylistReorderableSongList({
    super.key,
    required this.songs,
    required this.onRemove,
    required this.onReorder,
  });

  static final TextStyle _headerStyle = GoogleFonts.inconsolata(
    fontSize: 13.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: AppColors.onSurfaceVariant,
  );

  static final TextStyle _emptyStyle = GoogleFonts.inconsolata(
    fontSize: 13.5,
    color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
  );

  static final TextStyle _titleStyle = GoogleFonts.inconsolata(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: AppColors.futuristicWhite,
  );

  static final TextStyle _artistStyle = GoogleFonts.inconsolata(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFB3B3B3),
  );

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.playlist_add_rounded,
                size: 40.0,
                color: AppColors.futuristicWhite.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12.0),
              Text(
                context.l10n.playlist.noSongsAddedYet,
                textAlign: TextAlign.center,
                style: _emptyStyle,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.playlist.tracksHeaderWithCount(songs.length),
                style: _headerStyle,
              ),
              Text(
                context.l10n.playlist.dragToReorder,
                style: GoogleFonts.inconsolata(
                  fontSize: 11.5,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: songs.length,
          buildDefaultDragHandles: false,
          onReorderItem: onReorder,
          itemBuilder: (context, index) {
            final song = songs[index];
            final itemKey = ValueKey('${song.mediaStoreId}_$index');

            return Material(
              key: itemKey,
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    // 1. Drag Handle
                    ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: const Icon(
                          Icons.drag_indicator_rounded,
                          size: 20.0,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ),

                    // 2. Track Artwork Thumbnail
                    AnimaArtworkImage(
                      mediaStoreId: song.mediaStoreId,
                      albumId: song.albumId,
                      width: 44.0,
                      height: 44.0,
                      borderRadius: 4.0,
                      fallbackIcon: Icons.music_note_rounded,
                      isThumbnail: true,
                    ),
                    const SizedBox(width: 12.0),

                    // 3. Song Title & Artist
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

                    // 4. Remove Button ('X')
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18.0,
                        color: Color(0xFF8E8E8E),
                      ),
                      onPressed: () => onRemove(index),
                      splashRadius: 18.0,
                      tooltip: context.l10n.playlist.removeTrackTooltip,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

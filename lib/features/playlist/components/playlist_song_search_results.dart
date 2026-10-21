/// File: playlist_song_search_results.dart
/// Description: Search results panel presenting matched songs with instant add buttons
/// for assembling a playlist.
///
/// Components / Classes / Functions:
/// - PlaylistSongSearchResults: Stateless widget rendering matched song items.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/song.dart';
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
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Center(
          child: Text(
            'No matching songs found in your library',
            style: GoogleFonts.inconsolata(
              fontSize: 13.5,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: results.length,
        separatorBuilder: (context, index) => Divider(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          height: 1.0,
          indent: 64.0,
        ),
        itemBuilder: (context, index) {
          final song = results[index];
          final bool isAlreadyAdded = addedSongIds.contains(song.mediaStoreId);

          return Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
              leading: AnimaArtworkImage(
                mediaStoreId: song.mediaStoreId,
                albumId: song.albumId,
                width: 44.0,
                height: 44.0,
                borderRadius: 4.0,
                fallbackIcon: Icons.music_note_rounded,
                isThumbnail: true,
              ),
              title: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _titleStyle,
              ),
              subtitle: Text(
                song.artist ?? 'Unknown Artist',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _artistStyle,
              ),
              trailing: IconButton(
                icon: Icon(
                  isAlreadyAdded ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                  color: isAlreadyAdded ? AppColors.navIndicator : AppColors.futuristicWhite,
                  size: 24.0,
                ),
                onPressed: () => onSongAdd(song),
                tooltip: isAlreadyAdded ? 'Already added' : 'Add to playlist',
              ),
              onTap: () => onSongAdd(song),
            ),
          );
        },
      ),
    );
  }
}

/// File: search_songs_section.dart
/// Description: Spotify-styled secondary songs section displaying a vertical list
/// strictly constrained to at most 5 songs with unified section header.
///
/// Components / Classes / Functions:
/// - SearchSongsSection: Modular songs list presentation section.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/features/search/components/cards/search_song_tile.dart';
import 'package:project_anima/features/search/components/common/search_section_header.dart';

/// Modular section presenting up to 5 matching songs.
class SearchSongsSection extends StatelessWidget {
  /// Matching songs to display (strictly constrained to <= 5).
  final List<Song> songs;

  /// Callback when a song is tapped.
  final ValueChanged<Song>? onSongTap;

  /// Whether to render the section header ('SONGS'). Defaults to true.
  final bool showHeader;

  /// Header title text. Defaults to 'SONGS'.
  final String headerTitle;

  /// Maximum songs to display. Defaults to 5.
  final int maxItems;

  const SearchSongsSection({
    super.key,
    required this.songs,
    this.onSongTap,
    this.showHeader = true,
    this.headerTitle = 'SONGS',
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const SizedBox.shrink();
    }

    final displaySongs = songs.take(maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader) ...[
          SearchSectionHeader(title: headerTitle),
          const SizedBox(height: 4.0),
        ],
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: displaySongs.length,
          itemBuilder: (context, index) {
            final song = displaySongs[index];
            return SearchSongTile(
              song: song,
              onTap: () => onSongTap?.call(song),
            );
          },
        ),
      ],
    );
  }
}

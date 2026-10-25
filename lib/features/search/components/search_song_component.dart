/// File: search_song_component.dart
/// Description: Spotify-styled modular search component for Songs.
/// Composes SearchTopResultCard and SearchSongsSection for clean encapsulation
/// and backward compatibility.
///
/// Components / Classes / Functions:
/// - SearchSongComponent: Composite widget presenting song search results.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/features/search/components/cards/search_top_result_card.dart';
import 'package:project_anima/features/search/components/sections/search_songs_section.dart';

export 'package:project_anima/features/search/components/cards/search_song_tile.dart';

/// Spotify-style Song presentation component for search results.
class SearchSongComponent extends StatelessWidget {
  /// The song to display as the prominent Top Result, if any.
  final Song? topResultSong;

  /// Secondary matching songs (strictly limited to at most 5).
  final List<Song> songs;

  /// Callback when a song item or top card is tapped.
  final ValueChanged<Song>? onSongTap;

  /// Callback when the play button is tapped on top result song.
  final ValueChanged<Song>? onPlayTap;

  /// Callback when the card body of top result song is tapped.
  final ValueChanged<Song>? onCardTap;

  /// Whether to render only as the Top Result card.
  final bool isTopResultOnly;

  const SearchSongComponent({
    super.key,
    this.topResultSong,
    this.songs = const [],
    this.onSongTap,
    this.onPlayTap,
    this.onCardTap,
    this.isTopResultOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isTopResultOnly && topResultSong != null) {
      return SearchTopResultCard.song(
        song: topResultSong!,
        onTap: () => (onCardTap ?? onSongTap)?.call(topResultSong!),
        onPlayTap: () => onPlayTap?.call(topResultSong!),
      );
    }

    if (songs.isEmpty && topResultSong == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topResultSong != null) ...[
          SearchTopResultCard.song(
            song: topResultSong!,
            onTap: () => (onCardTap ?? onSongTap)?.call(topResultSong!),
            onPlayTap: () => onPlayTap?.call(topResultSong!),
          ),
          const SizedBox(height: 24.0),
        ],
        if (songs.isNotEmpty)
          SearchSongsSection(
            songs: songs,
            onSongTap: onSongTap,
          ),
      ],
    );
  }
}

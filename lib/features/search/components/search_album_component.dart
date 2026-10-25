/// File: search_album_component.dart
/// Description: Spotify-styled modular search component for Albums.
/// Composes SearchTopResultCard and SearchAlbumsSection for clean encapsulation
/// and backward compatibility.
///
/// Components / Classes / Functions:
/// - SearchAlbumComponent: Composite widget presenting album search results.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/features/search/components/cards/search_top_result_card.dart';
import 'package:project_anima/features/search/components/sections/search_albums_section.dart';

export 'package:project_anima/features/search/components/cards/search_album_card.dart';

/// Spotify-style Album presentation component for search results.
class SearchAlbumComponent extends StatelessWidget {
  /// The album to display as the prominent Top Result, if any.
  final AlbumDiscoveryItem? topResultAlbum;

  /// Secondary albums matching the query or related to the top result.
  final List<AlbumDiscoveryItem> secondaryAlbums;

  /// Callback when an album card is tapped.
  final ValueChanged<AlbumDiscoveryItem>? onAlbumTap;

  /// Callback when the play button is tapped.
  final ValueChanged<AlbumDiscoveryItem>? onPlayTap;

  /// Whether to render only as the Top Result card.
  final bool isTopResultOnly;

  const SearchAlbumComponent({
    super.key,
    this.topResultAlbum,
    this.secondaryAlbums = const [],
    this.onAlbumTap,
    this.onPlayTap,
    this.isTopResultOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isTopResultOnly && topResultAlbum != null) {
      return SearchTopResultCard.album(
        album: topResultAlbum!,
        onTap: () => onAlbumTap?.call(topResultAlbum!),
        onPlayTap: () => onPlayTap?.call(topResultAlbum!),
      );
    }

    if (secondaryAlbums.isEmpty && topResultAlbum == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topResultAlbum != null) ...[
          SearchTopResultCard.album(
            album: topResultAlbum!,
            onTap: () => onAlbumTap?.call(topResultAlbum!),
            onPlayTap: () => onPlayTap?.call(topResultAlbum!),
          ),
          const SizedBox(height: 24.0),
        ],
        if (secondaryAlbums.isNotEmpty)
          SearchAlbumsSection(
            albums: secondaryAlbums,
            onAlbumTap: onAlbumTap,
          ),
      ],
    );
  }
}

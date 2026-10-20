/// File: search_albums_section.dart
/// Description: Spotify-styled secondary albums section displaying a horizontal carousel
/// of 130dp square album cards with unified section header.
///
/// Components / Classes / Functions:
/// - SearchAlbumsSection: Modular albums carousel presentation section.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/features/search/components/cards/search_album_card.dart';
import 'package:project_anima/features/search/components/common/search_section_header.dart';

/// Modular section presenting a horizontal carousel of matching albums.
class SearchAlbumsSection extends StatelessWidget {
  /// Matching albums to display.
  final List<AlbumDiscoveryItem> albums;

  /// Callback when an album card is tapped.
  final ValueChanged<AlbumDiscoveryItem>? onAlbumTap;

  /// Whether to render the section header ('ALBUMS'). Defaults to true.
  final bool showHeader;

  /// Header title text. Defaults to 'ALBUMS'.
  final String headerTitle;

  /// Height of the horizontal carousel. Defaults to 188.0.
  final double carouselHeight;

  const SearchAlbumsSection({
    super.key,
    required this.albums,
    this.onAlbumTap,
    this.showHeader = true,
    this.headerTitle = 'ALBUMS',
    this.carouselHeight = 188.0,
  });

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader) ...[
          SearchSectionHeader(title: headerTitle),
          const SizedBox(height: 6.0),
        ],
        SizedBox(
          height: carouselHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: albums.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16.0),
            itemBuilder: (context, index) {
              final album = albums[index];
              return SearchAlbumCard(
                album: album,
                onTap: () => onAlbumTap?.call(album),
              );
            },
          ),
        ),
      ],
    );
  }
}

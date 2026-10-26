/// File: search_artists_section.dart
/// Description: Spotify-styled secondary artists section displaying a horizontal carousel
/// of circular artist cards using native Material Design avatars.
///
/// Components / Classes / Functions:
/// - SearchArtistsSection: Modular artists carousel presentation section.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/features/search/components/cards/search_artist_card.dart';
import 'package:project_anima/features/search/components/common/search_section_header.dart';

/// Modular section presenting a horizontal carousel of matching artists.
class SearchArtistsSection extends StatelessWidget {
  /// Matching artists to display.
  final List<ArtistDiscoveryItem> artists;

  /// Callback when an artist card is tapped.
  final ValueChanged<ArtistDiscoveryItem>? onArtistTap;

  /// Whether to render the section header ('ARTISTS'). Defaults to true.
  final bool showHeader;

  /// Header title text. Defaults to localized 'ARTISTS'.
  final String? headerTitle;

  /// Height of the horizontal carousel. Defaults to 172.0.
  final double carouselHeight;

  const SearchArtistsSection({
    super.key,
    required this.artists,
    this.onArtistTap,
    this.showHeader = true,
    this.headerTitle,
    this.carouselHeight = 172.0,
  });

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader) ...[
          SearchSectionHeader(
            title: headerTitle ?? context.l10n.search.artistsSectionHeader,
          ),
          const SizedBox(height: 6.0),
        ],
        SizedBox(
          height: carouselHeight,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: artists.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16.0),
            itemBuilder: (context, index) {
              final artist = artists[index];
              return SearchArtistCard(
                artist: artist,
                onTap: () => onArtistTap?.call(artist),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// File: search_artist_component.dart
/// Description: Spotify-styled modular search component for Artists.
/// Composes SearchTopResultCard and SearchArtistsSection for clean encapsulation
/// and backward compatibility.
///
/// Components / Classes / Functions:
/// - SearchArtistComponent: Composite widget presenting artist search results.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/features/search/components/cards/search_top_result_card.dart';
import 'package:project_anima/features/search/components/sections/search_artists_section.dart';

export 'package:project_anima/features/search/components/cards/search_artist_card.dart';
export 'package:project_anima/features/search/components/common/material_artist_avatar.dart';

/// Spotify-style Artist presentation component using native Material Design avatars.
class SearchArtistComponent extends StatelessWidget {
  /// The artist to display as the prominent Top Result, if any.
  final ArtistDiscoveryItem? topResultArtist;

  /// Secondary artists matching the query or related to the top result.
  final List<ArtistDiscoveryItem> secondaryArtists;

  /// Callback when an artist card is tapped.
  final ValueChanged<ArtistDiscoveryItem>? onArtistTap;

  /// Callback when the play button is tapped.
  final ValueChanged<ArtistDiscoveryItem>? onPlayTap;

  /// Whether to render only as the Top Result card.
  final bool isTopResultOnly;

  const SearchArtistComponent({
    super.key,
    this.topResultArtist,
    this.secondaryArtists = const [],
    this.onArtistTap,
    this.onPlayTap,
    this.isTopResultOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isTopResultOnly && topResultArtist != null) {
      return SearchTopResultCard.artist(
        artist: topResultArtist!,
        onTap: () => onArtistTap?.call(topResultArtist!),
        onPlayTap: () => onPlayTap?.call(topResultArtist!),
      );
    }

    if (secondaryArtists.isEmpty && topResultArtist == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topResultArtist != null) ...[
          SearchTopResultCard.artist(
            artist: topResultArtist!,
            onTap: () => onArtistTap?.call(topResultArtist!),
            onPlayTap: () => onPlayTap?.call(topResultArtist!),
          ),
          const SizedBox(height: 24.0),
        ],
        if (secondaryArtists.isNotEmpty)
          SearchArtistsSection(
            artists: secondaryArtists,
            onArtistTap: onArtistTap,
          ),
      ],
    );
  }
}

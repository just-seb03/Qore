/// File: search_results_group.dart
/// Description: Aggregated search results container categorizing matches into Top Result,
/// relevant songs (strictly limited to 5), albums, and artists following Spotify's hierarchy.
///
/// Components / Classes / Functions:
/// - SearchResultsGroup: Immutable container holding structured, categorized search results.
library;

import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/search/models/search_entity_type.dart';
import 'package:project_anima/core/search/models/search_top_result.dart';

/// Structured results produced by the fuzzy search engine.
class SearchResultsGroup {
  /// The search query term.
  final String query;

  /// The most relevant winning result across all categories, if any.
  final SearchTopResult? topResult;

  /// Dominant category determining the display order of secondary sections.
  final SearchEntityType primaryType;

  /// List of matching songs, strictly constrained to at most 5 items.
  final List<Song> matchedSongs;

  /// List of matching albums (promoted or secondary).
  final List<AlbumDiscoveryItem> matchedAlbums;

  /// List of matching artists (promoted or secondary).
  final List<ArtistDiscoveryItem> matchedArtists;

  const SearchResultsGroup({
    required this.query,
    this.topResult,
    this.primaryType = SearchEntityType.song,
    this.matchedSongs = const [],
    this.matchedAlbums = const [],
    this.matchedArtists = const [],
  });

  /// Factory creating an empty result set for cleared or blank searches.
  factory SearchResultsGroup.empty([String query = '']) {
    return SearchResultsGroup(query: query);
  }

  /// Whether no matches were found across any category.
  bool get isEmpty =>
      topResult == null &&
      matchedSongs.isEmpty &&
      matchedAlbums.isEmpty &&
      matchedArtists.isEmpty;

  /// Whether at least one match was found.
  bool get isNotEmpty => !isEmpty;
}

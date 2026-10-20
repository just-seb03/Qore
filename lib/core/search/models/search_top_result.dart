/// File: search_top_result.dart
/// Description: Data model encapsulating the primary, highest-relevance search result
/// (Top Result) in a Spotify-styled search presentation.
///
/// Components / Classes / Functions:
/// - SearchTopResult: Generic wrapper for the top matched entity (Artist, Album, or Song).
library;

import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/search/models/search_entity_type.dart';

/// Encapsulates the most relevant result item matching a search query.
class SearchTopResult {
  /// Category classification of the top result.
  final SearchEntityType type;

  /// Normalized fuzzy similarity score [0.0 - 1.0].
  final double score;

  /// Associated artist instance if type == [SearchEntityType.artist].
  final ArtistDiscoveryItem? artist;

  /// Associated album instance if type == [SearchEntityType.album].
  final AlbumDiscoveryItem? album;

  /// Associated song instance if type == [SearchEntityType.song].
  final Song? song;

  const SearchTopResult._({
    required this.type,
    required this.score,
    this.artist,
    this.album,
    this.song,
  });

  /// Factory constructor for an Artist top result.
  factory SearchTopResult.artist(ArtistDiscoveryItem artist, double score) {
    return SearchTopResult._(
      type: SearchEntityType.artist,
      score: score,
      artist: artist,
    );
  }

  /// Factory constructor for an Album top result.
  factory SearchTopResult.album(AlbumDiscoveryItem album, double score) {
    return SearchTopResult._(
      type: SearchEntityType.album,
      score: score,
      album: album,
    );
  }

  /// Factory constructor for a Song top result.
  factory SearchTopResult.song(Song song, double score) {
    return SearchTopResult._(
      type: SearchEntityType.song,
      score: score,
      song: song,
    );
  }

  /// Display title of the top entity.
  String get title {
    switch (type) {
      case SearchEntityType.artist:
        return artist?.name ?? '';
      case SearchEntityType.album:
        return album?.name ?? '';
      case SearchEntityType.song:
        return song?.title ?? '';
    }
  }

  /// Secondary subtitle text for the entity (e.g. artist name, tracks count).
  String get subtitle {
    switch (type) {
      case SearchEntityType.artist:
        final songs = artist?.songCount ?? 0;
        final albums = artist?.albumCount ?? 0;
        return '$songs ${songs == 1 ? "track" : "tracks"} • $albums ${albums == 1 ? "album" : "albums"}';
      case SearchEntityType.album:
        return album?.artist ?? '<Desconocido>';
      case SearchEntityType.song:
        return song?.artist ?? '<Desconocido>';
    }
  }

  /// Representative MediaStore ID for artwork thumbnail lookup.
  int get mediaStoreId {
    switch (type) {
      case SearchEntityType.artist:
        return artist?.representativeSongId ?? 0;
      case SearchEntityType.album:
        return album?.representativeSongId ?? 0;
      case SearchEntityType.song:
        return song?.mediaStoreId ?? 0;
    }
  }

  /// Representative Album ID if applicable.
  int? get albumId {
    switch (type) {
      case SearchEntityType.artist:
        return artist?.representativeAlbumId;
      case SearchEntityType.album:
        return album?.albumId;
      case SearchEntityType.song:
        return song?.albumId;
    }
  }
}

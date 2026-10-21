/// File: recent_search_item.dart
/// Description: Immutable domain model representing a clicked entity (Song, Album, or Artist)
/// stored in SQLite for the Recent Searches feature (MRU with max limit 20).
///
/// Components / Classes / Functions:
/// - RecentSearchType: Enum defining the supported entity categories.
/// - RecentSearchItem: Aggregated model containing entity pointers, artwork references, and timestamps.
library;

import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';

/// Supported recent search entity types.
enum RecentSearchType {
  song,
  album,
  artist;

  static RecentSearchType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'song':
        return RecentSearchType.song;
      case 'album':
        return RecentSearchType.album;
      case 'artist':
        return RecentSearchType.artist;
      default:
        return RecentSearchType.song;
    }
  }
}

/// Represents an entity clicked by the user during search for quick reselection.
class RecentSearchItem {
  /// SQLite primary key ID.
  final int? id;

  /// Entity category (song, album, artist).
  final RecentSearchType type;

  /// Unique compound key to eliminate duplicates (e.g. "song:101", "album:donda:kanye west").
  final String entityKey;

  /// Display title (track title, album name, or artist name).
  final String title;

  /// Subtitle providing category context (e.g. "Canción • Queen", "Álbum • Kanye West", "Artista").
  final String subtitle;

  /// MediaStore ID of a representative track used for artwork lookup.
  final int representativeSongId;

  /// Optional album ID used as fallback identifier for artwork.
  final int? albumId;

  /// Unix timestamp in seconds of when this item was clicked.
  final int timestampSeconds;

  const RecentSearchItem({
    this.id,
    required this.type,
    required this.entityKey,
    required this.title,
    required this.subtitle,
    required this.representativeSongId,
    this.albumId,
    required this.timestampSeconds,
  });

  /// Creates a [RecentSearchItem] from a clicked [Song].
  factory RecentSearchItem.fromSong(Song song) {
    final artistStr = (song.artist != null &&
            song.artist!.trim().isNotEmpty &&
            song.artist != '<Desconocido>' &&
            song.artist != 'Unknown Artist')
        ? song.artist!.trim()
        : 'Unknown Artist';

    return RecentSearchItem(
      type: RecentSearchType.song,
      entityKey: 'song:${song.mediaStoreId}',
      title: song.title,
      subtitle: 'Song • $artistStr',
      representativeSongId: song.mediaStoreId,
      albumId: song.albumId,
      timestampSeconds: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Creates a [RecentSearchItem] from a clicked [AlbumDiscoveryItem].
  factory RecentSearchItem.fromAlbum(AlbumDiscoveryItem album) {
    final cleanAlbum = album.name.trim().toLowerCase();
    final cleanArtist = album.artist.trim().toLowerCase();
    final artistStr = album.artist.isEmpty || album.artist == '<Desconocido>'
        ? 'Unknown Artist'
        : album.artist;

    return RecentSearchItem(
      type: RecentSearchType.album,
      entityKey: 'album:$cleanAlbum:$cleanArtist',
      title: album.name,
      subtitle: 'Album • $artistStr',
      representativeSongId: album.representativeSongId,
      albumId: album.albumId,
      timestampSeconds: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Creates a [RecentSearchItem] from a clicked [ArtistDiscoveryItem].
  factory RecentSearchItem.fromArtist(ArtistDiscoveryItem artist) {
    return RecentSearchItem(
      type: RecentSearchType.artist,
      entityKey: 'artist:${artist.name.trim().toLowerCase()}',
      title: artist.name,
      subtitle: 'Artist',
      representativeSongId: artist.representativeSongId,
      albumId: artist.representativeAlbumId,
      timestampSeconds: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Extracts the pure artist name from [subtitle] or [entityKey],
  /// stripping category prefixes like 'Album • ', 'Álbum • ', 'Song • ', 'Canción • ',
  /// or legacy/lowercase formats like 'album ', 'álbum '.
  String? get cleanArtistName {
    if (type == RecentSearchType.artist) {
      return title.trim().isNotEmpty ? title.trim() : null;
    }

    var candidate = sanitizeArtistName(subtitle);

    // Fallback: extract from entityKey if candidate is null or empty
    if ((candidate == null || candidate.isEmpty) &&
        type == RecentSearchType.album &&
        entityKey.startsWith('album:')) {
      final parts = entityKey.split(':');
      if (parts.length >= 3) {
        final artistFromKey = parts.sublist(2).join(':').trim();
        if (artistFromKey.isNotEmpty &&
            artistFromKey != 'unknown artist' &&
            artistFromKey != '<desconocido>') {
          return artistFromKey;
        }
      }
    }

    return candidate;
  }

  /// Convenience getter returning [cleanArtistName].
  String? get artistName => cleanArtistName;

  /// Static helper to sanitize raw artist strings by stripping prefixes.
  static String? sanitizeArtist(String? raw) => sanitizeArtistName(raw);

  /// Converts this item to a map for SQLite persistence.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'entity_type': type.name,
      'entity_key': entityKey,
      'title': title,
      'subtitle': subtitle,
      'representative_song_id': representativeSongId,
      'album_id': albumId,
      'searched_at': timestampSeconds,
    };
  }

  /// Reconstitutes a [RecentSearchItem] from an SQLite record.
  factory RecentSearchItem.fromMap(Map<String, dynamic> map) {
    String subtitle = (map['subtitle'] as String?) ?? '';
    if (subtitle.startsWith('Canción • ')) {
      subtitle = 'Song • ${subtitle.substring(10)}';
    } else if (subtitle.startsWith('Álbum • ')) {
      subtitle = 'Album • ${subtitle.substring(8)}';
    } else if (subtitle == 'Artista') {
      subtitle = 'Artist';
    }

    return RecentSearchItem(
      id: (map['id'] as num?)?.toInt(),
      type: RecentSearchType.fromString((map['entity_type'] as String?) ?? 'song'),
      entityKey: (map['entity_key'] as String?) ?? '',
      title: (map['title'] as String?) ?? 'Unknown Title',
      subtitle: subtitle,
      representativeSongId: (map['representative_song_id'] as num?)?.toInt() ?? 0,
      albumId: (map['album_id'] as num?)?.toInt(),
      timestampSeconds: (map['searched_at'] as num?)?.toInt() ?? 0,
    );
  }

  RecentSearchItem copyWith({
    int? id,
    RecentSearchType? type,
    String? entityKey,
    String? title,
    String? subtitle,
    int? representativeSongId,
    int? albumId,
    int? timestampSeconds,
  }) {
    return RecentSearchItem(
      id: id ?? this.id,
      type: type ?? this.type,
      entityKey: entityKey ?? this.entityKey,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      representativeSongId: representativeSongId ?? this.representativeSongId,
      albumId: albumId ?? this.albumId,
      timestampSeconds: timestampSeconds ?? this.timestampSeconds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentSearchItem &&
          runtimeType == other.runtimeType &&
          entityKey == other.entityKey;

  @override
  int get hashCode => entityKey.hashCode;

  @override
  String toString() {
    return 'RecentSearchItem(type: ${type.name}, title: $title, key: $entityKey, time: $timestampSeconds)';
  }
}

/// Utility function to sanitize raw artist strings by stripping prefixes
/// like 'Album • ', 'Álbum • ', 'album ', 'song • ', etc.
String? sanitizeArtistName(String? raw) {
  if (raw == null) return null;
  final rawSubtitle = raw.trim();
  String? candidate;

  if (rawSubtitle.contains('•')) {
    final parts = rawSubtitle.split('•');
    candidate = parts.sublist(1).join('•').trim();
  } else if (rawSubtitle.isNotEmpty) {
    final lower = rawSubtitle.toLowerCase();
    const prefixes = [
      'album •',
      'álbum •',
      'song •',
      'canción •',
      'artist •',
      'artista •',
      'album:',
      'álbum:',
      'album -',
      'álbum -',
      'album ',
      'álbum ',
      'song ',
      'canción ',
      'artist ',
      'artista ',
    ];
    bool matched = false;
    for (final p in prefixes) {
      if (lower.startsWith(p)) {
        candidate = rawSubtitle.substring(p.length).trim();
        matched = true;
        break;
      }
    }
    if (!matched) {
      candidate = rawSubtitle;
    }
  }

  if (candidate != null) {
    final lowerCand = candidate.toLowerCase();
    if (candidate.isEmpty ||
        candidate == '<Desconocido>' ||
        lowerCand == 'unknown artist' ||
        lowerCand == 'album' ||
        lowerCand == 'álbum' ||
        lowerCand == 'song' ||
        lowerCand == 'canción' ||
        lowerCand == 'artist' ||
        lowerCand == 'artista') {
      candidate = null;
    }
  }

  return candidate;
}

/// Backward compatible alias for [sanitizeArtistName].
String? sanitizeArtist(String? raw) => sanitizeArtistName(raw);

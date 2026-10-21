/// File: pinned_favorite.dart
/// Description: Immutable domain model representing a user-pinned favorite item (album, artist, or playlist)
/// displayed on the Home screen.
///
/// Components / Classes / Functions:
/// - PinnedItemType: Enum distinguishing album, artist, and playlist favorites.
/// - PinnedFavorite: Data class encapsulating pinned entity metadata.
library;

/// Type of entity pinned by the user.
enum PinnedItemType {
  album,
  artist,
  playlist;

  static PinnedItemType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'album':
        return PinnedItemType.album;
      case 'artist':
        return PinnedItemType.artist;
      case 'playlist':
        return PinnedItemType.playlist;
      default:
        return PinnedItemType.album;
    }
  }

  String toDbString() => name;
}

/// Domain model representing an album, artist, or playlist pinned to Home favorites.
class PinnedFavorite {
  /// Primary key in SQLite.
  final int? id;

  /// Type of pinned entity.
  final PinnedItemType itemType;

  /// Deterministic unique key (e.g. 'album::title::artist', 'artist::name', 'playlist::id').
  final String itemKey;

  /// Display title (album name, artist name, or playlist name).
  final String title;

  /// Optional subtitle (artist name for albums, 'Artist', or song count for playlists).
  final String? subtitle;

  /// MediaStore ID for Frame 0 artwork resolution.
  final int? representativeSongId;

  /// Android MediaStore album ID if applicable.
  final int? albumId;

  /// SQLite playlist ID if applicable.
  final int? playlistId;

  /// Optional filesystem path to custom hero/avatar cover.
  final String? coverPath;

  /// Optional custom typography font family (for playlists).
  final String? fontFamily;

  /// Timestamp when the item was pinned.
  final DateTime pinnedAt;

  const PinnedFavorite({
    this.id,
    required this.itemType,
    required this.itemKey,
    required this.title,
    this.subtitle,
    this.representativeSongId,
    this.albumId,
    this.playlistId,
    this.coverPath,
    this.fontFamily,
    required this.pinnedAt,
  });

  bool get isAlbum => itemType == PinnedItemType.album;
  bool get isArtist => itemType == PinnedItemType.artist;
  bool get isPlaylist => itemType == PinnedItemType.playlist;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'item_type': itemType.toDbString(),
      'item_key': itemKey,
      'title': title,
      'subtitle': subtitle,
      'representative_song_id': representativeSongId,
      'album_id': albumId,
      'playlist_id': playlistId,
      'cover_path': coverPath,
      'font_family': fontFamily,
      'pinned_at': pinnedAt.millisecondsSinceEpoch,
    };
  }

  factory PinnedFavorite.fromMap(Map<String, dynamic> map) {
    return PinnedFavorite(
      id: (map['id'] as num?)?.toInt(),
      itemType: PinnedItemType.fromString((map['item_type'] as String?) ?? 'album'),
      itemKey: (map['item_key'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      subtitle: map['subtitle'] as String?,
      representativeSongId: (map['representative_song_id'] as num?)?.toInt(),
      albumId: (map['album_id'] as num?)?.toInt(),
      playlistId: (map['playlist_id'] as num?)?.toInt(),
      coverPath: map['cover_path'] as String?,
      fontFamily: map['font_family'] as String?,
      pinnedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['pinned_at'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  @override
  String toString() {
    return 'PinnedFavorite(type: ${itemType.name}, key: $itemKey, title: $title)';
  }
}

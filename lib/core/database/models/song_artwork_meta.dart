/// File: song_artwork_meta.dart
/// Description: Lightweight projection representing the minimal metadata required by the artwork pipeline.
/// Avoids loading full [Song] instances (20+ fields) into Dart heap during artwork preloading.
///
/// Components / Classes / Functions:
/// - SongArtworkMeta: Data class containing minimal track identifiers and album metadata.
library;

import 'package:project_anima/core/database/models/song.dart';

/// Lightweight projection model for artwork lookup and preloading.
class SongArtworkMeta {
  /// Android MediaStore ID or unique track identifier.
  final int mediaStoreId;

  /// Album ID from MediaStore if available.
  final int? albumId;

  /// Album title.
  final String? album;

  /// Performing track artist.
  final String? artist;

  /// Dedicated album artist.
  final String? albumArtist;

  /// Filesystem path to the audio file for on-demand extraction.
  final String path;

  const SongArtworkMeta({
    required this.mediaStoreId,
    this.albumId,
    this.album,
    this.artist,
    this.albumArtist,
    required this.path,
  });

  /// Converts this lightweight metadata to a minimal [Song] for background extraction queueing.
  Song toSong() {
    return Song(
      mediaStoreId: mediaStoreId,
      title: '',
      artist: artist,
      album: album,
      albumArtist: albumArtist,
      albumId: albumId,
      duration: 0,
      path: path,
      dateModified: 0,
    );
  }
}


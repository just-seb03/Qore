/// File: lightweight_audio_item.dart
/// Description: Lightweight projection DTO extracted from MediaStore or filesystem in Phase 1.
/// Encapsulates essential identifiers and timestamps passed into worker isolates for Phase 3 deep scan.
///
/// Components / Classes / Functions:
/// - LightweightAudioItem: Lightweight audio metadata container.
library;

/// Represents minimal metadata fetched during Phase 1 projection.
class LightweightAudioItem {
  final int mediaStoreId;
  final String path;
  final int dateModified;
  final int? dateAdded;
  final int duration;
  final int? size;
  final String fallbackTitle;
  final String? fallbackArtist;
  final String? fallbackAlbum;
  final String? fallbackAlbumArtist;
  final int? albumId;

  const LightweightAudioItem({
    required this.mediaStoreId,
    required this.path,
    required this.dateModified,
    this.dateAdded,
    required this.duration,
    this.size,
    required this.fallbackTitle,
    this.fallbackArtist,
    this.fallbackAlbum,
    this.fallbackAlbumArtist,
    this.albumId,
  });
}

/// File: artwork_batch_item.dart
/// Description: Data models for background Isolate artwork processing.
/// Transfers file paths and target directories between the main thread and worker isolates.
///
/// Components / Classes / Functions:
/// - ArtworkBatchItem: Encapsulates item arguments sent to the worker isolate.
/// - ArtworkBatchResultItem: Encapsulates output paths and status returned from the worker isolate.
library;

/// Parameters sent to the worker isolate for image extraction and resizing.
class ArtworkBatchItem {
  final int mediaStoreId;
  final int? albumId;
  final String filePath;
  final String thumbnailTargetDirectory;
  final String coverTargetDirectory;

  const ArtworkBatchItem({
    required this.mediaStoreId,
    this.albumId,
    required this.filePath,
    required this.thumbnailTargetDirectory,
    required this.coverTargetDirectory,
  });
}

/// Result returned from the worker isolate after processing an item.
class ArtworkBatchResultItem {
  final int mediaStoreId;
  final int? albumId;
  final String? thumbnailPath;
  final String? coverPath;
  final bool hasArtwork;

  const ArtworkBatchResultItem({
    required this.mediaStoreId,
    this.albumId,
    this.thumbnailPath,
    this.coverPath,
    required this.hasArtwork,
  });
}

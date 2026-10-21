/// File: artwork_processor.dart
/// Description: Top-level background Isolate worker for extracting, decoding, resizing,
/// and saving dual-tier album artworks (100x100 thumbnails and 800x800 quality 85% covers).
///
/// Components / Classes / Functions:
/// - processArtworkBatchInIsolate: Top-level worker function executing inside a Dart isolate.
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:project_anima/core/artwork/models/artwork_batch_item.dart';

/// Standard common filenames used by desktop and mobile music apps for local album art.
const List<String> _kFolderArtworkCandidates = [
  'cover.jpg',
  'cover.png',
  'cover.jpeg',
  'folder.jpg',
  'folder.png',
  'front.jpg',
  'front.png',
  'albumart.jpg',
  'albumart.png',
  'artwork.jpg',
];

/// Top-level worker function that extracts and resizes album covers in a background isolate.
/// Keeps CPU-intensive image decoding and encoding off the main UI event loop.
List<ArtworkBatchResultItem> processArtworkBatchInIsolate(List<ArtworkBatchItem> items) {
  final List<ArtworkBatchResultItem> results = [];

  for (final item in items) {
    try {
      final String thumbJpgPath = p.join(item.thumbnailTargetDirectory, '${item.mediaStoreId}.jpg');
      final String thumbPngPath = p.join(item.thumbnailTargetDirectory, '${item.mediaStoreId}.png');
      final String coverPath = p.join(item.coverTargetDirectory, '${item.mediaStoreId}.jpg');

      final thumbJpg = File(thumbJpgPath);
      final thumbPng = File(thumbPngPath);
      final coverFile = File(coverPath);

      final String actualThumbPath = thumbJpg.existsSync() ? thumbJpgPath : thumbPngPath;
      final bool hasThumb = thumbJpg.existsSync() || thumbPng.existsSync();

      // Fast check: if both already exist on disk, return immediately
      if (hasThumb && coverFile.existsSync()) {
        results.add(ArtworkBatchResultItem(
          mediaStoreId: item.mediaStoreId,
          albumId: item.albumId,
          thumbnailPath: actualThumbPath,
          coverPath: coverPath,
          hasArtwork: true,
        ));
        continue;
      }

      final audioFile = File(item.filePath);
      if (!audioFile.existsSync()) {
        results.add(ArtworkBatchResultItem(
          mediaStoreId: item.mediaStoreId,
          albumId: item.albumId,
          hasArtwork: false,
        ));
        continue;
      }

      // 1. Extract embedded artwork from audio tags
      Uint8List? rawPictureBytes;
      try {
        final metadata = readMetadata(audioFile, getImage: true);
        if (metadata.pictures.isNotEmpty) {
          rawPictureBytes = metadata.pictures.first.bytes;
        }
      } catch (_) {
        // Fallback to directory heuristics on metadata error
      }

      // 2. Folder heuristics fallback if tags have no embedded image
      if (rawPictureBytes == null || rawPictureBytes.isEmpty) {
        final parentDir = audioFile.parent;
        for (final candidate in _kFolderArtworkCandidates) {
          final candidateFile = File(p.join(parentDir.path, candidate));
          if (candidateFile.existsSync()) {
            try {
              rawPictureBytes = candidateFile.readAsBytesSync();
              if (rawPictureBytes.isNotEmpty) break;
            } catch (_) {}
          }
        }
      }

      // If no picture found anywhere
      if (rawPictureBytes == null || rawPictureBytes.isEmpty) {
        results.add(ArtworkBatchResultItem(
          mediaStoreId: item.mediaStoreId,
          albumId: item.albumId,
          hasArtwork: false,
        ));
        continue;
      }

      // 3. Decode picture bytes
      final decoded = img.decodeImage(rawPictureBytes);
      if (decoded == null) {
        results.add(ArtworkBatchResultItem(
          mediaStoreId: item.mediaStoreId,
          albumId: item.albumId,
          hasArtwork: false,
        ));
        continue;
      }

      // 4. Generate 200x200 Thumbnail (JPEG quality 85% for 10x faster encoding than PNG)
      final thumbnailImg = img.copyResize(
        decoded,
        width: 200,
        height: 200,
        interpolation: img.Interpolation.linear,
      );
      final thumbBytes = img.encodeJpg(thumbnailImg, quality: 85);
      thumbJpg.writeAsBytesSync(thumbBytes, flush: true);

      // 5. Generate high-fidelity Cover (JPEG quality 85% at max 600x600)
      final img.Image coverImg;
      if (decoded.width > 600 || decoded.height > 600) {
        coverImg = img.copyResize(
          decoded,
          width: 600,
          height: 600,
          interpolation: img.Interpolation.linear,
        );
      } else {
        coverImg = decoded;
      }
      final coverBytes = img.encodeJpg(coverImg, quality: 85);
      coverFile.writeAsBytesSync(coverBytes, flush: true);

      results.add(ArtworkBatchResultItem(
        mediaStoreId: item.mediaStoreId,
        albumId: item.albumId,
        thumbnailPath: thumbJpgPath,
        coverPath: coverPath,
        hasArtwork: true,
      ));
    } catch (_) {
      results.add(ArtworkBatchResultItem(
        mediaStoreId: item.mediaStoreId,
        albumId: item.albumId,
        hasArtwork: false,
      ));
    }
  }

  return results;
}

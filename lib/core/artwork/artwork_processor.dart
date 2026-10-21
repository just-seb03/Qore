/// File: artwork_processor.dart
/// Description: Top-level background Isolate worker for extracting, decoding, resizing,
/// and saving dual-tier album artworks (400x400 thumbnails and HD pristine master covers).
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

      // 4. Generate 400x400 high-DPI Thumbnail (cubic interpolation, quality 92%)
      final thumbnailImg = img.copyResize(
        decoded,
        width: 400,
        height: 400,
        interpolation: img.Interpolation.cubic,
      );
      final thumbBytes = img.encodeJpg(thumbnailImg, quality: 92);
      thumbJpg.writeAsBytesSync(thumbBytes, flush: true);

      // 5. Generate pristine High-Definition Cover
      // If the original image is already a high-res JPEG (<= 1600px and <= 4MB),
      // preserve the exact untouched master bytes for 100% publisher fidelity and 0 recompression loss.
      final bool isRawJpeg = rawPictureBytes.length > 3 &&
          rawPictureBytes[0] == 0xFF &&
          rawPictureBytes[1] == 0xD8 &&
          rawPictureBytes[2] == 0xFF;

      if (isRawJpeg &&
          decoded.width <= 1600 &&
          decoded.height <= 1600 &&
          rawPictureBytes.length <= 4 * 1024 * 1024) {
        coverFile.writeAsBytesSync(rawPictureBytes, flush: true);
      } else {
        final img.Image coverImg;
        if (decoded.width > 1440 || decoded.height > 1440) {
          final bool isWider = decoded.width >= decoded.height;
          coverImg = img.copyResize(
            decoded,
            width: isWider ? 1440 : (decoded.width * 1440 / decoded.height).round(),
            height: isWider ? (decoded.height * 1440 / decoded.width).round() : 1440,
            interpolation: img.Interpolation.cubic,
          );
        } else {
          coverImg = decoded;
        }
        final coverBytes = img.encodeJpg(coverImg, quality: 95);
        coverFile.writeAsBytesSync(coverBytes, flush: true);
      }

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

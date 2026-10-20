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
      final String thumbPath = p.join(item.thumbnailTargetDirectory, '${item.mediaStoreId}.png');
      final String coverPath = p.join(item.coverTargetDirectory, '${item.mediaStoreId}.jpg');

      final thumbFile = File(thumbPath);
      final coverFile = File(coverPath);

      // Fast check: if both already exist on disk, return immediately
      if (thumbFile.existsSync() && coverFile.existsSync()) {
        results.add(ArtworkBatchResultItem(
          mediaStoreId: item.mediaStoreId,
          albumId: item.albumId,
          thumbnailPath: thumbPath,
          coverPath: coverPath,
          hasArtwork: true,
        ));
        continue;
      }

      // Check album shared cache if albumId is available
      if (item.albumId != null) {
        final albumThumbPath = p.join(item.thumbnailTargetDirectory, 'album_${item.albumId}.png');
        final albumCoverPath = p.join(item.coverTargetDirectory, 'album_${item.albumId}.jpg');
        final albumThumbFile = File(albumThumbPath);
        final albumCoverFile = File(albumCoverPath);

        if (albumThumbFile.existsSync() && albumCoverFile.existsSync()) {
          // Re-use album files directly or copy
          try {
            if (!thumbFile.existsSync()) albumThumbFile.copySync(thumbPath);
            if (!coverFile.existsSync()) albumCoverFile.copySync(coverPath);

            results.add(ArtworkBatchResultItem(
              mediaStoreId: item.mediaStoreId,
              albumId: item.albumId,
              thumbnailPath: thumbPath,
              coverPath: coverPath,
              hasArtwork: true,
            ));
            continue;
          } catch (_) {
            // If copy fails, fall through to direct extraction
          }
        }
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

      // 4. Generate 100x100 Thumbnail (PNG)
      final thumbnailImg = img.copyResize(
        decoded,
        width: 100,
        height: 100,
        interpolation: img.Interpolation.linear,
      );
      final thumbBytes = img.encodePng(thumbnailImg);
      thumbFile.writeAsBytesSync(thumbBytes, flush: true);

      // 5. Generate 800x800 Cover (JPEG quality 85%)
      final coverImg = img.copyResize(
        decoded,
        width: 800,
        height: 800,
        interpolation: img.Interpolation.linear,
      );
      final coverBytes = img.encodeJpg(coverImg, quality: 85);
      coverFile.writeAsBytesSync(coverBytes, flush: true);

      // Also save album copies if albumId is available
      if (item.albumId != null) {
        try {
          final albumThumbFile = File(p.join(item.thumbnailTargetDirectory, 'album_${item.albumId}.png'));
          final albumCoverFile = File(p.join(item.coverTargetDirectory, 'album_${item.albumId}.jpg'));
          if (!albumThumbFile.existsSync()) thumbFile.copySync(albumThumbFile.path);
          if (!albumCoverFile.existsSync()) coverFile.copySync(albumCoverFile.path);
        } catch (_) {}
      }

      results.add(ArtworkBatchResultItem(
        mediaStoreId: item.mediaStoreId,
        albumId: item.albumId,
        thumbnailPath: thumbPath,
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

/// File: artwork_pipeline_test.dart
/// Description: Unit and Widget tests for the Dual-Tier Artwork Pipeline (Module 6).
/// Verifies Frame 0 O(1) in-memory lookups, on-disk directory scanning,
/// throttled batch queueing, 100x100 and 800x800 image generation, and AnimaArtworkImage widget rendering.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:project_anima/core/artwork/artwork_processor.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/artwork/models/artwork_batch_item.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/song.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String thumbnailsDir;
  late String coversDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('anima_artwork_test_');
    final root = p.join(tempDir.path, 'anima_artworks');
    thumbnailsDir = p.join(root, 'thumbnails');
    coversDir = p.join(root, 'covers');
    Directory(thumbnailsDir).createSync(recursive: true);
    Directory(coversDir).createSync(recursive: true);

    ArtworkService.instance.reset();
  });

  tearDown(() async {
    ArtworkService.instance.reset();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Dual-Tier Artwork Pipeline Tests', () {
    test('Pre-populates in-memory cache from disk in Frame 0 (O-1 lookup)', () async {
      // Simulate existing files on disk before app launch
      final existingThumb = File(p.join(thumbnailsDir, '1001.png'));
      existingThumb.writeAsBytesSync([1, 2, 3]);

      final existingCover = File(p.join(coversDir, '1001.jpg'));
      existingCover.writeAsBytesSync([4, 5, 6]);

      final albumThumb = File(p.join(thumbnailsDir, 'album_55.png'));
      albumThumb.writeAsBytesSync([7, 8, 9]);

      final albumCover = File(p.join(coversDir, 'album_55.jpg'));
      albumCover.writeAsBytesSync([10, 11, 12]);

      // Initialize service using test root
      await ArtworkService.instance.initialize(baseDir: tempDir);

      expect(ArtworkService.instance.isInitialized, isTrue);
      expect(ArtworkService.instance.cachedThumbnailsCount, 1);
      expect(ArtworkService.instance.cachedCoversCount, 1);

      // O(1) lookups
      expect(ArtworkService.instance.getThumbnailPath(1001), existingThumb.path);
      expect(ArtworkService.instance.getCoverPath(1001), existingCover.path);
      expect(ArtworkService.instance.hasArtwork(1001), isTrue);

      // Album fallback lookup
      expect(ArtworkService.instance.getThumbnailPath(9999, albumId: 55), albumThumb.path);
      expect(ArtworkService.instance.getCoverPath(9999, albumId: 55), albumCover.path);
      expect(ArtworkService.instance.hasArtwork(9999, albumId: 55), isTrue);

      // Non-existent
      expect(ArtworkService.instance.getThumbnailPath(8888), isNull);
      expect(ArtworkService.instance.hasArtwork(8888), isFalse);
    });

    test('processArtworkBatchInIsolate generates 100x100 thumbnail and 800x800 cover', () async {
      // Create a test image
      final testImg = img.Image(width: 400, height: 400);
      img.fill(testImg, color: img.ColorRgb8(255, 0, 0));
      final testImgBytes = img.encodeJpg(testImg);

      // Create dummy audio directory with folder.jpg heuristic
      final audioDir = Directory(p.join(tempDir.path, 'album_test_dir'))..createSync();
      final dummyAudio = File(p.join(audioDir.path, 'song.mp3'))..writeAsStringSync('dummy audio');
      File(p.join(audioDir.path, 'cover.jpg')).writeAsBytesSync(testImgBytes);

      final items = [
        ArtworkBatchItem(
          mediaStoreId: 500,
          albumId: 10,
          filePath: dummyAudio.path,
          thumbnailTargetDirectory: thumbnailsDir,
          coverTargetDirectory: coversDir,
        ),
      ];

      final results = processArtworkBatchInIsolate(items);
      expect(results.length, 1);
      expect(results.first.hasArtwork, isTrue);
      expect(results.first.thumbnailPath, isNotNull);
      expect(results.first.coverPath, isNotNull);

      // Verify thumbnail file dimensions
      final generatedThumb = File(results.first.thumbnailPath!);
      expect(generatedThumb.existsSync(), isTrue);
      final thumbDecoded = img.decodeImage(generatedThumb.readAsBytesSync());
      expect(thumbDecoded, isNotNull);
      expect(thumbDecoded!.width, 100);
      expect(thumbDecoded.height, 100);

      // Verify cover file dimensions
      final generatedCover = File(results.first.coverPath!);
      expect(generatedCover.existsSync(), isTrue);
      final coverDecoded = img.decodeImage(generatedCover.readAsBytesSync());
      expect(coverDecoded, isNotNull);
      expect(coverDecoded!.width, 800);
      expect(coverDecoded.height, 800);
    });

    test('Throttled queue extracts missing artworks and updates in-memory cache', () async {
      await ArtworkService.instance.initialize(baseDir: tempDir);

      // Create a sample cover image
      final testImg = img.Image(width: 250, height: 250);
      img.fill(testImg, color: img.ColorRgb8(0, 200, 100));
      final testImgBytes = img.encodeJpg(testImg);

      final trackDir = Directory(p.join(tempDir.path, 'artist_dir'))..createSync();
      final audioPath = p.join(trackDir.path, 'track_1.mp3');
      File(audioPath).writeAsStringSync('dummy audio data');
      File(p.join(trackDir.path, 'folder.jpg')).writeAsBytesSync(testImgBytes);

      final song = Song(
        mediaStoreId: 777,
        title: 'Queue Test',
        artist: 'Artist',
        album: 'Album',
        albumId: 44,
        duration: 180000,
        path: audioPath,
        dateModified: 1000,
      );

      expect(ArtworkService.instance.getThumbnailPath(777), isNull);

      ArtworkService.instance.enqueueSongs([song]);

      // Allow background isolate and queue processing loop to complete
      int waitMs = 0;
      while (ArtworkService.instance.isProcessing && waitMs < 3000) {
        await Future.delayed(const Duration(milliseconds: 50));
        waitMs += 50;
      }

      // In-memory cache should now hold the extracted paths in O(1)
      expect(ArtworkService.instance.getThumbnailPath(777), isNotNull);
      expect(ArtworkService.instance.getCoverPath(777), isNotNull);
      expect(ArtworkService.instance.hasArtwork(777), isTrue);
    });

    testWidgets('AnimaArtworkImage widget renders placeholder and respects cache dimensions', (tester) async {
      await ArtworkService.instance.initialize(baseDir: tempDir);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimaArtworkImage(
              mediaStoreId: 99999, // Uncached ID
              width: 50.0,
              height: 50.0,
              isThumbnail: true,
            ),
          ),
        ),
      );

      // Should render fallback without error
      expect(find.byType(AnimaArtworkImage), findsOneWidget);
      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    });
  });
}

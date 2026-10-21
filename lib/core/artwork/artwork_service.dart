/// File: artwork_service.dart
/// Description: Dual-tier Artwork Pipeline service managing on-disk and in-memory caches
/// for album covers (100x100 thumbnails and 800x800 covers). Implements Frame 0 O(1) in-memory
/// lookup and a throttled 2-item background queue with 100 ms pauses between batches.
///
/// Components / Classes / Functions:
/// - ArtworkService: Singleton ChangeNotifier coordinating caching and background extraction.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:project_anima/core/artwork/artwork_processor.dart';
import 'package:project_anima/core/artwork/models/artwork_batch_item.dart';
import 'package:project_anima/core/database/models/song.dart';

/// Singleton service implementing the Dual-Tier Artwork Pipeline (Module 6).
class ArtworkService extends ChangeNotifier {
  ArtworkService._();
  static final ArtworkService instance = ArtworkService._();

  static const int _batchSize = 2;
  static const Duration _batchPause = Duration(milliseconds: 100);

  bool _initialized = false;
  late String _thumbnailsDir;
  late String _coversDir;
  late String _artistsDir;

  // In-Memory O(1) Frame 0 caches
  final Map<int, String> _thumbnailCache = {};
  final Map<int, String> _coverCache = {};
  final Map<int, String> _albumThumbnailCache = {};
  final Map<int, String> _albumCoverCache = {};
  final Map<String, String> _customArtistAvatarCache = {};

  // Tracks IDs known to have no artwork to prevent redundant re-queuing
  final Set<int> _noArtworkCache = {};

  // Queuing structures
  final List<Song> _queue = [];
  final Set<int> _pendingQueueSet = {};
  bool _isProcessingQueue = false;

  /// Whether the service has completed disk directory discovery and in-memory cache population.
  bool get isInitialized => _initialized;

  /// True if the background throttled extraction loop is active.
  bool get isProcessing => _isProcessingQueue;

  /// Current number of songs remaining in the extraction queue.
  int get queueLength => _queue.length;

  /// Total cached thumbnails count in memory.
  int get cachedThumbnailsCount => _thumbnailCache.length;

  /// Total cached covers count in memory.
  int get cachedCoversCount => _coverCache.length;

  /// Initializes directory structure and pre-populates in-memory lookup maps for Frame 0 rendering.
  Future<void> initialize({Directory? baseDir}) async {
    if (_initialized) return;

    final String rootPath;
    if (baseDir != null) {
      rootPath = p.join(baseDir.path, 'anima_artworks');
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      rootPath = p.join(docDir.path, 'anima_artworks');
    }

    _thumbnailsDir = p.join(rootPath, 'thumbnails');
    _coversDir = p.join(rootPath, 'covers');
    _artistsDir = p.join(rootPath, 'artists');

    final thumbDirFile = Directory(_thumbnailsDir);
    final coverDirFile = Directory(_coversDir);
    final artistDirFile = Directory(_artistsDir);

    if (!thumbDirFile.existsSync()) thumbDirFile.createSync(recursive: true);
    if (!coverDirFile.existsSync()) coverDirFile.createSync(recursive: true);
    if (!artistDirFile.existsSync()) artistDirFile.createSync(recursive: true);

    // Frame 0: Quick directory listing to populate in-memory maps in O(1)
    _populateCacheFromDisk(thumbDirFile, _thumbnailCache, _albumThumbnailCache, '.png');
    _populateCacheFromDisk(coverDirFile, _coverCache, _albumCoverCache, '.jpg');
    _populateArtistCacheFromDisk(artistDirFile);

    _initialized = true;
    notifyListeners();
  }

  /// Scans file names in target directory and registers them in memory maps.
  void _populateCacheFromDisk(
    Directory dir,
    Map<int, String> songMap,
    Map<int, String> albumMap,
    String extension,
  ) {
    try {
      final entities = dir.listSync(followLinks: false);
      for (final entity in entities) {
        if (entity is! File) continue;
        final filename = p.basename(entity.path);
        if (!filename.endsWith(extension)) continue;

        final rawName = filename.substring(0, filename.length - extension.length);
        if (rawName.startsWith('album_')) {
          final albumId = int.tryParse(rawName.substring('album_'.length));
          if (albumId != null) albumMap[albumId] = entity.path;
        } else {
          final id = int.tryParse(rawName);
          if (id != null) songMap[id] = entity.path;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ArtworkService] Error reading existing artworks: $e');
    }
  }

  /// Returns the local path to the 100x100 thumbnail in O(1) time if available.
  String? getThumbnailPath(int mediaStoreId, {int? albumId}) {
    final direct = _thumbnailCache[mediaStoreId];
    if (direct != null) return direct;
    if (albumId != null) return _albumThumbnailCache[albumId];
    return null;
  }

  /// Returns the local path to the 800x800 cover in O(1) time if available.
  String? getCoverPath(int mediaStoreId, {int? albumId}) {
    final direct = _coverCache[mediaStoreId];
    if (direct != null) return direct;
    if (albumId != null) return _albumCoverCache[albumId];
    return null;
  }

  /// Normalizes an artist name into a safe, deterministic filename key.
  String _normalizeArtistKey(String artist) {
    return artist.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_\-]'), '_');
  }

  /// Scans the artists directory and populates the in-memory custom artist avatar cache.
  void _populateArtistCacheFromDisk(Directory dir) {
    try {
      final entities = dir.listSync(followLinks: false);
      for (final entity in entities) {
        if (entity is! File) continue;
        final filename = p.basename(entity.path);
        if (!filename.endsWith('.png') && !filename.endsWith('.jpg')) continue;
        final rawKey = p.withoutExtension(filename);
        _customArtistAvatarCache[rawKey] = entity.path;
      }
    } catch (e) {
      debugPrint('⚠️ [ArtworkService] Error reading artist avatars: $e');
    }
  }

  /// Returns the local path to a custom artist avatar in O(1) time if available.
  String? getCustomArtistAvatar(String? artist) {
    if (artist == null || artist.trim().isEmpty) return null;
    final key = _normalizeArtistKey(artist);
    final direct = _customArtistAvatarCache[key];
    if (direct != null && File(direct).existsSync()) {
      return direct;
    }
    return null;
  }

  /// Saves a custom artist avatar to persistent disk storage and updates in-memory cache.
  Future<String> setCustomArtistAvatar(String artist, Uint8List imageBytes) async {
    final key = _normalizeArtistKey(artist);
    final targetPath = p.join(_artistsDir, '$key.png');
    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(imageBytes, flush: true);
    _customArtistAvatarCache[key] = targetPath;
    notifyListeners();
    return targetPath;
  }

  /// Removes custom artist avatar from disk and memory cache.
  Future<void> removeCustomArtistAvatar(String artist) async {
    final key = _normalizeArtistKey(artist);
    final path = _customArtistAvatarCache.remove(key);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  /// Checks whether an artwork exists for this song or album.
  bool hasArtwork(int mediaStoreId, {int? albumId}) {
    return getThumbnailPath(mediaStoreId, albumId: albumId) != null;
  }

  /// Enqueues songs that lack cached artworks for background extraction.
  /// Throttled in batches of 2 with 100 ms pauses to protect UI frame rate.
  void enqueueSongs(List<Song> songs) {
    if (!_initialized) return;

    for (final song in songs) {
      final id = song.mediaStoreId;
      final albumId = song.albumId;

      // Skip if already in memory, marked as having no artwork, or already queued
      if (_thumbnailCache.containsKey(id)) continue;
      if (albumId != null && _albumThumbnailCache.containsKey(albumId)) {
        _thumbnailCache[id] = _albumThumbnailCache[albumId]!;
        if (_albumCoverCache.containsKey(albumId)) {
          _coverCache[id] = _albumCoverCache[albumId]!;
        }
        continue;
      }
      if (_noArtworkCache.contains(id) || _pendingQueueSet.contains(id)) continue;

      _queue.add(song);
      _pendingQueueSet.add(id);
    }

    if (!_isProcessingQueue && _queue.isNotEmpty) {
      _processQueue();
    }
  }

  /// Processes the artwork extraction queue in batches of 2 with 100 ms pauses.
  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    try {
      while (_queue.isNotEmpty) {
        final count = _queue.length < _batchSize ? _queue.length : _batchSize;
        final List<Song> batch = _queue.sublist(0, count);
        _queue.removeRange(0, count);

        final List<ArtworkBatchItem> batchItems = batch.map((song) {
          return ArtworkBatchItem(
            mediaStoreId: song.mediaStoreId,
            albumId: song.albumId,
            filePath: song.path,
            thumbnailTargetDirectory: _thumbnailsDir,
            coverTargetDirectory: _coversDir,
          );
        }).toList();

        // Run extraction and resizing in a background worker isolate
        final List<ArtworkBatchResultItem> results = await compute(
          processArtworkBatchInIsolate,
          batchItems,
        );

        // Update in-memory caches with produced files
        bool hasNewArtworks = false;
        for (final res in results) {
          _pendingQueueSet.remove(res.mediaStoreId);

          if (res.hasArtwork && res.thumbnailPath != null && res.coverPath != null) {
            _thumbnailCache[res.mediaStoreId] = res.thumbnailPath!;
            _coverCache[res.mediaStoreId] = res.coverPath!;
            if (res.albumId != null) {
              _albumThumbnailCache[res.albumId!] = res.thumbnailPath!;
              _albumCoverCache[res.albumId!] = res.coverPath!;
            }
            hasNewArtworks = true;
          } else {
            _noArtworkCache.add(res.mediaStoreId);
          }
        }

        if (hasNewArtworks) {
          notifyListeners();
        }

        // Strict architectural rule: 100 ms pause between batches to preserve 90/120 Hz UI
        if (_queue.isNotEmpty) {
          await Future.delayed(_batchPause);
        }
      }
    } catch (e, stack) {
      debugPrint('⚠️ [ArtworkService] Queue processing error: $e\n$stack');
    } finally {
      _isProcessingQueue = false;
      notifyListeners();
    }
  }

  /// Clears in-memory caches and queue (useful for test suites or database resets).
  @visibleForTesting
  void reset() {
    _thumbnailCache.clear();
    _coverCache.clear();
    _albumThumbnailCache.clear();
    _albumCoverCache.clear();
    _customArtistAvatarCache.clear();
    _noArtworkCache.clear();
    _queue.clear();
    _pendingQueueSet.clear();
    _isProcessingQueue = false;
    _initialized = false;
  }
}

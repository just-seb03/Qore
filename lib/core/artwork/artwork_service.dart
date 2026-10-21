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

  static const int _batchSize = 4;
  static const Duration _batchPause = Duration(milliseconds: 30);

  bool _initialized = false;
  late String _thumbnailsDir;
  late String _coversDir;
  late String _artistsDir;

  // In-Memory O(1) Frame 0 caches
  final Map<int, String> _thumbnailCache = {};
  final Map<int, String> _coverCache = {};
  final Map<String, String> _customArtistAvatarCache = {};
  final Map<String, int> _albumRepresentativeCache = {};
  final Map<String, List<Song>> _albumPendingSongs = {};

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
    _populateCacheFromDisk(thumbDirFile, _thumbnailCache);
    _populateCacheFromDisk(coverDirFile, _coverCache);
    _populateArtistCacheFromDisk(artistDirFile);

    _initialized = true;
    notifyListeners();
  }

  /// Scans file names in target directory and registers them in memory maps.
  /// Also proactively purges legacy collided 'album_*' files.
  void _populateCacheFromDisk(
    Directory dir,
    Map<int, String> songMap,
  ) {
    try {
      final entities = dir.listSync(followLinks: false);
      for (final entity in entities) {
        if (entity is! File) continue;
        final filename = p.basename(entity.path);
        final lower = filename.toLowerCase();
        if (!lower.endsWith('.png') && !lower.endsWith('.jpg') && !lower.endsWith('.jpeg')) continue;

        final rawName = p.withoutExtension(filename);
        if (rawName.startsWith('album_')) {
          // Legacy collided album cache file - delete so it never causes collisions
          try {
            entity.deleteSync();
          } catch (_) {}
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
  String? getThumbnailPath(int mediaStoreId, {int? albumId, String? album, String? artist}) {
    final direct = _thumbnailCache[mediaStoreId];
    if (direct != null) return direct;
    if (album != null && artist != null) {
      return getThumbnailForAlbum(album, artist);
    }
    return null;
  }

  /// Returns the local path to the 800x800 cover in O(1) time if available.
  String? getCoverPath(int mediaStoreId, {int? albumId, String? album, String? artist}) {
    final direct = _coverCache[mediaStoreId];
    if (direct != null) return direct;
    if (album != null && artist != null) {
      return getCoverForAlbum(album, artist);
    }
    return null;
  }

  /// Generates a normalized album key from album title and artist name.
  String albumKeyFromStrings(String album, String artist) {
    final cleanAlb = album.trim().toLowerCase();
    final cleanArt = _cleanArtistBase(artist).trim().toLowerCase();
    return '$cleanAlb::$cleanArt';
  }

  /// Returns the local path to the thumbnail for an album in O(1) time if available.
  String? getThumbnailForAlbum(String album, String artist) {
    final key = albumKeyFromStrings(album, artist);
    final repId = _albumRepresentativeCache[key];
    if (repId != null) {
      return _thumbnailCache[repId];
    }
    return null;
  }

  /// Returns the local path to the cover for an album in O(1) time if available.
  String? getCoverForAlbum(String album, String artist) {
    final key = albumKeyFromStrings(album, artist);
    final repId = _albumRepresentativeCache[key];
    if (repId != null) {
      return _coverCache[repId];
    }
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

  /// Extracts base artist name by removing collaboration markers.
  /// Extracts base artist name by removing collaboration markers.
  String _cleanArtistBase(String? artist) {
    if (artist == null || artist.trim().isEmpty) return '<Desconocido>';
    return artist
        .split(RegExp(r'\s+(?:feat\.?|ft\.?|featuring|with|&|,|/)\s+', caseSensitive: false))
        .first
        .trim();
  }

  /// Generates a normalized album key combining album title and album artist.
  String _albumKey(Song song) {
    final album = (song.album ?? '<Desconocido>').trim().toLowerCase();
    final rawArtist = (song.albumArtist != null &&
            song.albumArtist!.trim().isNotEmpty &&
            song.albumArtist != '<Desconocido>')
        ? song.albumArtist!
        : _cleanArtistBase(song.artist);
    return '$album::${rawArtist.trim().toLowerCase()}';
  }

  /// Prioritizes songs in the queue (e.g. visible album covers) to be extracted first.
  void prioritizeSongIds(List<int> ids) {
    if (_queue.isEmpty || ids.isEmpty) return;
    final Set<int> targetIds = ids.toSet();
    final List<Song> priority = [];
    final List<Song> rest = [];
    for (final song in _queue) {
      if (targetIds.contains(song.mediaStoreId)) {
        priority.add(song);
      } else {
        rest.add(song);
      }
    }
    if (priority.isNotEmpty) {
      _queue.clear();
      _queue.addAll(priority);
      _queue.addAll(rest);
      if (!_isProcessingQueue) {
        _processQueue();
      }
    }
  }

  /// Checks whether an artwork exists for this song.
  bool hasArtwork(int mediaStoreId, {int? albumId}) {
    return _thumbnailCache.containsKey(mediaStoreId);
  }

  /// Evicts specific song thumbnails and covers from in-memory cache and on-disk files.
  void evictSongs(List<int> mediaStoreIds) {
    if (!_initialized) return;
    for (final id in mediaStoreIds) {
      _thumbnailCache.remove(id);
      _coverCache.remove(id);
      _noArtworkCache.remove(id);
      final thumbFile = File(p.join(_thumbnailsDir, '$id.png'));
      final coverFile = File(p.join(_coversDir, '$id.jpg'));
      try {
        if (thumbFile.existsSync()) thumbFile.deleteSync();
        if (coverFile.existsSync()) coverFile.deleteSync();
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Enqueues songs that lack cached artworks for background extraction.
  /// Deduplicates at the album level: only ONE representative song per album is enqueued.
  /// Remaining tracks of the album instantly inherit the artwork once extracted, reducing isolate workload by > 85%.
  void enqueueSongs(List<Song> songs) {
    if (!_initialized || songs.isEmpty) return;

    // Group songs by album key
    final Map<String, List<Song>> byAlbum = {};
    for (final song in songs) {
      final key = _albumKey(song);
      (byAlbum[key] ??= []).add(song);
    }

    for (final entry in byAlbum.entries) {
      final key = entry.key;
      final albumSongs = entry.value;

      // 1. Check if any song in this album already has artwork in cache
      int? cachedRepId;
      for (final song in albumSongs) {
        if (_thumbnailCache.containsKey(song.mediaStoreId)) {
          cachedRepId = song.mediaStoreId;
          break;
        }
      }

      if (cachedRepId != null) {
        _albumRepresentativeCache[key] = cachedRepId;
        final thumb = _thumbnailCache[cachedRepId]!;
        final cover = _coverCache[cachedRepId];
        for (final song in albumSongs) {
          _thumbnailCache[song.mediaStoreId] = thumb;
          if (cover != null) _coverCache[song.mediaStoreId] = cover;
        }
        continue;
      }

      // 2. Check if _albumRepresentativeCache already has this album with artwork
      if (_albumRepresentativeCache.containsKey(key)) {
        final repId = _albumRepresentativeCache[key]!;
        if (_thumbnailCache.containsKey(repId)) {
          final thumb = _thumbnailCache[repId]!;
          final cover = _coverCache[repId];
          for (final song in albumSongs) {
            _thumbnailCache[song.mediaStoreId] = thumb;
            if (cover != null) _coverCache[song.mediaStoreId] = cover;
          }
          continue;
        }
      }

      // 3. Album has no artwork extracted yet.
      // Filter out songs already marked as having no artwork or already queued
      final candidates = albumSongs
          .where((s) => !_noArtworkCache.contains(s.mediaStoreId) && !_pendingQueueSet.contains(s.mediaStoreId))
          .toList();
      if (candidates.isEmpty) continue;

      // Register candidates as pending for this album
      final pendingList = _albumPendingSongs[key] ??= [];
      for (final c in candidates) {
        if (!pendingList.any((s) => s.mediaStoreId == c.mediaStoreId)) {
          pendingList.add(c);
        }
      }

      // Enqueue ONLY the first candidate for this album
      final candidateToQueue = candidates.first;
      _albumRepresentativeCache[key] = candidateToQueue.mediaStoreId;
      _queue.add(candidateToQueue);
      _pendingQueueSet.add(candidateToQueue.mediaStoreId);
    }

    if (!_isProcessingQueue && _queue.isNotEmpty) {
      _processQueue();
    }
  }

  /// Processes the artwork extraction queue in batches of 4 with 25 ms pauses.
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
            hasNewArtworks = true;
          } else {
            _noArtworkCache.add(res.mediaStoreId);
          }
        }

        // Propagate newly resolved artworks to all pending songs of the same album
        if (hasNewArtworks) {
          for (final song in batch) {
            if (_thumbnailCache.containsKey(song.mediaStoreId)) {
              final key = _albumKey(song);
              _albumRepresentativeCache[key] = song.mediaStoreId;
              final thumb = _thumbnailCache[song.mediaStoreId]!;
              final cover = _coverCache[song.mediaStoreId]!;

              final pending = _albumPendingSongs.remove(key);
              if (pending != null) {
                for (final p in pending) {
                  _thumbnailCache[p.mediaStoreId] = thumb;
                  _coverCache[p.mediaStoreId] = cover;
                  _pendingQueueSet.remove(p.mediaStoreId);
                }
              }
            }
          }

          final List<Song> remaining = [];
          for (final song in _queue) {
            final key = _albumKey(song);
            if (_albumRepresentativeCache.containsKey(key)) {
              final repId = _albumRepresentativeCache[key]!;
              if (_thumbnailCache.containsKey(repId)) {
                _thumbnailCache[song.mediaStoreId] = _thumbnailCache[repId]!;
                if (_coverCache.containsKey(repId)) {
                  _coverCache[song.mediaStoreId] = _coverCache[repId]!;
                }
                _pendingQueueSet.remove(song.mediaStoreId);
                continue;
              }
            }
            remaining.add(song);
          }
          _queue.clear();
          _queue.addAll(remaining);
          notifyListeners();
        }

        // Handle candidates that had no artwork: try next candidate from album if any
        for (final song in batch) {
          if (!_thumbnailCache.containsKey(song.mediaStoreId)) {
            final key = _albumKey(song);
            final pending = _albumPendingSongs[key];
            if (pending != null && pending.isNotEmpty) {
              pending.removeWhere((s) => s.mediaStoreId == song.mediaStoreId);
              if (pending.isNotEmpty) {
                final nextCandidate = pending.first;
                if (!_noArtworkCache.contains(nextCandidate.mediaStoreId) &&
                    !_pendingQueueSet.contains(nextCandidate.mediaStoreId)) {
                  _queue.add(nextCandidate);
                  _pendingQueueSet.add(nextCandidate.mediaStoreId);
                  _albumRepresentativeCache[key] = nextCandidate.mediaStoreId;
                }
              } else {
                _albumPendingSongs.remove(key);
              }
            }
          }
        }

        // 25 ms pause between batches to preserve 90/120 Hz UI
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
    _albumRepresentativeCache.clear();
    _albumPendingSongs.clear();
    _customArtistAvatarCache.clear();
    _noArtworkCache.clear();
    _queue.clear();
    _pendingQueueSet.clear();
    _isProcessingQueue = false;
    _initialized = false;
  }
}

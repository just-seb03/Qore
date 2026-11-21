/// File: artwork_service.dart
/// Description: Dual-tier Artwork Pipeline service managing on-disk and in-memory caches
/// for album covers (100x100 thumbnails and 800x800 covers). Implements Frame 0 O(1) in-memory
/// lookup and a throttled 2-item background queue with 100 ms pauses between batches.
///
/// Components / Classes / Functions:
/// - ArtworkService: Singleton ChangeNotifier coordinating caching and background extraction.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:project_anima/core/artwork/artwork_processor.dart';
import 'package:project_anima/core/artwork/models/artwork_batch_item.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';

/// Lightweight queue item holding only the minimal fields needed for isolate extraction.
class _ArtworkQueueItem {
  final int mediaStoreId;
  final int? albumId;
  final String path;
  final String albumKey;

  const _ArtworkQueueItem({
    required this.mediaStoreId,
    this.albumId,
    required this.path,
    required this.albumKey,
  });
}

/// Singleton service implementing the Dual-Tier Artwork Pipeline (Module 6).
class ArtworkService extends ChangeNotifier {
  ArtworkService._();
  static final ArtworkService instance = ArtworkService._();

  static const int _batchSize = 4;
  static const Duration _batchPause = Duration(milliseconds: 30);
  static const int _kArtworkCacheVersion = 2;

  bool _initialized = false;
  late String _thumbnailsDir;
  late String _coversDir;
  late String _artistsDir;

  // In-Memory O(1) Frame 0 caches
  final Map<int, String> _thumbnailCache = {};
  final Map<int, String> _coverCache = {};
  final Map<String, String> _customArtistAvatarCache = {};
  final Map<String, String> _customArtistRoundCache = {};
  final Map<String, int> _customArtistVersionCache = {};
  final Map<String, String> _customArtistSquareCache = {};
  final Map<String, int> _albumRepresentativeCache = {};
  final Map<String, List<_ArtworkQueueItem>> _albumPendingSongs = {};
  final Map<int, String> _songAlbumKeyCache = {};

  // Tracks IDs known to have no artwork to prevent redundant re-queuing
  final Set<int> _noArtworkCache = {};

  // Queuing structures
  final List<_ArtworkQueueItem> _queue = [];
  final Set<int> _pendingQueueSet = {};
  bool _isProcessingQueue = false;
  int _totalQueueItemsToProcess = 0;
  int _processedQueueItems = 0;

  /// Whether the service has completed disk directory discovery and in-memory cache population.
  bool get isInitialized => _initialized;

  /// True if the background throttled extraction loop is active.
  bool get isProcessing => _isProcessingQueue;

  /// Current number of songs remaining in the extraction queue.
  int get queueLength => _queue.length;

  /// Total queue items scheduled in current batch.
  int get totalQueueItemsToProcess => _totalQueueItemsToProcess;

  /// Items processed so far in current batch.
  int get processedQueueItems => _processedQueueItems;

  /// Total cached thumbnails count in memory.
  int get cachedThumbnailsCount => _thumbnailCache.length;

  /// Total cached covers count in memory.
  int get cachedCoversCount => _coverCache.length;

  /// Initializes directory structure and pre-populates in-memory lookup maps for Frame 0 rendering.
  Future<void> initialize({Directory? baseDir, SongDao? songDao}) async {
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
    final versionFile = File(p.join(rootPath, '.artwork_cache_version'));

    int currentVersion = 0;
    if (versionFile.existsSync()) {
      try {
        currentVersion = int.tryParse(versionFile.readAsStringSync().trim()) ?? 0;
      } catch (_) {}
    }

    final bool isExistingCache = thumbDirFile.existsSync() || coverDirFile.existsSync();
    if (isExistingCache && currentVersion < _kArtworkCacheVersion) {
      // Automatic migration to HD Artwork engine: Purge old low-res degraded cache once
      if (thumbDirFile.existsSync()) {
        try {
          thumbDirFile.deleteSync(recursive: true);
        } catch (_) {}
      }
      if (coverDirFile.existsSync()) {
        try {
          coverDirFile.deleteSync(recursive: true);
        } catch (_) {}
      }
      thumbDirFile.createSync(recursive: true);
      coverDirFile.createSync(recursive: true);
      try {
        versionFile.writeAsStringSync('$_kArtworkCacheVersion', flush: true);
      } catch (_) {}
    } else {
      if (!thumbDirFile.existsSync()) thumbDirFile.createSync(recursive: true);
      if (!coverDirFile.existsSync()) coverDirFile.createSync(recursive: true);
      if (!versionFile.existsSync()) {
        try {
          versionFile.writeAsStringSync('$_kArtworkCacheVersion', flush: true);
        } catch (_) {}
      }
    }
    if (!artistDirFile.existsSync()) artistDirFile.createSync(recursive: true);

    // Frame 0: Quick directory listing to populate in-memory maps in O(1)
    _populateCacheFromDisk(thumbDirFile, _thumbnailCache);
    _populateCacheFromDisk(coverDirFile, _coverCache);
    _populateArtistCacheFromDisk(artistDirFile);

    _initialized = true;
    notifyListeners();

    // Asynchronously preload album mappings from SQLite in < 5 ms
    await preloadAlbumMappings(songDao: songDao);
  }

  /// Preloads album mappings from SQLite database in < 5 ms on app launch.
  /// Instantly connects all songs and albums to cached disk artworks before UI builds.
  Future<void> preloadAlbumMappings({SongDao? songDao}) async {
    try {
      final dao = songDao ?? SongDao();
      final metadataList = await dao.getSongArtworkMetadata();
      if (metadataList.isEmpty) return;

      // In-memory string interning table: avoids allocating thousands of duplicate albumKey strings
      final Map<String, String> internedKeys = {};

      // 1. Populate song -> albumKey index
      for (final meta in metadataList) {
        final rawKey = _albumKeyFromMeta(meta.album, meta.artist, meta.albumArtist);
        final key = internedKeys.putIfAbsent(rawKey, () => rawKey);
        _songAlbumKeyCache[meta.mediaStoreId] = key;
      }

      // 2. Discover representative song for each album that has cached artwork
      for (final meta in metadataList) {
        final key = _songAlbumKeyCache[meta.mediaStoreId]!;
        if (_thumbnailCache.containsKey(meta.mediaStoreId) ||
            _coverCache.containsKey(meta.mediaStoreId)) {
          _albumRepresentativeCache[key] ??= meta.mediaStoreId;
        }
      }

      // 3. NOTICE: We NO LONGER duplicate _thumbnailCache and _coverCache for every song.
      // In-memory lookups (getThumbnailPath, getCoverPath) resolve in O(1) via
      // _songAlbumKeyCache[mediaStoreId] -> _albumRepresentativeCache[key] -> _thumbnailCache[repId].
      // This saves tens of thousands of duplicate string and map entries in RAM.

      // 4. Automatically enqueue any songs or albums that do not have cached artworks yet.
      // Deduplicate at the album level: enqueue only ONE representative song per missing album.
      final List<SongArtworkMeta> missingArtworkMeta = [];
      final Set<String> enqueuedAlbumKeys = {};

      for (final meta in metadataList) {
        final key = _songAlbumKeyCache[meta.mediaStoreId]!;
        final repId = _albumRepresentativeCache[key];
        final hasArtwork = repId != null &&
            _coverCache.containsKey(repId) &&
            _thumbnailCache.containsKey(repId);

        if (!hasArtwork && enqueuedAlbumKeys.add(key)) {
          missingArtworkMeta.add(meta);
        }
      }

      if (missingArtworkMeta.isNotEmpty) {
        enqueueSongArtworkMeta(missingArtworkMeta);
      }
    } catch (e) {
      debugPrint('⚠️ [ArtworkService] preloadAlbumMappings error: $e');
    }
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

    final key = (album != null && artist != null)
        ? albumKeyFromStrings(album, artist)
        : _songAlbumKeyCache[mediaStoreId];
    if (key != null) {
      final repId = _albumRepresentativeCache[key];
      if (repId != null) {
        return _thumbnailCache[repId];
      }
    }
    return null;
  }

  /// Returns the local path to the 800x800 cover in O(1) time if available.
  String? getCoverPath(int mediaStoreId, {int? albumId, String? album, String? artist}) {
    final direct = _coverCache[mediaStoreId];
    if (direct != null) return direct;

    final key = (album != null && artist != null)
        ? albumKeyFromStrings(album, artist)
        : _songAlbumKeyCache[mediaStoreId];
    if (key != null) {
      final repId = _albumRepresentativeCache[key];
      if (repId != null) {
        return _coverCache[repId];
      }
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

  /// Scans the artists directory and populates the in-memory custom artist avatar cache
  /// differentiating square photos (for Space) and round photos (for avatars).
  void _populateArtistCacheFromDisk(Directory dir) {
    try {
      final entities = dir.listSync(followLinks: false);
      for (final entity in entities) {
        if (entity is! File) continue;
        final filename = p.basename(entity.path);
        if (!filename.endsWith('.png') && !filename.endsWith('.jpg')) continue;
        final rawKey = p.withoutExtension(filename);
        if (rawKey.endsWith('_round')) {
          final baseKey = rawKey.substring(0, rawKey.length - 6);
          _customArtistRoundCache[baseKey] = entity.path;
        } else if (rawKey.endsWith('_square')) {
          final baseKey = rawKey.substring(0, rawKey.length - 7);
          _customArtistSquareCache[baseKey] = entity.path;
        } else {
          _customArtistAvatarCache[rawKey] = entity.path;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ArtworkService] Error reading artist avatars: $e');
    }
  }

  /// Returns the local path to a custom artist avatar in O(1) time if available.
  /// Prefers the circular rasterized version if present, falling back to legacy or square.
  String? getCustomArtistAvatar(String? artist) {
    if (artist == null || artist.trim().isEmpty) return null;
    final key = _normalizeArtistKey(artist);
    final round = _customArtistRoundCache[key];
    if (round != null && File(round).existsSync()) {
      return round;
    }
    final direct = _customArtistAvatarCache[key];
    if (direct != null && File(direct).existsSync()) {
      return direct;
    }
    final square = _customArtistSquareCache[key];
    if (square != null && File(square).existsSync()) {
      return square;
    }
    return null;
  }

  /// Returns the local path to a custom artist square photo (for Space) in O(1) time if available.
  /// Prefers the 1:1 square version if present, falling back to legacy or round.
  String? getCustomArtistSquarePhoto(String? artist) {
    if (artist == null || artist.trim().isEmpty) return null;
    final key = _normalizeArtistKey(artist);
    final square = _customArtistSquareCache[key];
    if (square != null && File(square).existsSync()) {
      return square;
    }
    final direct = _customArtistAvatarCache[key];
    if (direct != null && File(direct).existsSync()) {
      return direct;
    }
    final round = _customArtistRoundCache[key];
    if (round != null && File(round).existsSync()) {
      return round;
    }
    return null;
  }

  /// Returns the in-memory revision counter for an artist's custom photo so
  /// widgets can invalidate `Image` keys immediately upon photo changes.
  int getArtistAvatarVersion(String? artist) {
    if (artist == null || artist.trim().isEmpty) return 0;
    return _customArtistVersionCache[_normalizeArtistKey(artist)] ?? 0;
  }

  void _evictArtistImageCaches(List<String> paths) {
    final imageCache = PaintingBinding.instance.imageCache;
    for (final path in paths) {
      FileImage(File(path)).evict();
    }
    // ResizeImage wraps FileImage with size-specific cache keys and live streams
    // remain pinned while ArtistHeaderView is mounted underneath the crop route.
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  /// Saves custom artist avatar to persistent disk storage in both 1:1 square format (for Space)
  /// and circular rasterized format (for avatars), and updates in-memory caches.
  Future<String> setCustomArtistAvatar(String artist, Uint8List imageBytes) async {
    final key = _normalizeArtistKey(artist);

    // 1. Save 1:1 square photo for Space and general usage
    final squarePath = p.join(_artistsDir, '${key}_square.png');
    final standardPath = p.join(_artistsDir, '$key.png');
    await File(squarePath).writeAsBytes(imageBytes, flush: true);
    await File(standardPath).writeAsBytes(imageBytes, flush: true);
    _customArtistSquareCache[key] = squarePath;
    _customArtistAvatarCache[key] = standardPath;

    // 2. Generate circular rasterized version for round avatar usage
    final roundBytes = await _createCircularImage(imageBytes);
    final roundPath = p.join(_artistsDir, '${key}_round.png');
    await File(roundPath).writeAsBytes(roundBytes, flush: true);
    _customArtistRoundCache[key] = roundPath;

    _customArtistVersionCache[key] = (_customArtistVersionCache[key] ?? 0) + 1;
    _evictArtistImageCaches([squarePath, standardPath, roundPath]);

    notifyListeners();
    return roundPath;
  }

  /// Removes custom artist avatar from disk and memory cache (both square and round versions).
  Future<void> removeCustomArtistAvatar(String artist) async {
    final key = _normalizeArtistKey(artist);
    _customArtistSquareCache.remove(key);
    _customArtistRoundCache.remove(key);
    _customArtistAvatarCache.remove(key);

    final paths = [
      p.join(_artistsDir, '${key}_square.png'),
      p.join(_artistsDir, '${key}_round.png'),
      p.join(_artistsDir, '$key.png'),
    ];
    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    _customArtistVersionCache[key] = (_customArtistVersionCache[key] ?? 0) + 1;
    _evictArtistImageCaches(paths);
    notifyListeners();
  }

  /// Helper generating a circular rasterized PNG from square image bytes.
  Future<Uint8List> _createCircularImage(Uint8List squareBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(squareBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final int size = math.min(image.width, image.height);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      );

      final clipPath = Path()
        ..addOval(Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
      canvas.clipPath(clipPath);

      final src = Rect.fromLTWH(
        (image.width - size) / 2.0,
        (image.height - size) / 2.0,
        size.toDouble(),
        size.toDouble(),
      );
      final dst = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
      canvas.drawImageRect(image, src, dst, Paint()..isAntiAlias = true);

      final picture = recorder.endRecording();
      final circularImage = await picture.toImage(size, size);
      final byteData = await circularImage.toByteData(format: ui.ImageByteFormat.png);

      // Explicitly dispose native Skia/GPU handles immediately to prevent memory leaks
      image.dispose();
      picture.dispose();
      circularImage.dispose();
      codec.dispose();

      return byteData?.buffer.asUint8List() ?? squareBytes;
    } catch (e) {
      debugPrint('⚠️ [ArtworkService] Fallback to square bytes for circular avatar: $e');
      return squareBytes;
    }
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

  /// Generates a normalized album key combining album title and album artist from metadata strings.
  String _albumKeyFromMeta(String? album, String? artist, String? albumArtist) {
    final alb = (album ?? '<Desconocido>').trim().toLowerCase();
    final rawArtist = (albumArtist != null &&
            albumArtist.trim().isNotEmpty &&
            albumArtist != '<Desconocido>')
        ? albumArtist
        : _cleanArtistBase(artist);
    return '$alb::${rawArtist.trim().toLowerCase()}';
  }

  /// Generates a normalized album key combining album title and album artist.
  String _albumKey(Song song) {
    return _albumKeyFromMeta(song.album, song.artist, song.albumArtist);
  }

  /// Prioritizes songs in the queue (e.g. visible album covers) to be extracted first.
  void prioritizeSongIds(List<int> ids) {
    if (_queue.isEmpty || ids.isEmpty) return;
    final Set<int> targetIds = ids.toSet();
    final List<_ArtworkQueueItem> priority = [];
    final List<_ArtworkQueueItem> rest = [];
    for (final item in _queue) {
      if (targetIds.contains(item.mediaStoreId)) {
        priority.add(item);
      } else {
        rest.add(item);
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
    if (_thumbnailCache.containsKey(mediaStoreId)) return true;
    final key = _songAlbumKeyCache[mediaStoreId];
    if (key != null) {
      final repId = _albumRepresentativeCache[key];
      if (repId != null && _thumbnailCache.containsKey(repId)) {
        return true;
      }
    }
    return false;
  }

  /// Evicts specific song thumbnails and covers from in-memory cache and on-disk files.
  void evictSongs(List<int> mediaStoreIds) {
    if (!_initialized) return;
    for (final id in mediaStoreIds) {
      _thumbnailCache.remove(id);
      _coverCache.remove(id);
      _noArtworkCache.remove(id);
      final key = _songAlbumKeyCache.remove(id);
      if (key != null && _albumRepresentativeCache[key] == id) {
        _albumRepresentativeCache.remove(key);
      }
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
      _songAlbumKeyCache[song.mediaStoreId] = key;
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
        continue;
      }

      // 2. Check if _albumRepresentativeCache already has this album with artwork
      if (_albumRepresentativeCache.containsKey(key)) {
        final repId = _albumRepresentativeCache[key]!;
        if (_thumbnailCache.containsKey(repId)) {
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
          pendingList.add(_ArtworkQueueItem(
            mediaStoreId: c.mediaStoreId,
            albumId: c.albumId,
            path: c.path,
            albumKey: key,
          ));
        }
      }

      // Enqueue ONLY the first candidate for this album
      final candidateToQueue = pendingList.first;
      _albumRepresentativeCache[key] = candidateToQueue.mediaStoreId;
      _queue.add(candidateToQueue);
      _pendingQueueSet.add(candidateToQueue.mediaStoreId);
      _totalQueueItemsToProcess++;
    }

    if (!_isProcessingQueue && _queue.isNotEmpty) {
      _processQueue();
    }
  }

  /// Enqueues lightweight artwork metadata for background extraction without instantiating Song domain models.
  void enqueueSongArtworkMeta(List<SongArtworkMeta> metadataList) {
    if (!_initialized || metadataList.isEmpty) return;

    final Map<String, List<SongArtworkMeta>> byAlbum = {};
    for (final meta in metadataList) {
      final key = _songAlbumKeyCache[meta.mediaStoreId] ??
          _albumKeyFromMeta(meta.album, meta.artist, meta.albumArtist);
      _songAlbumKeyCache[meta.mediaStoreId] = key;
      (byAlbum[key] ??= []).add(meta);
    }

    for (final entry in byAlbum.entries) {
      final key = entry.key;
      final albumSongs = entry.value;

      int? cachedRepId;
      for (final meta in albumSongs) {
        if (_thumbnailCache.containsKey(meta.mediaStoreId)) {
          cachedRepId = meta.mediaStoreId;
          break;
        }
      }

      if (cachedRepId != null) {
        _albumRepresentativeCache[key] = cachedRepId;
        continue;
      }

      if (_albumRepresentativeCache.containsKey(key)) {
        final repId = _albumRepresentativeCache[key]!;
        if (_thumbnailCache.containsKey(repId)) {
          continue;
        }
      }

      final candidates = albumSongs
          .where((s) =>
              !_noArtworkCache.contains(s.mediaStoreId) &&
              !_pendingQueueSet.contains(s.mediaStoreId))
          .toList();
      if (candidates.isEmpty) continue;

      final pendingList = _albumPendingSongs[key] ??= [];
      for (final c in candidates) {
        if (!pendingList.any((s) => s.mediaStoreId == c.mediaStoreId)) {
          pendingList.add(_ArtworkQueueItem(
            mediaStoreId: c.mediaStoreId,
            albumId: c.albumId,
            path: c.path,
            albumKey: key,
          ));
        }
      }

      final candidateToQueue = pendingList.first;
      _albumRepresentativeCache[key] = candidateToQueue.mediaStoreId;
      _queue.add(candidateToQueue);
      _pendingQueueSet.add(candidateToQueue.mediaStoreId);
      _totalQueueItemsToProcess++;
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
        final List<_ArtworkQueueItem> batch = _queue.sublist(0, count);
        _queue.removeRange(0, count);

        final List<ArtworkBatchItem> batchItems = batch.map((item) {
          return ArtworkBatchItem(
            mediaStoreId: item.mediaStoreId,
            albumId: item.albumId,
            filePath: item.path,
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
          for (final item in batch) {
            if (_thumbnailCache.containsKey(item.mediaStoreId)) {
              final key = item.albumKey;
              _albumRepresentativeCache[key] = item.mediaStoreId;

              final pending = _albumPendingSongs.remove(key);
              if (pending != null) {
                for (final p in pending) {
                  _pendingQueueSet.remove(p.mediaStoreId);
                }
              }
            }
          }

          final List<_ArtworkQueueItem> remaining = [];
          for (final item in _queue) {
            final key = item.albumKey;
            if (_albumRepresentativeCache.containsKey(key)) {
              final repId = _albumRepresentativeCache[key]!;
              if (_thumbnailCache.containsKey(repId)) {
                _pendingQueueSet.remove(item.mediaStoreId);
                continue;
              }
            }
            remaining.add(item);
          }
          _queue.clear();
          _queue.addAll(remaining);
          notifyListeners();
        }

        // Handle candidates that had no artwork: try next candidate from album if any
        for (final item in batch) {
          if (!_thumbnailCache.containsKey(item.mediaStoreId)) {
            final key = item.albumKey;
            final pending = _albumPendingSongs[key];
            if (pending != null && pending.isNotEmpty) {
              pending.removeWhere((s) => s.mediaStoreId == item.mediaStoreId);
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

        _processedQueueItems += count;

        // 25 ms pause between batches to preserve 90/120 Hz UI
        if (_queue.isNotEmpty) {
          await Future.delayed(_batchPause);
        }
      }
    } catch (e, stack) {
      debugPrint('⚠️ [ArtworkService] Queue processing error: $e\n$stack');
    } finally {
      _isProcessingQueue = false;
      if (_queue.isEmpty) {
        _totalQueueItemsToProcess = 0;
        _processedQueueItems = 0;
      }
      notifyListeners();
    }
  }

  /// Waits until the active artwork queue has finished processing or [timeout] expires.
  /// Reports [onProgress] with (processed, total) counts as batches finish.
  Future<void> waitForQueueCompletion({
    Duration timeout = const Duration(seconds: 4),
    void Function(int processed, int total)? onProgress,
  }) async {
    if (!_isProcessingQueue && _queue.isEmpty) {
      onProgress?.call(1, 1);
      return;
    }

    final stopwatch = Stopwatch()..start();
    while ((_isProcessingQueue || _queue.isNotEmpty) && stopwatch.elapsed < timeout) {
      final total = _totalQueueItemsToProcess > 0
          ? _totalQueueItemsToProcess
          : (_processedQueueItems + _queue.length);
      onProgress?.call(_processedQueueItems, total > 0 ? total : 1);
      await Future.delayed(const Duration(milliseconds: 50));
    }

    final finalTotal = _totalQueueItemsToProcess > 0 ? _totalQueueItemsToProcess : 1;
    onProgress?.call(finalTotal, finalTotal);
  }

  /// Clears in-memory caches and queue (useful for test suites or database resets).
  @visibleForTesting
  void reset() {
    _thumbnailCache.clear();
    _coverCache.clear();
    _albumRepresentativeCache.clear();
    _albumPendingSongs.clear();
    _songAlbumKeyCache.clear();
    _customArtistAvatarCache.clear();
    _noArtworkCache.clear();
    _queue.clear();
    _pendingQueueSet.clear();
    _isProcessingQueue = false;
    _totalQueueItemsToProcess = 0;
    _processedQueueItems = 0;
    _initialized = false;
  }
}

/// File: music_indexer.dart
/// Description: Core 4-phase high-performance Music Indexing and Delta Synchronization Engine.
/// Implements lightweight projection, in-memory algebraic set diffing, isolated deep scan
/// via Dart worker isolates, and atomic ACID SQLite transactions.
///
/// Components / Classes / Functions:
/// - parseMetadataInIsolate: Top-level worker function executing physical tag parsing in an isolate.
/// - MusicIndexer: Singleton coordinator executing the 4-phase delta synchronization workflow.
library;

import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/scanner/models/indexing_result.dart';
import 'package:project_anima/core/scanner/models/lightweight_audio_item.dart';

/// Top-level worker function executing isolated physical metadata extraction (Phase 3).
/// Runs in a background isolate via [compute] to protect the UI thread.
List<Song> parseMetadataInIsolate(List<LightweightAudioItem> items) {
  final List<Song> results = [];

  for (final item in items) {
    String title = item.fallbackTitle;
    String artist = item.fallbackArtist ?? '<Desconocido>';
    String album = item.fallbackAlbum ?? '<Desconocido>';
    String? albumArtist = item.fallbackAlbumArtist;
    int duration = item.duration;

    try {
      final file = File(item.path);
      if (file.existsSync()) {
        final metadata = readMetadata(file, getImage: false);
        if (metadata.title != null && metadata.title!.trim().isNotEmpty) {
          title = metadata.title!.trim();
        }
        if (metadata.artist != null && metadata.artist!.trim().isNotEmpty) {
          artist = metadata.artist!.trim();
        }
        if (metadata.album != null && metadata.album!.trim().isNotEmpty) {
          album = metadata.album!.trim();
        }
        if (metadata.albumArtist != null && metadata.albumArtist!.trim().isNotEmpty) {
          albumArtist = metadata.albumArtist!.trim();
        }
        if (metadata.duration != null && metadata.duration!.inMilliseconds > 0) {
          duration = metadata.duration!.inMilliseconds;
        }
      }
    } catch (_) {
      // In case of physical tag parsing failure, fallback fields remain intact
    }

    // Heurísticas de carpeta solo para archivos con campos desconocidos
    if (title.isEmpty || title == '<Desconocido>' || title == '<unknown>') {
      final fileName = item.path.split(Platform.pathSeparator).last;
      title = fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '').trim();
      if (title.isEmpty) title = 'Pista desconocida';
    }

    if (artist.isEmpty || artist == '<Desconocido>' || artist == '<unknown>') {
      final segments = item.path.split(Platform.pathSeparator);
      if (segments.length >= 2) {
        final parentFolder = segments[segments.length - 2];
        final lower = parentFolder.toLowerCase();
        if (lower != 'music' &&
            lower != 'download' &&
            lower != 'storage' &&
            lower != 'emulated' &&
            parentFolder.isNotEmpty) {
          artist = parentFolder;
        } else {
          artist = '<Desconocido>';
        }
      } else {
        artist = '<Desconocido>';
      }
    }

    if (album.isEmpty || album == '<Desconocido>' || album == '<unknown>') {
      album = '<Desconocido>';
    }

    if (albumArtist != null) {
      final clean = albumArtist.trim();
      if (clean.isEmpty || clean == '<Desconocido>' || clean == '<unknown>') {
        albumArtist = null;
      } else {
        albumArtist = clean;
      }
    }

    results.add(Song(
      mediaStoreId: item.mediaStoreId,
      title: title,
      artist: artist,
      album: album,
      albumArtist: albumArtist,
      albumId: item.albumId,
      duration: duration,
      path: item.path,
      dateModified: item.dateModified,
      dateAdded: item.dateAdded,
      size: item.size,
    ));
  }

  return results;
}

/// Core high-performance scanning and synchronization engine.
class MusicIndexer {
  static final MusicIndexer instance = MusicIndexer._internal();
  static const MethodChannel _mediaStoreChannel = MethodChannel('project_anima/media_store');

  MusicIndexer._internal({SongDao? songDao})
      : _songDao = songDao ?? SongDao();

  /// Factory provider allowing dependency injection for tests or custom DAO instances.
  factory MusicIndexer({SongDao? songDao}) {
    if (songDao == null) {
      return instance;
    }
    return MusicIndexer._internal(songDao: songDao);
  }

  final SongDao _songDao;

  bool _isIndexing = false;

  /// Whether a synchronization job is currently in progress.
  bool get isIndexing => _isIndexing;

  /// Checks if a filesystem path belongs to voice notes, ringtones, or messaging directories.
  static bool isExcludedPath(String path) {
    final lower = path.toLowerCase();
    return lower.contains('whatsapp') ||
        lower.contains('telegram') ||
        lower.contains('/notifications/') ||
        lower.contains('/ringtones/') ||
        lower.contains('/alarms/') ||
        lower.contains('voice recorder') ||
        lower.contains('voicenotes') ||
        lower.contains('audiorecorder');
  }

  /// Checks if a filesystem path has a supported audio extension.
  static bool isSupportedAudioFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp3') ||
        lower.endsWith('.flac') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.opus') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.aac');
  }

  /// Synchronizes device audio storage with local SQLite database following the 4-phase pipeline.
  ///
  /// Emits terminal log showing song count and elapsed duration upon completion.
  Future<IndexingResult> syncWithDevice({
    List<LightweightAudioItem>? mockDeviceItems,
  }) async {
    if (_isIndexing) {
      return IndexingResult.alreadyRunning();
    }
    _isIndexing = true;
    final stopwatch = Stopwatch()..start();

    try {
      // FASE 1: Proyección liviana de MediaStore (Coste: ~10-20 ms)
      final List<LightweightAudioItem> deviceItems =
          mockDeviceItems ?? await _fetchLightweightProjection();

      final Map<int, int> deviceMap = {
        for (final item in deviceItems) item.mediaStoreId: item.dateModified,
      };

      // FASE 2: Diff Set Algebraico en Memoria (Coste: < 2 ms para 10.000 canciones)
      final Map<int, int> cachedMap =
          await _songDao.getCachedMediaStoreIdsAndModified();

      final Set<int> deviceIds = deviceMap.keys.toSet();
      final Set<int> cachedIds = cachedMap.keys.toSet();

      final Set<int> addedIds = deviceIds.difference(cachedIds);
      final Set<int> deletedIds = cachedIds.difference(deviceIds);
      final Set<int> updatedIds = deviceIds.intersection(cachedIds).where(
        (id) => deviceMap[id] != cachedMap[id],
      ).toSet();

      final int deltaCount = addedIds.length + updatedIds.length + deletedIds.length;

      // Check if one-time album_artist backfill is needed for cached songs
      final bool needsBackfill = !await _songDao.isAlbumArtistBackfilled();
      if (needsBackfill) {
        final Map<int, String> backfillMap = {
          for (final item in deviceItems)
            if (item.fallbackAlbumArtist != null &&
                item.fallbackAlbumArtist!.trim().isNotEmpty)
              item.mediaStoreId: item.fallbackAlbumArtist!.trim(),
        };
        if (backfillMap.isNotEmpty) {
          await _songDao.backfillAlbumArtists(backfillMap);
        }
        await _songDao.markAlbumArtistBackfilled();
      }

      // Si delta == 0: Finalizar sincronización de inmediato sin tocar el disco
      if (deltaCount == 0) {
        stopwatch.stop();
        final int totalSongs = cachedIds.length;
        debugPrint(
          '🎵 [MusicIndexer] Sincronización completada: $totalSongs canciones en ${stopwatch.elapsedMilliseconds} ms. (Sin cambios / 0 deltas)',
        );

        // Ensure missing artworks are enqueued for background processing
        _songDao.getAllSongs().then((songs) {
          ArtworkService.instance.enqueueSongs(songs);
        });

        return IndexingResult(
          totalSongs: totalSongs,
          addedCount: 0,
          updatedCount: 0,
          deletedCount: 0,
          elapsedMilliseconds: stopwatch.elapsedMilliseconds,
        );
      }

      // FASE 3: Deep Scan Aislado (Solo para addedIds + updatedIds)
      final Set<int> scanIds = {...addedIds, ...updatedIds};
      final List<LightweightAudioItem> itemsToScan = deviceItems.where(
        (item) => scanIds.contains(item.mediaStoreId),
      ).toList();

      List<Song> parsedSongs = [];
      if (itemsToScan.isNotEmpty) {
        parsedSongs = await compute(parseMetadataInIsolate, itemsToScan);
      }

      // FASE 4: Escritura Atómica en SQLite
      await _songDao.syncDelta(
        toInsertOrUpdate: parsedSongs,
        toDelete: deletedIds.toList(),
      );

      stopwatch.stop();
      final int totalSongs = await _songDao.getSongCount();

      // Output terminal log as explicitly requested by specification
      debugPrint(
        '🎵 [MusicIndexer] Sincronización completada: $totalSongs canciones en ${stopwatch.elapsedMilliseconds} ms. '
        '(Añadidas: ${addedIds.length}, Modificadas: ${updatedIds.length}, Eliminadas: ${deletedIds.length})',
      );

      // Auto-enqueue newly indexed tracks into ArtworkService background throttled queue
      if (parsedSongs.isNotEmpty) {
        ArtworkService.instance.enqueueSongs(parsedSongs);
      }

      return IndexingResult(
        totalSongs: totalSongs,
        addedCount: addedIds.length,
        updatedCount: updatedIds.length,
        deletedCount: deletedIds.length,
        elapsedMilliseconds: stopwatch.elapsedMilliseconds,
      );
    } catch (e, stack) {
      debugPrint('❌ [MusicIndexer] Error durante la indexación: $e\n$stack');
      rethrow;
    } finally {
      _isIndexing = false;
    }
  }

  /// Fetches lightweight audio projection matching current platform.
  Future<List<LightweightAudioItem>> _fetchLightweightProjection() async {
    if (Platform.isAndroid) {
      return await _fetchAndroidLightweightProjection();
    } else {
      return await _fetchDesktopLightweightProjection();
    }
  }

  /// Queries Android MediaStore through the native high-speed MethodChannel and filters noise files.
  Future<List<LightweightAudioItem>> _fetchAndroidLightweightProjection() async {
    try {
      final List<dynamic>? rawList =
          await _mediaStoreChannel.invokeMethod<List<dynamic>>('queryAudio');
      if (rawList == null) return [];

      final List<LightweightAudioItem> items = [];
      for (final raw in rawList) {
        if (raw is! Map) continue;
        final path = raw['path'] as String? ?? '';
        if (path.isEmpty || isExcludedPath(path)) continue;

        items.add(LightweightAudioItem(
          mediaStoreId: (raw['id'] as num).toInt(),
          path: path,
          dateModified: (raw['dateModified'] as num?)?.toInt() ?? 0,
          dateAdded: (raw['dateAdded'] as num?)?.toInt(),
          duration: (raw['duration'] as num?)?.toInt() ?? 0,
          size: (raw['size'] as num?)?.toInt(),
          fallbackTitle: (raw['title'] as String?) ?? '',
          fallbackArtist: raw['artist'] as String?,
          fallbackAlbum: raw['album'] as String?,
          fallbackAlbumArtist: raw['albumArtist'] as String?,
          albumId: (raw['albumId'] as num?)?.toInt(),
        ));
      }
      return items;
    } catch (e) {
      debugPrint('⚠️ [MusicIndexer] MediaStore MethodChannel warning: $e');
      return [];
    }
  }

  /// Scans standard Linux/desktop audio directories for supported audio tracks.
  Future<List<LightweightAudioItem>> _fetchDesktopLightweightProjection() async {
    final List<LightweightAudioItem> items = [];
    final home = Platform.environment['HOME'];
    if (home == null) return items;

    final musicDir = Directory('$home/Music');
    if (!musicDir.existsSync()) return items;

    try {
      await for (final entity in musicDir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final path = entity.path;
        if (!isSupportedAudioFile(path)) continue;
        if (isExcludedPath(path)) continue;

        try {
          final stat = await entity.stat();
          final id = path.hashCode.abs();
          final fileName = path.split(Platform.pathSeparator).last;
          final title = fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

          items.add(LightweightAudioItem(
            mediaStoreId: id,
            path: path,
            dateModified: stat.modified.millisecondsSinceEpoch ~/ 1000,
            dateAdded: stat.changed.millisecondsSinceEpoch ~/ 1000,
            duration: 0,
            size: stat.size,
            fallbackTitle: title,
            fallbackArtist: '<Desconocido>',
            fallbackAlbum: '<Desconocido>',
            albumId: null,
          ));
        } catch (_) {
          // Skip inaccessible file
        }
      }
    } catch (e) {
      debugPrint('⚠️ [MusicIndexer] Desktop filesystem scan warning: $e');
    }
    return items;
  }
}

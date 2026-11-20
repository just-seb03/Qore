/// File: artwork_color_extractor.dart
/// Description: Fast O(1)-cached dominant color extractor for album covers, reading cached
/// Dual-Tier artwork thumbnails and selecting a vibrant, visually balanced primary color.
///
/// Components / Classes / Functions:
/// - ArtworkColorExtractor: Quantized chroma-weighted cover color extraction with LRU-like cache.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/models/song.dart';

class _ColorBucket {
  double weight = 0.0;
  double sumR = 0.0;
  double sumG = 0.0;
  double sumB = 0.0;
}

/// Extracts and caches the primary/dominant visual color from track album covers.
abstract final class ArtworkColorExtractor {
  static const Color defaultWaveColor = Color(0xFF5BABCE);
  static const int _maxCacheEntries = 256;

  static final Map<String, Color> _colorCache = {};

  /// Returns the cached primary color for [song] synchronously if already extracted.
  static Color? getCachedColorForSong(Song song) {
    final path = _resolveArtworkPath(song);
    if (path == null) return null;
    return _colorCache[path];
  }

  /// Resolves the dominant cover color for [song], caching by file path.
  /// Returns [defaultWaveColor] when the track has no artwork or decoding fails.
  static Future<Color> getDominantColorForSong(Song song) async {
    final path = _resolveArtworkPath(song);
    if (path == null) return defaultWaveColor;

    final cached = _colorCache[path];
    if (cached != null) return cached;

    try {
      final file = File(path);
      if (!await file.exists()) return defaultWaveColor;
      final bytes = await file.readAsBytes();
      final extracted = extractDominantColorFromBytes(bytes);
      if (extracted == null) return defaultWaveColor;

      if (_colorCache.length >= _maxCacheEntries) {
        _colorCache.remove(_colorCache.keys.first);
      }
      _colorCache[path] = extracted;
      return extracted;
    } catch (_) {
      return defaultWaveColor;
    }
  }

  /// Extracts a balanced dominant color from encoded PNG/JPEG/WebP image bytes.
  /// Samples pixels across a compact grid and weights colorful regions over flat dark/white borders.
  static Color? extractDominantColorFromBytes(Uint8List bytes) {
    if (bytes.isEmpty) return null;
    final decoded = img.decodeImage(bytes);
    if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
      return null;
    }

    const int targetGrid = 24;
    final int stepX = math.max(1, decoded.width ~/ targetGrid);
    final int stepY = math.max(1, decoded.height ~/ targetGrid);

    // Quantize RGB into 5x5x5 buckets so slight JPEG compression shifts aggregate cleanly
    final Map<int, _ColorBucket> colorBuckets = {};
    final Map<int, _ColorBucket> allBuckets = {};

    for (int y = 0; y < decoded.height; y += stepY) {
      for (int x = 0; x < decoded.width; x += stepX) {
        final pixel = decoded.getPixel(x, y);
        if (pixel.a < 128) continue;

        final int r = pixel.r.toInt().clamp(0, 255);
        final int g = pixel.g.toInt().clamp(0, 255);
        final int b = pixel.b.toInt().clamp(0, 255);

        final double maxC = math.max(r, math.max(g, b)) / 255.0;
        final double minC = math.min(r, math.min(g, b)) / 255.0;
        final double sat = maxC > 1e-4 ? (maxC - minC) / maxC : 0.0;
        final double lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;

        final int br = r >> 5;
        final int bg = g >> 5;
        final int bb = b >> 5;
        final int key = (br << 10) | (bg << 5) | bb;

        // Track full-image fallback bucket in case cover is monochrome B&W
        final allBucket = allBuckets.putIfAbsent(key, () => _ColorBucket());
        final double baseWeight = (lum > 0.08 && lum < 0.94) ? 1.0 : 0.25;
        allBucket.weight += baseWeight;
        allBucket.sumR += r * baseWeight;
        allBucket.sumG += g * baseWeight;
        allBucket.sumB += b * baseWeight;

        // Skip near-black or near-white neutral borders when selecting vivid main cover hue
        if (lum < 0.06 || (lum > 0.94 && sat < 0.10)) continue;

        final double midLumBoost = 1.0 - 0.35 * (lum - 0.5).abs();
        final double chromaWeight = (0.25 + 3.0 * sat * sat) * midLumBoost;

        final bucket = colorBuckets.putIfAbsent(key, () => _ColorBucket());
        bucket.weight += chromaWeight;
        bucket.sumR += r * chromaWeight;
        bucket.sumG += g * chromaWeight;
        bucket.sumB += b * chromaWeight;
      }
    }

    final Map<int, _ColorBucket> source =
        colorBuckets.isNotEmpty ? colorBuckets : allBuckets;
    if (source.isEmpty) return null;

    _ColorBucket? best;
    for (final bucket in source.values) {
      if (best == null || bucket.weight > best.weight) {
        best = bucket;
      }
    }
    if (best == null || best.weight <= 0.0) return null;

    final int r = (best.sumR / best.weight).round().clamp(0, 255);
    final int g = (best.sumG / best.weight).round().clamp(0, 255);
    final int b = (best.sumB / best.weight).round().clamp(0, 255);
    return Color.fromARGB(255, r, g, b);
  }

  static String? _resolveArtworkPath(Song song) {
    final artwork = ArtworkService.instance;
    var path = artwork.getThumbnailPath(
          song.mediaStoreId,
          albumId: song.albumId,
          album: song.album,
          artist: song.albumArtist ?? song.artist,
        ) ??
        artwork.getCoverPath(
          song.mediaStoreId,
          albumId: song.albumId,
          album: song.album,
          artist: song.albumArtist ?? song.artist,
        );

    if (path == null && song.album != null && (song.albumArtist ?? song.artist) != null) {
      final artName = song.albumArtist ?? song.artist!;
      path = artwork.getThumbnailForAlbum(song.album!, artName) ??
          artwork.getCoverForAlbum(song.album!, artName);
    }
    return path;
  }

  /// Clears cached dominant colors (for testing or cache resets).
  @visibleForTesting
  static void clearCache() => _colorCache.clear();
}


/// File: artist_splitter.dart
/// Description: Robust parsing and splitting utility for audio tracks featuring multiple artists.
/// Handles standard delimiters (',', '/', ';'), preserves casing, trims whitespace,
/// avoids false splits for established artists with slashes (e.g. AC/DC), and filters
/// placeholder artist tokens.
///
/// Components / Classes / Functions:
/// - ArtistSplitter: Utility class containing deterministic artist splitting logic.
library;

import 'package:flutter/foundation.dart';

/// High-speed, deterministic artist separation utility.
class ArtistSplitter {
  ArtistSplitter._();

  static final RegExp _delimiterRegex = RegExp(
    r'\s*[,;]\s*|\s*/\s*|\s+(?:feat\.|ft\.|featuring|with)\s+',
    caseSensitive: false,
  );

  /// Known artists containing slashes in their official name that should not be split.
  static const Set<String> _protectedArtists = {
    'ac/dc',
  };

  /// Bounded cache of memoized artist split results to avoid re-running regexes
  /// and re-allocating identical `List<String>` objects across thousands of song models.
  static final Map<String, List<String>> _splitCache = {};
  static const int _kMaxCacheSize = 1024;

  /// Clears the memoized cache (primarily for tests).
  @visibleForTesting
  static void clearCache() => _splitCache.clear();

  /// Splits a raw artist string into individual, trimmed, deduplicated artist names.
  ///
  /// Examples:
  /// - `"Virtual Riot, Eliminate"` -> `["Virtual Riot", "Eliminate"]`
  /// - `"Virtual Riot / Eliminate"` -> `["Virtual Riot", "Eliminate"]`
  /// - `"Virtual Riot; Eliminate"` -> `["Virtual Riot", "Eliminate"]`
  /// - `"AC/DC"` -> `["AC/DC"]`
  /// - `"<Desconocido>"` -> `[]`
  static List<String> split(String? raw) {
    if (raw == null) return const [];
    final trimmed = raw.trim();
    if (trimmed.isEmpty ||
        trimmed == '<Desconocido>' ||
        trimmed == '<unknown>' ||
        trimmed.toLowerCase() == 'unknown artist') {
      return const [];
    }

    final cached = _splitCache[trimmed];
    if (cached != null) return cached;

    // Preserve protected artists containing slashes
    if (_protectedArtists.contains(trimmed.toLowerCase())) {
      final protectedResult = List<String>.unmodifiable([trimmed]);
      if (_splitCache.length >= _kMaxCacheSize) {
        _splitCache.clear();
      }
      _splitCache[trimmed] = protectedResult;
      return protectedResult;
    }

    final tokens = trimmed.split(_delimiterRegex);
    final List<String> result = [];
    final Set<String> seen = {};

    for (final token in tokens) {
      final clean = token.trim();
      if (clean.isEmpty ||
          clean == '<Desconocido>' ||
          clean == '<unknown>' ||
          clean.toLowerCase() == 'unknown artist') {
        continue;
      }

      final lower = clean.toLowerCase();
      if (!seen.contains(lower)) {
        seen.add(lower);
        result.add(clean);
      }
    }

    final finalResult =
        result.isEmpty && trimmed.isNotEmpty && trimmed != '<Desconocido>'
            ? List<String>.unmodifiable([trimmed])
            : List<String>.unmodifiable(result);

    if (_splitCache.length >= _kMaxCacheSize) {
      _splitCache.clear();
    }
    _splitCache[trimmed] = finalResult;
    return finalResult;
  }

  /// Extracts the primary/lead artist name from a raw artist string.
  static String primaryArtist(String? raw) {
    final list = split(raw);
    if (list.isNotEmpty) return list.first;
    if (raw == null || raw.trim().isEmpty) return '<Desconocido>';
    return raw.trim();
  }
}

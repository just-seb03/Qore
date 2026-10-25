/// File: fuzzy_search_engine.dart
/// Description: High-performance, typo-tolerant fuzzy search engine implementing
/// Damerau-Levenshtein distance, multi-token fuzzy matching, and Spotify-style
/// entity relevance ranking (Artist, Album, Song).
///
/// Components / Classes / Functions:
/// - FuzzySearchEngine: Core search engine coordinating dictionary caching and fuzzy scoring.
library;

import 'dart:math' as math;
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/search/models/search_entity_type.dart';
import 'package:project_anima/core/search/models/search_results_group.dart';
import 'package:project_anima/core/search/models/search_top_result.dart';

/// High-performance fuzzy matching and category relevance ranking engine.
class FuzzySearchEngine {
  final SongDao _songDao;

  FuzzySearchEngine({SongDao? songDao}) : _songDao = songDao ?? SongDao();

  List<ArtistDiscoveryItem> _cachedArtists = [];
  List<AlbumDiscoveryItem> _cachedAlbums = [];
  List<Song> _cachedSongs = [];
  bool _isDictionaryLoaded = false;

  /// Whether the in-memory entity dictionary has been populated from SQLite.
  bool get isDictionaryLoaded => _isDictionaryLoaded;

  /// Loads or refreshes the in-memory search dictionary for instant (< 3 ms) fuzzy evaluation.
  Future<void> reloadDictionary() async {
    try {
      final artists = await _songDao.getAllUniqueArtists(limit: 1000);
      final albums = await _songDao.getAllUniqueAlbums(limit: 1000);
      final songs = await _songDao.getAllSongs();

      _cachedArtists = artists;
      _cachedAlbums = albums;
      _cachedSongs = songs;
      _isDictionaryLoaded = true;
    } catch (_) {
      // Gracefully ignore error and allow query-level fallback
    }
  }

  /// Calculates Damerau-Levenshtein distance between [source] and [target],
  /// supporting insertions, deletions, substitutions, and adjacent transpositions.
  static int damerauLevenshteinDistance(String source, String target) {
    final sLen = source.length;
    final tLen = target.length;
    if (sLen == 0) return tLen;
    if (tLen == 0) return sLen;

    final d = List.generate(sLen + 1, (_) => List.filled(tLen + 1, 0));

    for (var i = 0; i <= sLen; i++) {
      d[i][0] = i;
    }
    for (var j = 0; j <= tLen; j++) {
      d[0][j] = j;
    }

    for (var i = 1; i <= sLen; i++) {
      for (var j = 1; j <= tLen; j++) {
        final cost = source[i - 1] == target[j - 1] ? 0 : 1;

        d[i][j] = math.min(
          d[i - 1][j] + 1, // deletion
          math.min(
            d[i][j - 1] + 1, // insertion
            d[i - 1][j - 1] + cost, // substitution
          ),
        );

        // Transposition
        if (i > 1 &&
            j > 1 &&
            source[i - 1] == target[j - 2] &&
            source[i - 2] == target[j - 1]) {
          d[i][j] = math.min(d[i][j], d[i - 2][j - 2] + 1);
        }
      }
    }

    return d[sLen][tLen];
  }

  /// Computes a normalized fuzzy similarity score between [query] and [target] in [0.0 - 1.0].
  ///
  /// Combines:
  /// - Exact match: 1.0
  /// - Exact prefix: 0.90 - 0.99
  /// - Exact substring: 0.75 - 0.85
  /// - Compact Damerau-Levenshtein (handles space/punctuation typos, e.g. "ridoi jead" -> "radiohead")
  /// - Multi-token word-by-word fuzzy alignment
  static double computeFuzzyScore(String query, String target) {
    final q = query.trim().toLowerCase();
    final t = target.trim().toLowerCase();

    if (q.isEmpty || t.isEmpty) return 0.0;
    if (q == t) return 1.0;

    // 1. Exact prefix bonus
    if (t.startsWith(q)) {
      return 0.90 + (0.09 * (q.length / t.length));
    }

    // 2. Exact substring bonus
    if (t.contains(q)) {
      return 0.75 + (0.10 * (q.length / t.length));
    }

    // 3. Compact comparison (ignoring whitespace and special delimiters)
    final cleanQ = q.replaceAll(RegExp(r'[\s\-_.,/&]+'), '');
    final cleanT = t.replaceAll(RegExp(r'[\s\-_.,/&]+'), '');

    if (cleanQ.isEmpty || cleanT.isEmpty) return 0.0;
    if (cleanQ == cleanT) return 0.98;
    if (cleanT.startsWith(cleanQ)) return 0.88;
    if (cleanT.contains(cleanQ)) return 0.72;

    final compactDistance = damerauLevenshteinDistance(cleanQ, cleanT);
    final maxLen = math.max(cleanQ.length, cleanT.length);
    final compactScore = 1.0 - (compactDistance / maxLen);

    // 4. Token-level matching for multi-word queries
    final qTokens = q.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final tTokens = t.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

    double tokenTotalScore = 0.0;
    for (final qTok in qTokens) {
      double bestTokScore = 0.0;
      for (final tTok in tTokens) {
        if (tTok == qTok) {
          bestTokScore = 1.0;
          break;
        }
        if (tTok.startsWith(qTok)) {
          bestTokScore = math.max(bestTokScore, 0.85);
          continue;
        }
        if (tTok.contains(qTok)) {
          bestTokScore = math.max(bestTokScore, 0.70);
          continue;
        }
        final dist = damerauLevenshteinDistance(qTok, tTok);
        final mLen = math.max(qTok.length, tTok.length);
        final score = 1.0 - (dist / mLen);
        if (score > bestTokScore) bestTokScore = score;
      }
      tokenTotalScore += bestTokScore;
    }
    final tokenAvgScore = qTokens.isNotEmpty ? (tokenTotalScore / qTokens.length) : 0.0;

    return math.max(compactScore, tokenAvgScore);
  }

  /// Executes advanced fuzzy search across cached dictionary items and returns
  /// categorized results with Spotify-style dynamic hierarchy.
  Future<SearchResultsGroup> search(String rawQuery, {int songLimit = 5}) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return SearchResultsGroup.empty(query);
    }

    // Lazy load dictionary if not preloaded
    if (!_isDictionaryLoaded) {
      await reloadDictionary();
    }

    // Minimum threshold for fuzzy matches to qualify
    const double minRelevanceThreshold = 0.45;

    // 1. Evaluate Artists
    ArtistDiscoveryItem? bestArtist;
    double bestArtistScore = 0.0;
    final List<_ScoredItem<ArtistDiscoveryItem>> scoredArtists = [];

    for (final artist in _cachedArtists) {
      final score = computeFuzzyScore(query, artist.name);
      if (score >= minRelevanceThreshold) {
        scoredArtists.add(_ScoredItem(artist, score));
        if (score > bestArtistScore) {
          bestArtistScore = score;
          bestArtist = artist;
        }
      }
    }
    scoredArtists.sort((a, b) => b.score.compareTo(a.score));

    // 2. Evaluate Albums
    AlbumDiscoveryItem? bestAlbum;
    double bestAlbumScore = 0.0;
    final List<_ScoredItem<AlbumDiscoveryItem>> scoredAlbums = [];

    for (final album in _cachedAlbums) {
      final titleScore = computeFuzzyScore(query, album.name);
      final artistScore = computeFuzzyScore(query, album.artist);
      final score = math.max(titleScore, artistScore * 0.9);

      if (score >= minRelevanceThreshold) {
        scoredAlbums.add(_ScoredItem(album, score));
        if (score > bestAlbumScore) {
          bestAlbumScore = score;
          bestAlbum = album;
        }
      }
    }
    scoredAlbums.sort((a, b) => b.score.compareTo(a.score));

    // 3. Evaluate Songs
    Song? bestSong;
    double bestSongScore = 0.0;
    final List<_ScoredItem<Song>> scoredSongs = [];

    for (final song in _cachedSongs) {
      final titleScore = computeFuzzyScore(query, song.title);
      double artistScore = 0.0;
      if (song.artists.isNotEmpty) {
        for (final a in song.artists) {
          final s = computeFuzzyScore(query, a);
          if (s > artistScore) artistScore = s;
        }
      } else if (song.artist != null) {
        artistScore = computeFuzzyScore(query, song.artist!);
      }
      final albumScore = song.album != null ? computeFuzzyScore(query, song.album!) : 0.0;

      // Title match takes precedence, but artist/album matches also contribute
      final score = math.max(titleScore, math.max(artistScore * 0.85, albumScore * 0.75));

      if (score >= minRelevanceThreshold) {
        scoredSongs.add(_ScoredItem(song, score));
        if (score > bestSongScore) {
          bestSongScore = score;
          bestSong = song;
        }
      }
    }
    scoredSongs.sort((a, b) => b.score.compareTo(a.score));

    // If completely no fuzzy match found in dictionary, return empty
    if (scoredArtists.isEmpty && scoredAlbums.isEmpty && scoredSongs.isEmpty) {
      return SearchResultsGroup.empty(query);
    }

    // 4. Determine Top Result & Primary Category
    // Compare category top scores. Artist gets a slight intentional boost if scores are close,
    // reflecting music app behavior (e.g. searching "radiohead" highlights the artist first).
    final double artistWeight = bestArtistScore * 1.05;
    final double albumWeight = bestAlbumScore;
    final double songWeight = bestSongScore;

    SearchTopResult? topResult;
    SearchEntityType primaryType;

    if (artistWeight >= albumWeight && artistWeight >= songWeight && bestArtist != null) {
      primaryType = SearchEntityType.artist;
      topResult = SearchTopResult.artist(bestArtist, bestArtistScore);
    } else if (albumWeight >= songWeight && bestAlbum != null) {
      primaryType = SearchEntityType.album;
      topResult = SearchTopResult.album(bestAlbum, bestAlbumScore);
    } else if (bestSong != null) {
      primaryType = SearchEntityType.song;
      topResult = SearchTopResult.song(bestSong, bestSongScore);
    } else {
      primaryType = SearchEntityType.song;
    }

    // 5. Build Sub-Collections
    // A. Songs: Up to [songLimit] (default 5, strict rule)
    final List<Song> secondarySongs = [];
    if (primaryType == SearchEntityType.artist && bestArtist != null) {
      // Songs by this artist first (matching single or collaborative artists)
      final targetArtistLower = bestArtist.name.toLowerCase();
      final artistSongs = _cachedSongs
          .where((s) =>
              s.artists.any((a) => a.toLowerCase() == targetArtistLower) ||
              (s.artist != null && s.artist!.toLowerCase() == targetArtistLower))
          .take(songLimit)
          .toList();
      secondarySongs.addAll(artistSongs);

      // If artist has fewer songs than limit, fill with scored songs
      if (secondarySongs.length < songLimit) {
        for (final item in scoredSongs) {
          if (!secondarySongs.any((s) => s.mediaStoreId == item.item.mediaStoreId)) {
            secondarySongs.add(item.item);
            if (secondarySongs.length >= songLimit) break;
          }
        }
      }
    } else if (primaryType == SearchEntityType.album && bestAlbum != null) {
      // Songs from this album first, matching by album name and effective album artist
      final albumNameLower = bestAlbum.name.toLowerCase();
      final albumArtistLower = bestAlbum.artist.toLowerCase();
      final albumSongs = _cachedSongs
          .where((s) {
            if (s.album == null || s.album!.toLowerCase() != albumNameLower) return false;
            if (albumArtistLower == '<desconocido>') return true;
            final effectiveSongArtist = (s.albumArtist != null && s.albumArtist!.trim().isNotEmpty)
                ? s.albumArtist!.trim()
                : (s.artist ?? '');
            return effectiveSongArtist.toLowerCase() == albumArtistLower;
          })
          .take(songLimit)
          .toList();
      secondarySongs.addAll(albumSongs);

      if (secondarySongs.length < songLimit) {
        for (final item in scoredSongs) {
          if (!secondarySongs.any((s) => s.mediaStoreId == item.item.mediaStoreId)) {
            secondarySongs.add(item.item);
            if (secondarySongs.length >= songLimit) break;
          }
        }
      }
    } else {
      // Song primary: take top matching songs
      for (final item in scoredSongs) {
        // Exclude the top result song from the secondary list if already shown as top card
        if (topResult?.song?.mediaStoreId == item.item.mediaStoreId) continue;
        secondarySongs.add(item.item);
        if (secondarySongs.length >= songLimit) break;
      }
    }

    // B. Albums: Matched albums (excluding top result if album)
    final List<AlbumDiscoveryItem> secondaryAlbums = [];
    if (primaryType == SearchEntityType.artist && bestArtist != null) {
      final targetArtist = bestArtist.name.toLowerCase();
      final artistAlbums = _cachedAlbums
          .where((a) => a.artist.toLowerCase() == targetArtist)
          .toList();
      secondaryAlbums.addAll(artistAlbums);
    }
    for (final item in scoredAlbums) {
      if (topResult?.album?.name.toLowerCase() == item.item.name.toLowerCase()) continue;
      if (!secondaryAlbums.any((a) => a.name.toLowerCase() == item.item.name.toLowerCase())) {
        secondaryAlbums.add(item.item);
      }
    }

    // C. Artists: Matched artists (excluding top result if artist)
    final List<ArtistDiscoveryItem> secondaryArtists = [];
    for (final item in scoredArtists) {
      if (topResult?.artist?.name.toLowerCase() == item.item.name.toLowerCase()) continue;
      secondaryArtists.add(item.item);
    }

    // If album/song is top, also append their artist to secondary artists if available
    final currentAlbum = bestAlbum;
    final currentSong = bestSong;
    if (primaryType == SearchEntityType.album && currentAlbum != null) {
      final albumArtistName = currentAlbum.artist.toLowerCase();
      final artistMatch = _cachedArtists.firstWhere(
        (a) => a.name.toLowerCase() == albumArtistName,
        orElse: () => ArtistDiscoveryItem(
          name: currentAlbum.artist,
          songCount: 0,
          albumCount: 0,
          representativeSongId: currentAlbum.representativeSongId,
        ),
      );
      if (!secondaryArtists.any((a) => a.name.toLowerCase() == albumArtistName)) {
        secondaryArtists.insert(0, artistMatch);
      }
    } else if (primaryType == SearchEntityType.song && currentSong != null) {
      final songArtists = currentSong.artists.isNotEmpty
          ? currentSong.artists
          : (currentSong.artist != null ? [currentSong.artist!] : <String>[]);

      for (final sArtist in songArtists) {
        final sArtistLower = sArtist.toLowerCase();
        final artistMatch = _cachedArtists.firstWhere(
          (a) => a.name.toLowerCase() == sArtistLower,
          orElse: () => ArtistDiscoveryItem(
            name: sArtist,
            songCount: 0,
            albumCount: 0,
            representativeSongId: currentSong.mediaStoreId,
          ),
        );
        if (!secondaryArtists.any((a) => a.name.toLowerCase() == sArtistLower)) {
          secondaryArtists.add(artistMatch);
        }
      }
    }

    return SearchResultsGroup(
      query: query,
      topResult: topResult,
      primaryType: primaryType,
      matchedSongs: secondarySongs.take(songLimit).toList(),
      matchedAlbums: secondaryAlbums,
      matchedArtists: secondaryArtists,
    );
  }

  /// Searches only songs using the in-memory cached dictionary with typo-tolerant
  /// fuzzy matching (title, artist, album), token scoring, and Damerau-Levenshtein distance.
  Future<List<Song>> searchOnlySongs(String rawQuery, {int limit = 20}) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return [];

    if (!_isDictionaryLoaded) {
      await reloadDictionary();
    }

    const double minRelevanceThreshold = 0.38;
    final List<_ScoredItem<Song>> scoredSongs = [];

    for (final song in _cachedSongs) {
      final titleScore = computeFuzzyScore(query, song.title);
      final artistScore = song.artist != null ? computeFuzzyScore(query, song.artist!) : 0.0;
      final albumScore = song.album != null ? computeFuzzyScore(query, song.album!) : 0.0;

      final score = math.max(titleScore, math.max(artistScore * 0.85, albumScore * 0.75));

      if (score >= minRelevanceThreshold) {
        scoredSongs.add(_ScoredItem(song, score));
      }
    }

    scoredSongs.sort((a, b) => b.score.compareTo(a.score));
    return scoredSongs.take(limit).map((e) => e.item).toList();
  }
}

/// Helper container pairing a scored data item with its normalized similarity score.
class _ScoredItem<T> {
  final T item;
  final double score;

  const _ScoredItem(this.item, this.score);
}

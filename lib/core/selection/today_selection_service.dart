/// File: today_selection_service.dart
/// Description: Generates and caches the 20-song system playlist 'Today's Selection'.
/// Features deterministic daily shuffling based on date seed and selects representative collage covers.
///
/// Components / Classes / Functions:
/// - TodaySelectionService: Singleton service providing daily curated 20-track selection.
library;

import 'package:flutter/foundation.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';

/// Service managing the system-generated 'Today's Selection' 20-song playlist.
class TodaySelectionService extends ChangeNotifier {
  static final TodaySelectionService instance = TodaySelectionService._internal();

  TodaySelectionService._internal();

  factory TodaySelectionService() => instance;

  List<Song>? _cachedTodaySongs;
  DateTime? _lastFetchDate;

  /// Retrieves the 20 random songs curated for today.
  /// Seeds random shuffling by current day so the playlist remains consistent across app usage.
  Future<List<Song>> getTodaySelection({
    bool forceRefresh = false,
    SongDao? songDao,
  }) async {
    final now = DateTime.now();
    final isSameDay = _lastFetchDate != null &&
        _lastFetchDate!.year == now.year &&
        _lastFetchDate!.month == now.month &&
        _lastFetchDate!.day == now.day;

    if (!forceRefresh && isSameDay && _cachedTodaySongs != null) {
      return _cachedTodaySongs!;
    }

    try {
      final dao = songDao ?? SongDao();
      // Deterministic daily seed based on YYYYMMDD
      final seed = now.year * 10000 + now.month * 100 + now.day;
      final selectedSongs = await dao.getRandomDailySelection(seed: seed, limit: 20);

      _cachedTodaySongs = selectedSongs;
      _lastFetchDate = now;
      notifyListeners();
      return _cachedTodaySongs!;
    } catch (e) {
      debugPrint('⚠️ [TodaySelectionService] Error fetching today selection: $e');
      return _cachedTodaySongs ?? [];
    }
  }

  /// Picks up to 4 songs from [songs] with distinct album/artist combinations
  /// to create a vibrant collage hero banner.
  List<Song> getCollageSongs(List<Song> songs) {
    if (songs.isEmpty) return [];

    final List<Song> collage = [];
    final Set<String> seenAlbums = {};

    for (final song in songs) {
      final key = '${song.album ?? ''}::${song.artist ?? ''}'.toLowerCase();
      if (!seenAlbums.contains(key)) {
        seenAlbums.add(key);
        collage.add(song);
        if (collage.length == 4) break;
      }
    }

    // If fewer than 4 distinct albums, fill remaining with first songs
    if (collage.length < 4) {
      for (final song in songs) {
        if (!collage.contains(song)) {
          collage.add(song);
          if (collage.length == 4) break;
        }
      }
    }

    return collage;
  }

  /// Clears in-memory cache (for testing or manual refresh).
  @visibleForTesting
  void clearCache() {
    _cachedTodaySongs = null;
    _lastFetchDate = null;
  }
}

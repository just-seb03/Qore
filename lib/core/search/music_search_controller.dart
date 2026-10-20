/// File: music_search_controller.dart
/// Description: Zero-Jank Search Controller implementing 280 ms debouncing,
/// 20-item paginated loading, SQLite FTS5 integration, and out-of-order response cancellation.
///
/// Components / Classes / Functions:
/// - MusicSearchController: State notifier coordinating instant search, debounce, and pagination.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';

/// Coordinator for zero-jank instant search (Module 5).
class MusicSearchController extends ChangeNotifier {
  final SongDao _songDao;

  MusicSearchController({SongDao? songDao})
      : _songDao = songDao ?? SongDao();

  /// Debounce threshold strictly complying with Rule 5.2.1 (250 - 300 ms).
  static const Duration debounceDuration = Duration(milliseconds: 280);

  /// Pagination size strictly complying with Rule 5.2.2 (Max 20 initial songs).
  static const int pageSize = 20;

  Timer? _debounceTimer;
  int _searchSequence = 0;

  String _query = '';
  List<Song> _results = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;

  /// Active query string.
  String get query => _query;

  /// Matching songs returned by the search engine.
  List<Song> get results => List.unmodifiable(_results);

  /// True while an initial query search is in-flight.
  bool get isLoading => _isLoading;

  /// True while fetching the next page of 20 results via infinite scroll.
  bool get isLoadingMore => _isLoadingMore;

  /// True if additional pages exist for the current query.
  bool get hasMore => _hasMore;

  /// Handles user input keystrokes, applying the 280 ms debounce filter.
  void onQueryChanged(String newQuery) {
    final trimmed = newQuery.trim();
    if (trimmed == _query) return;

    _query = trimmed;
    _debounceTimer?.cancel();

    if (_query.isEmpty) {
      _results.clear();
      _isLoading = false;
      _isLoadingMore = false;
      _hasMore = false;
      notifyListeners();
      return;
    }

    // Set loading indicator immediately while user waits for debounce
    _isLoading = true;
    notifyListeners();

    _debounceTimer = Timer(debounceDuration, () {
      _executeSearch(_query);
    });
  }

  /// Dispatches the search to SQLite FTS5 with query sequence tracking.
  Future<void> _executeSearch(String queryToSearch) async {
    final int currentSequence = ++_searchSequence;

    try {
      final songs = await _songDao.searchSongsFts(
        queryToSearch,
        limit: pageSize,
        offset: 0,
      );

      // Discard results if a newer search was initiated during async execution
      if (currentSequence != _searchSequence) return;

      _results = songs;
      _hasMore = songs.length >= pageSize;
    } catch (_) {
      if (currentSequence != _searchSequence) return;
      _results = [];
      _hasMore = false;
    } finally {
      if (currentSequence == _searchSequence) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Loads the next batch of 20 results (Rule 5.2.2 pagination).
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _query.isEmpty) return;

    _isLoadingMore = true;
    notifyListeners();

    final int currentSequence = _searchSequence;

    try {
      final moreSongs = await _songDao.searchSongsFts(
        _query,
        limit: pageSize,
        offset: _results.length,
      );

      if (currentSequence != _searchSequence) return;

      _results.addAll(moreSongs);
      _hasMore = moreSongs.length >= pageSize;
    } catch (_) {
      // Keep existing results intact on error
    } finally {
      if (currentSequence == _searchSequence) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  /// Resets search query and results immediately.
  void clear() {
    _debounceTimer?.cancel();
    _searchSequence++;
    _query = '';
    _results.clear();
    _isLoading = false;
    _isLoadingMore = false;
    _hasMore = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

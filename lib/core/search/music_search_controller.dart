/// File: music_search_controller.dart
/// Description: Zero-Jank Search Controller orchestrating 280 ms debouncing,
/// out-of-order sequence cancellation, and Spotify-style multi-tier fuzzy matching
/// across Artists, Albums, and Songs (strictly limited to 5).
///
/// Components / Classes / Functions:
/// - MusicSearchController: State notifier coordinating search input, debounce, and fuzzy results.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/search/fuzzy_search_engine.dart';
import 'package:project_anima/core/search/models/search_results_group.dart';

/// Coordinator for Spotify-styled fuzzy search and entity categorization.
class MusicSearchController extends ChangeNotifier {
  final SongDao _songDao;
  final FuzzySearchEngine _fuzzyEngine;

  MusicSearchController({SongDao? songDao, FuzzySearchEngine? fuzzyEngine})
      : _songDao = songDao ?? SongDao(),
        _fuzzyEngine = fuzzyEngine ?? FuzzySearchEngine(songDao: songDao ?? SongDao()) {
    // Pre-warm in-memory search dictionary in background
    _fuzzyEngine.reloadDictionary();
  }

  /// Data access object instance.
  SongDao get songDao => _songDao;

  /// Debounce threshold strictly complying with Rule 5.2.1 (250 - 300 ms).
  static const Duration debounceDuration = Duration(milliseconds: 280);

  /// Maximum songs to display in secondary list.
  static const int maxSongResults = 5;

  Timer? _debounceTimer;
  int _searchSequence = 0;

  String _query = '';
  SearchResultsGroup _resultsGroup = SearchResultsGroup.empty();
  bool _isLoading = false;

  /// Active query string.
  String get query => _query;

  /// Full Spotify-style grouped search results (Top Result, Songs, Albums, Artists).
  SearchResultsGroup get resultsGroup => _resultsGroup;

  /// Backward-compatible getter returning matched songs.
  List<Song> get results => _resultsGroup.matchedSongs;

  /// True while an initial query search is in-flight.
  bool get isLoading => _isLoading;

  /// True if at least one result (artist, album, or song) was found.
  bool get hasResults => _resultsGroup.isNotEmpty;

  /// Refreshes the in-memory search dictionary (e.g. after background indexing).
  Future<void> reloadDictionary() async {
    await _fuzzyEngine.reloadDictionary();
  }

  /// Handles user input keystrokes, applying the 280 ms debounce filter.
  void onQueryChanged(String newQuery) {
    final trimmed = newQuery.trim();
    if (trimmed == _query) return;

    _query = trimmed;
    _debounceTimer?.cancel();

    if (_query.isEmpty) {
      _resultsGroup = SearchResultsGroup.empty();
      _isLoading = false;
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

  /// Dispatches query to the FuzzySearchEngine with sequence tracking.
  Future<void> _executeSearch(String queryToSearch) async {
    final int currentSequence = ++_searchSequence;

    try {
      final results = await _fuzzyEngine.search(
        queryToSearch,
        songLimit: maxSongResults,
      );

      // Discard results if a newer search was initiated during async execution
      if (currentSequence != _searchSequence) return;

      _resultsGroup = results;
    } catch (_) {
      if (currentSequence != _searchSequence) return;
      _resultsGroup = SearchResultsGroup.empty(queryToSearch);
    } finally {
      if (currentSequence == _searchSequence) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Resets search query and results immediately.
  void clear() {
    _debounceTimer?.cancel();
    _searchSequence++;
    _query = '';
    _resultsGroup = SearchResultsGroup.empty();
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

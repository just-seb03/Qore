/// File: artist_tracks_controller.dart
/// Description: Business controller for the Artist Tracks feature.
/// Manages high-performance asynchronous querying of all songs for an artist,
/// background prioritization of song artwork, and reactive loading state management.
///
/// Components / Classes / Functions:
/// - ArtistTracksController: ChangeNotifier managing artist tracks catalog state.
library;

import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';

/// State controller managing the retrieval and prioritization of an artist's complete tracklist.
class ArtistTracksController extends ChangeNotifier {
  /// Name of the artist whose tracks are loaded.
  final String artistName;

  /// Injected SongDao for database queries.
  final SongDao _songDao;

  /// Injected ArtworkService for cache prioritization.
  final ArtworkService _artworkService;

  bool _isLoading = true;
  String? _errorMessage;
  List<Song> _songs = [];

  ArtistTracksController({
    required this.artistName,
    SongDao? songDao,
    ArtworkService? artworkService,
  })  : _songDao = songDao ?? SongDao(),
        _artworkService = artworkService ?? ArtworkService.instance;

  /// Whether tracks are currently being fetched from SQLite.
  bool get isLoading => _isLoading;

  /// Optional error message if track retrieval failed.
  String? get errorMessage => _errorMessage;

  /// Complete list of tracks credited to this artist (zero-copy unmodifiable view).
  List<Song> get songs => UnmodifiableListView(_songs);

  /// Total count of songs in this tracklist.
  int get songCount => _songs.length;

  /// Aggregate duration of all songs in milliseconds.
  int get totalDurationMs =>
      _songs.fold<int>(0, (sum, song) => sum + song.duration);

  /// Loads all songs for this artist and prioritizes artwork for the top visible chunk.
  Future<void> loadTracks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await _songDao.getSongsByArtist(artistName);
      _songs = items;

      // Prioritize the first 25 tracks for immediate artwork rendering
      final topIds = items
          .take(25)
          .map((s) => s.mediaStoreId)
          .toList();
      if (topIds.isNotEmpty) {
        _artworkService.prioritizeSongIds(topIds);
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ [ArtistTracksController] Error loading tracks: $e\n$stackTrace');
      _errorMessage = 'Failed to load tracks.';
      _songs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

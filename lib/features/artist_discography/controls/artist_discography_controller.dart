/// File: artist_discography_controller.dart
/// Description: Business controller for the Artist Discography feature.
/// Manages asynchronous retrieval of all albums for a given artist,
/// background prioritization of album artwork, and reactive loading state notifications.
///
/// Components / Classes / Functions:
/// - ArtistDiscographyController: ChangeNotifier coordinator managing artist discography state.
library;

import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';

/// State controller managing the retrieval and prioritization of an artist's full discography.
class ArtistDiscographyController extends ChangeNotifier {
  /// Name of the artist whose discography is managed.
  final String artistName;

  /// Injected SongDao for database queries.
  final SongDao _songDao;

  /// Injected ArtworkService for cache prioritization.
  final ArtworkService _artworkService;

  bool _isLoading = true;
  String? _errorMessage;
  List<AlbumDiscoveryItem> _albums = [];

  ArtistDiscographyController({
    required this.artistName,
    SongDao? songDao,
    ArtworkService? artworkService,
  })  : _songDao = songDao ?? SongDao(),
        _artworkService = artworkService ?? ArtworkService.instance;

  /// Whether discography albums are currently loading from SQLite.
  bool get isLoading => _isLoading;

  /// Optional error message if album retrieval failed.
  String? get errorMessage => _errorMessage;

  /// List of distinct albums released by this artist (zero-copy unmodifiable view).
  List<AlbumDiscoveryItem> get albums => UnmodifiableListView(_albums);

  /// Total number of distinct albums in this discography.
  int get albumCount => _albums.length;

  /// Loads the full list of albums for this artist and prioritizes artwork extraction.
  Future<void> loadDiscography() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await _songDao.getAlbumsByArtist(artistName);
      _albums = items;

      // Prioritize album artwork thumbnail extraction for fast display
      final repIds = items
          .map((a) => a.representativeSongId)
          .whereType<int>()
          .toList();
      if (repIds.isNotEmpty) {
        _artworkService.prioritizeSongIds(repIds);
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ [ArtistDiscographyController] Error loading discography: $e\n$stackTrace');
      _errorMessage = 'Failed to load discography.';
      _albums = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

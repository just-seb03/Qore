/// File: recent_search_controller.dart
/// Description: Singleton ChangeNotifier coordinating in-memory state and SQLite persistence
/// for user Recent Searches (MRU behavior capped at 20 items).
///
/// Components / Classes / Functions:
/// - RecentSearchController: Singleton coordinator managing reactive recent searches.
library;

import 'package:flutter/foundation.dart';
import 'package:project_anima/core/database/dao/recent_search_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/search/models/recent_search_item.dart';

/// Reactive coordinator for the Recent Searches feature.
class RecentSearchController extends ChangeNotifier {
  static RecentSearchController _instance = RecentSearchController._internal();

  /// Global singleton instance.
  static RecentSearchController get instance => _instance;

  /// Injects a custom or mock instance for testing.
  @visibleForTesting
  static set instance(RecentSearchController custom) => _instance = custom;

  /// Resets instance to default singleton.
  @visibleForTesting
  static void resetInstance() => _instance = RecentSearchController._internal();

  RecentSearchController._internal({RecentSearchDao? dao})
      : _dao = dao ?? RecentSearchDao();

  /// Dependency-injected factory constructor for tests.
  factory RecentSearchController({RecentSearchDao? dao}) {
    if (dao == null) return instance;
    return RecentSearchController._internal(dao: dao);
  }

  final RecentSearchDao _dao;
  List<RecentSearchItem> _items = [];
  bool _isInitialized = false;

  /// Current list of recent searches (up to 10 items, most recent first).
  List<RecentSearchItem> get items => List.unmodifiable(_items);

  /// Whether the database has been read into memory.
  bool get isInitialized => _isInitialized;

  /// Loads recent search items from SQLite into memory for instantaneous display.
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _items = await _dao.getRecentSearches(limit: 10);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ [RecentSearchController] Error initializing recent searches: $e');
    }
  }

  /// Records a clicked [Song] in recent searches.
  Future<void> addSong(Song song) async {
    final item = RecentSearchItem.fromSong(song);
    await _recordItem(item);
  }

  /// Records a clicked [AlbumDiscoveryItem] in recent searches.
  Future<void> addAlbum(AlbumDiscoveryItem album) async {
    final item = RecentSearchItem.fromAlbum(album);
    await _recordItem(item);
  }

  /// Records a clicked [ArtistDiscoveryItem] in recent searches.
  Future<void> addArtist(ArtistDiscoveryItem artist) async {
    final item = RecentSearchItem.fromArtist(artist);
    await _recordItem(item);
  }

  /// Re-registers an existing [RecentSearchItem] to bump it to the top.
  Future<void> touchItem(RecentSearchItem item) async {
    final updated = item.copyWith(
      timestampSeconds: DateTime.now().millisecondsSinceEpoch,
    );
    await _recordItem(updated);
  }

  /// Internal helper to update memory immediately and commit to SQLite asynchronously.
  Future<void> _recordItem(RecentSearchItem item) async {
    // 1. Instantaneous in-memory update for zero jank
    _items.removeWhere((i) => i.entityKey == item.entityKey);
    _items.insert(0, item);
    if (_items.length > 10) {
      _items = _items.sublist(0, 10);
    }
    notifyListeners();

    // 2. Asynchronous SQLite write
    try {
      await _dao.saveRecentSearch(item);
    } catch (e) {
      debugPrint('⚠️ [RecentSearchController] Error saving recent search: $e');
    }
  }

  /// Removes an individual item from recent searches.
  Future<void> removeItem(RecentSearchItem item) async {
    _items.removeWhere((i) => i.entityKey == item.entityKey);
    notifyListeners();

    try {
      await _dao.deleteRecentSearchByKey(item.entityKey);
    } catch (e) {
      debugPrint('⚠️ [RecentSearchController] Error deleting recent search: $e');
    }
  }

  /// Clears all recent searches from memory and SQLite.
  Future<void> clearAll() async {
    _items.clear();
    notifyListeners();

    try {
      await _dao.clearAll();
    } catch (e) {
      debugPrint('⚠️ [RecentSearchController] Error clearing recent searches: $e');
    }
  }
}

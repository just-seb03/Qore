/// File: home_layout_controller.dart
/// Description: Controller managing Home screen slot items and defined-place reordering.
/// Persists customized slot positions into SQLite app_metadata, maintaining low coupling
/// and high cohesion.
///
/// Components / Classes / Functions:
/// - HomeLayoutController: State controller managing item positions and drag-and-drop state.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/features/home/controls/home_slot_item.dart';
import 'package:sqflite/sqflite.dart';

/// Controller coordinating the defined places and reordering of Home screen components.
class HomeLayoutController extends ChangeNotifier {
  static HomeLayoutController? _instance;

  /// Singleton accessor for HomeLayoutController.
  static HomeLayoutController get instance => _instance ??= HomeLayoutController();

  final AppDatabase _db;
  static const String _kMetadataKey = 'home_layout_order';

  List<HomeSlotItem> _items = [];
  List<String> _persistedOrderIds = [];
  bool _isArranging = false;
  String? _draggingItemId;
  bool _isInitialized = false;

  HomeLayoutController({AppDatabase? dbProvider})
      : _db = dbProvider ?? AppDatabase.instance;

  /// Ordered list of slots currently displayed on Home.
  List<HomeSlotItem> get items => List.unmodifiable(_items);

  /// Whether the user is currently in edit / rearrange mode.
  bool get isArranging => _isArranging;

  /// Identifier of the item currently being dragged, if any.
  String? get draggingItemId => _draggingItemId;

  /// Enters rearranging mode with haptic feedback.
  void enterArrangingMode() {
    if (_isArranging) return;
    _isArranging = true;
    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  /// Exits rearranging mode and saves layout order.
  void exitArrangingMode() {
    if (!_isArranging) return;
    _isArranging = false;
    _draggingItemId = null;
    HapticFeedback.lightImpact();
    saveOrder();
    notifyListeners();
  }

  /// Toggles rearranging mode.
  void toggleArrangingMode() {
    if (_isArranging) {
      exitArrangingMode();
    } else {
      enterArrangingMode();
    }
  }

  /// Signals that dragging has started for item with [id].
  void startDragging(String id) {
    _draggingItemId = id;
    notifyListeners();
  }

  /// Signals that dragging has ended and persists layout order.
  void endDragging() {
    _draggingItemId = null;
    saveOrder();
    notifyListeners();
  }

  /// Performs fluid live displacement while dragging (Windows Mobile live-tile style).
  /// Reorders items in-memory without blocking on SQLite disk write on every frame.
  void liveShift(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= _items.length) return;
    if (toIndex < 0 || toIndex >= _items.length) return;
    if (fromIndex == toIndex) return;

    final item = _items.removeAt(fromIndex);
    _items.insert(toIndex, item);
    notifyListeners();
  }

  /// Initializes controller by reading persisted order from SQLite app_metadata.
  Future<void> init() async {
    if (_isInitialized) return;
    await loadPersistedOrder();
    _isInitialized = true;
  }

  /// Loads the persisted slot order IDs from database.
  Future<void> loadPersistedOrder() async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'app_metadata',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [_kMetadataKey],
      );

      if (results.isNotEmpty && results.first['value'] != null) {
        final raw = results.first['value'] as String;
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _persistedOrderIds = decoded.map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      debugPrint('⚠️ [HomeLayoutController] Error loading persisted order: $e');
    }
  }

  /// Persists current items order to SQLite app_metadata.
  Future<void> saveOrder() async {
    try {
      final ids = _items.map((i) => i.id).toList();
      _persistedOrderIds = ids;
      final jsonStr = jsonEncode(ids);

      final db = await _db.database;
      await db.insert(
        'app_metadata',
        {
          'key': _kMetadataKey,
          'value': jsonStr,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('⚠️ [HomeLayoutController] Error saving layout order: $e');
    }
  }

  /// Synchronizes incoming data with persisted or customized order.
  void syncItems({
    required List<PinnedFavorite> pinnedItems,
    bool showToday = true,
    bool showFavorites = true,
  }) {
    // 1. Build map of all available items
    final Map<String, HomeSlotItem> available = {};

    if (showToday) {
      final today = HomeSlotItem.todaySelection();
      available[today.id] = today;
    }

    if (showFavorites) {
      final favs = HomeSlotItem.favorites();
      available[favs.id] = favs;
    }

    for (final pinned in pinnedItems) {
      final item = HomeSlotItem.fromPinned(pinned);
      available[item.id] = item;
    }

    // 2. Order available items based on _persistedOrderIds
    final List<HomeSlotItem> ordered = [];
    final Set<String> addedIds = {};

    for (final id in _persistedOrderIds) {
      if (available.containsKey(id) && !addedIds.contains(id)) {
        ordered.add(available[id]!);
        addedIds.add(id);
      }
    }

    // 3. Append any newly added items that weren't in persisted order
    for (final entry in available.entries) {
      if (!addedIds.contains(entry.key)) {
        ordered.add(entry.value);
        addedIds.add(entry.key);
      }
    }

    _items = ordered;
    notifyListeners();
  }

  /// Reorders item from [oldIndex] to [newIndex] with Android-style shift behavior.
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _items.length) return;
    if (newIndex < 0 || newIndex >= _items.length) return;
    if (oldIndex == newIndex) return;

    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);

    saveOrder();
    notifyListeners();
  }

  /// Moves item with [itemId] into the target slot [targetIndex].
  void moveItemTo(String itemId, int targetIndex) {
    final oldIndex = _items.indexWhere((i) => i.id == itemId);
    if (oldIndex == -1) return;
    reorder(oldIndex, targetIndex);
  }

  /// Moves item one step upwards/earlier.
  void moveItemUp(int index) {
    if (index > 0 && index < _items.length) {
      reorder(index, index - 1);
      HapticFeedback.selectionClick();
    }
  }

  /// Moves item one step downwards/later.
  void moveItemDown(int index) {
    if (index >= 0 && index < _items.length - 1) {
      reorder(index, index + 1);
      HapticFeedback.selectionClick();
    }
  }

  /// Resets the layout order to the default system sequence.
  void resetToDefault() {
    _persistedOrderIds.clear();
    saveOrder();
    notifyListeners();
  }
}

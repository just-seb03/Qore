/// File: space_tiles_grid.dart
/// Description: Windows Phone Metro Live Tiles grid for the Space screen.
/// Arranges pinned favorites (albums, artists, and playlists) alongside the top-left
/// Favorites tile with zero padding, zero elevation shadows, and sharp 90-degree corners.
/// Reactive to PinnedFavoritesDao.revision updates.
///
/// Components / Classes / Functions:
/// - SpaceTilesGrid: Stateful grid coordinating Windows Phone Metro live tiles.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project_anima/core/database/dao/pinned_favorites_dao.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/scanner/music_indexer.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/home/components/metro_live_tile.dart';
import 'package:project_anima/features/home/components/tiles/metro_album_tile.dart';
import 'package:project_anima/features/home/components/tiles/metro_artist_tile.dart';
import 'package:project_anima/features/home/components/tiles/metro_favorites_tile.dart';
import 'package:project_anima/features/home/components/tiles/metro_playlist_tile.dart';

/// Sealed row hierarchy for Metro layout packing.
sealed class _MetroRowItem {}

class _MetroTopRowItem extends _MetroRowItem {
  final PinnedFavorite? rightItem;
  _MetroTopRowItem(this.rightItem);
}

class _MetroPlaylistRowItem extends _MetroRowItem {
  final PinnedFavorite playlist;
  _MetroPlaylistRowItem(this.playlist);
}

class _MetroPairRowItem extends _MetroRowItem {
  final PinnedFavorite first;
  final PinnedFavorite? second;
  _MetroPairRowItem(this.first, [this.second]);
}

/// Windows Phone-styled Metro live tiles grid for the Space screen.
class SpaceTilesGrid extends StatefulWidget {
  /// Optional pre-loaded pinned items (useful for testing or initial state).
  final List<PinnedFavorite>? initialPinnedItems;

  /// Optional pre-loaded favorite songs for the Favorites tile.
  final List<Song>? initialFavoriteSongs;

  const SpaceTilesGrid({
    super.key,
    this.initialPinnedItems,
    this.initialFavoriteSongs,
  });

  @override
  State<SpaceTilesGrid> createState() => _SpaceTilesGridState();
}

class _SpaceTilesGridState extends State<SpaceTilesGrid> {
  final ValueNotifier<int?> _flipTargetNotifier = ValueNotifier<int?>(null);
  Timer? _schedulerTimer;
  int _nextFlipCursor = 0;
  int _totalSlots = 1;
  bool _isTickerEnabled = true;

  List<PinnedFavorite>? _pinnedItems;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialPinnedItems != null) {
      _pinnedItems = widget.initialPinnedItems;
      _isLoading = false;
    } else {
      final cached = PinnedFavoritesDao.instance.cachedPinned;
      if (cached != null) {
        _pinnedItems = cached;
        _isLoading = false;
      }
      _loadPinned();
    }
    PinnedFavoritesDao.revision.addListener(_onRevisionChanged);
    MusicIndexer.revision.addListener(_onRevisionChanged);
    MetroLiveTile.isPaused.addListener(_syncSchedulerTimer);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isTickerEnabled = TickerMode.valuesOf(context).enabled;
    _syncSchedulerTimer();
  }

  @override
  void didUpdateWidget(covariant SpaceTilesGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPinnedItems != oldWidget.initialPinnedItems &&
        widget.initialPinnedItems != null) {
      setState(() {
        _pinnedItems = widget.initialPinnedItems;
        _isLoading = false;
      });
      _syncSchedulerTimer();
    }
  }

  @override
  void dispose() {
    _schedulerTimer?.cancel();
    _flipTargetNotifier.dispose();
    PinnedFavoritesDao.revision.removeListener(_onRevisionChanged);
    MusicIndexer.revision.removeListener(_onRevisionChanged);
    MetroLiveTile.isPaused.removeListener(_syncSchedulerTimer);
    super.dispose();
  }

  void _syncSchedulerTimer() {
    final bool shouldSchedule =
        !_isLoading && _isTickerEnabled && !MetroLiveTile.isPaused.value;
    if (!shouldSchedule) {
      _schedulerTimer?.cancel();
      _schedulerTimer = null;
      return;
    }

    _schedulerTimer ??= Timer.periodic(
      const Duration(seconds: 12),
      (_) => _triggerNextTileFlip(),
    );
  }

  void _triggerNextTileFlip() {
    if (!mounted ||
        _isLoading ||
        !_isTickerEnabled ||
        MetroLiveTile.isPaused.value ||
        _totalSlots <= 0) {
      return;
    }
    final int targetSlot = _nextFlipCursor % _totalSlots;
    _nextFlipCursor++;
    _flipTargetNotifier.value = null;
    _flipTargetNotifier.value = targetSlot;
  }

  void _onRevisionChanged() {
    if (widget.initialPinnedItems == null) {
      _loadPinned();
    }
  }

  Future<void> _loadPinned() async {
    try {
      final items = await PinnedFavoritesDao.instance.getAllPinned();
      if (!mounted) return;
      setState(() {
        _pinnedItems = items;
        _isLoading = false;
      });
      _syncSchedulerTimer();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pinnedItems = [];
        _isLoading = false;
      });
      _syncSchedulerTimer();
    }
  }

  Future<void> _confirmUnpin(PinnedFavorite item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'Desanclar de Space',
          style: AppFonts.segoe(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          '¿Deseas desanclar "${item.title}" de Space?',
          style: AppFonts.segoe(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'CANCELAR',
              style: AppFonts.segoe(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'DESANCLAR',
              style: AppFonts.segoe(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PinnedFavoritesDao.instance.togglePin(item);
    }
  }

  List<_MetroRowItem> _packRows(List<PinnedFavorite> items) {
    final List<_MetroRowItem> rows = [];
    final remaining = List<PinnedFavorite>.from(items);

    // 1. Pack top row: Slot 0 = Favorites (always present).
    // Slot 1 = First available square item (album or artist).
    final squareIdx = remaining.indexWhere((it) => it.isAlbum || it.isArtist);
    PinnedFavorite? topSquareItem;
    if (squareIdx != -1) {
      topSquareItem = remaining.removeAt(squareIdx);
    }
    rows.add(_MetroTopRowItem(topSquareItem));

    // 2. Pack subsequent rows with remaining items
    int i = 0;
    while (i < remaining.length) {
      final current = remaining[i];
      if (current.isPlaylist) {
        // Full width rectangular row (2:1 aspect ratio)
        rows.add(_MetroPlaylistRowItem(current));
        i++;
      } else {
        // Square item: find next square item to pair with
        final nextSquareIdx = remaining.indexWhere(
          (it) => it.isAlbum || it.isArtist,
          i + 1,
        );
        if (nextSquareIdx != -1) {
          final pair = remaining.removeAt(nextSquareIdx);
          rows.add(_MetroPairRowItem(current, pair));
          i++; // current was processed
        } else {
          rows.add(_MetroPairRowItem(current, null));
          i++;
        }
      }
    }

    return rows;
  }

  Widget _buildSquareTile(PinnedFavorite item, int index, {int? flipSlot}) {
    final staggerDelay = Duration(seconds: 22 + (index % 6) * 10);

    if (item.isAlbum) {
      return MetroAlbumTile(
        key: ValueKey('metro_album_${item.id ?? item.itemKey}'),
        album: item,
        initialDelay: staggerDelay,
        flipTrigger: flipSlot != null ? _flipTargetNotifier : null,
        flipSlot: flipSlot,
        onLongPress: () => _confirmUnpin(item),
      );
    }

    if (item.isArtist) {
      return MetroArtistTile(
        key: ValueKey('metro_artist_${item.id ?? item.itemKey}'),
        artist: item,
        initialDelay: staggerDelay,
        flipTrigger: flipSlot != null ? _flipTargetNotifier : null,
        flipSlot: flipSlot,
        onLongPress: () => _confirmUnpin(item),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    final items = _pinnedItems ?? [];
    final rows = _packRows(items);
    final List<int> rowStartSlot = List<int>.filled(rows.length, 0);
    int slotCursor = 0;
    for (int i = 0; i < rows.length; i++) {
      rowStartSlot[i] = slotCursor;
      slotCursor += switch (rows[i]) {
        _MetroTopRowItem(:final rightItem) => rightItem != null ? 2 : 1,
        _MetroPlaylistRowItem() => 1,
        _MetroPairRowItem(:final second) => second != null ? 2 : 1,
      };
    }
    _totalSlots = slotCursor;

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: 0.0,
          bottom: 160.0,
        ),
        physics: const BouncingScrollPhysics(),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          final int baseSlot = rowStartSlot[index];
          return switch (row) {
            _MetroTopRowItem(:final rightItem) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: MetroFavoritesTile(
                      initialSongs: widget.initialFavoriteSongs,
                      flipTrigger: _flipTargetNotifier,
                      flipSlot: baseSlot,
                    ),
                  ),
                  Expanded(
                    child: rightItem != null
                        ? _buildSquareTile(rightItem, 0, flipSlot: baseSlot + 1)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            _MetroPlaylistRowItem(:final playlist) => MetroPlaylistTile(
                key: ValueKey('metro_playlist_${playlist.id ?? playlist.itemKey}'),
                playlistItem: playlist,
                initialDelay: Duration(seconds: 36 + (index % 5) * 12),
                flipTrigger: _flipTargetNotifier,
                flipSlot: baseSlot,
                onLongPress: () => _confirmUnpin(playlist),
              ),
            _MetroPairRowItem(:final first, :final second) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildSquareTile(first, index, flipSlot: baseSlot),
                  ),
                  Expanded(
                    child: second != null
                        ? _buildSquareTile(second, index + 1, flipSlot: baseSlot + 1)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
          };
        },
      ),
    );
  }
}

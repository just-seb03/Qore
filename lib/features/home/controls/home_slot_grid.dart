/// File: home_slot_grid.dart
/// Description: Visual component rendering reorderable defined places on the Home screen.
/// Implements Android launcher-style drag-and-drop displacement, pairing half-width
/// items into 2-per-row slots and full-width banners across full rows.
///
/// Components / Classes / Functions:
/// - HomeSlotGrid: Defined-places grid with interactive drag-to-reorder and slot shifting.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/home/components/home_artist_card.dart';
import 'package:project_anima/features/home/components/home_favorites_hero_card.dart';
import 'package:project_anima/features/home/controls/home_layout_controller.dart';
import 'package:project_anima/features/home/controls/home_slot_item.dart';
import 'package:project_anima/features/library/components/albums/library_album_card.dart';
import 'package:project_anima/features/library/components/playlists/library_playlist_card.dart';

/// Sealed row descriptor for the defined-places Home layout.
sealed class _GridRow {
  const _GridRow();
}

class _FullRow extends _GridRow {
  final HomeSlotItem item;
  final int itemIndex;
  const _FullRow(this.item, this.itemIndex);
}

class _PairRow extends _GridRow {
  final HomeSlotItem first;
  final int firstIndex;
  final HomeSlotItem? second;
  final int? secondIndex;
  const _PairRow(this.first, this.firstIndex, [this.second, this.secondIndex]);
}

/// Visual grid presenting defined places on the Home screen with Android-style
/// displacement reordering and full/half width row packing.
class HomeSlotGrid extends StatelessWidget {
  final List<Song> todaySongs;
  final List<Song> favoriteSongs;
  final HomeLayoutController controller;
  final void Function(PinnedFavorite item) onOpenAlbum;
  final void Function(PinnedFavorite item) onOpenPlaylist;
  final void Function(PinnedFavorite item) onOpenArtist;

  const HomeSlotGrid({
    super.key,
    required this.todaySongs,
    required this.favoriteSongs,
    required this.controller,
    required this.onOpenAlbum,
    required this.onOpenPlaylist,
    required this.onOpenArtist,
  });

  /// Computes structured rows preserving defined place indices.
  List<_GridRow> _buildRows(List<HomeSlotItem> items) {
    final List<_GridRow> rows = [];
    int i = 0;

    while (i < items.length) {
      final current = items[i];

      if (current.isFullWidth) {
        rows.add(_FullRow(current, i));
        i += 1;
      } else {
        // Half-width item: check if the subsequent item is also half-width
        if (i + 1 < items.length && !items[i + 1].isFullWidth) {
          rows.add(_PairRow(current, i, items[i + 1], i + 1));
          i += 2;
        } else {
          rows.add(_PairRow(current, i));
          i += 1;
        }
      }
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final items = controller.items;
        if (items.isEmpty) return const SizedBox.shrink();

        final rows = _buildRows(items);
        final isArranging = controller.isArranging;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 18.0),
              itemBuilder: (context, index) {
                final row = rows[index];
                return switch (row) {
                  _FullRow(:final item, :final itemIndex) =>
                    _buildFullRow(context, item, itemIndex, isArranging),
                  _PairRow(:final first, :final firstIndex, :final second, :final secondIndex) =>
                    _buildPairRow(context, first, firstIndex, second, secondIndex, isArranging),
                };
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFullRow(
    BuildContext context,
    HomeSlotItem item,
    int index,
    bool isArranging,
  ) {
    final card = _buildCardContent(context, item);

    return _buildSlotWrapper(
      context: context,
      item: item,
      index: index,
      isArranging: isArranging,
      child: card,
    );
  }

  Widget _buildPairRow(
    BuildContext context,
    HomeSlotItem first,
    int firstIndex,
    HomeSlotItem? second,
    int? secondIndex,
    bool isArranging,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildSlotWrapper(
              context: context,
              item: first,
              index: firstIndex,
              isArranging: isArranging,
              child: _buildCardContent(context, first),
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: second != null && secondIndex != null
                ? _buildSlotWrapper(
                    context: context,
                    item: second,
                    index: secondIndex,
                    isArranging: isArranging,
                    child: _buildCardContent(context, second),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotWrapper({
    required BuildContext context,
    required HomeSlotItem item,
    required int index,
    required bool isArranging,
    required Widget child,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetWidth = item.isFullWidth
        ? screenWidth - 40.0
        : (screenWidth - 54.0) / 2.0;

    // Wrap with DragTarget: proximity-based live snapping (Windows Mobile live-tile style)
    // As the dragged item moves near or over this slot, it dynamically rectifies
    // and shifts items into place without needing precision.
    return DragTarget<HomeSlotItem>(
      hitTestBehavior: HitTestBehavior.translucent,
      onWillAcceptWithDetails: (details) {
        if (details.data.id != item.id) {
          final fromIdx = controller.items.indexWhere((i) => i.id == details.data.id);
          if (fromIdx != -1 && fromIdx != index) {
            controller.liveShift(fromIdx, index);
            HapticFeedback.selectionClick();
          }
        }
        return true;
      },
      onAcceptWithDetails: (details) {
        controller.endDragging();
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        final slotCard = AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: isHovered
                ? Border.all(color: AppColors.futuristicWhite, width: 2.0)
                : (isArranging
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 1.0,
                      )
                    : null),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.15),
                      blurRadius: 16.0,
                      spreadRadius: 2.0,
                    ),
                  ]
                : null,
          ),
          child: child,
        );

        // When in arranging mode: fluid drag-and-drop with Windows Mobile elevation & tilt
        if (isArranging) {
          return LongPressDraggable<HomeSlotItem>(
            data: item,
            delay: const Duration(milliseconds: 100),
            hapticFeedbackOnStart: true,
            onDragStarted: () {
              controller.startDragging(item.id);
              HapticFeedback.mediumImpact();
            },
            onDragEnd: (_) => controller.endDragging(),
            feedback: Material(
              color: Colors.transparent,
              elevation: 20.0,
              shadowColor: Colors.black.withValues(alpha: 0.8),
              child: Opacity(
                opacity: 0.94,
                child: Transform.scale(
                  scale: 1.04,
                  child: Transform.rotate(
                    angle: 0.025,
                    child: SizedBox(
                      width: targetWidth,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.18,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: child,
              ),
            ),
            child: slotCard,
          );
        }

        // When NOT in arranging mode: long-pressing any pin or system playlist
        // enters arranging mode
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () {
            controller.enterArrangingMode();
          },
          child: slotCard,
        );
      },
    );
  }

  Widget _buildCardContent(BuildContext context, HomeSlotItem slot) {
    switch (slot.type) {
      case HomeSlotType.todaySelection:
        return const SizedBox.shrink();

      case HomeSlotType.favorites:
        return HomeFavoritesHeroCard(songs: favoriteSongs);

      case HomeSlotType.pinnedPlaylist:
        final pinned = slot.pinnedFavorite;
        if (pinned == null) return const SizedBox.shrink();
        final playlist = Playlist(
          id: pinned.playlistId,
          name: pinned.title,
          coverPath: pinned.coverPath,
          fontFamily: pinned.fontFamily,
          firstMediaStoreId: pinned.representativeSongId,
          createdAt: pinned.pinnedAt.millisecondsSinceEpoch,
          updatedAt: pinned.pinnedAt.millisecondsSinceEpoch,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: LibraryPlaylistCard(
            playlist: playlist,
            showPlayButton: false,
            onTap: () => onOpenPlaylist(pinned),
          ),
        );

      case HomeSlotType.pinnedAlbum:
        final pinned = slot.pinnedFavorite;
        if (pinned == null) return const SizedBox.shrink();
        final albumDiscovery = AlbumDiscoveryItem(
          name: pinned.title,
          artist: pinned.subtitle ?? '',
          albumId: pinned.albumId,
          representativeSongId: pinned.representativeSongId ?? 0,
          songCount: 0,
          totalDuration: 0,
        );
        return LibraryAlbumCard(
          album: albumDiscovery,
          onTap: () => onOpenAlbum(pinned),
        );

      case HomeSlotType.pinnedArtist:
        final pinned = slot.pinnedFavorite;
        if (pinned == null) return const SizedBox.shrink();
        return HomeArtistCard(
          artist: pinned,
          onTap: () => onOpenArtist(pinned),
        );
    }
  }
}

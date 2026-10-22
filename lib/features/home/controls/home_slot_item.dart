/// File: home_slot_item.dart
/// Description: Data model representing a defined place / slot item on the Home screen.
/// Encapsulates both system playlist hero banners ('Today Selection', 'Favorites')
/// and user-pinned entities (albums, artists, custom playlists). Follows high cohesion
/// and low coupling.
///
/// Components / Classes / Functions:
/// - HomeSlotType: Enum distinguishing system and pinned entities.
/// - HomeSlotItem: Immutable slot model with unique identifier and full/half width span.
library;

import 'package:project_anima/core/database/models/pinned_favorite.dart';

/// Type of item placed in a Home screen slot.
enum HomeSlotType {
  todaySelection,
  favorites,
  pinnedPlaylist,
  pinnedAlbum,
  pinnedArtist,
}

/// Defined slot item representing a configurable component on the Home screen.
class HomeSlotItem {
  /// Unique identifier across system and pinned items.
  final String id;

  /// Classification of the item.
  final HomeSlotType type;

  /// Display title.
  final String title;

  /// Optional subtitle.
  final String? subtitle;

  /// Whether this item spans the full row width (2 columns).
  /// True for system hero playlists and custom playlists; false for albums and artists.
  final bool isFullWidth;

  /// Associated PinnedFavorite entity when type is pinned (album, artist, playlist).
  final PinnedFavorite? pinnedFavorite;

  const HomeSlotItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    required this.isFullWidth,
    this.pinnedFavorite,
  });

  /// Deterministic ID for system "Today's Selection" banner.
  static const String kTodaySelectionId = 'system::today_selection';

  /// Deterministic ID for system "Favorites" banner.
  static const String kFavoritesId = 'system::favorites';

  /// Generates a deterministic ID for a pinned item.
  static String pinnedId(PinnedFavorite item) => 'pinned::${item.itemKey}';

  /// Creates a HomeSlotItem for the Today Selection system playlist.
  factory HomeSlotItem.todaySelection() {
    return const HomeSlotItem(
      id: kTodaySelectionId,
      type: HomeSlotType.todaySelection,
      title: 'Today Selection',
      subtitle: 'Daily 20-track algorithmic mix',
      isFullWidth: true,
    );
  }

  /// Creates a HomeSlotItem for the Favorites system playlist.
  factory HomeSlotItem.favorites() {
    return const HomeSlotItem(
      id: kFavoritesId,
      type: HomeSlotType.favorites,
      title: 'Favorites',
      subtitle: 'Liked tracks playlist',
      isFullWidth: true,
    );
  }

  /// Creates a HomeSlotItem from a PinnedFavorite entity.
  factory HomeSlotItem.fromPinned(PinnedFavorite item) {
    if (item.isPlaylist) {
      return HomeSlotItem(
        id: pinnedId(item),
        type: HomeSlotType.pinnedPlaylist,
        title: item.title,
        subtitle: item.subtitle,
        isFullWidth: true,
        pinnedFavorite: item,
      );
    } else if (item.isArtist) {
      return HomeSlotItem(
        id: pinnedId(item),
        type: HomeSlotType.pinnedArtist,
        title: item.title,
        subtitle: item.subtitle,
        isFullWidth: false,
        pinnedFavorite: item,
      );
    } else {
      return HomeSlotItem(
        id: pinnedId(item),
        type: HomeSlotType.pinnedAlbum,
        title: item.title,
        subtitle: item.subtitle,
        isFullWidth: false,
        pinnedFavorite: item,
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeSlotItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

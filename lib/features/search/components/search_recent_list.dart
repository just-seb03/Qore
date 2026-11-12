/// File: search_recent_list.dart
/// Description: Spotify-styled list widget displaying up to 20 user recent searches
/// (songs, albums, and artists) on the initial search view, with individual delete ('x')
/// and clear-all actions.
///
/// Components / Classes / Functions:
/// - SearchRecentList: Main widget presenting recent searches in clean list format.
/// - _RecentSearchTile: Individual list item with artwork/avatar, title, subtitle, and dismiss button.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/search/models/recent_search_item.dart';
import 'package:project_anima/core/search/recent_search_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/search/components/common/material_artist_avatar.dart';

/// Renders the list of recently clicked search entities.
class SearchRecentList extends StatelessWidget {
  final ValueChanged<RecentSearchItem>? onItemTap;
  final ScrollController? scrollController;
  final RecentSearchController? controller;

  const SearchRecentList({
    super.key,
    this.onItemTap,
    this.scrollController,
    this.controller,
  });

  static TextStyle get _headerStyle => AppFonts.segoe(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: AppColors.onBackground,
  );

  static TextStyle get _clearAllStyle => AppFonts.segoe(
    fontSize: 13.0,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceVariant,
  );

  @override
  Widget build(BuildContext context) {
    final effectiveController = controller ?? RecentSearchController.instance;

    return ListenableBuilder(
      listenable: effectiveController,
      builder: (context, _) {
        final items = effectiveController.items.take(10).toList();
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListView.builder(
          controller: scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 8.0, bottom: 160.0),
          itemCount: items.length + 1, // Header + Items
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.search.recentSearchesHeader,
                      style: _headerStyle,
                    ),
                    TextButton(
                      onPressed: () => effectiveController.clearAll(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        context.l10n.search.clearAllRecentAction,
                        style: _clearAllStyle,
                      ),
                    ),
                  ],
                ),
              );
            }

            final item = items[index - 1];
            return _RecentSearchTile(
              item: item,
              onTap: () {
                effectiveController.touchItem(item);
                onItemTap?.call(item);
              },
              onRemove: () => effectiveController.removeItem(item),
            );
          },
        );
      },
    );
  }
}

/// Individual recent search row with icon/artwork, typography, and delete button.
class _RecentSearchTile extends StatelessWidget {
  final RecentSearchItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentSearchTile({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  static TextStyle get _titleStyle => AppFonts.segoe(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static TextStyle get _subtitleStyle => AppFonts.segoe(
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.3),
        highlightColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // 1. Artwork or Material Avatar
              _buildLeadingWidget(),
              const SizedBox(width: 14.0),

              // 2. Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _titleStyle,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _subtitleStyle,
                    ),
                  ],
                ),
              ),

              // 3. Remove Button ('X')
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Icons.close_rounded,
                  size: 20.0,
                  color: AppColors.onSurfaceVariant,
                ),
                splashRadius: 18.0,
                tooltip: context.l10n.search.removeRecentTooltip,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingWidget() {
    switch (item.type) {
      case RecentSearchType.artist:
        return MaterialArtistAvatar(
          radius: 26.0,
          artistName: item.title,
        );
      case RecentSearchType.album:
        return AnimaArtworkImage(
          mediaStoreId: item.representativeSongId,
          albumId: item.albumId,
          albumName: item.title,
          artistName: item.cleanArtistName,
          width: 52.0,
          height: 52.0,
          borderRadius: 0.0,
          fallbackIcon: Icons.album_rounded,
          isThumbnail: false,
        );
      case RecentSearchType.song:
        return AnimaArtworkImage(
          mediaStoreId: item.representativeSongId,
          albumId: item.albumId,
          width: 52.0,
          height: 52.0,
          borderRadius: 0.0,
          fallbackIcon: Icons.music_note_rounded,
          isThumbnail: false,
        );
    }
  }
}

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
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/search/models/recent_search_item.dart';
import 'package:project_anima/core/search/recent_search_controller.dart';
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

  static final TextStyle _headerStyle = GoogleFonts.inconsolata(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: Colors.white,
  );

  static final TextStyle _clearAllStyle = GoogleFonts.inconsolata(
    fontSize: 13.0,
    fontWeight: FontWeight.w600,
    color: const Color(0xFFB3B3B3),
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
          padding: const EdgeInsets.only(top: 8.0, bottom: 32.0),
          itemCount: items.length + 1, // Header + Items
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECENT SEARCHES',
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
                        'Clear all',
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

  static final TextStyle _titleStyle = GoogleFonts.inconsolata(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static final TextStyle _subtitleStyle = GoogleFonts.inconsolata(
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFB3B3B3),
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFF282828),
        highlightColor: const Color(0xFF1E1E1E),
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
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20.0,
                  color: Color(0xFF8E8E8E),
                ),
                splashRadius: 18.0,
                tooltip: 'Remove from recents',
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
          width: 52.0,
          height: 52.0,
          borderRadius: 6.0,
          fallbackIcon: Icons.album_rounded,
          isThumbnail: false,
        );
      case RecentSearchType.song:
        return AnimaArtworkImage(
          mediaStoreId: item.representativeSongId,
          albumId: item.albumId,
          width: 52.0,
          height: 52.0,
          borderRadius: 6.0,
          fallbackIcon: Icons.music_note_rounded,
          isThumbnail: false,
        );
    }
  }
}

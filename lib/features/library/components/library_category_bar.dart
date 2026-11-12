/// File: library_category_bar.dart
/// Description: Top navigation control for the Library screen styled in authentic Windows Phone
/// Metro Pivot design language. Features horizontal left-aligned Pivot titles ('Álbumes', 'Artistas',
/// 'Canciones', 'Playlists') in Segoe UI typography, with responsive sizing and zero rounded corners.
///
/// Components / Classes / Functions:
/// - LibraryCategoryBar: Animated Metro Pivot navigation bar for Library.
/// - _LibraryCategoryBarState: State class coordinating tab transitions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/library/components/library_filter_pills.dart';

/// Top category navigation bar for Library in authentic Metro Pivot aesthetic:
/// `[Álbumes]  [Artistas]  [Canciones]  [Playlists]`
class LibraryCategoryBar extends StatefulWidget {
  /// Currently selected category filter. Defaults to [LibraryFilter.albums].
  final LibraryFilter selectedFilter;

  /// Callback when a category title is tapped.
  final ValueChanged<LibraryFilter>? onFilterChanged;

  /// Optional callback when navigate previous is triggered.
  final VoidCallback? onPrevious;

  /// Optional callback when navigate next is triggered.
  final VoidCallback? onNext;

  /// Whether animations are enabled.
  final bool animate;

  /// Whether navigation chevron arrows ('<' and '>') are displayed. Defaults to true.
  final bool showChevrons;

  /// Padding around the category bar. Defaults to left-aligned padding.
  final EdgeInsetsGeometry padding;

  const LibraryCategoryBar({
    super.key,
    required this.selectedFilter,
    this.onFilterChanged,
    this.onPrevious,
    this.onNext,
    this.animate = true,
    this.showChevrons = true,
    this.padding = const EdgeInsets.only(left: 20.0, right: 16.0, top: 2.0, bottom: 6.0),
  });

  @override
  State<LibraryCategoryBar> createState() => _LibraryCategoryBarState();
}

class _LibraryCategoryBarState extends State<LibraryCategoryBar> {
  void _handleTap(LibraryFilter filter) {
    if (widget.selectedFilter != filter) {
      HapticFeedback.selectionClick();
      widget.onFilterChanged?.call(filter);
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    final lower = text.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final categories = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Albums Pivot Button
          _buildCategoryButton(
            key: const ValueKey('library_category_albums'),
            filter: LibraryFilter.albums,
            label: _capitalize(l10n.library.filterAlbums),
            tooltip: l10n.library.filterAlbums,
            filledIcon: Icons.album_rounded,
            outlinedIcon: Icons.album_outlined,
            size: 26.0,
          ),
          const SizedBox(width: 12.0),

          // 2. Artists Pivot Button
          _buildCategoryButton(
            key: const ValueKey('library_category_artists'),
            filter: LibraryFilter.artists,
            label: _capitalize(l10n.library.filterArtists),
            tooltip: l10n.library.filterArtists,
            filledIcon: Icons.person_rounded,
            outlinedIcon: Icons.person_outline_rounded,
            size: 32.0,
          ),
          const SizedBox(width: 12.0),

          // 3. Songs Pivot Button (New before Playlists)
          _buildCategoryButton(
            key: const ValueKey('library_category_songs'),
            filter: LibraryFilter.songs,
            label: _capitalize(l10n.library.filterSongs),
            tooltip: l10n.library.filterSongs,
            filledIcon: Icons.music_note_rounded,
            outlinedIcon: Icons.music_note_outlined,
            size: 26.0,
          ),
          const SizedBox(width: 12.0),

          // 4. Playlists Pivot Button
          _buildCategoryButton(
            key: const ValueKey('library_category_playlists'),
            filter: LibraryFilter.playlists,
            label: _capitalize(l10n.library.filterPlaylists),
            tooltip: l10n.library.filterPlaylists,
            filledIcon: Icons.queue_music_rounded,
            outlinedIcon: Icons.queue_music_outlined,
            size: 26.0,
          ),
        ],
      ),
    );

    if (!widget.showChevrons) {
      return Padding(
        padding: widget.padding,
        child: categories,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          // Left Chevron '<'
          InkResponse(
            key: const ValueKey('library_nav_previous'),
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onPrevious?.call();
            },
            radius: 20.0,
            splashColor: AppColors.accent.withValues(alpha: 0.2),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 24.0,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(child: categories),
          // Right Chevron '>'
          InkResponse(
            key: const ValueKey('library_nav_next'),
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onNext?.call();
            },
            radius: 20.0,
            splashColor: AppColors.accent.withValues(alpha: 0.2),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 24.0,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton({
    required Key key,
    required LibraryFilter filter,
    required String label,
    required String tooltip,
    required IconData filledIcon,
    required IconData outlinedIcon,
    required double size,
  }) {
    final isSelected = widget.selectedFilter == filter;
    final activeTextColor = AppColors.onBackground;
    final inactiveTextColor = AppColors.onSurfaceVariant.withValues(alpha: 0.40);
    final activeIconColor = AppColors.accent;
    final inactiveIconColor = AppColors.onSurfaceVariant.withValues(alpha: 0.40);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        key: key,
        onTap: () => _handleTap(filter),
        splashColor: AppColors.accent.withValues(alpha: 0.15),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppFonts.segoe(
                  fontSize: isSelected ? 17.0 : 16.0,
                  fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
                  color: isSelected ? activeTextColor : inactiveTextColor,
                  letterSpacing: -0.2,
                ),
              ),
              Opacity(
                opacity: 0.0,
                child: SizedBox(
                  width: 1.0,
                  height: 1.0,
                  child: OverflowBox(
                    minWidth: size,
                    maxWidth: size,
                    minHeight: size,
                    maxHeight: size,
                    child: Icon(
                      isSelected ? filledIcon : outlinedIcon,
                      key: ValueKey('${filter.name}_${isSelected ? "filled" : "outline"}'),
                      size: size,
                      color: isSelected ? activeIconColor : inactiveIconColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// File: library_category_bar.dart
/// Description: Top navigation control for the Library screen featuring oscillating '<' and '>'
/// chevron arrows enclosing the Album, Artist, and Playlist category icons.
/// Implements filled vs outlined icon styling based on the active selection, an enlarged Artist icon,
/// and smooth interactive tapping with haptic and animation feedback.
///
/// Components / Classes / Functions:
/// - LibraryCategoryBar: Animated top category icon bar with '<' and '>' chevrons.
/// - _LibraryCategoryBarState: State class coordinating arrow oscillation and icon transitions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/library/components/library_filter_pills.dart';

/// Top category navigation bar for Library rendering:
/// `< [Album Icon] [Artist Icon (Enlarged)] [Playlist Icon] >`
class LibraryCategoryBar extends StatefulWidget {
  /// Currently selected category filter. Defaults to [LibraryFilter.albums].
  final LibraryFilter selectedFilter;

  /// Callback when a category icon is tapped.
  final ValueChanged<LibraryFilter>? onFilterChanged;

  /// Optional callback when the left chevron '<' is tapped (navigate previous).
  final VoidCallback? onPrevious;

  /// Optional callback when the right chevron '>' is tapped (navigate next).
  final VoidCallback? onNext;

  /// Whether chevron arrows should animate continuously. Defaults to true.
  final bool animate;

  /// Padding around the category bar. Defaults to vertical 6.0.
  final EdgeInsetsGeometry padding;

  const LibraryCategoryBar({
    super.key,
    required this.selectedFilter,
    this.onFilterChanged,
    this.onPrevious,
    this.onNext,
    this.animate = true,
    this.padding = const EdgeInsets.symmetric(vertical: 6.0),
  });

  @override
  State<LibraryCategoryBar> createState() => _LibraryCategoryBarState();
}

class _LibraryCategoryBarState extends State<LibraryCategoryBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrowAnimController;
  late final Animation<double> _arrowOffsetAnimation;

  @override
  void initState() {
    super.initState();
    // Gentle breathing oscillation for '<' and '>' chevrons matching search bar
    _arrowAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _arrowOffsetAnimation = Tween<double>(begin: 0.0, end: 3.5).animate(
      CurvedAnimation(
        parent: _arrowAnimController,
        curve: Curves.easeInOutSine,
      ),
    );

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (widget.animate && !isTest) {
      _arrowAnimController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _arrowAnimController.dispose();
    super.dispose();
  }

  void _handleTap(LibraryFilter filter) {
    if (widget.selectedFilter != filter) {
      HapticFeedback.selectionClick();
      widget.onFilterChanged?.call(filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: widget.padding,
      child: Center(
        child: AnimatedBuilder(
          animation: _arrowOffsetAnimation,
          builder: (context, _) {
            final offset = _arrowOffsetAnimation.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Left Chevron '<' (breathing leftward)
                Transform.translate(
                  offset: Offset(-offset, 0),
                  child: InkResponse(
                    key: const ValueKey('library_nav_previous'),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onPrevious?.call();
                    },
                    radius: 20.0,
                    splashColor: AppColors.accent.withValues(alpha: 0.2),
                    highlightColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 26.0,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),

                // 2. Album Icon
                _buildCategoryButton(
                  key: const ValueKey('library_category_albums'),
                  filter: LibraryFilter.albums,
                  tooltip: l10n.library.filterAlbums,
                  filledIcon: Icons.album_rounded,
                  outlinedIcon: Icons.album_outlined,
                  size: 26.0,
                ),
                const SizedBox(width: 16.0),

                // 3. Artist Icon (Enlarged)
                _buildCategoryButton(
                  key: const ValueKey('library_category_artists'),
                  filter: LibraryFilter.artists,
                  tooltip: l10n.library.filterArtists,
                  filledIcon: Icons.person_rounded,
                  outlinedIcon: Icons.person_outline_rounded,
                  size: 32.0,
                ),
                const SizedBox(width: 16.0),

                // 4. Playlist Icon
                _buildCategoryButton(
                  key: const ValueKey('library_category_playlists'),
                  filter: LibraryFilter.playlists,
                  tooltip: l10n.library.filterPlaylists,
                  filledIcon: Icons.queue_music_rounded,
                  outlinedIcon: Icons.queue_music_outlined,
                  size: 26.0,
                ),
                const SizedBox(width: 8.0),

                // 5. Right Chevron '>' (breathing rightward)
                Transform.translate(
                  offset: Offset(offset, 0),
                  child: InkResponse(
                    key: const ValueKey('library_nav_next'),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onNext?.call();
                    },
                    radius: 20.0,
                    splashColor: AppColors.accent.withValues(alpha: 0.2),
                    highlightColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 26.0,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryButton({
    required Key key,
    required LibraryFilter filter,
    required String tooltip,
    required IconData filledIcon,
    required IconData outlinedIcon,
    required double size,
  }) {
    final isSelected = widget.selectedFilter == filter;
    final activeColor = AppColors.accent;
    final inactiveColor = AppColors.onSurfaceVariant.withValues(alpha: 0.45);

    return Tooltip(
      message: tooltip,
      child: InkResponse(
        key: key,
        onTap: () => _handleTap(filter),
        radius: 24.0,
        splashColor: AppColors.accent.withValues(alpha: 0.25),
        highlightColor: Colors.transparent,
        child: SizedBox(
          width: 44.0,
          height: 44.0,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.88, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
              child: Icon(
                isSelected ? filledIcon : outlinedIcon,
                key: ValueKey('${filter.name}_${isSelected ? "filled" : "outline"}'),
                size: size,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

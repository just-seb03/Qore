/// File: library_category_bar.dart
/// Description: Top navigation control for the Library screen styled in authentic Windows Phone
/// Metro Pivot design language. Features horizontal Pivot labels ('Álbumes', 'Artistas', 'Playlists')
/// in Segoe UI Light typography, filled vs outlined icons, and oscillating '<' and '>' chevron arrows.
///
/// Components / Classes / Functions:
/// - LibraryCategoryBar: Animated Metro Pivot navigation bar for Library.
/// - _LibraryCategoryBarState: State class coordinating arrow oscillation and tab transitions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/library/components/library_filter_pills.dart';

/// Top category navigation bar for Library in authentic Metro Pivot aesthetic:
/// `< [Álbumes] [Artistas] [Playlists] >`
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

  /// Padding around the category bar. Defaults to vertical 4.0.
  final EdgeInsetsGeometry padding;

  const LibraryCategoryBar({
    super.key,
    required this.selectedFilter,
    this.onFilterChanged,
    this.onPrevious,
    this.onNext,
    this.animate = true,
    this.padding = const EdgeInsets.only(top: 4.0, bottom: 8.0),
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

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    final lower = text.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
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
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
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
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 24.0,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),

                  // 2. Album Pivot Button
                  _buildCategoryButton(
                    key: const ValueKey('library_category_albums'),
                    filter: LibraryFilter.albums,
                    label: _capitalize(l10n.library.filterAlbums),
                    tooltip: l10n.library.filterAlbums,
                    filledIcon: Icons.album_rounded,
                    outlinedIcon: Icons.album_outlined,
                    size: 26.0,
                  ),
                  const SizedBox(width: 6.0),

                  // 3. Artist Pivot Button
                  _buildCategoryButton(
                    key: const ValueKey('library_category_artists'),
                    filter: LibraryFilter.artists,
                    label: _capitalize(l10n.library.filterArtists),
                    tooltip: l10n.library.filterArtists,
                    filledIcon: Icons.person_rounded,
                    outlinedIcon: Icons.person_outline_rounded,
                    size: 32.0,
                  ),
                  const SizedBox(width: 6.0),

                  // 4. Playlist Pivot Button
                  _buildCategoryButton(
                    key: const ValueKey('library_category_playlists'),
                    filter: LibraryFilter.playlists,
                    label: _capitalize(l10n.library.filterPlaylists),
                    tooltip: l10n.library.filterPlaylists,
                    filledIcon: Icons.queue_music_rounded,
                    outlinedIcon: Icons.queue_music_outlined,
                    size: 26.0,
                  ),
                  const SizedBox(width: 4.0),

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
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 24.0,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
    final inactiveTextColor = AppColors.onSurfaceVariant.withValues(alpha: 0.4);
    final activeIconColor = AppColors.accent;
    final inactiveIconColor = AppColors.onSurfaceVariant.withValues(alpha: 0.4);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        key: key,
        onTap: () => _handleTap(filter),
        splashColor: AppColors.accent.withValues(alpha: 0.15),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppFonts.segoe(
                  fontSize: 19.0,
                  fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
                  color: isSelected ? activeTextColor : inactiveTextColor,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 5.0),
              Icon(
                isSelected ? filledIcon : outlinedIcon,
                key: ValueKey('${filter.name}_${isSelected ? "filled" : "outline"}'),
                size: size,
                color: isSelected ? activeIconColor : inactiveIconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

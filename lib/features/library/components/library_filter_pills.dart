/// File: library_filter_pills.dart
/// Description: High-performance, native Material Design 3 Expressive connected
/// button group for the Library screen. Features identical button widths,
/// independent multi-selection (zero, some, or all), strict adherence to
/// AppColors, and top-centered positioning matching the search bar layout.
/// Implements static caching of Inconsolata TextStyles to prevent font overhead during selection toggles.
///
/// Components / Classes / Functions:
/// - LibraryFilterPills: Stateful widget displaying the top-centered, equal-width connected filter pills.
/// - _ConnectedPillButton: Internal optimized button item rendering M3 Expressive connected corner radii.
///   - _selectedTextStyle: Pre-cached TextStyle for selected pill item.
///   - _unselectedTextStyle: Pre-cached TextStyle for unselected pill item.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Data model representing an action item in the connected filter pill group.
class _PillItem {
  final IconData icon;
  final String label;

  const _PillItem({
    required this.icon,
    required this.label,
  });
}

/// Native Material Design 3 Expressive connected pill group.
///
/// Formatted with equal-width buttons, horizontal top-centering, multi-selection toggles,
/// and smooth instant response matching the vertical position of the search bar.
class LibraryFilterPills extends StatefulWidget {
  /// Initial set of selected filter indices. Defaults to empty (none selected).
  final Set<int> initialSelectedIndices;

  /// Optional callback triggered when the set of active filters changes.
  final ValueChanged<Set<int>>? onFiltersChanged;

  /// Padding surrounding the pill group container. Defaults to vertical 8.0 to match the search bar.
  final EdgeInsetsGeometry padding;

  /// Maximum container width constraint to keep buttons neatly sized and centered.
  final double maxWidth;

  const LibraryFilterPills({
    super.key,
    this.initialSelectedIndices = const <int>{},
    this.onFiltersChanged,
    this.padding = const EdgeInsets.only(
      left: 16.0,
      top: 0.0,
      right: 16.0,
      bottom: 8.0,
    ),
    this.maxWidth = 360.0,
  });

  @override
  State<LibraryFilterPills> createState() => _LibraryFilterPillsState();
}

class _LibraryFilterPillsState extends State<LibraryFilterPills> {
  late Set<int> _selectedIndices;

  static const List<_PillItem> _items = [
    _PillItem(icon: Symbols.person_rounded, label: 'Artists'),
    _PillItem(icon: Symbols.album_rounded, label: 'Albums'),
    _PillItem(icon: Symbols.queue_music_rounded, label: 'Playlists'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndices = Set<int>.from(widget.initialSelectedIndices);
  }

  void _toggleIndex(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
    widget.onFiltersChanged?.call(Set<int>.unmodifiable(_selectedIndices));
  }

  BorderRadius _getShapeForIndex(int index, int total) {
    const outerRadius = Radius.circular(20.0);
    const innerRadius = Radius.circular(4.0);

    if (total == 1) {
      return const BorderRadius.all(outerRadius);
    }
    if (index == 0) {
      // Leading connected pill
      return const BorderRadius.only(
        topLeft: outerRadius,
        bottomLeft: outerRadius,
        topRight: innerRadius,
        bottomRight: innerRadius,
      );
    } else if (index == total - 1) {
      // Trailing connected pill
      return const BorderRadius.only(
        topLeft: innerRadius,
        bottomLeft: innerRadius,
        topRight: outerRadius,
        bottomRight: outerRadius,
      );
    } else {
      // Middle connected pill
      return const BorderRadius.all(innerRadius);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              for (int i = 0; i < _items.length; i++) ...[
                if (i > 0) const SizedBox(width: 2.0),
                Expanded(
                  child: _ConnectedPillButton(
                    item: _items[i],
                    isSelected: _selectedIndices.contains(i),
                    shape: _getShapeForIndex(i, _items.length),
                    onTap: () => _toggleIndex(i),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual connected button item with M3 Expressive animated states and colors.
class _ConnectedPillButton extends StatelessWidget {
  final _PillItem item;
  final bool isSelected;
  final BorderRadius shape;
  final VoidCallback onTap;

  /// Pre-cached Inconsolata style for selected pill.
  static final TextStyle _selectedTextStyle = GoogleFonts.inconsolata(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  /// Pre-cached Inconsolata style for unselected pill.
  static final TextStyle _unselectedTextStyle = GoogleFonts.inconsolata(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  const _ConnectedPillButton({
    required this.item,
    required this.isSelected,
    required this.shape,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? AppColors.navIndicator
        : AppColors.surfaceContainer;

    final foregroundColor = isSelected
        ? AppColors.futuristicWhite
        : AppColors.onSurfaceVariant;

    final borderColor = isSelected
        ? AppColors.outline
        : AppColors.outlineVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: 40.0,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: shape,
        border: Border.all(
          color: borderColor,
          width: isSelected ? 1.0 : 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          splashColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
          highlightColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 17.0,
                  color: foregroundColor,
                ),
                const SizedBox(width: 6.0),
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (isSelected ? _selectedTextStyle : _unselectedTextStyle).copyWith(
                      color: foregroundColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

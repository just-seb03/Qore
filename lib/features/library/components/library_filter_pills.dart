/// File: library_filter_pills.dart
/// Description: Connected pill button group component for the Library screen,
/// built natively with Material Design 3 Expressive guidelines. Features
/// connected pill shapes, animated selection squish, and monochromatic dark styling.
///
/// Components / Classes / Functions:
/// - LibraryFilterPills: Stateful widget displaying the M3 Expressive connected filter pills.
library;

import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Material Design 3 Expressive connected pill group for Library filters.
///
/// Renders connected pills with leading, middle, and trailing shapes that morph
/// upon selection, matching the M3 Expressive Connected Button Group specifications.
class LibraryFilterPills extends StatefulWidget {
  /// Index of the initially selected pill.
  final int initialIndex;

  /// Optional callback triggered when the active filter changes.
  final ValueChanged<int>? onFilterChanged;

  /// Padding surrounding the pill group container.
  final EdgeInsetsGeometry padding;

  const LibraryFilterPills({
    super.key,
    this.initialIndex = 0,
    this.onFilterChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  });

  @override
  State<LibraryFilterPills> createState() => _LibraryFilterPillsState();
}

class _LibraryFilterPillsState extends State<LibraryFilterPills> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _handleSelectionChanged(int? index) {
    if (index == null || _selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    widget.onFilterChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: M3EButtonGroup(
          type: M3EButtonGroupType.connected,
          shape: M3EButtonShape.round,
          size: M3EButtonSize.sm,
          style: M3EButtonStyle.tonal,
          neighborSquish: true,
          selectionRequired: true,
          selectedIndex: _selectedIndex,
          onSelectedIndexChanged: _handleSelectionChanged,
          actions: const [
            M3EButtonGroupAction(
              icon: Icon(Symbols.person_rounded, size: 18.0),
              selectedIcon: Icon(Symbols.person_rounded, size: 18.0),
              label: Text(
                'Artists',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.0,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            M3EButtonGroupAction(
              icon: Icon(Symbols.album_rounded, size: 18.0),
              selectedIcon: Icon(Symbols.album_rounded, size: 18.0),
              label: Text(
                'Albums',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.0,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            M3EButtonGroupAction(
              icon: Icon(Symbols.queue_music_rounded, size: 18.0),
              selectedIcon: Icon(Symbols.queue_music_rounded, size: 18.0),
              label: Text(
                'Playlists',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.0,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

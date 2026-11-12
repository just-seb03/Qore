/// File: metro_alphabet_scroller.dart
/// Description: Windows Phone Metro style alphabet jump-list scroller.
/// Features a vertical alphabet rail (#, A-Z) along the right margin with dynamic
/// kinetic leftward projection for the active letter, and subtle rightward
/// kinetic offset for the corresponding active items in the list.
///
/// Components / Classes / Functions:
/// - MetroAlphabetScroller: Generic StatefulWidget coordinating alphabet indexing and kinetic scrolling.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Metro Jump-List widget wrapping a list of items with an interactive alphabet rail.
class MetroAlphabetScroller<T> extends StatefulWidget {
  /// List of items to display.
  final List<T> items;

  /// Selector extracting the string title used for alphabetical indexing.
  final String Function(T item) titleSelector;

  /// Fixed height for each list tile for high performance virtualization.
  final double itemExtent;

  /// Builder for list items, receiving (context, index, item, isCurrentSection).
  final Widget Function(
    BuildContext context,
    int index,
    T item,
    bool isCurrentSection,
  ) itemBuilder;

  /// Optional external scroll controller.
  final ScrollController? scrollController;

  /// Padding around the scroll view.
  final EdgeInsetsGeometry padding;

  /// Widget to display when items list is empty.
  final Widget? emptyWidget;

  const MetroAlphabetScroller({
    super.key,
    required this.items,
    required this.titleSelector,
    required this.itemExtent,
    required this.itemBuilder,
    this.scrollController,
    this.padding = const EdgeInsets.only(
      left: 16.0,
      right: 36.0,
      top: 10.0,
      bottom: 160.0,
    ),
    this.emptyWidget,
  });

  /// Normalizes a string to extract its single uppercase Metro jump-list key ('#' or 'A'..'Z').
  static String normalizeLetter(String title) {
    if (title.isEmpty) return '#';
    final char = title.trim()[0].toUpperCase();
    const accents = {
      'Á': 'A', 'À': 'A', 'Ä': 'A', 'Â': 'A',
      'É': 'E', 'È': 'E', 'Ë': 'E', 'Ê': 'E',
      'Í': 'I', 'Ì': 'I', 'Ï': 'I', 'Î': 'I',
      'Ó': 'O', 'Ò': 'O', 'Ö': 'O', 'Ô': 'O',
      'Ú': 'U', 'Ù': 'U', 'Ü': 'U', 'Û': 'U',
      'Ñ': 'N',
    };
    final unaccented = accents[char] ?? char;
    if (RegExp(r'^[A-Z]$').hasMatch(unaccented)) {
      return unaccented;
    }
    return '#';
  }

  @override
  State<MetroAlphabetScroller<T>> createState() => _MetroAlphabetScrollerState<T>();
}

class _MetroAlphabetScrollerState<T> extends State<MetroAlphabetScroller<T>> {
  static const List<String> _alphabet = [
    '#', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  late ScrollController _scrollController;
  bool _ownsController = false;
  String _activeLetter = '#';
  Map<String, int> _letterIndices = {};

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _ownsController = true;
    }
    _recomputeIndices();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant MetroAlphabetScroller<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _recomputeIndices();
    }
    if (widget.scrollController != oldWidget.scrollController) {
      if (_ownsController) {
        _scrollController.removeListener(_onScroll);
        _scrollController.dispose();
        _ownsController = false;
      }
      if (widget.scrollController != null) {
        _scrollController = widget.scrollController!;
      } else {
        _scrollController = ScrollController();
        _ownsController = true;
      }
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (_ownsController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _recomputeIndices() {
    final map = <String, int>{};
    for (int i = 0; i < widget.items.length; i++) {
      final letter = MetroAlphabetScroller.normalizeLetter(
        widget.titleSelector(widget.items[i]),
      );
      map.putIfAbsent(letter, () => i);
    }
    _letterIndices = map;
    if (widget.items.isNotEmpty) {
      _activeLetter = MetroAlphabetScroller.normalizeLetter(
        widget.titleSelector(widget.items.first),
      );
    }
  }

  void _onScroll() {
    if (!mounted || widget.items.isEmpty || !_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final index = (offset / widget.itemExtent)
        .floor()
        .clamp(0, widget.items.length - 1);
    final letter = MetroAlphabetScroller.normalizeLetter(
      widget.titleSelector(widget.items[index]),
    );
    if (letter != _activeLetter) {
      setState(() {
        _activeLetter = letter;
      });
    }
  }

  void _jumpToLetter(String letter) {
    final index = _letterIndices[letter];
    if (index == null || !_scrollController.hasClients) return;
    HapticFeedback.selectionClick();
    setState(() {
      _activeLetter = letter;
    });
    final targetOffset = (index * widget.itemExtent).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return widget.emptyWidget ?? const SizedBox.shrink();
    }

    return Stack(
      children: [
        // 1. Virtualized list view with kinetic item offset
        ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: widget.padding,
          itemExtent: widget.itemExtent,
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final itemLetter = MetroAlphabetScroller.normalizeLetter(
              widget.titleSelector(item),
            );
            final isCurrent = itemLetter == _activeLetter;
            return widget.itemBuilder(context, index, item, isCurrent);
          },
        ),

        // 2. Windows Phone Metro Alphabet Scrubber Rail
        Positioned(
          top: 6.0,
          right: 2.0,
          bottom: 90.0,
          width: 32.0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalHeight = constraints.maxHeight;
              final letterHeight = totalHeight / _alphabet.length;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  final y = details.localPosition.dy;
                  final letterIdx = (y / letterHeight).floor().clamp(0, _alphabet.length - 1);
                  final letter = _alphabet[letterIdx];
                  if (_letterIndices.containsKey(letter) && letter != _activeLetter) {
                    _jumpToLetter(letter);
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _alphabet.map((letter) {
                    final hasItems = _letterIndices.containsKey(letter);
                    final isActive = letter == _activeLetter;

                    return GestureDetector(
                      onTap: hasItems ? () => _jumpToLetter(letter) : null,
                      child: _buildAlphabetTile(letter, hasItems, isActive),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlphabetTile(String letter, bool hasItems, bool isActive) {
    if (isActive) {
      return Transform.translate(
        offset: const Offset(-10.0, 0.0),
        child: Container(
          width: 20.0,
          height: 18.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.zero,
          ),
          child: Text(
            letter,
            style: AppFonts.segoe(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.onAccent,
              height: 1.0,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.5),
      child: Text(
        letter,
        style: AppFonts.segoe(
          fontSize: hasItems ? 10.0 : 8.5,
          fontWeight: hasItems ? FontWeight.w400 : FontWeight.w200,
          color: hasItems
              ? AppColors.onSurfaceVariant.withValues(alpha: 0.75)
              : AppColors.onSurfaceVariant.withValues(alpha: 0.18),
          height: 1.0,
        ),
      ),
    );
  }
}

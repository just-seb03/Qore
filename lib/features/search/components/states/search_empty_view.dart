/// File: search_empty_view.dart
/// Description: Initial view displayed when the search query is empty.
/// Shows the SearchRecentList if recent search entries exist, or displays
/// a clean, unobstructed view without placeholder invitation texts.
///
/// Components / Classes / Functions:
/// - SearchEmptyView: Empty state coordinator widget.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/search/models/recent_search_item.dart';
import 'package:project_anima/core/search/recent_search_controller.dart';
import 'package:project_anima/features/search/components/search_recent_list.dart';

/// State view rendered when search query is empty.
class SearchEmptyView extends StatelessWidget {
  /// Callback when a recent search item is tapped.
  final ValueChanged<RecentSearchItem>? onRecentItemTap;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  /// Optional RecentSearchController for dependency injection.
  final RecentSearchController? controller;

  const SearchEmptyView({
    super.key,
    this.onRecentItemTap,
    this.scrollController,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveController = controller ?? RecentSearchController.instance;

    return ListenableBuilder(
      listenable: effectiveController,
      builder: (context, _) {
        final recentItems = effectiveController.items;
        if (recentItems.isNotEmpty) {
          return SearchRecentList(
            scrollController: scrollController,
            onItemTap: onRecentItemTap,
            controller: effectiveController,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

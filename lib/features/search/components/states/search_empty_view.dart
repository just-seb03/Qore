/// File: search_empty_view.dart
/// Description: Initial view displayed when the search query is empty.
/// Shows the SearchRecentList if recent search entries exist, or displays
/// the library search invitation placeholder.
///
/// Components / Classes / Functions:
/// - SearchEmptyView: Empty state coordinator widget.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/search/models/recent_search_item.dart';
import 'package:project_anima/core/search/recent_search_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
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

  static final TextStyle _emptyHeaderStyle = GoogleFonts.inconsolata(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.futuristicWhite.withValues(alpha: 0.35),
  );

  static final TextStyle _emptySubtitleStyle = GoogleFonts.inconsolata(
    fontSize: 13.5,
    color: AppColors.futuristicWhite.withValues(alpha: 0.25),
  );

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

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.manage_search_rounded,
                size: 64.0,
                color: AppColors.futuristicWhite.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 12.0),
              Text(
                'SEARCH YOUR LIBRARY',
                style: _emptyHeaderStyle,
              ),
              const SizedBox(height: 4.0),
              Text(
                'Indexed titles, artists, or albums',
                style: _emptySubtitleStyle,
              ),
            ],
          ),
        );
      },
    );
  }
}

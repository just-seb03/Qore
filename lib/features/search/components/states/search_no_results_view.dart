/// File: search_no_results_view.dart
/// Description: Empty state view displayed when no matches are found across
/// songs, albums, or artists for a given search query.
///
/// Components / Classes / Functions:
/// - SearchNoResultsView: "Sin Resultados" presentation widget.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Empty results message displayed when a query yields zero matches.
class SearchNoResultsView extends StatelessWidget {
  /// The active search query that returned no matches.
  final String query;

  const SearchNoResultsView({
    super.key,
    required this.query,
  });

  static final TextStyle _noResultsHeaderStyle = GoogleFonts.zenDots(
    fontSize: 13.0,
    letterSpacing: 1.2,
    color: AppColors.futuristicWhite.withValues(alpha: 0.4),
  );

  static final TextStyle _noResultsSubtitleStyle = GoogleFonts.inconsolata(
    fontSize: 13.5,
    color: AppColors.futuristicWhite.withValues(alpha: 0.3),
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56.0,
              color: AppColors.futuristicWhite.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12.0),
            Text(
              'NO RESULTS FOUND',
              style: _noResultsHeaderStyle,
            ),
            const SizedBox(height: 6.0),
            Text(
              'No matches found for "$query"',
              textAlign: TextAlign.center,
              style: _noResultsSubtitleStyle,
            ),
          ],
        ),
      ),
    );
  }
}

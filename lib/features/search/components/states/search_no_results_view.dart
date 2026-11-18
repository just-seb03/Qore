/// File: search_no_results_view.dart
/// Description: Empty state view displayed when no matches are found across
/// songs, albums, or artists for a given search query.
///
/// Components / Classes / Functions:
/// - SearchNoResultsView: "Sin Resultados" presentation widget.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Empty results message displayed when a query yields zero matches.
class SearchNoResultsView extends StatelessWidget {
  /// The active search query that returned no matches.
  final String query;

  const SearchNoResultsView({
    super.key,
    required this.query,
  });

  static TextStyle get _noResultsHeaderStyle => AppFonts.light(
    fontSize: 18.0,
    letterSpacing: 1.4,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle get _noResultsSubtitleStyle => AppFonts.segoe(
    fontSize: 13.5,
    fontWeight: FontWeight.w300,
    color: AppColors.onSurfaceVariant.withValues(alpha: 0.75),
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
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12.0),
            Text(
              context.l10n.search.noResultsTitle,
              style: _noResultsHeaderStyle,
            ),
            const SizedBox(height: 6.0),
            Text(
              context.l10n.search.noResultsSubtitle(query),
              textAlign: TextAlign.center,
              style: _noResultsSubtitleStyle,
            ),
          ],
        ),
      ),
    );
  }
}

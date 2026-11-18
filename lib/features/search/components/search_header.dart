/// File: search_header.dart
/// Description: Top header component for the Search screen displaying a centered
/// title in the 'Inconsolata' typeface without background or separator lines.
/// Implements static caching of the Inconsolata TextStyle to prevent font parsing overhead.
///
/// Components / Classes / Functions:
/// - SearchHeader: Stateless widget rendering the centered Inconsolata section title.
///   - _titleTextStyle: Pre-cached TextStyle for GoogleFonts.inconsolata.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Top header for the Search screen supporting both centered standard typography
/// and authentic Windows Phone Metro Pivot aesthetic (Segoe UI Light, left-aligned).
class SearchHeader extends StatelessWidget {
  /// The header text to display. Defaults to localized 'Search' / 'Buscar'.
  final String? title;

  /// Custom padding around the header text.
  final EdgeInsetsGeometry? padding;

  /// Whether to render in authentic Windows Phone Metro Pivot aesthetic.
  final bool isMetro;

  /// Dynamic text style for the centered title matching active theme.
  static TextStyle get _titleTextStyle => AppFonts.segoe(
    fontSize: 24.0,
    fontWeight: FontWeight.w300,
    letterSpacing: 1.5,
    color: AppColors.onBackground,
  );

  const SearchHeader({
    super.key,
    this.title,
    this.padding,
    this.isMetro = false,
  });

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    final lower = text.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final rawTitle = title ?? context.l10n.search.headerTitle;

    if (isMetro) {
      final displayTitle = _capitalize(rawTitle);
      return Padding(
        padding: padding ??
            const EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 14.0,
              bottom: 8.0,
            ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            displayTitle,
            style: AppFonts.segoe(
              fontSize: 42.0,
              fontWeight: FontWeight.w300,
              letterSpacing: -0.5,
              color: AppColors.onBackground,
              height: 1.1,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: padding ??
          const EdgeInsets.only(
            top: 6.0,
            bottom: 12.0,
          ),
      child: Center(
        child: Text(
          rawTitle,
          textAlign: TextAlign.center,
          style: _titleTextStyle,
        ),
      ),
    );
  }
}

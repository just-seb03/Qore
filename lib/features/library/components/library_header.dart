/// File: library_header.dart
/// Description: Top header component for the Library screen displaying a centered
/// title in the 'Inconsolata' typeface without background or separator lines.
/// Implements static caching of the Inconsolata TextStyle to prevent font parsing overhead.
///
/// Components / Classes / Functions:
/// - LibraryHeader: Stateless widget rendering the centered Inconsolata section title.
///   - _titleTextStyle: Pre-cached TextStyle for GoogleFonts.inconsolata.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Top header for the Library screen with centered Inconsolata typography.
class LibraryHeader extends StatelessWidget {
  /// The header text to display. Defaults to localized 'Library'.
  final String? title;

  /// Custom padding around the header text.
  final EdgeInsetsGeometry padding;

  /// Dynamic text style for the Inconsolata title to respect active theme palette.
  static TextStyle get _titleTextStyle => AppFonts.segoe(
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.onBackground,
  );

  const LibraryHeader({
    super.key,
    this.title,
    this.padding = const EdgeInsets.only(
      top: 6.0,
      bottom: 12.0,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = title ?? context.l10n.library.headerTitle;

    return Padding(
      padding: padding,
      child: Center(
        child: Text(
          displayTitle,
          textAlign: TextAlign.center,
          style: _titleTextStyle,
        ),
      ),
    );
  }
}

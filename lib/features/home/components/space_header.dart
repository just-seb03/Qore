/// File: space_header.dart
/// Description: Top header component for the Space screen displaying a centered
/// title in the 'Inconsolata' typeface matching the exact font, size, and location
/// of the LibraryHeader and SearchHeader.
/// Implements dynamic theme color access and static caching of the Inconsolata TextStyle.
///
/// Components / Classes / Functions:
/// - SpaceHeader: Stateless widget rendering the centered Inconsolata section title 'Space'.
///   - _titleTextStyle: Pre-cached TextStyle for GoogleFonts.inconsolata.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Top header for the Space screen with centered Inconsolata typography.
class SpaceHeader extends StatelessWidget {
  /// The header text to display. Defaults to localized 'Space'.
  final String? title;

  /// Custom padding around the header text, strictly matching LibraryHeader and SearchHeader.
  final EdgeInsetsGeometry padding;

  /// Dynamic text style for the Inconsolata title matching active theme.
  static TextStyle get _titleTextStyle => AppFonts.segoe(
    fontSize: 24.0,
    fontWeight: FontWeight.w300,
    letterSpacing: 1.5,
    color: AppColors.onBackground,
  );

  const SpaceHeader({
    super.key,
    this.title,
    this.padding = const EdgeInsets.only(
      top: 6.0,
      bottom: 12.0,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: Text(
          title ?? context.l10n.home.spaceTitle,
          textAlign: TextAlign.center,
          style: _titleTextStyle,
        ),
      ),
    );
  }
}

/// File: library_header.dart
/// Description: Header component for the Library screen. Supports standard centered
/// header typography (matching SpaceHeader and SearchHeader) as well as the authentic
/// Windows Phone Metro Pivot aesthetic with prominent Segoe UI Light typography.
///
/// Components / Classes / Functions:
/// - LibraryHeader: Stateless widget rendering the Library section header.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Top header for the Library screen.
class LibraryHeader extends StatelessWidget {
  /// The header text to display. Defaults to localized 'Library' / 'Biblioteca'.
  final String? title;

  /// Custom padding around the header text.
  final EdgeInsetsGeometry? padding;

  /// Whether to render in authentic Windows Phone Metro Pivot aesthetic.
  final bool isMetro;

  /// Default text style for standard centered title matching SpaceHeader and SearchHeader.
  static TextStyle get _standardTextStyle => AppFonts.segoe(
    fontSize: 24.0,
    fontWeight: FontWeight.w300,
    letterSpacing: 1.5,
    color: AppColors.onBackground,
  );

  const LibraryHeader({
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
    final rawTitle = title ?? context.l10n.library.headerTitle;

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
          style: _standardTextStyle,
        ),
      ),
    );
  }
}
